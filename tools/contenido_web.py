#!/usr/bin/env python3
"""El contenido propio de la portada de Twin Bee: hallazgos y galeria.

Vive aparte de make_web.py a proposito: asi el generador no lleva dentro ni un
texto del cartucho anterior, que es de donde salen casi todos los restos de
copia y pega de esta serie.

Cada hallazgo dice QUE se ha medido y CON QUE, y cada pie de imagen dice de
donde sale el dibujo. Ninguna cifra esta escrita a ojo.
"""

HALLAZGOS = {
    "es": [
        ("En la ROM solo esta media nave",
         "<p>De cada patron de sprite, el cartucho guarda <b>la mitad "
         "izquierda</b>: dieciseis bytes. La derecha la calcula "
         "<code>sube_patrones_de_sprite</code> (<code>0x4743</code>) "
         "invirtiendo cada byte bit a bit con los ocho <code>rr l / rla</code> "
         "de <code>0x4793</code>. Por eso <b>todo lo que vuela en Twin Bee es "
         "simetrico</b>: las dos naves, los disparos, las campanas y los "
         "enemigos. El mismo espejo se usa en el decorado, donde "
         "<code>sube_espejado</code> (<code>0x4695</code>) sube el bloque con "
         "el bit 0 de C puesto. Comprobado: los 2.048 bytes de la tabla de "
         "patrones de sprite salen <b>identicos</b> a los del emulador en las "
         "cinco fases.</p>"),
        ("La demostracion es una partida grabada, y por eso el azar es cero",
         "<p><code>arranca_la_demostracion</code> (<code>0x5FBF</code>) monta "
         "una partida de verdad -misma RAM, misma fase, mismo codigo- y le "
         "mete el mando por la <b>misma puerta</b> por la que entra el del "
         "jugador. Lo que se juega son los <b>28 valores</b> de "
         "<code>0x6016</code>, uno cada 32 cuadros, hasta el <code>0xFF</code> "
         "que corta la partida. Y para que la misma tira de pulsaciones de "
         "siempre la misma partida hace falta que el azar tambien sea el "
         "mismo: por eso <code>0x5FCF</code> pone <b>a cero el registro R</b> "
         "del Z80, que es de donde el juego saca sus numeros al azar en los "
         "cinco <code>ld a,r</code> de <code>0xAF75</code>, <code>0xB2CE</code>, "
         "<code>0xB757</code>, <code>0xBE0C</code> y <code>0xBE36</code>. Sin "
         "ese <code>ld r,a</code> la demostracion se descarrilaria sola.</p>"),
        ("La tabla de coseno es la de Knightmare, con dos erratas arregladas",
         "<p>Los 65 valores de <code>0xB950</code> son "
         "255&nbsp;&times;&nbsp;cos(k&nbsp;&times;&nbsp;90/64), y son <b>la "
         "misma tabla</b> que la de Knightmare (RC-739): de los 65 bytes solo "
         "se diferencian <b>tres</b>. Y esos tres son justo los que Konami "
         "arreglo. En Knightmare, k=58 vale 47 cuando la anterior vale 43 "
         "-o sea que la tabla <b>sube</b>, que es lo unico que un coseno de un "
         "cuadrante no puede hacer-; aqui vale 37, que es lo que toca. La que "
         "sobrevive es la de <b>k=46</b>: 105 donde tocaria 109, cuatro "
         "unidades de menos en un angulo de 64,7 grados. No rompe la "
         "monotonia, y por eso nadie la vio.</p>"),
        ("Un solo escenario de 1.761 filas para las cinco fases",
         "<p>Twin Bee no tiene cinco mapas: tiene <b>uno</b>. El guion de "
         "<code>0x6D74</code> encadena tramos de la tabla de "
         "<code>0x6E01</code>, y de ahi salen <b>1.761 codigos de fila</b>, o "
         "sea <b>73 pantallas</b> de 24. Cada codigo indexa uno de los "
         "<b>248 bloques de 32 casillas</b> de <code>0x6F8F</code>, que es una "
         "fila entera de la pantalla, y <code>0x6D17</code> lo copia con "
         "treinta y dos <code>ldi</code> seguidos. La cuenta cierra sola: "
         "entre <code>0x6F8F</code> y <code>0x8E8F</code> hay "
         "<code>0x1F00</code> bytes, que son 248 filas exactas, y el codigo "
         "mas alto que gastan los tramos es 0xF7&nbsp;=&nbsp;247. Lo que "
         "cambia de fase a fase no es el mapa: son los <b>dibujos</b> de las "
         "casillas.</p>"),
        ("La fase 3 no tiene color propio: se lo permutan",
         "<p><code>sube_el_color_comun</code> (<code>0x9F41</code>) mira la "
         "fase y, si es la tercera, sube el <b>mismo</b> bloque de color que "
         "las demas pero con el bit 7 del registro C puesto. Ese bit enciende "
         "la permuta de <code>0x47B5</code>, que cambia los nibbles uno a uno: "
         "el 12 pasa a 6, el 6 a 12 y el 5 a 9. Con eso, la misma hoja de "
         "casillas sale con otra paleta y el cartucho se ahorra un juego "
         "entero de color.</p>"),
        ("La VRAM como mesa de trabajo",
         "<p>El descompresor de este cartucho <b>solo sabe escribir en la "
         "VRAM</b>: saca los bytes por el puerto <code>0x98</code> y no tiene "
         "forma de dejarlos en la RAM. Asi que cuando hace falta una tabla "
         "comprimida en memoria -la de 81 valores que decide como se dan la "
         "mano las dos naves- el juego la descomprime en <code>0x3B80</code>, "
         "un hueco de la tabla de atributos de sprites que nadie usa, y la "
         "trae de vuelta a <code>0xEB00</code> con <b>LDIRMV</b> "
         "(<code>0x5E0F</code>). La memoria de video hace de banco de "
         "trabajo.</p>"),
        ("Los sprites se turnan para no desaparecer siempre los mismos",
         "<p>El TMS9918 pinta <b>cuatro sprites por linea</b> y descarta los "
         "de indice mas alto, asi que un juego con muchos enemigos parpadea "
         "siempre en los mismos. <code>sube_los_sprites</code> "
         "(<code>0x46CE</code>) deja los cuatro primeros fijos -las naves y "
         "sus disparos- y sube los <b>veintiocho</b> restantes en un orden que "
         "<b>rota</b>: <code>(0xE00F)</code> avanza 0x10 en cada cuadro y da la "
         "vuelta al llegar a 0x1E, y dentro del bucle el paso es 0x44. Ningun "
         "enemigo se queda sin pintar dos cuadros seguidos, y lo que se ve no "
         "es una desaparicion sino un parpadeo repartido.</p>"),
        ("Tres escrituras a la propia ROM que no llegan a ninguna parte",
         "<p><code>0x4028</code>, <code>0x4055</code> y <code>0x40FE</code> "
         "escriben en <code>0x4195</code>, <code>0x41A1</code> y "
         "<code>0x47F7</code>, que estan <b>dentro del propio cartucho</b>: el "
         "<code>ld</code> sale al bus y se pierde. De tener efecto, la primera "
         "dejaria un <code>pop hl / ret</code> donde hay un <code>djnz</code>, "
         "la segunda un <code>jp 0x0000</code> -o sea un reinicio- y la "
         "tercera apagaria la pantalla tocando el byte de R1 de la tabla de "
         "registros. Las dos primeras estan <b>iguales</b> en Knightmare "
         "(RC-739) y en The Goonies (RC-734), en las mismas posiciones "
         "relativas: vienen del armazon, no de este juego.</p>"),
        ("Veintisiete bytes de codigo al que no llega nadie",
         "<p>Cuatro trozos -<code>0x60CD</code>, <code>0xBB18</code>, "
         "<code>0xBB25</code> y <code>0xBB38</code>- son instrucciones validas "
         "y coherentes a las que <b>ningun salto entra</b>. En "
         "<code>0x60CD</code> se ve bien: el <code>jr z</code> de "
         "<code>0x60C9</code> cae en <code>0x60D2</code> y el <code>jr</code> "
         "de <code>0x60CB</code> en <code>0x60D6</code>, o sea justo por "
         "debajo y por encima. Hace lo mismo que <code>0x60DB</code>, que si "
         "se usa. Los otros tres son las variantes de 0x10 de codigo que si "
         "esta vivo. Se comprobo tambien que la palabra de esas direcciones no "
         "aparece en ninguna tabla del cartucho.</p>"),
        ("La campana no da lo que parece: da lo que toca por turno",
         "<p>El premio de una campana <b>no sale del color que se ve</b>. Sale "
         "de un contador de 32 pasos, <code>(0xE364)</code>, que avanza una "
         "posicion cada vez que se recoge una y entra en una tabla de 32 "
         "casillas que empieza en <code>0xEB88</code>. Esa tabla <b>no esta en "
         "la ROM</b>: la escribe a mano <code>empieza_la_partida</code> con "
         "cinco <code>ld</code> y cuatro <code>rlca</code> "
         "(<code>0x5D41</code>&ndash;<code>0x5D51</code>), o sea que solo "
         "<b>cinco</b> de las treinta y dos posiciones traen premio -1 "
         "potencia, 2 doble disparo, 4 el brazo, 8 el arma y 0x10 el escudo- y "
         "las otras veintisiete solo dan puntos. Leido en el emulador: en "
         "<code>0xEB88</code> hay <code>00 00 00 00 01 00 00 00 02 &hellip; 04 "
         "&hellip; 08</code>.</p>"),
        ("Noventa y nueve fases, cinco escenarios",
         "<p><code>(0xE07D)</code> es el numero de fase que se ve, en BCD, y "
         "sube de uno en uno hasta <b>99</b>. <code>(0xE076)</code> es el "
         "escenario, y cuando su nibble bajo llega a <b>seis</b> vuelve a "
         "<code>0x11</code>, o sea a la primera con el nibble alto a uno "
         "(<code>0x6169</code>). De ahi en adelante el juego da vueltas a los "
         "mismos cinco escenarios contando vueltas en el nibble alto. Llegar a "
         "la fase 99 es la <b>unica</b> manera de terminar Twin Bee: "
         "<code>0x618E</code> pone la marca de partida acabada.</p>"),
        ("La segunda cabecera, y la marca que Nemesis busca",
         "<p>En <code>0x4010</code> va la cabecera del <i>Konami Game "
         "Master</i>, el cartucho de trucos de la casa: <code>\"CD\" 07 40</code>, "
         "o sea RC-740. Los bytes que siguen se reparten con un byte de "
         "banderas y el reparto <b>cuadra</b>: acaba en <code>0x4025</code>, "
         "justo donde vuelve a haber codigo. Declara la escena, la fase y "
         "cuantas hay, las vidas, el record, la puntuacion, los bits de modo y "
         "una <b>rutina de este cartucho</b> (<code>0x4103</code>) que el Game "
         "Master llama entre ranuras. Y al final del todo, en "
         "<code>0xBFF7</code>, esta la marca oculta de Konami: "
         "<code>ba b7 9a ac 81 91 06 40 aa</code>, el titulo en katakana mas "
         "el RC-740. Sus <b>seis ultimos bytes</b> son exactamente los que "
         "Nemesis (RC-742) va buscando por las ranuras 0, 0x80, 0x84, 0x88 y "
         "0x8C para saber si Twin Bee esta enchufado al lado.</p>"),
    ],
    "en": [
        ("Only half a ship is in the ROM",
         "<p>For each sprite pattern the cartridge stores <b>the left "
         "half</b>: sixteen bytes. The right half is worked out by "
         "<code>sube_patrones_de_sprite</code> (<code>0x4743</code>), flipping "
         "every byte bit for bit with the eight <code>rr l / rla</code> at "
         "<code>0x4793</code>. That is why <b>everything that flies in Twin "
         "Bee is symmetric</b>: both ships, the shots, the bells and the "
         "enemies. The same mirror drives the scenery, where "
         "<code>sube_espejado</code> (<code>0x4695</code>) uploads the block "
         "with bit 0 of C set. Checked: all 2,048 bytes of the sprite pattern "
         "table come out <b>identical</b> to the emulator in all five "
         "stages.</p>"),
        ("The demo is a recorded game, and that is why the randomness is zero",
         "<p><code>arranca_la_demostracion</code> (<code>0x5FBF</code>) sets "
         "up a real game -same RAM, same stage, same code- and feeds the "
         "joystick in through the <b>very same door</b> the player's input "
         "uses. What gets played are the <b>28 values</b> at "
         "<code>0x6016</code>, one every 32 frames, until the <code>0xFF</code> "
         "that cuts the game short. And for the same string of button presses "
         "to give the same game every time, the randomness has to be the same "
         "too: that is why <code>0x5FCF</code> sets the Z80's <b>R register to "
         "zero</b>, which is where the game gets its random numbers from in "
         "the five <code>ld a,r</code> at <code>0xAF75</code>, "
         "<code>0xB2CE</code>, <code>0xB757</code>, <code>0xBE0C</code> and "
         "<code>0xBE36</code>. Without that <code>ld r,a</code> the demo would "
         "derail on its own.</p>"),
        ("The cosine table is Knightmare's, with two typos fixed",
         "<p>The 65 values at <code>0xB950</code> are "
         "255&nbsp;&times;&nbsp;cos(k&nbsp;&times;&nbsp;90/64), and they are "
         "<b>the same table</b> as Knightmare's (RC-739): out of 65 bytes only "
         "<b>three</b> differ. And those three are exactly the ones Konami "
         "fixed. In Knightmare k=58 holds 47 while the previous entry holds 43 "
         "-so the table <b>goes up</b>, the one thing a cosine quadrant cannot "
         "do-; here it holds 37, which is right. The one that survives is "
         "<b>k=46</b>: 105 where 109 belongs, four units short at an angle of "
         "64.7 degrees. It does not break monotonicity, and that is why nobody "
         "spotted it.</p>"),
        ("One single 1,761-row scenery for all five stages",
         "<p>Twin Bee does not have five maps: it has <b>one</b>. The script "
         "at <code>0x6D74</code> chains stretches from the table at "
         "<code>0x6E01</code>, and out come <b>1,761 row codes</b>, that is "
         "<b>73 screens</b> of 24. Each code indexes one of the <b>248 blocks "
         "of 32 tiles</b> at <code>0x6F8F</code>, which is one whole screen "
         "row, and <code>0x6D17</code> copies it with thirty-two consecutive "
         "<code>ldi</code>. The arithmetic closes by itself: between "
         "<code>0x6F8F</code> and <code>0x8E8F</code> there are "
         "<code>0x1F00</code> bytes, exactly 248 rows, and the highest code "
         "the stretches use is 0xF7&nbsp;=&nbsp;247. What changes from stage "
         "to stage is not the map: it is the tile <b>artwork</b>.</p>"),
        ("Stage 3 has no colour of its own: it gets it permuted",
         "<p><code>sube_el_color_comun</code> (<code>0x9F41</code>) looks at "
         "the stage and, if it is the third, uploads the <b>same</b> colour "
         "block as the others but with bit 7 of register C set. That bit turns "
         "on the permutation at <code>0x47B5</code>, which swaps nibbles one "
         "by one: 12 becomes 6, 6 becomes 12 and 5 becomes 9. With that, the "
         "same tile sheet comes out in another palette and the cartridge saves "
         "a whole colour set.</p>"),
        ("VRAM as a workbench",
         "<p>This cartridge's decompressor <b>can only write to VRAM</b>: it "
         "pushes bytes out through port <code>0x98</code> and has no way of "
         "leaving them in RAM. So when a compressed table is needed in memory "
         "-the 81 values that decide how the two ships join hands- the game "
         "decompresses it at <code>0x3B80</code>, an unused gap in the sprite "
         "attribute table, and brings it back to <code>0xEB00</code> with "
         "<b>LDIRMV</b> (<code>0x5E0F</code>). Video memory doubles as a "
         "workbench.</p>"),
        ("Sprites take turns so the same ones do not always vanish",
         "<p>The TMS9918 draws <b>four sprites per line</b> and drops the "
         "higher-numbered ones, so a game with many enemies always flickers on "
         "the same ones. <code>sube_los_sprites</code> (<code>0x46CE</code>) "
         "keeps the first four fixed -the ships and their shots- and uploads "
         "the remaining <b>twenty-eight</b> in an order that <b>rotates</b>: "
         "<code>(0xE00F)</code> advances by 0x10 every frame and wraps at "
         "0x1E, and inside the loop the step is 0x44. No enemy goes unpainted "
         "two frames running, and what you see is not a disappearance but a "
         "shared-out flicker.</p>"),
        ("Three writes to the cartridge's own ROM that go nowhere",
         "<p><code>0x4028</code>, <code>0x4055</code> and <code>0x40FE</code> "
         "write to <code>0x4195</code>, <code>0x41A1</code> and "
         "<code>0x47F7</code>, which sit <b>inside the cartridge itself</b>: "
         "the <code>ld</code> goes out on the bus and is lost. Had they any "
         "effect, the first would leave a <code>pop hl / ret</code> where a "
         "<code>djnz</code> is, the second a <code>jp 0x0000</code> -a reset- "
         "and the third would blank the screen by touching the R1 byte of the "
         "register table. The first two are <b>identical</b> in Knightmare "
         "(RC-739) and The Goonies (RC-734), at the same relative offsets: "
         "they come from the framework, not from this game.</p>"),
        ("Twenty-seven bytes of code nothing reaches",
         "<p>Four chunks -<code>0x60CD</code>, <code>0xBB18</code>, "
         "<code>0xBB25</code> and <code>0xBB38</code>- are valid, coherent "
         "instructions that <b>no jump enters</b>. At <code>0x60CD</code> it "
         "shows clearly: the <code>jr z</code> at <code>0x60C9</code> lands on "
         "<code>0x60D2</code> and the <code>jr</code> at <code>0x60CB</code> "
         "on <code>0x60D6</code>, that is just below and just above. It does "
         "the same as <code>0x60DB</code>, which is used. The other three are "
         "the 0x10 variants of code that is alive. It was also checked that "
         "the word of those addresses appears in no table of the "
         "cartridge.</p>"),
        ("The bell does not give what it looks like: it gives what is next in turn",
         "<p>A bell's prize <b>does not come from the colour you see</b>. It "
         "comes from a 32-step counter, <code>(0xE364)</code>, that advances "
         "one place each time a bell is collected and indexes a 32-slot table "
         "starting at <code>0xEB88</code>. That table is <b>not in the "
         "ROM</b>: <code>empieza_la_partida</code> writes it by hand with five "
         "<code>ld</code> and four <code>rlca</code> "
         "(<code>0x5D41</code>&ndash;<code>0x5D51</code>), so only <b>five</b> "
         "of the thirty-two slots carry a prize -1 power, 2 twin shot, 4 the "
         "arm, 8 the weapon and 0x10 the shield- and the other twenty-seven "
         "only give points. Read back in the emulator: at <code>0xEB88</code> "
         "there is <code>00 00 00 00 01 00 00 00 02 &hellip; 04 &hellip; "
         "08</code>.</p>"),
        ("Ninety-nine stages, five sceneries",
         "<p><code>(0xE07D)</code> is the stage number you see, in BCD, and it "
         "climbs one at a time up to <b>99</b>. <code>(0xE076)</code> is the "
         "scenery, and when its low nibble reaches <b>six</b> it goes back to "
         "<code>0x11</code>, that is the first one with the high nibble at one "
         "(<code>0x6169</code>). From there on the game cycles through the "
         "same five sceneries, counting laps in the high nibble. Reaching "
         "stage 99 is the <b>only</b> way to finish Twin Bee: "
         "<code>0x618E</code> sets the game-over flag.</p>"),
        ("The second header, and the mark Nemesis looks for",
         "<p>At <code>0x4010</code> sits the <i>Konami Game Master</i> header, "
         "the house cheat cartridge: <code>\"CD\" 07 40</code>, that is RC-740. "
         "The bytes that follow are laid out under a flags byte and the layout "
         "<b>adds up</b>: it ends at <code>0x4025</code>, exactly where code "
         "resumes. It declares the scene, the stage and how many there are, "
         "the lives, the high score, the score, the mode bits and a <b>routine "
         "of this cartridge</b> (<code>0x4103</code>) that the Game Master "
         "calls across slots. And right at the end, at <code>0xBFF7</code>, "
         "sits Konami's hidden mark: <code>ba b7 9a ac 81 91 06 40 aa</code>, "
         "the title in katakana plus the RC-740. Its <b>last six bytes</b> are "
         "exactly the ones Nemesis (RC-742) goes hunting for through slots 0, "
         "0x80, 0x84, 0x88 and 0x8C to know whether Twin Bee is plugged in "
         "next door.</p>"),
    ],
}

# (fichero, pie en castellano, pie en ingles)
# EL ESCENARIO va APARTE, en su propia seccion: son tiras de 2104 x 1768 y
# metidas en la rejilla de la galeria salen ilegibles. Aqui van a tamano real,
# una debajo de otra y en orden de fase.
FASES = [
    ("mapa_fase1.png",
     "<b>Fase 1.</b> El escenario entero, partido en ocho columnas: 1.761 "
     "filas, 73 pantallas. Se lee de arriba abajo y de izquierda a derecha. "
     "Islas verdes con acantilados rosas, campos, casas, un rio con puentes y "
     "una pista de aterrizaje; ninguna es una captura.",
     "<b>Stage 1.</b> The whole scenery, cut into eight columns: 1,761 rows, "
     "73 screens. Read it top to bottom, left to right. Green islands with "
     "pink cliffs, fields, houses, a river with bridges and a landing strip; "
     "not one of them is a capture."),
    ("mapa_fase2.png",
     "<b>Fase 2.</b> El mismo mapa con otras casillas: el bloque que sube "
     "<code>sube_los_patrones_de_la_fase</code> a la casilla 0xC0 es distinto, "
     "y de la 0x3C a la 0xBF son las mismas en las cinco.",
     "<b>Stage 2.</b> The same map with different tiles: the block "
     "<code>sube_los_patrones_de_la_fase</code> uploads at tile 0xC0 is "
     "another one, and tiles 0x3C to 0xBF are shared by all five."),
    ("mapa_fase3.png",
     "<b>Fase 3.</b> La que no tiene color propio: es el color de las demas "
     "pasado por la permuta de <code>0x47B5</code>.",
     "<b>Stage 3.</b> The one with no colour of its own: it is the other "
     "stages' colour run through the permutation at <code>0x47B5</code>."),
    ("mapa_fase4.png",
     "<b>Fase 4.</b> La de la hoja de casillas mas corta: su bloque propio "
     "acaba en la casilla 0xC5.",
     "<b>Stage 4.</b> The one with the shortest tile sheet: its own block "
     "ends at tile 0xC5."),
    ("mapa_fase5.png",
     "<b>Fase 5.</b> La mas cargada: llega hasta la casilla 0xEA, treinta y "
     "cinco mas que la 4.",
     "<b>Stage 5.</b> The busiest: it reaches tile 0xEA, thirty-five more "
     "than stage 4."),
]

GALERIA = [
    # EL ORDEN IMPORTA: primero las pantallas fijas, luego las hojas de
    # casillas y por ultimo los sprites. El escenario va aparte, en FASES.
    ("titulo.png",
     "La pantalla del titulo, montada ejecutando los pasos de "
     "<code>monta_el_titulo</code> (<code>0x4BD3</code>). El cotejo contra la "
     "VRAM del emulador da <b>cero</b> diferencias en los 16.384 bytes.",
     "The title screen, assembled by running the steps of "
     "<code>monta_el_titulo</code> (<code>0x4BD3</code>). Checked against the "
     "emulator's VRAM it comes out with <b>zero</b> differences over all "
     "16,384 bytes."),
    ("presentacion.png",
     "El cartel de KONAMI de la presentacion, en el sitio al que llega tras "
     "sus catorce pasos de <code>baja_un_paso</code> (<code>0x4B0A</code>).",
     "The KONAMI banner of the intro, at the place it reaches after the "
     "fourteen steps of <code>baja_un_paso</code> (<code>0x4B0A</code>)."),
    ("pantalla_fase1.png",
     "La primera pantalla del escenario: las 24 filas que "
     "<code>monta_las_veinticuatro_filas</code> copia al buffer, empezando por "
     "la fila 23 del mapa y bajando.",
     "The first screen of the scenery: the 24 rows "
     "<code>monta_las_veinticuatro_filas</code> copies into the buffer, "
     "starting at map row 23 and going down."),
    ("logotipo.png",
     "El rotulo <i>TwinBee</i>, que son <b>27 casillas</b> comprimidas en "
     "<code>0x4B3C</code> y escritas en tres filas de once desde la casilla "
     "0xC0 (<code>0x4BF9</code>).",
     "The <i>TwinBee</i> logo: <b>27 tiles</b> compressed at "
     "<code>0x4B3C</code> and written in three rows of eleven from tile 0xC0 "
     "(<code>0x4BF9</code>)."),
    ("fuente.png",
     "La fuente entera. No es un alfabeto completo: hay 0 a 9, el simbolo de "
     "copyright, un punto, una admiracion y solo las letras "
     "<b>A B C D E F G H I K L M N O P R S T U V W Y</b>, que son las que "
     "hacen falta para los rotulos de este cartucho.",
     "The whole font. It is not a complete alphabet: there are 0 to 9, the "
     "copyright sign, a full stop, an exclamation mark and only the letters "
     "<b>A B C D E F G H I K L M N O P R S T U V W Y</b>, which are the ones "
     "this cartridge's captions need."),
    ("casillas_fase1.png",
     "La hoja de casillas del decorado de la fase 1, de la 0x3C a la 0xD1. "
     "Cotejada contra la VRAM del emulador: <b>cero</b> diferencias en las 150 "
     "casillas, patron y color, en los tres bancos.",
     "The scenery tile sheet for stage 1, tiles 0x3C to 0xD1. Checked against "
     "the emulator's VRAM: <b>zero</b> differences across all 150 tiles, "
     "pattern and colour, in all three banks."),
    ("casillas_fase3.png",
     "La misma hoja de la fase 3. Los patrones son los mismos que arriba; lo "
     "unico que cambia es el color, permutado nibble a nibble.",
     "The same sheet for stage 3. The patterns are the ones above; the only "
     "thing that changes is the colour, permuted nibble by nibble."),
    ("naves.png",
     "Los sprites que no dependen de la fase, los 176 patrones de "
     "<code>0x1800</code> a <code>0x1D80</code>: las dos naves, el brazo que "
     "se estira, los disparos, las bombas, las campanas, las nubes, los "
     "avisos de puntos y el GAME OVER. Todos salen de media plantilla, con la "
     "mitad derecha calculada por el espejo de <code>0x4743</code>.",
     "The sprites that do not depend on the stage, the 176 patterns from "
     "<code>0x1800</code> to <code>0x1D80</code>: both ships, the arm that "
     "stretches out, the shots, the bombs, the bells, the clouds, the score "
     "pop-ups and the GAME OVER. Every one comes from half a template, with "
     "the right half worked out by the mirror at <code>0x4743</code>."),
    ("enemigos_fase1.png",
     "Los enemigos de la fase 1, subidos por <code>0x9177</code> a partir del "
     "patron <code>0xB0</code> desde el bloque que le toca de la tabla de "
     "<code>0x9191</code>.",
     "Stage 1's enemies, uploaded by <code>0x9177</code> from pattern "
     "<code>0xB0</code> on, out of the block the table at <code>0x9191</code> "
     "hands it."),
    ("enemigos_fase5.png",
     "Y los de la fase 5. Cada fase trae los suyos, y el primer byte de su "
     "bloque dice cuantas parejas de 16 bytes vienen detras.",
     "And stage 5's. Each stage brings its own, and the first byte of its "
     "block says how many 16-byte halves follow."),
    ("jefe_fase1.png",
     "El jefe de la fase 1, en el MISMO sitio: sus patrones <b>pisan</b> a los "
     "de los enemigos en <code>0x1D80</code>, porque cuando aparece ya no "
     "hacen falta.",
     "Stage 1's boss, in the SAME place: its patterns <b>overwrite</b> the "
     "enemies at <code>0x1D80</code>, because by the time it shows up they "
     "are no longer needed."),
]
