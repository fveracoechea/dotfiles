{
  lib,
  config,
  pkgs,
  ...
}: {
  options.dotfiles.handy.enable = lib.mkEnableOption "Handy speech-to-text application";

  config = lib.mkIf config.dotfiles.handy.enable {
    home.packages = [pkgs.handy];

    home.activation.configureHandy = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run ${pkgs.bash}/bin/bash -c ${lib.escapeShellArg ''
        set -euo pipefail

        settings_file=${lib.escapeShellArg "${config.xdg.dataHome}/com.pais.handy/settings_store.json"}
        ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$settings_file")"
        settings_input="$settings_file"
        if [ ! -f "$settings_input" ]; then
          settings_input=/dev/null
        fi

        temporary_file=$(${pkgs.coreutils}/bin/mktemp "$settings_file.XXXXXX")
        trap '${pkgs.coreutils}/bin/rm -f "$temporary_file"' EXIT

        ${pkgs.jq}/bin/jq -s '
          (.[0] // {})
          | .settings.push_to_talk = true
          | .settings.bindings.transcribe = (
              (.settings.bindings.transcribe // {
                id: "transcribe",
                name: "Transcribe",
                description: "Converts your speech into text.",
                default_binding: "ctrl+space"
              }) + {current_binding: "alt+space"}
            )
        ' "$settings_input" > "$temporary_file"

        ${pkgs.coreutils}/bin/mv "$temporary_file" "$settings_file"
      ''}
    '';
  };
}
