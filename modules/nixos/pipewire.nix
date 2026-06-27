{
  inputs,
  lib,
  config,
  ...
}: let
  hasMusnix = inputs ? musnix;
in {
  imports = lib.optional hasMusnix inputs.musnix.nixosModules.musnix;

  options.dotfiles.pipewire.enable = lib.mkEnableOption "PipeWire audio (with musnix)";

  config = lib.mkIf config.dotfiles.pipewire.enable {
    # Realtime scheduling priority for audio (required by PipeWire)
    security.rtkit.enable = true;

    # Enable audio with PipeWire
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    # PipeWire requires this to be false
    services.pulseaudio.enable = false;

    # Enable musnix, a module for real-time audio.
    musnix.enable = lib.mkIf hasMusnix true;
  };
}
