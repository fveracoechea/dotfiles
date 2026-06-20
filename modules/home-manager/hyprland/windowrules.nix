# inspired by omarchy's defaults
# https://github.com/basecamp/omarchy/blob/master/default/hypr/apps/system.conf
{
  lib,
  config,
  ...
}: let
  floatingClasses = builtins.concatStringsSep "|" [
    "blueberry.py"
    "Impala"
    "Wiremix"
    "org.gnome.NautilusPreviewer"
    "com.gabm.satty"
    "TUI.float"
    "imv"
    "mpv"
  ];

  floatingTitleMatches = builtins.concatStringsSep "|" [
    "Open.*Files?"
    "Open [F|f]older.*"
    "Save.*Files?"
    "Save.*As"
    "Save"
    "All Files"
    ".*wants to [open|save].*"
    "[C|c]hoose.*"
  ];

  floatingClassesWithTitle = builtins.concatStringsSep "|" [
    "xdg-desktop-portal-gtk"
    "DesktopEditors"
    "org.gnome.Nautilus"
  ];
in {
  config = lib.mkIf config.dotfiles.hyprland.enable {
    wayland.windowManager.hyprland.settings.windowrule = [
      "float on, match:tag floating-window"
      "center on, match:tag floating-window"
      "size 1024 768, match:tag floating-window"

      "tag +floating-window, match:class (${floatingClasses})"
      "tag +floating-window, match:class (${floatingClassesWithTitle}), match:title ^(${floatingTitleMatches})"
      "float on, match:class org.gnome.Calculator"

      "border_size 0, match:fullscreen 1"
      "idle_inhibit fullscreen, match:class .*"
      "suppress_event maximize, match:class .*"
    ];
  };
}
