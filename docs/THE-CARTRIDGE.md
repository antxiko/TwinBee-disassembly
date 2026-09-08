# The cartridge

32,768 bytes, mapped into **pages 1 and 2** of the MSX, that is `0x4000` to
`0xBFFF`. Not a MegaROM: no bank switching anywhere.

    sha256  02bdce8ceafe6af05a45b61a689e78807551df663afd152090f7cd9cac827dd4

## Two headers, not one

`0x4000` carries the standard `"AB"` header, with **INIT at `0x40B1`** and
STATEMENT, DEVICE and TEXT all zero. That is the one the BIOS reads.

`0x4010` carries a second one, `"CD" 07 40`, and this cartridge **never reads
it**: it is there for the one plugged in next door. It is the header of the
*Konami Game Master*, the house cheat cartridge, and the layout of the bytes
that follow is not guesswork - it comes from hand-running the Game Master's own
reader. That reader copies 21 bytes from `0x4012`, takes the catalogue number
and then walks a **flags byte** at `0x4014`: one `rra` per field, and a bit at
**zero** means the field is present.

With flags `0x08` -only bit 3 set- the fields come out like this, and the last
one ends exactly at `0x4025`, one byte before code resumes:

| offset | field |
|---|---|
| `0x4015` | `0xE000` and `0x04`: the scene variable, and the scene where cheats apply |
| `0x4018` | `0xE076` and `0x05`: the stage variable, and how many stages: five |
| `0x401B` | `0xE070`: the lives |
| `0x401D` | `0xE06C`: the high score |
| `0x401F` | `0xE068`: the score |
| `0x4021` | `0xE002`: the mode bits |
| `0x4023` | `0x4103`: a **routine of this cartridge**, which the Game Master calls across slots to set a stage up |

The field that is missing -bit 3- is the pointer to the block of game data the
Game Master knows how to save to and load from disk. Twin Bee declares none.

## The hidden mark

The last nine useful bytes of the cartridge, at `0xBFF7`:

    ba b7 9a ac 81 91 06 40 aa

Nobody in this cartridge reads them. It is the signature Konami left at the end
of its ROMs: the title in katakana, the `0x06` length, the `07 40` of RC-740
and the `0xAA` that closes it. **This was discovered by Manuel Pazos**, and
without his work these bytes would be padding.

And its **last six bytes** are exactly the ones Nemesis (RC-742) goes hunting
for through slots 0, `0x80`, `0x84`, `0x88` and `0x8C`: that is how Nemesis
knows whether Twin Bee is plugged in next door.

## Video

The register table lives at `0x47F1` and is written **from register 7 down to
0** -`ld c,8`, then `dec c`- so it reads backwards from how it is stored:

| register | value | what it means |
|---|---|---|
| R0 | `0x02` | SCREEN 2 |
| R1 | `0xE2` | 16 KB, screen and interrupt on, 16x16 sprites |
| R2 | `0x0E` | name table at `0x3800` |
| R3 | `0x7F` | colour at `0x0000`, and the rest is a mask |
| R4 | `0x07` | patterns at `0x2000` |
| R5 | `0x76` | sprite attributes at `0x3B00` |
| R6 | `0x03` | sprite patterns at `0x1800` |
| R7 | `0xE4` | ink 14 on background 4, the blue of the sea |

R3 and R4 are the trap of SCREEN 2: they are **not addresses**, they are a base
and a mask. Read as addresses they put the tables in the wrong place, the
shapes come out right and the colours come out in stripes. Here they land the
other way round from the usual: patterns **above**, colour **below**.

## Memory map

    0x4000 - 0x4025   the two headers
    0x4025 - 0x4103   the framework: interrupt hook, dispatchers, INIT
    0x4103 - 0x4172   the routine the Game Master calls, and the scene dispatch
    0x4182 - 0x4535   the eight scenes
    0x4535 - 0x4652   the score, in BCD
    0x4652 - 0x47F9   the decompressor and the VRAM routines
    0x47F9 - 0x48B4   the joysticks
    0x48B4 - 0x4D1E   the intro and the title screen, with their scripts
    0x4D1E - 0x518C   the sound player
    0x518C - 0x5D20   the tunes
    0x5D20 - 0x6CD1   the game: ships, shots, bombs, bells and clouds
    0x6CD1 - 0x6F8F   the scenery: scroll, map script and stretches
    0x6F8F - 0x8E8F   the 248 row blocks
    0x8E8F - 0x994A   sprite patterns
    0x994A - 0xA14B   scenery patterns and colour
    0xA14B - 0xAD25   collisions and waves
    0xAD25 - 0xBFF7   the enemy engine, the trigonometry and the boss
    0xBFF7 - 0xC000   the hidden mark

## The RAM

The game clears `0xE000` to `0xF0FF` on boot and puts the stack at the top of
it. Some landmarks:

    0xE000  the scene, and 0xE001 the step inside it
    0xE003  the frame counter, which half the cartridge looks at
    0xE007  what the joystick reads, and 0xE009 what has just been pressed
    0xE010  the three sound channels, 0x13 bytes each
    0xE076  the stage, and 0xE07D the number you see, in BCD
    0xE0A0  the two ships
    0xE100  the shots
    0xE160  the fourteen enemies, 0x20 bytes each
    0xE320  the boss
    0xE400  the map, decompressed
    0xEB00  the join table, brought back from VRAM
    0xEC40  the screen buffer, 768 bytes
    0xEF80  the sprite buffer, 32 sprites
