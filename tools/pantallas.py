#!/usr/bin/env python3
"""Monta pantallas enteras ejecutando en Python los pasos del cartucho.

No hay ni una captura de pantalla en este repositorio. Cada lamina se
construye igual que la construye el juego -descomprimiendo sus guiones en una
VRAM de mentira y pintando esa VRAM con la paleta del TMS9918-, y que este
bien hecho no es una opinion: tools/coteja_vram.py resta esta misma VRAM de la
que el emulador tiene DE VERDAD.

**La herencia importa.** La VRAM de una pantalla no es lo que esa pantalla
sube: es eso MAS lo que dejo la anterior. Las casillas altas del decorado de
las fases 2, 3 y 4 no las carga la fase -su bloque de pareja no llega ahi- y
lo que se ve en ellas es lo que quedo de la pantalla del titulo, con el color
0x80 que le puso el FILVRM de 0x4BEC. Sin encadenar presentacion -> titulo ->
fase, el cotejo falla en esas casillas y uno se pone a buscar una carga que no
existe. La cadena de aqui no esta supuesta: sale de tools/omsx_cargas.tcl, que
la apunta en el emulador con un punto de interrupcion en cada puerta del
descompresor.

Lo que sale:

    presentacion.png    el cartel de KONAMI que baja
    titulo.png          la pantalla del titulo entera
    logotipo.png        solo el rotulo, para la cabecera de la web
    fuente.png          las casillas de la fuente, con su codigo
    casillas_faseN.png  la hoja de casillas del decorado de cada fase
    pantalla_faseN.png  la primera pantalla de cada fase

Uso: pantallas.py <rom> <org> <directorio de salida>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from descomprime import descomprime, tres_bancos                # noqa: E402
from vdp import (PALETA, R7, R7_EN_JUEGO, NOMBRES, SPR_ATR, casilla, con_borde,  # noqa: E402
                 guarda, pinta)

FUENTE = 0x49D0               # -> 0x2080, casilla 0x10
LOGOTIPO = 0x4B3C             # -> 0x2200, casilla 0x40: las 27 del rotulo
GUION_DEL_TITULO = 0x4C35     # trae su destino dentro: 0x2600
TEXTOS_DEL_TITULO = 0x48C5    # dos guiones seguidos
CARTEL_DE_KONAMI = 0x48B4     # el que baja en la presentacion


def filvrm(v, hl, bc, a):
    for i in range(bc):
        v[(hl + i) & 0x3FFF] = a


def tres(v, hl, bc, a):
    """El FILVRM en los tres bancos de 0x4684."""
    for k in range(3):
        filvrm(v, hl + 0x800 * k, bc, a)


def guion_de_texto(rom, org, v, de, mascara=0xFF):
    """El guion de 0x46AD: una direccion de VRAM, los codigos que van ahi,
    0xFE para saltar a otra direccion y 0xFF para acabar."""
    p = de - org
    while True:
        hl = rom[p] | rom[p + 1] << 8
        p += 2
        while True:
            a = rom[p]
            p += 1
            if a == 0xFF:
                return org + p
            if a == 0xFE:
                break
            v[hl & 0x3FFF] = a & mascara
            hl += 1


def la_fuente(rom, org, v):
    """0x49AA: borra la casilla 0, sube la fuente y le pone color blanco."""
    tres(v, 0x2000, 8, 0)
    tres(v, 0x0000, 8, 0)
    tres_bancos(rom, org, FUENTE, 0x2080, 0, v)
    tres(v, 0x0080, 0x158, 0xF0)


def tira(v, hl, a, n):
    """0x4B2E: n casillas consecutivas desde el codigo A, y devuelve la
    casilla de la fila de abajo."""
    for _ in range(n):
        v[hl & 0x3FFF] = a
        hl += 1
        a = (a + 1) & 0xFF
    return hl - n + 0x20, a


def presentacion(rom, org, v=None):
    """La escena 0: el cartel de KONAMI bajando.

    0x4AF6 sube las 26 casillas del rotulo y 0x4B0A lo repinta una fila mas
    arriba cada vez: 3 casillas desde la 0x40, once mas, doce mas, y la fila
    de abajo borrada. Se dan los CATORCE pasos que cuenta (0xE00A), asi que
    lo que sale es donde acaba el cartel, no donde empieza."""
    if v is None:
        v = bytearray(0x4000)
    la_fuente(rom, org, v)
    tres_bancos(rom, org, LOGOTIPO, 0x2200, 0, v)
    tres(v, 0x0200, 0xD8, 0xF0)
    hl = 0x3AAA
    for _ in range(14):
        hl -= 0x20
        p, a = tira(v, hl, 0x40, 3)
        p, a = tira(v, p, a, 11)
        p, a = tira(v, p, a, 12)
        filvrm(v, p, 12, 0)
    # y el cartel de texto, que 0x418D sube al acabarse los catorce pasos
    descomprime(rom, org, CARTEL_DE_KONAMI, vram=v)
    return v


def titulo(rom, org, v=None):
    """La escena 0 subescena 2: la pantalla del titulo entera (0x4BD3)."""
    if v is None:
        v = presentacion(rom, org)
    filvrm(v, NOMBRES, 0x300, 0)
    la_fuente(rom, org, v)
    descomprime(rom, org, GUION_DEL_TITULO, vram=v)
    # 0x4BEC llama a FILVRM directamente, no a 0x4684: este relleno va en UN
    # banco, no en los tres. Darle los tres deja el color del titulo mal en
    # los dos tercios de abajo, y el cotejo de la fase 4 lo saca.
    filvrm(v, 0x0600, 0x108, 0x80)
    hl, a = 0x38AA, 0xC0
    for _ in range(3):                      # el rotulo: 3 filas de 11
        p = hl
        for _ in range(11):
            v[p & 0x3FFF] = a
            p += 1
            a = (a + 1) & 0xFF
        hl += 0x20
    p = guion_de_texto(rom, org, v, TEXTOS_DEL_TITULO)
    guion_de_texto(rom, org, v, p)
    aparta_los_sprites(v)
    return v


def aparta_los_sprites(v):
    """0x46C1 pone 0xE0 en la Y de los 32 sprites del buffer de 0xEF80 y
    0x46CE lo sube a la tabla de atributos: fuera de la pantalla."""
    for k in range(32):
        v[SPR_ATR + 4 * k] = 0xE0


def hoja(v, cas0, cas1, banda=0, cols=16, r7=R7):
    """Una hoja con las casillas de cas0 a cas1, para mirarlas de una vez."""
    filas = (cas1 - cas0 + cols - 1) // cols
    px = [[PALETA[r7 & 0x0F]] * (cols * 8) for _ in range(filas * 8)]
    for i in range(cas1 - cas0):
        d = casilla(v, cas0 + i, banda, r7)
        oy, ox = (i // cols) * 8, (i % cols) * 8
        for y in range(8):
            px[oy + y][ox:ox + 8] = d[y]
    return px


def main():
    from mapas import vram_de_la_fase, mapa, pinta_tira, FASES
    rom = open(sys.argv[1], "rb").read()
    org = int(sys.argv[2], 0)
    sal = sys.argv[3]
    os.makedirs(sal, exist_ok=True)

    # Las pantallas van con el BORDE del MSX alrededor, del color que tiene el
    # registro 7 en ese momento: azul (0xE4) en la presentacion y el titulo,
    # negro (0xE0) en cuanto empieza la partida. Lo pidio el usuario: que se
    # vean como en el monitor, no como un recorte.
    v = presentacion(rom, org)
    guarda(con_borde(pinta(v), R7), os.path.join(sal, "presentacion.png"))
    v = titulo(rom, org, v)
    guarda(con_borde(pinta(v), R7), os.path.join(sal, "titulo.png"))
    # el rotulo solo: las tres filas de once casillas que pone 0x4BF9
    nombres = v[NOMBRES:NOMBRES + 768]
    px = pinta(v, nombres)
    guarda([f[80:168] for f in px[40:64]], os.path.join(sal, "logotipo.png"), 3)
    guarda(hoja(v, 0x10, 0x40), os.path.join(sal, "fuente.png"), 3)

    # La primera pantalla de cada fase NO es la de la tira: la tira lleva las
    # cinco fases seguidas y cada una arranca donde llego el jefe anterior
    # (mapas.tramo_de_la_fase). Antes se pintaba el arranque de la fase 1 con
    # las casillas de las cinco; lo cazo el usuario mirando las laminas.
    from mapas import tramo_de_la_fase
    codigos = mapa(rom, org)            # indice 0 = la fila de abajo del arranque
    for fase in range(1, FASES + 1):
        vf = vram_de_la_fase(rom, org, fase, titulo(rom, org))
        # las casillas se ven JUGANDO (registro 7 a 0xE0: color 0 = negro), y
        # la fase 5 sube hasta la 0xEA: la hoja llegaba solo a la 0xD2
        guarda(hoja(vf, 0x3C, 0xEB, r7=R7_EN_JUEGO),
               os.path.join(sal, "casillas_fase%d.png" % fase), 3)
        primera, _ultima = tramo_de_la_fase(rom, org, fase)
        pantalla = codigos[primera:primera + 24][::-1]   # de arriba abajo, como se ve
        guarda(con_borde(pinta_tira(rom, org, vf, pantalla), R7_EN_JUEGO),
               os.path.join(sal, "pantalla_fase%d.png" % fase))


if __name__ == "__main__":
    main()
