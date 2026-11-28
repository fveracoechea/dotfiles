"""Exercise the real just recipes with fake Nix, SSH, and activation executables."""

import copy
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
import unittest


ROOT = Path(__file__).resolve().parents[2]
FAKE = r"""
import json, os, pathlib, sys
p = pathlib.Path(os.environ["READINESS_FIXTURE"])
fixture = json.loads(p.read_text())
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
state_path = p.with_suffix(".state")
state = json.loads(state_path.read_text()) if state_path.exists() else {"archives": 0, "collections": 0}
if name == "nix":
    if args[:2] == ["flake", "archive"]:
        state["archives"] += 1
        changed = fixture.get("changeSource") and state["archives"] > 1
        print(json.dumps({"path": fixture["source"] + ("-changed" if changed else "")}))
    elif args[0] == "eval":
        print(json.dumps(fixture["candidate"]))
    elif args[:2] != ["flake", "check"]:
        sys.exit(9)
elif name == "ssh":
    if fixture.get("sshFailure"):
        sys.exit(255)
    if args[-1].startswith("cat "):
        if fixture.get("missingManifest"):
            sys.exit(1)
        print(json.dumps(fixture["evidence"]["manifest"]))
    else:
        sys.stdin.read()
        state["collections"] += 1
        evidence = fixture["evidence"]
        if fixture.get("changeLive") and state["collections"] > 1:
            evidence["systemPath"] += "-changed"
        print(json.dumps(evidence))
elif name == "nixos-rebuild":
    if args[0] == "build":
        print(fixture["candidate"]["systemPath"] + ("-wrong" if fixture.get("wrongBuild") else ""))
        state_directory = pathlib.Path(os.environ["XDG_STATE_HOME"]) / "dotfiles/server-readiness"
        host = fixture["evidence"]["host"]
        if fixture.get("changeAccepted"):
            (state_directory / f"{host}-accepted.json").write_text(json.dumps(fixture["evidence"]))
        if fixture.get("changeAcceptance"):
            (state_directory / f"{host}-acceptance.json").write_text("{}")
    else:
        with p.with_suffix(".activation").open("a") as f:
            f.write(json.dumps(args) + "\n")
else:
    sys.exit(8)
state_path.write_text(json.dumps(state))
"""


def store(name):
    return "/nix/store/" + "a" * 32 + "-" + name


def package(name, version):
    return {"family": name, "version": version, "path": store(f"{name}-{version}")}


class DeploymentTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(
            prefix="server-readiness-", dir=os.environ.get("TMPDIR", "/tmp/opencode")
        )
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for relative in ("justfile", "scripts/server-readiness/gate.py",
                         "scripts/server-readiness/collect.py", "checks/server-baseline.json"):
            destination = self.root / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / relative, destination)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for name in ("nix", "ssh", "nixos-rebuild"):
            executable = self.bin / name
            executable.write_text(f"#!{sys.executable}\n" + FAKE)
            executable.chmod(0o755)
        self.path = self.root / "fixture.json"
        self.env = {
            **os.environ, "PATH": f"{self.bin}:{os.environ['PATH']}",
            "XDG_STATE_HOME": str(self.root / "state"),
            "READINESS_FIXTURE": str(self.path),
        }

    def prepare(self, host="homelab"):
        self.host = host
        baseline = json.loads((self.root / "checks/server-baseline.json").read_text())
        packages = {name: package(name, v)
                    for name, v in baseline["hosts"][host]["serviceVersions"].items()}
        database = None
        containers = {}
        if host == "homelab":
            packages.update({
                "immich/nodejs": package("nodejs", "24.18.1"),
                "postgresql/pgvector": package("pgvector", "0.8.6"),
                "postgresql/vectorchord": package("vectorchord", "1.1.1"),
                "zwave-js-driver": package("zwave-js-driver", "15.24.2"),
            })
            database = {
                "name": "immich", "major": "17",
                "extensions": {
                    "vector": packages["postgresql/pgvector"],
                    "vchord": packages["postgresql/vectorchord"],
                }, "psql": store("postgresql") + "/bin/psql",
            }
            containers = {"paperless-gpt": {
                "image": baseline["paperlessGpt"]["image"],
                "autoStart": True, "configuration": "container-config",
            }}
        unit_name = "immich-server" if host == "homelab" else "headscale"
        executable = packages["immich/nodejs" if host == "homelab" else "headscale"]["path"]
        unit = {
            "start": packages["immich" if host == "homelab" else "headscale"]["path"] + "/bin/server",
            "executables": [executable], "configuration": "unit-config",
        }
        manifest = {
            "schemaVersion": 1, "host": host,
            "source": {"kind": "preserved", "revision": baseline["nixpkgsRevision"]},
            "collectorPython": store("python3-3.14.6") + "/bin/python3.14",
            "packages": packages, "units": {unit_name: unit}, "containers": containers,
            "database": database, "stateVersions": {
                "system": baseline["hosts"][host]["systemStateVersion"],
                "home": baseline["hosts"][host]["homeStateVersion"],
            }, "compatibility": "compatibility-config", "blockers": [],
        }
        self.fixture = {
            "source": str(self.root),
            "candidate": {
                "manifest": copy.deepcopy(manifest),
                "systemPath": store("candidate-system"), "systemDrv": store("candidate-system.drv"),
            },
            "evidence": {
                "schemaVersion": 1, "host": host, "hostname": host,
                "capturedAt": int(time.time()), "finishedAt": int(time.time()),
                "systemPath": store("deployed-system"),
                "profilePath": store("deployed-system"),
                "finalSystemPath": store("deployed-system"),
                "manifest": manifest, "errors": [],
                "units": {unit_name: {
                    "active": "active", "start": unit["start"], "executable": executable + "/bin/server",
                }},
                "containers": {name: {
                    "running": True, "configId": "sha256:" + "b" * 64,
                    "digests": [c["image"]],
                } for name, c in containers.items()},
                "database": {
                    "version": "17.10", "extensions": {"vector": "0.8.6", "vchord": "1.1.1"},
                } if database else None,
                "driverVersion": "15.24.2" if database else None,
            },
        }
        self.save()

    def save(self):
        self.path.write_text(json.dumps(self.fixture))

    def command(self, recipe=None, *arguments):
        self.save()
        state = self.path.with_suffix(".state")
        state.unlink(missing_ok=True)
        result = subprocess.run(
            ["just", "--justfile", str(self.root / "justfile"),
             recipe or f"deploy-{self.host}", *arguments],
            cwd=self.root, env=self.env, text=True, capture_output=True, timeout=30,
        )
        output = result.stdout.strip()
        return result, json.JSONDecoder().raw_decode(output)[0] if output else {}

    def accept(self, target=None):
        result, report = self.command("server-readiness", self.host, target or self.host)
        self.assertIn(result.returncode, (0, 1), result.stderr)
        template = report["acceptanceTemplate"]
        for check in template["checks"].values():
            check.update(status="accepted", evidence="Owner-run fixture acceptance")
        path = Path(self.env["XDG_STATE_HOME"]) / "dotfiles/server-readiness" / f"{self.host}-acceptance.json"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(template))

    def assert_blocked(self, reason):
        result, report = self.command()
        self.assertNotEqual(result.returncode, 0, result.stderr)
        self.assertIn(reason, "\n".join(report["blockers"]))
        self.assertFalse(self.path.with_suffix(".activation").exists())
        return report

    def test_both_real_recipes_deploy_the_checked_snapshot(self):
        for host in ("homelab", "vps"):
            with self.subTest(host=host):
                self.path.with_suffix(".activation").unlink(missing_ok=True)
                self.prepare(host)
                self.accept()
                result, report = self.command()
                self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
                self.assertTrue(report["ready"])
                command = json.loads(self.path.with_suffix(".activation").read_text())
                self.assertEqual(command[command.index("--flake") + 1], f"{self.root}#{host}")
                self.assertEqual("--build-host" in command, host == "homelab")
                self.assertIn("--no-link", command)
                self.assertIn("--no-update-lock-file", command)

    def test_supported_forward_update(self):
        self.prepare()
        self.fixture["candidate"]["manifest"]["packages"]["immich"]["version"] = "3.10.0"
        self.accept()
        result, report = self.command()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(report["versionGate"], "pass")

    def test_read_only_check_never_activates(self):
        self.prepare("vps")
        self.accept()
        result, report = self.command("server-readiness", "vps")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(report["ready"])
        self.assertFalse(self.path.with_suffix(".activation").exists())

    def test_historical_immich_and_extension_downgrades_aggregate(self):
        self.prepare()
        manifest = self.fixture["candidate"]["manifest"]
        manifest["packages"]["immich"]["version"] = "2.7.5"
        manifest["packages"]["postgresql/pgvector"]["version"] = "0.8.2"
        report = self.assert_blocked("immich: downgrade")
        self.assertIn("live/extension/vector: downgrade", "\n".join(report["blockers"]))
        self.assertEqual(report["versionGate"], "blocked")

    def test_runtime_downgrade(self):
        self.prepare()
        self.fixture["candidate"]["manifest"]["packages"]["immich/nodejs"]["version"] = "22.20.0"
        self.assert_blocked("immich/nodejs: downgrade")

    def test_version_ordering(self):
        cases = [
            ("1.9", "1.10", True), ("2026-08-01", "2026-11-01", True),
            ("1.0rc1", "1.0", True), ("1.0", "1.0-beta2", False),
            ("1.0rc2", "1.0rc10", True), ("1.0", "1.0.0", True),
            ("1.0", "nightly", False), ("unknown", "1.0", False),
            ("22.0.0-rocm", "22.1.0-rocm", True),
        ]
        for deployed, candidate, passes in cases:
            with self.subTest(deployed=deployed, candidate=candidate):
                self.prepare("vps")
                self.fixture["evidence"]["manifest"]["packages"]["extra"] = package("extra", deployed)
                self.fixture["candidate"]["manifest"]["packages"]["extra"] = package("extra", candidate)
                self.accept()
                result, report = self.command()
                self.assertEqual(result.returncode == 0, passes, result.stdout + result.stderr)

    def test_inventory_versions_families_and_state_fail_closed(self):
        for mutation, reason in (
            (lambda m: m["packages"].pop("immich"), "missing candidate inventory"),
            (lambda m: m["packages"]["immich"].update(version=None), "unknown"),
            (lambda m: m["packages"]["immich"].update(family="other"), "package-family"),
            (lambda m: m["blockers"].append("Unregistered host service file"), "Unregistered"),
            (lambda m: m["stateVersions"].update(system="26.11"), "State Versions"),
            (lambda m: m["database"].update(major="18"), "major 17"),
        ):
            with self.subTest(reason=reason):
                self.prepare()
                mutation(self.fixture["candidate"]["manifest"])
                self.assert_blocked(reason)

    def test_missing_stale_failed_and_mismatched_live_evidence(self):
        for mutation, reason in (
            (lambda e: e.update(capturedAt=int(time.time()) - 3600), "stale"),
            (lambda e: e["errors"].append("Failed unit probe"), "Failed unit probe"),
            (lambda e: e.update(profilePath=store("other")), "System identities differ"),
            (lambda e: e["units"]["immich-server"].update(executable=store("other") + "/bin/node"),
             "running/deployed service identity"),
            (lambda e: e.update(host="vps"), "different host"),
            (lambda e: e["database"]["extensions"].pop("vector"), "unknown version"),
        ):
            with self.subTest(reason=reason):
                self.prepare()
                mutation(self.fixture["evidence"])
                self.assert_blocked(reason)

    def test_container_identity_is_not_an_image_configuration_id(self):
        for value in ("latest", "sha256:" + "b" * 64, "repo@sha256:" + "c" * 64):
            with self.subTest(value=value):
                self.prepare()
                self.fixture["candidate"]["manifest"]["containers"]["paperless-gpt"]["image"] = value
                self.assert_blocked("registry")

    def test_live_registry_digest_cannot_be_replaced_with_config_id(self):
        self.prepare()
        live = self.fixture["evidence"]["containers"]["paperless-gpt"]
        live["digests"] = [live["configId"]]
        self.assert_blocked("changed or unknown registry digest")

    def test_postgres_minor_upgrade_does_not_allow_extension_downgrade(self):
        self.prepare()
        self.fixture["candidate"]["manifest"]["packages"]["postgresql"]["version"] = "17.11"
        self.fixture["evidence"]["database"]["extensions"]["vector"] = "0.8.7"
        self.assert_blocked("live/extension/vector: downgrade")

    def test_owner_acceptance_is_bound_and_never_updated(self):
        self.prepare()
        self.accept()
        state = Path(self.env["XDG_STATE_HOME"])
        before = {p: p.read_bytes() for p in state.rglob("*.json")}
        self.fixture["candidate"]["manifest"]["packages"]["immich"]["version"] = "3.2.0"
        self.assert_blocked("different candidate")
        self.assertEqual(before, {p: p.read_bytes() for p in state.rglob("*.json")})

    def test_changes_after_check_block_activation(self):
        for flag, reason in (("changeSource", "Source or lock changed"),
                             ("changeLive", "Deployed evidence changed"),
                             ("changeAccepted", "Accepted deployment evidence changed"),
                             ("changeAcceptance", "Owner acceptance changed")):
            with self.subTest(flag=flag):
                self.prepare()
                self.accept()
                self.fixture[flag] = True
                result, output = self.command()
                self.assertNotEqual(result.returncode, 0, result.stderr)
                self.assertIn(reason, result.stdout)
                self.assertFalse(self.path.with_suffix(".activation").exists())

    def test_legacy_vps_target_is_preserved(self):
        self.prepare("vps")
        self.fixture["evidence"]["hostname"] = "hostinger"
        self.accept("hostinger")
        result, report = self.command("deploy-vps", "hostinger")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(report["target"], "hostinger")

    def test_unavailable_host_fails_without_activation(self):
        self.prepare("vps")
        self.fixture["sshFailure"] = True
        self.assert_blocked("ssh failed")

    def test_wrong_built_system_never_activates(self):
        self.prepare("vps")
        self.accept()
        self.fixture["wrongBuild"] = True
        self.assert_blocked("different System identity")

    def test_initial_manifest_requires_reviewed_bootstrap(self):
        self.prepare("vps")
        self.fixture["missingManifest"] = True
        self.assert_blocked("owner-reviewed bootstrap evidence is required")
        state = Path(self.env["XDG_STATE_HOME"]) / "dotfiles/server-readiness"
        state.mkdir(parents=True, exist_ok=True)
        bootstrap = {
            "manifest": self.fixture["evidence"]["manifest"],
            "systemPath": self.fixture["evidence"]["systemPath"],
            "source": "immutable deployed source", "reviewedBy": "",
        }
        path = state / "vps-bootstrap.json"
        path.write_text(json.dumps(bootstrap))
        self.assert_blocked("Bootstrap source and reviewer are required")
        bootstrap["reviewedBy"] = "Owner fixture"
        path.write_text(json.dumps(bootstrap))
        self.accept()
        result, report = self.command()
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)

    def test_accepted_deployment_remains_a_version_floor(self):
        self.prepare()
        accepted = copy.deepcopy(self.fixture["evidence"])
        accepted["manifest"]["packages"]["immich"]["version"] = "4.0.0"
        state = Path(self.env["XDG_STATE_HOME"]) / "dotfiles/server-readiness"
        state.mkdir(parents=True, exist_ok=True)
        path = state / "homelab-accepted.json"
        contents = json.dumps(accepted)
        path.write_text(contents)
        self.assert_blocked("immich: downgrade")
        self.assertEqual(path.read_text(), contents)

    def test_blocked_homelab_does_not_block_vps(self):
        self.prepare()
        self.fixture["candidate"]["manifest"]["packages"]["immich"]["version"] = "2.7.5"
        self.assert_blocked("immich: downgrade")
        self.prepare("vps")
        self.accept()
        result, report = self.command()
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)

    def test_real_evaluated_manifests_through_deployment_recipes(self):
        if "READINESS_MANIFESTS" not in os.environ:
            self.skipTest("Evaluated manifests are supplied by the flake check")
        manifests = json.loads(Path(os.environ["READINESS_MANIFESTS"]).read_text())
        for host, manifest in manifests.items():
            with self.subTest(host=host):
                self.path.with_suffix(".activation").unlink(missing_ok=True)
                self.prepare(host)
                self.fixture["candidate"]["manifest"] = copy.deepcopy(manifest)
                evidence = self.fixture["evidence"]
                evidence["manifest"] = manifest
                evidence["units"] = {
                    name: {
                        "active": "active", "start": unit["start"],
                        "executable": unit["executables"][0] + "/bin/service",
                    } for name, unit in manifest["units"].items()
                }
                self.accept()
                result, report = self.command()
                self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
                self.assertEqual(report["versionGate"], "pass")

    def test_bootstrap_collector_uses_only_read_only_probes(self):
        self.prepare()
        manifest = self.fixture["evidence"]["manifest"]
        systemctl = self.bin / "systemctl"
        systemctl.write_text(
            f"#!{sys.executable}\nimport os\n"
            f"print('ActiveState=active\\nExecStart={{ path={manifest['units']['immich-server']['start']} ; }}')\n"
            "print('MainPID=' + str(os.getppid()))\n"
        )
        systemctl.chmod(0o755)
        podman = self.bin / "podman"
        image = manifest["containers"]["paperless-gpt"]["image"]
        podman.write_text(
            f"#!{sys.executable}\nimport sys\n"
            f"print('sha256:configuration true' if 'container' in sys.argv else {json.dumps([image])!r})\n"
        )
        podman.chmod(0o755)
        sudo = self.bin / "sudo"
        sudo.write_text(
            f"#!{sys.executable}\nimport sys\n"
            "print('17.10' if 'SHOW server_version;' in sys.argv else 'vector|0.8.6\\nvchord|1.1.1')\n"
        )
        sudo.chmod(0o755)
        # This fixture omits the driver file, which must be a reported probe failure.
        bootstrap = {
            "systemPath": os.path.realpath("/run/current-system"),
            "manifest": manifest, "source": "owner-reviewed fixture", "reviewedBy": "fixture",
        }
        script = f"BOOTSTRAP = {bootstrap!r}\n" + (ROOT / "scripts/server-readiness/collect.py").read_text()
        result = subprocess.run(
            [sys.executable, "-I", "-"], input=script, env=self.env,
            text=True, capture_output=True, timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        evidence = json.loads(result.stdout)
        self.assertEqual(evidence["units"]["immich-server"]["active"], "active")
        self.assertEqual(evidence["containers"]["paperless-gpt"]["digests"], [image])
        self.assertEqual(evidence["database"]["extensions"]["vector"], "0.8.6")
        self.assertIn("Failed database or Z-Wave driver probe", evidence["errors"])


if __name__ == "__main__":
    unittest.main()
