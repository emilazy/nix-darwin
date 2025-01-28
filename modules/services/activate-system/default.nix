{ config, lib, pkgs, ... }:

let
  activationPath =
    lib.makeBinPath [
      pkgs.gnugrep
      pkgs.coreutils
    ]
    + ":"
    +
      lib.replaceStrings [ "/run/current-system" ] [ "$(cat ${config.system.profile}/systemConfig)" ]
        config.environment.systemPath;
in

{
  imports = [
    (lib.mkRemovedOptionModule [ "services" "activate-system" "enable" ] "The `activate-system` service is now always enabled as it is necessary for a working `nix-darwin` setup.")
  ];

  config = {
    launchd.daemons.activate-system = {
      script = ''
        set -e
        set -o pipefail

        export PATH="${activationPath}"

        systemConfig=$(cat ${config.system.profile}/systemConfig)

        # Make this configuration the current configuration.
        # The readlink is there to ensure that when $systemConfig = /system
        # (which is a symlink to the store), /run/current-system is still
        # used as a garbage collection root.
        ln -sfn $(cat ${config.system.profile}/systemConfig) /run/current-system

        # Prevent the current configuration from being garbage-collected.
        ln -sfn /run/current-system /nix/var/nix/gcroots/current-system

        ${config.system.activationScripts.etcChecks.text}
        ${config.system.activationScripts.etc.text}
        ${config.system.activationScripts.keyboard.text}
      '';
      serviceConfig.RunAtLoad = true;
    };
  };
}
