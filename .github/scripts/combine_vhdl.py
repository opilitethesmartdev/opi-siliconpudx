from pathlib import Path
import yaml

ROOT = Path(__file__).resolve().parents[2]
INFO = ROOT / "info.yaml"
SRC = ROOT / "src"
GENERATED = SRC / "generated.vhdl"

with INFO.open("r", encoding="utf-8") as f:
    info = yaml.safe_load(f)

sources = info["project"]["source_sources"]

contents = []

for source in sources:
    path = SRC / source

    if not path.is_file():
        raise FileNotFoundError(f"Missing VHDL source: {path}")

    contents.append(
        f"-- BEGIN {source}\n"
        f"{path.read_text(encoding='utf-8')}\n"
        f"-- END {source}\n"
    )

GENERATED.write_text(
    "-- GENERATED FILE -- DO NOT EDIT\n\n"
    + "\n".join(contents),
    encoding="utf-8",
)

print(f"Generated {GENERATED}")