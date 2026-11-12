{
  lib,
  pkgs,
  homelab,
  desktop,
}: let
  c = homelab.config;
  service = c.systemd.services.opencode-web;
  user = c.users.users.opencode-web;
  identity = {
    inherit user service;
    groups = c.users.groups;
    trustedUsers = c.nix.settings.trusted-users;
    sudoRules = c.security.sudo.extraRules;
  };
  isolated = {
    user,
    service,
    groups,
    trustedUsers,
    sudoRules,
  }: let
    s = service.serviceConfig;
  in
    user.isSystemUser
    && !user.isNormalUser
    && user.name == "opencode-web"
    && user.uid != 0
    && user.group == "opencode-web"
    && groups.opencode-web.gid != 0
    && user.extraGroups == []
    && user.openssh.authorizedKeys.keys == []
    && user.openssh.authorizedKeys.keyFiles == []
    && user.home == "/var/lib/opencode-web"
    && builtins.all (group: !(builtins.elem "opencode-web" group.members)) (builtins.attrValues groups)
    && builtins.all (name: !(builtins.elem name trustedUsers)) ["opencode-web" "@opencode-web" "*"]
    && builtins.all (rule:
      !(builtins.any (name: builtins.elem name rule.users) ["opencode-web" "ALL"])
      && !(builtins.any (name: builtins.elem name rule.groups) ["opencode-web" "ALL"]))
    sudoRules
    && s.User == "opencode-web"
    && s.Group == "opencode-web"
    && (s.SupplementaryGroups or []) == []
    && s.NoNewPrivileges
    && s.ProtectHome
    && s.ProtectSystem == "strict"
    && s.CapabilityBoundingSet == ""
    && s.RestrictSUIDSGID
    && s.PrivateTmp
    && s.PrivateDevices
    && service.confinement.enable
    && !service.confinement.fullUnit
    && service.confinement.mode == "full-apivfs"
    && s.RootDirectory == "/run/confinement/%n"
    && s.StateDirectory == "opencode-web"
    && s.StateDirectoryMode == "0700"
    && s.WorkingDirectory == "/var/lib/opencode-web"
    && s.UMask == "0077"
    && s.EnvironmentFile == "/var/lib/opencode-web.env"
    && service.unitConfig.ConditionPathExists == s.EnvironmentFile
    && (s.ReadWritePaths or []) == []
    && (s.BindPaths or []) == []
    && builtins.length s.BindReadOnlyPaths == 6
    && lib.take 4 s.BindReadOnlyPaths == ["/etc/resolv.conf" "/etc/hosts" "/etc/passwd" "/etc/group"]
    && builtins.match "/nix/store/[a-z0-9]{32}-opencode-web-nsswitch.conf:/etc/nsswitch.conf" (builtins.elemAt s.BindReadOnlyPaths 4) != null
    && builtins.match "/nix/store/[a-z0-9]{32}-coreutils-[^/]+/bin/env:/usr/bin/env" (builtins.elemAt s.BindReadOnlyPaths 5) != null
    && service.environment.HOME == "/var/lib/opencode-web"
    && lib.hasPrefix "/nix/store/" service.environment.XDG_CONFIG_HOME
    && service.environment.XDG_DATA_HOME == "/var/lib/opencode-web/data"
    && service.environment.XDG_CACHE_HOME == "/var/lib/opencode-web/cache"
    && service.environment.XDG_STATE_HOME == "/var/lib/opencode-web/state";
  mutations = {
    root-service.service.serviceConfig.User = "root";
    root-uid.user.uid = 0;
    root-gid.groups.opencode-web.gid = 0;
    wheel-user.user.extraGroups = ["wheel"];
    wheel-service.service.serviceConfig.SupplementaryGroups = ["wheel"];
    wheel-membership.groups.wheel.members = ["opencode-web"];
    trusted-user.trustedUsers = ["root" "@wheel" "opencode-web"];
    trusted-group.trustedUsers = ["root" "@opencode-web"];
    sudo-user.sudoRules = [
      {
        users = ["opencode-web"];
        groups = [];
      }
    ];
    sudo-group.sudoRules = [
      {
        users = [];
        groups = ["opencode-web"];
      }
    ];
    readable-home.service.serviceConfig.ProtectHome = false;
    privileged-exec.service.serviceConfig.NoNewPrivileges = false;
    shared-state.service.environment.XDG_STATE_HOME = "/home/fveracoechea/.local/state";
    shared-config.service.environment.XDG_CONFIG_HOME = "/home/fveracoechea/.config";
    writable-project.service.serviceConfig.ReadWritePaths = ["/home/fveracoechea/projects"];
    owner-bind.service.serviceConfig.BindReadOnlyPaths = ["/home/fveracoechea/.ssh:/run/owner-ssh"];
    unconfined.service.confinement.enable = false;
    whole-unit-closure.service.confinement.fullUnit = true;
    full-store-bind.service.serviceConfig.BindReadOnlyPaths = ["/nix/store"];
    store-password.service.serviceConfig.EnvironmentFile = "/nix/store/unapproved-password";
    missing-file-condition.service.unitConfig.ConditionPathExists = "/unexpected-fixture";
    ssh-key.user.openssh.authorizedKeys.keys = ["unapproved-key"];
  };
  rejectsMutations = builtins.all (name:
    lib.assertMsg (!(isolated (lib.recursiveUpdate identity mutations.${name})))
    "coding-agents: web isolation accepted ${name}") (builtins.attrNames mutations);
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
  coding-agents-web-isolation = import ./web-isolation-test.nix {inherit homelab lib;};
  coding-agents-web = assert lib.assertMsg (
    c.dotfiles.coding-agents.web.enable
    && !desktop.config.dotfiles.coding-agents.web.enable
    && !(desktop.config.systemd.services ? opencode-web)
    && isolated identity
    && rejectsMutations
  ) "coding-agents: web identity or isolation changed";
    pkgs.runCommand "coding-agents-web-check" {nativeBuildInputs = [pkgs.caddy pkgs.python3];} ''
      set -eu
      if env -i ${service.serviceConfig.ExecStart} > missing-password.log 2>&1; then
        echo "Service accepted a missing password" >&2
        exit 1
      fi
      grep -q 'OPENCODE_PASSWORD must be provisioned' missing-password.log
      if env -i OPENCODE_PASSWORD= ${service.serviceConfig.ExecStart} > empty-password.log 2>&1; then
        echo "Service accepted an empty password" >&2
        exit 1
      fi
      grep -q 'OPENCODE_PASSWORD must be provisioned' empty-password.log
      caddy adapt --config ${proxyFixture} --adapter caddyfile > proxy.json
      python3 ${./web-check.py} proxy.json --mutations
      test -s ${service.environment.XDG_CONFIG_HOME}/opencode/opencode.json
      test -s ${service.environment.XDG_CONFIG_HOME}/opencode/AGENTS.md
      test -s ${service.environment.XDG_CONFIG_HOME}/opencode/agents/super.md
      test -s ${service.environment.XDG_CONFIG_HOME}/opencode/agents/worker.md
      test -s ${service.environment.XDG_CONFIG_HOME}/opencode/skills/herdr/SKILL.md
      test -s ${service.environment.XDG_CONFIG_HOME}/opencode/plugins/operator.ts
      touch "$out"
    '';
}
