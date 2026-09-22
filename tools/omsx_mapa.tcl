# Vuelca lo que hace falta para COTEJAR EL MAPA, no los dibujos: la lista de
# codigos de fila que 0x460C deja en 0xE400, el indice por donde va el decorado
# (0xEBF0), el hito de la fase (0xEBB6), el contador de fase (0xEBB8) y la tabla
# de nombres de la VRAM, en varios instantes de la demostracion -que juega la
# primera fase sola-. Cada instante deja mapa_tNN.bin (RAM 0xE400..0xEBFF, 2 KB)
# y nombres_tNN.bin (VRAM 0x3800..0x3AFF), mas info_mapa_tNN.txt.
#
#   "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
#       -cart twinbee.rom -script tools/omsx_mapa.tcl
set renderer none
set throttle off
set carpeta "work/omsx"

proc vuelca {t} {
    global carpeta
    set f [open [file join $carpeta "mapa_t$t.bin"] w]
    fconfigure $f -translation binary
    puts -nonewline $f [debug read_block memory 0xE400 2048]
    close $f
    set f [open [file join $carpeta "nombres_t$t.bin"] w]
    fconfigure $f -translation binary
    puts -nonewline $f [debug read_block VRAM 0x3800 768]
    close $f
    set f [open [file join $carpeta "info_mapa_t$t.txt"] w]
    puts $f "tiempo [machine_info time]"
    puts $f "escena [debug read memory 0xE000] subescena [debug read memory 0xE001]"
    puts $f "fase_E076 [debug read memory 0xE076]"
    puts $f "EBF0 [expr {[debug read memory 0xEBF0] | ([debug read memory 0xEBF1] << 8)}]"
    puts $f "EBB6 [expr {[debug read memory 0xEBB6] | ([debug read memory 0xEBB7] << 8)}]"
    puts $f "EBB8 [debug read memory 0xEBB8]"
    close $f
}

foreach t {20 30 45 60 90} {
    after time $t [list vuelca $t]
}
after time 95 exit
