# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM ?= icarus
FST ?= -fst # Use more efficient FST format
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../src

ifneq ($(GATES),yes)

# RTL simulation:
SIM_BUILD				= sim_build/rtl
VHDL_SOURCES += $(SRC_DIR)/core.pkg.vhdl
VHDL_SOURCES += $(SRC_DIR)/ff.pkg.vhdl
VHDL_SOURCES += $(SRC_DIR)/instruction.pkg.vhdl
VHDL_SOURCES += $(SRC_DIR)/register.pkg.vhdl
VHDL_SOURCES += $(SRC_DIR)/AddressResolutionIf.vhdl
VHDL_SOURCES += $(SRC_DIR)/clkdiv.vhdl
VHDL_SOURCES += $(SRC_DIR)/ExecutionUnit.vhdl
VHDL_SOURCES += $(SRC_DIR)/InstructionBank.vhdl
VHDL_SOURCES += $(SRC_DIR)/ProcessingElement.vhdl
VHDL_SOURCES += $(SRC_DIR)/ProgramCounterIf.vhdl
VHDL_SOURCES += $(SRC_DIR)/RegisterBank.vhdl
VHDL_SOURCES += $(SRC_DIR)/spislave.vhdl
VHDL_SOURCES += $(SRC_DIR)/toplevel.vhdl
VHDL_SOURCES += $(SRC_DIR)/asic.harness.vhdl
VHDL_SOURCES += $(SRC_DIR)/tt_um_opi_siliconpudx.vhdl

else

# Gate level simulation:
SIM_BUILD				= sim_build/gl
COMPILE_ARGS    += -DGL_TEST
COMPILE_ARGS    += -DFUNCTIONAL
COMPILE_ARGS    += -DUSE_POWER_PINS
COMPILE_ARGS    += -DSIM
COMPILE_ARGS    += -DUNIT_DELAY=\#1
VERILOG_SOURCES += $(PDK_ROOT)/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/verilog/primitives.v
VERILOG_SOURCES += $(PDK_ROOT)/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/verilog/gf180mcu_fd_sc_mcu7t5v0.v

# this gets copied in by the GDS action workflow
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

endif

# Allow sharing configuration between design and testbench via `include`:
COMPILE_ARGS 		+= -I$(SRC_DIR)

# Include the testbench sources:
VERILOG_SOURCES += $(PWD)/tb.v
TOPLEVEL = tb

# List test modules to run, separated by commas and without the .py suffix:
COCOTB_TEST_MODULES = test

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
