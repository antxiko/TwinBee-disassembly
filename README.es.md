# Twin Bee (Konami, MSX1) — desensamblado comentado

*(Also [in English](README.md).)* ·
**[Leerlo en la web](https://antxiko.github.io/TwinBee-disassembly/es/)**

Desensamblado completo y comentado del **Twin Bee** de Konami para MSX
(RC-740, 32 KB, 1986). Los 32.768 bytes estan explicados uno a uno, y el
listado reensambla a la ROM **byte a byte**.

    explicado             32.768 de 32.768   100 %
    densidad de comentario 1.820 de 7.405    24,6 %
    bloques por debajo del 10 %   0 de 1.000
    destinos de call sin nombre   0
    tests                        21, en verde
    reensamblado          mismo sha256 que el cartucho
    cotejo de VRAM        0 diferencias en los 16.384 bytes de la pantalla
                          del titulo, y 0 en las casillas del decorado y los
                          patrones de sprite de las cinco fases

## Que hay aqui

    src/twinbee.asm       el listado comentado, generado
    src/twinbee.notes     los comentarios y los bloques de datos, con su medida
    src/twinbee.entries   los puntos de entrada que el trazado no puede deducir
    tools/                el desensamblador, los dibujantes y las sondas de openMSX
    tests/                21 comprobaciones sobre el listado y sobre lo que afirma
    docs/                 la web, en castellano e ingles

El cartucho **no** se distribuye. Pon tu copia en la raiz como `twinbee.rom`
-32.768 bytes, sha256
`02bdce8ceafe6af05a45b61a689e78807551df663afd152090f7cd9cac827dd4`- y
`make comprueba` te dira si es la misma.

## Reproducirlo

    make comprueba     # es tu ROM esta
    make               # listado, reensamblado, comprobaciones y tests
    make imagenes      # dibuja el escenario, los sprites y las pantallas
    make vram          # coteja esas imagenes contra la VRAM de openMSX

## Ni una captura

Todas las imagenes de `docs/` estan **dibujadas desde los bytes de la ROM**,
ejecutando en Python el mismo descompresor, el mismo espejo y el mismo montador
de filas que corre el Z80. Y luego se cotejan byte a byte contra la VRAM que
openMSX tiene de verdad.

## Algo de lo que aparecio

- **En la ROM solo esta media nave.** De cada patron de sprite se guarda la
  mitad izquierda; la derecha la calcula el cartucho invirtiendo cada byte bit
  a bit. Por eso todo lo que vuela en este juego es simetrico.
- **La demostracion es una partida grabada**, y el registro R del Z80 -que es
  de donde este cartucho saca el azar- se pone a cero para que salga siempre
  igual.
- **La tabla de coseno es la de Knightmare**, con dos de sus tres erratas
  arregladas y una que sobrevive.
- **La VRAM hace de mesa de trabajo**: el descompresor solo sabe escribir en la
  memoria de video, asi que una tabla que tiene que acabar en la RAM se
  descomprime en un hueco de la tabla de atributos de sprites y se lee de
  vuelta con LDIRMV.

El resto esta en [la pagina de hallazgos](https://antxiko.github.io/TwinBee-disassembly/es/HALLAZGOS.html).

## Creditos

La marca oculta de Konami del final de la ROM la **descubrio Manuel Pazos**;
sin su trabajo esos nueve bytes serian relleno.

## Legal

Ver [AVISO-LEGAL.md](AVISO-LEGAL.md). Esto es trabajo de preservacion y
documentacion; el juego es de Konami y la imagen del cartucho no se distribuye.
