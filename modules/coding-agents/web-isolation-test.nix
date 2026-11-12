{
  homelab,
  lib,
}: let
  pkgs = homelab.pkgs;
  service = homelab.config.systemd.services.opencode-web;
  opencode = homelab.config.home-manager.users.fveracoechea.programs.opencode.package;
  unrelatedProject = pkgs.writeText "unrelated-project" "synthetic-not-a-runtime-dependency";
  deniedPaths = [
    "/srv/world-readable-project/README"
    "/home/owner/.ssh/synthetic-key"
    "/opt/unrelated/synthetic-data"
    # Do not add this unrelated fixture to the probe's runtime closure.
    (builtins.unsafeDiscardStringContext "${unrelatedProject}")
  ];
  probe = pkgs.writeShellScript "opencode-web-isolation-probe" ''
    set -eu
    mkdir -p "$HOME/workspace" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"
    for directory in "$HOME/workspace" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"; do
      echo private-state > "$directory/probe"
      test -r "$directory/probe"
    done
    test -r "$XDG_CONFIG_HOME/opencode/opencode.json"
    test -r "$XDG_CONFIG_HOME/opencode/AGENTS.md"
    test ! -w "$XDG_CONFIG_HOME/opencode/opencode.json"
    test -r /etc/resolv.conf
    /usr/bin/env /bin/sh -c 'test -w "$HOME/workspace"'
    ${lib.getExe opencode} --version
    git --version
    git -C "$HOME/workspace" init
    python3 -c 'import os, pwd, socket, ssl; assert pwd.getpwuid(os.getuid()).pw_name == "opencode-web"; assert socket.getaddrinfo("localhost", 443); assert ssl.create_default_context().get_ca_certs()'
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
in
  pkgs.testers.runNixOSTest {
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
        serviceConfig =
          (builtins.removeAttrs service.serviceConfig ["ExecStart" "EnvironmentFile" "Restart" "RestartSec"])
          // {
            ExecStart = probe;
            Type = "oneshot";
            RemainAfterExit = true;
          };
      };
    };
    testScript = ''
      machine.start()
      machine.wait_for_unit("multi-user.target")
      for path in ${builtins.toJSON deniedPaths}:
          machine.succeed(f"runuser -u opencode-web -- cat {path}")
      machine.succeed("systemctl start opencode-web.service")
      machine.succeed("journalctl -u opencode-web.service --no-pager | grep 'Denied synthetic path: /srv/world-readable-project/README'")
      machine.succeed("test -r /var/lib/opencode-web/workspace/probe")
    '';
  }
