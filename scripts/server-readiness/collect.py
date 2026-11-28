"""Read-only probes sent to the Python recorded in the deployed manifest."""

import json
import os
from pathlib import Path
import re
import socket
import subprocess
import time


def run(*args):
    result = subprocess.run(args, capture_output=True, text=True, timeout=30)
    if result.returncode:
        raise RuntimeError(f"{args[0]} probe failed")
    return result.stdout.strip()


def unit_evidence(name, unit):
    properties = run(
        "systemctl", "show", f"{name}.service",
        "--property=ActiveState,MainPID,ExecStart",
    )
    values = dict(line.split("=", 1) for line in properties.splitlines())
    start = re.search(r"path=([^ ;}]+)", values["ExecStart"])
    executable = os.readlink(f"/proc/{int(values['MainPID'])}/exe")
    resolved = []
    for package in unit["executables"]:
        binary = Path(package, "bin", Path(executable).name)
        if binary.exists():
            resolved.append(os.path.realpath(binary))
    return {
        "active": values["ActiveState"],
        "start": start.group(1) if start else None,
        "executable": executable,
        "resolvedExecutables": resolved,
    }


def container_evidence(name):
    identity = run("podman", "container", "inspect", "--format",
                   "{{.Image}} {{.State.Running}}", name).split()
    digests = sorted(json.loads(run("podman", "image", "inspect", "--format",
                                   "{{json .RepoDigests}}", identity[0])) or [])
    return {"running": identity[1] == "true", "configId": identity[0], "digests": digests}


def database_evidence(database):
    command = [
        "sudo", "-n", "-u", "postgres", database["psql"],
        "--no-psqlrc", "--set=ON_ERROR_STOP=1", f"--dbname={database['name']}",
        "--tuples-only", "--no-align",
    ]
    extensions = run(*command, "--command",
                     "BEGIN READ ONLY; SELECT extname, extversion FROM pg_extension; COMMIT;")
    return {
        "version": run(*command, "--command", "SHOW server_version;").split()[0],
        "extensions": dict(line.split("|") for line in extensions.splitlines() if "|" in line),
    }


def collect(bootstrap=None):
    current = os.path.realpath("/run/current-system")
    manifest = bootstrap["manifest"] if bootstrap else json.loads(
        Path(current, "etc/dotfiles/server-manifest.json").read_text()
    )
    evidence = {
        "schemaVersion": 1, "host": manifest["host"], "hostname": socket.gethostname(),
        "capturedAt": int(time.time()), "systemPath": current,
        "profilePath": os.path.realpath("/nix/var/nix/profiles/system"),
        "manifest": manifest, "units": {}, "containers": {}, "errors": [],
        "database": None, "driverVersion": None,
        "provenance": {
            "kind": "owner-bootstrap", "source": bootstrap["source"],
            "reviewedBy": bootstrap["reviewedBy"],
        } if bootstrap else {"kind": "installed-manifest"},
    }
    if bootstrap and bootstrap["systemPath"] != current:
        evidence["errors"].append("Bootstrap evidence does not match the running generation")
    for name in manifest["units"]:
        try:
            evidence["units"][name] = unit_evidence(name, manifest["units"][name])
        except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired):
            evidence["errors"].append(f"Failed unit probe: {name}")
    for name in manifest["containers"]:
        try:
            evidence["containers"][name] = container_evidence(name)
        except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired):
            evidence["errors"].append(f"Failed container probe: {name}")
    if manifest["database"]:
        try:
            evidence["database"] = database_evidence(manifest["database"])
            root = manifest["packages"]["zwave-js"]["path"]
            driver = Path(root, "lib/node_modules/@zwave-js/server/node_modules/zwave-js/package.json")
            evidence["driverVersion"] = json.loads(driver.read_text())["version"]
        except (OSError, ValueError, KeyError, RuntimeError, subprocess.TimeoutExpired):
            evidence["errors"].append("Failed database or Z-Wave driver probe")
    evidence["finishedAt"] = int(time.time())
    evidence["finalSystemPath"] = os.path.realpath("/run/current-system")
    return evidence


if __name__ == "__main__":
    print(json.dumps(collect(globals().get("BOOTSTRAP")), sort_keys=True))
