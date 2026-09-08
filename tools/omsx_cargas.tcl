# Apunta TODAS las cargas de VRAM que hace el cartucho, en orden.
#
# Para que sirve: la VRAM de una pantalla no es solo lo que esa pantalla sube;
# es lo que sube MAS lo que quedo de la anterior. Sin saber la cadena, un
# cotejo byte a byte falla en las casillas que nadie repinta y uno se pone a
# buscar una carga que no existe. Aqui se pone un punto de interrupcion en cada
# puerta del descompresor y se apunta con que registros entra:
#
#   0x4695  tres bancos CON espejo (C=1)      0x4699  tres bancos sin espejo
#   0x469B  tres bancos con el C que traiga   0x4711  bloque con destino dentro
#   0x4716  bloque con destino en HL          0x4743  patrones de sprite
#   0x46AD  guion de texto
#
# La salida es una linea por carga con la rutina, DE, HL, BC y el estado del
# juego, que es lo que hace falta para reproducirla en Python.

set renderer none
set throttle off

set f [open "work/omsx/cargas.txt" w]

proc apunta {nombre} {
    global f
    puts $f [format "%s de=%04X hl=%04X bc=%04X c=%02X escena=%02X sub=%02X fase=%02X t=%.2f" \
        $nombre [reg DE] [reg HL] [reg BC] [expr {[reg BC] & 0xFF}] \
        [debug read memory 0xE000] [debug read memory 0xE001] \
        [debug read memory 0xE076] [machine_info time]]
    flush $f
}

foreach {dir nombre} {0x4695 esp3 0x4699 lit3 0x469B tres 0x4711 bloque
                      0x4716 crudo 0x4743 sprites 0x46AD texto} {
    debug set_bp $dir {} "apunta $nombre"
}

after time 40 {close $f; exit}
