{
  lib,
  config,
  ...
}: {
  options.dotfiles.timezone.enable = lib.mkEnableOption "timezone and locale";

  config = lib.mkIf config.dotfiles.timezone.enable {
    time.timeZone = "America/New_York";

    i18n = let
      locale = "en_US.UTF-8";
    in {
      defaultLocale = locale;
      extraLocaleSettings = {
        LC_ADDRESS = locale;
        LC_IDENTIFICATION = locale;
        LC_MEASUREMENT = locale;
        LC_MONETARY = locale;
        LC_NAME = locale;
        LC_NUMERIC = locale;
        LC_PAPER = locale;
        LC_TELEPHONE = locale;
        LC_TIME = locale;
        LC_MESSAGES = locale;
      };
    };
  };
}
