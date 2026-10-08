# SRAM-aware PDN configuration.
# Keep LibreLane's standard GF180 PDN and connect the SRAM's Metal3
# power pins to the existing macro grid.
source $::env(SCRIPTS_DIR)/openroad/common/pdn_cfg.tcl

add_pdn_connect \
    -grid macro \
    -layers "$::env(PDN_VERTICAL_LAYER) Metal3"
