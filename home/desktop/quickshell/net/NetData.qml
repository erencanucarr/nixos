pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// What NetMenu shows and does, through NetworkManager (nmcli) and /sys:
// the connection carrying the default route with its addresses, its
// traffic, an on-demand ping and public IP, and the edits (DNS, the IPv4
// mode, the name). Polls only while the menu is open (`watching`).
//
// Nothing here talks to the network unprompted: the ping and the public IP
// lookup run only when their button is pressed.
Singleton {
    id: root

    // Set by NetMenu while it is open.
    property bool watching: false

    // The primary link: device, type ("ethernet", "wifi"), state, the
    // connection's name and uuid, addresses, and its saved IPv4 settings.
    property var link: ({})
    // Saved Ethernet and Wi-Fi connections, for the IP settings page.
    property var connections: []

    // Bytes per second and in total since the link came up.
    property real rxRate: 0
    property real txRate: 0
    property real rxTotal: 0
    property real txTotal: 0
    property real lastSample: 0

    property string publicIp: ""
    property bool publicIpBusy: false
    // "12 ms · %0 kayıp", or "" before the first measure.
    property string ping: ""
    property bool pingBusy: false

    // The last edit's outcome, shown under the menu for a few seconds.
    property string status: ""
    property bool statusError: false
    property bool busy: false

    readonly property var dnsPresets: [
        { name: "Otomatik", servers: "" },
        { name: "Cloudflare", servers: "1.1.1.1 1.0.0.1" },
        { name: "Google", servers: "8.8.8.8 8.8.4.4" },
        { name: "Quad9", servers: "9.9.9.9 149.112.112.112" }
    ]

    // The preset matching the connection's saved DNS, or "" for none
    // ("Otomatik" only when it also takes the router's).
    readonly property string dnsPreset: {
        const saved = (link.savedDns ?? "").split(/[ ,]+/).filter(s => s).join(" ");
        if (saved === "")
            return "Otomatik";
        if (link.ignoreAutoDns !== "yes")
            return "";
        return dnsPresets.find(p => p.servers === saved)?.name ?? "";
    }

    function human(bytes: real, perSecond: bool): string {
        const units = ["B", "KB", "MB", "GB", "TB"];
        let v = bytes;
        let i = 0;
        while (v >= 1024 && i < units.length - 1) {
            v /= 1024;
            i++;
        }
        const n = i === 0 ? Math.round(v) : v.toFixed(v < 10 ? 1 : 0);
        return `${n} ${units[i]}${perSecond ? "/s" : ""}`;
    }

    function refresh(): void {
        if (!details.running)
            details.running = true;
    }

    function copy(text: string): void {
        Quickshell.execDetached(["wl-copy", text]);
        root.say(`Kopyalandı: ${text}`, false);
    }

    function say(text: string, error: bool): void {
        root.status = text;
        root.statusError = error;
        statusTimer.restart();
    }

    // One nmcli edit: `args` lists commands run in order; the first failure
    // stops and is reported.
    function run(commands: var, done: string): void {
        if (root.busy)
            return;
        root.busy = true;
        edit.done = done;
        edit.command = ["sh", "-c", commands.map(c => c.map(a => `'${String(a).replace(/'/g, "'\\''")}'`).join(" ")).join(" && ")];
        edit.running = true;
    }

    function setDns(servers: string): void {
        const l = root.link;
        if (!l.uuid)
            return;
        root.run([["nmcli", "connection", "modify", l.uuid, "ipv4.dns", servers, "ipv4.ignore-auto-dns", servers === "" ? "no" : "yes"], ["nmcli", "device", "reapply", l.device]], "DNS değişti");
    }

    function rename(name: string): void {
        const l = root.link;
        if (!l.uuid || !name.trim() || name.trim() === l.name)
            return;
        root.run([["nmcli", "connection", "modify", l.uuid, "connection.id", name.trim()]], "Ad değişti");
    }

    // Manual needs an address with its prefix ("192.168.0.50/24"); the
    // connection is brought up again so the change takes effect.
    function saveIp(uuid: string, manual: bool, address: string, gateway: string, dns: string): void {
        const dnsList = dns.split(/[ ,]+/).filter(s => s).join(" ");
        if (manual) {
            if (!/^\d{1,3}(\.\d{1,3}){3}\/\d{1,2}$/.test(address.trim())) {
                root.say("Adres 192.168.0.50/24 biçiminde olmalı", true);
                return;
            }
            root.run([["nmcli", "connection", "modify", uuid, "ipv4.method", "manual", "ipv4.addresses", address.trim(), "ipv4.gateway", gateway.trim(), "ipv4.dns", dnsList], ["nmcli", "connection", "up", uuid]], "IP ayarları kaydedildi");
        } else {
            root.run([["nmcli", "connection", "modify", uuid, "ipv4.method", "auto", "ipv4.addresses", "", "ipv4.gateway", "", "ipv4.dns", dnsList], ["nmcli", "connection", "up", uuid]], "Otomatik IP'ye dönüldü");
        }
    }

    function measurePing(): void {
        if (pinger.running)
            return;
        root.pingBusy = true;
        pinger.running = true;
    }

    function lookupPublicIp(): void {
        if (publicLookup.running)
            return;
        root.publicIpBusy = true;
        publicLookup.running = true;
    }

    // The link with the default route (or the first Ethernet or Wi-Fi device
    // without one), as JSON. nmcli's -g prints one line per field asked.
    Process {
        id: details

        command: ["sh", "-c", `
            dev=$(ip -4 route show default | awk '{for(i=1;i<NF;i++) if($i=="dev"){print $(i+1); exit}}')
            [ -n "$dev" ] || dev=$(nmcli -t -f DEVICE,TYPE dev | awk -F: '$2=="ethernet"||$2=="wifi"{print $1; exit}')
            { IFS= read -r type; IFS= read -r state; IFS= read -r name; IFS= read -r uuid
              IFS= read -r ip; IFS= read -r gw; IFS= read -r dns; } <<EOF
$(nmcli -t -g GENERAL.TYPE,GENERAL.STATE,GENERAL.CONNECTION,GENERAL.CON-UUID,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS dev show "$dev" 2>/dev/null)
EOF
            { IFS= read -r method; IFS= read -r saddr; IFS= read -r sgw; IFS= read -r sdns; IFS= read -r ignore; } <<EOF
$([ -n "$uuid" ] && nmcli -t -g ipv4.method,ipv4.addresses,ipv4.gateway,ipv4.dns,ipv4.ignore-auto-dns con show "$uuid" 2>/dev/null)
EOF
            s=/sys/class/net/$dev
            jq -cn --arg device "$dev" --arg type "$type" --arg state "$state" --arg name "$name" \\
              --arg uuid "$uuid" --arg ip "$ip" --arg gateway "$gw" --arg dns "$dns" \\
              --arg method "$method" --arg savedAddress "$saddr" --arg savedGateway "$sgw" \\
              --arg savedDns "$sdns" --arg ignoreAutoDns "$ignore" \\
              --arg mac "$(cat $s/address 2>/dev/null)" --arg mtu "$(cat $s/mtu 2>/dev/null)" \\
              --arg speed "$(cat $s/speed 2>/dev/null)" \\
              --argjson connections "$(nmcli -t -f UUID,TYPE,NAME con show | jq -R '
                  split(":") | {uuid: .[0], type: .[1], name: (.[2:] | join(":") | gsub("\\\\\\\\"; ""))}
                  | select(.type == "802-3-ethernet" or .type == "802-11-wireless")' | jq -s .)" \\
              '{device: $device, type: $type, state: $state, name: $name, uuid: $uuid,
                ip: $ip, gateway: $gateway, dns: ($dns | gsub(" \\\\| "; ", ")), method: $method,
                savedAddress: $savedAddress, savedGateway: $savedGateway, savedDns: $savedDns,
                ignoreAutoDns: $ignoreAutoDns, mac: ($mac | ascii_upcase), mtu: $mtu, speed: $speed,
                connections: $connections}'
        `]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.connections = d.connections;
                    delete d.connections;
                    root.link = d;
                } catch (e) {
                    console.warn(`net: ${e}`);
                }
            }
        }
    }

    // Traffic: the byte counters of the link's device, sampled each second.
    Process {
        id: counters

        command: ["cat", `/sys/class/net/${root.link.device}/statistics/rx_bytes`, `/sys/class/net/${root.link.device}/statistics/tx_bytes`]

        stdout: StdioCollector {
            onStreamFinished: {
                const [rx, tx] = text.trim().split("\n").map(Number);
                const now = Date.now();
                if (root.lastSample > 0 && rx >= root.rxTotal) {
                    const dt = (now - root.lastSample) / 1000;
                    root.rxRate = (rx - root.rxTotal) / dt;
                    root.txRate = (tx - root.txTotal) / dt;
                }
                root.rxTotal = rx;
                root.txTotal = tx;
                root.lastSample = now;
            }
        }
    }

    Process {
        id: pinger

        command: ["ping", "-c", "5", "-i", "0.2", "-W", "1", "-q", "1.1.1.1"]

        stdout: StdioCollector {
            onStreamFinished: {
                const loss = text.match(/(\d+(?:\.\d+)?)% packet loss/)?.[1];
                const avg = text.match(/= [\d.]+\/([\d.]+)\//)?.[1];
                root.ping = avg ? `${Math.round(Number(avg))} ms · %${loss} kayıp` : "yanıt yok";
                root.pingBusy = false;
            }
        }
    }

    Process {
        id: publicLookup

        command: ["curl", "-s", "--max-time", "5", "https://api.ipify.org"]

        stdout: StdioCollector {
            onStreamFinished: {
                const ip = text.trim();
                root.publicIp = /^[\d.]+$/.test(ip) ? ip : "alınamadı";
                root.publicIpBusy = false;
            }
        }
    }

    Process {
        id: edit

        property string done

        stderr: StdioCollector {
            id: editErr
        }

        onExited: code => {
            root.busy = false;
            if (code === 0)
                root.say(edit.done, false);
            else
                root.say(editErr.text.trim().split("\n").pop().replace(/^Error: /, "") || "Olmadı", true);
            root.refresh();
        }
    }

    Timer {
        running: root.watching
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.link.device)
                counters.running = true;
        }
    }

    Timer {
        running: root.watching
        interval: 4000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        id: statusTimer
        interval: 4000
        onTriggered: root.status = ""
    }

    // Read once at start so the menu opens filled.
    Component.onCompleted: refresh()
}
