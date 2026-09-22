# El juego

*Twin Bee* es un matamarcianos vertical que Konami publico para MSX en 1986,
numero de catalogo **RC-740**, en un cartucho de 32 KB. Dos navecillas con
brazos vuelan sobre una isla, disparan a las nubes y recogen las campanas que
caen de ellas.

![La pantalla del titulo](../imagenes/titulo.png)

## Como es una partida

Llevas una nave que se mueve en las cuatro direcciones y dispara hacia arriba.
Dos botones: uno dispara y el otro suelta una bomba al suelo. Pueden jugar dos
a la vez, cada uno con su nave, su marcador y sus vidas.

El numero de fase sube de uno en uno hasta **99**, pero escenarios solo hay
**cinco**: `(0xE076)` dice cual esta puesto, y cuando su nibble bajo llega a
seis vuelve a `0x11` -el primero otra vez, con el nibble alto contando vueltas.
Llegar a la fase 99 es la unica manera de terminar el juego.

![La primera pantalla](../imagenes/pantalla_fase1.png)

## Las campanas

Se dispara a una nube y cae una campana. Mientras cae va cambiando de color, y
el juego te deja mantenerla en el aire a disparos: esa es toda la mecanica. Lo
que da, sin embargo, **no** sale del color que se ve. Sale de un contador de 32
pasos que avanza una posicion cada vez que se recoge una campana, y solo
**cinco** de esas treinta y dos posiciones traen premio:

| posicion | premio |
|---|---|
| 4 | un nivel mas de potencia, hasta siete |
| 8 | el disparo doble |
| 16 | el brazo |
| 20 | el arma, dieciseis usos |
| 32 | el escudo |

Las otras veintisiete solo dan puntos. Y esa tabla ni siquiera esta en la ROM:
la escribe a mano `empieza_la_partida` con cinco `ld` y cuatro `rlca`.

## El brazo

La nave puede estirar un brazo hacia arriba. Quien lo mueve es
`nace_el_disparo_uno` (`0x65F1`): el brazo aparece arriba del todo, espera, y
luego sube tres pixeles por cuadro hasta que se le acaba la cuenta.

## Dos naves que se dan la mano

Esta es la parte que casi ningun juego de dos jugadores de la epoca tenia. Si
las dos naves se acercan lo bastante -`mira_si_se_dan_la_mano` (`0x667C`) mide
la distancia en los dos ejes y pide que las dos quepan en 0x22 pixeles- se
**enganchan**, y a partir de ahi `mueve_las_dos_agarradas` (`0x6326`) las mueve
como si fueran una.

Mientras van juntas, el mando que manda es la suma de los dos, y `0x5EC7` la
deja a cero en cuanto uno de los dos tira para el otro lado: eso es lo que las
separa. Y el dibujo del brazo que las une tampoco esta improvisado: sale de una
tabla de 81 valores, nueve pasos de distancia vertical por nueve de horizontal.

![Los sprites comunes](../imagenes/naves.png)

## El escenario

El escenario es **una sola tira de 1.761 filas** montada con 248 bloques de 32
casillas -una fila entera de pantalla cada uno-, y las cinco fases la recorren
**seguidas**: la fase 1 va de la fila 0 a la 261, donde llega su jefe; la 2
sigue de ahi a la 585; la 3 a la 945; la 4 a la 1272 y la 5 hasta la 1760, el
final de la tira (tabla de `0x6132`). Cuando cae un jefe, `0x613C` sube las
casillas del escenario siguiente sin mover la pantalla. Lo que cambia de fase a
fase son los dibujos; lo que NO se repite es el terreno: cada fase tiene el
suyo.

Y jugando, el registro 7 del VDP vale `0xE0`: el borde y las casillas
transparentes son **negros**, no el azul del titulo. Los mapas de aqui van
pintados asi, que es como se ven.

![La hoja de casillas de la fase 1](../imagenes/casillas_fase1.png)

Avanza una fila cada dieciseis cuadros -`avanza_el_decorado` (`0x6CD1`) es
quien los cuenta- y el mapa esta guardado **de abajo arriba**: la fila de
arriba de la pantalla es el indice mayor, y el contador sube segun avanza la
partida.

## Los enemigos

Catorce huecos de 0x20 bytes desde `0xE160`. El byte 1 de un hueco dice **que
es** ese enemigo: ese numero entra en la tabla de cuarenta punteros de `0xAD60`
y de ahi sale la rutina que lo mueve. Cinco de esos cuarenta hacen doble papel
como disparos del jefe.

![Los enemigos de la fase 1](../imagenes/enemigos_fase1.png)

Con dos jugadores, los enemigos no apuntan a la nave mas cerca ni a la que mas
molesta: van turnandose. `elige_a_quien_apuntar` (`0xBA72`) conmuta
`(0xE150)` con un `xor 1` en cada llamada, asi que un enemigo apunta a la
primera nave y el siguiente a la segunda.

## Los jefes

Uno por fase, en su propio hueco de `0xE320`, con su comportamiento sacado de
la tabla de cinco punteros de `0xADCC`. Un jefe no cabe en un sprite de 16x16,
asi que se dibuja **escribiendo casillas** en el buffer de la pantalla:
`coloca_al_jefe` (`0xBBC9`) coge su guion y pone dos casillas en una fila y dos
en la de abajo.

![El jefe de la fase 1](../imagenes/jefe_fase1.png)

## La demostracion

Deja el cartucho quieto y se juega solo. No es un piloto automatico: es una
**partida grabada**. Veintiocho lecturas de mando, una cada 32 cuadros, metidas
por la misma puerta por la que entra el mando del jugador. Y para que la misma
tira de pulsaciones de siempre la misma partida, el registro R del Z80 -que es
de donde este cartucho saca el azar- se pone a cero antes de empezar.
