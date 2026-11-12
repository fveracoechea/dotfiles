{
  lib,
  pkgs,
  pkgs-stable,
  home-manager,
  homeModule,
  dotfilesPkgs,
  hosts,
  nixpkgs,
  nixosModule,
}: let
  members = ["zsh" "tmux" "bat" "btop" "yazi" "git"];
  fixture = modules:
    (home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {inherit dotfilesPkgs pkgs-stable;};
      modules = [
        {
          home = {
            username = "shell-fixture";
            homeDirectory = "/home/shell-fixture";
            stateVersion = "24.05";
          };
        }
      ] ++ modules;
    }).config;
  bare = fixture [];
  disabled = fixture [homeModule];
  enabled = fixture [homeModule {dotfiles.shell.enable = true;}];
  without = member: fixture [
    homeModule
    {
      dotfiles = {
        shell.enable = true;
        ${member}.enable = false;
      };
    }
  ];
  alone = member: fixture [homeModule {dotfiles.${member}.enable = true;}];
  companions = fixture [
    homeModule
    {
      dotfiles.shell.enable = true;
      programs.neovim.enable = true;
    }
  ];
  paths = c: map toString c.home.packages;
  files = c: lib.mapAttrs (_: f: {
    inherit (f) enable target text onChange;
    source = toString f.source;
  }) c.home.file;
  check = name: condition:
    assert lib.assertMsg condition "shell: ${name}";
      pkgs.runCommand "shell-${name}" {} ''touch "$out"'';
  zshAlone = alone "zsh";
  yaziAlone = alone "yazi";
  gitAlone = alone "git";
  systemFixture = settings: (nixpkgs.lib.nixosSystem {
    modules = [
      nixosModule
      {
        nixpkgs.pkgs = pkgs-stable;
        system.stateVersion = "24.05";
      }
      settings
    ];
  }).config;
  systemDisabled = systemFixture {};
  systemEnabled = systemFixture {dotfiles.system-shell.enable = true;};
  systemShellMatches = host: let
    c = hosts.${host}.config;
    h = c.home-manager.users.fveracoechea;
  in
    h.programs.zsh.package.drvPath == c.users.defaultUserShell.drvPath
    && h.programs.tmux.shell == "${c.users.defaultUserShell}/bin/zsh";
in {
  system-shell-options = check "system-options" (
    !systemDisabled.programs.zsh.enable
    && systemEnabled.programs.zsh.enable
    && systemEnabled.users.defaultUserShell.drvPath == pkgs-stable.zsh.drvPath
    && builtins.elem "/share/zsh" systemEnabled.environment.pathsToLink
    && builtins.elem systemEnabled.users.defaultUserShell systemEnabled.environment.shells
  );
  shell-disabled = check "disabled" (
    builtins.all (name: !disabled.programs.${name}.enable) members
    && paths disabled == paths bare
    && files disabled == files bare
    && disabled.home.activation == bare.home.activation
    && disabled.systemd.user.services == bare.systemd.user.services
  );
  shell-grouping = check "grouping" (
    builtins.all (name: enabled.programs.${name}.enable) members
    && builtins.all (member: let c = without member; in
      !c.programs.${member}.enable
      && builtins.all (other: other == member || c.programs.${other}.enable) members
    ) members
    && builtins.all (member: let c = alone member; in
      c.programs.${member}.enable
      && builtins.all (other: other == member || !c.programs.${other}.enable) members
    ) members
  );
  shell-companions = check "companions" (
    !(zshAlone.programs.zsh.shellAliases ? t)
    && !(zshAlone.programs.zsh.shellAliases ? cat)
    && enabled.programs.zsh.shellAliases.t == ''tmux new-session -A -s "$(basename "$PWD")"''
    && enabled.programs.zsh.shellAliases.cat == "bat"
    && !(gitAlone.programs.git.settings.core ? editor)
    && companions.programs.git.settings.core.editor == "nvim"
    && !(enabled.programs.git.settings.core ? editor)
    && builtins.all (p: !(p ? url && p.url == "*/")) yaziAlone.programs.yazi.settings.plugin.prepend_previewers
    && builtins.any (p: p ? url && p.url == "*/" && lib.hasInfix "eza" p.run) enabled.programs.yazi.settings.plugin.prepend_previewers
    && !yaziAlone.programs.eza.enable
    && !gitAlone.programs.neovim.enable
  );
  shell-package-coupling = check "package-coupling" (
    enabled.programs.zsh.package.drvPath == pkgs-stable.zsh.drvPath
    && enabled.programs.tmux.shell == "${pkgs-stable.zsh}/bin/zsh"
    && systemShellMatches "nixos-desktop"
    && systemShellMatches "homelab"
    && hosts.homelab.config.users.defaultUserShell.drvPath != pkgs-stable.zsh.drvPath
  );
  shell-config = pkgs.runCommand "shell-config-check" {} ''
    set -eu
    grep -F 'set -g allow-passthrough on' ${enabled.xdg.configFile."tmux/tmux.conf".source}
    grep -F '@powerkit_theme "catppuccin"' ${enabled.xdg.configFile."tmux/tmux.conf".source}
    grep -F 'piper -- eza' ${enabled.xdg.configFile."yazi/yazi.toml".source}
    if grep -F 'piper -- eza' ${yaziAlone.xdg.configFile."yazi/yazi.toml".source}; then exit 1; fi
    touch "$out"
  '';
}
