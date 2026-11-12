{
  lib,
  pkgs,
  home-manager,
  homeModule,
  dotfilesPkgs,
  pkgs-stable,
  homelab,
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
  serverOff = (homelab.extendModules {
    modules = [({lib, ...}: {home-manager.users.fveracoechea.dotfiles.coding-agents.enable = lib.mkForce false;})];
  }).config.home-manager.users.fveracoechea;
  serverFiles = pkgs.linkFarm "homelab-coding-agents-config" (lib.mapAttrsToList (name: f: {
    inherit name;
    path = f.source;
  }) (lib.filterAttrs (name: f: f.enable && builtins.any (prefix: lib.hasPrefix prefix name) ["opencode/" "herdr/" "hunk/"]) serverHome.xdg.configFile));
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
    && desktop.programs.herdr.settings.ui.sidebar_width == 32
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
    && overridden.programs.opencode.cli.plugins == desktop.programs.opencode.cli.plugins
    && overridden.programs.opencode.skills == desktop.programs.opencode.skills
  );
  coding-agents-config = pkgs.runCommand "coding-agents-config-check" {nativeBuildInputs = [pkgs.jq];} ''
    set -eu
    config=${staged}/.config
    test -f "$config/opencode/herdr-opencode/tui.js"
    test -f "$config/opencode/plugins/operator.ts"
    test -f "$config/opencode/AGENTS.md"
    test -f "$config/hunk/extensions/hunk-gh/index.ts"
    ${lib.concatMapStringsSep "\n" (name: ''test -f "$config/opencode/skills/${name}/SKILL.md"'') (dotfilesPkgs.operator.skills ++ ["herdr" "hunk-review"])}
    jq -e '.mcp.servers["nix-mcp"].type == "local" and .model == "openai/gpt-6.1-sol"' "$config/opencode/opencode.json"
    jq -e '.plugins == ["./herdr-opencode"]' "$config/opencode/cli.json"
    touch "$out"
  '';
}
