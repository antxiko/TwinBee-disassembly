# Hallazgos

Lo que aparecio al desmontar el cartucho. Cada uno lleva la medida de la que
sale, y casi todos estan vigilados por un test de `tests/test_listado.py` para
que no dejen de ser ciertos sin que nadie se entere.

## La tabla de coseno es la de Knightmare, con dos erratas arregladas

Los 65 valores de `0xB950` son 255 × cos(k × 90/64), y son **la misma tabla**
que la que Knightmare (RC-739) tiene en `0x844E`. De los 65 bytes solo se
diferencian **tres**, y esos tres son justo los que Konami arreglo:

| k | Knightmare | Twin Bee | 255·cos(k·90/64) |
|---|---|---|---|
| 46 | 105 | 105 | 109 |
| 56 | 46 | 48 | 50 |
| 58 | 47 | 37 | 37 |
| 64 | 1 | 0 | 0 |

Un cuadrante de coseno **solo puede bajar**. El de Knightmare sube en k=58 -47
donde la anterior vale 43-, que es lo unico que no puede hacer; el de Twin Bee
pone ahi 37, que es lo que toca, y ademas deja cos(90) en cero en vez de uno.

La que sobrevive es la de **k=46**: 105 donde tocaria 109. No rompe la
monotonia, y por eso nadie la vio, y cuatro unidades de menos en un angulo de
64,7 grados no se notan jugando. Twin Bee es RC-740 y Knightmare RC-739: el
arreglo viajo un cartucho adelante.

## El cartucho se defiende: proteccion anticopia

Dos instrucciones del arranque escriben dentro del propio cartucho:

- **0x4028** deja un `pop hl` y un `ret` encima del `djnz` de 0x4195.
  Carga `0xC9E1` en HL y lo suelta de golpe: en memoria esos dos bytes
  son `E1 C9`, que se leen como `pop hl` y `ret`.
- **0x4055** deja un cero en 0x41A1, que no es un dato: es el operando del `jp`
  de 0x41A0. En memoria eso lo convierte en `jp 00000h`, un reinicio en seco.

**Ninguna de las dos hace nada aqui.** El cartucho corre desde ROM, y la ROM no admite
escritura: por eso parecen codigo muerto. No lo son. Un cartucho pirateado es una
copia cargada en **RAM**, y ahi la escritura si cuela y rompe el juego. Que no
haga nada en el original es justo la gracia.

No es una idea suelta de este cartucho: el mismo par —una escritura sobre un
`djnz` y otra sobre el operando de un `jp`— aparece en diez cartuchos de esta
serie, siempre en las mismas dos rutinas del arranque. Las identifico **Manuel
Pazos** en su desensamblado del RC-727, donde las llamo `ReadKeys_AC` y
`VRAM_writeAC`.

## En la ROM solo esta media nave

De cada patron de sprite, el cartucho guarda **la mitad izquierda**: dieciseis
bytes. La derecha la calcula `sube_patrones_de_sprite` (`0x4743`) invirtiendo
cada byte bit a bit. Asi que todo lo que vuela en este juego es simetrico
respecto a su eje vertical - y no es una decision artistica, son 16 bytes
ahorrados por sprite.

El mismo espejo mueve el decorado: `sube_espejado` (`0x4695`) sube el bloque
comprimido con el bit 0 de C puesto, y el filtro del descompresor le da la
vuelta a cada byte al salir.

Comprobado: los 2.048 bytes de la tabla de patrones de sprite salen identicos a
los del emulador en las cinco fases.

## La demostracion es una partida grabada

`arranca_la_demostracion` (`0x5FBF`) monta una partida de verdad -misma RAM,
misma fase, mismo codigo- y le mete el mando por la **misma puerta** por la que
entra el del jugador: `0x600E` salta a `guarda_lo_que_acaba_de_pulsarse` con HL
en `0xE007`, que es donde el lector de mandos deja lo suyo.

Lo que se juega son los **28 valores** de `0x6016`, uno cada 32 cuadros, hasta
el `0xFF` que corta la partida.

Y aqui esta lo que lo hace funcionar: para que la misma tira de pulsaciones de
siempre la misma partida, el azar tiene que ser el mismo. Asi que `0x5FCF` pone
**a cero el registro R** del Z80 antes de empezar. R es el contador de
refresco, y es lo que este cartucho usa de dado en cinco sitios: `0xAF75`,
`0xB2CE`, `0xB757`, `0xBE0C` y `0xBE36`. Sin ese `ld r,a` la demostracion se
descarrilaria sola.

## La VRAM de mesa de trabajo

El descompresor solo sabe escribir en la VRAM: saca los bytes por el puerto
`0x98` y no tiene forma de dejarlos en la RAM. Asi que cuando el juego necesita
una tabla comprimida **en memoria** -los 81 valores que deciden como se dan la
mano las dos naves- la descomprime en `0x3B80`, un hueco de la tabla de
atributos de sprites que nadie usa, y la trae de vuelta a `0xEB00` con LDIRMV
(`0x5E0F`).

## La fase 3 no tiene color propio

`sube_el_color_comun` (`0x9F41`) mira la fase y, si es la tercera, sube el
**mismo** bloque de color que las demas pero con el bit 7 del registro C
puesto. Ese bit enciende la permuta de `0x47B5`, que cambia los nibbles: el 12
pasa a 6, el 6 a 12 y el 5 a 9. La misma hoja de casillas, otra paleta, y un
juego entero de color ahorrado.

## Los sprites se turnan para no desaparecer siempre los mismos

El TMS9918 pinta cuatro sprites por linea y descarta los de indice mas alto,
asi que un juego con muchos enemigos parpadea siempre en los mismos.
`sube_los_sprites` (`0x46CE`) deja los cuatro primeros fijos y sube los
veintiocho restantes en un orden que **rota**: `(0xE00F)` avanza 0x10 en cada
cuadro y da la vuelta al llegar a 0x1E, y dentro del bucle el paso es 0x44. Lo
que se ve no es una desaparicion, es un parpadeo repartido.

## Tres escrituras a la propia ROM

`0x4028`, `0x4055` y `0x40FE` escriben en `0x4195`, `0x41A1` y `0x47F7`, los
tres **dentro del cartucho**: el `ld` sale al bus y se pierde. De tener efecto,
la primera dejaria un `pop hl / ret` donde hay un `djnz`, la segunda un
`jp 0x0000` -o sea un reinicio- y la tercera apagaria la pantalla tocando el
byte de R1 de la tabla de registros.

Las dos primeras estan **iguales** en Knightmare (RC-739) y en The Goonies
(RC-734), en las mismas posiciones relativas. Vienen del armazon, no de este
juego.

## Veintisiete bytes de codigo al que no llega nadie

Cuatro trozos -`0x60CD` (5 bytes), `0xBB18` (5), `0xBB25` (6) y `0xBB38` (11)-
son instrucciones validas y coherentes a las que **ningun salto entra**. En
`0x60CD` se ve bien: el `jr z` de `0x60C9` cae en `0x60D2` y el `jr` de
`0x60CB` en `0x60D6`, o sea justo por debajo y por encima, y lo que queda en
medio hace lo mismo que `0x60DB`, que si se usa. Los otros tres son las
variantes de 0x10 de codigo que si esta vivo.

Comprobado en las dos direcciones: ningun salto cae ahi, y la palabra de esas
direcciones no aparece en ninguna tabla del cartucho.

## La campana da lo que toca por turno, no lo que dice su color

El premio de una campana no sale del color que se ve. Sale de un contador de 32
pasos, `(0xE364)`, que avanza una posicion cada vez que se recoge una y entra
en una tabla de 32 casillas que empieza en `0xEB88`. Esa tabla **no esta en la
ROM**: la escribe a mano `empieza_la_partida` con cinco `ld` y cuatro `rlca`
(`0x5D41`–`0x5D51`), o sea que solo **cinco** de las treinta y dos posiciones
traen premio -1 potencia, 2 doble disparo, 4 el brazo, 8 el arma y 0x10 el
escudo- y las otras veintisiete solo dan puntos.

Leido en el emulador, `0xEB88` tiene
`00 00 00 00 01 00 00 00 02 … 04 … 08`. Exactamente eso.

## Un escenario, noventa y nueve fases

Hay cinco escenarios y noventa y nueve fases. `(0xE07D)` es el numero que se
ve, en BCD, y sube de uno en uno hasta 99; `(0xE076)` es el escenario, y cuando
su nibble bajo llega a seis vuelve a `0x11` -el primero otra vez, con el nibble
alto contando vueltas. Llegar a la fase 99 es la unica manera de terminar Twin
Bee.

Y el escenario en si es un solo mapa de 1.761 filas -73 pantallas- montado con
248 bloques de 32 casillas. Lo que cambia de fase a fase son los dibujos de las
casillas, no el mapa.

## Con dos jugadores, los enemigos tambien se turnan

`elige_a_quien_apuntar` (`0xBA72`) conmuta `(0xE150)` con un `xor 1` en cada
llamada. Un enemigo apunta a la primera nave y el siguiente a la segunda. Con
un solo jugador vivo, todos van a por el.

## La segunda cabecera, y la marca que busca Nemesis

En `0x4010` va la cabecera del *Konami Game Master*, y este cartucho no la lee
nunca. El reparto de los bytes que siguen salio de ejecutar a mano el lector
del propio Game Master, y **cuadra**: el ultimo campo acaba exactamente en
`0x4025`, un byte antes de donde vuelve a haber codigo. Ese cuadre byte a byte
es la prueba de que el reparto es ese y no otro.

Y al final del todo, en `0xBFF7`, esta la marca oculta de Konami:
`ba b7 9a ac 81 91 06 40 aa` - el titulo en katakana, la longitud, el `07 40`
del RC-740 y el `0xAA` que cierra. **Lo descubrio Manuel Pazos**; sin su
trabajo estos serian bytes de relleno.

Y sus seis ultimos bytes son justamente los que Nemesis (RC-742) va buscando
por las ranuras 0, `0x80`, `0x84`, `0x88` y `0x8C`, en su rutina de `0x505A`.
Asi sabe Nemesis que Twin Bee esta enchufado al lado.

## Una fuente que no es un alfabeto

La fuente de `0x49D0` tiene 0 a 9, el simbolo de copyright, un punto, una
admiracion y solo las letras **A B C D E F G H I K L M N O P R S T U V W Y**.
La J, la Q, la X y la Z sencillamente no estan: ningun rotulo de este cartucho
las necesita.
