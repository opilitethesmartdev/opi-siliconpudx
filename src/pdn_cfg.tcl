# SRAM-aware PDN configuration.
# Keep LibreLane's standard GF180 grid, then add the foundry SRAM grid.
source $::env(SCRIPTS_DIR)/openroad/common/pdn_cfg.tcl
source $::env(DESIGN_DIR)/pdn_5v_sram.tcl
