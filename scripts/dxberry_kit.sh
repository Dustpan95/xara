#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

target=aarch64-unknown-linux-gnu
cargo build --locked --release --target "$target" --bin xara --features varac-17

python3 - "$target" <<'PY'
import json
from pathlib import Path
import subprocess
import sys
from zipfile import ZipFile, ZIP_DEFLATED

metadata = json.loads(subprocess.check_output(
    ["cargo", "metadata", "--locked", "--no-deps", "--format-version", "1"]
))
manifest = Path("crates/xara/Cargo.toml").resolve()
version = next(pkg["version"] for pkg in metadata["packages"]
               if Path(pkg["manifest_path"]) == manifest)
target_dir = Path(metadata["target_directory"])
binary = target_dir / sys.argv[1] / "release" / "xara"
with binary.open("rb") as executable:
    header = executable.read(20)
if header[:6] != b"\x7fELF\x02\x01" or header[18:20] != b"\xb7\x00":
    sys.exit("DXBerry-Pi requires an ARM64 Linux executable")
archive = target_dir / "dxberry" / "xara.zip"
archive.parent.mkdir(parents=True, exist_ok=True)
with ZipFile(archive, "w", ZIP_DEFLATED) as kit:
    kit.write(binary, "xara")
    kit.write("LICENSE")
    kit.writestr("VERSION", version + "\n")
print(archive)
PY
