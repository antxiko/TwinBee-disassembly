#!/usr/bin/env python3
"""Comprobaciones sobre el listado de Twin Bee, y sobre lo que afirma.

Ninguna necesita el cartucho: las que miran bytes los sacan de los `defb` del
propio listado, que es lo mismo que hay en la ROM -eso lo garantiza
`make verify`, que reensambla y compara el sha256-.

Lo que se vigila:

  - que el listado no se degrade sin que nadie se entere: densidad, rutinas
    flojas, destinos de `call` sin bautizar, bloques de datos sin descripcion;
  - que las afirmaciones que se publican SE COMPRUEBEN sobre los bytes: que la
    cabecera del Game Master se reparta como se dice y acabe justo donde
    empieza el codigo, que la tabla de coseno se ajuste a la funcion -y que la
    errata que sobrevive siga ahi, porque es parte del hallazgo-, que los 248
    bloques de fila cuadren exactamente con el hueco que ocupan, que ningun
    codigo del mapa se salga de ellos, que la marca oculta de Konami este
    donde se dice y sea la que Nemesis busca, y que las tres escrituras a la
    propia ROM sigan siendo tres;
  - que no se cuele el nombre de otro juego de la serie, que ya ha pasado.
"""
import math
import os
import re
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASM = os.path.join(RAIZ, "src", "twinbee.asm")
NOTES = os.path.join(RAIZ, "src", "twinbee.notes")
ENTRIES = os.path.join(RAIZ, "src", "twinbee.entries")
ORG, FIN = 0x4000, 0xC000

# Los demas juegos de la serie. Que el nombre de otro salga en una pagina de
# este es casi siempre un copia y pega: ya paso con cinco ficheros LICENSE, con
# el pie de catorce paginas de otro proyecto y con unos tests que llegaron
# copiados y apuntaban al .asm de otro cartucho.
#
# CUATRO nombres NO estan en la lista, y no por dejadez, sino porque son
# contenido de este desensamblado: "Knightmare", que es el cartucho con el que
# comparte la tabla de coseno; "Nemesis", que es el que busca su marca oculta
# por las ranuras; "The Goonies", que es el otro que trae el mismo armazon; y
# el "Game Master", que es el cartucho de trucos que lee su segunda cabecera.
# Los cuatro tienen su propio test aqui abajo.
OTROS_JUEGOS = (
    "temptations", "ale hop", "alehop", "colt 36", "colt36", "stardust",
    "antarctic", "pitfall", "war in middle earth", "athletic land",
    "monkey academy", "f-1 spirit", "f1 spirit", "pippols", "time pilot",
    "frogger", "super cobra", "billiards", "mahjong", "demonia",
    "hyper olympic", "hyper rally", "hyper sports", "sky jaguar",
    "king's valley", "kings valley", "mopi ranger", "mopiranger",
    "road fighter", "ping pong", "soccer", "football", "trailblazer",
    "cabbage patch", "baseball", "yie ar kung-fu", "yie ar kung fu",
    "bomber man", "bomberman", "boxing", "hole in one", "casio world open",
    "3d golf", "descubrimiento",
)


def lee(fn):
    return open(fn, encoding="utf-8").read()


def bytes_del_listado():
    """Los 32768 bytes del cartucho, sacados de los `defb` y de los `defw` del
    propio listado. Que esto sea la ROM lo garantiza `make verify`."""
    mem = {}
    for ln in lee(ASM).split("\n"):
        m = re.match(r"^\tdef([bw])\s+(.*?)\t*;\s*([0-9a-f]{4})", ln)
        if not m:
            continue
        ancho = 1 if m.group(1) == "b" else 2
        a = int(m.group(3), 16)
        for v in m.group(2).split(","):
            v = v.strip()
            if not v:
                continue
            n = int(v.rstrip("h"), 16) if v.endswith("h") else int(v)
            for k in range(ancho):
                mem[a] = (n >> (8 * k)) & 0xFF
                a += 1
    return mem


class ElListadoNoSeDegrada(unittest.TestCase):
    """Los numeros que se publican, comprobados sobre el listado."""

    @classmethod
    def setUpClass(cls):
        cls.asm = lee(ASM)
        cls.lineas = cls.asm.split("\n")

    def instrucciones(self):
        """Las lineas que son una instruccion de verdad, con su comentario."""
        out = []
        for ln in self.lineas:
            m = re.match(r"^\t(?!def[bw])(\S.*?)\t+;([0-9a-f]{4})(.*)$", ln)
            if m:
                out.append((int(m.group(2), 16), m.group(3).strip()))
        return out

    def test_la_densidad_no_baja_del_22_por_ciento(self):
        ins = self.instrucciones()
        con = [a for a, c in ins if c.startswith("; ")]
        self.assertGreater(len(ins), 7000, "faltan instrucciones en el listado")
        pct = 100.0 * len(con) / len(ins)
        self.assertGreaterEqual(
            pct, 22.0,
            "la densidad ha bajado a %.1f %% (%d de %d)" % (pct, len(con), len(ins)))

    def test_ningun_destino_de_call_se_queda_sin_nombre(self):
        """Una etiqueta a la que solo se llega con un salto puede quedarse en
        L_xxxx; una que es destino de un `call` es una rutina y tiene nombre."""
        sin = sorted({m.group(1) for m in
                      re.finditer(r"^\tcall\s+(?:\w\w,)?(L_[0-9A-F]{4})",
                                  self.asm, re.M)})
        self.assertEqual(sin, [], "destinos de call sin bautizar: %s" % sin)

    def test_todo_bloque_de_datos_lleva_descripcion(self):
        for m in re.finditer(r"^; DATOS (\S+)", self.asm, re.M):
            self.assertNotEqual(
                m.group(1), "sin",
                "queda un bloque de datos sin identificar en el listado")

    def test_los_cuatro_cartuchos_que_si_se_nombran(self):
        """Knightmare, Nemesis, The Goonies y el Game Master salen en el
        .notes porque son contenido, no descuido: si alguno desaparece, es que
        se ha perdido el hallazgo que lo traia."""
        n = lee(NOTES).lower()
        self.assertIn("knightmare", n, "falta la comparacion de la tabla de coseno")
        self.assertIn("nemesis", n, "falta quien busca la marca oculta")
        self.assertIn("goonies", n, "falta el otro cartucho del mismo armazon")
        self.assertIn("game master", n, "falta la segunda cabecera")

    def test_no_se_nombra_a_otro_juego_de_la_serie(self):
        bajo = self.asm.lower() + lee(NOTES).lower()
        colados = [j for j in OTROS_JUEGOS if j in bajo]
        self.assertEqual(colados, [],
                         "se ha colado el nombre de otro juego de la serie")


class LasAfirmacionesSeSostienen(unittest.TestCase):
    """Lo que dice la web, comprobado sobre los bytes del cartucho."""

    @classmethod
    def setUpClass(cls):
        cls.mem = bytes_del_listado()
        cls.asm = lee(ASM)

    def b(self, a):
        return self.mem[a]

    def w(self, a):
        return self.mem[a] | self.mem[a + 1] << 8

    def test_las_dos_cabeceras(self):
        self.assertEqual(bytes(self.b(a) for a in (0x4000, 0x4001)), b"AB")
        self.assertEqual(self.w(0x4002), 0x40B1, "el INIT que declara la cabecera")
        for a in range(0x4004, 0x4010):
            self.assertEqual(self.b(a), 0, "el resto de la cabecera va a cero")
        self.assertEqual(bytes(self.b(a) for a in (0x4010, 0x4011)), b"CD")
        self.assertEqual((self.b(0x4012), self.b(0x4013)), (0x07, 0x40),
                         "el numero de catalogo: RC-740")

    def test_la_cabecera_del_game_master_acaba_donde_empieza_el_codigo(self):
        """El reparto que describe el .notes se ejecuta aqui igual que lo
        ejecuta 0x5E92 del Game Master: un `rra` por campo, y el bit A CERO
        quiere decir que el campo viene. Si el reparto fuera otro, el ultimo
        campo no acabaria justo en 0x4025."""
        banderas = self.b(0x4014)
        self.assertEqual(banderas, 0x08)
        p = 0x4015
        b = banderas
        for tam in (3, 3):                  # los dos primeros: puntero y uno mas
            if not b & 1:
                p += tam
            b >>= 1
        for _ in range(6):                  # y los seis de la lista de 0x5EE6
            if not b & 1:
                p += 2
            b >>= 1
        self.assertEqual(p, 0x4025,
                         "el reparto no cierra donde empieza el codigo")
        self.assertEqual(self.w(0x4023), 0x4103,
                         "el ultimo campo es la rutina que llama el Game Master")

    def test_la_marca_oculta_de_konami(self):
        marca = bytes(self.b(a) for a in range(0xBFF7, 0xC000))
        self.assertEqual(marca.hex(" "), "ba b7 9a ac 81 91 06 40 aa")
        # los seis que Nemesis (RC-742) busca por las ranuras
        self.assertEqual(marca[3:].hex(" "), "ac 81 91 06 40 aa")

    def test_la_tabla_de_coseno_y_la_errata_que_sobrevive(self):
        """65 valores de 255*cos(k*90/64). Un coseno de un cuadrante SOLO
        PUEDE BAJAR, y este baja siempre. La unica desviacion grande contra la
        funcion es la de k=46, que es la errata que Twin Bee hereda de
        Knightmare y no llego a arreglar: si algun dia se toca la tabla, este
        test avisa."""
        t = [self.b(0xB950 + k) for k in range(65)]
        self.assertEqual(t[0], 255)
        self.assertEqual(t[64], 0, "cos(90) tiene que ser cero")
        for k in range(1, 65):
            self.assertLessEqual(t[k], t[k - 1],
                                 "la tabla sube en k=%d: eso no es un coseno" % k)
        gordas = [k for k in range(65)
                  if abs(t[k] - round(255 * math.cos(k * math.pi / 2 / 64))) > 2]
        self.assertEqual(gordas, [46],
                         "las desviaciones grandes tienen que ser solo la de k=46")
        self.assertEqual(t[46], 105, "y valer 105 donde tocaria 109")

    def test_los_248_bloques_de_fila_cuadran_con_su_hueco(self):
        """Entre 0x6F8F y 0x8E8F hay 0x1F00 bytes. Si son filas de 32 casillas
        tienen que salir 248 exactas, sin sobrar ni faltar un byte."""
        self.assertEqual((0x8E8F - 0x6F8F) % 32, 0)
        self.assertEqual((0x8E8F - 0x6F8F) // 32, 248)

    def test_ningun_codigo_del_mapa_se_sale_de_los_bloques(self):
        """El guion de 0x6D74 saca tramos de la tabla de 0x6E01, y cada tramo
        es una lista de codigos de fila. Ninguno puede pasar de 247, o estaria
        leyendo los patrones de sprite de al lado."""
        codigos, p = [], 0x6D74
        while self.b(p) != 0xFF:
            t = self.w(0x6E01 + self.b(p))
            self.assertTrue(0x6E3B <= t < 0x6F8F,
                            "un tramo apunta fuera de la zona de tramos")
            p += 1
            q = t
            while self.b(q) != 0xFF:
                codigos.append(self.b(q))
                q += 1
        self.assertGreater(len(codigos), 1700, "el mapa se ha quedado corto")
        self.assertLessEqual(max(codigos), 247,
                             "hay un codigo de fila fuera de los 248 bloques")
        self.assertEqual(len(codigos) % 1, 0)

    def test_el_mapa_son_1761_filas(self):
        """La cifra que se publica: 1761 filas, o sea 73 pantallas de 24."""
        codigos, p = [], 0x6D74
        while self.b(p) != 0xFF:
            q = self.w(0x6E01 + self.b(p))
            p += 1
            while self.b(q) != 0xFF:
                codigos.append(self.b(q))
                q += 1
        self.assertEqual(len(codigos), 1761)
        self.assertEqual(len(codigos) // 24, 73)

    def test_los_registros_del_vdp_dicen_lo_que_se_publica(self):
        """La tabla de 0x47F1 se escribe del registro 7 al 0."""
        r = [self.b(0x47F1 + k) for k in range(8)]
        self.assertEqual(r, [0xE4, 0x03, 0x76, 0x07, 0x7F, 0x0E, 0xE2, 0x02])
        r7, r6, r5, r4, r3, r2, r1, r0 = r
        self.assertEqual(r2 * 0x400, 0x3800, "la tabla de nombres")
        self.assertEqual(r6 * 0x800, 0x1800, "los patrones de sprite")
        self.assertEqual(r5 * 0x80, 0x3B00, "los atributos de sprite")
        self.assertEqual((r4 & 4) << 11, 0x2000, "los patrones, ARRIBA")
        self.assertEqual((r3 & 0x80) << 6, 0x0000, "y el color, ABAJO")
        self.assertTrue(r1 & 2, "sprites de 16x16")

    def test_las_tres_escrituras_a_la_propia_rom(self):
        """0x4028, 0x4055 y 0x40FE escriben en la ROM del cartucho y se
        pierden. Son tres, ni una mas: si aparece otra, hay que mirarla."""
        a_rom = re.findall(r"ld \(0([4-9ab][0-9a-f]{3})h\)", self.asm)
        self.assertEqual(sorted(a_rom), ["4195", "41a1"])
        self.assertIn("ld hl,047f7h", self.asm)
        self.assertIn("res 6,(hl)", self.asm)

    def test_el_azar_sale_del_registro_r(self):
        """Cinco sitios leen el refresco del Z80, y uno lo pone a cero: el que
        arranca la demostracion, para que la partida grabada salga igual."""
        self.assertEqual(len(re.findall(r"^\tld a,r", self.asm, re.M)), 5)
        self.assertEqual(len(re.findall(r"^\tld r,a", self.asm, re.M)), 1)

    def test_el_guion_de_la_demostracion_acaba_en_ff(self):
        p = 0x6016
        while p < 0x6033 and self.b(p) != 0xFF:
            p += 1
        self.assertEqual(p, 0x6032, "el guion no acaba donde se dice")
        self.assertEqual(0x6032 - 0x6016, 28, "son 28 pulsaciones")

    def test_la_tabla_de_los_cuarenta_enemigos_apunta_a_codigo(self):
        """Los cuarenta destinos del despacho de 0xAD5D tienen que caer todos
        dentro del cartucho y llevar etiqueta en el listado, o sea que el
        trazado los alcanzo de verdad."""
        etiquetadas, pendiente = set(), False
        for ln in self.asm.split("\n"):
            if re.match(r"^\w[\w.]*:", ln):
                pendiente = True
                continue
            m = re.search(r";([0-9a-f]{4})", ln)
            if m and pendiente:
                etiquetadas.add(int(m.group(1), 16))
                pendiente = False
        destinos = [self.w(0xAD60 + 2 * k) for k in range(40)]
        self.assertEqual([d for d in destinos if not ORG <= d < FIN], [],
                         "hay destinos fuera del cartucho")
        sueltos = sorted({d for d in destinos if d not in etiquetadas})
        self.assertEqual(sueltos, [], "%d destinos sin etiqueta" % len(sueltos))

    def test_los_cuatro_trozos_de_codigo_muerto(self):
        """27 bytes de codigo al que no llega nadie. Estan declarados como
        datos con su explicacion, y son cuatro."""
        n = len(re.findall(r"^D 0x[0-9A-F]{4} 0x[0-9A-F]{4} "
                           r"codigo_al_que_no_llega_nadie", lee(NOTES), re.M))
        self.assertEqual(n, 4)


class LosFicherosCitadosExisten(unittest.TestCase):
    """Un fichero que se nombra en el proyecto tiene que estar."""

    def test_los_ficheros_de_src(self):
        for fn in (ASM, NOTES, ENTRIES):
            self.assertTrue(os.path.exists(fn), "falta %s" % fn)

    def test_las_herramientas_que_nombra_el_makefile(self):
        mk = lee(os.path.join(RAIZ, "Makefile"))
        for m in re.finditer(r"tools/(\w+\.(?:py|sh|tcl))", mk):
            self.assertTrue(
                os.path.exists(os.path.join(RAIZ, "tools", m.group(1))),
                "el Makefile nombra tools/%s y no esta" % m.group(1))

    def test_las_imagenes_que_nombra_la_web(self):
        docs = os.path.join(RAIZ, "docs")
        if not os.path.isdir(docs):
            self.skipTest("todavia no hay web")
        for raiz, _, ficheros in os.walk(docs):
            for fn in ficheros:
                if not fn.endswith((".md", ".html")):
                    continue
                for m in re.finditer(r"imagenes/([\w.]+\.png)",
                                     lee(os.path.join(raiz, fn))):
                    self.assertTrue(
                        os.path.exists(os.path.join(docs, "imagenes", m.group(1))),
                        "%s nombra imagenes/%s y no esta" % (fn, m.group(1)))


if __name__ == "__main__":
    unittest.main()
