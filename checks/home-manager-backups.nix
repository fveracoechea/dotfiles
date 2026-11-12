{
  pkgs,
  desktop,
}: let
  home = desktop.home-manager.users.fveracoechea;
  environment = desktop.systemd.services.home-manager-fveracoechea.environment;
in
  pkgs.runCommand "home-manager-backups" {
    nativeBuildInputs = [pkgs.gettext];
    HOME_MANAGER_BACKUP_COMMAND = environment.HOME_MANAGER_BACKUP_COMMAND or "";
    HOME_MANAGER_BACKUP_EXT = environment.HOME_MANAGER_BACKUP_EXT or "";
    HOME_MANAGER_BACKUP_OVERWRITE = environment.HOME_MANAGER_BACKUP_OVERWRITE or "";
  } ''
    ${home.lib.bash.initHomeManagerLib}
    export HOME="$TMPDIR/home with spaces"
    newGenPath="$TMPDIR/generation"
    mkdir -p "$HOME/.config/opencode" "$newGenPath/home-files/.config/opencode"
    target="$HOME/.config/opencode/cli.json"
    source="$newGenPath/home-files/.config/opencode/cli.json"
    printf 'managed\n' > "$source"
    printf 'original backup\n' > "$target.hm-backup"
    printf 'first edit\n' > "$target"

    ${home.home.activation.checkLinkTargets.data}
    ${home.home.activation.linkGeneration.data}

    test -L "$target"
    test "$(cat "$target")" = managed
    test "$(cat "$target.hm-backup")" = 'first edit'
    test "$(cat "$target.hm-backup.~1~")" = 'original backup'

    rm "$target"
    printf 'second edit\n' > "$target"

    checkNewGenCollision
    linkNewGen

    test -L "$target"
    test "$(cat "$target")" = managed
    test "$(cat "$target.hm-backup")" = 'second edit'
    test "$(cat "$target.hm-backup.~1~")" = 'original backup'
    test "$(cat "$target.hm-backup.~2~")" = 'first edit'
    touch "$out"
  ''
