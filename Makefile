# Twin Bee (Konami, MSX1) - desensamblado
#
# El orden de las cosas: trazar el flujo -> generar el listado -> comprobar que
# vuelve a dar la ROM byte a byte -> las comprobaciones que el reensamblado NO
# cubre.
#
# El cartucho no se distribuye: hace falta en la raiz como twinbee.rom, y
# `make comprueba` verifica su sha256.

ROM      = twinbee.rom
SHA      = 02bdce8ceafe6af05a45b61a689e78807551df663afd152090f7cd9cac827dd4
SRC      = src
WORK     = work
ORG      = 0x4000
TITULO   = TWIN BEE - Konami - MSX1 - cartucho RC-740 de 32 KB en las paginas 1 y 2

all: listado verify sanity test

$(ROM):
	@echo "=================================================================="
	@echo " Falta $(ROM), y este repositorio NO lo distribuye."
	@echo ""
	@echo " Es Twin Bee (Konami, RC-740) para MSX, 32768 bytes exactos."
	@echo " Ponlo aqui con ese nombre. Para comprobar que es el mismo:"
	@echo "     shasum -a 256 $(ROM)"
	@echo "     $(SHA)"
	@echo "=================================================================="
	@false

comprueba: $(ROM)
	@echo "$(SHA)  $(ROM)" | shasum -a 256 -c -

# El trazado sigue el flujo desde los puntos de entrada. Los que no se pueden
# deducir estaticamente -ganchos de interrupcion, destinos de saltos
# indirectos- estan declarados en el .entries, cada uno con su justificacion.
$(WORK)/twinbee.trace.json: $(ROM) $(SRC)/twinbee.entries $(SRC)/twinbee.nocode
	@mkdir -p $(WORK)
	python3 tools/z80trace.py $(ROM) $(ORG) $(SRC)/twinbee.entries \
	        $(WORK)/twinbee $(SRC)/twinbee.nocode

trace: $(WORK)/twinbee.trace.json

listado: $(WORK)/twinbee.trace.json $(SRC)/twinbee.notes
	python3 tools/mkasm.py $(ROM) $(ORG) $(WORK)/twinbee.trace.json \
	        $(SRC)/twinbee.notes work/msx.sym $(SRC)/twinbee.asm "$(TITULO)"

# La prueba que decide si el desensamblado es fiable.
verify: $(SRC)/twinbee.asm $(ROM)
	@sh tools/verify_build.sh $(SRC)/twinbee.asm $(ROM) $(ORG)

# Lo que el reensamblado NO puede cazar: que unos datos se esten leyendo como
# codigo. El binario sale identico igual, porque los bytes no cambian; lo unico
# que cambia es lo que decimos de ellos.
sanity: $(WORK)/twinbee.trace.json
	@echo "=================================================================="
	@echo " ningun byte declarado como datos puede salir como codigo"
	@echo "=================================================================="
	@python3 tools/check_trace.py $(WORK)/twinbee.trace.json $(SRC)/twinbee.nocode
	@python3 tools/check_datos_como_codigo.py $(WORK) $(SRC)
	@echo "=================================================================="
	@echo " ningun punto de entrada puede caer dentro de una zona de datos"
	@echo "=================================================================="
	@python3 tools/check_entradas.py $(SRC)/twinbee.entries $(SRC)/twinbee.notes \
	        $(SRC)/twinbee.nocode
	@echo "=================================================================="
	@echo " ni un byte del cartucho sin asignar"
	@echo "=================================================================="
	@python3 tools/presupuesto.py $(WORK) $(SRC)

densidad:
	@python3 tools/densidad.py $(SRC)/twinbee.asm

test:
	@echo "=================================================================="
	@echo " Tests"
	@echo "=================================================================="
	@python3 -W ignore -m unittest discover -s tests -v

# Las imagenes, montadas ejecutando en Python los pasos del cartucho. No hay ni
# una captura de pantalla en este repositorio.
imagenes: $(ROM)
	@mkdir -p work/gfx
	python3 tools/pantallas.py $(ROM) $(ORG) work/gfx
	python3 tools/sprites.py $(ROM) $(ORG) work/gfx
	python3 tools/mapas.py $(ROM) $(ORG) work/gfx

# Y la comprobacion de que esas imagenes son las de verdad: se deja correr el
# cartucho en openMSX, se vuelca su VRAM y se compara BYTE A BYTE. Mirar el
# dibujo no basta.
OPENMSX = C:/Program Files/openMSX/openmsx.exe
vram: $(ROM)
	@rm -rf work/omsx && mkdir -p work/omsx
	@for f in 1 2 3 4 5; do 	  TWINBEE_FASE=$$f "$(OPENMSX)" -machine Philips_VG_8020 -cart $(ROM) 	      -script tools/omsx_vram.tcl >/dev/null 2>&1; 	done
	@python3 tools/coteja_vram.py $(ROM) $(ORG) work/omsx

# Y la sonda que apunta, en orden, TODAS las cargas de VRAM del cartucho: de
# ahi sale la cadena de herencia que respetan tools/pantallas.py y mapas.py.
cargas: $(ROM)
	@mkdir -p work/omsx
	"$(OPENMSX)" -machine Philips_VG_8020 -cart $(ROM) -script tools/omsx_cargas.tcl
	@cat work/omsx/cargas.txt

# LA WEB
#
# Bilingue: el ingles en docs/ y el castellano en docs/es/. Las paginas se
# escriben en markdown y se convierten con md2html.py; la portada la monta
# make_web.py, que declara las cifras medidas de ESTE cartucho.
#
# Las imagenes se REHACEN aqui, no se copian a mano: si una herramienta de
# dibujo se queda fuera de este target, la lamina se queda vieja sin que nadie
# proteste.
web: $(ROM)
	@mkdir -p docs/imagenes
	python3 tools/pantallas.py $(ROM) $(ORG) docs/imagenes
	python3 tools/sprites.py $(ROM) $(ORG) docs/imagenes
	python3 tools/mapas.py $(ROM) $(ORG) docs/imagenes
	python3 tools/md2html.py docs en
	python3 tools/md2html.py docs/es es
	python3 tools/make_web.py docs/imagenes docs/index.html en
	python3 tools/make_web.py docs/imagenes docs/es/index.html es
	python3 tools/check_enlaces.py docs

clean:
	rm -rf $(WORK)/twinbee.trace.json $(WORK)/twinbee.blocks

.PHONY: all comprueba trace listado verify sanity test densidad imagenes vram cargas web clean
