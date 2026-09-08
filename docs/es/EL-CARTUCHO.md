# El cartucho

32.768 bytes, mapeados en las **paginas 1 y 2** del MSX, o sea de `0x4000` a
`0xBFFF`. No es un MegaROM: no hay conmutacion de bancos en ninguna parte.

    sha256  02bdce8ceafe6af05a45b61a689e78807551df663afd152090f7cd9cac827dd4

## Dos cabeceras, no una

En `0x4000` va la cabecera normal, `"AB"`, con **INIT en `0x40B1`** y
STATEMENT, DEVICE y TEXT a cero. Esa es la que lee la BIOS.

En `0x4010` va una segunda, `"CD" 07 40`, y este cartucho **no la lee nunca**:
esta puesta para el de al lado. Es la cabecera del *Konami Game Master*, el
cartucho de trucos de la casa, y el reparto de los bytes que siguen no esta
supuesto: sale de ejecutar a mano el lector del propio Game Master. Ese lector
copia 21 bytes desde `0x4012`, saca el numero de catalogo y luego recorre un
byte de **banderas** en `0x4014`: un `rra` por campo, y el bit a **cero**
quiere decir que el campo viene.

Con banderas `0x08` -solo el bit 3 puesto- los campos salen asi, y el ultimo
acaba exactamente en `0x4025`, un byte antes de donde vuelve a haber codigo:

| direccion | campo |
|---|---|
| `0x4015` | `0xE000` y `0x04`: la variable de escena y la escena en la que se aplican los trucos |
| `0x4018` | `0xE076` y `0x05`: la variable de fase y cuantas hay: cinco |
| `0x401B` | `0xE070`: las vidas |
| `0x401D` | `0xE06C`: el record |
| `0x401F` | `0xE068`: la puntuacion |
| `0x4021` | `0xE002`: los bits de modo |
| `0x4023` | `0x4103`: una **rutina de este cartucho**, que el Game Master llama entre ranuras para dejar montada una fase |

El campo que falta -el del bit 3- es el puntero al bloque de datos que el Game
Master sabe guardar y cargar en disco. Twin Bee no declara ninguno.

## La marca oculta

Los nueve ultimos bytes utiles del cartucho, en `0xBFF7`:

    ba b7 9a ac 81 91 06 40 aa

No los lee nadie de aqui dentro. Es la firma que Konami dejaba al final de sus
ROM: el titulo en katakana, el `0x06` de la longitud, el `07 40` del RC-740 y
el `0xAA` que cierra. **Lo descubrio Manuel Pazos**, y sin su trabajo estos
bytes serian relleno.

Y sus **seis ultimos bytes** son justamente los que Nemesis (RC-742) va
buscando por las ranuras 0, `0x80`, `0x84`, `0x88` y `0x8C`: asi sabe Nemesis
si Twin Bee esta enchufado al lado.

## El video

La tabla de registros vive en `0x47F1` y se escribe **del registro 7 al 0**
-`ld c,8` y luego `dec c`-, o sea al reves de como esta guardada:

| registro | valor | que significa |
|---|---|---|
| R0 | `0x02` | SCREEN 2 |
| R1 | `0xE2` | 16 KB, pantalla e interrupcion activas, sprites de 16x16 |
| R2 | `0x0E` | tabla de nombres en `0x3800` |
| R3 | `0x7F` | color en `0x0000`, y el resto es mascara |
| R4 | `0x07` | patrones en `0x2000` |
| R5 | `0x76` | atributos de sprite en `0x3B00` |
| R6 | `0x03` | patrones de sprite en `0x1800` |
| R7 | `0xE4` | tinta 14 sobre fondo 4, el azul del mar |

R3 y R4 son la trampa de SCREEN 2: **no son direcciones**, son una base y una
mascara. Leidos como direcciones ponen las tablas donde no van, las formas
salen bien y los colores a franjas. Aqui caen ademas al reves de lo corriente:
patrones **arriba**, color **abajo**.

## El mapa de memoria

    0x4000 - 0x4025   las dos cabeceras
    0x4025 - 0x4103   el armazon: gancho, despachadores, INIT
    0x4103 - 0x4172   la rutina del Game Master y el reparto de escenas
    0x4182 - 0x4535   las ocho escenas
    0x4535 - 0x4652   la puntuacion, en BCD
    0x4652 - 0x47F9   el descompresor y las rutinas de VRAM
    0x47F9 - 0x48B4   los mandos
    0x48B4 - 0x4D1E   la presentacion y el titulo, con sus guiones
    0x4D1E - 0x518C   el reproductor de sonido
    0x518C - 0x5D20   las partituras
    0x5D20 - 0x6CD1   el juego: naves, disparos, bombas, campanas y nubes
    0x6CD1 - 0x6F8F   el decorado: scroll, guion del mapa y tramos
    0x6F8F - 0x8E8F   los 248 bloques de fila
    0x8E8F - 0x994A   patrones de sprite
    0x994A - 0xA14B   patrones y color del decorado
    0xA14B - 0xAD25   choques y oleadas
    0xAD25 - 0xBFF7   el motor de enemigos, la trigonometria y el jefe
    0xBFF7 - 0xC000   la marca oculta

## La RAM

El juego borra de `0xE000` a `0xF0FF` al arrancar y pone la pila arriba del
todo. Algunas referencias:

    0xE000  la escena, y 0xE001 el paso dentro de ella
    0xE003  el contador de cuadros, que medio cartucho mira
    0xE007  lo que lee el mando, y 0xE009 lo que ACABA de pulsarse
    0xE010  los tres canales de sonido, 0x13 bytes cada uno
    0xE076  la fase, y 0xE07D el numero que se ve, en BCD
    0xE0A0  las dos naves
    0xE100  los disparos
    0xE160  los catorce enemigos, 0x20 bytes cada uno
    0xE320  el jefe
    0xE400  el mapa, descomprimido
    0xEB00  la tabla del abrazo, traida de la VRAM
    0xEC40  el buffer de la pantalla, 768 bytes
    0xEF80  el buffer de sprites, 32 sprites
