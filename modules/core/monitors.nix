{lib, ...}: {
  options.dotfiles.monitors = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    description = "Monitor spec strings for the active host (e.g. \"DP-1, 5120x1440@119.98Hz, auto, auto, bitdepth, 8, cm, auto\").";
  };
}
