#!/usr/bin/env python3
"""Package the Blender extension without adding generated archives to Git."""

from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools" / "blender_pyrbuilding"
DESTINATION = ROOT / "dist" / "pyramida_building_tools-0.1.0.zip"
FILES = ("__init__.py", "pyrbuilding_codec.py", "blender_manifest.toml")


def main() -> None:
    DESTINATION.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(DESTINATION, "w", ZIP_DEFLATED) as extension_zip:
        for filename in FILES:
            extension_zip.write(SOURCE / filename, filename)
    print(DESTINATION)


if __name__ == "__main__":
    main()
