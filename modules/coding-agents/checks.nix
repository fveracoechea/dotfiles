{
  lib,
  pkgs,
  home-manager,
  homeModule,
  dotfilesPkgs,
  pkgs-stable,
  homelab,
  desktopHost,
}: let
  fixture = modules:
    (home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {inherit dotfilesPkgs;};
      modules =
        [
          {
            home = {
              username = "coding-agents-fixture";
              homeDirectory = "/home/coding-agents-fixture";
              stateVersion = "24.05";
            };
          }
        ]
        ++ modules;
    }).config;
  bare = fixture [];
  disabled = fixture [homeModule {dotfiles.coding-agents.enable = false;}];
  enabled = fixture [homeModule {dotfiles.coding-agents.enable = true;}];
  desktop = fixture [
    homeModule
    {
      dotfiles.coding-agents.enable = true;
      dotfiles.git.enable = true;
    }
  ];
  overridden = fixture [
    homeModule
    {
      dotfiles.coding-agents.enable = true;
      programs.herdr.settings.ui.sidebar_width = 40;
      programs.herdr.settings.ui.toast.delivery = "herdr";
      programs.opencode.settings.model = "fixture/model";
    }
  ];
  paths = c: map toString c.home.packages;
  files = c:
    lib.mapAttrs (_: f: {
      inherit (f) enable target text onChange;
      source = toString f.source;
    })
    c.home.file;
  check = name: condition:
    assert lib.assertMsg condition "coding-agents: ${name}";
      pkgs.runCommand "coding-agents-${name}" {} ''touch "$out"'';
  configFiles = desktop.xdg.configFile;
  staged = pkgs.linkFarm "coding-agents-config" (lib.mapAttrsToList (_: f: {
    name = f.target;
    path = f.source;
  }) (lib.filterAttrs (name: f: f.enable && builtins.any (prefix: lib.hasPrefix prefix name) ["opencode/" "herdr/" "hunk/"]) configFiles));
  serverHome = homelab.config.home-manager.users.fveracoechea;
  serverOff =
    (homelab.extendModules {
      modules = [({lib, ...}: {home-manager.users.fveracoechea.dotfiles.coding-agents.enable = lib.mkForce false;})];
    }).config.home-manager.users.fveracoechea;
  serverFiles = pkgs.linkFarm "homelab-coding-agents-config" (lib.mapAttrsToList (name: f: {
    inherit name;
    path = f.source;
  }) (lib.filterAttrs (name: f: f.enable && builtins.any (prefix: lib.hasPrefix prefix name) ["opencode/" "herdr/" "hunk/"]) serverHome.xdg.configFile));
  expectedFormatters = {
    nixfmt = {
      command = [(lib.getExe pkgs.nixfmt) "$FILE"];
      extensions = [".nix"];
    };
    oxfmt = {
      command = [(lib.getExe pkgs.oxfmt) "--write" "$FILE"];
      extensions = [".js" ".jsx" ".mjs" ".cjs" ".ts" ".tsx" ".mts" ".cts"];
    };
  };
  formatterMutations = [
    {nixfmt.command = ["/missing/nixfmt" "$FILE"];}
    {oxfmt.command = [(lib.getExe pkgs.coreutils) "$FILE"];}
    {nixfmt.disabled = true;}
    {oxfmt.extensions = [".nix"];}
    {nixfmt.command = [(lib.getExe pkgs.nixfmt)];}
  ];
  validFormatters = formatters: formatters == expectedFormatters;
  formatterFixture = settings:
    assert lib.assertMsg (validFormatters settings.formatter) "coding-agents: formatter policy changed";
      ''
        mkdir "formatter fixtures"
        test ! -e "formatter fixtures/package.json"
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: original: let
          command = settings.formatter.${name}.command;
          run = lib.concatMapStringsSep " " (arg: if arg == "$FILE" then ''"$file"'' else lib.escapeShellArg arg) command;
          extension = if name == "nixfmt" then ".nix" else ".ts";
        in ''
          file="$PWD/formatter fixtures/unformatted example${extension}"
          printf '%s\n' ${lib.escapeShellArg original} > "$file"
          original=$(sha256sum "$file")
          test -x ${lib.escapeShellArg (builtins.head command)}
          ${run}
          if [ "$(sha256sum "$file")" = "$original" ]; then
            echo "${name} did not format the fixture" >&2
            exit 1
          fi
          formatted=$(sha256sum "$file")
          ${run}
          test "$(sha256sum "$file")" = "$formatted"
          ${lib.escapeShellArg (builtins.head command)} --check "$file"
        '') {
          nixfmt = "{foo=1;bar=[1 2];}";
          oxfmt = "const value={foo:1,bar:[1,2]};";
        })}
      '';
  web = homelab.config;
  service = web.systemd.services.opencode-web;
  identity = {
    user = web.users.users.opencode-web;
    inherit service;
    groups = web.users.groups;
    trustedUsers = web.nix.settings.trusted-users;
    sudoRules = web.security.sudo.extraRules;
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
      && !(builtins.any (name: builtins.elem name rule.groups) ["opencode-web" "ALL"])) sudoRules
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
  isolationMutations = {
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
  proxyFixture = pkgs.writeText "opencode-web.Caddyfile" ''
    {
      admin off
      auto_https off
    }
    https://opencode.veracoechea.com {
      ${web.services.caddy.virtualHosts."opencode.veracoechea.com".extraConfig}
    }
  '';
  proxyCheck = pkgs.writeText "opencode-web-proxy-check.jq" ''
    (.apps.http.servers | to_entries | map(.value)) as $servers |
    $servers[0].routes as $routes |
    $routes[0].handle[0].routes as $access |
    ($servers | length) == 1 and ($routes | length) == 1 and
    $routes[0].match == [{host: ["opencode.veracoechea.com"]}] and
    ($access | length) == 2 and
    $access[0].match == [{remote_ip: {ranges: ["100.64.0.0/10"]}}] and
    ($access[1] | has("match") | not) and
    ($access[0].group | type) == "string" and
    $access[0].group == $access[1].group and
    $access[0].handle[0].routes[0].handle == [{handler: "reverse_proxy", upstreams: [{dial: "127.0.0.1:4096"}]}] and
    $access[1].handle[0].routes[0].handle == [{handler: "static_response", status_code: 403}] and
    ([.. | objects | has("client_ip")] | any | not)
  '';
  proxyMutations = {
    lan = ''.apps.http.servers[].routes[0].handle[0].routes[0].match[0].remote_ip.ranges += ["192.168.0.0/16"]'';
    public = ''.apps.http.servers[].routes[0].handle[0].routes[0].match[0].remote_ip.ranges = ["0.0.0.0/0"]'';
    forwarded-ip = ''(.apps.http.servers[].routes[0].handle[0].routes[0].match[0]) |= {client_ip: .remote_ip}'';
    missing-denial = ''del(.apps.http.servers[].routes[0].handle[0].routes[1])'';
    denial-proxy = ''.apps.http.servers[].routes[0].handle[0].routes[1].handle = .apps.http.servers[].routes[0].handle[0].routes[0].handle'';
    public-backend = ''.apps.http.servers[].routes[0].handle[0].routes[0].handle[0].routes[0].handle[0].upstreams[0].dial = "0.0.0.0:4096"'';
    extra-route = ''.apps.http.servers[].routes += [{handle: [{handler: "reverse_proxy"}]}]'';
  };
in {
  coding-agents-homelab = check "homelab" (
    serverHome.dotfiles.coding-agents.enable
    && serverHome.programs.opencode.package == pkgs.opencode
    && serverHome.programs.herdr.package == dotfilesPkgs.herdr
    && !serverHome.programs.opencode.web.enable
    && !serverHome.programs.claude-code.enable
    && !(serverHome.home.file ? "OPINIONS.md")
    && serverHome.programs.git.settings.core.pager == "hunk pager"
    && serverHome.programs.lazygit.settings.git.diffRenderers == [{command = "hunk pager";}]
    && serverHome.programs.opencode.settings == desktop.programs.opencode.settings
    && serverHome.programs.herdr.settings == desktop.programs.herdr.settings
    && !serverHome.programs.herdr.settings.ui.sound.enabled
    && serverHome.programs.git.settings == serverOff.programs.git.settings
    && serverHome.programs.lazygit.settings == serverOff.programs.lazygit.settings
    && serverHome.home.sessionVariables == serverOff.home.sessionVariables
    && serverHome.systemd.user.services == serverOff.systemd.user.services
  );
  coding-agents-homelab-config = pkgs.runCommand "homelab-coding-agents-config-check" {nativeBuildInputs = [pkgs.jq pkgs.check-jsonschema];} ''
    set -eu
    config=${serverFiles}
    check-jsonschema --force-filetype=json --schemafile=${pkgs.opencode.jsonschema.config} "$config/opencode/opencode.json"
    check-jsonschema --force-filetype=json --schemafile=${pkgs.opencode.jsonschema.cli} "$config/opencode/cli.json"
    test -s "$config/opencode/herdr-opencode/tui.js"
    test -s "$config/opencode/plugins/operator.ts"
    test -s "$config/opencode/AGENTS.md"
    test -s "$config/opencode/agents/super.md"
    test -s "$config/opencode/agents/worker.md"
    grep -q '^mode: primary$' "$config/opencode/agents/super.md"
    grep -q '^mode: primary$' "$config/opencode/agents/worker.md"
    grep -q 'agent\|Agent' "$config/opencode/AGENTS.md"
    test -f "$config/hunk/extensions/hunk-gh/index.ts"
    sed 's|${serverOff.home.path}|${serverHome.home.path}|g' ${serverOff.xdg.configFile."fontconfig/conf.d/10-hm-fonts.conf".source} > fontconfig-expected.xml
    cmp fontconfig-expected.xml ${serverHome.xdg.configFile."fontconfig/conf.d/10-hm-fonts.conf".source}
    ${lib.concatMapStringsSep "\n" (name: ''test -s "$config/opencode/skills/${name}/SKILL.md"'') (dotfilesPkgs.operator.skills ++ ["herdr" "hunk-review"])}
    jq -e '.plugins == ["./herdr-opencode"]' "$config/opencode/cli.json"
    touch "$out"
  '';
  coding-agents-disabled = check "disabled" (
    !disabled.programs.opencode.enable
    && !disabled.programs.herdr.enable
    && paths disabled == paths bare
    && files disabled == files bare
    && disabled.home.activation == bare.home.activation
    && disabled.systemd.user.services == bare.systemd.user.services
  );
  coding-agents-enabled = check "enabled" (
    desktop.programs.opencode.enable
    && desktop.programs.herdr.enable
    && desktop.programs.herdr.package == dotfilesPkgs.herdr
    && builtins.all (p: builtins.elem (toString p) (paths desktop)) [
      dotfilesPkgs.operator
      pkgs.python3
      pkgs.nixd
      pkgs.nixfmt
      pkgs.typescript-language-server
      pkgs.biome
      pkgs.oxfmt
      pkgs.lsof
      pkgs.gh
    ]
    && desktop.programs.opencode.settings.mcp.servers.nix-mcp.type == "local"
    && desktop.programs.opencode.settings.mcp.servers.nix-mcp.command == [(lib.getExe pkgs-stable.mcp-nixos)]
    && builtins.elem (toString pkgs-stable.mcp-nixos) (paths desktop)
    && desktop.programs.opencode.settings.model == "openai/gpt-6.1-sol"
    && desktop.programs.opencode.settings.formatter.nixfmt.command == [(lib.getExe pkgs.nixfmt) "$FILE"]
    && desktop.programs.opencode.settings.formatter.oxfmt.command == [(lib.getExe pkgs.oxfmt) "--write" "$FILE"]
    && desktop.programs.opencode.settings.compaction
    == {
      buffer = "25%";
      keep.tokens = 20000;
    }
    && desktop.programs.opencode.settings.agents.plan.disabled
    && desktop.programs.opencode.settings.agents.super.model == "openai/gpt-6.1-sol#high"
    && desktop.programs.opencode.settings.agents.worker.model == "openai/gpt-6.1-sol#medium"
    && desktop.programs.opencode.settings.providers.openai.settings.compaction.type == "native"
    && desktop.programs.herdr.settings.ui.sidebar_width == 32
    && !desktop.programs.herdr.settings.ui.sound.enabled
    && !(desktop.programs.herdr.settings.ui ? toast)
    && desktop.programs.opencode.cli.plugins == ["./herdr-opencode"]
    && builtins.all (name: desktop.programs.opencode.skills ? ${name}) (dotfilesPkgs.operator.skills ++ ["herdr" "hunk-review"])
    && desktop.programs.git.settings.core.pager == "hunk pager"
    && desktop.programs.lazygit.settings.git.diffRenderers == [{command = "hunk pager";}]
    && !enabled.programs.git.enable
    && !enabled.programs.lazygit.enable
    && !(enabled.programs.git.settings.core ? pager)
    && !((enabled.programs.lazygit.settings.git or {}) ? diffRenderers)
  );
  coding-agents-override = check "override" (
    overridden.programs.herdr.settings.ui.sidebar_width
    == 40
    && overridden.programs.opencode.settings.model == "fixture/model"
    && !overridden.programs.herdr.settings.ui.sound.enabled
    && overridden.programs.herdr.settings.ui.toast.delivery == "herdr"
    && overridden.programs.opencode.cli.plugins == desktop.programs.opencode.cli.plugins
    && overridden.programs.opencode.skills == desktop.programs.opencode.skills
  );
  coding-agents-config = pkgs.runCommand "coding-agents-config-check" {nativeBuildInputs = [pkgs.jq pkgs.python3];} ''
    set -eu
    config=${staged}/.config
    test -f "$config/opencode/herdr-opencode/tui.js"
    test -f "$config/opencode/plugins/operator.ts"
    test -f "$config/opencode/AGENTS.md"
    test -s "$config/opencode/agents/super.md"
    test -s "$config/opencode/agents/worker.md"
    grep -q '^mode: primary$' "$config/opencode/agents/super.md"
    grep -q '^mode: primary$' "$config/opencode/agents/worker.md"
    test -f "$config/hunk/extensions/hunk-gh/index.ts"
    ${lib.concatMapStringsSep "\n" (name: ''test -f "$config/opencode/skills/${name}/SKILL.md"'') (dotfilesPkgs.operator.skills ++ ["herdr" "hunk-review"])}
    jq -e '.mcp.servers["nix-mcp"].type == "local" and .model == "openai/gpt-6.1-sol"' "$config/opencode/opencode.json"
    jq -e '.plugins == ["./herdr-opencode"]' "$config/opencode/cli.json"
    jq -e '.compaction == {buffer: "25%", keep: {tokens: 20000}} and .agents.plan.disabled and .agents.super.model == "openai/gpt-6.1-sol#high" and .agents.worker.model == "openai/gpt-6.1-sol#medium" and .providers.openai.settings.compaction.type == "native" and any(.providers.openai.models["gpt-6.1-sol"].variants[]; .id == "medium" and .settings.reasoningEffort == "medium")' "$config/opencode/opencode.json"
    python3 -c 'import sys, tomllib; c = tomllib.load(open(sys.argv[1], "rb")); assert c["ui"]["sound"]["enabled"] is False; assert "toast" not in c["ui"]' "$config/herdr/config.toml"
    python3 -c 'import sys, tomllib; c = tomllib.load(open(sys.argv[1], "rb")); assert c["ui"]["sound"]["enabled"] is False; assert c["ui"]["toast"]["delivery"] == "herdr"' ${overridden.xdg.configFile."herdr/config.toml".source}
    touch "$out"
  '';
  coding-agents-formatters = assert builtins.all (mutation: !(validFormatters (lib.recursiveUpdate expectedFormatters mutation))) formatterMutations;
    pkgs.runCommand "coding-agents-formatters-check" {nativeBuildInputs = [pkgs.jq];} ''
    jq -e --argjson expected ${lib.escapeShellArg (builtins.toJSON expectedFormatters)} '.formatter == $expected' ${configFiles."opencode/opencode.json".source}
    ${formatterFixture desktop.programs.opencode.settings}
    touch "$out"
  '';
  coding-agents-web = assert lib.assertMsg (
    web.dotfiles.coding-agents.web.enable
    && !desktopHost.config.dotfiles.coding-agents.web.enable
    && !(desktopHost.config.systemd.services ? opencode-web)
    && isolated identity
    && builtins.all (name:
      lib.assertMsg (!(isolated (lib.recursiveUpdate identity isolationMutations.${name})))
      "coding-agents: web isolation accepted ${name}") (builtins.attrNames isolationMutations)
  ) "coding-agents: web identity or isolation changed";
    pkgs.runCommand "coding-agents-web-check" {nativeBuildInputs = [pkgs.caddy pkgs.jq];} ''
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
      jq -e -f ${proxyCheck} proxy.json
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: mutation: ''
        jq ${lib.escapeShellArg mutation} proxy.json > mutation.json
        if jq -e -f ${proxyCheck} mutation.json; then
          echo "Accepted proxy mutation: ${name}" >&2
          exit 1
        fi
        echo "Rejected proxy mutation: ${name}"
      '') proxyMutations)}
      config=${service.environment.XDG_CONFIG_HOME}/opencode
      for asset in opencode.json AGENTS.md agents/super.md agents/worker.md skills/herdr/SKILL.md plugins/operator.ts; do
        test -s "$config/$asset"
      done
      jq -e --argjson expected ${lib.escapeShellArg (builtins.toJSON expectedFormatters)} '.formatter == $expected' "$config/opencode.json"
      ${formatterFixture serverHome.programs.opencode.settings}
      touch "$out"
    '';
  coding-agents-web-isolation = let
    vmPkgs = homelab.pkgs;
    unrelatedProject = vmPkgs.writeText "unrelated-project" "synthetic-not-a-runtime-dependency";
    deniedPaths = [
      "/srv/world-readable-project/README"
      "/home/owner/.ssh/synthetic-key"
      "/opt/unrelated/synthetic-data"
      # Do not add this unrelated fixture to the probe's runtime closure.
      (builtins.unsafeDiscardStringContext "${unrelatedProject}")
    ];
    probe = vmPkgs.writeShellScript "opencode-web-isolation-probe" ''
      set -eu
      mkdir -p "$HOME/workspace" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"
      for directory in "$HOME/workspace" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"; do
        echo private-state > "$directory/probe"
        test -r "$directory/probe"
      done
      test -r "$XDG_CONFIG_HOME/opencode/opencode.json"
      test -r "$XDG_CONFIG_HOME/opencode/AGENTS.md"
      test -r "$XDG_CONFIG_HOME/opencode/agents/super.md"
      test -r "$XDG_CONFIG_HOME/opencode/agents/worker.md"
      test ! -w "$XDG_CONFIG_HOME/opencode/opencode.json"
      test -r /etc/resolv.conf
      /usr/bin/env /bin/sh -c 'test -w "$HOME/workspace"'
      ${lib.getExe serverHome.programs.opencode.package} --version
      git --version
      git -C "$HOME/workspace" init
      python3 -c 'import os, pwd, socket, ssl; assert pwd.getpwuid(os.getuid()).pw_name == "opencode-web"; assert socket.getaddrinfo("localhost", 443); assert ssl.create_default_context().get_ca_certs()'
      cd "$HOME/workspace"
      ${formatterFixture serverHome.programs.opencode.settings}
      cat --version > /dev/null
      failed=0
      for file in ${lib.escapeShellArgs deniedPaths}; do
        if cat "$file" > /dev/null 2>&1; then
          echo "Unexpected readable path: $file" >&2
          failed=1
        else
          echo "Denied synthetic path: $file"
        fi
      done
      exit "$failed"
    '';
  in vmPkgs.testers.runNixOSTest {
    name = "coding-agents-web-isolation";
    nodes.machine = {
      virtualisation.additionalPaths = [unrelatedProject];
      users.groups.opencode-web = {};
      users.users.opencode-web = {
        isSystemUser = true;
        group = "opencode-web";
        home = "/var/lib/opencode-web";
      };
      systemd.tmpfiles.rules = [
        "d /srv/world-readable-project 0755 root root -"
        "f /srv/world-readable-project/README 0644 root root - synthetic-project"
        "d /home/owner/.ssh 0755 root root -"
        "f /home/owner/.ssh/synthetic-key 0644 root root - synthetic-not-a-secret"
        "d /opt/unrelated 0755 root root -"
        "f /opt/unrelated/synthetic-data 0644 root root - synthetic-unrelated"
      ];
      systemd.services.opencode-web = {
        inherit (service) path confinement;
        environment = builtins.removeAttrs service.environment ["PATH"];
        serviceConfig = (builtins.removeAttrs service.serviceConfig ["ExecStart" "EnvironmentFile" "Restart" "RestartSec"]) // {
          ExecStart = probe;
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };
      systemd.services.opencode-web-unprovisioned = {
        inherit (service) path confinement serviceConfig unitConfig;
        environment = builtins.removeAttrs service.environment ["PATH"];
      };
    };
    testScript = ''
      machine.start()
      machine.wait_for_unit("multi-user.target")
      machine.succeed("test ! -e /var/lib/opencode-web.env")
      machine.succeed("test ! -d /var/lib/opencode-web/workspace")
      machine.succeed("systemctl start opencode-web-unprovisioned.service")
      machine.succeed("systemctl show opencode-web-unprovisioned.service -p ConditionResult --value | grep '^no$'")
      machine.fail("systemctl is-active --quiet opencode-web-unprovisioned.service")
      machine.succeed("test ! -d /var/lib/opencode-web/workspace")
      for path in ${builtins.toJSON deniedPaths}:
          machine.succeed(f"runuser -u opencode-web -- cat {path}")
      machine.succeed("systemctl start opencode-web.service")
      machine.succeed("journalctl -u opencode-web.service --no-pager | grep 'Denied synthetic path: /srv/world-readable-project/README'")
      machine.succeed("test -r /var/lib/opencode-web/workspace/probe")
    '';
  };
}
