{ config, pkgs, plasma-manager, stylix, ... }:
let
  vesktop-wrapped = pkgs.writeShellScriptBin "vesktop" ''
    export HTTP_PROXY="http://127.0.0.1:4452"
    export HTTPS_PROXY="http://127.0.0.1:4452"
    exec ${pkgs.vesktop}/bin/vesktop "$@"
  '';
in
{
  imports = [
    plasma-manager.homeModules.plasma-manager
  ];
  home = {
    username = "can";
    homeDirectory = "/home/can";
    stateVersion = "26.05";
  };
  programs.home-manager.enable = true;
  gtk.gtk2.force = true;
  home.packages = with pkgs; [
    vesktop-wrapped
    grim slurp wl-clipboard
    libnotify
    jetbrains-mono
    nerd-fonts.jetbrains-mono
  ];
  home.sessionVariables = {
    XDG_CURRENT_DESKTOP = "KDE";
    XDG_SESSION_TYPE = "wayland";
    QT_QPA_PLATFORM = "wayland;xcb";
    NIXOS_OZONE_WL = "1";
  };
  programs.plasma = {
    enable = true;
    shortcuts = {
      "kwin" = {
        "Switch One Desktop to the Left" = "Ctrl+Left";
        "Switch One Desktop to the Right" = "Ctrl+Right";
        "Window to Previous Desktop" = "Ctrl+Shift+Left";
        "Window to Next Desktop" = "Ctrl+Shift+Right";
      };
    };
    panels = [
      {
        location = "bottom";
        height = 44;
        widgets = [
          "org.kde.plasma.kickoff"
          "org.kde.plasma.pager"
          { panelSpacer = { expanding = true; }; }
          {
            iconTasks = {
              settings = {
                General = {
                  useCustomStyle = true;
                  customIconStyle = 2;
                };
              };
            };
          }
          { panelSpacer = { expanding = true; }; }
          "org.kde.plasma.marginsseparator"
          "org.kde.plasma.systemtray"
          "org.kde.plasma.digitalclock"
          "org.kde.plasma.showdesktop"
        ];
      }
    ];
  };
}
