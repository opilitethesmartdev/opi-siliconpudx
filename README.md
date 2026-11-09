# SiliconPUdx

Simple 8-bit microcontroller architecure based on the WDR Paper computer ISA, extended with pointer indirection and MMIO interfaces 
**Author: opilitethesmartdev**

## Features: 
- Simplified ISA: 6 base commands + 9 additions 
  - Base ISA from the Matchstick PC (WDR Computer Club)
  - Extended for actual MCU use
- Pointer indirection:
  - Integrated address resolution interface
  - up to two levels of indirection (pointer to pointer to value)
- 256 internal registers
  - Mirrored SRAM for parallel indirection of both parameters
- up to 1024 instructions
- (to be confirmed) embedded data in instruction storage
- External program loading from host (to be tested)

## To be implemented (post emulation):
- MMIO: Memory-mapped IO
  - Interfacing with free pins (GPIO)
  - Parallel 4-bit duplex protocol
  - Specialized ISA extensions
  - Possibly some cool extension modules (Interrupts, MAC)
- External (persistent) storage
- Adjustment to ASIC constraints

## ISA
**Base commands:**
```
inc A, (B) -- increase register A by one (by B)
dec A, (B) -- decrease register A by one (by B)

isz A, (B) -- check if A is equal 0 (equal B)
           -- if false: continue
           -- if true: skip next instruction

jmp A      -- jump to instruction A
stp        -- stop program
```
**Implicit:**
```
nop        -- no command (throws error when reached)
```
**Extensions:**
```
idl        -- do nothing (idle)
wrr A, B   -- override register A to value Bs

ldd A, B   -- load embedded data from location A to register B
wrd A, B   -- write value A to embedded data location B

iot A, B   -- toggle bit B on MMIO register A
iow A, B   -- write value A[7-4] with mask A[3-0] to a MMIO register B half
           -- if A[9] = 0: write to register [7-4]
           -- if A[9] = 1: write to register [3-0]

izb A, (B) -- check if (bit B) of MMIO register A equals 0
           -- (same behavior as isz)

izv A, B   -- check if MMIO register A half equals B[7-4] with mask B[3-0]
           -- if B[9] = 0: check register [7-4]
           -- if B[9] = 1: check register [3-0]
           -- (same behavior as isz)

pke A, (B) -- send a pulse to MMIO register A (with message B)
```

## Instruction
Instructions are 28-bit long, and split into multiple parts:
```
[27-26][25-24][23-20][19-10][9-0]
   |      |      |      |     |____ parameter B (10 bit)
   |      |      |      |           (usable as [2][8] metadata;value depending on command)
   |      |      |      |     
   |      |      |      |__________ parameter A (10 bit) 
   |      |      |                  (usable as [2][8] metadata;value depending on command)
   |      |      |      
   |      |      |_________________ command (4 bit)
   |      |     
   |      |________________________ pointer depth of parameter B (2 bit)
   |      |
   |_______________________________ pointer depth of parameter A (2 bit)
```

## Embedded data
The (to be confirmed) instruction storage has the size of 1024x32 bits. As such, each instruction leaves 4 bits of data unused. This can be used to have embedded data:
```
0x00 [28-bit instruction][4-bit data]
0x01 [28-bit instruction][4-bit data]
0x02 [28-bit instruction][4-bit data]
0x03 [28-bit instruction][4-bit data]
```
These chunks of 4 bit data can be merged into 8 bit values that can be loaded into registers
using the `ldd` command. These can be edited using the `wrd` command