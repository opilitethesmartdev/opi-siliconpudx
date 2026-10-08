# GF180MCU 5V SRAM PDN.
#
# This is based on the proven GF180 256x8/512x8 SRAM integration recipe used
# by TinyTapeout/OpenLane designs. The SRAM power pins are on Metal3, while
# the TinyTapeout top-level PDN uses Metal4 as its highest routing layer.

set sram_macros_NS [list \
    i_asic_harness.i_toplevel.instbank.sram0.sram256x8m8wm1_sram \
    i_asic_harness.i_toplevel.instbank.sram1.sram256x8m8wm1_sram \
]

define_pdn_grid \
    -macro \
    -instances $sram_macros_NS \
    -name sram_macros_NS \
    -starts_with POWER \
    -halo "$::env(PDN_HORIZONTAL_HALO) $::env(PDN_VERTICAL_HALO)"

# Connect the SRAM-local M4 grid to the normal top-level PDN stack and to the
# SRAM's actual Metal3 supply shapes.
add_pdn_connect \
    -grid sram_macros_NS \
    -layers "$::env(PDN_VERTICAL_LAYER) $::env(PDN_HORIZONTAL_LAYER)"

add_pdn_connect \
    -grid sram_macros_NS \
    -layers "$::env(PDN_VERTICAL_LAYER) Metal3"

# W/E-edge straps: these are part of the proven GF180 5V SRAM recipe and reach
# the SRAM's Metal3 power ring through the M4/M3 connection above.
add_pdn_stripe \
    -grid sram_macros_NS \
    -layer Metal4 \
    -width 2.36 \
    -offset 1.18 \
    -spacing 0.28 \
    -pitch 426.86 \
    -starts_with GROUND \
    -number_of_straps 2

# Additional M4 straps across the macro improve access to the SRAM power ring.
add_pdn_stripe \
    -grid sram_macros_NS \
    -layer Metal4 \
    -width 4.00 \
    -offset 65.93 \
    -spacing 0.28 \
    -pitch 50 \
    -starts_with GROUND \
    -number_of_straps 9
