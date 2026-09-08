# The code

## Everything hangs off the interrupt

INIT (`0x40B1`) does four things and nothing else: it works out which slot the
cartridge is in and enables page 2, it installs a `jp` to `0x402E` at the
H.KEYI hook, it clears the RAM, and it falls into a `jr $` at `0x40F9`.

From there on **the whole game runs inside the interrupt**. `cada_cuadro`
(`0x402E`) is the top of it: the sound first, then a latch so a frame cannot
enter twice, then the joysticks and the scene.

This is the framework the Konami cartridges of 1986 share: Knightmare (RC-739)
and The Goonies (RC-734) carry the same one, down to two `ld` that write to the
cartridge's own ROM at the same relative offsets and go nowhere.

## The dispatcher of two instructions

    reparte_por_tabla:
        pop hl              ; the return address IS the table
        call palabra_de_tabla
        ex de,hl
        jp (hl)

The table sits **right behind the `call`**, in the code. A `call
reparte_por_tabla` followed by eight words is a switch of eight cases, and the
`ret` of whichever routine it lands on returns to whoever called the caller.
There are four of these in the cartridge, and between them they dispatch the
eight scenes, the forty enemy behaviours, the five bosses and the five boss
shots.

## The scenes, and why the first one is last

`(0xE000)` is the scene and `(0xE001)` the step inside it. The scene dispatch
picks one of eight routines, and inside each one the steps are chained with
`djnz`:

    escena_0_la_presentacion:
        djnz L_4195          ; step 0 and steps 2 up, further down
        ...                  ; step 1

With B at one the first `djnz` does not jump and falls into the first branch;
with two it jumps once; and with **zero** the `djnz` leaves B at 0xFF and jumps
**as well**. So step 0 -the one that sets the screen up- ends up at the *end*
of the chain. That is why in this listing the preparation of each scene reads
last and not first.

## The decompressor

Everything this cartridge puts into VRAM goes through `0x4716`. The format,
read instruction by instruction at `0x471F`:

| byte | meaning |
|---|---|
| `0x00` | end of block |
| `< 0x80` | **run**: the next byte, that many times |
| `0x80` | change destination: the next two bytes are the new VRAM address, and the filter is switched off |
| `> 0x80` | **literals**: the next `n & 0x7F` bytes, as they are |

And every byte that comes out goes through the filter at `0x4786`, which looks
at register C:

- **bit 0**: the byte is flipped bit for bit -the eight `rr l / rla` at
  `0x4793`-. That is the horizontal mirror: half a ship stored, the other half
  computed.
- **bit 7**: **colour permutation** (`0x47B5`), nibble by nibble: 12 becomes 6
  always; and if bit 0 is set too, 10 stays put, 6 becomes 12 and 5 becomes 9.

`sube_espejado` (`0x4695`) enters with C=1 and `sube_tal_cual` (`0x4699`) with
C=0; both repeat the same block **three times**, stepping 0x800 in VRAM, which
are the three banks of SCREEN 2.

## The sprites are half-stored

`sube_patrones_de_sprite` (`0x4743`) reads sixteen bytes -half a sprite- and
writes them followed by **the same sixteen flipped**. A 16x16 sprite pattern is
32 bytes, the first sixteen being the left half; so half stored plus half
computed is a sprite whose right side mirrors its left. That is why every
enemy, every ship and every bell in Twin Bee is symmetric.

## VRAM as a workbench

The decompressor **only knows how to write to VRAM**. So when the game needs a
compressed table **in RAM** -the 81 values that decide how the two ships join
hands- it decompresses it into `0x3B80`, an unused gap in the sprite attribute
table, and brings it back to `0xEB00` with LDIRMV. The video memory doubles as
a workbench.

## The scenery

A row of the screen is a **block of 32 tiles**, and the map is the list of
those blocks:

1. `descomprime_el_mapa` (`0x460C`) walks the script at `0x6D74`. Each byte
   indexes the stretch table at `0x6E01`, and the stretch it picks -a list of
   row codes ending in 0xFF- is copied straight into `0xE400`.
2. `la_fila_numero` (`0x6D62`) turns a row code into an address with five
   `add hl,hl`, that is index times 32, plus `0x6F8F`.
3. `monta_las_veinticuatro_filas` (`0x6D08`) copies twenty-four of them into
   the screen buffer with thirty-two consecutive `ldi` each.

The arithmetic closes by itself: between `0x6F8F` and `0x8E8F` there are
`0x1F00` bytes, exactly 248 rows, and the highest code the stretches use is
0xF7 = 247.

## Sprites take turns

The TMS9918 draws four sprites per line and drops the rest. `sube_los_sprites`
(`0x46CE`) keeps the first four fixed -the ships and their shots- and uploads
the other twenty-eight in an order that **rotates**: `(0xE00F)` advances 0x10 a
frame and wraps at 0x1E, and the step inside the loop is 0x44. No enemy is
skipped two frames running.

## The enemies

Fourteen slots of 0x20 bytes from `0xE160`, always laid out the same way:

    (ix+0)      the drawing
    (ix+1)      the class: the index into the forty-pointer table
    (ix+2,3)    vertical speed, with its fractional part
    (ix+4,5)    horizontal speed
    (ix+6,7)    vertical position
    (ix+8,9)    horizontal position
    (ix+10,11)  sprite pattern and colour
    (ix+14)     the wait between shots
    (ix+16)     the frame counter
    (ix+19)     the heading, on a 256-degree circle

Classes `0xFF` and `0xFE` are reserved -the first switches the slot off, the
second means it is dying- and that is why `0xAD42` and `0xAD51` do two `inc a`
before dispatching.

## The trigonometry

One quadrant of cosine, 65 values at `0xB950`, and out of it come the sine, the
cosine and all four quadrants: `seno_y_coseno` (`0xB921`) indexes it with the
angle and fixes the sign from the quadrant, and gets the sine out of the **same
table** by entering at `0x40 - k`.

The other way round -from a pair of distances to an angle- is
`angulo_hacia_la_nave` (`0xB850`): it divides with eight bits of fraction and
walks the eight tangents at `0xB991` from largest to smallest, eight degrees
per step.

## The sound

Three tone channels plus noise, all driven from the interrupt by
`el_reproductor` (`0x4E48`). A request carries the tune in the low six bits and
the **priority** in the top two: if what is already playing outranks it, the
request is dropped.

Each tune is a script the interpreter at `0x4F06` walks: `0xFE` jumps, `0xFF`
and above end it, a byte whose high nibble is 2 changes the instrument and the
note length, a 1 sets the PSG envelope, and anything else is a **note** -volume
in the high nibble, octave in the low one, with the note code in the byte after
it-. The periods come from twelve semitones at `0x510E`, and the octaves are
made by doubling with `add hl,hl`.
