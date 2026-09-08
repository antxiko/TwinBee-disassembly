#!/usr/bin/env python3
"""Resta la VRAM calculada de la que el emulador tiene DE VERDAD.

Mirar un dibujo y decir que "se ve bien" no es una comprobacion: un color
cambiado o media hoja de casillas desplazada se ve igual de convincente. Lo
que si comprueba es esto: se deja correr el cartucho en openMSX, se vuelcan
los 16 KB de VRAM en los instantes que importan (tools/omsx_vram.tcl) y se
comparan BYTE A BYTE con los que tools/pantallas.py y tools/mapas.py levantan
en Python desde la ROM.

Se compara:

  - la pantalla del titulo, los 16384 bytes enteros;
  - de cada una de las cinco fases, la hoja de casillas del decorado -patrones
    y color de la 0x3C a la 0xD1, en los tres bancos- y los 2 KB enteros de la
    tabla de patrones de SPRITE, que es lo que esta subido en el instante del
    volcado.

Uso: coteja_vram.py <rom> <org> <carpeta de volcados>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mapas import vram_de_la_fase, FASES                        # noqa: E402
from pantallas import titulo                                    # noqa: E402
from sprites import vram_de_sprites                             # noqa: E402
from vdp import PATRONES, COLOR, SPR_PAT                        # noqa: E402

CAS0, CAS1 = 0x3C, 0xD2


def casillas_distintas(mia, real):
    dif = set()
    for banda in range(3):
        for cas in range(CAS0, CAS1):
            for k in range(8):
                p = PATRONES + banda * 0x800 + cas * 8 + k
                c = COLOR + banda * 0x800 + cas * 8 + k
                if mia[p] != real[p]:
                    dif.add(("patron", banda, cas))
                if mia[c] != real[c]:
                    dif.add(("color", banda, cas))
    return dif


def main():
    rom = open(sys.argv[1], "rb").read()
    org = int(sys.argv[2], 0)
    carpeta = sys.argv[3]
    base = titulo(rom, org)
    fallos = 0

    fn = os.path.join(carpeta, "vram_titulo.bin")
    if os.path.exists(fn):
        real = open(fn, "rb").read()
        d = [i for i in range(0x4000) if base[i] != real[i]]
        print("  titulo: %d bytes distintos de 16384" % len(d))
        fallos += len(d)
    else:
        print("  titulo: sin volcado (haz `make vram`)")

    for fase in range(1, FASES + 1):
        fn = os.path.join(carpeta, "vram_fase%d.bin" % fase)
        if not os.path.exists(fn):
            print("  fase %d: sin volcado" % fase)
            continue
        real = open(fn, "rb").read()
        dif = casillas_distintas(vram_de_la_fase(rom, org, fase, base), real)
        vs = vram_de_sprites(rom, org, fase)
        ds = [i for i in range(SPR_PAT, SPR_PAT + 0x800) if vs[i] != real[i]]
        print("  fase %d: %d casillas distintas de %d, y %d bytes de sprite "
              "distintos de 2048" %
              (fase, len(dif), 3 * 2 * (CAS1 - CAS0), len(ds)))
        fallos += len(dif) + len(ds)

    print("  ==> %s" % ("TODO IGUAL" if not fallos else "%d DIFERENCIAS" % fallos))
    return 1 if fallos else 0


if __name__ == "__main__":
    sys.exit(main())
