{
  lib,
  host,
}: let
  plain = value: builtins.unsafeDiscardStringContext (toString value);
  counterfactual = host.extendModules {
    modules = [
      ({lib, ...}: {
        dotfiles.coding-agents.web.enable = lib.mkForce false;
        home-manager.users.fveracoechea.dotfiles.coding-agents.enable = lib.mkForce false;
      })
    ];
  };
  before = counterfactual.config;
  after = host.config;
  oldHome = before.home-manager.users.fveracoechea;
  newHome = after.home-manager.users.fveracoechea;
  packages = home: builtins.sort builtins.lessThan (map plain home.home.packages);
  files = home:
    lib.mapAttrs (_: file: {
      inherit (file) enable target executable recursive force onChange;
      source = plain file.source;
    })
    home.home.file;
  oldFiles = files oldHome;
  newFiles = files newHome;
  delta = {
    addedPackages = lib.subtractLists (packages oldHome) (packages newHome);
    removedPackages = lib.subtractLists (packages newHome) (packages oldHome);
    changedFiles = lib.mapAttrs (_: file: file.source) (lib.filterAttrs (name: value: !(oldFiles ? ${name}) || oldFiles.${name} != value) newFiles);
    removedFiles = lib.subtractLists (builtins.attrNames newFiles) (builtins.attrNames oldFiles);
    # These identities include the complete Home activation, environment and user units.
    activationPackage = plain newHome.home.activationPackage;
    homePath = plain newHome.home.path;
    userPackages = map plain after.users.users.fveracoechea.packages;
    homeManagerUnitHash = builtins.hashString "sha256" after.systemd.units."home-manager-fveracoechea.service".text;
  };
  expected = builtins.fromJSON (builtins.readFile ./homelab-agent-delta.json);
  webDelta = {
    userHash = builtins.hashString "sha256" (builtins.toJSON after.users.users.opencode-web);
    groupHash = builtins.hashString "sha256" (builtins.toJSON after.users.groups.opencode-web);
    unitHash = builtins.hashString "sha256" after.systemd.units."opencode-web.service".text;
    proxy = after.services.caddy.virtualHosts."opencode.veracoechea.com".extraConfig;
    confinementPackages = lib.subtractLists (map plain before.systemd.packages) (map plain after.systemd.packages);
  };
  expectedWeb = builtins.fromJSON (builtins.readFile ./homelab-web-delta.json);
  normalized = host.extendModules {
    modules = [
      ({lib, ...}: {
        options = {
          users.users = lib.mkOption {apply = users: builtins.removeAttrs users ["opencode-web"];};
          users.groups = lib.mkOption {apply = groups: builtins.removeAttrs groups ["opencode-web"];};
          systemd.units = lib.mkOption {apply = units: builtins.removeAttrs units ["opencode-web.service"];};
          systemd.packages = lib.mkOption {apply = packages: builtins.filter (package: !(builtins.elem (plain package) expectedWeb.confinementPackages)) packages;};
          services.caddy.virtualHosts = lib.mkOption {apply = vhosts: builtins.removeAttrs vhosts ["opencode.veracoechea.com"];};
        };
        config = {
          users.users.fveracoechea.packages = lib.mkForce before.users.users.fveracoechea.packages;
          systemd.units."home-manager-fveracoechea.service".text = lib.mkForce before.systemd.units."home-manager-fveracoechea.service".text;
        };
      })
    ];
  };
in {
  inherit counterfactual delta webDelta;
  normalizedPath = plain normalized.config.system.build.toplevel;
  counterfactualPath = plain before.system.build.toplevel;
  preserved =
    delta
    == expected
    && webDelta == expectedWeb
    && plain normalized.config.system.build.toplevel == plain before.system.build.toplevel;
}
