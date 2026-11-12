import json
import os
from pathlib import Path
import subprocess
import sys


formatters = json.loads(Path(sys.argv[1]).read_text())["formatter"]
assert set(formatters) == {"nixfmt", "oxfmt"}
fixtures = {
    "nixfmt": (".nix", "{foo=1;bar=[1 2];}\n"),
    "oxfmt": (".ts", "const value={foo:1,bar:[1,2]};\n"),
}
assert formatters["nixfmt"]["extensions"] == [".nix"]
assert formatters["oxfmt"]["extensions"] == [
    ".js", ".jsx", ".mjs", ".cjs", ".ts", ".tsx", ".mts", ".cts"
]
directory = Path.cwd() / "formatter fixtures"
directory.mkdir()
assert not (directory / "package.json").exists()
for name, (extension, original) in fixtures.items():
    formatter = formatters[name]
    assert not formatter.get("disabled", False)
    command = formatter["command"]
    assert Path(command[0]).is_absolute() and os.access(command[0], os.X_OK)
    assert Path(command[0]).name == name
    assert command.count("$FILE") == 1
    file = directory / f"unformatted example{extension}"
    file.write_text(original)
    argv = [str(file) if arg == "$FILE" else arg for arg in command]
    subprocess.run(argv, cwd=directory, check=True)
    formatted = file.read_text()
    assert formatted != original, name
    subprocess.run(argv, cwd=directory, check=True)
    assert file.read_text() == formatted, name
    subprocess.run([command[0], "--check", str(file)], cwd=directory, check=True)
