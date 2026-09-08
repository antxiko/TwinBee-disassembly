# In the emulator

Static analysis only takes you so far. Three of the things on the findings page
were settled by booting the cartridge in openMSX and looking.

## Checking the pictures against the VRAM

    make vram

This boots the cartridge five times -one per stage-, dumps the 16 KB of VRAM at
the exact instant the scenery finishes loading, and compares it **byte for
byte** against what `tools/pantallas.py`, `tools/mapas.py` and
`tools/sprites.py` build in Python from the ROM.

The instant matters. The dump is taken at `0x5FEC`, the instruction right after
`call 0x9177`:

- half a second later would not do: the water and the highlights animate
  themselves, and the first attempt came out with four "differences" that were
  nothing but that;
- one `call` earlier, at `0x5FE9`, the stage's enemy sprites are not up yet,
  and 202 bytes come out different for that reason alone.

The stage is imposed with a breakpoint at `0x994A`, just before that routine
reads `(0xE076)`. Nothing is faked: one byte of the starting state is changed,
which is what a player reaching that stage would do.

Today it comes out at:

    titulo: 0 bytes distintos de 16384
    fase 1: 0 casillas distintas de 900, y 0 bytes de sprite distintos de 2048
    ... (the same for the other four)

## Where the load chain came from

    make cargas

The scenery tiles of stages 2, 3 and 4 do not fill the whole sheet: the top
tiles are **not loaded by the stage** and what shows there is whatever the
title screen left behind. Guessing that costs an afternoon of looking for a
load that does not exist.

`tools/omsx_cargas.tcl` settles it by putting a breakpoint on every door of the
decompressor -`0x4695`, `0x4699`, `0x469B`, `0x4711`, `0x4716`, `0x4743` and
`0x46AD`- and writing down, in order, what registers it enters with. Out comes
the whole chain: intro → title → stage, with every block, its destination and
its filter. `tools/pantallas.py` reproduces that chain, which is why the check
closes at zero.

That same log is what showed that the FILVRM at `0x4BEC` fills **one** bank and
not three - and that difference is exactly what made stage 4's colour come out
wrong.

## Reading a table the ROM does not carry

The prize table at `0xEB88` is written into RAM by hand, so there is nothing to
read in the cartridge. A breakpoint at `0xA214` and a dump of those 32 bytes
gives it:

    00 00 00 00 01 00 00 00 02 00 00 00 00 00 00 00
    04 00 00 00 08 00 00 00 00 00 00 00 00 00 00 00

Five prizes in thirty-two slots. And a write watchpoint over that range gives
who puts them there: `0x5D41`, `0x5D45`, `0x5D49` and `0x5D4D`, inside
`empieza_la_partida`.

## The traps of Tcl, already paid for

The scripts here respect three things this series learned the hard way: no
brackets inside a `format`, binary files opened with `-translation binary`, and
`debug read_block` instead of `debug save_to_file`, which does not exist.
