# The music

Everything you hear here comes from running the cartridge's own sound engine (the routine at 0x4E48, which the interrupt calls every frame, and `pide_un_sonido`, 0x4D29, which hands it the channels) on an emulated Z80, frame by frame at 60 per second, just as the game calls it. What the engine writes to the PSG is turned into sound with an AY-3-8910 (`tools/musica.py`). Each MP3 is the whole piece up to where it starts again, plus 8 seconds of the repeat fading out; those that do not repeat end where the engine ends.

## Checked against openMSX

The PSG writes have been compared frame by frame with those of openMSX (C-BIOS MSX1 japonés). In every frame the PSG ends up the same:

- the 33 tunes 0xD6 to 0xF6, each forced on every request the game makes: in all of them there are stretches of 218 to 426 frames with the PSG state equal in every frame, with the sound RAM as it was when they were asked for.

The timbre is not checked: it is a textbook AY-3-8910, not a recording of the emulator. The probes are `tools/omsx_psg.tcl` and `tools/coteja_psg.py`.

## What is published

The number asked for carries the tune in the low six bits and the priority in the top two; the priority changes which channels it goes to and what state it starts with, so each number is a different piece. The priority-3 tunes (0xC0 and up) are the long music; the lower numbers are effects of a few frames and are not published. 0xD6 to 0xF6 are published, except those that make no sound. Those no routine asks for with an `ld a` come out of the score table (0x5118) and have not been tried one by one in a game: only with the forced request. Each piece is cut at 45 s.

## The tunes

**The stage start tune** (0xD6)

Asked for by `L_5DE5`: apaga a los enemigos y «arranca la de la fase»; is cut at 45 s (the piece goes on).

<audio controls preload="none" src="audio/musica_D6.mp3?v=72b48d6c"></audio>

**The stage tune** (0xE2)

Asked for by `L_5DE5`, con el número que guarda 0xE05D; lasts 7.0 s.

<audio controls preload="none" src="audio/musica_E2.mp3?v=14f4e718"></audio>

**The ending tune** (0xD8)

Asked for by `L_618E`, que la deja en 0xE05D; la pide `suena_el_cambio`; lasts 21.4 s and starts again at second 0.0.

<audio controls preload="none" src="audio/musica_D8.mp3?v=e51a63ef"></audio>

**The change** (0xEE)

Asked for by `suena_el_cambio`; lasts 4.8 s.

<audio controls preload="none" src="audio/musica_EE.mp3?v=063fc5af"></audio>

**The new ship** (0xF4)

Asked for by `pon_la_nave_nueva`; lasts 5.5 s.

<audio controls preload="none" src="audio/musica_F4.mp3?v=efc4ac7d"></audio>

**Table tune 0xD7** (0xD7)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; is cut at 45 s (the piece goes on).

<audio controls preload="none" src="audio/musica_D7.mp3?v=f6be1689"></audio>

**Table tune 0xD9** (0xD9)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; is cut at 45 s (the piece goes on).

<audio controls preload="none" src="audio/musica_D9.mp3?v=e1cb6779"></audio>

**Table tune 0xDA** (0xDA)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; lasts 1.1 s and starts again at second 0.2.

<audio controls preload="none" src="audio/musica_DA.mp3?v=aa268ab0"></audio>

**Table tune 0xDB** (0xDB)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; is cut at 45 s (the piece goes on).

<audio controls preload="none" src="audio/musica_DB.mp3?v=b590a57c"></audio>

**Table tune 0xDC** (0xDC)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; lasts 21.4 s and starts again at second 0.0.

<audio controls preload="none" src="audio/musica_DC.mp3?v=5bbf5d53"></audio>

**Table tune 0xDD** (0xDD)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; is cut at 45 s (the piece goes on).

<audio controls preload="none" src="audio/musica_DD.mp3?v=534d4912"></audio>

**Table tune 0xDE** (0xDE)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; lasts 30.6 s and starts again at second 14.4.

<audio controls preload="none" src="audio/musica_DE.mp3?v=63003a70"></audio>

**Table tune 0xDF** (0xDF)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; lasts 30.6 s and starts again at second 14.4.

<audio controls preload="none" src="audio/musica_DF.mp3?v=4ea6e4ec"></audio>

**Table tune 0xE0** (0xE0)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; lasts 17.9 s and starts again at second 1.8.

<audio controls preload="none" src="audio/musica_E0.mp3?v=490d1429"></audio>

**Table tune 0xE1** (0xE1)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; lasts 22.2 s and starts again at second 6.0.

<audio controls preload="none" src="audio/musica_E1.mp3?v=3af34b90"></audio>

**Table tune 0xE3** (0xE3)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; lasts 7.0 s.

<audio controls preload="none" src="audio/musica_E3.mp3?v=4fa8c8c0"></audio>

**Table tune 0xE4** (0xE4)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; lasts 6.1 s.

<audio controls preload="none" src="audio/musica_E4.mp3?v=c4a26736"></audio>

**Table tune 0xE5** (0xE5)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; lasts 4.0 s.

<audio controls preload="none" src="audio/musica_E5.mp3?v=7b557866"></audio>

**Table tune 0xE6** (0xE6)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; lasts 4.0 s.

<audio controls preload="none" src="audio/musica_E6.mp3?v=a96672df"></audio>

**Table tune 0xE7** (0xE7)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; lasts 3.2 s.

<audio controls preload="none" src="audio/musica_E7.mp3?v=91cfd8ba"></audio>

**Table tune 0xE8** (0xE8)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; lasts 2.6 s.

<audio controls preload="none" src="audio/musica_E8.mp3?v=76fec33a"></audio>

**Table tune 0xE9** (0xE9)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; lasts 43.5 s.

<audio controls preload="none" src="audio/musica_E9.mp3?v=d1d9a892"></audio>

**Table tune 0xEA** (0xEA)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; is cut at 45 s (the piece goes on).

<audio controls preload="none" src="audio/musica_EA.mp3?v=654da26f"></audio>

**Table tune 0xEB** (0xEB)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; is cut at 45 s (the piece goes on).

<audio controls preload="none" src="audio/musica_EB.mp3?v=adfbccab"></audio>

**Table tune 0xEC** (0xEC)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; is cut at 45 s (the piece goes on).

<audio controls preload="none" src="audio/musica_EC.mp3?v=70385250"></audio>

**Table tune 0xED** (0xED)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; lasts 43.1 s.

<audio controls preload="none" src="audio/musica_ED.mp3?v=9a77b12c"></audio>

**Table tune 0xEF** (0xEF)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; lasts 4.8 s.

<audio controls preload="none" src="audio/musica_EF.mp3?v=ed01b077"></audio>

**Table tune 0xF0** (0xF0)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; lasts 4.0 s.

<audio controls preload="none" src="audio/musica_F0.mp3?v=3c723730"></audio>

**Table tune 0xF1** (0xF1)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; is cut at 45 s (the piece goes on).

<audio controls preload="none" src="audio/musica_F1.mp3?v=1a3a4267"></audio>

**Table tune 0xF2** (0xF2)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; is cut at 45 s (the piece goes on).

<audio controls preload="none" src="audio/musica_F2.mp3?v=84df49ee"></audio>

**Table tune 0xF3** (0xF3)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; is cut at 45 s (the piece goes on).

<audio controls preload="none" src="audio/musica_F3.mp3?v=d538ec22"></audio>

**Table tune 0xF5** (0xF5)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; lasts 5.5 s.

<audio controls preload="none" src="audio/musica_F5.mp3?v=5668aae0"></audio>

**Table tune 0xF6** (0xF6)

Asked for by ninguna llamada directa: la pide el juego con un número calculado; lasts 5.5 s.

<audio controls preload="none" src="audio/musica_F6.mp3?v=c94b0e0a"></audio>
