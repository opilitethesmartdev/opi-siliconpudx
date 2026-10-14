# OPI-SiliconPUdx

> **8-bit Microcontroller architecture based on the simple WDR matchstick PC, expanded with pointer indirection**

**Author:** [@opilitethesmartdev](https://github.com/opilitethesmartdev)

---

## Features

- **Simplified ISA:** `5 commands only`
  - Commands: `isz`, `inc`, `dec`, `jmp`, `stp`
  - *(Future expansion possible for up to 16 commands)*
  - **Original ISA** from the Matchstick PC (WDR Computer Club)
  - Expanded to support **2 parameters**
- **Pointer indirection:**
  - **Integrated** address resolution interface
  - Up to three levels of indirection (`pointer` → `pointer` → `pointer` → `value`)
- **256-word instruction storage:**
  - 24-bit width
  - Achieved with three SRAM Macros
- **32 8-bit asynchronous registers**
- **Current area consumption:** **4x2** TinyTapeout tiles, about **320x1360 µm**

---

## To Be Implemented

- [ ] **Memory Mapped IO**
  - **Async** registers that link directly to peripheral hardware
  - **GPIOs, Serial interfaces**, practically **anything**
- [ ] **Serial**
  - Simple parallel – serial converter, for general use
- [ ] **Instruction memory offloading**
  - Finding a way to **reduce the need of onboard SRAM**
  - **Options:**
    - Another serial interface
    - Using the analog pins as a **hardware interface**
    - ~~(Reducing bit width)~~ *(would be sad)*

> [!NOTE]
> This architecture is designed for TinyTapeout deployment.