# Twin Bee (Konami, MSX1) — a commented disassembly

*(También [en castellano](README.es.md).)* ·
**[Read it on the web](https://antxiko.github.io/TwinBee-disassembly/)**

A complete, commented disassembly of Konami's **Twin Bee** for the MSX
(RC-740, 32 KB, 1986). Every one of the 32,768 bytes is accounted for, and the
listing reassembles into the ROM **byte for byte**.

    explained          32,768 of 32,768   100 %
    comment density    1,820 of 7,405     24.6 %
    blocks below 10 %        0 of 1,000
    call targets unnamed     0
    tests                   21, green
    reassembly         same sha256 as the cartridge
    VRAM check         0 differences over the title screen's 16,384 bytes,
                       and 0 over the scenery tiles and sprite patterns of
                       all five stages

## What is here

    src/twinbee.asm       the commented listing, generated
    src/twinbee.notes     the comments and the data blocks, with their measure
    src/twinbee.entries   the entry points the tracer cannot deduce
    tools/                the disassembler, the drawing tools and the openMSX probes
    tests/                21 checks over the listing and over what it claims
    docs/                 the website, in English and Spanish

The cartridge is **not** distributed. Put your copy in the root as
`twinbee.rom` — 32,768 bytes, sha256
`02bdce8ceafe6af05a45b61a689e78807551df663afd152090f7cd9cac827dd4` — and
`make comprueba` will tell you whether it is the same one.

## Reproducing it

    make comprueba     # is your ROM this one
    make               # listing, reassembly, sanity checks and tests
    make imagenes      # draws the scenery, the sprites and the screens
    make vram          # checks those pictures against openMSX's VRAM

## Not one capture

Every picture in `docs/` is **drawn from the ROM bytes**, by running in Python
the same decompressor, the same mirror and the same row builder the Z80 runs.
They are then checked byte for byte against the VRAM openMSX really has.

## Some of what turned up

- **Only half a ship is in the ROM.** Each sprite pattern stores its left half;
  the right half is computed by flipping every byte bit for bit. That is why
  everything that flies in this game is symmetric.
- **The demo is a recorded game**, and the Z80's R register — which is where
  this cartridge gets its randomness — is set to zero so it always plays out
  the same.
- **The cosine table is Knightmare's**, with two of its three typos fixed and
  one still there.
- **VRAM doubles as a workbench**: the decompressor can only write to video
  memory, so a table that has to end up in RAM is decompressed into an unused
  gap of the sprite attribute table and read back with LDIRMV.

The rest is on [the findings page](https://antxiko.github.io/TwinBee-disassembly/FINDINGS.html).

## Credits

The hidden Konami mark at the end of the ROM was **discovered by Manuel
Pazos**; without his work those nine bytes would be padding.

## Legal

See [LEGAL-NOTICE.md](LEGAL-NOTICE.md). This is preservation and documentation
work; the game is Konami's and the cartridge image is not distributed.
