"""Server deployment readiness. External commands are the only test boundaries."""

import argparse
from datetime import date
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import time


ROOT = Path(__file__).resolve().parents[2]
REVIEW_CHECKS = (
    "configuration", "paired-services", "backup-restore",
    "independent-access", "retained-generations", "owner-build",
)


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def run(*args, text=None):
    result = subprocess.run(args, input=text, capture_output=True, text=True, timeout=240)
    if result.returncode:
        details = f"\n{result.stderr.strip()}" if args[0] == "nix" else ""
        raise RuntimeError(f"{args[0]} failed (exit {result.returncode}); no activation attempted{details}")
    return result.stdout


def version(value):
    if not isinstance(value, str):
        raise ValueError("unknown version")
    if re.fullmatch(r"\d{4}-\d{2}-\d{2}", value):
        date.fromisoformat(value)
        value = value.replace("-", ".")
    match = re.fullmatch(
        r"(\d+(?:\.\d+){0,11})(?:-?(dev|alpha|a|beta|b|pre|rc)[.-]?(\d+)?)?"
        r"(-rocm)?(?:\+[a-zA-Z0-9.-]+)?", value,
    )
    if not match:
        raise ValueError("unsupported version format")
    numbers = tuple(int(part) for part in match[1].split("."))
    rank = {None: 5, "dev": 0, "alpha": 1, "a": 1, "beta": 2, "b": 2, "pre": 3, "rc": 4}
    return numbers + (0,) * (12 - len(numbers)), rank[match[2]], int(match[3] or 0), match[4] or ""


def comparison(name, deployed, candidate, comparisons, blockers):
    reason = None
    try:
        candidate_version = version(candidate)
        deployed_version = version(deployed)
        if candidate_version[3] != deployed_version[3]:
            reason = "unreviewed version variant"
        elif candidate_version < deployed_version:
            reason = "downgrade"
    except ValueError as error:
        reason = str(error)
    comparisons.append({
        "name": name, "deployed": deployed, "candidate": candidate,
        "result": "blocked" if reason else "pass", "reason": reason,
    })
    if reason:
        blockers.append(f"{name}: {reason} ({deployed!r} -> {candidate!r})")


def snapshot():
    return json.loads(run(
        "nix", "flake", "archive", "--json", "--no-write-lock-file", "--no-update-lock-file", ".",
    ))["path"]


def collect(host, target, state, source):
    bootstrap = None
    try:
        deployed = json.loads(run(
            "ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=10", "--", target,
            "cat /run/current-system/etc/dotfiles/server-manifest.json",
        ))
    except RuntimeError as error:
        path = state / f"{host}-bootstrap.json"
        if not path.exists():
            raise RuntimeError(f"{error}. No deployed manifest; owner-reviewed bootstrap evidence is required") from error
        bootstrap = json.loads(path.read_text())
        if not bootstrap["source"].strip() or not bootstrap["reviewedBy"].strip():
            raise ValueError("Bootstrap source and reviewer are required")
        deployed = bootstrap["manifest"]
    python = deployed["collectorPython"]
    if not re.fullmatch(r"/nix/store/[a-z0-9]{32}-[^/\s]+/bin/python3(?:\.\d+)?", python):
        raise ValueError("invalid deployed collector Python")
    evidence = json.loads(run(
        "ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=10", "--", target,
        f"sudo -n {shlex.quote(python)} -I -",
        text=(f"BOOTSTRAP = {bootstrap!r}\n" if bootstrap else "")
        + (Path(source) / "scripts/server-readiness/collect.py").read_text(),
    ))
    if evidence["manifest"] != deployed:
        raise ValueError("deployed manifest changed during collection")
    return evidence


def evidence_identity(evidence):
    return digest({key: value for key, value in evidence.items()
                   if key not in ("capturedAt", "finishedAt")})


def validate_live(host, evidence, blockers):
    deployed = evidence["manifest"]
    if evidence["schemaVersion"] != 1 or deployed["schemaVersion"] != 1:
        blockers.append("Unsupported deployed evidence schema")
    if evidence["host"] != host or deployed["host"] != host:
        blockers.append("Deployment evidence belongs to a different host")
    aliases = {"homelab": {"homelab"}, "vps": {"vps", "hostinger"}}
    if evidence["hostname"] not in aliases[host]:
        blockers.append("Unexpected remote hostname")
    if not 0 <= time.time() - evidence["capturedAt"] <= 300:
        blockers.append("Deployment evidence is stale or in the future")
    if not evidence["capturedAt"] <= evidence["finishedAt"] <= time.time() + 5:
        blockers.append("Invalid collection timestamps")
    identities = {evidence[key] for key in ("systemPath", "profilePath", "finalSystemPath")}
    if len(identities) != 1 or not evidence["systemPath"].startswith("/nix/store/"):
        blockers.append("Running, deployed, or final System identities differ")
    blockers.extend(evidence["errors"])
    blockers.extend(deployed["blockers"])
    validate_units(deployed, evidence, blockers)


def validate_units(deployed, evidence, blockers):
    for name, unit in deployed["units"].items():
        live = evidence["units"].get(name, {})
        executable = live.get("executable", "")
        valid = any(executable.startswith(path + "/") for path in unit["executables"])
        valid = valid or executable in live.get("resolvedExecutables", [])
        if live.get("active") != "active" or live.get("start") != unit["start"] or not valid:
            blockers.append(f"{name}: unresolved running/deployed service identity")


def validate_candidate(host, manifest, deployed, baseline, blockers):
    if manifest["schemaVersion"] != 1 or manifest["host"] != host:
        blockers.append("Invalid candidate manifest schema or host")
    blockers.extend(manifest["blockers"])
    if manifest["stateVersions"] != deployed["stateVersions"]:
        blockers.append("State Versions changed")
    expected = baseline["hosts"][host]
    if manifest["stateVersions"] != {
        "system": expected["systemStateVersion"], "home": expected["homeStateVersion"],
    }:
        blockers.append("State Versions differ from the accepted baseline")
    if manifest["source"]["kind"] == "preserved":
        if manifest["source"]["revision"] != baseline["nixpkgsRevision"]:
            blockers.append("Preserved server source changed")
    elif manifest["source"]["kind"] == "release":
        if not re.fullmatch(r"nixos-\d{2}\.(05|11)", manifest["source"]["channel"]):
            blockers.append("Candidate must use a named Release Channel")
    else:
        blockers.append("Unknown candidate source policy")


def compare_packages(deployed, candidate, comparisons, blockers):
    if not deployed["packages"] or not candidate["packages"]:
        blockers.append("Empty managed service inventory")
    for name, package in candidate["packages"].items():
        try:
            version(package["version"])
            if not package["family"] or not package["path"].startswith("/nix/store/"):
                raise ValueError("unknown package identity")
        except (ValueError, TypeError):
            blockers.append(f"{name}: unknown candidate version or package identity")
        if name not in deployed["packages"]:
            comparison(name, package["version"], package["version"], comparisons, blockers)
    for name, old in deployed["packages"].items():
        new = candidate["packages"].get(name)
        if not new:
            blockers.append(f"{name}: missing candidate inventory entry")
            comparison(name, old["version"], None, comparisons, blockers)
            continue
        if old["family"] != new["family"]:
            blockers.append(f"{name}: unreviewed package-family change")
        comparison(name, old["version"], new["version"], comparisons, blockers)


def compare_database(deployed, candidate, evidence, comparisons, blockers):
    if not deployed["database"]:
        if candidate["database"]:
            blockers.append("Unreviewed database addition")
        return
    database = candidate["database"]
    live = evidence["database"]
    if not database or not live:
        blockers.append("Missing database evidence")
        return
    if database["major"] != "17" or deployed["database"]["major"] != "17":
        blockers.append("PostgreSQL must remain on major 17")
    comparison("live/postgresql", live["version"], candidate["packages"]["postgresql"]["version"],
               comparisons, blockers)
    if version(live["version"]) != version(deployed["packages"]["postgresql"]["version"]):
        blockers.append("Running PostgreSQL differs from the deployed manifest")
    for name, package in database["extensions"].items():
        comparison(f"live/extension/{name}", live["extensions"].get(name), package["version"],
                   comparisons, blockers)
    known_extensions = {"cube", "earthdistance", "pg_trgm", "plpgsql", "unaccent", "uuid-ossp"}
    unknown = set(live["extensions"]) - set(database["extensions"]) - known_extensions
    blockers.extend(f"Untracked installed database extension: {name}" for name in sorted(unknown))
    comparison("live/zwave-js-driver", evidence["driverVersion"],
               candidate["packages"]["zwave-js-driver"]["version"], comparisons, blockers)


def compare_containers(deployed, candidate, evidence, blockers):
    if set(deployed["containers"]) != set(candidate["containers"]):
        blockers.append("Changed or missing OCI container inventory")
    for name, container in candidate["containers"].items():
        image = container["image"]
        old = deployed["containers"].get(name, {})
        live = evidence["containers"].get(name, {})
        if not re.fullmatch(r"[^@\s]+@sha256:[a-f0-9]{64}", image):
            blockers.append(f"{name}: expected a registry manifest digest, not a tag or image ID")
        if image != old.get("image") or image not in (live.get("digests") or []):
            blockers.append(f"{name}: changed or unknown registry digest")
        if not live.get("running"):
            blockers.append(f"{name}: container is not running")


def baseline_floors(host, candidate, baseline, comparisons, blockers):
    for name, floor in baseline["hosts"][host]["serviceVersions"].items():
        comparison(f"accepted/{name}", floor, candidate["packages"].get(name, {}).get("version"),
                   comparisons, blockers)
    if host == "homelab":
        for name, floor in baseline["hosts"][host]["postgresqlExtensions"].items():
            comparison(f"accepted/{name}", floor,
                       candidate["packages"].get(f"postgresql/{name}", {}).get("version"),
                       comparisons, blockers)
        if candidate["containers"].get("paperless-gpt", {}).get("image") != baseline["paperlessGpt"]["image"]:
            blockers.append("paperless-gpt differs from its accepted registry digest")


def review_acceptance(report, candidate, acceptance, blockers):
    if acceptance.get("candidateId") != report["candidateId"]:
        blockers.append("Owner acceptance is missing or belongs to a different candidate")
    if acceptance.get("deployedEvidenceId") != report["deployedEvidenceId"]:
        blockers.append("Owner acceptance does not match the current deployed evidence")
    required = list(REVIEW_CHECKS)
    if candidate["source"]["kind"] == "release":
        required.append("released-channel")
    checks = acceptance.get("checks", {})
    for name in required:
        check = checks.get(name, {})
        if check.get("status") != "accepted" or not check.get("evidence", "").strip():
            blockers.append(f"Owner acceptance required: {name}")
    report["acceptanceTemplate"] = {
        "candidateId": report["candidateId"], "deployedEvidenceId": report["deployedEvidenceId"],
        "checks": {name: {"status": "pending", "evidence": ""} for name in required},
    }


def check(host, target, selection, acceptance, state):
    frozen = snapshot()
    output = "serverReadiness" if selection == "active" else "serverCandidates"
    candidate = json.loads(run(
        "nix", "eval", "--json", "--no-write-lock-file", "--no-update-lock-file",
        f"{frozen}#lib.{output}.{host}",
    ))
    manifest = candidate["manifest"]
    baseline = json.loads((Path(frozen) / "checks/server-baseline.json").read_text())
    evidence = collect(host, target, state, frozen)
    blockers = []
    comparisons = []
    validate_live(host, evidence, blockers)
    validate_candidate(host, manifest, evidence["manifest"], baseline, blockers)
    compare_packages(evidence["manifest"], manifest, comparisons, blockers)
    if set(manifest["units"]) != set(evidence["manifest"]["units"]):
        blockers.append("Changed or missing managed service units")
    compare_database(evidence["manifest"], manifest, evidence, comparisons, blockers)
    compare_containers(evidence["manifest"], manifest, evidence, blockers)
    baseline_floors(host, manifest, baseline, comparisons, blockers)
    accepted_path = state / f"{host}-accepted.json"
    accepted = {}
    if accepted_path.exists():
        accepted = json.loads(accepted_path.read_text())
        if accepted["manifest"]["host"] != host:
            blockers.append("Accepted deployment record belongs to a different host")
        compare_packages(accepted["manifest"], manifest, comparisons, blockers)
    report = {
        "host": host, "target": target, "selection": selection, "source": frozen,
        "candidate": candidate, "deployedSystem": evidence["systemPath"],
        "deployedEvidence": evidence,
        "acceptedEvidenceId": digest(accepted),
        "candidateId": digest({
            "source": frozen, "target": target, "selection": selection,
            "acceptedEvidenceId": digest(accepted), **candidate,
        }),
        "deployedEvidenceId": evidence_identity(evidence),
        "versionGate": "blocked" if any(c["result"] == "blocked" for c in comparisons) else "pass",
        "compatibility": "unchanged" if manifest["compatibility"] == evidence["manifest"]["compatibility"]
        else "changed",
        "comparisons": comparisons, "blockers": blockers,
    }
    before_acceptance = len(blockers)
    review_acceptance(report, manifest, acceptance, blockers)
    report["ownerAcceptance"] = "accepted" if len(blockers) == before_acceptance else "required"
    report["ready"] = not blockers
    return report


def deploy(report, args, state, path, acceptance):
    if args.selection != "active":
        raise ValueError("Release candidates are inspect-only; review active host selection before deployment")
    command = [
        "nixos-rebuild", "build", "--flake", f"{report['source']}#{args.host}",
        "--target-host", args.target, "--sudo", "--no-link", "--no-update-lock-file",
    ]
    if args.host == "homelab":
        command.extend(("--build-host", args.target))
    built = subprocess.run(command, stdout=subprocess.PIPE, text=True, check=False)
    if built.returncode or built.stdout.strip() != report["candidate"]["systemPath"]:
        raise ValueError("Owner build failed or produced a different System identity")
    if snapshot() != report["source"]:
        raise ValueError("Source or lock changed after readiness checking")
    fresh = collect(args.host, args.target, state, report["source"])
    live_blockers = []
    validate_live(args.host, fresh, live_blockers)
    if live_blockers or evidence_identity(fresh) != report["deployedEvidenceId"]:
        raise ValueError("Deployed evidence changed before activation")
    if json.loads(path.read_text()) != acceptance:
        raise ValueError("Owner acceptance changed before activation")
    accepted_path = state / f"{args.host}-accepted.json"
    accepted = json.loads(accepted_path.read_text()) if accepted_path.exists() else {}
    if digest(accepted) != report["acceptedEvidenceId"]:
        raise ValueError("Accepted deployment evidence changed before activation")
    command[1] = "switch"
    print(json.dumps(report, indent=2, sort_keys=True), flush=True)
    return subprocess.run(command, check=False).returncode


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("operation", choices=("check", "deploy"))
    parser.add_argument("host", choices=("homelab", "vps"))
    parser.add_argument("target")
    parser.add_argument("selection", nargs="?", default="active", choices=("active", "release"))
    args = parser.parse_args()
    os.chdir(ROOT)
    if not re.fullmatch(r"[a-zA-Z0-9_][a-zA-Z0-9_.@:-]*", args.target):
        parser.error("invalid SSH target")
    state = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "dotfiles/server-readiness"
    path = state / f"{args.host}-acceptance.json"
    report = {"host": args.host, "ready": False, "blockers": []}
    try:
        acceptance = json.loads(path.read_text()) if path.exists() else {}
        report = check(args.host, args.target, args.selection, acceptance, state)
        if not report["ready"] or args.operation == "check":
            print(json.dumps(report, indent=2, sort_keys=True), flush=True)
            return 0 if report["ready"] else 1
        return deploy(report, args, state, path, acceptance)
    except (OSError, ValueError, KeyError, TypeError, AttributeError, IndexError,
            RuntimeError, subprocess.TimeoutExpired) as error:
        report["ready"] = False
        report["blockers"].append(str(error))
        print(json.dumps(report, indent=2, sort_keys=True), flush=True)
        return 1


if __name__ == "__main__":
    sys.exit(main())
