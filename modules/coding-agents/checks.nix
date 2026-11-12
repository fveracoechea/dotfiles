{
  lib,
  pkgs,
  home-manager,
  homeModule,
  dotfilesPkgs,
  pkgs-stable,
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
in {
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
    && desktop.programs.opencode.settings.compaction == {buffer = "25%"; keep.tokens = 20000;}
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
    test -f "$config/opencode/agents/super.md"
    test -f "$config/opencode/agents/worker.md"
    test -f "$config/hunk/extensions/hunk-gh/index.ts"
    ${lib.concatMapStringsSep "\n" (name: ''test -f "$config/opencode/skills/${name}/SKILL.md"'') (dotfilesPkgs.operator.skills ++ ["herdr" "hunk-review"])}
    jq -e '.mcp.servers["nix-mcp"].type == "local" and .model == "openai/gpt-6.1-sol"' "$config/opencode/opencode.json"
    jq -e '.plugins == ["./herdr-opencode"]' "$config/opencode/cli.json"
    jq -e '.compaction == {buffer: "25%", keep: {tokens: 20000}} and .agents.plan.disabled and .agents.super.model == "openai/gpt-6.1-sol#high" and .agents.worker.model == "openai/gpt-6.1-sol#medium" and .providers.openai.settings.compaction.type == "native" and any(.providers.openai.models["gpt-6.1-sol"].variants[]; .id == "medium" and .settings.reasoningEffort == "medium")' "$config/opencode/opencode.json"
    python -c 'import sys, tomllib; c = tomllib.load(open(sys.argv[1], "rb")); assert c["ui"]["sound"]["enabled"] is False; assert "toast" not in c["ui"]' "$config/herdr/config.toml"
    python -c 'import sys, tomllib; c = tomllib.load(open(sys.argv[1], "rb")); assert c["ui"]["sound"]["enabled"] is False; assert c["ui"]["toast"]["delivery"] == "herdr"' ${overridden.xdg.configFile."herdr/config.toml".source}
    touch "$out"
  '';
  coding-agents-formatters = pkgs.runCommand "coding-agents-formatters-check" {nativeBuildInputs = [pkgs.python3];} ''
    python ${./formatters-check.py} ${configFiles."opencode/opencode.json".source}
    touch "$out"
  '';
}
