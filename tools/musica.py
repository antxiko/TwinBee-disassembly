#!/usr/bin/env python3
"""La musica del cartucho, ejecutando su motor de sonido (ver motor_musica.py).

Pide el sonido con `pide_un_sonido` (0x4D29, A = numero; `pide_un_sonido_si_se_juega`,
0x4D1E, solo suena con partida y entra por 0x4D2B, el cuerpo comun) y corre
`0x4E48`, que la interrupcion llama cada cuadro. Canales de 19 bytes desde
0xE010; la copia del registro 7 del PSG, en 0xE05C. El numero lleva la
melodia en los seis bits bajos y la prioridad en los dos altos.
Uso:  musica.py registros 0xD6 [cuadros] | mp3 0xD6 f.mp3 | todas docs/audio
      musica.py barrido 0x80 0xFF | emu
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402
from motor_musica import P  # noqa: E402

TABLA = "ninguna llamada directa: la pide el juego con un número calculado"

PIEZAS = [
    P(0xD6, "La música de arranque de la fase", "The stage start tune",
      "`L_5DE5`: apaga a los enemigos y «arranca la de la fase»"),
    P(0xE2, "La música de la fase", "The stage tune",
      "`L_5DE5`, con el número que guarda 0xE05D"),
    P(0xD8, "La melodía del final", "The ending tune",
      "`L_618E`, que la deja en 0xE05D; la pide `suena_el_cambio`"),
    P(0xEE, "El cambio", "The change", "`suena_el_cambio`"),
    P(0xF4, "La nave nueva", "The new ship", "`pon_la_nave_nueva`"),
] + [P(n, "Melodía 0x%02X de la tabla" % n, "Table tune 0x%02X" % n, TABLA)
     for n in range(0xD7, 0xF7) if n not in (0xD8, 0xE2, 0xEE, 0xF4)]

PAGINA = motor_musica.pagina_basica(
    "la rutina de 0x4E48, que llama la interrupción cada cuadro, y "
    "`pide_un_sonido`, 0x4D29, que le reparte los canales",
    "the routine at 0x4E48, which the interrupt calls every frame, and "
    "`pide_un_sonido`, 0x4D29, which hands it the channels",
    "C-BIOS MSX1 japonés",
    [("las 33 melodías 0xD6 a 0xF6, cada una pedida a la fuerza en cada "
      "petición del juego: en todas hay trozos de entre 218 y 426 cuadros "
      "con el estado del PSG igual en cada cuadro, con la RAM del sonido tal "
      "como estaba al pedirlas",
      "the 33 tunes 0xD6 to 0xF6, each forced on every request the game "
      "makes: in all of them there are stretches of 218 to 426 frames with "
      "the PSG state equal in every frame, with the sound RAM as it was "
      "when they were asked for")],
    [("Qué se publica",
      "El número que se pide lleva la melodía en los seis bits bajos y la "
      "prioridad en los dos altos; la prioridad cambia a qué canales va y "
      "con qué estado empieza, así que cada número es una pieza distinta. "
      "Las melodías con prioridad 3 (0xC0 y más) son las de música larga; "
      "las de números más bajos son efectos de pocos cuadros y no se "
      "publican. Se publican la 0xD6 a la 0xF6, salvo las que no suenan. "
      "Las que no pide ninguna rutina con un `ld a` salen de la tabla de "
      "partituras (0x5118) y no se han probado una a una en una partida: "
      "solo con la petición forzada. Cada pieza se corta a los 45 s.",
      "What is published",
      "The number asked for carries the tune in the low six bits and the "
      "priority in the top two; the priority changes which channels it goes "
      "to and what state it starts with, so each number is a different "
      "piece. The priority-3 tunes (0xC0 and up) are the long music; the "
      "lower numbers are effects of a few frames and are not published. "
      "0xD6 to 0xF6 are published, except those that make no sound. Those "
      "no routine asks for with an `ld a` come out of the score table "
      "(0x5118) and have not been tried one by one in a game: only with the "
      "forced request. Each piece is cut at 45 s.")])

CFG = dict(rom="twinbee.rom", org=0x4000, frame=0x4E48, pide=0x4D29,
           bp_pide=0x4D2B, ram=(0xE010, 0xE05D), ram0=[(0xE05C, 0xB8)],
           excluye=[0xE019, 0xE02C, 0xE03F], hz=60, max_s=45,
           psg0={7: 0xB8}, piezas=PIEZAS, pagina=PAGINA, cotejado=[])

if __name__ == "__main__":
    sys.exit(motor_musica.main(CFG, sys.argv[1:]))
