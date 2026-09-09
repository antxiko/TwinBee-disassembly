# Getting started

This repository does not carry the cartridge. It carries what you need to
regenerate everything from your own copy and check that what it says is true.

## What you need

- **Python 3** for the tools.
- **pasmo** for the reassembly (`make verify`).
- **openMSX** only if you want to check the pictures against the VRAM.
- Your copy of `twinbee.rom`, in the root. Exactly 32,768 bytes, and

      sha256  02bdce8ceafe6af05a45b61a689e78807551df663afd152090f7cd9cac827dd4

  `make comprueba` tells you whether it is the same one.

## The four steps

    make comprueba     # is your ROM this one
    make               # listing, reassembly, sanity checks and tests
    make imagenes      # draws the scenery, the sprites and the screens
    make vram          # checks those pictures against openMSX's VRAM

`make` is the one that matters. It chains four things:

1. **`listado`** traces the flow from the entry points declared in
   `src/twinbee.entries` and generates `src/twinbee.asm` with the comments
   from `src/twinbee.notes`.
2. **`verify`** reassembles that listing with pasmo and compares the sha256
   with your ROM's. If they differ, the disassembly is worthless and it stops
   there.
3. **`sanity`** checks what the reassembly can**not** catch: that no area
   declared as data comes out as code, that no entry point falls inside a data
   block, and that **not one byte is left unassigned**.
4. **`test`** runs the 21 checks in `tests/`.

## How the listing is organised

The listing is generated; it is not hand-edited. What is edited is
`src/twinbee.notes`, and out of it come the labels, the line comments, the
block headers and the boundaries of every data area. Each `D` directive
declares a range with a name **and with the measurement it comes from**: no
boundary is set by eye.

    src/twinbee.entries   entry points the tracer cannot deduce, each with its
                          reason: INIT, the interrupt hook, the routine the
                          Game Master calls, the four dispatch tables and the
                          address the code pushes as a return address
    src/twinbee.nocode    ranges that are data even though the tracer reaches
                          them. Empty here: it was not needed
    src/twinbee.notes     the annotations
    src/twinbee.asm       the generated listing, 11,500 lines

## What each number means

`make sanity` prints the budget: **14,406 bytes of code** and **18,362 bytes of
data**, which add up to the 32,768 of the cartridge with **zero** left over.
`make densidad` prints the other two: **1,000 named blocks** and **41.4 %** of
the instructions carrying a line comment, with **no routine below 10 %**.

None of those figures is typed in by hand anywhere: `tests/test_listado.py`
recomputes them from the listing and fails if they drop.

## Checking the pictures

`make imagenes` draws the scenery, the tile sheets and the sprites from the
ROM bytes, running in Python the very same decompressor the Z80 runs. `make
vram` boots the cartridge in openMSX five times -one per stage-, dumps the
16 KB of VRAM at the exact instant the scenery finishes loading and compares
it byte for byte against what Python built. Today it comes out at zero.
