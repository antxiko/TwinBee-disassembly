# La música

Todo lo que suena aquí sale de ejecutar el motor de sonido del cartucho (la rutina de 0x4E48, que llama la interrupción cada cuadro, y `pide_un_sonido`, 0x4D29, que le reparte los canales) en un Z80 emulado, cuadro a cuadro y a 60 por segundo, igual que lo llama el juego. Lo que el motor escribe en el PSG pasa a sonido con un AY-3-8910 (`tools/musica.py`). Cada MP3 es la pieza entera hasta donde vuelve a empezar, más 8 segundos de la vuelta apagándose; las que no se repiten acaban donde acaba el motor.

## Cotejado con openMSX

Las escrituras al PSG se han comparado cuadro a cuadro con las de openMSX (C-BIOS MSX1 japonés). En todos los cuadros el PSG queda igual:

- las 33 melodías 0xD6 a 0xF6, cada una pedida a la fuerza en cada petición del juego: en todas hay trozos de entre 218 y 426 cuadros con el estado del PSG igual en cada cuadro, con la RAM del sonido tal como estaba al pedirlas.

El timbre no está cotejado: es el de un AY-3-8910 de manual, no una grabación del emulador. Las sondas están en `tools/omsx_psg.tcl` y `tools/coteja_psg.py`.

## Qué se publica

El número que se pide lleva la melodía en los seis bits bajos y la prioridad en los dos altos; la prioridad cambia a qué canales va y con qué estado empieza, así que cada número es una pieza distinta. Las melodías con prioridad 3 (0xC0 y más) son las de música larga; las de números más bajos son efectos de pocos cuadros y no se publican. Se publican la 0xD6 a la 0xF6, salvo las que no suenan. Las que no pide ninguna rutina con un `ld a` salen de la tabla de partituras (0x5118) y no se han probado una a una en una partida: solo con la petición forzada. Cada pieza se corta a los 45 s.

## Las músicas

**La música de arranque de la fase** (0xD6)

Lo pide `L_5DE5`: apaga a los enemigos y «arranca la de la fase»; se corta a los 45 s (la pieza sigue).

<audio controls preload="none" src="../audio/musica_D6.mp3?v=72b48d6c"></audio>

**La música de la fase** (0xE2)

Lo pide `L_5DE5`, con el número que guarda 0xE05D; dura 7,0 s.

<audio controls preload="none" src="../audio/musica_E2.mp3?v=14f4e718"></audio>

**La melodía del final** (0xD8)

Lo pide `L_618E`, que la deja en 0xE05D; la pide `suena_el_cambio`; dura 21,4 s y vuelve a empezar en el segundo 0,0.

<audio controls preload="none" src="../audio/musica_D8.mp3?v=e51a63ef"></audio>

**El cambio** (0xEE)

Lo pide `suena_el_cambio`; dura 4,8 s.

<audio controls preload="none" src="../audio/musica_EE.mp3?v=063fc5af"></audio>

**La nave nueva** (0xF4)

Lo pide `pon_la_nave_nueva`; dura 5,5 s.

<audio controls preload="none" src="../audio/musica_F4.mp3?v=efc4ac7d"></audio>

**Melodía 0xD7 de la tabla** (0xD7)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; se corta a los 45 s (la pieza sigue).

<audio controls preload="none" src="../audio/musica_D7.mp3?v=f6be1689"></audio>

**Melodía 0xD9 de la tabla** (0xD9)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; se corta a los 45 s (la pieza sigue).

<audio controls preload="none" src="../audio/musica_D9.mp3?v=e1cb6779"></audio>

**Melodía 0xDA de la tabla** (0xDA)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; dura 1,1 s y vuelve a empezar en el segundo 0,2.

<audio controls preload="none" src="../audio/musica_DA.mp3?v=aa268ab0"></audio>

**Melodía 0xDB de la tabla** (0xDB)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; se corta a los 45 s (la pieza sigue).

<audio controls preload="none" src="../audio/musica_DB.mp3?v=b590a57c"></audio>

**Melodía 0xDC de la tabla** (0xDC)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; dura 21,4 s y vuelve a empezar en el segundo 0,0.

<audio controls preload="none" src="../audio/musica_DC.mp3?v=5bbf5d53"></audio>

**Melodía 0xDD de la tabla** (0xDD)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; se corta a los 45 s (la pieza sigue).

<audio controls preload="none" src="../audio/musica_DD.mp3?v=534d4912"></audio>

**Melodía 0xDE de la tabla** (0xDE)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; dura 30,6 s y vuelve a empezar en el segundo 14,4.

<audio controls preload="none" src="../audio/musica_DE.mp3?v=63003a70"></audio>

**Melodía 0xDF de la tabla** (0xDF)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; dura 30,6 s y vuelve a empezar en el segundo 14,4.

<audio controls preload="none" src="../audio/musica_DF.mp3?v=4ea6e4ec"></audio>

**Melodía 0xE0 de la tabla** (0xE0)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; dura 17,9 s y vuelve a empezar en el segundo 1,8.

<audio controls preload="none" src="../audio/musica_E0.mp3?v=490d1429"></audio>

**Melodía 0xE1 de la tabla** (0xE1)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; dura 22,2 s y vuelve a empezar en el segundo 6,0.

<audio controls preload="none" src="../audio/musica_E1.mp3?v=3af34b90"></audio>

**Melodía 0xE3 de la tabla** (0xE3)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; dura 7,0 s.

<audio controls preload="none" src="../audio/musica_E3.mp3?v=4fa8c8c0"></audio>

**Melodía 0xE4 de la tabla** (0xE4)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; dura 6,1 s.

<audio controls preload="none" src="../audio/musica_E4.mp3?v=c4a26736"></audio>

**Melodía 0xE5 de la tabla** (0xE5)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; dura 4,0 s.

<audio controls preload="none" src="../audio/musica_E5.mp3?v=7b557866"></audio>

**Melodía 0xE6 de la tabla** (0xE6)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; dura 4,0 s.

<audio controls preload="none" src="../audio/musica_E6.mp3?v=a96672df"></audio>

**Melodía 0xE7 de la tabla** (0xE7)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; dura 3,2 s.

<audio controls preload="none" src="../audio/musica_E7.mp3?v=91cfd8ba"></audio>

**Melodía 0xE8 de la tabla** (0xE8)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; dura 2,6 s.

<audio controls preload="none" src="../audio/musica_E8.mp3?v=76fec33a"></audio>

**Melodía 0xE9 de la tabla** (0xE9)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; dura 43,5 s.

<audio controls preload="none" src="../audio/musica_E9.mp3?v=d1d9a892"></audio>

**Melodía 0xEA de la tabla** (0xEA)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; se corta a los 45 s (la pieza sigue).

<audio controls preload="none" src="../audio/musica_EA.mp3?v=654da26f"></audio>

**Melodía 0xEB de la tabla** (0xEB)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; se corta a los 45 s (la pieza sigue).

<audio controls preload="none" src="../audio/musica_EB.mp3?v=adfbccab"></audio>

**Melodía 0xEC de la tabla** (0xEC)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; se corta a los 45 s (la pieza sigue).

<audio controls preload="none" src="../audio/musica_EC.mp3?v=70385250"></audio>

**Melodía 0xED de la tabla** (0xED)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; dura 43,1 s.

<audio controls preload="none" src="../audio/musica_ED.mp3?v=9a77b12c"></audio>

**Melodía 0xEF de la tabla** (0xEF)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; dura 4,8 s.

<audio controls preload="none" src="../audio/musica_EF.mp3?v=ed01b077"></audio>

**Melodía 0xF0 de la tabla** (0xF0)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; dura 4,0 s.

<audio controls preload="none" src="../audio/musica_F0.mp3?v=3c723730"></audio>

**Melodía 0xF1 de la tabla** (0xF1)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; se corta a los 45 s (la pieza sigue).

<audio controls preload="none" src="../audio/musica_F1.mp3?v=1a3a4267"></audio>

**Melodía 0xF2 de la tabla** (0xF2)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; se corta a los 45 s (la pieza sigue).

<audio controls preload="none" src="../audio/musica_F2.mp3?v=84df49ee"></audio>

**Melodía 0xF3 de la tabla** (0xF3)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; se corta a los 45 s (la pieza sigue).

<audio controls preload="none" src="../audio/musica_F3.mp3?v=d538ec22"></audio>

**Melodía 0xF5 de la tabla** (0xF5)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; dura 5,5 s.

<audio controls preload="none" src="../audio/musica_F5.mp3?v=5668aae0"></audio>

**Melodía 0xF6 de la tabla** (0xF6)

Lo pide ninguna llamada directa: la pide el juego con un número calculado; dura 5,5 s.

<audio controls preload="none" src="../audio/musica_F6.mp3?v=c94b0e0a"></audio>
