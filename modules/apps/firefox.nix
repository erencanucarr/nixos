{ lib, ... }:
let
  black = "{9b84b6b4-07c4-4b4b-ba21-394d86f6e9ee}";
  amo = slug: "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
  addon =
    slug: extra:
    {
      installation_mode = "normal_installed";
      install_url = amo slug;
    }
    // extra;
  default = value: {
    Value = value;
    Status = "default";
  };
in
{
  programs.firefox.enable = true;

  programs.firefox.policies = {
    ExtensionSettings = {
      ${black} = addon "black21" { };
      "uBlock0@raymondhill.net" = addon "ublock-origin" { default_area = "navbar"; };
      "{446900e4-71c2-419f-a6a7-df9c091e268b}" = addon "bitwarden-password-manager" {
        default_area = "navbar";
      };
    };

    DisableTelemetry = true;
    DisableFirefoxStudies = true;
    DisablePocket = true;
    DontCheckDefaultBrowser = true;
    NoDefaultBookmarks = true;
    OverrideFirstRunPage = "";
    OverridePostUpdatePage = "";

    PasswordManagerEnabled = false;
    OfferToSaveLogins = false;
    AutofillCreditCardEnabled = false;

    DNSOverHTTPS = {
      Enabled = false;
      Locked = false;
    };

    EnableTrackingProtection = {
      Value = true;
      Cryptomining = true;
      Fingerprinting = true;
      EmailTracking = true;
    };

    FirefoxHome = {
      SponsoredTopSites = false;
      SponsoredStories = false;
      Stories = false;
    };
    FirefoxSuggest = {
      SponsoredSuggestions = false;
      ImproveSuggest = false;
    };
    UserMessaging = {
      ExtensionRecommendations = false;
      FeatureRecommendations = false;
      SkipOnboarding = true;
      MoreFromMozilla = false;
    };

    Preferences = lib.mapAttrs (_: default) {
      "extensions.activeThemeID" = black;
      "sidebar.revamp" = true;
      "sidebar.verticalTabs" = true;
      "browser.tabs.closeWindowWithLastTab" = false;
      "browser.aboutConfig.showWarning" = false;
      "browser.download.useDownloadDir" = true;
      "browser.urlbar.trimHttps" = true;
      "browser.newtabpage.activity-stream.showSponsored" = false;
      "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
    };
  };
}
