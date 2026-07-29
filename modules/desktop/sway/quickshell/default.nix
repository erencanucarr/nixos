{ pkgs, ... }:
let
  waitForSockets = pkgs.writeShellScript "quickshell-wait-sockets" ''
    n=0
    while [ ! -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]; do
      n=$((n + 1)); [ "$n" -ge 100 ] && exit 1
      ${pkgs.coreutils}/bin/sleep 0.1
    done

    n=0
    while [ "$n" -lt 100 ]; do
      sock=$(${pkgs.coreutils}/bin/ls -t "$XDG_RUNTIME_DIR"/sway-ipc.*.sock 2>/dev/null | ${pkgs.coreutils}/bin/head -n1)
      if [ -n "$sock" ] && [ -S "$sock" ]; then
        ${pkgs.systemd}/bin/systemctl --user set-environment SWAYSOCK="$sock"
        break
      fi
      n=$((n + 1))
      ${pkgs.coreutils}/bin/sleep 0.1
    done
    exit 0
  '';
in
{
  programs.quickshell = {
    enable = true;
    configs.default = ./config;
    activeConfig = "default";
    systemd.enable = true;
  };

  systemd.user.services.quickshell = {
    Unit = {
      After = [ "sway-session.target" ];
      PartOf = [ "sway-session.target" ];
      StartLimitIntervalSec = 0;
    };

    Service = {
      Environment = [
        "QT_QPA_PLATFORM=wayland"
        "WAYLAND_DISPLAY=wayland-1"
      ];

      ExecStartPre = "${waitForSockets}";

      RestartSec = 1;
    };
  };
}
