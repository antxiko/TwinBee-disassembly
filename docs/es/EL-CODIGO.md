# El codigo

## Todo cuelga de la interrupcion

INIT (`0x40B1`) hace cuatro cosas y ninguna mas: averigua en que ranura esta el
cartucho y conecta la pagina 2, instala un `jp` a `0x402E` en el gancho H.KEYI,
limpia la RAM y cae en un `jr $` en `0x40F9`.

A partir de ahi **el juego entero corre dentro de la interrupcion**.
`cada_cuadro` (`0x402E`) es la cabecera: el sonido lo primero, luego un cerrojo
para que no entre un cuadro dentro de otro, y luego los mandos y la escena.

Este es el armazon que comparten los cartuchos de Konami de 1986: Knightmare
(RC-739) y The Goonies (RC-734) llevan el mismo, hasta en dos `ld` que escriben
sobre la propia ROM del cartucho en las mismas posiciones relativas y no llegan
a ninguna parte.

## El despachador de dos instrucciones

    reparte_por_tabla:
        pop hl              ; la direccion de retorno ES la tabla
        call palabra_de_tabla
        ex de,hl
        jp (hl)

La tabla va **justo detras del `call`**, dentro del codigo. Un `call
reparte_por_tabla` seguido de ocho palabras es un `switch` de ocho casos, y el
`ret` de la rutina a la que caiga vuelve a quien llamo al que llamo. En el
cartucho hay cuatro, y entre los cuatro reparten las ocho escenas, los cuarenta
comportamientos de enemigo, los cinco jefes y los cinco disparos de jefe.

## Las escenas, y por que la primera esta la ultima

`(0xE000)` es la escena y `(0xE001)` el paso dentro de ella. El reparto elige
una de ocho rutinas, y dentro de cada una los pasos se encadenan con `djnz`:

    escena_0_la_presentacion:
        djnz L_4195          ; paso 0 y paso 2 para abajo, mas adelante
        ...                  ; paso 1

Con B a uno el primer `djnz` no salta y cae en la primera rama; con dos salta
una vez; y con **cero** el `djnz` deja B en 0xFF y salta **tambien**. Asi que
el paso 0 -el que monta la pantalla- acaba en la *ultima* rama de la cadena.
Por eso en este listado la preparacion de cada escena se lee al final y no al
principio.

## El descompresor

Todo lo que este cartucho mete en la VRAM pasa por `0x4716`. El formato, leido
instruccion a instruccion en `0x471F`:

| byte | que significa |
|---|---|
| `0x00` | fin del bloque |
| `< 0x80` | **repeticion**: el byte siguiente, tantas veces |
| `0x80` | cambio de destino: los dos bytes siguientes son la nueva direccion de VRAM, y de paso se apaga el filtro |
| `> 0x80` | **literales**: los `n & 0x7F` bytes siguientes, tal cual |

Y cada byte que sale pasa por el filtro de `0x4786`, que mira el registro C:

- **bit 0**: el byte se invierte bit a bit -los ocho `rr l / rla` de
  `0x4793`-. Es el espejo horizontal: media nave guardada y la otra media
  calculada.
- **bit 7**: **permuta de color** (`0x47B5`), nibble a nibble: el 12 pasa a 6
  siempre; y si ademas esta el bit 0, el 10 se queda, el 6 pasa a 12 y el 5 a 9.

`sube_espejado` (`0x4695`) entra con C=1 y `sube_tal_cual` (`0x4699`) con C=0;
los dos repiten el mismo bloque **tres veces**, subiendo 0x800 en la VRAM, que
son los tres bancos de SCREEN 2.

## Los sprites estan a medias

`sube_patrones_de_sprite` (`0x4743`) lee dieciseis bytes -media pareja- y los
escribe seguidos de **esos mismos dieciseis invertidos**. Un patron de sprite
de 16x16 son 32 bytes, y los dieciseis primeros son la mitad izquierda: media
guardada mas media calculada es un sprite cuyo lado derecho es el espejo del
izquierdo. Por eso todos los enemigos, las naves y las campanas de Twin Bee son
simetricos.

## La VRAM de mesa de trabajo

El descompresor **solo sabe escribir en la VRAM**. Asi que cuando el juego
necesita una tabla comprimida **en la RAM** -los 81 valores que deciden como se
dan la mano las dos naves- la descomprime en `0x3B80`, un hueco de la tabla de
atributos de sprites que nadie usa, y la trae de vuelta a `0xEB00` con LDIRMV.
La memoria de video hace de banco de trabajo.

## El decorado

Una fila de la pantalla es un **bloque de 32 casillas**, y el mapa es la lista
de esos bloques:

1. `descomprime_el_mapa` (`0x460C`) recorre el guion de `0x6D74`. Cada byte
   indexa la tabla de tramos de `0x6E01`, y el tramo que saca -una lista de
   codigos de fila cerrada con 0xFF- se copia tal cual a `0xE400`.
2. `la_fila_numero` (`0x6D62`) convierte un codigo de fila en direccion con
   cinco `add hl,hl`, o sea indice por 32, mas `0x6F8F`.
3. `monta_las_veinticuatro_filas` (`0x6D08`) copia veinticuatro de ellas al
   buffer de la pantalla, con treinta y dos `ldi` seguidos cada una.

La cuenta cierra sola: entre `0x6F8F` y `0x8E8F` hay `0x1F00` bytes, que son
248 filas exactas, y el codigo mas alto que gastan los tramos es 0xF7 = 247.

## Los sprites se turnan

El TMS9918 pinta cuatro sprites por linea y descarta el resto.
`sube_los_sprites` (`0x46CE`) deja los cuatro primeros fijos -las naves y sus
disparos- y sube los otros veintiocho en un orden que **rota**: `(0xE00F)`
avanza 0x10 por cuadro y da la vuelta en 0x1E, y el paso dentro del bucle es
0x44. Ningun enemigo se queda sin pintar dos cuadros seguidos.

## Los enemigos

Catorce huecos de 0x20 bytes desde `0xE160`, siempre con el mismo reparto:

    (ix+0)      el dibujo
    (ix+1)      la clase: el indice en la tabla de cuarenta
    (ix+2,3)    la velocidad vertical, con su fraccion
    (ix+4,5)    la horizontal
    (ix+6,7)    la posicion vertical
    (ix+8,9)    la horizontal
    (ix+10,11)  el patron y el color del sprite
    (ix+14)     la espera entre disparos
    (ix+16)     el contador de cuadros
    (ix+19)     el rumbo, en una circunferencia de 256 grados

Las clases `0xFF` y `0xFE` estan reservadas -la primera apaga el hueco y la
segunda quiere decir que se esta muriendo- y por eso `0xAD42` y `0xAD51` hacen
dos `inc a` antes de repartir.

## La trigonometria

Un cuadrante de coseno, 65 valores en `0xB950`, y de ahi salen el seno, el
coseno y los cuatro cuadrantes: `seno_y_coseno` (`0xB921`) lo indexa con el
angulo y arregla el signo segun el cuadrante, y saca el seno de la **misma
tabla** entrando por `0x40 - k`.

Al reves -de un par de distancias a un angulo- lo hace `angulo_hacia_la_nave`
(`0xB850`): divide con ocho bits de fraccion y recorre las ocho tangentes de
`0xB991` de mayor a menor, ocho grados por paso.

## El sonido

Tres canales de tono mas ruido, todos movidos desde la interrupcion por
`el_reproductor` (`0x4E48`). Una peticion lleva la melodia en los seis bits
bajos y la **prioridad** en los dos altos: si lo que ya suena manda mas, la
peticion se descarta.

Cada melodia es un guion que recorre el interprete de `0x4F06`: `0xFE` salta,
`0xFF` y arriba acaban, un byte de nibble alto 2 cambia el instrumento y la
duracion, uno de nibble alto 1 pone la envolvente del PSG, y cualquier otro es
una **nota** -volumen en el nibble alto, octava en el bajo, con el codigo de
nota en el byte siguiente-. Los periodos salen de doce semitonos en `0x510E`, y
las octavas se hacen doblando con `add hl,hl`.
