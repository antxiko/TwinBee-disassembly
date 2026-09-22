#!/usr/bin/env python3
"""Dibuja el escenario entero de cada fase, ejecutando lo que hace el cartucho.

Aqui no hay ni una captura de pantalla. La tira de cada fase se monta
repitiendo paso a paso lo que hacen 0x460C y 0x6CD1:

  - **0x460C descomprime el mapa a la RAM.** El guion de 0x6D74 es una lista
    de indices terminada en 0xFF; cada indice entra en la tabla de punteros de
    0x6E01 y saca un TRAMO, y cada tramo es una lista de codigos de fila que
    se copia tal cual a 0xE400 (`ldi` en 0x4628) hasta su propio 0xFF.
  - **cada codigo de fila es un bloque de 32 bytes de 0x6F8F**: 0x6D62 lo
    calcula con cinco `add hl,hl`, o sea indice * 32, y 0x6D17 lo copia con
    treinta y dos `ldi` al buffer de la tabla de nombres (0xEC40). Una fila
    de la pantalla, ni mas ni menos.

De ahi sale la cuenta que lo cierra: entre 0x6F8F y 0x8E8F hay 0x1F00 bytes,
que son 248 filas de 32 casillas exactas, y el codigo mas alto que usan los
tramos es 0xF7 = 247. No sobra ni falta un byte.

Y LA TIRA NO ES UNA FASE: SON LAS CINCO SEGUIDAS. La partida arranca con el
indice (0xEBF0) en 23 (0x5D27) y el hito del jefe en 261 (0x5D37); cuando el
indice llega al hito, 0x610E saca al jefe y toma el hito siguiente de la
tabla de 0x6132 -261, 585, 945, 1272, 1760-, y al caer el jefe 0x613C sube
las casillas del escenario siguiente SIN mover el indice. O sea que cada fase
juega su tramo de la misma tira: la 1 de la fila 0 a la 261, la 2 de la 238 a
la 585, la 3 de la 562 a la 945, la 4 de la 922 a la 1272 y la 5 de la 1249 a
la 1760 -las 24 filas de solape son la pantalla del jefe, que se ve con los
dos juegos de casillas-. Antes esta herramienta pintaba la tira ENTERA con
las casillas de cada fase, y salian cinco mapas de 73 pantallas que no
existen; lo cazo el usuario mirando las laminas.

Comprobado en openMSX (tools/omsx_mapa.tcl): la lista de 0xE400 es identica a
la que sale de aqui, byte a byte, y la tabla de nombres son los bloques de las
filas (0xEBF0)-r en tres instantes distintos de la demostracion.

Las casillas salen de 0x994A (los patrones) y 0x9F2F (el color), cada una con
su tabla por fase. Y la fase 3 no tiene color propio: usa el de las demas
pasado por la PERMUTA de 0x47B5, que 0x9F67 enciende con el bit 7 de C.

Uso: mapas.py <rom> <org> <directorio de salida>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from descomprime import descomprime, tres_bancos                # noqa: E402
from vdp import PALETA, R7_EN_JUEGO, casilla, guarda            # noqa: E402

# El escenario se ve JUGANDO, y jugando el registro 7 vale 0xE0: el borde y las
# casillas de color 0 son negras, no azules como en el titulo.
R7 = R7_EN_JUEGO

GUION_DEL_MAPA = 0x6D74       # la lista de tramos, cerrada con 0xFF
TABLA_DE_TRAMOS = 0x6E01      # 29 punteros de 16 bits
FILAS = 0x6F8F                # 248 bloques de 32 casillas
FIN_DE_FILAS = 0x8E8F
FASES = 5
ARRANQUE = 23                 # 0x5D27: la fila de arriba de la primera pantalla
HITOS = 0x6132                # las cinco filas en las que llega cada jefe
ALTO_DE_PANTALLA = 24

# Las dos tablas por fase de 0x996E y 0x9F88: un puntero suelto y una pareja.
PAT_SUELTO = 0x9994           # -> 0x2600
PAT_PAREJA = 0x999E           # (guion, destino), y va ESPEJADO
COL_SUELTO = 0x9FAE           # -> 0x0600
COL_PAREJA = 0x9FB8

# Lo que 0x994A y 0x9F2F suben igual para todas las fases.
COMUNES = (
    (0x99B2, 0x21E0, 0), (0x9BE7, 0x2498, 1),
    (0x9C37, 0x24E8, 0), (0x9C8C, 0x25A8, 1),
    (0xA05A, 0x03B0, 0), (0xA087, 0x0498, 0),
)
# Y los tres bloques de color que la fase 3 recibe permutados (0x9F67).
COLOR_BASE = ((0x9FCC, 0x01E0), (0xA096, 0x04E8), (0xA0B6, 0x05A8))


def palabra(rom, org, a):
    return rom[a - org] | rom[a - org + 1] << 8


def vram_de_la_fase(rom, org, fase, heredada=None):
    """La VRAM tal como la dejan 0x994A y 0x9F2F para la fase dada (1..5).

    `heredada` es lo que quedo de la pantalla anterior: las casillas altas de
    las fases 2, 3 y 4 no las toca nadie al empezar y conservan lo del titulo.
    """
    v = bytearray(heredada) if heredada is not None else bytearray(0x4000)
    for de, hl, c in COMUNES:
        tres_bancos(rom, org, de, hl, c, v)
    # el color base: permutado solo en la fase 3
    c = 0x80 if fase == 3 else 0
    for k, (de, hl) in enumerate(COLOR_BASE):
        tres_bancos(rom, org, de, hl, c | (1 if k and c else 0), v)
    i = fase - 1
    tres_bancos(rom, org, palabra(rom, org, PAT_SUELTO + 2 * i), 0x2600, 0, v)
    tres_bancos(rom, org, palabra(rom, org, COL_SUELTO + 2 * i), 0x0600, 0, v)
    # la pareja de patrones va ESPEJADA (0x9991 salta a 0x4695, c=1) y la de
    # color NO (0x9FAB salta a 0x4699, c=0). Confundirlas cuesta las casillas
    # altas de tres fases, y el cotejo contra la VRAM del emulador lo caza.
    for base, c in ((PAT_PAREJA, 1), (COL_PAREJA, 0)):
        de = palabra(rom, org, base + 4 * i)
        hl = palabra(rom, org, base + 4 * i + 2)
        tres_bancos(rom, org, de, hl, c, v)
    return v


def mapa(rom, org):
    """La tira de codigos de fila que 0x460C deja en 0xE400.

    OJO AL SENTIDO: sale en el orden en que esta guardada, que es de ABAJO
    hacia ARRIBA. 0x6D08 monta la pantalla empezando por el indice que marca
    (0xEBF0) y BAJANDO -0x6D62 guarda el puntero y el bucle hace `dec hl`
    antes de cada fila-, y ese indice ARRANCA EN 23 (0x5D27) y sube conforme
    avanza el juego. O sea que el codigo 0 es la ultima fila de la partida y
    el ultimo es la primera. Para verla como se ve, hay que darle la vuelta.
    """
    out = []
    p = GUION_DEL_MAPA - org
    while rom[p] != 0xFF:
        t = palabra(rom, org, TABLA_DE_TRAMOS + rom[p])
        p += 1
        q = t - org
        while rom[q] != 0xFF:
            out.append(rom[q])
            q += 1
    return out


def fila(rom, org, codigo):
    """Las 32 casillas del bloque numero `codigo` (0x6D62: indice * 32)."""
    a = FILAS - org + codigo * 32
    return rom[a:a + 32]


def hitos(rom, org):
    """Las cinco filas de la tabla de 0x6132 en las que llega cada jefe."""
    return [palabra(rom, org, HITOS + 2 * i) for i in range(FASES)]


def tramo_de_la_fase(rom, org, fase):
    """(primera, ultima) fila de la tira -indices de 0xE400- que se ven con
    las casillas de la fase dada. La primera pantalla de la fase 1 va de la
    fila 23 a la 0; las demas arrancan donde llego el jefe anterior, con su
    pantalla de 24 filas ya puesta."""
    h = hitos(rom, org)
    arranque = ARRANQUE if fase == 1 else h[fase - 2]
    return arranque - (ALTO_DE_PANTALLA - 1), h[fase - 1]


def pinta_tira(rom, org, v, codigos, banda=None):
    """Pinta las filas que se le den, cada una con el banco que le toca en la
    pantalla. `banda` fija el banco; sin ella se usa el de la posicion."""
    fondo = PALETA[R7 & 0x0F]
    px = [[fondo] * 256 for _ in range(8 * len(codigos))]
    for f, cod in enumerate(codigos):
        n = fila(rom, org, cod)
        b = banda if banda is not None else (f // 8) % 3
        for c in range(32):
            d = casilla(v, n[c], b, R7)
            for y in range(8):
                px[f * 8 + y][c * 8:c * 8 + 8] = d[y]
    return px


def en_columnas(rom, org, v, codigos, columnas=8, hueco=8):
    """El mapa entero repartido en columnas, que de una tirada son 14.000
    pixeles de alto y no hay quien los mire. Se lee de arriba abajo y de
    izquierda a derecha, y cada columna sigue donde acabo la anterior."""
    porcol = (len(codigos) + columnas - 1) // columnas
    tiras = [pinta_tira(rom, org, v, codigos[i * porcol:(i + 1) * porcol])
             for i in range(columnas)]
    alto = max(len(t) for t in tiras)
    fondo = PALETA[R7 & 0x0F]
    ancho = columnas * 256 + (columnas - 1) * hueco
    px = [[fondo] * ancho for _ in range(alto)]
    for i, t in enumerate(tiras):
        ox = i * (256 + hueco)
        for y, fila in enumerate(t):
            px[y][ox:ox + 256] = fila
    return px


def main():
    rom = open(sys.argv[1], "rb").read()
    org = int(sys.argv[2], 0)
    sal = sys.argv[3]
    os.makedirs(sal, exist_ok=True)
    from pantallas import titulo
    codigos = mapa(rom, org)                # indice 0 = la fila de abajo del arranque
    print("  la tira son %d filas, %d pantallas de 24, con los jefes en las filas %s" %
          (len(codigos), len(codigos) // 24, hitos(rom, org)))
    base = titulo(rom, org)
    for fase in range(1, FASES + 1):
        primera, ultima = tramo_de_la_fase(rom, org, fase)
        tramo = codigos[primera:ultima + 1][::-1]   # de arriba abajo, como se ve
        print("  fase %d: filas %d..%d, %d filas, %.1f pantallas" %
              (fase, primera, ultima, len(tramo), len(tramo) / ALTO_DE_PANTALLA))
        v = vram_de_la_fase(rom, org, fase, base)
        guarda(en_columnas(rom, org, v, tramo, columnas=3),
               os.path.join(sal, "mapa_fase%d.png" % fase), 1)


if __name__ == "__main__":
    main()
