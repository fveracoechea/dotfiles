{
  lib,
  config,
  ...
}:
{
  options.dotfiles.crash-capture.enable = lib.mkEnableOption "ramoops-backed pstore for capturing kernel panic logs across reboots";

  config = lib.mkIf config.dotfiles.crash-capture.enable {
    boot.kernelParams = [
      # Reserve 8MB of physical RAM at 0x30000000 for ramoops
      "memmap=8M\$0x30000000"
      "ramoops.mem_address=0x30000000"
      "ramoops.mem_size=0x800000"
      "ramoops.record_size=0x20000"
      "ramoops.console_size=0x200000"
      "ramoops.pmsg_size=0x40000"
      "ramoops.dump_oops=1"
      "ramoops.ecc=1"
      "pstore.backend=ramoops"
      # Reboot automatically 10s after a panic instead of hanging forever
      "panic=10"
    ];
  };
}
