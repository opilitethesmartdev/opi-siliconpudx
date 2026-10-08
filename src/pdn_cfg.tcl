# GF180 SRAM-aware PDN configuration.
source $::env(SCRIPTS_DIR)/openroad/common/pdn_cfg.tcl

define_pdn_grid \
    -macro \
    -instances i_asic_harness.i_toplevel.instbank.sram0.sram256x8m8wm1_sram \
    -name sram0_grid \
    -starts_with POWER \
    -halo "$::env(PDN_HORIZONTAL_HALO) $::env(PDN_VERTICAL_HALO)"

add_pdn_connect \
    -grid sram0_grid \
    -layers "$::env(PDN_VERTICAL_LAYER) Metal3"
