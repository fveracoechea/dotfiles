{agentPkgs, inputs, stablePkgsFor}: {lib, config, ...}: let
  cfg = config.dotfiles.coding-agents.web;
  codingAgentSources = {inherit (inputs) herdr hunk operator;};
  codingAgentPackages = import ./packages.nix {inherit inputs; pkgs = agentPkgs;};
  codingAgentMcpPackage = (stablePkgsFor agentPkgs.stdenv.hostPlatform.system).mcp-nixos;
  settings = import ./settings.nix {inherit lib codingAgentMcpPackage;};
  json = (agentPkgs.formats.json {}).generate "opencode-web.json" ({"$schema" = "https://opencode.ai/config.json";} // settings);
  checkedJson = agentPkgs.runCommand "opencode-web-config" {nativeBuildInputs = [agentPkgs.check-jsonschema];} ''
    check-jsonschema --force-filetype=json --schemafile=${agentPkgs.opencode.jsonschema.config} ${json}
    cp ${json} "$out"
  '';
  files = {
    "opencode/opencode.json" = checkedJson;
    "opencode/AGENTS.md" = "${inputs.operator}/agents/AGENTS.md";
    "opencode/plugins/operator.ts" = "${codingAgentPackages.operator}/share/opencode/plugins/operator.ts";
  } // lib.mapAttrs' (name: source: lib.nameValuePair "opencode/skills/${name}" source)
    (import ./skills.nix {inherit lib codingAgentPackages codingAgentSources;});
  configDirectory = agentPkgs.linkFarm "opencode-web-config-directory" (lib.mapAttrsToList (name: path: {inherit name path;}) files);
  start = agentPkgs.writeShellScript "opencode-web-start" ''
    set -eu
    if [ -z "''${OPENCODE_PASSWORD:-}" ]; then
      echo "OPENCODE_PASSWORD must be provisioned in the runtime environment file" >&2
      exit 1
    fi
    mkdir -p "$HOME/workspace"
    cd "$HOME/workspace"
    exec ${lib.getExe agentPkgs.opencode} serve --hostname 127.0.0.1 --port ${toString cfg.port}
  '';
in {
  options.dotfiles.coding-agents.web = {
    enable = lib.mkEnableOption "a dedicated, loopback-only OpenCode web service";
    port = lib.mkOption {type = lib.types.port; default = 4096; description = "Loopback backend port; ingress belongs to the host.";};
    environmentFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/opencode-web.env";
      description = "Root-owned runtime EnvironmentFile containing a nonempty OPENCODE_PASSWORD. Never a Nix store file.";
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = lib.hasPrefix "/" cfg.environmentFile && !(lib.hasPrefix "/nix/store/" cfg.environmentFile);
      message = "OpenCode web authentication must use an absolute runtime environment-file reference outside the Nix store.";
    }];
    users.groups.opencode-web = {};
    users.users.opencode-web = {
      isSystemUser = true;
      group = "opencode-web";
      home = "/var/lib/opencode-web";
    };
    systemd.services.opencode-web = {
      description = "Dedicated OpenCode web agent";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      path = with agentPkgs; [git gh python3 nixd typescript-language-server biome oxfmt lsof codingAgentMcpPackage codingAgentPackages.operator];
      environment = {
        HOME = "/var/lib/opencode-web";
        XDG_CONFIG_HOME = "${configDirectory}";
        XDG_DATA_HOME = "/var/lib/opencode-web/data";
        XDG_CACHE_HOME = "/var/lib/opencode-web/cache";
        XDG_STATE_HOME = "/var/lib/opencode-web/state";
      };
      serviceConfig = {
        User = "opencode-web";
        Group = "opencode-web";
        ExecStart = start;
        EnvironmentFile = cfg.environmentFile;
        StateDirectory = "opencode-web";
        StateDirectoryMode = "0700";
        WorkingDirectory = "/var/lib/opencode-web";
        UMask = "0077";
        Restart = "on-failure";
        RestartSec = 10;
        NoNewPrivileges = true;
        CapabilityBoundingSet = "";
        ProtectHome = true;
        ProtectSystem = "strict";
        PrivateTmp = true;
        PrivateDevices = true;
        RestrictSUIDSGID = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6"];
      };
    };
  };
}
