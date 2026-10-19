#!/usr/bin/env python3
"""Normalize the community GF180 SRAM GDS for LibreLane/TinyTapeout."""

from pathlib import Path

import gdstk

GDS_PATH = Path(
    "components/sram/macros/256x8_3v3/"
    "gf180mcu_ocd_ip_sram__sram256x8m8wm1.gds"
)
SOURCE_CELL = "gf180mcu_ocd_ip_sram__sram256x8m8wm1"
TARGET_CELL = "gf180mcu_ocd_ip_sram_sram256x8m8wm1"
WIDTH_UM = 301.300
HEIGHT_UM = 224.930
PR_BOUNDARY_LAYER = 0
PR_BOUNDARY_DATATYPE = 0


def is_expected_boundary(polygon: gdstk.Polygon) -> bool:
    if polygon.layer != PR_BOUNDARY_LAYER or polygon.datatype != PR_BOUNDARY_DATATYPE:
        return False
    xs = [float(point[0]) for point in polygon.points]
    ys = [float(point[1]) for point in polygon.points]
    return (
        abs(min(xs)) < 1e-6
        and abs(min(ys)) < 1e-6
        and abs(max(xs) - WIDTH_UM) < 1e-6
        and abs(max(ys) - HEIGHT_UM) < 1e-6
    )


def main() -> None:
    if not GDS_PATH.is_file():
        raise SystemExit(f"SRAM GDS not found: {GDS_PATH}")

    library = gdstk.read_gds(str(GDS_PATH))
    source_cells = [cell for cell in library.cells if cell.name == SOURCE_CELL]
    target_cells = [cell for cell in library.cells if cell.name == TARGET_CELL]

    if len(source_cells) == 1 and not target_cells:
        root = source_cells[0]
        root.name = TARGET_CELL
    elif not source_cells and len(target_cells) == 1:
        # Allow re-running the script against an already-normalized GDS.
        root = target_cells[0]
    else:
        raise SystemExit(
            f"Expected one root named {SOURCE_CELL!r} or {TARGET_CELL!r}; "
            f"found {len(source_cells)} source and {len(target_cells)} target cells"
        )

    # TinyTapeout's GF180 tech definition maps PR_bndry to GDS layer/datatype 0/0.
    if not any(is_expected_boundary(polygon) for polygon in root.polygons):
        root.add(
            gdstk.rectangle(
                (0.0, 0.0),
                (WIDTH_UM, HEIGHT_UM),
                layer=PR_BOUNDARY_LAYER,
                datatype=PR_BOUNDARY_DATATYPE,
            )
        )

    temporary_path = GDS_PATH.with_suffix(".fixed.gds")
    library.write_gds(str(temporary_path))

    # Re-open the output and validate the exact top-cell name and boundary.
    verified = gdstk.read_gds(str(temporary_path))
    verified_roots = [cell for cell in verified.cells if cell.name == TARGET_CELL]
    if len(verified_roots) != 1 or not any(
        is_expected_boundary(polygon) for polygon in verified_roots[0].polygons
    ):
        temporary_path.unlink(missing_ok=True)
        raise SystemExit(
            "Output GDS validation failed: expected renamed top cell and "
            "301.300 x 224.930 um PR boundary on layer/datatype 0/0"
        )

    temporary_path.replace(GDS_PATH)
    print(f"Renamed SRAM GDS top cell to {TARGET_CELL}")
    print(
        f"Added/verified {WIDTH_UM:.3f} x {HEIGHT_UM:.3f} um PR boundary "
        f"on layer/datatype {PR_BOUNDARY_LAYER}/{PR_BOUNDARY_DATATYPE}"
    )


if __name__ == "__main__":
    main()
