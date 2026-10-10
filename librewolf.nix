# Shared declarative LibreWolf configuration for NixOS and nix-darwin.
{
  config,
  inputs,
  lib,
  pkgs,
  librewolfPkgs,
}:
let
  mio = inputs.mio.packages.${pkgs.stdenv.hostPlatform.system};

  firefoxAddonAsNixExtension =
    pkg:
    let
      extid =
        pkg.extid or (pkg.passthru or { }).extid
          or (lib.throw "firefox addon ${lib.getName pkg} is missing extid");
    in
    pkg
    // {
      inherit extid;
    };

  librewolf_extension_packages =
    (with mio; [
      audio-equalizer-firefox
      bitwarden-extension
      dark-reader
      floccus-firefox
      sponsorblock-for-youtube-firefox
      ublock-origin-firefox
      unhook-firefox
      wayback-machine-extension
      yt-mirror-firefox
    ])
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      mio.plasma-integration-firefox
    ];

  librewolf_nix_extensions = map firefoxAddonAsNixExtension librewolf_extension_packages;

  librewolf_declarative_extension_args_for =
    old:
    lib.optionalAttrs
      ((config.librewolf_declarative_extensions or true) && librewolf_nix_extensions != [ ])
      {
        nixExtensions = (old.nixExtensions or [ ]) ++ librewolf_nix_extensions;
      };

  librewolf_declarative_extension_args = librewolf_declarative_extension_args_for { };

  librewolf_customize_prefs = ''
    // Don't remove data on exit
    pref("privacy.sanitize.sanitizeOnShutdown", false);
    pref("privacy.clearOnShutdown.history", false);
    pref("privacy.clearOnShutdown.cookies", false);
    pref("privacy.clearOnShutdown.sessions", false);
    pref("privacy.clearOnShutdown.cache", false);
    pref("privacy.clearOnShutdown.downloads", false);
    pref("privacy.clearOnShutdown.formdata", false);
    pref("privacy.clearOnShutdown.offlineApps", false);
    pref("privacy.clearOnShutdown.siteSettings", false);
  ''
  + ''
    // Websites that process the picked picture client-side through <canvas>
    // (preview, resize/crop, EXIF rotation, thumbnail or checksum) get poisoned
    // canvas data under LibreWolf's default Resist Fingerprinting: pixel
    // readback returns noise and toDataURL()/toBlob() emit a noise image, so
    // the upload fails validation or uploads a blank picture.
    // Exempting a site disables RFP for that site only; the rest of the browser
    // keeps it. Verified on librewolf-157.0-1: for an exempted host canvas
    // readback returns the real pixels again, without the exemption it is noise.
    // Both the bare domain and *.domain are listed: which form covers
    // subdomains (www.ebay.com) is not worth relying on, and an extra entry is
    // harmless. Add/remove sites here. Needs a browser restart; mozilla.cfg
    // re-applies this at every startup, so edit it here and not in about:config.
    // https://librewolf.net/docs/faq/
    pref(
      "privacy.resistFingerprinting.exemptedDomains",
      "*.example.invalid,ebay.com,*.ebay.com,amazon.com,*.amazon.com,etsy.com,*.etsy.com,"
      + "vinted.com,*.vinted.com,facebook.com,*.facebook.com,instagram.com,*.instagram.com,"
      + "reddit.com,*.reddit.com,x.com,*.x.com,whatsapp.com,*.whatsapp.com"
    );
  ''
  + lib.optionalString ((config.middle_click_scroll or "off") == "browsers") ''
    // Firefox/LibreWolf: Settings → General → Browsing → "Use autoscrolling"
    // https://support.mozilla.org/kb/mouse-shortcuts-perform-common-tasks
    // LibreWolf "Enable Autoscroll safely":
    // https://librewolf.net/docs/settings/
    pref("middlemouse.paste", false);
    pref("general.autoScroll", true);
  '';

  package =
    (if config.use_librewolf_bin then librewolfPkgs.librewolf-bin else librewolfPkgs.librewolf).override
      (
        old:
        let
          oldPolicies = old.extraPolicies or { };
          oldSearchEngines = oldPolicies.SearchEngines or { };
          oldAdd = oldSearchEngines.Add or [ ];
        in
        {
          extraPrefs = (old.extraPrefs or "") + librewolf_customize_prefs;
          extraPolicies = oldPolicies // {
            SearchEngines = oldSearchEngines // {
              Default = "Google";
              Add = oldAdd ++ [
                {
                  Name = "Google";
                  URLTemplate = "https://www.google.com/search?q={searchTerms}";
                  Method = "GET";
                  Alias = "@g";
                }
              ];
            };
          };
        }
        // librewolf_declarative_extension_args_for old
      );
in
{
  inherit
    firefoxAddonAsNixExtension
    librewolf_extension_packages
    librewolf_nix_extensions
    librewolf_declarative_extension_args_for
    librewolf_declarative_extension_args
    librewolf_customize_prefs
    package
    ;
}
