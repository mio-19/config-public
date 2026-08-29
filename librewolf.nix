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
        {
          extraPrefs = (old.extraPrefs or "") + librewolf_customize_prefs;
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
