{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:
let
  upper = (import ../include.nix args);
in
with upper;
upper
// rec {
  pkgs-stable = import inputs.nixpkgs-stable {
    config = config.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
    ];
  };
  pkgs' = import inputs.nixpkgs {
    config = config.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
      inputs.nur.overlays.default
    ];
  };

  pkgs-pin = import inputs.nixpkgs-pin {
    config = config.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
      inputs.nur.overlays.default
    ];
  };
  pkgs-pin2 = import inputs.nixpkgs-pin2 {
    config = config.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
      inputs.nur.overlays.default
    ];
  };
  pkgs-pin3 = import inputs.nixpkgs-pin3 {
    config = config.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
      inputs.nur.overlays.default
    ];
  };
  pkgs-pin4 = import inputs.nixpkgs-pin4 {
    config = config.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
      inputs.nur.overlays.default
      inputs.darwin-emacs.overlays.emacs
    ];
  };
  pkgs-pin5 = import inputs.nixpkgs-pin5 {
    config = config.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
    ];
  };
  pkgs-pin6 = import inputs.nixpkgs-pin6 {
    config = config.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
    ];
  };
  pkgs-pin7 = import inputs.nixpkgs-pin7 {
    config = config.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
    ];
  };
  pkgs-489506 = import inputs.nixpkgs-489506 {
    config = config.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
      inputs.nur.overlays.default
    ];
  };
  pkgs''' = import inputs.nixpkgs-pin2 {
    config = config.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
  };
  pkgs-openclaw = import inputs.nixpkgs {
    config = config.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
      inputs.nix-openclaw.overlays.default
    ];
  };

  octaveGui = pkgs.writeShellScriptBin "octave" ''
    exec "${pkgs.octaveFull}/bin/octave" --gui "$@"
  '';

  pkgs-new = import inputs.nixpkgs-new {
    config = config.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
      inputs.nur.overlays.default
    ];
  };
  pkgs-staging = import inputs.nixpkgs-staging {
    config = config.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
      inputs.nur.overlays.default
    ];
  };
  script = {
    upgrade = pkgs.writeShellScriptBin "upgrade" ''
      set -e
      cd ~/Documents/config/mac
      ${lib.getExe progs.git} config pull.rebase false
      sudo true
      ${lib.getExe progs.git} pull --no-edit
      if [ -d ~/Documents/config-public ]; then
        cd ~/Documents/config-public/mac
        ${lib.getExe progs.git} config pull.rebase false
        ${lib.getExe progs.git} pull --no-edit
        ${lib.getExe config.nix.package} flake update
        ${lib.getExe progs.git} add flake.lock
        ${lib.getExe progs.git} commit -m "mac: lockup" || true
        ${lib.getExe progs.git} push
        cd ~/Documents/config/mac
        ${lib.getExe progs.git} pull --no-edit https://github.com/mio-19/config-public.git
      else
        ${lib.getExe progs.git} pull --no-edit https://github.com/mio-19/config-public.git
        ${lib.getExe config.nix.package} flake update
        ${lib.getExe progs.git} add flake.lock
        ${lib.getExe progs.git} commit -m "mac: lockup" || true
      fi
      ${lib.getExe progs.git} push &
      sudo nice -n 20 darwin-rebuild switch --flake ~/Documents/config/mac --print-build-logs "$@" |& ${lib.getExe pkgs.nix-output-monitor}
      brew upgrade; brew cu -af; brew cleanup --prune=all
    '';
    switch = pkgs.writeShellScriptBin "swit" ''
      set -e
      cd ~/Documents/config/mac
      ${lib.getExe progs.git} config pull.rebase false
      sudo true
      ${lib.getExe progs.git} -c http.lowSpeedLimit=10000 -c http.lowSpeedTime=10 -c core.sshCommand="ssh -o ConnectTimeout=15" pull --no-edit || true
      ${lib.getExe progs.git} -c http.lowSpeedLimit=10000 -c http.lowSpeedTime=10 -c core.sshCommand="ssh -o ConnectTimeout=15" pull --no-edit https://github.com/mio-19/config-public.git || true
      ${lib.getExe progs.git} push &
      sudo nice -n 20 darwin-rebuild switch --flake ~/Documents/config/mac --print-build-logs "$@" |& ${lib.getExe pkgs.nix-output-monitor}
    '';
  };
  x86_64-darwin = (pkgs.stdenv.isx86_64 && pkgs.stdenv.isDarwin);
  mac-app-util-enabled = !x86_64-darwin;
}
