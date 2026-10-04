# SiliconPUdx

Simple 8-bit microcontroller architecure based on the WDR Paper computer ISA, extended with pointer indirection and MMIO interfaces 
**Author: opilitethesmartdev**

## Features: 
- Simplified ISA: 5 commands only : isz inc dec jmp stp 
  - Original ISA from the Matchstick PC (WDR Computer Club)
  - (future expansion possible for up to 63 commands)
- Pointer indirection:
  - Integrated address resolution interface
  - up to two levels of indirection (pointer to pointer to value)
  - (indirection expandable at price of less commands)
- 256-word instruction storage and 32 registers
- External program loading from host (to be tested)

## To be implemented (post emulation):
- MMIO: Memory-mapped IO
  - Interfacing with free pins (GPIO)
  - Parallel 4-bit duplex protocol
  - Specialized ISA extensions
- External (persistent) storage
- Adjustment to ASIC constraints
