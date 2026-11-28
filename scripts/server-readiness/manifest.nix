{
  lib,
  config,
  host,
  source,
  pkgs,
  options,
}:
let
  services = config.services;
  package = p: {
    family = p.pname or null;
    version = p.version or null;
    path = toString p;
  };
  inputs = p: (p.buildInputs or [ ]) ++ (p.nativeBuildInputs or [ ]);
  runtimes =
    kind: p:
    lib.unique (
      builtins.filter (p: lib.hasPrefix kind (p.pname or "")) (
        (inputs p) ++ lib.optional (p ? python) p.python
      )
    );
  unit =
    name: packages:
    let
      configured =
        config.systemd.services.${name}.serviceConfig.ExecStart or {
          tailscaled = "${applications.tailscale}/bin/tailscaled";
          fail2ban = "${applications.fail2ban}/bin/fail2ban-server";
        }
        .${name};
      command = lib.last (builtins.filter (s: s != "") (lib.toList configured));
      executable = builtins.head (lib.splitString " " command);
    in
    {
      start = lib.removeSuffix "\"" (lib.removePrefix "\"" executable);
      executables = map toString packages;
      configuration = builtins.hashString "sha256" (
        builtins.toJSON {
          inherit (config.systemd.services.${name})
            serviceConfig
            environment
            preStart
            script
            path
            after
            requires
            wants
            ;
        }
      );
    };
  common = {
    caddy = services.caddy.package;
    tailscale = services.tailscale.package;
  };
  applications =
    common
    // (
      if host == "homelab" then
        {
          adguardhome = services.adguardhome.package;
          home-assistant = services.home-assistant.finalPackage;
          immich = services.immich.package;
          immich-machine-learning = services.immich.package.machine-learning;
          ollama = services.ollama.package;
          paperless = services.paperless.package;
          podman = config.virtualisation.podman.package;
          postgresql = services.postgresql.package;
          redis = services.redis.package;
          vaultwarden = services.vaultwarden.package.override { inherit (services.vaultwarden) dbBackend; };
          vaultwarden-web = services.vaultwarden.webVaultPackage;
          zwave-js = services.zwave-js.package;
        }
      else
        {
          fail2ban = services.fail2ban.package;
          headscale = services.headscale.package;
          headplane = services.headplane.package;
        }
    );
  runtimePackages =
    lib.concatMapAttrs
      (
        name: kind:
        builtins.listToAttrs (
          map (runtime: {
            name = "${name}/${runtime.pname}";
            value = runtime;
          }) (runtimes kind applications.${name})
        )
      )
      (
        if host == "homelab" then
          {
            home-assistant = "python3";
            immich = "nodejs";
            immich-machine-learning = "python3";
            paperless = "python3";
            zwave-js = "nodejs";
          }
        else
          {
            fail2ban = "python3";
            headplane = "nodejs";
          }
      );
  ha = services.home-assistant.finalPackage;
  haDependencies =
    if host == "homelab" then
      lib.unique (
        (ha.dependencies or [ ])
        ++ lib.concatMap (component: ha.getPackages component ha.python3Packages) ha.extraComponents
        ++ services.home-assistant.extraPackages ha.python3Packages
        ++ services.home-assistant.customComponents
      )
    else
      [ ];
  dependencies =
    runtimePackages
    // lib.optionalAttrs (host == "homelab") (
      {
        "paperless/granian" = applications.paperless.python.pkgs.granian;
      }
      // builtins.listToAttrs (
        map (p: {
          name = "home-assistant/${p.pname}";
          value = p;
        }) haDependencies
      )
      // builtins.listToAttrs (
        map (p: {
          name = "postgresql/${p.pname}";
          value = p;
        }) (services.postgresql.extensions services.postgresql.package.pkgs)
      )
      // builtins.listToAttrs (
        map
          (p: {
            name = "ollama/${p.pname}";
            value = p;
          })
          (
            builtins.filter (
              p: builtins.match ".*(rocm|rocblas|hipblas|hip|rocsolver|rocsparse|clr).*" (p.pname or "") != null
            ) (services.ollama.package.buildInputs or [ ])
          )
      )
    );
  units = {
    caddy = unit "caddy" [ applications.caddy ];
    tailscaled = unit "tailscaled" [ applications.tailscale ];
  }
  // (
    if host == "homelab" then
      {
        adguardhome = unit "adguardhome" [ applications.adguardhome ];
        home-assistant = unit "home-assistant" (runtimes "python3" ha);
        immich-server = unit "immich-server" (runtimes "nodejs" applications.immich);
        immich-machine-learning = unit "immich-machine-learning" (
          runtimes "python3" applications.immich-machine-learning
        );
        ollama = unit "ollama" [ applications.ollama ];
        paperless-web = unit "paperless-web" [ applications.paperless.python ];
        paperless-task-queue = unit "paperless-task-queue" [ applications.paperless.python ];
        paperless-scheduler = unit "paperless-scheduler" [ applications.paperless.python ];
        paperless-consumer = unit "paperless-consumer" [ applications.paperless.python ];
        postgresql = unit "postgresql" [ applications.postgresql ];
        redis-immich = unit "redis-immich" [ applications.redis ];
        redis-paperless = unit "redis-paperless" [ applications.redis ];
        vaultwarden = unit "vaultwarden" [ applications.vaultwarden ];
        zwave-js = unit "zwave-js" (runtimes "nodejs" applications.zwave-js);
      }
    else
      {
        fail2ban = unit "fail2ban" (runtimes "python3" applications.fail2ban);
        headscale = unit "headscale" [ applications.headscale ];
        headplane = unit "headplane" (runtimes "nodejs" applications.headplane);
      }
  );
  registeredFiles =
    if host == "homelab" then
      [
        "adguardhome.nix"
        "browse.nix"
        "caddy.nix"
        "home-assistant.nix"
        "immich.nix"
        "ollama.nix"
        "opencode.nix"
        "paperless-gpt.nix"
        "paperless.nix"
        "postgresql.nix"
        "tailscale.nix"
        "vaultwarden.nix"
        "zwave-js.nix"
      ]
    else
      [
        "caddy.nix"
        "fail2ban.nix"
        "headplane.nix"
        "headscale.nix"
        "tailscale.nix"
      ];
  files = builtins.filter (lib.hasSuffix ".nix") (
    builtins.attrNames (builtins.readDir (../../hosts + "/${host}/services"))
  );
  infrastructure = [
    "dbus"
    "fstrim"
    "getty"
    "logind"
    "logrotate"
    "lvm"
    "nscd"
    "openssh"
    "sshd"
    "timesyncd"
    "udev"
  ];
  enabledServices = builtins.filter (
    name:
    (options.services.${name} ? enable)
    && (options.services.${name}.enable.visible or true) != false
    && (services.${name}.enable or false) == true
  ) (builtins.attrNames options.services);
  untrackedServices = lib.subtractLists (
    (builtins.attrNames applications) ++ infrastructure
  ) enabledServices;
  redisServers = builtins.filter (name: services.redis.servers.${name}.enable) (
    builtins.attrNames services.redis.servers
  );
  driverLock =
    (builtins.fromJSON (builtins.readFile ../../checks/server-npm-locks.json)).zwave-js-server;
  driverKnown =
    host == "homelab"
    && applications.zwave-js.version == driverLock.version
    && applications.zwave-js.src.outputHash == driverLock.sourceHash
    && applications.zwave-js.npmDepsHash == driverLock.npmDepsHash;
in
{
  schemaVersion = 1;
  inherit
    host
    source
    units
    enabledServices
    ;
  collectorPython = pkgs.python3.interpreter;
  stateVersions = {
    system = config.system.stateVersion;
    home = if host == "homelab" then config.home-manager.users.fveracoechea.home.stateVersion else null;
  };
  packages =
    builtins.mapAttrs (_: package) (applications // dependencies)
    // lib.optionalAttrs (host == "homelab") {
      zwave-js-driver = {
        family = "zwave-js-driver";
        version = if driverKnown then driverLock.driverVersion else null;
        path = toString applications.zwave-js;
      };
    };
  containers = builtins.mapAttrs (_: c: {
    inherit (c) image autoStart;
    configuration = builtins.hashString "sha256" (builtins.toJSON c);
  }) config.virtualisation.oci-containers.containers;
  compatibility = builtins.hashString "sha256" (
    builtins.toJSON {
      inherit units;
      firewall = config.networking.firewall;
      proxy = services.caddy.virtualHosts;
      storage = {
        inherit (config) fileSystems;
        swapDevices = map (entry: { inherit (entry) device; }) config.swapDevices;
      };
      postgres = lib.optionalAttrs (host == "homelab") {
        inherit (services.postgresql)
          dataDir
          settings
          ensureDatabases
          ensureUsers
          ;
      };
      vaultwardenBackend = if host == "homelab" then services.vaultwarden.dbBackend else null;
    }
  );
  database =
    if host == "homelab" then
      {
        name = services.immich.database.name;
        major = lib.versions.major services.postgresql.package.version;
        extensions = {
          vector = (package services.postgresql.package.pkgs.pgvector);
          vchord = (package services.postgresql.package.pkgs.vectorchord);
        };
        psql = "${services.postgresql.package}/bin/psql";
      }
    else
      null;
  blockers =
    (map (file: "Unregistered host service file: ${file}") (lib.subtractLists registeredFiles files))
    ++ (map (name: "Untracked enabled application service: ${name}") untrackedServices)
    ++ (map (name: "Untracked Redis instance: ${name}") (
      lib.subtractLists (
        if host == "homelab" then
          [
            "immich"
            "paperless"
          ]
        else
          [ ]
      ) redisServers
    ))
    ++ lib.optional (
      config.virtualisation.oci-containers.containers != { }
      && config.virtualisation.oci-containers.backend != "podman"
    ) "Untracked OCI backend"
    ++ lib.optionals (host == "homelab" && !driverKnown) [
      "Unreviewed Z-Wave JS dependency lock. Update checks/server-npm-locks.json against the selected source."
    ];
}
