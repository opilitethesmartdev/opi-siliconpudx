# SiliconPUdx

Simple 8-bit microcontroller architecure based on the WDR Paper computer ISA, extended with pointer indirection and MMIO interfaces 
**Author: opilitethesmartdev**

## Features: 
- Simplified ISA: 5 base commands + 6 additions 
  - Base ISA from the Matchstick PC (WDR Computer Club)
  - Extended for actual MCU use
- Pointer indirection:
  - Integrated address resolution interface
  - up to two levels of indirection (pointer to pointer to value)
- 256 internal registers
  - Mirrored SRAM for parallel indirection of both parameters
- up to 512 instructions (to be confirmed) 
- embedded data in instruction storage
- External program loading from host (to be tested)

## To be implemented (post emulation):
- MMIO: Memory-mapped IO
  - Interfacing with free pins (GPIO)
  - Parallel 4-bit duplex protocol
  - Specialized ISA extensions
  - Possibly some cool extension modules (Interrupts, MAC, ReLU)
- External (persistent) storage
- Adjustment to ASIC constraints

## ISA
**Base commands:**
```
inc A, (B) // increase register A by one (by B)
dec A, (B) // decrease register A by one (by B)

isz A, (B) // check if A is equal 0 (equal B)
           // if false: continue
           // if true: skip next instruction

jmp A, A   // jump to instruction A
           // (A is 20-bit, composed from [param0][param1])

stp        // stop program
```
**Implicit:**
```
nop        // no command (throws error when reached)
idl        // do nothing (idle)
```
**Extensions:**
```
wrr A, B   // override register A to value B

ldd A, B   // load embedded data from location A to register B
           // (4 bits from A and 4 bits from A + 1)

iot A, B   // toggle bit(s) B on MMIO register A

izb A, (B) // check if (bit B) of MMIO register A equals 0
           // (same behavior as isz)

mtr A, B   // move MMIO register A to register B
rtm A, B   // move register A to MMIO register B
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
   |       
   |_______________________________ pointer depth of parameter A (2 bit)
```

## Embedded data
The (to be confirmed) instruction storage has the size of 512x32 bits. As such, each instruction leaves 4 bits of data unused. This can be used to have embedded data:
```
0x00 [28-bit instruction][4-bit data]
0x01 [28-bit instruction][4-bit data]
0x02 [28-bit instruction][4-bit data]
0x03 [28-bit instruction][4-bit data]
```
These chunks of 4 bit data can be merged into 8 bit values that can be loaded into registers
using the `ldd` command.

## Pointer indirection
Each instruction has a pointer depth per parameter, currently two bits, which allows for up to 4 levels of indirection:
```
| Depth |           Indirection           |
|-------|---------------------------------|
|   0   | Literal (as is)                 |
|   1   | Register                        |
|   2   | Address of register             |
|   3   | Address of address of register  |
|-------|---------------------------------|
```
This allows up to two levels of conventional pointers, aswell as assigning the value of a register to any command, 
increasing the possibilites of the ISA by a substantial amount. For example:
```
inc 1 6  // Adds 6 to register 1

inc 1 >6 // Adds the value of register 6 to register 1
```
And suddenly, our seemingly arithmetic-less ISA now has register addition and subtraction.

**WARNING:** Note that some commands are inherently treating the parameters as register addresses. For example:
```
wrr 1, 5 // Writes 5 to the register 1
```
In this case, the parameter `1` would inherently be a register (indirection level 1), meaning this parameters can have an extra indirection level:
```
0 : Register (implicit)
1 : Address of register
2 : Address of address of register
3 : Address of address of address of register
```
Which results in *three* levels of conventional pointers, for these specific cases.

## Implicit indirection behavior
As explained above, some commands treat parameters differently, which can cause issues. Therefore, here is
a table of all commands and how they use their parameters:
```
cmd  pr1   pr2
---------------
inc  reg  (lit)
dec  reg  (lit)
isz  reg  (lit)
jmp  lit   ---  // Note: indirection not recommended for values over 256. Only apply indirection for param1
                // (theoretical near-complete indirection is possible, but only 16 bits would be addressable)
stp  ---   ---
nop  ---   ---
idl  ---   ---
wrr  reg   lit
ldd  lit   lit
iot  reg   lit
izb  reg   lit
mtr  reg   reg
rtm  reg   reg
```