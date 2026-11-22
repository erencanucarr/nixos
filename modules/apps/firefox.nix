{ ... }:
let
  black = "{9b84b6b4-07c4-4b4b-ba21-394d86f6e9ee}";
in
{
  programs.firefox.policies = {
    ExtensionSettings.${black} = {
      installation_mode = "normal_installed";
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/black21/latest.xpi";
    };
    Preferences."extensions.activeThemeID" = {
      Value = black;
      Status = "default";
    };
  };
}
