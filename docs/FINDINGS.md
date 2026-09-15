# Findings

What turned up when the cartridge was taken apart. Every one of these carries
the measurement it comes from, and most of them are watched by a test in
`tests/test_listado.py` so they cannot quietly stop being true.

## The cosine table is Knightmare's, with two typos fixed

The 65 values at `0xB950` are 255 × cos(k × 90/64), and they are **the same
table** as the one Knightmare (RC-739) carries at `0x844E`. Out of 65 bytes
only **three** differ - and those three are exactly the ones Konami fixed:

| k | Knightmare | Twin Bee | 255·cos(k·90/64) |
|---|---|---|---|
| 46 | 105 | 105 | 109 |
| 56 | 46 | 48 | 50 |
| 58 | 47 | 37 | 37 |
| 64 | 1 | 0 | 0 |

A cosine quadrant **can only go down**. Knightmare's goes up at k=58 -47 where
the previous entry holds 43-, which is the one thing it cannot do; Twin Bee
holds 37 there, which is right, and it also puts cos(90) at zero instead of
one.

The one that survives is **k=46**: 105 where 109 belongs. It does not break
monotonicity, which is why nobody spotted it, and four units short at 64.7
degrees is not something you can see while playing. Twin Bee is RC-740 and
Knightmare RC-739: the fix travelled forward one cartridge.

## The cartridge defends itself: copy protection

Two instructions in the start-up write inside the cartridge itself:

- **0x4028** puts a `pop hl` and a `ret` over the `djnz` at 0x4195.
  It loads `0xC9E1` into HL and drops it in one go: in memory those two
  bytes are `E1 C9`, which read as `pop hl` and `ret`.
- **0x4055** leaves a zero at 0x41A1, which is not data: it is the operand of
  the `jp` at 0x41A0. In memory that turns it into `jp 00000h`, a dead reset.

**Neither of them does anything here.** The cartridge runs from ROM, and ROM takes no
writes: that is why they look like dead code. They are not. A pirated cartridge is a
copy loaded into **RAM**, and there the write does land and breaks the game.
Doing nothing on the original is exactly the point.

This is no one-off idea in this cartridge: the same pair —a write over a `djnz`
and another over the operand of a `jp`— turns up in ten cartridges of this
series, always in the same two start-up routines. **Manuel Pazos** identified
them in his disassembly of RC-727, where he named them `ReadKeys_AC` and
`VRAM_writeAC`.

## Only half a ship is in the ROM

Of every sprite pattern the cartridge stores **the left half**, sixteen bytes.
The right half is computed by `sube_patrones_de_sprite` (`0x4743`), flipping
each byte bit for bit. So everything that flies in this game is symmetric about
its vertical axis - and it is not an artistic choice, it is 16 bytes saved per
sprite.

The same mirror drives the scenery: `sube_espejado` (`0x4695`) uploads the
compressed block with bit 0 of C set, and the decompressor's filter flips every
byte on its way out.

Checked: all 2,048 bytes of the sprite pattern table come out identical to the
emulator's in all five stages.

## The demo is a recorded game

`arranca_la_demostracion` (`0x5FBF`) sets up a real game -same RAM, same stage,
same code- and feeds the joystick in through the **same door** the player's
input uses: `0x600E` jumps to `guarda_lo_que_acaba_de_pulsarse` with HL at
`0xE007`, which is where the joystick reader leaves its result.

What gets played are the **28 values** at `0x6016`, one every 32 frames, until
the `0xFF` that cuts the game short.

And here is the part that makes it work: for the same string of presses to give
the same game every time, the randomness has to be the same too. So `0x5FCF`
sets the Z80's **R register to zero** before starting. R is the refresh
counter, and it is what this cartridge uses as a dice, in five places:
`0xAF75`, `0xB2CE`, `0xB757`, `0xBE0C` and `0xBE36`. Without that `ld r,a` the
demo would derail on its own.

## VRAM as a workbench

The decompressor only knows how to write to VRAM: it pushes bytes out through
port `0x98` and has no way of leaving them in RAM. So when the game needs a
compressed table **in memory** -the 81 values that decide how the two ships
join hands- it decompresses it at `0x3B80`, an unused gap in the sprite
attribute table, and brings it back to `0xEB00` with LDIRMV (`0x5E0F`).

## Stage 3 has no colour of its own

`sube_el_color_comun` (`0x9F41`) looks at the stage and, if it is the third,
uploads the **same** colour block as the others but with bit 7 of register C
set. That bit turns on the permutation at `0x47B5`, which swaps nibbles: 12
becomes 6, 6 becomes 12, 5 becomes 9. The same tile sheet, another palette, and
a whole colour set saved.

## Sprites take turns so the same ones do not always vanish

The TMS9918 draws four sprites per line and drops the higher-numbered ones, so
a game with many enemies always flickers on the same ones. `sube_los_sprites`
(`0x46CE`) keeps the first four fixed and uploads the remaining twenty-eight in
an order that **rotates**: `(0xE00F)` advances 0x10 every frame and wraps at
0x1E, and inside the loop the step is 0x44. What you see is not a
disappearance, it is a shared-out flicker.

## Three writes to the cartridge's own ROM

`0x4028`, `0x4055` and `0x40FE` write to `0x4195`, `0x41A1` and `0x47F7`, all
three **inside the cartridge**: the `ld` goes out on the bus and is lost. Had
they any effect, the first would leave a `pop hl / ret` where a `djnz` is, the
second a `jp 0x0000` -a reset- and the third would blank the screen by touching
the R1 byte of the register table.

The first two are **identical** in Knightmare (RC-739) and The Goonies
(RC-734), at the same relative offsets. They come from the framework, not from
this game.

## Twenty-seven bytes of code nothing reaches

Four chunks -`0x60CD` (5 bytes), `0xBB18` (5), `0xBB25` (6) and `0xBB38` (11)-
are valid, coherent instructions that **no jump enters**. At `0x60CD` it shows
clearly: the `jr z` at `0x60C9` lands on `0x60D2` and the `jr` at `0x60CB` on
`0x60D6`, that is just below and just above, and what is in between does the
same as `0x60DB`, which is used. The other three are the 0x10 variants of code
that is alive.

Checked in both directions: no jump lands there, and the word of those
addresses appears in no table of the cartridge.

## The bell gives what is next in turn, not what colour it is

A bell's prize does not come from the colour you see. It comes from a 32-step
counter, `(0xE364)`, that advances one place each time a bell is collected and
indexes a 32-slot table at `0xEB88`. That table is **not in the ROM**:
`empieza_la_partida` writes it by hand with five `ld` and four `rlca`
(`0x5D41`–`0x5D51`), so only **five** of the thirty-two slots carry a prize
-1 power, 2 twin shot, 4 the arm, 8 the weapon, 0x10 the shield- and the other
twenty-seven only give points.

Read back in the emulator, `0xEB88` holds
`00 00 00 00 01 00 00 00 02 … 04 … 08`. Exactly that.

## One scenery, ninety-nine stages

There are five sceneries and ninety-nine stages. `(0xE07D)` is the number you
see, in BCD, climbing one at a time to 99; `(0xE076)` is the scenery, and when
its low nibble hits six it goes back to `0x11` -the first one again, with the
high nibble counting laps-. Reaching stage 99 is the only way to finish Twin
Bee.

And the scenery itself is one map of 1,761 rows -73 screens- built out of 248
blocks of 32 tiles. What changes from stage to stage is the tile artwork, not
the map.

## With two players, enemies take turns as well

`elige_a_quien_apuntar` (`0xBA72`) flips `(0xE150)` with an `xor 1` on every
call. One enemy aims at the first ship, the next one at the second. With only
one player alive, they all go for that one.

## The second header, and the mark Nemesis looks for

`0x4010` carries the *Konami Game Master* header, and this cartridge never
reads it. The layout of the bytes that follow was worked out by hand-running
the Game Master's own reader, and it **adds up**: the last field ends exactly
at `0x4025`, one byte before code resumes. That cuadre, byte for byte, is the
proof the layout is this one and not another.

At the very end, `0xBFF7`, sits Konami's hidden mark:
`ba b7 9a ac 81 91 06 40 aa` - the title in katakana, the length, the `07 40`
of RC-740 and the `0xAA` that closes it. **Discovered by Manuel Pazos**;
without his work these would be padding bytes.

And its last six bytes are exactly the ones Nemesis (RC-742) goes hunting for
through slots 0, `0x80`, `0x84`, `0x88` and `0x8C`, in its routine at `0x505A`.
That is how Nemesis knows Twin Bee is plugged in next door.

## A font that is not an alphabet

The font at `0x49D0` has 0 to 9, a copyright sign, a full stop, an exclamation
mark and only the letters **A B C D E F G H I K L M N O P R S T U V W Y**. J,
Q, X and Z are simply not there: no caption in this cartridge needs them.
