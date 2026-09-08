# Empezar

Este repositorio no lleva el cartucho. Lleva lo que hace falta para regenerarlo
todo desde tu copia y comprobar que lo que dice es cierto.

## Lo que necesitas

- **Python 3** para las herramientas.
- **pasmo** para el reensamblado (`make verify`).
- **openMSX** solo si quieres cotejar las imagenes contra la VRAM.
- Tu copia de `twinbee.rom`, en la raiz. Exactamente 32.768 bytes, y

      sha256  02bdce8ceafe6af05a45b61a689e78807551df663afd152090f7cd9cac827dd4

  `make comprueba` te dice si es la misma.

## Los cuatro pasos

    make comprueba     # es tu ROM esta
    make               # listado, reensamblado, comprobaciones y tests
    make imagenes      # dibuja el escenario, los sprites y las pantallas
    make vram          # coteja esas imagenes contra la VRAM de openMSX

`make` es el que importa. Encadena cuatro cosas:

1. **`listado`** traza el flujo desde los puntos de entrada declarados en
   `src/twinbee.entries` y genera `src/twinbee.asm` con los comentarios de
   `src/twinbee.notes`.
2. **`verify`** reensambla ese listado con pasmo y compara el sha256 con el de
   tu ROM. Si no coinciden, el desensamblado no vale nada y para ahi.
3. **`sanity`** comprueba lo que el reensamblado **no** puede cazar: que
   ninguna zona declarada como datos salga como codigo, que ningun punto de
   entrada caiga dentro de un bloque de datos, y que **no quede ni un byte sin
   asignar**.
4. **`test`** pasa las 21 comprobaciones de `tests/`.

## Como esta organizado el listado

El listado se genera, no se edita a mano. Lo que se edita es
`src/twinbee.notes`, y de ahi salen las etiquetas, los comentarios de linea,
las cabeceras de bloque y los limites de cada zona de datos. Cada directiva `D`
declara un rango con su nombre **y con la medida de la que sale**: ningun
limite esta puesto a ojo.

    src/twinbee.entries   los puntos de entrada que el trazado no puede
                          deducir, cada uno con su justificacion: INIT, el
                          gancho de interrupcion, la rutina que llama el Game
                          Master, las cuatro tablas de despacho y la direccion
                          que el codigo apila como retorno
    src/twinbee.nocode    rangos que son datos aunque el trazado los alcance.
                          Vacio aqui: no hizo falta
    src/twinbee.notes     las anotaciones
    src/twinbee.asm       el listado generado, 11.500 lineas

## Que significa cada cifra

`make sanity` imprime el presupuesto: **14.406 bytes de codigo** y **18.362 de
datos**, que suman los 32.768 del cartucho sin sobrar **nada**. `make densidad`
imprime las otras dos: **1.000 bloques con nombre** y un **24,6 %** de las
instrucciones con comentario de linea, **sin una sola rutina por debajo del
10 %**.

Ninguna de esas cifras esta escrita a mano en ningun sitio:
`tests/test_listado.py` las vuelve a calcular sobre el listado y falla si
bajan.

## Cotejar las imagenes

`make imagenes` dibuja el escenario, las hojas de casillas y los sprites desde
los bytes de la ROM, ejecutando en Python el mismo descompresor que corre el
Z80. `make vram` arranca el cartucho en openMSX cinco veces -una por fase-,
vuelca los 16 KB de VRAM en el instante exacto en que acaba de cargar el
decorado y los compara byte a byte con lo que monto Python. Hoy sale a cero.
