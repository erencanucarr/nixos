# Firefox's look, part of the system: the "Black" theme (addons.mozilla.org,
# black21) is installed by Firefox itself on its first run, through an
# enterprise policy, and is the default theme of every new profile.
# "normal_installed": it can be switched off in about:addons, not removed.
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
    # A default, not a lock: picking another theme still sticks.
    Preferences."extensions.activeThemeID" = {
      Value = black;
      Status = "default";
    };
  };
}
