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
- 64 internal registers
  - Mirrored SRAM for parallel indirection of both parameters
- up to 512 instructions 
- embedded data in instruction storage
- External program loading from host (to be tested)

## To be implemented (post emulation):
- MMIO: Memory-mapped IO
  - Interfacing with free pins (GPIO)
  - Parallel 4-bit duplex protocol
  - Specialized ISA extensions
  - Boolean & arithmetic operations
  - Possibly some cool extension modules (Interrupts, MAC, ReLU)
- External (persistent) storage
- Adjustment to ASIC constraints

## ISA
**Base commands:**
```
inc A, B   // increase register A by B
dec A, B   // decrease register A by B

isz A, B   // check if A is equal equal B
           // if false: continue
           // if true: skip next instruction

jmp AA     // jump to instruction A
           // (A is 16-bit, composed from [param0][param1])

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

lda A, B   // load embedded data from location [A][B] (16 bit) to accumulator
atr A      // move embedded data from accumulator to register A

iot A, B   // toggle bit(s) B on MMIO register A
iop A, B   // pulse  bit(s) B on MMIO register A

izb A, B   // check if bit B of MMIO register A equals 0
           // (same behavior as isz)

mtr A, B   // move MMIO register A to register B
rtm A, B   // move register A to MMIO register B
```

## Instruction
Instructions are 24-bit long, and split into multiple parts:
```
[23-22][21-20][19-16][15-8][7-0]
   |      |      |      |     |____ parameter B (8 bit)
   |      |      |      |     
   |      |      |      |__________ parameter A (8 bit) 
   |      |      |      
   |      |      |_________________ command (4 bit)
   |      |     
   |      |________________________ pointer depth of parameter B (2 bit)
   |       
   |_______________________________ pointer depth of parameter A (2 bit)
```

## Embedded data
The (to be confirmed) instruction storage has the size of 512x32 bits. As such, each instruction leaves 8 bits of data unused. This can be used to have embedded data:
```
0x00 [8-bit data][24-bit instruction]
0x01 [8-bit data][24-bit instruction]
0x02 [8-bit data][24-bit instruction]
0x03 [8-bit data][24-bit instruction]
```
These chunks of 8 bits can be loaded into an accumulator using the `lda` command, then transferred into a register using the `atr` command.

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
lda  lit   lit
iot  lit   lit
iop  lit   lit
izb  reg   lit
mtr  reg   reg
rtm  reg   reg
```

## Host Serial Interface
A simple serial interface is provided for the host to interface with the internal memories.
The protocol is formatted as following:
```
[42][41][40 - 0]
 |   |      |_______________ Payload 
 |   |
 |   |______________________ Selection bit (0 for register sram, 1 for instruction sram)
 | 
 |__________________________ Operation bit (0 for read, 1 for write)
```
Given the fact that the two target SRAMs are of different layouts, the payload format differs:
```
Inst SRAM: [40 - 32][31 - 0]
               |        |_____________ Payload (32 bit) (ignored when read)
               |
               |______________________ Address (9 bit)

Reg SRAM:  [40][39 - 32][31 - 24][33 - 0]
            |      |        |        |______ Ignored
            |      |        |
            |      |        |_______________ Payload (8 bit) (ignored when read)
            |      |                                      
            |      |________________________ Address (8 bit)
            |                                                        
            |_______________________________ MMIO selection bit (read/write from/to MMIO registers)
```
The response is formatted like this:
```
[42][41][40 - 32][31 - 0]
  |   |     |        |____ Response
  |   |     |
  |   |     |_____________ Mirror of input address
  |   |                    (9 bit when instruction, 8+1 when register)
  |   |
  |   |__________________ Status bit (1 when error)
  |
  |______________________ Mirror of input operation bit
```