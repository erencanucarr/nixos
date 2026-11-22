pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

Singleton {
    id: root

    property bool watching: false

    property string state: ""
    property var self: ({})
    property var peers: []
    property var services: []
    property string tailnet: ""
    property string suffix: ""
    property string exitNode: ""
    property var health: []

    property string status: ""
    property bool statusError: false
    property bool busy: false
    property bool probing: false

    readonly property bool running: state === "Running"
    readonly property bool needsLogin: state === "NeedsLogin" || state === "NeedsMachineAuth"
    readonly property int onlineCount: peers.filter(p => p.online).length
    readonly property var exitNodes: peers.filter(p => p.exitOption)
    readonly property int servicesUp: services.filter(s => s.reachable).length

    function shortName(dns: string, host: string): string {
        const first = (dns ?? "").split(".")[0];
        return first || host || "?";
    }

    function ago(iso: string): string {
        const t = Date.parse(iso ?? "");
        if (!t || t < 86400000)
            return "";
        const s = Math.max(0, (Date.now() - t) / 1000);
        if (s < 3600)
            return `${Math.max(1, Math.round(s / 60))} dk önce`;
        if (s < 86400)
            return `${Math.round(s / 3600)} sa önce`;
        return `${Math.round(s / 86400)} gün önce`;
    }

    function osName(os: string): string {
        const m = { linux: "Linux", windows: "Windows", macOS: "macOS", iOS: "iOS", android: "Android", freebsd: "FreeBSD" };
        return m[os] ?? os ?? "";
    }

    function parse(text: string): void {
        let j;
        try {
            j = JSON.parse(text);
        } catch (e) {
            root.state = "NoState";
            return;
        }
        root.state = j.BackendState ?? "";
        root.tailnet = j.CurrentTailnet?.Name ?? "";
        root.suffix = j.CurrentTailnet?.MagicDNSSuffix ?? j.MagicDNSSuffix ?? "";
        root.health = j.Health ?? [];

        const s = j.Self ?? {};
        root.self = {
            name: root.shortName(s.DNSName, s.HostName),
            dns: (s.DNSName ?? "").replace(/\.$/, ""),
            ip4: (s.TailscaleIPs ?? []).find(a => !a.includes(":")) ?? "",
            ip6: (s.TailscaleIPs ?? []).find(a => a.includes(":")) ?? "",
            os: root.osName(s.OS)
        };

        const list = Object.values(j.Peer ?? {}).map(p => ({
            id: p.ID ?? p.PublicKey,
            name: root.shortName(p.DNSName, p.HostName),
            dns: (p.DNSName ?? "").replace(/\.$/, ""),
            ip4: (p.TailscaleIPs ?? []).find(a => !a.includes(":")) ?? "",
            os: root.osName(p.OS),
            online: !!p.Online,
            active: !!p.Active,
            direct: !!p.CurAddr,
            relay: p.Relay ?? "",
            seen: root.ago(p.LastSeen),
            exitOption: !!p.ExitNodeOption,
            exitActive: !!p.ExitNode,
            routes: p.PrimaryRoutes ?? []
        }));
        list.sort((a, b) => b.online - a.online || a.name.localeCompare(b.name));
        root.peers = list;
        root.exitNode = list.find(p => p.exitActive)?.name ?? "";

        const found = {};
        const caps = s.CapMap ?? {};
        for (const key of Object.keys(caps)) {
            if (!key.startsWith("services/") || !Array.isArray(caps[key]))
                continue;
            for (const e of caps[key]) {
                if (!e || !(e.Ports ?? []).includes("tcp:443"))
                    continue;
                const name = String(e.Name ?? "").replace(/^svc:/, "");
                if (!/^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$/i.test(name) || !root.suffix)
                    continue;
                const addrs = (e.Addrs ?? []).map(a => a + (a.includes(":") ? "/128" : "/32"));
                const host = list.find(p => p.routes.some(r => addrs.includes(r)));
                const old = root.services.find(x => x.name === name);
                found[name] = {
                    name,
                    url: `https://${name}.${root.suffix}/`,
                    host: host?.name ?? "",
                    code: old?.code ?? -1,
                    ms: old?.ms ?? 0,
                    reachable: old?.reachable ?? false
                };
            }
        }
        root.services = Object.values(found).sort((a, b) => a.name.localeCompare(b.name));
    }

    function refresh(): void {
        if (!reader.running)
            reader.running = true;
    }

    function probe(): void {
        if (root.probing || root.services.length === 0)
            return;
        root.probing = true;
        prober.exec(["sh", "-c", `for u in "$@"; do (
            r=$(curl --disable -s -o /dev/null --noproxy '*' --proto =https --connect-timeout 2 --max-time 5 -w '%{http_code} %{time_total}' --url "$u") || r="0 0"
            printf '%s %s\\n' "$u" "$r" ) &
        done; wait`, "sh", ...root.services.map(s => s.url)]);
    }

    function run(args: var, done: string): void {
        if (root.busy)
            return;
        root.busy = true;
        root.status = "";
        action.done = done;
        action.exec(["tailscale", ...args]);
    }

    function setUp(on: bool): void {
        if (on && root.needsLogin)
            return root.login();
        root.run([on ? "up" : "down"], on ? "Bağlandı" : "Bağlantı kesildi");
    }

    function login(): void {
        if (loginProc.running)
            return;
        root.status = "Tarayıcıda giriş sayfası açılıyor…";
        root.statusError = false;
        loginProc.opened = false;
        loginProc.denied = false;
        loginProc.running = true;
    }

    function useExit(name: string): void {
        root.run(["set", `--exit-node=${name}`], name ? `Çıkış düğümü: ${name}` : "Çıkış düğümü kapatıldı");
    }

    function copy(text: string): void {
        if (!text)
            return;
        Quickshell.execDetached(["wl-copy", text]);
        root.status = `Kopyalandı: ${text}`;
        root.statusError = false;
        clear.restart();
    }

    IpcHandler {
        target: "tailscale"

        function menu(): void {
            Panels.togglePopup("tailscale", Panels.focusedScreen());
        }

        function up(): void {
            root.setUp(true);
        }

        function down(): void {
            root.setUp(false);
        }
    }

    Component.onCompleted: refresh()
    onWatchingChanged: if (watching) {
        refresh();
        probe();
    }

    Timer {
        interval: root.watching ? 4000 : 30000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        interval: 60000
        running: root.watching
        repeat: true
        onTriggered: root.probe()
    }

    Timer {
        id: clear

        interval: 3000
        onTriggered: root.status = ""
    }

    Process {
        id: reader

        command: ["tailscale", "status", "--json"]
        stdout: StdioCollector {
            onStreamFinished: if (text)
                root.parse(text)
        }
        onExited: code => {
            if (code !== 0 && code !== 1)
                root.state = "NoState";
        }
    }

    Process {
        id: prober

        stdout: StdioCollector {
            onStreamFinished: {
                const res = {};
                for (const line of text.split("\n")) {
                    const [u, code, t] = line.split(" ");
                    if (u)
                        res[u] = { code: Number(code) || 0, ms: Math.round(Number(t) * 1000) || 0 };
                }
                root.services = root.services.map(s => {
                    const r = res[s.url];
                    return r ? Object.assign({}, s, { code: r.code, ms: r.ms, reachable: r.code >= 100 && r.code < 500 }) : s;
                });
                root.probing = false;
            }
        }
    }

    Process {
        id: action

        property string done

        stderr: StdioCollector {
            id: actionErr
        }
        onExited: code => {
            root.busy = false;
            root.statusError = code !== 0;
            root.status = code === 0 ? action.done : (actionErr.text.trim().split("\n")[0] || "İşlem başarısız");
            if (code === 0)
                clear.restart();
            root.refresh();
        }
    }

    Process {
        id: loginProc

        property bool opened: false
        property bool denied: false

        function scan(data: string): void {
            if (data.includes("Access denied"))
                loginProc.denied = true;
            const m = /https:\/\/login\.tailscale\.com\/\S+/.exec(data);
            if (m && !loginProc.opened) {
                loginProc.opened = true;
                Qt.openUrlExternally(m[0]);
                root.status = "Tarayıcıda girişi onayla";
            }
        }

        command: ["tailscale", "login"]
        stdout: SplitParser {
            onRead: data => loginProc.scan(data)
        }
        stderr: SplitParser {
            onRead: data => loginProc.scan(data)
        }
        onExited: code => {
            root.statusError = code !== 0;
            root.status = code === 0 ? "Giriş yapıldı" : loginProc.denied ? "Yetki yok. İlk giriş için bir kez terminalde: sudo tailscale up --operator=$USER" : "Giriş tamamlanmadı";
            clear.restart();
            root.refresh();
        }
    }
}
