# Vuelca la VRAM de Twin Bee en el instante que importa: con los patrones y el
# color de una fase recien subidos.
#
# UNA fase por arranque, la que diga la variable de entorno TWINBEE_FASE (1 a
# 5). El motivo es que la carga del decorado -0x5FE3, que encadena `call
# 0x994A` y `call 0x9F2F`- se ejecuta UNA sola vez por partida, al empezar, y
# la demostracion que el cartucho corre solo no pasa de la primera fase. Asi
# que se impone la fase en (0xE076) en un punto de interrupcion en 0x994A,
# justo antes de que esa rutina la lea, y se arranca cinco veces.
#
# El volcado va EN 0x5FEC, la instruccion de despues del `call 0x9177`: con la
# hoja de casillas Y los patrones de sprite de la fase subidos, y sin que el
# juego haya animado todavia ni una casilla. Medio segundo mas tarde ya no
# valdria -el agua y los brillos se repintan solos- y ese fue justo el ruido
# de la primera medida; y un `call` antes, en 0x5FE9, los sprites de los
# enemigos todavia no estan.
#
# De cada arranque salen dos ficheros: vram_faseN.bin con los 16 KB tal cual e
# info_faseN.txt con el estado, para poder decir CONTRA QUE se compara.
#
# Trampas de Tcl ya pagadas en esta serie y respetadas aqui: nada de corchetes
# dentro de un `format`, el binario con -translation binary, y `debug
# read_block` en vez de `debug save_to_file`, que no existe.

set renderer none
set throttle off

set carpeta "work/omsx"
set fase 1
if {[info exists ::env(TWINBEE_FASE)]} { set fase $::env(TWINBEE_FASE) }
set hecho 0

proc vuelca {nombre} {
    global carpeta
    set d [debug read_block VRAM 0 16384]
    set f [open [file join $carpeta "vram_$nombre.bin"] w]
    fconfigure $f -translation binary
    puts -nonewline $f $d
    close $f

    set f [open [file join $carpeta "info_$nombre.txt"] w]
    puts $f "tiempo [machine_info time]"
    puts $f "escena [debug read memory 0xE000]"
    puts $f "subescena [debug read memory 0xE001]"
    puts $f "fase [debug read memory 0xE076]"
    close $f
}

# La pantalla del titulo, por tiempo: va antes que nada y no depende de la fase.
after time 12 {vuelca "titulo"}

debug set_bp 0x994A {} {
    global fase
    debug write memory 0xE076 $fase
}

debug set_bp 0x5FEC {} {
    global fase hecho
    if {$hecho == 0} {
        set hecho 1
        vuelca "fase$fase"
        after time 1 exit
    }
}

after time 240 exit
