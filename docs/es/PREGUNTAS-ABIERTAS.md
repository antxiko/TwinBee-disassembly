# Preguntas abiertas

Lo que **no** se sabe. Aqui no hay nada disfrazado de respuesta.

## Los cuarenta comportamientos van por numero, no por lo que hacen

La tabla de `0xAD60` reparte cuarenta comportamientos de enemigo, y cada uno es
una rutina propia. Estan todos trazados, todos comentados y todos alcanzables
-pero se llaman `comportamiento_0` a `comportamiento_39`, que es lo unico que
se puede afirmar sin jugarse cada uno. Leer el codigo dice *como* se mueve uno;
no dice *cual* de los que salen en pantalla es. Atar cada numero a lo que se ve
pediria una partida por comportamiento, con un punto de interrupcion en el.

Cinco de los cuarenta hacen doble papel como disparos del jefe, que la tabla de
`0xAE9E` vuelve a nombrar: los indices 6, 7, 8, 9 y 10.

## Que son las melodias

Las 57 melodias de `0x511A` estan decodificadas -el lenguaje que recorre el
interprete de `0x4F06` esta documentado- pero ninguna se ha escuchado y atado a
un momento del juego. Cual es la del titulo, cual la de la fase y cual la que
suena al coger una campana no esta escrito aqui.

## Las tres tablas por fase

`monta_la_fase_para_el_game_master` (`0x4103`) llena cuatro variables con
cuatro tablas: `0x4153`, `0x6132`, `0x61D5` y `0x6210`. La primera es la altura
a la que aparece el jefe, y las otras tres son hitos contra los que el decorado
se compara segun avanza: `prepara_el_marcador` (`0x610E`) saca el jefe cuando
el mapa llega a `(0xEBB6)`, `mira_si_toca_nube` (`0x619D`) saca una nube en
`(0xEBB0)` y `mira_si_toca_musica` (`0x61E9`) cambia la melodia en `(0xEBB3)`.
Lo que no esta claro es por que la tabla del jefe tiene **cuatro** entradas
para cinco fases, cuando las otras tres tienen cinco.

## La clase 0x21

`la_tanda_del_final` (`0xBD2B`) impone la clase `0x21` y los saca de uno en
uno, dieciseis rondas, y `recarga_la_espera` (`0xAEFC`) le da a esa misma clase
un caso especial: no le recarga la cuenta de disparo. Tiene pinta de ser la
oleada que cierra una fase, pero eso no se ha visto pasar.

## Si algo mas busca a Twin Bee ademas de Nemesis

Nemesis (RC-742) busca los seis bytes de la marca de este cartucho por las
ranuras. Si Twin Bee busca a alguien a su vez esta comprobado, y la respuesta
es **no**: en su codigo no hay ni un `RDSLT`, ni un `CALSLT`, ni un recorrido
de ranuras mas alla del ENASLT de INIT. Si algun *otro* cartucho de Konami
busca a Twin Bee es una pregunta para esos cartuchos, no para este.

## El byte de truco de 0xF0FF

`0x44EC` escribe en `0xF0FF` un valor sacado de los bits de servicio de la
segunda lectura de mando, y tres sitios lo leen: `0x5D73` da potencia de
salida, `0x5D7A` da campanas ya cargadas y `0xA3F7` dobla los usos del arma.
Que combinacion de teclas produce cada valor no esta averiguado: el byte sale
de `(0xE063)`, que es la lectura entera de la fila 5 del teclado, y atar eso a
teclas de verdad pediria una partida con un punto de interrupcion y una mano en
el teclado.
