{
  lib,
  config,
  ...
}: {
  options.dotfiles.misc.enable = lib.mkEnableOption "miscellaneous NixOS services (fwupd, flatpak, firefox, printing, rtkit, gvfs, udev)";

  config = lib.mkIf config.dotfiles.misc.enable {
    # allows to update some devices' firmware, including UEFI for several machines.
    services.fwupd.enable = true;

    # Enable flatpak
    services.flatpak.enable = true;

    # Install firefox.
    programs.firefox.enable = true;

    # Enable CUPS to print documents.
    services.printing.enable = true;

    # Realtime scheduling priority to user processes on demand.
    # For example, the PulseAudio server uses this to acquire realtime priority.
    security.rtkit.enable = true;

    # Enable GVFS for virtual file system support (e.g., Trash can).
    services.gvfs.enable = true;

    # udev rule for Kinesis Advantage360 Pro serial access (idVendor 29ea)
    services.udev.extraRules = ''
      ATTRS{idVendor}=="29ea", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    '';
  };
}
