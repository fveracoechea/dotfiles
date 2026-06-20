{
  inputs,
  lib,
  config,
  ...
}: {
  imports = [
    inputs.musnix.nixosModules.musnix
  ];

  options.dotfiles.pipewire.enable = lib.mkEnableOption "PipeWire audio (with musnix)";

  config = lib.mkIf config.dotfiles.pipewire.enable {
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
    musnix.enable = true;
  };
}
