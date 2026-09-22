#!/usr/bin/env python3
"""Genera la portada de la web de Twin Bee, en los dos idiomas.

El diseno es el compartido por la serie (tools/estilo_web.py) y la pagina sale
autocontenida, con las imagenes embebidas como data URI.

Las imagenes NO son ilustraciones ni capturas: las dibujan tools/mapas.py,
tools/sprites.py y tools/pantallas.py a partir de los propios bytes de la ROM,
ejecutando en Python el descompresor, el montador de bandas y el interprete de
rotulos que corre el Z80. Ninguna se ha retocado, y todas estan cotejadas byte
a byte contra la VRAM del emulador con tools/coteja_vram.py.

Uso: make_web.py <docs/imagenes> <salida.html> <idioma>
"""
import base64
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estilo_web import ESTILO                                   # noqa: E402

# Las cifras salen de contar sobre el listado generado, no de escribirlas a
# ojo: 32768 = 14406 + 18362, que es lo que imprime tools/presupuesto.py
# (make sanity). RUTINAS son los bloques con nombre que cuenta densidad.py y
# DENSIDAD la proporcion de instrucciones comentadas, las dos de
# tools/densidad.py (make densidad).
CODIGO = 14406
DATOS = 18362
RUTINAS = 1000
INSTRUCCIONES = 7405
COMENTARIOS = 3062
DENSIDAD = "41,4"
DENSIDAD_EN = "41.4"


def mil(n, idioma):
    return f"{n:,}".replace(",", "." if idioma == "es" else ",")


TXT = {
    "es": dict(
        titulo="Twin Bee - desensamblado comentado",
        aviso="<b>Aqui no hay ninguna captura.</b> Todas las imagenes "
              "estan <b>dibujadas desde los bytes de la ROM</b>, ejecutando "
              "en Python el mismo descompresor, el mismo espejo y el mismo "
              "montador de filas que corre el Z80, y <b>cotejadas byte a "
              "byte contra la VRAM de openMSX</b>: la pantalla del titulo da "
              "<b>cero</b> diferencias en los <b>16.384 bytes</b> enteros, y "
              "las cinco fases dan <b>cero</b> en sus 900 casillas de "
              "decorado y en los 2.048 bytes de patrones de sprite. El "
              "listado y las cifras se reproducen con <code>make</code>, y el "
              "reensamblado devuelve la ROM <b>byte a byte</b>.",
        claim="<b>Los sprites de Twin Bee estan a medias en la ROM.</b> De "
              "cada uno solo se guarda la mitad izquierda: la derecha la "
              "calcula el cartucho invirtiendo cada byte bit a bit, y por eso "
              "todo lo que vuela en este juego es simetrico. El mismo espejo "
              "monta el decorado, y el descompresor -que solo sabe escribir "
              "en la VRAM- llega a usar la memoria de video de mesa de "
              "trabajo para dejar una tabla en la RAM.",
        ficha=["Konami - <b>(c) Konami 1986</b>",
               "Cartucho <b>RC-740</b>, 32 KB",
               "MSX1 - <b>paginas 1 y 2</b>", "Volcado <b>02bdce8c...</b>"],
        nav=[("#numbers", "Las cifras"), ("#findings", "Hallazgos"),
             ("#stages", "El escenario"), ("#screens", "Lo que dibuja")],
        docnav=[("EMPEZAR.html", "Empezar"), ("EL-JUEGO.html", "El juego"),
                ("EL-CARTUCHO.html", "El cartucho"),
                ("EL-CODIGO.html", "El codigo"),
                ("HALLAZGOS.html", "Hallazgos"),
                ("EN-EL-EMULADOR.html", "En el emulador"),
                ("PREGUNTAS-ABIERTAS.html", "Preguntas abiertas")],
        otro=("../", "In English"),
        h_num="El cartucho en cifras", h_find="Lo que aparecio al desmontarlo",
        h_fas="Las cinco fases, cada una con su tramo y su paleta",
        nota_fas="El escenario de Twin Bee es una tira de 1.761 filas que las "
                 "cinco fases recorren seguidas: cada mapa es el tramo de su "
                 "fase, con los jefes en las filas 261, 585, 945, 1272 y 1760. "
                 "Tres columnas, de arriba abajo y de izquierda a derecha, con "
                 "el fondo negro de partida.",
        h_scr="Lo que el cartucho dibuja",
        cifras=[("100 %", "del binario explicado"),
                (str(RUTINAS), "bloques de codigo medidos"),
                (DENSIDAD + " %", "del listado comentado"),
                (mil(CODIGO, "es"), "bytes de codigo"),
                (mil(DATOS, "es"), "bytes de datos"),
                ("0", "bytes sin identificar")],
        nota_scr="Debajo de cada imagen esta de donde sale y que se esta "
                 "viendo.",
        pie_leg="Esto es trabajo de documentacion y preservacion: el codigo y "
                "los graficos siguen siendo de sus autores y de Konami, y la "
                "imagen del cartucho no se distribuye.",
    ),
    "en": dict(
        titulo="Twin Bee - a commented disassembly",
        aviso="<b>Not one capture here.</b> Every picture is <b>drawn from "
              "the bytes of the ROM</b>, by running in Python the very same "
              "decompressor, mirror and row builder the Z80 runs, and then "
              "<b>checked byte for byte against the VRAM of openMSX</b>: the "
              "title screen comes out with <b>zero</b> differences over all "
              "<b>16,384 bytes</b>, and the five stages with <b>zero</b> "
              "across their 900 scenery tiles and the 2,048 bytes of sprite "
              "patterns. The listing and the numbers are reproducible with "
              "<code>make</code>, and reassembling gives back the ROM "
              "<b>byte for byte</b>.",
        claim="<b>Twin Bee sprites are half-stored in the ROM.</b> Only "
              "the left half of each one is kept: the cartridge works out the "
              "right half by flipping every byte bit for bit, which is why "
              "everything that flies in this game is symmetric. The same "
              "mirror builds the scenery, and the decompressor -which can "
              "only write to VRAM- even uses video memory as a workbench to "
              "get a table into RAM.",
        ficha=["Konami - <b>(c) Konami 1986</b>",
               "An <b>RC-740</b> 32 KB cartridge",
               "MSX1 - <b>pages 1 and 2</b>", "Dump <b>02bdce8c...</b>"],
        nav=[("#numbers", "The numbers"), ("#findings", "What turned up"),
             ("#stages", "The scenery"), ("#screens", "What it draws")],
        docnav=[("GETTING-STARTED.html", "Getting started"),
                ("THE-GAME.html", "The game"),
                ("THE-CARTRIDGE.html", "The cartridge"),
                ("THE-CODE.html", "The code"),
                ("FINDINGS.html", "Findings"),
                ("IN-THE-EMULATOR.html", "In the emulator"),
                ("OPEN-QUESTIONS.html", "Open questions")],
        otro=("es/", "En castellano"),
        h_num="The cartridge in numbers",
        h_find="What turned up when we took it apart",
        h_fas="The five stages, each with its own stretch and palette",
        nota_fas="Twin Bee's scenery is a 1,761-row strip that the five "
                 "stages run through back to back: each map is its stage's "
                 "stretch, with the bosses at rows 261, 585, 945, 1272 and "
                 "1760. Three columns, top to bottom and left to right, on "
                 "the black background of play.",
        h_scr="What the cartridge draws",
        cifras=[("100%", "of the binary explained"),
                (str(RUTINAS), "code blocks measured"),
                (DENSIDAD_EN + "%", "of the listing commented"),
                (mil(CODIGO, "en"), "bytes of code"),
                (mil(DATOS, "en"), "bytes of data"),
                ("0", "bytes unidentified")],
        nota_scr="Under each picture is where it comes from and what is on it.",
        pie_leg="This is documentation and preservation work: the code and "
                "artwork still belong to their authors and to Konami, and the "
                "cartridge image is not distributed.",
    ),
}

# El contenido propio de este cartucho vive aparte, en contenido_web.py:
# asi el generador no lleva dentro ni un texto del juego anterior.
from contenido_web import HALLAZGOS, GALERIA, FASES  # noqa: E402


def img64(ruta):
    with open(ruta, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    imgdir, salida, idioma = argv[1:4]
    t = TXT[idioma]

    # El "logotipo" de la cabecera no es un montaje ni una captura: es la
    # pantalla de titulo que el propio cartucho pinta, dibujada desde la ROM
    # por pantallas.py. Si el PNG no esta, el trabajo NO esta hecho: se cae al
    # texto, y eso se ve.
    ruta_logo = os.path.join(imgdir, "logotipo.png")
    cabecera = (f'<img src="{img64(ruta_logo)}" alt="Twin Bee">'
                if os.path.exists(ruta_logo)
                else "<h1>Twin Bee</h1>")

    nav = "".join(f'<a href="{h}">{x}</a>' for h, x in t["nav"])
    nav += "".join(f'<a href="{h}">{x}</a>' for h, x in t["docnav"])
    nav += (f'<a href="{t["otro"][0]}" style="margin-left:auto;color:var(--oro)">'
            f'{t["otro"][1]}</a>')

    cifras = "".join(f'<div class="cifra"><b>{v}</b><span>{e}</span></div>'
                     for v, e in t["cifras"])
    halls = "".join(f'<div class="hall"><h3>{tit}</h3>{cuerpo}</div>'
                    for tit, cuerpo in HALLAZGOS[idioma])
    imgs = ""
    faltan = []
    for fich, es, en in GALERIA:
        ruta = os.path.join(imgdir, fich)
        if not os.path.exists(ruta):
            faltan.append(fich)
            continue
        pie = es if idioma == "es" else en
        imgs += (f'<figure><img src="{img64(ruta)}" alt="{pie}">'
                 f'<figcaption>{pie}</figcaption></figure>')
    # el escenario, una tira por fase
    tiras = ""
    for fich, es, en in FASES:
        ruta = os.path.join(imgdir, fich)
        if not os.path.exists(ruta):
            faltan.append(fich)
            continue
        pie = es if idioma == "es" else en
        tiras += (f'<figure><img src="{img64(ruta)}" alt="{pie}">'
                  f'<figcaption>{pie}</figcaption></figure>')
    if faltan:
        print("  (faltan %d imagenes: %s)" % (len(faltan), " ".join(faltan)))

    html = f"""<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t['titulo']}</title>
<style>{ESTILO}</style>
<header class="top">
  {cabecera}
  <p class="claim">{t['claim']}</p>
  <p class="ficha">{' - '.join(t['ficha'])}</p>
</header>
<p class="ficha" style="border:1px solid var(--oro);padding:.8em 1em;margin:1.5em 0">
{t['aviso']}</p>
<nav>{nav}</nav>
<section id="numbers">
  <h2>{t['h_num']}</h2>
  <div class="cifras">{cifras}</div>
</section>
<section id="findings"><h2>{t['h_find']}</h2>{halls}</section>
<section id="stages">
  <h2>{t['h_fas']}</h2>
  <p class="n">{t['nota_fas']}</p>
  <div class="fases">{tiras}</div>
</section>
<section id="screens">
  <h2>{t['h_scr']}</h2>
  <p class="n">{t['nota_scr']}</p>
  <div class="galeria">{imgs}</div>
</section>
<footer><p>{t['pie_leg']}</p></footer>
"""
    with open(salida, "w", encoding="utf-8") as f:
        f.write(html)
    print("  %s: %d KB (%s)" % (salida, len(html) // 1024, idioma))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
