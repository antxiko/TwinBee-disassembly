# En el emulador

El analisis estatico llega hasta donde llega. Tres de las cosas de la pagina de
hallazgos se cerraron arrancando el cartucho en openMSX y mirando.

## Cotejar las imagenes contra la VRAM

    make vram

Arranca el cartucho cinco veces -una por fase-, vuelca los 16 KB de VRAM en el
instante exacto en que acaba de cargar el decorado, y los compara **byte a
byte** con lo que montan en Python `tools/pantallas.py`, `tools/mapas.py` y
`tools/sprites.py` desde la ROM.

El instante importa. El volcado se toma en `0x5FEC`, la instruccion de despues
del `call 0x9177`:

- medio segundo mas tarde no vale: el agua y los brillos se animan solos, y la
  primera medida salio con cuatro "diferencias" que no eran mas que eso;
- un `call` antes, en `0x5FE9`, los sprites de los enemigos de la fase todavia
  no estan, y salen 202 bytes distintos solo por eso.

La fase se impone con un punto de interrupcion en `0x994A`, justo antes de que
esa rutina lea `(0xE076)`. No se falsea nada: se cambia un byte del estado de
partida, que es lo que haria un jugador llegando a esa fase.

Hoy sale asi:

    titulo: 0 bytes distintos de 16384
    fase 1: 0 casillas distintas de 900, y 0 bytes de sprite distintos de 2048
    ... (lo mismo en las otras cuatro)

## De donde salio la cadena de cargas

    make cargas

Las casillas del decorado de las fases 2, 3 y 4 no llenan la hoja entera: las
casillas altas **no las carga la fase**, y lo que se ve ahi es lo que dejo la
pantalla del titulo. Adivinar eso cuesta una tarde buscando una carga que no
existe.

`tools/omsx_cargas.tcl` lo zanja poniendo un punto de interrupcion en cada
puerta del descompresor -`0x4695`, `0x4699`, `0x469B`, `0x4711`, `0x4716`,
`0x4743` y `0x46AD`- y apuntando, en orden, con que registros entra. Sale la
cadena entera: presentacion, titulo y fase, con cada bloque, su destino y su
filtro. `tools/pantallas.py` reproduce esa cadena, y por eso el cotejo cierra a
cero.

Ese mismo registro es el que enseno que el FILVRM de `0x4BEC` rellena **un**
banco y no tres, y esa diferencia es justamente la que hacia salir mal el color
de la fase 4.

## Leer una tabla que la ROM no lleva

La tabla de premios de `0xEB88` la escribe a mano el propio juego, asi que en
el cartucho no hay nada que leer. Un punto de interrupcion en `0xA214` y un
volcado de esos 32 bytes la da:

    00 00 00 00 01 00 00 00 02 00 00 00 00 00 00 00
    04 00 00 00 08 00 00 00 00 00 00 00 00 00 00 00

Cinco premios en treinta y dos posiciones. Y un watchpoint de escritura sobre
ese rango da quien los pone: `0x5D41`, `0x5D45`, `0x5D49` y `0x5D4D`, dentro de
`empieza_la_partida`.

## Las trampas de Tcl, ya pagadas

Los guiones de aqui respetan tres cosas que esta serie aprendio a base de
golpes: nada de corchetes dentro de un `format`, los binarios con
`-translation binary`, y `debug read_block` en vez de `debug save_to_file`, que
no existe.
