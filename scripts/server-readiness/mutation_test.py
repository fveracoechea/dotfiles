"""Confirm the deployment tests reject broken downgrade and source-change guards."""

import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[2]
MUTATIONS = (
    ("downgrade comparison", 'elif candidate_version < deployed_version:', "elif False:",
     "test_historical_immich_and_extension_downgrades_aggregate"),
    ("source binding", 'if snapshot() != report["source"]:', "if False:",
     "test_changes_after_check_block_activation"),
)


def main():
    for name, original, replacement, test in MUTATIONS:
        with tempfile.TemporaryDirectory(
            prefix="readiness-mutation-", dir=os.environ.get("TMPDIR", "/tmp/opencode")
        ) as directory:
            root = Path(directory)
            for relative in ("justfile", "checks/server-baseline.json"):
                target = root / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / relative, target)
            shutil.copytree(ROOT / "scripts/server-readiness", root / "scripts/server-readiness")
            gate = root / "scripts/server-readiness/gate.py"
            source = gate.read_text()
            if source.count(original) != 1:
                raise RuntimeError(f"Mutation target changed: {name}")
            gate.write_text(source.replace(original, replacement))
            result = subprocess.run(
                [sys.executable, str(root / "scripts/server-readiness/gate_test.py"),
                 f"DeploymentTests.{test}"],
                capture_output=True, text=True, timeout=60,
            )
            if result.returncode == 0 or "FAIL" not in result.stderr:
                raise RuntimeError(f"Mutation was not rejected: {name}\n{result.stdout}\n{result.stderr}")
            print(f"Rejected mutation: {name}")


if __name__ == "__main__":
    main()
