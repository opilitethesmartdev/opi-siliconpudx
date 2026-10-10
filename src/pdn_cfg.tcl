# GF180 SRAM-aware PDN configuration.
source $::env(SCRIPTS_DIR)/openroad/common/pdn_cfg.tcl

define_pdn_grid \
    -macro \
    -instances {i_asic_harness.i_toplevel.instb.sram0.sram256x8m8wm1_sram  \
                i_asic_harness.i_toplevel.instb.sram1.sram256x8m8wm1_sram  \
                i_asic_harness.i_toplevel.instb.sram2.sram256x8m8wm1_sram} \
    -name sram_grid \
    -starts_with POWER \
    -grid_over_pg_pins \
    -halo "$::env(PDN_HORIZONTAL_HALO) $::env(PDN_VERTICAL_HALO)"

add_pdn_connect \
    -grid sram_grid \
    -layers "$::env(PDN_VERTICAL_LAYER) Metal3"
