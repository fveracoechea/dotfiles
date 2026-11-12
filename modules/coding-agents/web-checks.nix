{lib, pkgs, homelab, desktop}: let
  c = homelab.config;
  service = c.systemd.services.opencode-web;
  user = c.users.users.opencode-web;
  proxy = c.services.caddy.virtualHosts."opencode.veracoechea.com".extraConfig;
  proxyFixture = pkgs.writeText "opencode-web.Caddyfile" ''
    {
      admin off
      auto_https off
    }
    https://opencode.veracoechea.com {
      ${proxy}
    }
  '';
in {
  coding-agents-web = assert lib.assertMsg (
    c.dotfiles.coding-agents.web.enable
    && !desktop.config.dotfiles.coding-agents.web.enable
    && !(desktop.config.systemd.services ? opencode-web)
    && user.isSystemUser && !user.isNormalUser
    && user.extraGroups == []
    && user.openssh.authorizedKeys.keys == []
    && user.home == "/var/lib/opencode-web"
    && service.serviceConfig.User == "opencode-web"
    && service.serviceConfig.Group == "opencode-web"
    && service.serviceConfig.NoNewPrivileges
    && service.serviceConfig.ProtectHome
    && service.serviceConfig.ProtectSystem == "strict"
    && service.serviceConfig.StateDirectoryMode == "0700"
    && service.serviceConfig.EnvironmentFile == "/var/lib/opencode-web.env"
    && !(builtins.elem "opencode-web" c.nix.settings.trusted-users)
    && !(builtins.elem "@opencode-web" c.nix.settings.trusted-users)
  ) "coding-agents: web identity or isolation changed";
    pkgs.runCommand "coding-agents-web-check" {nativeBuildInputs = [pkgs.caddy pkgs.python3];} ''
      set -eu
      if env -i ${service.serviceConfig.ExecStart} > missing-password.log 2>&1; then
        echo "Service accepted a missing password" >&2
        exit 1
      fi
      grep -q 'OPENCODE_PASSWORD must be provisioned' missing-password.log
      caddy adapt --config ${proxyFixture} --adapter caddyfile > proxy.json
      python3 ${./web-check.py} proxy.json
      test -s ${service.environment.XDG_CONFIG_HOME}/opencode/opencode.json
      test -s ${service.environment.XDG_CONFIG_HOME}/opencode/AGENTS.md
      test -s ${service.environment.XDG_CONFIG_HOME}/opencode/skills/herdr/SKILL.md
      test -s ${service.environment.XDG_CONFIG_HOME}/opencode/plugins/operator.ts
      touch "$out"
    '';
}
