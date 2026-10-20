#!/usr/bin/env python3
"""Normalize the community GF180 SRAM GDS files for LibreLane/TinyTapeout."""

from pathlib import Path

import gdstk

MACROS = (
    {
        "path": Path("components/sram/macros/256x8_3v3/gf180mcu_ocd_ip_sram__sram256x8m8wm1.gds"),
        "source": "gf180mcu_ocd_ip_sram__sram256x8m8wm1",
        "target": "gf180mcu_ocd_ip_sram_sram256x8m8wm1",
        "width": 301.300,
        "height": 224.930,
    },
    {
        "path": Path("components/sram/macros/64x8_3v3/gf180mcu_ocd_ip_sram__sram64x8m8wm1.gds"),
        "source": "gf180mcu_ocd_ip_sram__sram64x8m8wm1",
        "target": "gf180mcu_ocd_ip_sram_sram64x8m8wm1",
        "width": 301.300,
        "height": 152.210,
    },
)
PR_BOUNDARY_LAYER = 0
PR_BOUNDARY_DATATYPE = 0


def is_expected_boundary(polygon: gdstk.Polygon, width: float, height: float) -> bool:
    if polygon.layer != PR_BOUNDARY_LAYER or polygon.datatype != PR_BOUNDARY_DATATYPE:
        return False
    xs = [float(point[0]) for point in polygon.points]
    ys = [float(point[1]) for point in polygon.points]
    return (
        abs(min(xs)) < 1e-6
        and abs(min(ys)) < 1e-6
        and abs(max(xs) - width) < 1e-6
        and abs(max(ys) - height) < 1e-6
    )


def normalize_macro(config: dict[str, str | float | Path]) -> None:
    path = config["path"]
    assert isinstance(path, Path)
    source = str(config["source"])
    target = str(config["target"])
    width = float(config["width"])
    height = float(config["height"])

    if not path.is_file():
        raise SystemExit(f"SRAM GDS not found: {path}")

    library = gdstk.read_gds(str(path))
    source_cells = [cell for cell in library.cells if cell.name == source]
    target_cells = [cell for cell in library.cells if cell.name == target]

    if len(source_cells) == 1 and not target_cells:
        root = source_cells[0]
        root.name = target
    elif not source_cells and len(target_cells) == 1:
        root = target_cells[0]
    else:
        raise SystemExit(
            f"{path}: expected one root named {source!r} or {target!r}; "
            f"found {len(source_cells)} source and {len(target_cells)} target cells"
        )

    if not any(is_expected_boundary(polygon, width, height) for polygon in root.polygons):
        root.add(
            gdstk.rectangle(
                (0.0, 0.0),
                (width, height),
                layer=PR_BOUNDARY_LAYER,
                datatype=PR_BOUNDARY_DATATYPE,
            )
        )

    temporary_path = path.with_suffix(".fixed.gds")
    library.write_gds(str(temporary_path))
    verified = gdstk.read_gds(str(temporary_path))
    verified_roots = [cell for cell in verified.cells if cell.name == target]
    if len(verified_roots) != 1 or not any(
        is_expected_boundary(polygon, width, height) for polygon in verified_roots[0].polygons
    ):
        temporary_path.unlink(missing_ok=True)
        raise SystemExit(f"{path}: output GDS validation failed for {target}")

    temporary_path.replace(path)
    print(f"{path}: normalized top cell to {target}; verified {width:.3f} x {height:.3f} um PR boundary")


def main() -> None:
    for macro in MACROS:
        normalize_macro(macro)


if __name__ == "__main__":
    main()
