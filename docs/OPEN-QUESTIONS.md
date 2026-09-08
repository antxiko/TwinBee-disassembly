# Open questions

What is **not** known. Nothing here is disguised as an answer.

## The forty behaviours are named by number, not by what they do

The table at `0xAD60` dispatches forty enemy behaviours, and each one is a
routine of its own. They are all traced, all commented and all reachable - but
they are named `comportamiento_0` to `comportamiento_39`, which is the only
thing that can be stated without playing each of them. Reading the code tells
you *how* one moves; it does not tell you *which* enemy on screen it is. Tying
each number to the thing you see would need a run per behaviour with a
breakpoint on it.

Five of the forty do double duty as the boss's shots, which the table at
`0xAE9E` names again: indices 6, 7, 8, 9 and 10.

## What the tunes are

The 57 tunes at `0x511A` are decoded -the language the interpreter at `0x4F06`
walks is documented- but none of them has been listened to and matched to a
moment of the game. Which is the title tune, which the stage tune and which the
one that plays when a bell is collected is not written down anywhere here.

## The three per-stage tables

`monta_la_fase_para_el_game_master` (`0x4103`) fills four variables out of four
tables: `0x4153`, `0x6132`, `0x61D5` and `0x6210`. The first one is the height
at which the boss appears, and the other three are landmarks the scenery
compares itself against as it scrolls: `prepara_el_marcador` (`0x610E`) fires
the boss when the map reaches `(0xEBB6)`, `mira_si_toca_nube` (`0x619D`) fires
a cloud at `(0xEBB0)` and `mira_si_toca_musica` (`0x61E9`) changes the tune at
`(0xEBB3)`. What is not clear is why the boss table has **four** entries for
five stages, when the other three have five.

## The 0x21 class

`la_tanda_del_final` (`0xBD2B`) forces class `0x21` and sends them out one at a
time, sixteen rounds, and `recarga_la_espera` (`0xAEFC`) gives that same class
a special case: it does not reload its shot timer. It looks like the closing
wave of a stage, but that has not been watched happening.

## Whether anything looks for Twin Bee besides Nemesis

Nemesis (RC-742) hunts for the six bytes of this cartridge's mark through the
slots. Whether Twin Bee looks for anybody in return has been checked and the
answer is **no**: there is no `RDSLT`, no `CALSLT` and no slot walk anywhere in
its code beyond the ENASLT of INIT. Whether any *other* Konami cartridge looks
for Twin Bee is a question for those cartridges, not for this one.

## The 0xF0FF cheat byte

`0x44EC` writes into `0xF0FF` a value taken from the service bits of the second
joystick read, and three places read it back: `0x5D73` gives you power at the
start, `0x5D7A` gives you bells already loaded and `0xA3F7` doubles the weapon
uses. What key combination produces each value has not been worked out - the
byte comes out of `(0xE063)`, the whole row-5 keyboard read, and matching that
to actual keys would need a run with a breakpoint and a hand on the keyboard.
