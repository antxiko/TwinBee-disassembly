; ==========================================================================
; TWIN BEE - Konami - MSX1 - cartucho RC-740 de 32 KB en las paginas 1 y 2
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; Direcciones que solo aparecen como VALOR -en un `ld`, no en
; un salto-: son punteros que el codigo se pasa o numeros que
; casualmente coinciden con una direccion. No hay nada que
; trazar en ellas; el equ existe para que el listado ensamble.
; ----------------------------------------------------------------------
lb4b8h:	equ 0x0b4b8

; ----------------------------------------------------------------------
; DATOS cabecera_del_cartucho: "AB" y la direccion de INIT (0x40B1).
;   STATEMENT, DEVICE y TEXT a cero, y los seis bytes reservados tambien
;   0x4000..0x4010  (16 bytes)
DATA_cabecera_del_cartucho:
	defw 04241h,040b1h,00000h,00000h,00000h,00000h,00000h,00000h	; 4000

; ----------------------------------------------------------------------
; DATOS cabecera_del_game_master: "CD" 07 40: el 0x07 de los RC-7xx y el 0x40
;   de RC-740. El "CD" es el marcador de los cartuchos de 1986-87, frente al
;   "AB" de los de 1985
;   0x4010..0x4014  (4 bytes)
DATA_cabecera_del_game_master:
	defb 043h,044h,007h,040h	; 4010

; ----------------------------------------------------------------------
; DATOS banderas_del_game_master: 0x08: vienen los ocho campos menos el del
;   bit 3, que es el puntero al bloque de datos que el Game Master sabe
;   guardar y cargar en disco (0xD30C alli). Twin Bee no declara ninguno
;   0x4014..0x4015  (1 bytes)
DATA_banderas_del_game_master:
	defb 008h	; 4014

; ----------------------------------------------------------------------
; DATOS punteros_del_game_master: Los siete campos que declara el cartucho, en
;   el orden en que los lee 0x5E92 del Game Master: 0xE000 y 0x04 (la variable
;   de escena y la escena en la que hay que aplicar los trucos), 0xE076 y 0x05
;   (la variable de fase y CUANTAS hay: cinco), 0xE070 (las vidas), 0xE06C (el
;   record), 0xE068 (la puntuacion), 0xE002 (los bits de modo) y 0x4103, que
;   es una RUTINA de este cartucho que el Game Master llama entre ranuras para
;   dejar montada la fase que se le pida
;   0x4015..0x4025  (16 bytes)
DATA_punteros_del_game_master:
	defw 0e000h,07604h	; 4015
	defb 0e0h	; 4019
	defw 07005h,06ce0h	; 401a
	defb 0e0h	; 401e
	defw 0e068h,0e002h,04103h	; 401f  -> 0xe068 0xe002 monta_la_fase_para_el_game_master

; ======================================================================
; CODIGO 0x4025..0x4153  (302 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL PARCHE QUE NO PARCHEA. Las escrituras de 0x4028, 0x4055 y 0x40FE apuntan a 0x4195, 0x41A1 y 0x47F7, que estan en la propia ROM del cartucho: el `ld` sale al bus y se pierde. De tener efecto, la primera dejaria un `pop hl / ret` donde hay un `djnz`, la segunda un `jp 00000h` -o sea un reinicio- y la tercera apagaria la pantalla tocando el byte de R1 de la tabla de registros. Las dos primeras estan IGUAL en Knightmare (RC-739) y en The Goonies (RC-734), en las mismas posiciones relativas, asi que vienen del armazon y no de este juego.
; ----------------------------------------------------------------------
arranca_la_pantalla_del_titulo:		; Parchea 0x4195 -que esta en ROM, asi que el `ld` no llega a ninguna parte- y se va a montar el cartel
	ld hl,0c9e1h		;4025   ; 0xC9E1 seria `pop hl / ret`
	ld (04195h),hl		;4028   ; pero 0x4195 es ROM: no llega
	jp monta_el_cartel		;402b   ; y a montar el cartel de la presentacion
cada_cuadro:		; El gancho de H.KEYI: el juego ENTERO cuelga de aqui
	call 0013eh		;402e   ; BIOS RDVDP - Reads VDP status register | limpia la peticion de interrupcion del VDP
	di			;4031
	call el_reproductor		;4032   ; el sonido, lo primero de todo
	ld hl,0e005h		;4035   ; el cerrojo: si ya hay un cuadro dentro, no se entra otra vez
	bit 0,(hl)		;4038
	jr nz,remata_la_interrupcion		;403a
	inc (hl)			;403c   ; se echa
	ei			;403d   ; y a partir de aqui se admiten interrupciones anidadas
	call lo_de_cada_cuadro		;403e   ; el mando, el marcador y lo que va suelto
	call reparte_la_escena		;4041   ; y la escena que toque
	xor a			;4044
	ld (0e005h),a		;4045   ; cerrojo abierto
remata_la_interrupcion:
	call 0013eh		;4048   ; BIOS RDVDP - Reads VDP status register | si mientras tanto ha entrado otro cuadro
	or a			;404b
	di			;404c
	call m,el_reproductor		;404d   ; se le da otra pasada al sonido
	ei			;4050
	ret			;4051
pon_registro_del_vdp:		; B el valor, C el numero de registro
	ld hl,00000h		;4052   ; 0x41A1 es ROM: este `ld` tampoco llega
	ld (041a1h),hl		;4055
	jp 00047h		;4058   ; BIOS WRTVDP - Writes data in the VDP-register | lo que si hace es escribir el registro: B el valor, C el numero
palabra_de_tabla_de_cuatro:		; Un `add a,a` suelto delante de la rutina de al lado: con el, las entradas de la tabla son de CUATRO bytes en vez de dos
	add a,a			;405b   ; se dobla A antes de que la de abajo lo vuelva a doblar
palabra_de_tabla:		; Devuelve en DE la palabra numero A de la tabla HL
	call indexa_palabras		;405c   ; HL += 2A
	ld e,(hl)			;405f   ; la palabra que sale, en DE
	inc hl			;4060
	ld d,(hl)			;4061
	ret			;4062
es_el_segundo_jugador:		; El bit 5 de (0xE002); vuelve con Z si NO lo es
	ld a,(0e002h)		;4063   ; el bit 5 de los bits de modo
	bit 5,a		;4066
	ret			;4068
indexa_palabras:		; HL += 2A
	add a,a			;4069   ; dobla A: entradas de dos bytes
suma_a_a_hl:		; HL += A, con el acarreo al alto
	add a,l			;406a   ; el acarreo, al alto
	ld l,a			;406b
	ret nc			;406c
	inc h			;406d
	ret			;406e
suma_a_a_de:		; DE += A, igual
	add a,e			;406f
	ld e,a			;4070
	ret nc			;4071
	inc d			;4072
	ret			;4073
el_uno_tiene_bomba:		; El bit 0 de (0xE078) o la bomba de (0xE087): vuelve con Z si el primer jugador puede hacer algo
	ld hl,0e087h		;4074
	ld a,(0e078h)		;4077
	and 001h		;407a
	or (hl)			;407c
	ret			;407d
el_dos_tiene_bomba:		; Lo mismo con el bit 1 y (0xE088)
	ld hl,0e088h		;407e
	ld a,(0e078h)		;4081
	and 002h		;4084
	or (hl)			;4086
	ret			;4087
donde_esta_la_nave_uno:		; Devuelve en HL la vertical y la horizontal enteras de la nave 1
	ld a,(0e0a1h)		;4088
	ld l,a			;408b
	ld a,(0e0a3h)		;408c
	ld h,a			;408f
	ret			;4090
donde_esta_la_nave_dos:		; Y las de la nave 2
	ld a,(0e0adh)		;4091
	ld l,a			;4094
	ld a,(0e0afh)		;4095
	ld h,a			;4098
	ret			;4099
cuantas_bombas:		; Dos con dos jugadores, una con uno
	call es_el_segundo_jugador		;409a
	ld b,002h		;409d
	ret nz			;409f
	dec b			;40a0
	ret			;40a1
cuantos_disparos:		; Seis con dos jugadores, dos con uno
	call es_el_segundo_jugador		;40a2
	ld b,006h		;40a5
	ret z			;40a7
	ld b,002h		;40a8
	ret			;40aa
reparte_por_tabla:		; El `pop hl` recoge la tabla: es la direccion de retorno, o sea los bytes que van justo detras del `call`
	pop hl			;40ab   ; la direccion de retorno ES la tabla
	call palabra_de_tabla		;40ac   ; la entrada numero A
	ex de,hl			;40af   ; y se salta ahi, con lo cual el `ret` de esa rutina vuelve a quien llamo
	jp (hl)			;40b0
INIT:		; Lo que ejecuta la BIOS al encontrar la "AB" de 0x4000
	di			;40b1   ; lo primero, saber en que ranura esta este cartucho
	call 00138h		;40b2   ; BIOS RSLREG - Reads the primary slot register
	rrca			;40b5   ; los dos bits de la pagina 1
	rrca			;40b6
	and 003h		;40b7
	ld c,a			;40b9
	ld hl,0fcc1h		;40ba   ; la tabla de subranuras de la BIOS
	add a,l			;40bd
	ld l,a			;40be
	ld a,(hl)			;40bf
	and 080h		;40c0   ; el bit de "hay subranuras"
	or c			;40c2
	ld c,a			;40c3
	inc l			;40c4   ; cuatro adelante: la pagina 2 de la misma tabla
	inc l			;40c5
	inc l			;40c6
	inc l			;40c7
	ld a,(hl)			;40c8
	and 00ch		;40c9
	or c			;40cb
	ld h,080h		;40cc   ; la pagina 2, que es donde va la mitad de arriba del cartucho
	call 00024h		;40ce   ; BIOS ENASLT - Switches to specified slot and page definitively | y se conecta de verdad
	ld a,0c3h		;40d1   ; el `jp` del gancho de interrupcion
	ld (0fd9ah),a		;40d3
	ld hl,cada_cuadro		;40d6   ; que apunta aqui dentro
	ld (0fd9bh),hl		;40d9
	ld hl,0e000h		;40dc   ; la RAM del juego, de 0xE000 a 0xF100
	ld de,0e001h		;40df
	ld bc,010ffh		;40e2
	xor a			;40e5   ; a cero
	ld (hl),a			;40e6
	ldir		;40e7
	ld sp,hl			;40e9   ; y la pila, arriba del todo de ella
	inc a			;40ea
	ld (0e005h),a		;40eb   ; el cerrojo, echado
	call prepara_la_maquina		;40ee   ; se prepara la maquina
	xor a			;40f1
	ld (0e005h),a		;40f2
	call 0013eh		;40f5   ; BIOS RDVDP - Reads VDP status register | se limpia la peticion del VDP
	ei			;40f8   ; y se abre la puerta
el_bucle_vacio:		; INIT acaba aqui: a partir de este `jr $` todo pasa en la interrupcion
	jr el_bucle_vacio		;40f9   ; el bucle vacio: a partir de aqui todo pasa en la interrupcion
apaga_la_pantalla:		; O eso pretende: 0x47F7 es ROM, asi que el `res 6` no llega. Lo unico que hace de verdad es callar el sonido
	ld hl,047f7h		;40fb   ; 0x47F7 es el byte de R1 de la tabla de registros... y tambien es ROM
	res 6,(hl)		;40fe   ; asi que la pantalla no se apaga
	jp pide_un_sonido		;4100
monta_la_fase_para_el_game_master:		; El ultimo campo de la cabecera de 0x4010, y la unica rutina de este cartucho que el Game Master llama entre ranuras
	ld a,(0e076h)		;4103   ; la fase que le hayan escrito, 1 a 5
	and a			;4106
	jr nz,L_410D		;4107
	inc a			;4109   ; con la fase a cero se entiende que es la 1
	ld (0e076h),a		;410a
L_410D:
	ld (0e07dh),a		;410d   ; la fase, tambien aparte
	dec a			;4110   ; con la fase 0 no hay nada que montar
	ret z			;4111
	ld c,a			;4112
	ld hl,06132h		;4113   ; la tabla de donde empieza cada fase
	ld (0ebb8h),a		;4116   ; la fase, para el resto del juego
	dec a			;4119
	call palabra_de_tabla		;411a   ; la palabra numero fase-1
	ld (0ebf0h),de		;411d   ; por donde va el decorado
	inc hl			;4121   ; y la de al lado: el tope
	ld e,(hl)			;4122
	inc hl			;4123
	ld d,(hl)			;4124
	ld (0ebb6h),de		;4125
	ld hl,061d5h		;4129   ; la segunda tabla por fase
	ld a,c			;412c
	add a,a			;412d   ; doblada, que es como la quiere 0xEBB2
	ld (0ebb2h),a		;412e
	call palabra_de_tabla		;4131   ; y su palabra
	ld (0ebb0h),de		;4134
	ld hl,06210h		;4138   ; y la tercera
	ld a,c			;413b
	ld (0ebb5h),a		;413c
	call palabra_de_tabla		;413f
	ld (0ebb3h),de		;4142
	ld a,c			;4146
	ld hl,04153h		;4147   ; y la cuarta tabla, que es la unica de cuatro entradas
	dec a			;414a
	call palabra_de_tabla		;414b
	ld (0e3a0h),de		;414e   ; la altura a la que aparece el jefe
	ret			;4152

; ----------------------------------------------------------------------
; DATOS alturas_de_la_fase: Cuatro palabras, una por fase de la 1 a la 4, que
;   0x4147 mete en (0xE3A0). Son la primera de las tablas por fase que monta
;   la rutina del Game Master
;   0x4153..0x415b  (8 bytes)
DATA_alturas_de_la_fase:
	defw 02e0eh,00f22h,02637h,02e4bh	; 4153

; ======================================================================
; CODIGO 0x415b..0x4172  (23 bytes)
; ======================================================================


reparte_la_escena:		; Cuenta el cuadro y despacha por (0xE000)
	ld hl,0e003h		;415b   ; el contador de cuadros, que muchas cosas miran
	inc (hl)			;415e
	ld a,(0e000h)		;415f   ; la escena
	cp 003h		;4162   ; en las tres primeras -presentacion, titulo y arranque-
	jr nc,L_416A		;4164
	ld hl,04493h		;4166   ; se apila 0x4493, que remata el cuadro
	push hl			;4169   ; y hara de direccion de retorno cuando la escena acabe
L_416A:
	ld bc,(0e000h)		;416a   ; C la escena y B el paso dentro de ella
	ld a,c			;416e
	call reparte_por_tabla		;416f   ; y a la que toque de las ocho de aqui abajo

; ----------------------------------------------------------------------
; DATOS tabla_de_escenas: Las ocho escenas del juego, y el `call 40ABh` de
;   0x416F reparte por (0xE000): 0 presentacion, 1 el titulo, 2 la partida, 3
;   la fase superada, 4 empieza la fase, 5 el juego, 6 se acabo y 7 el
;   marcador final
;   0x4172..0x4182  (16 bytes)
DATA_tabla_de_escenas:
	defw 04182h,041b1h,041bbh,041dfh,04211h,04222h,042f2h,0432ah	; 4172

; ======================================================================
; CODIGO 0x4182..0x4344  (450 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LAS OCHO ESCENAS. Cada una entra con B = (0xE001), el paso dentro de la escena, y encadena `djnz` para repartir: el paso 0 cae en la primera, el 1 en la segunda y asi. Al final casi todas pasan por 0x41DA, que cuenta un paso mas.
; ----------------------------------------------------------------------
escena_0_la_presentacion:
	djnz L_4195		;4182   ; paso 0 y paso 2 para abajo, mas adelante
	ld a,(0e003h)		;4184   ; el contador de cuadros
	rra			;4187   ; uno de cada dos: el cartel baja a medio ritmo
	ret nc			;4188
	call baja_un_paso		;4189   ; una fila mas arriba
	ret nz			;418c   ; hasta que se acaben los catorce pasos
	ld de,048b4h		;418d   ; y entonces el cartel de KONAMI
	call sube_bloque		;4190
	jr pon_la_espera		;4193   ; y 0x22 cuadros de espera
L_4195:
	djnz L_41A3		;4195   ; paso 2: espera y a la pantalla del titulo
	ld hl,0e004h		;4197
	dec (hl)			;419a   ; mientras quede espera, nada
	ret nz			;419b
	call monta_el_titulo		;419c   ; la pantalla del titulo entera
	xor a			;419f
	jp empieza_la_escena_siguiente		;41a0   ; y a la escena 1 con el paso a cero
L_41A3:
	call escribe_los_registros_del_vdp		;41a3   ; EL PASO 0: los registros del VDP
	call limpia_la_pantalla		;41a6   ; pantalla limpia
	call sube_la_fuente		;41a9   ; la fuente
	call arranca_la_presentacion		;41ac   ; y el rotulo, arriba del todo, listo para bajar
	jr pasa_al_siguiente_paso		;41af
escena_1_el_titulo:
	ld hl,0e004h		;41b1   ; la escena del titulo es solo esperar
	dec (hl)			;41b4
	jp nz,parpadea_la_eleccion		;41b5   ; mientras tanto, parpadea la eleccion
	jp pasa_a_la_escena_siguiente		;41b8   ; y al acabarse la espera, a jugar
escena_2_empieza_la_partida:
	djnz L_41CE		;41bb   ; paso 0 al final, como siempre
	call gasta_el_guion_de_la_demostracion		;41bd   ; el aviso de que empieza
	call el_cuadro_de_juego		;41c0   ; y el marcador
	ld a,(0e077h)		;41c3   ; si queda partida
	or a			;41c6
	ret nz			;41c7
L_41C8:
	ld (0e000h),a		;41c8   ; vuelta a la escena 0: la presentacion otra vez
	jp L_42A9		;41cb
L_41CE:
	call fondo_negro		;41ce   ; fondo negro
	call limpia_la_pantalla		;41d1
	call arranca_la_demostracion		;41d4   ; el rotulo de la fase
pon_la_espera:		; A cuadros de espera en (0xE004)
	ld (0e004h),a		;41d7   ; A cuadros de espera
pasa_al_siguiente_paso:
	ld hl,0e001h		;41da   ; un paso mas
	inc (hl)			;41dd
	ret			;41de
escena_3_fase_superada:
	djnz L_41FC		;41df   ; paso 0 al final
	ld hl,0e004h		;41e1
	dec (hl)			;41e4
	jr z,pasa_al_siguiente_paso		;41e5   ; acabada la espera, al paso siguiente
	call es_el_segundo_jugador		;41e7   ; cada jugador tiene su rotulo
	ld de,048e3h		;41ea   ; el del primero
	jr z,L_41F2		;41ed
	ld de,048eeh		;41ef   ; y el del segundo
L_41F2:
	bit 2,(hl)		;41f2   ; el bit 2 de la espera: asi el rotulo parpadea
	jp z,guion_de_texto		;41f4   ; medio cuadro se escribe
	ld c,000h		;41f7   ; y el otro medio se borra, pasando los codigos por `and 0`
	jp L_46AF		;41f9
L_41FC:
	djnz L_420D		;41fc   ; paso 2 para abajo
	call empieza_una_partida_nueva		;41fe   ; partida nueva
	call fondo_negro		;4201
	call limpia_la_pantalla		;4204
	call empieza_la_partida		;4207   ; y a montarla
	jp pasa_a_la_escena_siguiente		;420a
L_420D:
	ld a,050h		;420d   ; EL PASO 0: 0x50 cuadros de rotulo
	jr pon_la_espera		;420f
escena_4_monta_la_fase:
	call es_el_segundo_jugador		;4211   ; el segundo jugador
	jr z,L_421C		;4214
	ld a,(0e070h)		;4216   ; hereda las vidas del primero
	ld (0e073h),a		;4219
L_421C:
	call monta_el_decorado		;421c   ; los patrones, el color, los sprites y la primera pantalla
	jp pasa_a_la_escena_siguiente		;421f
escena_5_el_juego:
	ld a,(0ebfdh)		;4222   ; el aviso que este corriendo
	and 003h		;4225
	jp nz,L_42D9		;4227   ; si hay uno, se atiende y se sale
	ld a,(0e006h)		;422a   ; el bit 7 del mando: la pausa
	and 080h		;422d   ; con el
	jr z,L_4247		;422f
	rlca			;4231   ; se apunta que hay pausa
	ld (0e05fh),a		;4232
	ld a,(0e079h)		;4235
	cpl			;4238   ; y se conmuta
	ld (0e079h),a		;4239
	and a			;423c   ; sin ella no suena nada
	jr z,L_4247		;423d
	ld a,0d5h		;423f
	call pide_un_sonido_si_se_juega		;4241   ; y con ella, el pitido
	call borra_el_primer_sprite		;4244   ; y se borra el primer sprite
L_4247:
	ld a,(0e079h)		;4247   ; con la pausa puesta
	and a			;424a
	jr z,L_427B		;424b
L_424D:
	call es_el_segundo_jugador		;424d   ; cada jugador tiene su rotulo de vidas
	ld de,04924h		;4250   ; REST del primero
	jr z,L_4258		;4253
	ld de,0491dh		;4255   ; y del segundo
L_4258:
	call guion_a_la_pantalla		;4258   ; el guion al buffer de la pantalla
	call escribe_las_vidas		;425b   ; y las vidas que queden
L_425E:
	ld de,0492bh		;425e   ; STAGE
	call guion_a_la_pantalla		;4261
	call escribe_la_fase		;4264   ; y el numero de fase
escribe_el_marcador:
	call es_el_segundo_jugador		;4267   ; el marcador
	ld de,04907h		;426a   ; HI SCORE y 1P SCORE
	jr z,L_4272		;426d
	ld de,048fch		;426f   ; o los tres, si juegan dos
L_4272:
	call guion_a_la_pantalla		;4272
	call escribe_los_marcadores		;4275   ; y las cifras
	jp sube_la_pantalla		;4278   ; y todo eso a la VRAM de una vez
L_427B:
	call el_cuadro_de_juego		;427b   ; el cuadro de juego entero
	ld a,(0e07fh)		;427e   ; si se acabo la partida
	and a			;4281
	jr z,L_4289		;4282
	call pasa_a_la_escena_siguiente		;4284   ; se saltan dos escenas de golpe
	jr pasa_a_la_escena_siguiente		;4287
L_4289:
	ld hl,0e079h		;4289   ; la cuenta atras de las dos naves
	ld ix,0ef80h		;428c   ; los sprites del primero
	ld de,0e104h		;4290   ; y sus variables
	ld b,002h		;4293   ; los dos jugadores
	call cuenta_atras_de_los_dos		;4295
	ld a,(0e07ah)		;4298   ; mientras a alguno le quede algo
	or (hl)			;429b
	ret nz			;429c
	ld a,(0e077h)		;429d   ; o quede partida
	or a			;42a0
	ret nz			;42a1
empieza_la_escena_siguiente:
	ld (0e004h),a		;42a2   ; la espera a cero
pasa_a_la_escena_siguiente:
	ld hl,0e000h		;42a5   ; una escena mas
	inc (hl)			;42a8
L_42A9:
	xor a			;42a9   ; y su paso, a cero
	ld (0e001h),a		;42aa
	ret			;42ad
cuenta_atras_de_los_dos:		; Los dos jugadores, con IX en su bloque de sprites y DE en sus variables
	inc l			;42ae   ; el contador de la nave
	ld a,(hl)			;42af
	and a			;42b0
	jr z,L_42C2		;42b1
	dec (hl)			;42b3   ; uno menos
	jr nz,L_42C2		;42b4
	ld a,0e0h		;42b6   ; y al llegar a cero, los sprites de la nave se apartan
	ld (ix+000h),a		;42b8
	ld (ix+004h),a		;42bb
	ld (ix+010h),a		;42be
	ld (de),a			;42c1
L_42C2:
	ld de,0e114h		;42c2   ; las variables del segundo
	ld ix,0ef88h		;42c5   ; y sus sprites
	djnz cuenta_atras_de_los_dos		;42c9
	ret			;42cb
borra_el_primer_sprite:
	ld a,0d0h		;42cc   ; 0xD0 en la Y del primer sprite corta la lista entera
	ld hl,03b00h		;42ce
	call 0004dh		;42d1   ; BIOS WRTVRM - Writes data in VRAM
	ld d,014h		;42d4   ; y se borran veinte casillas
	jp borra_el_marco		;42d6
L_42D9:
	rra			;42d9   ; el bit 0 del aviso
	jr nc,L_42E6		;42da
	ld (0e004h),a		;42dc   ; espera a cero
	ld a,002h		;42df
	ld (0ebfdh),a		;42e1   ; y el aviso pasa a 2
	jr borra_el_primer_sprite		;42e4
L_42E6:
	ld hl,0e004h		;42e6
	dec (hl)			;42e9   ; mientras dure la espera
	jp nz,L_424D		;42ea   ; se sigue pintando el marcador
	xor a			;42ed
	ld (0ebfdh),a		;42ee   ; y al acabarse, el aviso fuera
	ret			;42f1
escena_6_se_acabo:
	djnz L_430A		;42f2   ; paso 0 al final
	ld a,(0e006h)		;42f4   ; los dos mandos
	ld hl,0e008h		;42f7
	or (hl)			;42fa
	and 010h		;42fb   ; el gatillo: se puede saltar la espera
	jp nz,pasa_al_siguiente_paso		;42fd
	ld hl,0e004h		;4300
	dec (hl)			;4303   ; o esperar a que se acabe
	jp z,pasa_al_siguiente_paso		;4304
	jp L_425E		;4307   ; mientras tanto, el marcador
L_430A:
	djnz L_431A		;430a   ; paso 2 para abajo
	ld hl,0e002h		;430c   ; los bits de modo
	ld a,(hl)			;430f
	and 09fh		;4310   ; fuera los bits 5 y 6: se acabo lo de dos jugadores
	ld (hl),a			;4312
	xor a			;4313
	ld (0f0ffh),a		;4314   ; y la marca de partida empezada
	jp L_41C8		;4317
L_431A:
	call aparta_los_sprites		;431a   ; los sprites fuera
	ld hl,0ec40h		;431d   ; el buffer de la pantalla
	ld de,02018h		;4320   ; se limpia entero
	call borra_un_cuadro		;4323
	xor a			;4326
	jp pon_la_espera		;4327   ; y sin espera
escena_7_el_marcador_final:
	push bc			;432a   ; el marcador se sube en cada cuadro
	call sube_la_pantalla		;432b
	pop bc			;432e
	djnz $+42		;432f   ; paso 2 para abajo
	ld hl,0ebf7h		;4331   ; lo que dura la animacion
	dec (hl)			;4334
	jr z,L_433B		;4335   ; al acabarse, otra vuelta
	ld b,001h		;4337
	jr $+54		;4339
L_433B:
	call aparta_los_sprites		;433b   ; los sprites fuera
	ld hl,04353h		;433e   ; y el estado inicial del guion
	jp L_446A		;4341

; ----------------------------------------------------------------------
; DATOS guion_de_la_nave_del_marcador: El que gasta la escena 7, el marcador
;   final
;   0x4344..0x4353  (15 bytes)
DATA_guion_de_la_nave_del_marcador:
	defb 003h	; 4344
	defb 021h	; 4345
	defb 044h	; 4346
	defb 082h	; 4347
	defb 005h	; 4348
	defb 023h	; 4349
	defb 046h	; 434a
	defb 084h	; 434b
	defb 007h	; 434c
	defb 025h	; 434d
	defb 048h	; 434e
	defb 086h	; 434f
	defb 009h	; 4350
	defb 027h	; 4351
	defb 04ah	; 4352

; ----------------------------------------------------------------------
; DATOS estado_inicial_del_marcador: Los seis bytes que 0x433E copia a 0xEBF7.
;   Los dos ultimos son 44 43, o sea el puntero a 0x4344 de aqui arriba
;   0x4353..0x4359  (6 bytes)
DATA_estado_inicial_del_marcador:
	defb 051h,003h,08ch,0edh	; 4353
	defw 04344h	; 4357  -> DATA_guion_de_la_nave_del_marcador

; ======================================================================
; CODIGO 0x4359..0x4475  (284 bytes)
; ======================================================================


L_4359:
	djnz L_43C8		;4359   ; paso 0 al final
	ld hl,0ebf7h		;435b   ; la cuenta del cartel
	dec (hl)			;435e
	jr nz,L_436D		;435f
	ld de,04933h		;4361   ; el CONGRATULATION!
	call guion_a_la_pantalla		;4364
	call escribe_el_marcador		;4367   ; y los puntos
	jp pasa_al_siguiente_paso		;436a
L_436D:
	ld b,000h		;436d
L_436F:
	ld hl,0ebf8h		;436f   ; el reloj del paso
	dec (hl)			;4372
	ld a,(hl)			;4373
	ld c,a			;4374
	and 01fh		;4375   ; los cinco bits bajos: lo que dura
	jr nz,dibuja_la_nave_que_cruza		;4377
	ld hl,(0ebfbh)		;4379   ; y al acabarse, el paso siguiente del guion
	inc hl			;437c
	ld (0ebfbh),hl		;437d
	ld a,(hl)			;4380
	ld (0ebf8h),a		;4381
dibuja_la_nave_que_cruza:
	xor a			;4384   ; sin paso, no se dibuja
	dec b			;4385   ; el paso, uno menos
	ld b,a			;4386   ; las dos de abajo, en blanco
	ld d,a			;4387
	ld e,a			;4388
	jr nz,escribe_las_cuatro_casillas		;4389
	ld de,07475h		;438b   ; las casillas de la estela
	ld a,(0ebf7h)		;438e   ; el bit 0 del estado: dos parejas de dibujos
	rra			;4391
	ld a,070h		;4392   ; la de la izquierda
	ld b,071h		;4394   ; y la de la derecha
	jr c,escribe_las_cuatro_casillas		;4396
	ld a,072h		;4398   ; la otra pareja
	ld b,073h		;439a
escribe_las_cuatro_casillas:
	ld hl,(0ebf9h)		;439c   ; donde va
	ld (hl),a			;439f   ; las dos casillas de arriba
	inc hl			;43a0
	ld (hl),b			;43a1   ; y la de la derecha
	ld a,01fh		;43a2   ; y 0x1F mas alla, o sea la fila de abajo
	call suma_a_a_hl		;43a4
	ld (hl),d			;43a7   ; la de abajo a la izquierda
	inc hl			;43a8
	ld (hl),e			;43a9   ; y la de abajo a la derecha
	ld a,c			;43aa   ; los tres bits altos: por donde tira
	and 0e0h		;43ab
	ld de,00002h		;43ad   ; a la derecha
	jr z,L_43C0		;43b0
	cp 020h		;43b2
	ld e,040h		;43b4   ; hacia abajo, dos filas
	jr z,L_43C0		;43b6
	cp e			;43b8
	ld de,0fffeh		;43b9   ; a la izquierda
	jr z,L_43C0		;43bc
	ld e,0c0h		;43be   ; y hacia arriba
L_43C0:
	ld hl,(0ebf9h)		;43c0
	add hl,de			;43c3
	ld (0ebf9h),hl		;43c4
	ret			;43c7
L_43C8:
	ld hl,(0ebf4h)		;43c8   ; por donde va la nave
	inc hl			;43cb   ; una casilla mas
	ld (0ebf4h),hl		;43cc
	djnz L_43FA		;43cf   ; paso 2 para abajo
	ld de,00400h		;43d1   ; y al llegar a 0x400, se acabo
	rst 20h			;43d4
	jp z,pasa_al_siguiente_paso		;43d5
L_43D8:
	ld hl,0ebf3h		;43d8   ; el paso siguiente
	inc (hl)			;43db
	ld a,(hl)			;43dc
	sub 012h		;43dd
	ret nz			;43df
	ld (hl),a			;43e0
	ld hl,0ec40h		;43e1
	ld bc,00300h		;43e4
L_43E7:
	ld a,(hl)			;43e7   ; las casillas de la estela
	cp 070h		;43e8   ; de la 0x70 a la 0x73
	jr c,L_43F2		;43ea
	cp 074h		;43ec
	jr nc,L_43F2		;43ee
	xor 002h		;43f0   ; se les da la vuelta con el bit 1
L_43F2:
	ld (hl),a			;43f2   ; y se escriben
	inc hl			;43f3
	dec bc			;43f4
	ld a,c			;43f5
	or b			;43f6
	jr nz,L_43E7		;43f7
	ret			;43f9
L_43FA:
	djnz L_443F		;43fa
	ld a,l			;43fc   ; cada dieciseis casillas
	and 00fh		;43fd
	jr nz,L_43D8		;43ff
	ld hl,0ece6h		;4401   ; se sube una fila entera del buffer
	ld de,0ecc6h		;4404
	ld b,00fh		;4407
L_4409:
	push bc			;4409   ; veinte casillas de la fila
	ld bc,00014h		;440a   ; veinte casillas por fila
	ldir		;440d
	pop bc			;440f
	ld a,00ch		;4410
	call suma_a_a_de		;4412   ; doce mas: hasta el borde
	ld hl,00020h		;4415   ; y la fila siguiente
	add hl,de			;4418
	djnz L_4409		;4419
	ex de,hl			;441b
	ld b,014h		;441c   ; veinte casillas
	xor a			;441e
pinta_el_cartel_del_final:
	ld (hl),a			;441f
	inc hl			;4420   ; la fila siguiente
	djnz pinta_el_cartel_del_final		;4421
	ld hl,0ebf6h		;4423   ; el paso del cartel
	inc (hl)			;4426
	ld a,(hl)			;4427
	cp 00dh		;4428   ; y con trece se acabo
	jp z,pasa_al_siguiente_paso		;442a
	dec a			;442d
	ld hl,04945h		;442e   ; la tabla de los doce rotulos
	call palabra_de_tabla		;4431
	ld a,(de)			;4434
	ld hl,0eea0h		;4435   ; en su sitio del buffer
	call suma_a_a_hl		;4438
	inc de			;443b
	jp L_462F		;443c
L_443F:
	djnz L_445C		;443f   ; paso 3
	ld de,009c0h		;4441   ; al llegar a 0x9C0
	rst 20h			;4444
	jr nz,L_444F		;4445
	ld a,0f7h		;4447   ; se calla la musica
	ld (0e05eh),a		;4449
	jp L_43D8		;444c
L_444F:
	ld a,(0e012h)		;444f   ; y con el canal libre
	and a			;4452
	jr nz,L_43D8		;4453
	ld hl,00206h		;4455   ; se pasa a la escena 2 paso 6
	ld (0e000h),hl		;4458
	ret			;445b
L_445C:
	ld hl,00380h		;445c
	ld a,020h		;445f
	ld bc,00030h		;4461
	call rellena_los_tres_bancos		;4464
	ld hl,0448dh		;4467
L_446A:
	ld de,0ebf7h		;446a
	ld bc,00006h		;446d
	ldir		;4470
	jp pasa_al_siguiente_paso		;4472

; ----------------------------------------------------------------------
; DATOS guion_de_la_nave_de_la_fase: El de la escena 3, cuando se pasa de fase
;   0x4475..0x448d  (24 bytes)
DATA_guion_de_la_nave_de_la_fase:
	defb 02bh	; 4475
	defb 00fh	; 4476
	defb 08bh	; 4477
	defb 04eh	; 4478
	defb 02ah	; 4479
	defb 00dh	; 447a
	defb 089h	; 447b
	defb 04ch	; 447c
	defb 028h	; 447d
	defb 00bh	; 447e
	defb 087h	; 447f
	defb 04ah	; 4480
	defb 026h	; 4481
	defb 009h	; 4482
	defb 085h	; 4483
	defb 048h	; 4484
	defb 024h	; 4485
	defb 007h	; 4486
	defb 083h	; 4487
	defb 046h	; 4488
	defb 022h	; 4489
	defb 005h	; 448a
	defb 081h	; 448b
	defb 045h	; 448c

; ----------------------------------------------------------------------
; DATOS estado_inicial_de_la_fase: Y su estado, con el puntero a 0x4475
;   0x448d..0x4493  (6 bytes)
DATA_estado_inicial_de_la_fase:
	defb 0c1h,02bh,040h,0ech	; 448d
	defw 04475h	; 4491  -> DATA_guion_de_la_nave_de_la_fase

; ======================================================================
; CODIGO 0x4493..0x4525  (146 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL REMATE DEL CUADRO EN LAS TRES PRIMERAS ESCENAS. Aqui vuelve el `ret` de la escena, porque 0x4166 apilo esta direccion antes de repartir. Lee los dos mandos, y con el gatillo arranca la partida: uno o dos jugadores segun donde este la eleccion.
; ----------------------------------------------------------------------
L_4493:
	call lee_el_mando_del_uno		;4493   ; el mando del primer jugador
	push af			;4496
	call lee_el_mando_del_dos		;4497   ; y el del segundo
	pop hl			;449a
	or h			;449b   ; juntos
	ld hl,0e061h		;449c   ; y las teclas
	call guarda_lo_que_acaba_de_pulsarse		;449f
	and 03fh		;44a2   ; sin gatillo ni START no hay nada que hacer
	ret z			;44a4
	ld hl,0e004h		;44a5   ; la espera, a cero
	ld (hl),000h		;44a8
	ld l,(hl)			;44aa   ; y ese cero es tambien el paso: L pasa a valer 0
	ld de,0e062h		;44ab
	ld b,(hl)			;44ae
	djnz L_44F0		;44af   ; con el paso a 1 -o sea en el titulo-, se empieza
	and 030h		;44b1   ; los bits 4 y 5: el gatillo de verdad
	jr z,L_44FA		;44b3
	ld a,(de)			;44b5   ; donde este la eleccion
	or a			;44b6
	ld a,040h		;44b7   ; arriba, un jugador
	jr z,L_44BD		;44b9
	ld a,060h		;44bb   ; abajo, dos
L_44BD:
	ld (0e002h),a		;44bd   ; y eso son los bits de modo
	ld (hl),003h		;44c0   ; escena 3
	inc hl			;44c2
	ld c,000h		;44c3   ; con el paso a cero
	ld (hl),c			;44c5
	dec c			;44c6
	call marca_la_eleccion		;44c7   ; y se calla el sonido
	ld a,(0e060h)		;44ca   ; los bits de servicio
	and 020h		;44cd
	jr z,L_44E9		;44cf
	call es_el_segundo_jugador		;44d1   ; solo para el primer jugador
	jr nz,L_44E9		;44d4
	ld a,(0e063h)		;44d6   ; lo que se haya pulsado
	ld c,002h		;44d9
	cp c			;44db
	jr z,L_44EB		;44dc
	dec c			;44de
	cp 080h		;44df
	jr z,L_44EB		;44e1
	cp 010h		;44e3
	ld c,004h		;44e5
	jr z,L_44EB		;44e7
L_44E9:
	ld c,000h		;44e9
L_44EB:
	ld a,c			;44eb
	ld (0f0ffh),a		;44ec   ; va a 0xF0FF, que es donde se apunta el truco
	ret			;44ef
L_44F0:
	ld (hl),001h		;44f0   ; en la presentacion, el gatillo salta al titulo
	ld a,0f7h		;44f2   ; se calla el sonido
	call pide_un_sonido		;44f4
	jp monta_el_titulo		;44f7   ; y se monta el titulo de golpe
L_44FA:
	ld a,(de)			;44fa   ; fuera del titulo, el gatillo solo mueve la eleccion
	xor 001h		;44fb
	ld (de),a			;44fd
	ret			;44fe
empieza_una_partida_nueva:
	ld hl,0e068h		;44ff   ; toda la RAM de partida, de 0xE068 a 0xF000
	ld de,0e069h		;4502
	ld bc,00f98h		;4505
	ld (hl),000h		;4508   ; a cero
	ldir		;450a
	call es_el_segundo_jugador		;450c   ; cada jugador tiene su tanda de arranque
	ld hl,04525h		;450f
	jr z,L_4517		;4512
	ld hl,0452dh		;4514
L_4517:
	ld de,0e070h		;4517
	ld c,008h		;451a
	ldir		;451c   ; los ocho bytes a sus variables
	ld a,(0e076h)		;451e   ; y la fase, tambien aparte
	ld (0e07dh),a		;4521
	ret			;4524

; ----------------------------------------------------------------------
; DATOS partida_nueva_del_uno: Los ocho bytes que 0x451C copia a 0xE070 al
;   empezar: las vidas, la fase y los contadores
;   0x4525..0x452d  (8 bytes)
DATA_partida_nueva_del_uno:
	defb 002h	; 4525
	defb 010h	; 4526
	defb 000h	; 4527
	defb 000h	; 4528
	defb 000h	; 4529
	defb 000h	; 452a
	defb 001h	; 452b
	defb 001h	; 452c

; ----------------------------------------------------------------------
; DATOS partida_nueva_del_dos: Lo mismo para el segundo jugador; 0x450C elige
;   entre los dos
;   0x452d..0x4535  (8 bytes)
DATA_partida_nueva_del_dos:
	defb 002h	; 452d
	defb 010h	; 452e
	defb 000h	; 452f
	defb 002h	; 4530
	defb 010h	; 4531
	defb 000h	; 4532
	defb 001h	; 4533
	defb 003h	; 4534

; ======================================================================
; CODIGO 0x4535..0x47f1  (700 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LA PUNTUACION, QUE VA EN BCD. Tres bytes por jugador -seis cifras- sumados con `daa`, con tope en 999999 y una vida extra cada vez que se cruza el escalon que guarda 0xE075. Cada jugador entra por su puerta: 0x4535 el primero y 0x453F el segundo.
; ----------------------------------------------------------------------
suma_al_primero:
	ld l,c			;4535   ; lo que se suma, que viene en BC
	ld h,b			;4536
	ld bc,0e06dh		;4537   ; la puntuacion del primero
	ld de,0e072h		;453a   ; y su escalon de vida extra
	jr L_4547		;453d
suma_al_segundo:
	ld l,c			;453f
	ld h,b			;4540
	ld bc,0e069h		;4541   ; la del segundo
	ld de,0e075h		;4544
L_4547:
	ld a,(0e002h)		;4547   ; el bit 6 de los bits de modo
	add a,a			;454a
	ret p			;454b   ; con el a cero no se puntua: es la demostracion
	ld a,(bc)			;454c   ; las dos cifras bajas
	add a,l			;454d
	daa			;454e   ; en decimal
	ld (bc),a			;454f
	inc c			;4550
	ld a,(bc)			;4551   ; las de en medio
	adc a,h			;4552
	daa			;4553
	ld (bc),a			;4554
	ld l,a			;4555
	inc c			;4556
	ld a,(bc)			;4557   ; y las altas
	adc a,000h		;4558
	daa			;455a
	ld (bc),a			;455b
	ld h,a			;455c
	jr nc,L_4569		;455d   ; si se pasa de 999999
	ld hl,09999h		;455f   ; se clava ahi
	ld (0e064h),hl		;4562
	ld (0e066h),hl		;4565
	ret			;4568
L_4569:
	push bc			;4569   ; el escalon de la vida extra
	ld a,(de)			;456a   ; el escalon, en BCD
	ld b,a			;456b
	dec de			;456c
	ld a,(de)			;456d
	ld c,a			;456e
	and a			;456f   ; menos la puntuacion
	sbc hl,bc		;4570   ; hasta llegar a el no hay nada
	jr c,L_4594		;4572
	ld a,010h		;4574   ; y al pasarlo, el escalon sube 0x1000
	add a,c			;4576   ; el byte bajo mas 0x10
	daa			;4577
	ld (de),a			;4578
	ld l,a			;4579   ; a salvo para el `or`
	inc de			;457a
	ld a,000h		;457b   ; y el alto, con el acarreo
	adc a,b			;457d
	daa			;457e
	ld (de),a			;457f
	or l			;4580   ; con los dos a cero, desbordo
	jr nz,L_4586		;4581
	ld a,0a0h		;4583   ; y al desbordar se pone en 0xA0
	ld (de),a			;4585
L_4586:
	dec de			;4586   ; dos bytes atras: las vidas
	dec de			;4587
	ld a,(de)			;4588   ; las vidas
	cp 099h		;4589   ; con 99 ya no caben mas
	jr z,L_4594		;458b
	add a,001h		;458d   ; una mas
	daa			;458f
	ld (de),a			;4590
	call musica_de_vida_extra		;4591   ; y suena el aviso
L_4594:
	pop hl			;4594
	ld b,004h		;4595   ; cuatro cifras del record
	ld de,0e067h		;4597   ; el record
	ld c,l			;459a   ; y la puntuacion
L_459B:
	ld a,(de)			;459b   ; se compara con la puntuacion
	sub (hl)			;459c
	jr c,L_45A4		;459d
	ret nz			;459f   ; si el record gana, nada
	dec l			;45a0
	dec e			;45a1
	djnz L_459B		;45a2
L_45A4:
	ld l,c			;45a4   ; y si no, la puntuacion pasa a ser el record
	ld bc,00003h		;45a5
	ld e,067h		;45a8
	lddr		;45aa
	ret			;45ac
escribe_los_marcadores:
	ld de,0e067h		;45ad   ; el marcador del primer jugador
	ld hl,0ed51h		;45b0   ; en su sitio del buffer
	call escribe_cuatro_cifras		;45b3
	call es_el_segundo_jugador		;45b6   ; y si juegan dos
	ld hl,0ee51h		;45b9   ; tambien el del segundo
	ld e,06bh		;45bc   ; y su puntuacion
	call nz,escribe_cuatro_cifras		;45be
	ld hl,0edb1h		;45c1   ; y el record, que siempre se pinta
	ld e,06fh		;45c4   ; el record vive en 0xE06F
escribe_cuatro_cifras:
	ld b,004h		;45c6   ; cuatro bytes: ocho cifras
	jr escribe_cifras		;45c8
escribe_la_fase:
	ld hl,0ecf2h		;45ca   ; la fase
	ld de,0e07dh		;45cd   ; y el numero de fase
	jr escribe_una_cifra		;45d0
escribe_las_vidas:
	ld hl,0ee91h		;45d2   ; las vidas del segundo
	ld de,0e073h		;45d5   ; y sus vidas
	call es_el_segundo_jugador		;45d8
	call nz,escribe_una_cifra		;45db
	ld hl,0edf1h		;45de   ; y las del primero
	ld e,070h		;45e1   ; y las vidas del primero
escribe_una_cifra:
	ld b,001h		;45e3   ; una sola cifra
escribe_cifras:
	ld c,000h		;45e5   ; sin ceros a la izquierda todavia
L_45E7:
	ld a,(de)			;45e7   ; el byte en BCD
	rra			;45e8   ; la cifra alta
	rra			;45e9
	rra			;45ea
	rra			;45eb
	and 00fh		;45ec   ; en binario
	jr z,L_45F2		;45ee   ; mientras sea cero y no haya salido ninguna cifra
	ld c,0ffh		;45f0   ; en cuanto sale una, se dejan de comer ceros
L_45F2:
	add a,010h		;45f2   ; el codigo de la casilla del digito
	and c			;45f4   ; y con C a cero, la casilla se queda en blanco
	ld (hl),a			;45f5
	inc hl			;45f6   ; la casilla siguiente
	djnz L_45FB		;45f7   ; y si era la ultima
	ld c,0ffh		;45f9   ; la cifra baja ya no se come
L_45FB:
	inc b			;45fb   ; se deshace el `djnz`
	ld a,(de)			;45fc   ; la cifra baja
	and 00fh		;45fd
	jr z,L_4603		;45ff
	ld c,0ffh		;4601
L_4603:
	add a,010h		;4603
	and c			;4605
	ld (hl),a			;4606   ; la casilla
	dec e			;4607   ; y al byte anterior, que las cifras van al reves
	inc hl			;4608
	djnz L_45E7		;4609
	ret			;460b
descomprime_el_mapa:
	ld de,0e400h		;460c   ; el mapa se descomprime a la RAM
	ld hl,06d74h		;460f   ; el guion, que es una lista de tramos
	push hl			;4612   ; y se apila para el bucle
el_siguiente_tramo:
	pop hl			;4613
	ld a,(hl)			;4614   ; el tramo que toca
	inc a			;4615   ; 0xFF y se acabo el mapa
	ret z			;4616
	dec a			;4617
	inc hl			;4618
	push hl			;4619   ; el guion, a salvo
	ld hl,06e01h		;461a   ; la tabla de tramos
	call suma_a_a_hl		;461d   ; la entrada de la tabla
	ld a,(hl)			;4620   ; y su direccion
	inc hl			;4621
	ld h,(hl)			;4622
	ld l,a			;4623
copia_el_tramo:
	ld a,(hl)			;4624   ; cada tramo es una lista de codigos de fila
	inc a			;4625   ; hasta su propio 0xFF
	jr z,el_siguiente_tramo		;4626
	ldi		;4628   ; y se copian tal cual
	jr copia_el_tramo		;462a
guion_a_la_pantalla:
	call saca_el_destino_del_bloque		;462c   ; el destino sale del propio guion
L_462F:
	ld a,(de)			;462f
	inc de			;4630
	ld b,a			;4631
	inc b			;4632   ; 0xFF acaba
	ret z			;4633
	inc b			;4634   ; 0xFE cambia de sitio
	jr z,guion_a_la_pantalla		;4635
	ld (hl),a			;4637   ; y lo demas son codigos de casilla
	inc hl			;4638
	jr L_462F		;4639
borra_el_marco:
	ld hl,0ecc6h		;463b   ; el marco del cuadro de juego
	ld e,010h		;463e
borra_un_cuadro:
	ld c,000h		;4640   ; D filas de B casillas
	ld b,d			;4642
	push hl			;4643
L_4644:
	ld (hl),c			;4644
	inc hl			;4645
	djnz L_4644		;4646
	pop hl			;4648
	ld a,020h		;4649
	call suma_a_a_hl		;464b   ; y la fila de abajo
	dec e			;464e
	jr nz,borra_un_cuadro		;464f
	ret			;4651
limpia_la_pantalla:
	call aparta_los_sprites		;4652   ; los sprites fuera
	ld hl,03800h		;4655   ; y la tabla de nombres a cero
	ld bc,00300h		;4658
	xor a			;465b
	jp 00056h		;465c   ; BIOS FILVRM - Fills VRAM with value
prepara_la_escritura:		; SETWRT y deja en C el puerto de datos del VDP
	call 00053h		;465f   ; BIOS SETWRT - Enables VDP to write | el puerto de datos del VDP, que la BIOS deja en 0x0007
	ld a,(00007h)		;4662
	ld c,a			;4665
	ret			;4666
saca_el_destino_del_bloque:		; Los dos primeros bytes de un bloque son su direccion de VRAM
	ex de,hl			;4667   ; se cambian, se lee la palabra
	ld e,(hl)			;4668
	inc hl			;4669
	ld d,(hl)			;466a
	ex de,hl			;466b
	inc de			;466c   ; y el puntero queda pasado los dos bytes
	ret			;466d
sube_la_pantalla:		; Los 768 bytes del buffer de 0xEC40 a la tabla de nombres, de 0x40 en 0x40
	ld hl,03800h		;466e   ; la tabla de nombres
	call prepara_la_escritura		;4671
	ld hl,0ec40h		;4674   ; desde el buffer de RAM
	ld a,018h		;4677   ; 24 filas
	ld d,040h		;4679   ; de 0x40 bytes... que son dos de 0x20
L_467B:
	ld b,d			;467b
L_467C:
	outi		;467c   ; y salen por el puerto sin pasar por la BIOS
	djnz L_467C		;467e
	dec a			;4680
	jr nz,L_467B		;4681
	ret			;4683
rellena_los_tres_bancos:		; El FILVRM de la BIOS repetido en los tres bancos de SCREEN 2
	ld d,003h		;4684   ; los tres bancos de SCREEN 2
L_4686:
	push bc			;4686
	push de			;4687
	call 00056h		;4688   ; BIOS FILVRM - Fills VRAM with value
	ld de,00800h		;468b   ; 0x800 mas arriba cada vez
	add hl,de			;468e
	pop de			;468f
	pop bc			;4690
	dec d			;4691
	jr nz,L_4686		;4692
	ret			;4694

; ----------------------------------------------------------------------
; EL DESCOMPRESOR. Todo lo que este cartucho mete en la VRAM pasa por aqui. El formato, leido en 0x471F: un 0x00 acaba; un byte menor que 0x80 es una REPETICION -el byte siguiente, tantas veces-; el 0x80 exacto cambia el destino, que viene en las dos siguientes, y de paso apaga el filtro; y cualquier otro son (n & 0x7F) bytes LITERALES. Y cada byte que sale pasa por el filtro de 0x4786, que mira el registro C: con el bit 0 el byte se invierte bit a bit -el espejo horizontal, que es como se guarda media nave y se calcula la otra mitad- y con el bit 7 se permutan los colores.
; ----------------------------------------------------------------------
sube_espejado:		; Tres bancos, con el espejo puesto (C=1)
	ld c,001h		;4695
	jr sube_tres_bancos		;4697
sube_tal_cual:		; Tres bancos, sin filtro
	ld c,000h		;4699
sube_tres_bancos:		; Con el filtro que le den en C
	ld b,003h		;469b
L_469D:
	push bc			;469d   ; tres bancos
	push de			;469e
	push hl			;469f
	call sube_bloque_a_hl		;46a0   ; el bloque
	pop hl			;46a3
	ld a,008h		;46a4   ; 0x800 mas arriba cada vez
	add a,h			;46a6
	ld h,a			;46a7
	pop de			;46a8
	pop bc			;46a9
	djnz L_469D		;46aa
	ret			;46ac
guion_de_texto:		; Una direccion de VRAM, los codigos que van ahi, 0xFE para saltar a otra y 0xFF para acabar
	ld c,0ffh		;46ad   ; C a 0xFF: los codigos pasan enteros
L_46AF:
	call saca_el_destino_del_bloque		;46af   ; y el destino, del propio guion
L_46B2:
	ld a,(de)			;46b2
	inc de			;46b3
	ld b,a			;46b4
	inc b			;46b5   ; 0xFF acaba
	ret z			;46b6
	inc b			;46b7   ; 0xFE salta a otra direccion
	jr z,L_46AF		;46b8
	and c			;46ba   ; `and c`: con C a cero el codigo se convierte en la casilla vacia, y asi el mismo guion sirve para BORRAR el rotulo
	call 0004dh		;46bb   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;46be
	jr L_46B2		;46bf
aparta_los_sprites:		; Y = 0xE0 en los 32 sprites del buffer: fuera de la pantalla
	ld hl,0ef80h		;46c1   ; los 32 sprites del buffer
	ld b,020h		;46c4
L_46C6:
	ld (hl),0e0h		;46c6   ; Y = 0xE0, que en el TMS9918 es "fuera de la pantalla"
	ld a,004h		;46c8   ; de cuatro en cuatro
	add a,l			;46ca
	ld l,a			;46cb
	djnz L_46C6		;46cc

; ----------------------------------------------------------------------
; LA RUEDA DE SPRITES. El TMS9918 solo pinta cuatro sprites por linea y descarta los de indice mas alto, asi que un juego con muchos enemigos parpadea siempre en los mismos. Aqui los cuatro primeros -las naves y sus disparos- van fijos a 0x3B00, y los VEINTIOCHO restantes se suben en un ORDEN QUE ROTA: (0xE00F) avanza 0x10 en cada cuadro y da la vuelta al llegar a 0x1E, y dentro del bucle el paso es 0x44. Asi ningun enemigo se queda sin pintar dos cuadros seguidos, y lo que se ve no es una desaparicion sino un parpadeo repartido.
; ----------------------------------------------------------------------
sube_los_sprites:
	ld hl,03b00h		;46ce   ; los cuatro primeros sprites, siempre en cabeza
	call prepara_la_escritura		;46d1
	ld hl,0ef80h		;46d4
	ld b,010h		;46d7   ; 16 bytes = 4 sprites
	di			;46d9   ; el `outi` no admite interrupcion por medio
L_46DA:
	outi		;46da
	djnz L_46DA		;46dc
	ei			;46de
	ld hl,03b08h		;46df   ; y a partir del quinto
	call prepara_la_escritura		;46e2
	ld hl,0e00fh		;46e5   ; por donde va la rueda
	ld a,(hl)			;46e8
	add a,010h		;46e9   ; 0x10 mas en cada cuadro
	ld d,a			;46eb
	sub 01eh		;46ec   ; y al pasarse de 0x1E, vuelta a empezar
	jr nc,L_46F1		;46ee
	ld a,d			;46f0
L_46F1:
	ld (hl),a			;46f1
	add a,a			;46f2   ; por cuatro: cada sprite ocupa cuatro bytes
	add a,a			;46f3
	ld e,01eh		;46f4   ; veintiocho sprites
L_46F6:
	ld hl,0ef88h		;46f6   ; el buffer, desde el quinto
	ld d,a			;46f9
	add a,l			;46fa
	ld l,a			;46fb
	ld b,008h		;46fc   ; dos sprites por vuelta
	di			;46fe
L_46FF:
	outi		;46ff
	djnz L_46FF		;4701
	ei			;4703
	ld a,d			;4704
	add a,044h		;4705   ; 0x44 adelante, que es 17 sprites
	ld d,a			;4707
	sub 078h		;4708   ; dando la vuelta a los 0x78
	jr nc,L_470D		;470a
	ld a,d			;470c
L_470D:
	dec e			;470d
	jr nz,L_46F6		;470e
	ret			;4710
sube_bloque:		; El destino viene DENTRO del bloque
	ld c,000h		;4711   ; sin filtro
	call saca_el_destino_del_bloque		;4713   ; y el destino, del bloque
sube_bloque_a_hl:		; Con el destino ya en HL
	call 00053h		;4716   ; BIOS SETWRT - Enables VDP to write | SETWRT deja el puerto listo
	exx			;4719   ; el juego de registros de repuesto guarda el puerto
	ld a,(00007h)		;471a
	ld c,a			;471d
	exx			;471e
L_471F:
	ld a,(de)			;471f   ; el byte de mando
	and a			;4720   ; 0x00 acaba
	ret z			;4721
	inc de			;4722
	ld b,a			;4723
	and 07fh		;4724   ; se le quita el bit 7
	cp b			;4726   ; si no cambia, es que el bit 7 estaba a cero: REPETICION
	jr z,L_4738		;4727
	and a			;4729   ; y si lo que queda es cero, o sea 0x80 exacto
	jr z,sube_bloque		;472a   ; se cambia de destino
	ld b,a			;472c   ; y si no, son B bytes literales
L_472D:
	call filtro_del_byte		;472d   ; cada uno pasa por el filtro
	exx			;4730
	out (c),a		;4731   ; y sale por el puerto
	exx			;4733
	djnz L_472D		;4734
	jr L_471F		;4736
L_4738:
	call filtro_del_byte		;4738   ; en la repeticion, un solo byte
L_473B:
	exx			;473b   ; repetido B veces
	out (c),a		;473c
	exx			;473e
	djnz L_473B		;473f
	jr L_471F		;4741
sube_patrones_de_sprite:		; Media pareja de 16 bytes y la otra media calculada invirtiendo cada byte: por eso los sprites de este juego son simetricos
	call 00053h		;4743   ; BIOS SETWRT - Enables VDP to write | el destino, en BC al reves
	ld h,c			;4746   ; H el filtro y L las vueltas
	ld l,b			;4747
	ld a,(00007h)		;4748
	ld c,a			;474b
L_474C:
	push de			;474c   ; se guarda el origen
	xor a			;474d
	call tira_de_dieciseis		;474e   ; dieciseis bytes tal cual: la mitad izquierda
	bit 0,h		;4751   ; con el bit 0 de H, dos parejas por vuelta
	jr z,L_4760		;4753
	push de			;4755
	xor a			;4756
	call tira_de_dieciseis		;4757
	pop de			;475a
	ld a,001h		;475b
	call tira_de_dieciseis		;475d
L_4760:
	pop de			;4760   ; y otra vez desde el mismo sitio
	ld a,001h		;4761
	call tira_de_dieciseis		;4763   ; pero invertidos: la mitad derecha es el espejo de la izquierda
	bit 0,h		;4766
	jr z,L_476F		;4768
	ld a,010h		;476a   ; con dos parejas, el origen avanza 0x10
	call suma_a_a_de		;476c
L_476F:
	dec l			;476f   ; una fila menos
	jr nz,L_474C		;4770
	ret			;4772
tira_de_dieciseis:
	push hl			;4773   ; A dice si hay que invertir
	ld b,010h		;4774   ; dieciseis bytes
	ld h,a			;4776
L_4777:
	push hl			;4777
	ld a,(de)			;4778
	bit 0,h		;4779   ; el bit 0 de H
	call nz,da_la_vuelta_al_byte		;477b   ; y si esta puesto, se le da la vuelta
	inc de			;477e
	out (c),a		;477f   ; al puerto del VDP
	pop hl			;4781
	djnz L_4777		;4782
	pop hl			;4784
	ret			;4785
filtro_del_byte:		; El espejo y la permuta de color
	ld a,(de)			;4786   ; el byte crudo
	inc de			;4787
	bit 7,c		;4788   ; el bit 7 de C: permuta de color
	jr nz,L_479A		;478a
	bit 0,c		;478c   ; el bit 0: espejo
	ret z			;478e   ; y sin ninguno de los dos, el byte sale tal cual
da_la_vuelta_al_byte:		; Los ocho `rr l / rla`: el espejo horizontal de una fila de pixeles
	ld h,b			;478f   ; B se guarda en H, que hace falta el contador
	ld l,a			;4790
	ld b,008h		;4791   ; ocho vueltas
L_4793:
	rr l		;4793   ; sale por abajo de L
	rla			;4795   ; y entra por arriba de A: el byte del reves
	djnz L_4793		;4796
	ld b,h			;4798
	ret			;4799
L_479A:
	ld h,a			;479a   ; el byte entero
	call permuta_un_nibble		;479b   ; se permuta el nibble bajo
	ld a,h			;479e
	and 0f0h		;479f   ; y se pega al alto
	or l			;47a1
	ld h,a			;47a2
	rrca			;47a3   ; ahora el alto
	rrca			;47a4
	rrca			;47a5
	rrca			;47a6
	call permuta_un_nibble		;47a7   ; se permuta tambien
	ld a,l			;47aa
	rlca			;47ab   ; y vuelve a su sitio
	rlca			;47ac
	rlca			;47ad
	rlca			;47ae
	ld l,a			;47af
	ld a,h			;47b0
	and 00fh		;47b1   ; el bajo que ya se permuto
	or l			;47b3
	ret			;47b4
permuta_un_nibble:
	and 00fh		;47b5
	cp 00ch		;47b7   ; el 12 siempre pasa a 6
	ld l,006h		;47b9
	ret z			;47bb
	bit 0,c		;47bc   ; y con el bit 0 tambien puesto
	jr z,L_47CC		;47be
	cp 00ah		;47c0   ; el 10 se queda
	ret z			;47c2
	cp l			;47c3   ; el 6 pasa a 12
	ld l,00ch		;47c4
	ret z			;47c6
	cp 005h		;47c7   ; y el 5 a 9
	ld l,009h		;47c9
	ret z			;47cb
L_47CC:
	ld l,a			;47cc   ; lo demas, igual
	ret			;47cd
prepara_la_maquina:
	ld a,0bfh		;47ce   ; el PSG callado
	call escribe_el_mezclador		;47d0
	ld a,0f7h		;47d3   ; y la pantalla apagada... o eso pretende: 0x40FB escribe sobre la ROM
	call apaga_la_pantalla		;47d5
	xor a			;47d8
	ld l,a			;47d9
	ld h,a			;47da
	ld c,a			;47db
	ld b,040h		;47dc   ; los 0x4000 bytes de la VRAM
	call 00056h		;47de   ; BIOS FILVRM - Fills VRAM with value
escribe_los_registros_del_vdp:		; Del 7 al 0, o sea al reves de como esta la tabla
	ld hl,047f1h		;47e1   ; la tabla de registros
	ld c,008h		;47e4   ; ocho, y se escriben del 7 al 0
L_47E6:
	ld a,c			;47e6
	and a			;47e7
	ret z			;47e8
	dec c			;47e9
	ld b,(hl)			;47ea
	call 00047h		;47eb   ; BIOS WRTVDP - Writes data in the VDP-register
	inc hl			;47ee
	jr L_47E6		;47ef

; ----------------------------------------------------------------------
; DATOS registros_del_vdp: Los ocho registros, escritos del 7 al 0 por 0x47E1
;   (`ld c,8`, `dec c`): R7=0xE4 tinta 14 sobre fondo 4, R6=0x03 patrones de
;   sprite en 0x1800, R5=0x76 atributos en 0x3B00, R4=0x07 y R3=0x7F que en
;   SCREEN 2 son base y mascara -patrones en 0x2000 y color en 0x0000, al
;   reves de lo corriente-, R2=0x0E nombres en 0x3800, R1=0xE2 con sprites de
;   16x16 y R0=0x02
;   0x47f1..0x47f9  (8 bytes)
DATA_registros_del_vdp:
	defb 0e4h	; 47f1
	defb 003h	; 47f2
	defb 076h	; 47f3
	defb 007h	; 47f4
	defb 07fh	; 47f5
	defb 00eh	; 47f6
	defb 0e2h	; 47f7
	defb 002h	; 47f8

; ======================================================================
; CODIGO 0x47f9..0x48b4  (187 bytes)
; ======================================================================


fondo_negro:
	ld b,0e0h		;47f9   ; registro 7 a 0xE0: fondo negro
pon_el_registro_siete:
	ld c,007h		;47fb
	jp pon_registro_del_vdp		;47fd
lo_de_cada_cuadro:
	call lee_el_mando_del_uno		;4800   ; el mando
	ld hl,0e007h		;4803   ; y lo que ACABA de pulsarse
	call guarda_lo_que_acaba_de_pulsarse		;4806
	ld a,(0e000h)		;4809   ; de la escena 4 en adelante
	cp 004h		;480c
	jr c,L_4814		;480e
	call es_el_segundo_jugador		;4810   ; solo si juegan dos
	ret z			;4813
L_4814:
	call lee_el_mando_del_dos		;4814   ; se lee tambien el segundo mando
	ld hl,0e009h		;4817
guarda_lo_que_acaba_de_pulsarse:
	ld c,(hl)			;481a   ; el estado anterior
	ld (hl),a			;481b
	xor c			;481c   ; lo que ha cambiado
	and (hl)			;481d
	dec hl			;481e   ; el estado de antes
	ld (hl),a			;481f   ; y lo pulsado nuevo, en la de al lado
	ret			;4820

; ----------------------------------------------------------------------
; LOS DOS MANDOS. Cada jugador se lee dos veces: el joystick por el registro 14 del PSG y el teclado por SNSMAT, y las dos lecturas se juntan con un `or`. El resultado es un byte de banderas -arriba, abajo, izquierda, derecha, gatillo, segundo gatillo, START- que el resto del juego mira sin saber de donde vino.
; ----------------------------------------------------------------------
lee_el_mando_del_uno:
	ld e,08fh		;4821   ; el puerto A del PSG a entrada, el B a salida: el mando 1
	ld a,00fh		;4823
	call 00093h		;4825   ; BIOS WRTPSG - Writes data to PSG-register
	call lee_el_joystick		;4828   ; y el joystick
	push af			;482b
	ld a,008h		;482c   ; linea 8 del teclado
	call 00141h		;482e   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;4831   ; las teclas van a cero cuando se pulsan
	rrca			;4832   ; dos vueltas
	rrca			;4833
	ld b,a			;4834   ; lo leido, a salvo
	and 004h		;4835   ; el bit de una direccion
	ld e,a			;4837   ; se va juntando en E
	ld a,b			;4838
	rrca			;4839   ; dos vueltas mas
	rrca			;483a
	ld b,a			;483b
	and 018h		;483c   ; dos direcciones de golpe
	or e			;483e
	ld e,a			;483f
	ld a,b			;4840
	rrca			;4841   ; una vuelta mas
	and 003h		;4842
	or e			;4844
	ld e,a			;4845
	ld a,006h		;4846   ; linea 6: los cursores
	call 00141h		;4848   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;484b
	rlca			;484c
	rlca			;484d
	and 080h		;484e
	or e			;4850
	ld e,a			;4851
	ld a,004h		;4852   ; linea 4
	call 00141h		;4854   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;4857
	rlca			;4858
	jr pega_el_ultimo_bit		;4859
lee_el_mando_del_dos:
	ld e,0cfh		;485b   ; el mando 2
	ld a,00fh		;485d   ; el registro 15 del PSG
	call 00093h		;485f   ; BIOS WRTPSG - Writes data to PSG-register
	call lee_el_joystick		;4862   ; primero el joystick, que ya trae las direcciones
	push af			;4865   ; lo leido, a la pila
	ld a,005h		;4866   ; linea 5
	call 00141h		;4868   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;486b   ; la matriz viene invertida
	ld (0e063h),a		;486c   ; se guarda entera: de aqui salen los bits de servicio
	rlca			;486f   ; el bit al sitio
	rlca			;4870
	and 004h		;4871   ; el disparo del dos
	ld e,a			;4873   ; y se va juntando en E
	ld a,003h		;4874   ; linea 3
	call 00141h		;4876   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;4879
	ld b,a			;487a   ; la linea 3, a salvo
	and 008h		;487b   ; otra tecla del dos
	or e			;487d   ; se acumula
	ld e,a			;487e
	ld a,b			;487f
	rlca			;4880   ; la siguiente al sitio
	ld b,a			;4881
	and 002h		;4882   ; y otra mas
	or e			;4884
	ld e,a			;4885
	ld a,b			;4886
	rrca			;4887   ; tres vueltas
	rrca			;4888
	rrca			;4889
	and 001h		;488a   ; el ultimo bit
	or e			;488c
	ld e,a			;488d
	ld a,006h		;488e   ; linea 6
	call 00141h		;4890   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;4893
	rlca			;4894   ; tres vueltas tambien
	rlca			;4895
	rlca			;4896
	and 010h		;4897
	or e			;4899
	ld e,a			;489a
	ld a,007h		;489b   ; linea 7: el espacio
	call 00141h		;489d   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;48a0
pega_el_ultimo_bit:
	rlca			;48a1   ; el ultimo bit, el del gatillo
	rlca			;48a2
	and 020h		;48a3
	or e			;48a5
	pop bc			;48a6   ; y se le pega lo que dijo el joystick
	or b			;48a7
	ret			;48a8
lee_el_joystick:
	ld a,00eh		;48a9   ; el registro 14: el puerto de mando
	di			;48ab   ; RDPSG no admite interrupcion por medio
	call 00096h		;48ac   ; BIOS RDPSG - Reads value from PSG-register
	ei			;48af
	cpl			;48b0   ; tambien al reves
	and 03fh		;48b1   ; seis bits: cuatro direcciones y dos gatillos
	ret			;48b3

; ----------------------------------------------------------------------
; DATOS cartel_de_konami: El bloque comprimido del cartel que baja en la
;   presentacion; trae su destino dentro (0x394A)
;   0x48b4..0x48c5  (17 bytes)
DATA_cartel_de_konami:
	defb 04ah,039h,00ch,05ah,080h,06ch,039h,088h,026h,02eh,01fh,027h,029h,02fh,034h,032h	; 48b4  J9.Z.l9.&..')/42
	defb 000h	; 48c4

; ----------------------------------------------------------------------
; DATOS textos_del_titulo: Los dos guiones que 0x4C08 suelta uno detras de
;   otro: (C) KONAMI 1986, PLAY SELECT, 1 PLAYER y 2 PLAYERS
;   0x48c5..0x48fc  (55 bytes)
DATA_textos_del_titulo:
	defb 029h,039h,01ah,022h,02eh,024h,02fh,031h,021h,000h,000h,011h,019h,018h,016h,0feh	; 48c5  )9.".$/1!.......
	defb 0abh,039h,025h,023h,02fh,02ah,000h,026h,032h,023h,032h,01dh,027h,0feh,00dh,03ah	; 48d5  .9%#/*.&2#2.'..:
	defb 011h,000h,025h,023h,02fh,02ah,032h,034h,0ffh,04dh,03ah,012h,000h,025h,023h,02fh	; 48e5  ..%#/*24.M:..%#/
	defb 02ah,032h,034h,026h,0ffh,01bh,0ffh	; 48f5

; ----------------------------------------------------------------------
; DATOS guiones_de_la_partida: Los rotulos del marcador y los avisos, cada uno
;   con su direccion dentro: HI SCORE, 1P SCORE, 2P SCORE, REST, STAGE y el
;   CONGRATULATION! de 0x4933. 0x4258, 0x4261 y 0x4272 eligen entre la pareja
;   de cada uno segun el jugador que toque
;   0x48fc..0x49aa  (174 bytes)
DATA_guiones_de_la_partida:
	defb 047h,0eeh,012h,025h,000h,026h,01dh,02eh,034h,032h,0feh,0a7h,0edh,011h,025h,000h	; 48fc  G..%.&..42....%.
	defb 026h,01dh,02eh,034h,032h,0feh,047h,0edh,020h,021h,000h,026h,01dh,02eh,034h,032h	; 490c  &..42.G. !.&..42
	defb 0ffh,08bh,0eeh,034h,032h,026h,027h,0feh,0ebh,0edh,034h,032h,026h,027h,0ffh,0ech	; 491c  ...42&'...42&'..
	defb 0ech,026h,027h,02fh,02dh,032h,0ffh,0e8h,0ech,01dh,02eh,024h,02dh,034h,02fh,027h	; 492c  .&'/-2.....$-4/'
	defb 028h,023h,02fh,027h,021h,02eh,024h,02ch,0ffh,05dh,049h,0a8h,049h,064h,049h,0a8h	; 493c  (#/'!.$,.]I.IdI.
	defb 049h,076h,049h,0a8h,049h,088h,049h,0a8h,049h,0a8h,049h,09ah,049h,0a8h,049h,0a8h	; 494c  IvI.I.I.I.I.I.I.
	defb 049h,00dh,026h,027h,02fh,01fh,01fh,0ffh,008h,02fh,022h,021h,02bh,024h,02fh,000h	; 495c  I.&'/..../"!+$/.
	defb 000h,000h,020h,021h,026h,02fh,032h,02bh,021h,0ffh,008h,020h,021h,034h,02eh,02bh	; 496c  .. !&/2+!.. !4.+
	defb 01fh,000h,000h,000h,026h,02fh,027h,02eh,032h,02bh,027h,0ffh,008h,021h,026h,02fh	; 497c  ....&/'.2+'..!&/
	defb 02eh,02bh,02fh,000h,000h,000h,02ah,02eh,026h,020h,021h,02bh,026h,0ffh,009h,01ah	; 498c  .+/...*.& !+&...
	defb 022h,02eh,024h,02fh,031h,021h,000h,000h,000h,011h,019h,018h,016h,0ffh	; 499c  ".$/1!........

; ======================================================================
; CODIGO 0x49aa..0x49d0  (38 bytes)
; ======================================================================


sube_la_fuente:
	call borra_la_casilla_cero		;49aa   ; la casilla 0 en blanco
	ld de,049d0h		;49ad   ; la fuente
	ld hl,02080h		;49b0
	call sube_tal_cual		;49b3
	ld a,0f0h		;49b6   ; con color blanco sobre transparente
	ld hl,00080h		;49b8
	ld bc,00158h		;49bb
	jr L_49CD		;49be
borra_la_casilla_cero:
	ld hl,02000h		;49c0   ; los patrones
	call borra_ocho_bytes		;49c3
	ld hl,00000h		;49c6   ; y el color
borra_ocho_bytes:
	ld bc,00008h		;49c9
	xor a			;49cc
L_49CD:
	jp rellena_los_tres_bancos		;49cd

; ----------------------------------------------------------------------
; DATOS fuente: Los 43 dibujos de la fuente, comprimidos. 0x49B3 los sube a
;   0x2080 -la casilla 0x10- en los tres bancos, y 0x49B6 les pone color 0xF0,
;   blanco sobre transparente. El alfabeto no esta entero: hay 0 a 9, el
;   simbolo de copyright, un punto, una admiracion y solo las letras A B C D E
;   F G H I K L M N O P R S T U V W Y, que son las que hacen falta para los
;   rotulos de este cartucho
;   0x49d0..0x4ae8  (280 bytes)
DATA_fuente:
	defb 083h,000h,01ch,022h,003h,063h,085h,022h,01ch,000h,018h,038h,004h,018h,0aeh,07eh	; 49d0  ...".c."...8...~
	defb 000h,03eh,063h,003h,00eh,03ch,070h,07fh,000h,03eh,063h,003h,00eh,003h,063h,03eh	; 49e0  .>c..<p..>c...c>
	defb 000h,00eh,01eh,036h,066h,066h,07fh,006h,000h,07fh,060h,07eh,063h,003h,063h,03eh	; 49f0  ...6ff....`~c.c>
	defb 000h,03eh,063h,060h,07eh,063h,063h,03eh,000h,07fh,063h,006h,00ch,003h,018h,0abh	; 4a00  .>c`~cc>..c.....
	defb 000h,03eh,063h,063h,03eh,063h,063h,03eh,000h,03eh,063h,063h,03fh,003h,063h,03eh	; 4a10  .>cc>cc>.>cc?.c>
	defb 03ch,042h,099h,0a1h,0a1h,099h,042h,03ch,01ch,022h,02ah,063h,03eh,03eh,07fh,06bh	; 4a20  <B....B<."*c>>.k
	defb 000h,07eh,063h,063h,07eh,063h,063h,07eh,000h,03eh,063h,003h,060h,085h,063h,03eh	; 4a30  .~cc~cc~.>c.`.c>
	defb 000h,07ch,066h,003h,063h,087h,066h,07ch,000h,07fh,060h,060h,07eh,003h,060h,081h	; 4a40  .|f.c.f|..``~.`.
	defb 000h,003h,063h,081h,07fh,003h,063h,082h,000h,03ch,005h,018h,08ah,03ch,000h,063h	; 4a50  ..c...c..<...<.c
	defb 066h,06ch,078h,07ch,06eh,067h,000h,006h,060h,08bh,07fh,000h,063h,073h,07bh,07fh	; 4a60  flx|ng..`...cs{.
	defb 06fh,067h,063h,000h,07eh,003h,063h,08dh,07eh,060h,060h,000h,03eh,063h,060h,03eh	; 4a70  ogc.~.c.~``.>c`>
	defb 003h,063h,03eh,000h,07eh,006h,018h,081h,000h,006h,063h,08eh,03eh,000h,063h,063h	; 4a80  .c>.~.....c.>.cc
	defb 06bh,06bh,07fh,077h,022h,000h,066h,066h,07eh,03ch,003h,018h,006h,000h,002h,030h	; 4a90  kk.w".ff~<.....0
	defb 081h,018h,003h,03ch,084h,018h,000h,018h,018h,08ah,000h,03eh,063h,060h,067h,063h	; 4aa0  ...<.......>c`gc
	defb 063h,03fh,000h,03eh,005h,063h,08ah,03eh,000h,01ch,036h,063h,063h,07fh,063h,063h	; 4ab0  c?.>.c.>..6cc.cc
	defb 000h,004h,063h,0a3h,036h,01ch,008h,000h,063h,077h,07fh,07fh,06bh,063h,063h,000h	; 4ac0  ..c.6...cw..kcc.
	defb 07fh,060h,060h,07eh,060h,060h,07fh,000h,07fh,060h,060h,07eh,060h,060h,07fh,000h	; 4ad0  .``~``...``~``..
	defb 07eh,063h,063h,062h,07ch,066h,063h,000h	; 4ae0  ~ccb|fc.

; ======================================================================
; CODIGO 0x4ae8..0x4b3c  (84 bytes)
; ======================================================================


arranca_la_presentacion:		; Catorce pasos, empezando por la ultima fila
	ld a,00eh		;4ae8
	ld (0e00ah),a		;4aea
	ld hl,03aaah		;4aed
	ld (0e00dh),hl		;4af0
	jp arranca_la_pantalla_del_titulo		;4af3
monta_el_cartel:
	ld de,04b3ch		;4af6   ; las 27 casillas del rotulo
	ld hl,02200h		;4af9
	call sube_tal_cual		;4afc
	ld hl,00200h		;4aff   ; y su color, blanco sobre transparente
	ld bc,000d8h		;4b02
	ld a,0f0h		;4b05
	jp rellena_los_tres_bancos		;4b07
baja_un_paso:		; Repinta el rotulo una fila mas arriba y borra la de abajo
	ld hl,(0e00dh)		;4b0a
	ld de,0ffe0h		;4b0d   ; 0x20 casillas atras: una fila mas arriba
	add hl,de			;4b10
	ld (0e00dh),hl		;4b11
	ld a,040h		;4b14   ; el rotulo, tres casillas
	ld b,003h		;4b16
	call escribe_seguidas		;4b18
	ld bc,00b0ch		;4b1b   ; once del relleno
	call escribe_seguidas		;4b1e
	ld b,c			;4b21   ; y otras once
	call escribe_seguidas		;4b22
	xor a			;4b25   ; y la fila de abajo, a cero
	call 00056h		;4b26   ; BIOS FILVRM - Fills VRAM with value
	ld hl,0e00ah		;4b29   ; un paso menos
	dec (hl)			;4b2c
	ret			;4b2d
escribe_seguidas:
	push hl			;4b2e
L_4B2F:
	call 0004dh		;4b2f   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;4b32
	inc a			;4b33
	djnz L_4B2F		;4b34
	pop de			;4b36
	ld hl,00020h		;4b37
	add hl,de			;4b3a
	ret			;4b3b

; ----------------------------------------------------------------------
; DATOS logotipo: Las 27 casillas del rotulo TWIN BEE, comprimidas. 0x4AFC las
;   sube a 0x2200 -la casilla 0x40- en los tres bancos, y 0x4AFF les pone
;   color 0xF0
;   0x4b3c..0x4bd3  (151 bytes)
DATA_logotipo:
	defb 00fh,000h,001h,001h,006h,000h,082h,0ffh,0feh,008h,00fh,084h,0c3h,0c7h,0cfh,0dfh	; 4b3c  ................
	defb 003h,0ffh,089h,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,007h,007h,005h,000h,083h,003h	; 4b4c  ................
	defb 0cfh,0dfh,005h,000h,083h,0e1h,0f9h,07dh,005h,000h,083h,0efh,0ffh,0f7h,005h,000h	; 4b5c  .......}........
	defb 083h,007h,08fh,09eh,005h,000h,083h,0f0h,0f8h,078h,005h,000h,083h,0f7h,0ffh,0fbh	; 4b6c  .........x......
	defb 005h,000h,08bh,08fh,0dfh,0f7h,00ch,01eh,01eh,00ch,000h,01eh,09eh,09eh,008h,00fh	; 4b7c  ................
	defb 090h,0ffh,0ffh,0dfh,0cfh,0c7h,0c3h,0c1h,0c0h,007h,087h,0c7h,0efh,0ffh,0ffh,0ffh	; 4b8c  ................
	defb 0fch,004h,0deh,084h,09eh,09fh,00fh,003h,005h,03dh,083h,07dh,0f9h,0e1h,008h,0e3h	; 4b9c  .........=.}....
	defb 090h,0dch,0c0h,0c7h,0deh,0dch,0deh,0cfh,0c3h,03ch,07ch,0fch,03ch,03ch,07ch,0fch	; 4bac  .........<|.<<|.
	defb 0deh,008h,0f1h,008h,0e3h,008h,0deh,088h,038h,044h,0bah,0aah,0b2h,0aah,044h,038h	; 4bbc  ........8D....D8
	defb 003h,000h,001h,0ffh,004h,000h,000h	; 4bcc

; ======================================================================
; CODIGO 0x4bd3..0x4c35  (98 bytes)
; ======================================================================


monta_el_titulo:		; Fondo azul, pantalla limpia, la fuente, el dibujo grande y los dos rotulos
	ld b,0e4h		;4bd3
	call pon_el_registro_siete		;4bd5   ; fondo azul
	call limpia_la_pantalla		;4bd8   ; pantalla limpia
	call sube_la_fuente		;4bdb   ; la fuente
	ld de,04c35h		;4bde   ; el dibujo grande
	call sube_bloque		;4be1
	ld hl,00600h		;4be4   ; y su color, en un solo banco
	ld bc,00108h		;4be7
	ld a,080h		;4bea
	call 00056h		;4bec   ; BIOS FILVRM - Fills VRAM with value
	ld hl,038aah		;4bef   ; tres filas de once casillas
	ld de,00020h		;4bf2
	ld a,0c0h		;4bf5
	ld c,003h		;4bf7
L_4BF9:
	ld b,00bh		;4bf9
	push hl			;4bfb
L_4BFC:
	call 0004dh		;4bfc   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;4bff
	inc a			;4c00
	djnz L_4BFC		;4c01
	pop hl			;4c03
	add hl,de			;4c04
	dec c			;4c05
	jr nz,L_4BF9		;4c06
	ld de,048c5h		;4c08   ; y los dos rotulos
	call guion_de_texto		;4c0b
	jp guion_de_texto		;4c0e
parpadea_la_eleccion:
	ld hl,0e004h		;4c11
	bit 3,(hl)		;4c14
	ld c,0ffh		;4c16
	jr nz,marca_la_eleccion		;4c18
	inc c			;4c1a
marca_la_eleccion:
	ld hl,03a0bh		;4c1b   ; las dos filas de la eleccion
	ld de,03a4bh		;4c1e   ; la de abajo
	ld a,(0e062h)		;4c21   ; y la que este marcada
	or a			;4c24
	jr z,L_4C28		;4c25
	ex de,hl			;4c27
L_4C28:
	push de			;4c28   ; la que NO esta marcada, a salvo
	call escribe_la_flecha		;4c29   ; se le pinta la flecha
	pop hl			;4c2c
	ld c,000h		;4c2d   ; y con C a cero, se borra de la otra
escribe_la_flecha:
	ld de,048fah		;4c2f   ; el guion de la flecha
	jp L_46B2		;4c32

; ----------------------------------------------------------------------
; DATOS guion_del_titulo: El dibujo grande de la pantalla del titulo -el
;   rotulo TwinBee dibujado y el (C) KONAMI 1986-, comprimido y con su destino
;   dentro (0x2600)
;   0x4c35..0x4d1e  (233 bytes)
DATA_guion_del_titulo:
	defb 000h,026h,003h,000h,085h,07fh,0ffh,0ffh,07fh,001h,003h,000h,004h,0ffh,081h,0f0h	; 4c35  .&..............
	defb 003h,000h,084h,0e0h,0f0h,0f0h,0e0h,005h,000h,003h,001h,004h,000h,081h,0c0h,003h	; 4c45  ................
	defb 0e0h,081h,0c0h,00bh,000h,085h,01fh,03fh,03fh,01fh,003h,003h,000h,004h,0ffh,081h	; 4c55  .......??.......
	defb 087h,004h,000h,002h,080h,002h,0c0h,010h,000h,083h,001h,003h,003h,003h,007h,002h	; 4c65  ................
	defb 00fh,0a8h,0e0h,0e6h,0efh,0cfh,0ceh,08eh,08eh,09eh,000h,030h,079h,079h,07bh,0f3h	; 4c75  ...........0yy{.
	defb 0f7h,0f7h,000h,0c3h,0e7h,0e7h,0cfh,09eh,09eh,03ch,000h,00ch,09dh,09fh,03fh,07ch	; 4c85  .........<....?|
	defb 078h,0f1h,000h,070h,0f8h,0f8h,0f0h,0f1h,0f3h,0e7h,003h,007h,002h,00fh,0a5h,01fh	; 4c95  x..p............
	defb 09eh,09eh,08fh,01fh,0feh,0fch,0feh,0feh,03fh,00fh,080h,007h,00fh,01ch,038h,030h	; 4ca5  ........?.....80
	defb 070h,060h,000h,0e0h,0f1h,0f3h,077h,076h,06eh,0ech,000h,0fch,0feh,09eh,00eh,00eh	; 4cb5  p`....wvn.......
	defb 00ch,01ch,01fh,01fh,003h,03eh,083h,03ch,018h,000h,005h,01fh,0cbh,01eh,00ch,000h	; 4cc5  .....>.<........
	defb 0efh,0feh,0fch,0fch,0f9h,0f9h,070h,000h,03ch,079h,0f3h,0f3h,0e7h,0e7h,0c3h,000h	; 4cd5  ......p.<y......
	defb 0f1h,0e3h,0c3h,0c3h,083h,083h,001h,000h,0efh,0dfh,0feh,0fch,0f8h,0e0h,080h,000h	; 4ce5  ................
	defb 03ch,03ch,078h,078h,0ffh,0ffh,07fh,000h,00fh,00fh,01eh,07eh,0fch,0f8h,0c0h,000h	; 4cf5  <<xx.......~....
	defb 063h,07fh,07fh,07ch,07fh,03fh,01eh,000h,0d4h,0bbh,077h,0efh,0cfh,087h,003h,000h	; 4d05  c..|.?....w.....
	defb 07ah,0f7h,0efh,09eh,0fch,0f0h,0c0h,000h,000h	; 4d15  z........

; ======================================================================
; CODIGO 0x4d1e..0x510e  (1008 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; PEDIR UN SONIDO. Por aqui entra todo lo que suena. Hay dos puertas: 0x4D1E solo suena si el bit 6 de los bits de modo esta puesto -o sea, no en la demostracion- y 0x4D29 suena siempre. El numero que se pide lleva la melodia en los seis bits bajos y la PRIORIDAD en los dos altos: si lo que ya esta sonando manda mas, la peticion se descarta.
; ----------------------------------------------------------------------
pide_un_sonido_si_se_juega:
	di			;4d1e   ; el bit 6 de los bits de modo
	push hl			;4d1f
	ld hl,0e002h		;4d20
	bit 6,(hl)		;4d23
	jr z,L_4D34		;4d25   ; en la demostracion no suena nada
	jr L_4D2B		;4d27
pide_un_sonido:
	di			;4d29
	push hl			;4d2a
L_4D2B:
	push de			;4d2b
	push bc			;4d2c
	push af			;4d2d
	call elige_la_melodia		;4d2e   ; y se pide
	pop af			;4d31
	pop bc			;4d32
	pop de			;4d33
L_4D34:
	pop hl			;4d34
	ei			;4d35
	ret			;4d36
elige_la_melodia:
	cp 0d5h		;4d37   ; la melodia 0xD5 es la de la pausa
	jr nz,L_4D45		;4d39
	ld hl,0e036h		;4d3b   ; que se guarda el canal entero para devolverlo luego
	ld de,0e049h		;4d3e
	call guarda_el_canal		;4d41
	ld a,c			;4d44
L_4D45:
	ld c,a			;4d45   ; el numero pedido
	ld d,000h		;4d46
	ld hl,0e012h		;4d48
	cp 0c5h		;4d4b   ; las de 0xC5 y 0xD5
	jr z,L_4D5B		;4d4d
	cp 0d5h		;4d4f
	jr z,L_4D5B		;4d51
	and 0c0h		;4d53   ; y las de prioridad 0 o 3
	jr z,L_4D5D		;4d55
	cp 0c0h		;4d57
	jr z,L_4D5D		;4d59
L_4D5B:
	ld l,038h		;4d5b   ; van al canal de arriba
L_4D5D:
	ld b,002h		;4d5d   ; dos canales
	ld a,c			;4d5f
	and 03fh		;4d60   ; la melodia sola
	cp 016h		;4d62   ; las de menos de 0x16 gastan uno
	jr c,L_4D6D		;4d64
	cp 022h		;4d66   ; las de 0x22 arriba, tres
	jr c,L_4D6E		;4d68
	inc b			;4d6a
	jr L_4D6E		;4d6b
L_4D6D:
	dec b			;4d6d
L_4D6E:
	ld a,(hl)			;4d6e   ; lo que esta sonando
	cp 08fh		;4d6f   ; 0x8F es "no hay nada"
	jr nz,L_4D74		;4d71
	ld d,a			;4d73
L_4D74:
	and 03fh		;4d74   ; la prioridad, sin los dos bits altos
	ld e,a			;4d76   ; a E
	ld a,c			;4d77   ; la melodia que se pide
	cp 0d5h		;4d78   ; la de la pausa entra siempre
	jr z,L_4D99		;4d7a
	cp d			;4d7c   ; y si es la misma, no se repite
	ret z			;4d7d
	and 03fh		;4d7e   ; tambien sin los dos bits altos
	ld d,a			;4d80
	cp 014h		;4d81   ; tres melodias se cuelan una posicion mas arriba
	jr z,L_4D94		;4d83
	cp 016h		;4d85
	jr z,L_4D8E		;4d87
	cp 025h		;4d89
	jr nz,L_4D90		;4d8b
	inc a			;4d8d   ; una mas
L_4D8E:
	inc a			;4d8e   ; y dos mas
	inc a			;4d8f
L_4D90:
	cp e			;4d90   ; y si la que suena manda mas, no se cambia
	ret c			;4d91
	jr L_4D98		;4d92
L_4D94:
	ld a,e			;4d94
	cp 02bh		;4d95
	ret nc			;4d97
L_4D98:
	ld a,d			;4d98
L_4D99:
	and 03fh		;4d99
	add a,a			;4d9b
	ld de,05118h		;4d9c   ; la tabla de partituras
	call suma_a_a_de		;4d9f
	dec l			;4da2
	dec l			;4da3
monta_los_canales:
	ld (hl),001h		;4da4   ; el canal, en marcha
	inc l			;4da6   ; dos bytes adelante
	inc l			;4da7
	ld (hl),c			;4da8   ; con su numero
	inc l			;4da9   ; al puntero de la partitura
	ld a,(de)			;4daa   ; y el puntero a la partitura
	ld (hl),a			;4dab
	inc l			;4dac
	inc de			;4dad
	ld a,(de)			;4dae   ; y el alto
	ld (hl),a			;4daf
	ld a,006h		;4db0   ; seis bytes mas alla
	add a,l			;4db2
	ld l,a			;4db3
	xor a			;4db4   ; sin nota puesta
	ld (hl),a			;4db5
	ld a,005h		;4db6   ; cinco mas: el canal siguiente
	add a,l			;4db8
	ld l,a			;4db9
	ld (hl),001h		;4dba   ; el siguiente canal
	inc l			;4dbc   ; dos bytes adelante
	inc l			;4dbd
	xor a			;4dbe   ; la nota, a cero
	ld (hl),a			;4dbf
	inc l			;4dc0
	ld (hl),a			;4dc1
	inc l			;4dc2
	inc de			;4dc3   ; la partitura siguiente
	djnz monta_los_canales		;4dc4   ; los canales que pidan
	ret			;4dc6
guarda_el_canal:
	ld bc,00013h		;4dc7   ; los 0x13 bytes del canal
	ldir		;4dca   ; de un juego al otro
	ld c,a			;4dcc   ; el numero que traia
	xor a			;4dcd
	ld (0e05fh),a		;4dce   ; y se suelta la marca de ocupado
	ret			;4dd1
el_paso_de_la_nota:
	inc hl			;4dd2   ; el byte de la partitura
	ld a,(hl)			;4dd3
	or a			;4dd4   ; un cero es un salto
	jr nz,L_4DE6		;4dd5
	ld a,003h		;4dd7
	call suma_a_a_hl		;4dd9   ; tres bytes atras: el bucle
	ld (ix+011h),l		;4ddc
	ld (ix+012h),h		;4ddf
	dec hl			;4de2
	dec hl			;4de3
	jr L_4DF5		;4de4
L_4DE6:
	ld a,(ix+00ah)		;4de6   ; el desliz hacia la nota nueva
	inc a			;4de9
	cp (hl)			;4dea   ; al llegar
	jr z,L_4E00		;4deb
	jp m,L_4DF1		;4ded
	dec a			;4df0
L_4DF1:
	ld (ix+00ah),a		;4df1
	inc hl			;4df4
L_4DF5:
	ld a,(hl)			;4df5   ; el byte de la nota
	ld (ix+003h),a		;4df6
	inc hl			;4df9   ; y el siguiente
	ld a,(hl)			;4dfa
	ld (ix+004h),a		;4dfb
	jr L_4E09		;4dfe
L_4E00:
	inc hl			;4e00
	inc hl			;4e01
	xor a			;4e02   ; se para el desliz
	ld (ix+00ah),a		;4e03
	call avanza_la_partitura		;4e06
L_4E09:
	inc (ix+000h)		;4e09   ; y un paso mas de la partitura
	jp sigue_la_partitura		;4e0c
pon_el_mezclador:
	ld a,(0e05ch)		;4e0f   ; el mezclador que hay puesto
	ld e,a			;4e12
	ld a,(ix+005h)		;4e13
	and 003h		;4e16   ; los dos bits de este canal: tono y ruido
	ld d,a			;4e18
	ld a,c			;4e19
	cp 001h		;4e1a
	jr z,L_4E1F		;4e1c
	dec a			;4e1e
L_4E1F:
	ld b,a			;4e1f   ; el numero de canal
	bit 1,d		;4e20   ; el bit 1: hay tono
	call z,enciende_el_bit		;4e22   ; se enciende
	bit 1,d		;4e25
	call nz,apaga_el_bit		;4e27   ; o se apaga
	ld a,b			;4e2a
	rlca			;4e2b   ; tres huecos a la izquierda: los bits de ruido
	rlca			;4e2c
	rlca			;4e2d
	bit 0,d		;4e2e
	call z,enciende_el_bit		;4e30
	bit 0,d		;4e33
	call nz,apaga_el_bit		;4e35
escribe_el_mezclador:
	ld (0e05ch),a		;4e38   ; se guarda
	ld e,a			;4e3b
	ld a,007h		;4e3c   ; y al registro 7 del PSG
	jp 00093h		;4e3e   ; BIOS WRTPSG - Writes data to PSG-register
apaga_el_bit:
	cpl			;4e41
	and e			;4e42
	ld e,a			;4e43
	ret			;4e44
enciende_el_bit:
	or e			;4e45
	ld e,a			;4e46
	ret			;4e47
el_reproductor:		; Lo que suena en cada interrupcion: tres canales de tono y uno de ruido
	ld a,(0e05ch)		;4e48   ; el mezclador, otra vez
	call escribe_el_mezclador		;4e4b
	ld c,001h		;4e4e   ; el numero de registro del primer canal
	ld ix,0e010h		;4e50   ; el primer canal
	exx			;4e54   ; el juego de repuesto lleva la cuenta
	ld b,003h		;4e55   ; tres canales
	ld de,00013h		;4e57   ; de 0x13 bytes
L_4E5A:
	exx			;4e5a   ; y se vuelve al normal para trabajar
	ld a,c			;4e5b
	cp 005h		;4e5c   ; el canal 5, que es el del ruido
	jr nz,canal_de_la_pausa		;4e5e
	ld a,(0e05fh)		;4e60   ; con la pausa puesta
	or a			;4e63
	jr z,L_4E75		;4e64
	ld h,000h		;4e66   ; con volumen cero
	call escribe_el_volumen		;4e68
	ld a,c			;4e6b   ; el canal
	ld hl,0e049h		;4e6c   ; se devuelve lo que se habia guardado
	ld de,0e036h		;4e6f
	call guarda_el_canal		;4e72
L_4E75:
	ld a,(ix+002h)		;4e75   ; la melodia que lleva
	or a			;4e78   ; sin melodia, se calla
	jr nz,L_4E80		;4e79
	call acaba_la_melodia		;4e7b   ; se calla
	jr L_4E83		;4e7e
L_4E80:
	call sigue_la_partitura		;4e80   ; y si la tiene, sigue su partitura
L_4E83:
	inc c			;4e83   ; dos numeros de registro por canal
	inc c			;4e84
	exx			;4e85   ; al de repuesto
	add ix,de		;4e86   ; 0x13 bytes hasta el canal siguiente
	djnz L_4E5A		;4e88
	ret			;4e8a
canal_de_la_pausa:
	ld a,(0e079h)		;4e8b   ; en pausa no avanza nada
	or a			;4e8e
	jr z,el_avance_de_la_melodia		;4e8f
	ld h,000h		;4e91   ; con volumen cero: se calla
	call escribe_el_volumen		;4e93
	jr L_4E83		;4e96
el_avance_de_la_melodia:
	ld a,(0e05eh)		;4e98   ; la melodia de fondo
	or a			;4e9b
	jr z,L_4EE1		;4e9c
	dec (ix+00fh)		;4e9e   ; su reloj
	jr nz,L_4E75		;4ea1   ; mientras dure, la partitura sigue
	inc (ix+010h)		;4ea3   ; un paso mas
	ld a,04ah		;4ea6   ; con 0x4A cuadros por paso
	ld (ix+00fh),a		;4ea8
	ld a,(ix+010h)		;4eab
	cp 003h		;4eae   ; tres pasos
	jr c,L_4E75		;4eb0
	ld a,015h		;4eb2   ; y 0x15 a partir del tercero
	ld (ix+00fh),a		;4eb4
	ld a,(ix+010h)		;4eb7   ; el paso
	cp 004h		;4eba   ; el cuarto baja el tono
	call z,baja_el_tono		;4ebc
	ld a,(ix+010h)		;4ebf
	cp 005h		;4ec2
	jr c,L_4E75		;4ec4
	ld a,(0e077h)		;4ec6   ; y al quinto, se acaba
	and a			;4ec9   ; con jugadores vivos no se apaga
	jr nz,L_4ECF		;4eca
	ld (0e05eh),a		;4ecc
L_4ECF:
	ld a,(0e05eh)		;4ecf   ; la melodia de fondo pasa a primer plano
	ld (0e05dh),a		;4ed2
	call pide_si_no_suena_ya		;4ed5   ; y se pide, si no suena ya
	cp 0f7h		;4ed8   ; y si era la del final, se calla
	ld a,000h		;4eda
	jr nz,L_4EE1		;4edc
	ld (0e05dh),a		;4ede
L_4EE1:
	ld (ix+010h),a		;4ee1   ; el paso, a cero
	ld (0e05eh),a		;4ee4   ; y la melodia de fondo, fuera
	inc a			;4ee7
	ld (ix+00fh),a		;4ee8   ; con el reloj a uno
	jr L_4E75		;4eeb
baja_el_tono:
	ld a,(ix+002h)		;4eed
	and 03fh		;4ef0   ; la melodia que suena
	cp 022h		;4ef2   ; las de 0x22 arriba no bajan de tono
	ret nc			;4ef4
	jp L_4FC3		;4ef5
sigue_la_partitura:
	ld a,(ix+002h)		;4ef8   ; los dos bits altos del numero
	and 0c0h		;4efb   ; los dos bits altos
	cp 0c0h		;4efd   ; con los dos puestos, es efecto y no melodia
	jp z,el_paso_de_un_efecto		;4eff
	dec (ix+000h)		;4f02   ; la cuenta de la nota
	ret nz			;4f05

; ----------------------------------------------------------------------
; EL LENGUAJE DE LAS PARTITURAS. Cada paso es un byte de mando y sus argumentos: 0xFE salta a otro sitio, 0xFF y arriba acaban la melodia, un byte de nibble alto 2 cambia la forma de la onda y de paso la duracion, uno de nibble alto 1 pone la envolvente del PSG, y cualquier otro es una NOTA -el nibble alto es el volumen y el bajo la octava, con el byte siguiente de codigo de nota-.
; ----------------------------------------------------------------------
lee_el_paso:
	ld l,(ix+003h)		;4f06   ; por donde va la partitura
	ld h,(ix+004h)		;4f09
	ld a,(hl)			;4f0c   ; el byte de mando
	cp 0feh		;4f0d   ; 0xFE es "salta"
	jp z,el_paso_de_la_nota		;4f0f
	jp nc,acaba_la_melodia		;4f12   ; y de 0xFF arriba, se acabo
	ld a,(ix+002h)		;4f15   ; los dos bits altos del numero
	and 0c0h		;4f18
	cp 0c0h		;4f1a
	ld a,(hl)			;4f1c
	jp z,lee_una_nota		;4f1d   ; con los dos, es un efecto y va por otro lado
	and 0f0h		;4f20   ; el nibble alto del mando
	cp 020h		;4f22   ; el 2 cambia el instrumento
	jr nz,L_4F52		;4f24
	ld a,(hl)			;4f26
	ld (ix+005h),a		;4f27   ; la forma de la onda
	inc hl			;4f2a
	ld a,(hl)			;4f2b
	ld (ix+001h),a		;4f2c   ; y la duracion
	inc hl			;4f2f
	ld a,(ix+005h)		;4f30
	cp 020h		;4f33   ; con 0x20 exacto, solo silencio
	jr nz,L_4F3C		;4f35
	dec hl			;4f37   ; se retrocede un byte
	ld b,000h		;4f38   ; sin volumen
	jr L_4F6C		;4f3a
L_4F3C:
	bit 3,(ix+005h)		;4f3c   ; el bit 3 trae envolvente
	jr z,L_4F52		;4f40
	ld a,(hl)			;4f42
	ld e,a			;4f43   ; el periodo bajo
	ld a,00ch		;4f44   ; registro 12 del PSG: el periodo
	call 00093h		;4f46   ; BIOS WRTPSG - Writes data to PSG-register
	inc hl			;4f49
	ld a,(hl)			;4f4a   ; y el alto
	ld e,a			;4f4b
	ld a,00bh		;4f4c   ; y el 11
	call 00093h		;4f4e   ; BIOS WRTPSG - Writes data to PSG-register
	inc hl			;4f51
L_4F52:
	ld a,(hl)			;4f52
	and 0f0h		;4f53
	cp 010h		;4f55   ; el 1 pone el ruido
	jr nz,L_4F64		;4f57
	ld a,(hl)			;4f59
	and 00fh		;4f5a   ; los cuatro bits bajos
	add a,a			;4f5c   ; por dos
	ld e,a			;4f5d
	ld a,006h		;4f5e   ; registro 6 del PSG
	call 00093h		;4f60   ; BIOS WRTPSG - Writes data to PSG-register
	inc hl			;4f63
L_4F64:
	ld a,(hl)			;4f64
	and 0f0h		;4f65   ; el volumen, en el nibble alto
	ld b,a			;4f67   ; el volumen, a salvo en B
	xor (hl)			;4f68   ; y la octava en el bajo
	ld d,a			;4f69
	inc hl			;4f6a
	ld e,(hl)			;4f6b   ; con el codigo de nota detras
L_4F6C:
	call avanza_la_partitura		;4f6c   ; se traduce a periodo
	ex de,hl			;4f6f
	call pon_el_periodo		;4f70   ; y se escribe
	ld a,b			;4f73
	rrca			;4f74   ; el volumen, al nibble bajo
	rrca			;4f75
	rrca			;4f76
	rrca			;4f77
	ld h,a			;4f78
	ld a,(ix+001h)		;4f79   ; la duracion que puso el instrumento
	ld (ix+000h),a		;4f7c   ; con la duracion que toque
	jp escribe_el_volumen		;4f7f   ; y a sonar
acaba_la_melodia:
	ld a,(ix+012h)		;4f82   ; el sitio al que volver de un salto
	or a			;4f85
	jr z,L_4F9E		;4f86
	ld (ix+004h),a		;4f88   ; se recupera
	ld a,(ix+011h)		;4f8b   ; y el bajo
	ld (ix+003h),a		;4f8e
	xor a			;4f91
	ld (ix+00ah),a		;4f92   ; y el desliz se para
	ld (ix+011h),a		;4f95
	ld (ix+012h),a		;4f98
	jp L_4E09		;4f9b   ; con un paso mas de partitura
L_4F9E:
	ld a,c			;4f9e
	cp 005h		;4f9f   ; el canal de ruido
	jr nz,L_4FAD		;4fa1
	ld a,(ix+002h)		;4fa3   ; la melodia que suena
	cp 094h		;4fa6   ; con la melodia 0x94
	jr nz,L_4FAD		;4fa8
	call pide_si_no_suena_ya		;4faa
L_4FAD:
	ld a,c			;4fad
	cp 003h		;4fae   ; el canal 3
	jr nz,L_4FC3		;4fb0
	ld a,(ix+002h)		;4fb2   ; la melodia
	and 03fh		;4fb5
	cp 022h		;4fb7   ; y las melodias de 0x22 arriba
	ld (ix+002h),000h		;4fb9   ; el canal se apaga
	call nc,pide_si_no_suena_ya		;4fbd
	xor a			;4fc0
	jr L_4FC7		;4fc1
L_4FC3:
	xor a			;4fc3
	ld (ix+002h),a		;4fc4   ; el canal, callado
L_4FC7:
	ld h,a			;4fc7
	ld (ix+005h),a		;4fc8   ; sin instrumento
	ld (ix+00ch),a		;4fcb   ; ni desafinado
	jr escribe_el_volumen		;4fce
pide_si_no_suena_ya:
	ld a,(0e012h)		;4fd0   ; lo que suena en el canal de arriba
	ld e,a			;4fd3   ; a salvo
	ld a,(0e05dh)		;4fd4
	cp e			;4fd7   ; y si es la misma, no se pide otra vez
	ret z			;4fd8
	jp pide_un_sonido_si_se_juega		;4fd9
L_4FDC:
	dec (ix+009h)		;4fdc
L_4FDF:
	ld a,(ix+008h)		;4fdf   ; la cuenta de la nota
	dec a			;4fe2
	ret m			;4fe3   ; con la nota acabada, nada
	ld (ix+008h),a		;4fe4
	ld h,a			;4fe7
	ld a,(ix+002h)		;4fe8
	and 03fh		;4feb
	cp 022h		;4fed   ; las melodias largas
	jr nc,escribe_el_volumen		;4fef
	ld a,(0e05eh)		;4ff1   ; y el fondo puesto
	or a			;4ff4
	jr z,escribe_el_volumen		;4ff5
	ld a,(ix+010h)		;4ff7
	ld e,a			;4ffa   ; el desvanecido
	ld a,h			;4ffb
	sub e			;4ffc
	ld h,a			;4ffd
	jp m,L_5003		;4ffe   ; y por debajo de cero, se calla
	jr escribe_el_volumen		;5001
L_5003:
	ld h,000h		;5003
escribe_el_volumen:
	call pon_el_mezclador		;5005   ; el mezclador
	ld a,c			;5008   ; el numero de canal
	rrca			;5009   ; el registro de volumen del canal
	add a,088h		;500a
	ld d,a			;500c   ; 8, 9 o 10 segun el canal
	bit 3,(ix+005h)		;500d   ; con envolvente
	jr z,L_501C		;5011
	ld e,h			;5013   ; la forma va en H
	ld a,00dh		;5014   ; registro 13 del PSG: la forma
	call 00093h		;5016   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,010h		;5019   ; y el volumen pasa a ser "envolvente"
	ld h,a			;501b
L_501C:
	ld a,d			;501c   ; el registro
	ld e,h			;501d   ; y el valor
	jp 00093h		;501e   ; BIOS WRTPSG - Writes data to PSG-register | registro 8, 9 o 10
el_paso_de_un_efecto:
	dec (ix+000h)		;5021   ; la cuenta de la nota
	jp z,lee_el_paso		;5024   ; acabada, al paso siguiente
	dec (ix+009h)		;5027   ; y la del efecto
	ld a,(ix+009h)		;502a
	cp (ix+000h)		;502d   ; contra la de la nota
	jr nz,L_4FDC		;5030
	ld e,a			;5032
	ld a,(ix+00eh)		;5033   ; y contra el escalon de desvanecido
	cp e			;5036
	ld a,e			;5037
	jr nc,L_4FDF		;5038
	ret			;503a
lee_una_nota:
	ld a,(hl)			;503b   ; el nibble alto
	and 0f0h		;503c   ; el nibble alto
	cp 0d0h		;503e   ; el 0xD cambia el paso de la escala
	ld a,(hl)			;5040
	jr nz,lee_la_duracion		;5041
	and 00fh		;5043
	ld (ix+00bh),a		;5045   ; los cuatro bits bajos son el paso
	inc hl			;5048
	ld a,(hl)			;5049   ; y sigue el byte siguiente
lee_la_duracion:
	cp 0f0h		;504a   ; de 0xF0 arriba viene la duracion
	jr c,lee_el_ataque		;504c
	and 00fh		;504e   ; los cuatro bits bajos
	inc a			;5050
	ld (ix+007h),a		;5051   ; sus cuatro bits bajos, mas uno
	inc hl			;5054
	ld a,(hl)			;5055   ; el byte siguiente
	and 0f0h		;5056
	rrca			;5058   ; y el byte siguiente trae dos numeros
	rrca			;5059
	rrca			;505a
	rrca			;505b
	ld d,a			;505c   ; el alto, en D
	ld a,(hl)			;505d
	and 00fh		;505e
	ld e,a			;5060   ; y el bajo, en E
	ld a,(ix+002h)		;5061   ; la melodia que suena
	cp 0d6h		;5064   ; dos melodias concretas
	jr z,L_506C		;5066
	cp 0d8h		;5068
	jr nz,L_507E		;506a
L_506C:
	ld a,(0e05eh)		;506c   ; con el fondo puesto
	or a			;506f
	jr z,L_507E		;5070
	ld a,(ix+002h)		;5072
	cp 0d8h		;5075
	ld a,001h		;5077   ; cambian de duracion
	ld e,a			;5079
	jr nz,L_507D		;507a
	inc e			;507c   ; o 2
L_507D:
	ld d,a			;507d
L_507E:
	ld a,d			;507e   ; los dos numeros, a su sitio
	ld (ix+00dh),a		;507f   ; el ataque
	ld a,e			;5082
	ld (ix+00eh),a		;5083   ; y el desvanecido
	inc hl			;5086
	ld a,(hl)			;5087
lee_el_ataque:
	cp 0e0h		;5088   ; de 0xE0 arriba viene el ataque
	jr c,pon_la_nota		;508a
	and 00fh		;508c   ; los cuatro bits bajos
	bit 3,a		;508e   ; el bit 3 lo separa del desvanecido
	jr z,L_5098		;5090
	ld (ix+00ch),a		;5092   ; con el bit 3, es el desvanecido
	inc hl			;5095
	jr lee_una_nota		;5096
L_5098:
	ld (ix+006h),a		;5098   ; y sin el, el ataque
	inc hl			;509b
	ld a,(hl)			;509c
pon_la_nota:
	and 00fh		;509d   ; la octava
	ld b,a			;509f   ; la octava, en B
	ld a,(ix+00bh)		;50a0   ; el paso de escala
	jr z,L_50AA		;50a3   ; con octava cero, no se suma nada
L_50A5:
	add a,(ix+00bh)		;50a5   ; sumando el paso de escala tantas veces
	djnz L_50A5		;50a8
L_50AA:
	ld (ix+001h),a		;50aa   ; y eso es la duracion base
	ld a,(hl)			;50ad   ; el codigo de nota
	call avanza_la_partitura		;50ae   ; el codigo de nota
	and 0f0h		;50b1   ; su nibble alto
	rrca			;50b3
	rrca			;50b4
	rrca			;50b5
	rrca			;50b6
	ld b,a			;50b7
	sub 00ch		;50b8   ; la nota 12 no se alarga
	jr z,L_50BF		;50ba
	ld a,(ix+007h)		;50bc
L_50BF:
	ld (ix+008h),a		;50bf   ; la duracion de la nota
	ld d,a			;50c2
	ld e,(ix+001h)		;50c3   ; la duracion
	ld (ix+000h),e		;50c6
	ld a,(ix+00dh)		;50c9   ; mas el ataque
	add a,e			;50cc
	ld (ix+009h),a		;50cd
	ld a,b			;50d0
	ld hl,0510eh		;50d1   ; la tabla de periodos
	call suma_a_a_hl		;50d4
	ld l,(hl)			;50d7
	ld h,000h		;50d8
	ld a,(ix+006h)		;50da   ; la octava
	or a			;50dd
	jr z,pon_el_periodo		;50de
	ld b,a			;50e0
L_50E1:
	add hl,hl			;50e1   ; se dobla el periodo por cada una
	djnz L_50E1		;50e2
pon_el_periodo:
	ld a,(ix+00ch)		;50e4   ; y el desafinado, si lo hay
	or a			;50e7
	jr z,L_50EB		;50e8
	inc hl			;50ea
L_50EB:
	ld a,c			;50eb   ; el registro del periodo, byte alto
	ld e,h			;50ec   ; el valor
	call 00093h		;50ed   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,c			;50f0   ; y el byte bajo
	dec a			;50f1
	ld e,l			;50f2
	call 00093h		;50f3   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,(ix+002h)		;50f6   ; el estado del canal
	and 0c0h		;50f9   ; los dos bits altos
	cp 0c0h		;50fb   ; con los dos puestos, se sigue
	ret nz			;50fd
	ld h,d			;50fe   ; el volumen que traia
	ld (ix+005h),002h		;50ff   ; y el canal pasa al estado 2
	jp escribe_el_volumen		;5103
avanza_la_partitura:
	inc hl			;5106
	ld (ix+003h),l		;5107   ; el puntero de vuelta a la partitura
	ld (ix+004h),h		;510a
	ret			;510d

; ----------------------------------------------------------------------
; DATOS periodos_de_las_notas: Los DOCE semitonos, de 0x6B a 0x39. 0x50D1
;   indexa aqui con el codigo de nota y luego baja de octava doblando el
;   periodo con `add hl,hl` (0x50E1): con doce numeros se hacen las ocho
;   octavas
;   0x510e..0x511a  (12 bytes)
DATA_periodos_de_las_notas:
	defb 06bh	; 510e
	defb 065h	; 510f
	defb 05fh	; 5110
	defb 05ah	; 5111
	defb 055h	; 5112
	defb 050h	; 5113
	defb 04ch	; 5114
	defb 047h	; 5115
	defb 043h	; 5116
	defb 040h	; 5117
	defb 03ch	; 5118
	defb 039h	; 5119

; ----------------------------------------------------------------------
; DATOS tabla_de_melodias: Los 57 punteros a las partituras. 0x4D9C entra con
;   `ld de,0x5118` y el numero de melodia DOBLADO, asi que la melodia 1 es el
;   primer puntero de aqui y la 0 no existe
;   0x511a..0x518c  (114 bytes)
DATA_tabla_de_melodias:
	defw 0518ch,051a1h,051bch,051f9h,05220h,05229h,05248h,0524fh	; 511a
	defw 05264h,0528ah,052d7h,052e6h,05317h,0533ah,053d5h,053dch	; 512a
	defw 05411h,05397h,05482h,05505h,0553dh,0554ah,056a5h,057cdh	; 513a
	defw 0588ch,058e7h,058f7h,05907h,05922h,05934h,059d6h,059ach	; 514a
	defw 05a2eh,05a54h,05a7fh,05abch,05af7h,05b21h,05b4bh,05b6eh	; 515a
	defw 05b73h,05b7ch,05b9ah,05bc1h,05be6h,05c1fh,05c35h,05c53h	; 516a
	defw 05d1fh,05d1fh,05505h,05c79h,05cb8h,05cf7h,05d1fh,05d1fh	; 517a
	defw 05d1fh	; 518a

; ----------------------------------------------------------------------
; DATOS partituras: Las melodias y los efectos del cartucho, en el lenguaje
;   que interpreta 0x4F06: 0xFE salta, 0xFF acaba, el nibble alto 2 cambia de
;   instrumento, el 1 pone el ruido y lo demas son notas con su volumen y su
;   octava
;   0x518c..0x5d20  (2964 bytes)
DATA_partituras:
	defb 022h,001h,0a0h,080h,090h,011h,0c0h,040h,0c0h,060h,0b0h,080h,0b0h,09ah,0a0h,0b5h	; 518c  "......@.`......
	defb 0a0h,0e0h,091h,00ah,0ffh,022h,001h,090h,00ch,0a0h,05ah,0c0h,02dh,0c0h,05ah,0a0h	; 519c  ....."....Z.-.Z.
	defb 00ch,0b0h,060h,090h,030h,0a0h,060h,080h,030h,000h,000h,090h,060h,070h,030h,0ffh	; 51ac  ..`.0.`.0...`p0.
	defb 022h,001h,060h,0b0h,070h,0b8h,080h,0c0h,090h,0c8h,0a0h,0d0h,0b0h,0d8h,0c0h,0e0h	; 51bc  ".`.p...........
	defb 0d0h,0e8h,0d0h,0f0h,0d0h,0f8h,0d1h,000h,0d1h,008h,0c1h,010h,0c1h,018h,0b1h,020h	; 51cc  ............... 
	defb 0b1h,028h,0a1h,030h,0a1h,038h,091h,040h,091h,048h,081h,050h,081h,058h,071h,060h	; 51dc  .(.0.8.@.H.P.Xq`
	defb 071h,068h,061h,070h,061h,078h,051h,080h,051h,088h,051h,090h,0ffh,022h,001h,0c0h	; 51ec  qhapaxQ.Q.Q.."..
	defb 078h,0c0h,088h,0b0h,090h,0a0h,098h,0a0h,0a0h,090h,078h,090h,080h,090h,088h,090h	; 51fc  x.........x.....
	defb 090h,090h,098h,090h,0a0h,080h,078h,080h,080h,080h,088h,080h,090h,080h,098h,080h	; 520c  ......x.........
	defb 0a0h,080h,0a8h,0ffh,0d2h,0fdh,08fh,0e1h,012h,0d4h,0e0h,016h,0ffh,022h,001h,0c0h	; 521c  ............."..
	defb 080h,0c0h,0c0h,0b1h,000h,0b1h,040h,0a1h,080h,0a1h,0c0h,092h,000h,092h,040h,082h	; 522c  ......@.......@.
	defb 080h,082h,0c0h,073h,000h,073h,040h,063h,080h,063h,0c0h,0ffh,02ah,005h,002h,050h	; 523c  ...s.s@c.c..*..P
	defb 090h,01eh,0ffh,022h,001h,0d1h,01bh,0a1h,009h,0d0h,0ddh,0b0h,0dch,0d0h,0c4h,0a0h	; 524c  ..."............
	defb 0adh,0d0h,09ah,0a0h,08ah,0d0h,08ah,0ffh,022h,001h,0d1h,000h,0e1h,080h,0e2h,080h	; 525c  ........".......
	defb 0d3h,080h,0c4h,080h,0b5h,080h,023h,004h,01fh,0e2h,000h,0d4h,000h,0c6h,000h,0b8h	; 526c  ......#.........
	defb 000h,07ah,000h,09ch,000h,078h,000h,09ah,000h,08ch,000h,07eh,000h,0ffh,022h,001h	; 527c  .z...x.....~..".
	defb 0d1h,020h,0d1h,010h,0d1h,000h,0d0h,0f0h,0d0h,0e0h,0d0h,0d0h,0d0h,0c0h,0d0h,0b0h	; 528c  . ..............
	defb 0d0h,0a0h,0c1h,0e0h,0c1h,0d4h,0c1h,0c8h,0c1h,0bch,0c1h,0b0h,0c1h,0a4h,0c1h,098h	; 529c  ................
	defb 0c1h,08ch,0c1h,080h,0c1h,074h,0c1h,068h,0c1h,05ch,0c1h,050h,0c1h,044h,0c1h,038h	; 52ac  .....t.h.\.P.D.8
	defb 0c1h,02eh,0c1h,024h,0c1h,01ah,0c1h,010h,0c1h,006h,0c0h,0fch,0c0h,0f2h,0b0h,0e8h	; 52bc  ...$............
	defb 0b0h,0e0h,0b0h,0d8h,0b0h,0d0h,0b0h,0c8h,0b0h,0c0h,0ffh,022h,001h,0d0h,02ah,0d0h	; 52cc  ..........."..*.
	defb 01ch,0c0h,02dh,0c0h,01eh,0b0h,02ah,0b0h,01ch,0ffh,022h,001h,0c0h,074h,0c0h,094h	; 52dc  ..-...*..."..t..
	defb 0d0h,0a4h,0d0h,0b4h,0d0h,0c4h,0d0h,0d4h,0c0h,0c4h,0c0h,0b4h,0c0h,0a4h,0b0h,094h	; 52ec  ................
	defb 0b0h,084h,0b0h,074h,0b0h,064h,022h,002h,090h,054h,022h,003h,080h,054h,022h,004h	; 52fc  ...t.d"..T"..T".
	defb 070h,054h,022h,002h,070h,054h,060h,054h,050h,054h,0ffh,022h,001h,0d0h,023h,030h	; 530c  pT".pT`TPT."..#0
	defb 013h,0d0h,026h,0d0h,013h,0c0h,026h,0c0h,013h,0b0h,027h,0b0h,014h,090h,027h,090h	; 531c  ..&...&...'...'.
	defb 014h,080h,027h,080h,014h,070h,027h,060h,014h,040h,013h,040h,013h,0ffh,022h,001h	; 532c  ..'..p'`.@.@..".
	defb 0d1h,0fch,0a1h,0fch,081h,0fch,0d1h,0c3h,0a1h,0c3h,081h,0c3h,0d1h,093h,0a1h,093h	; 533c  ................
	defb 081h,093h,0d1h,064h,0a1h,064h,081h,064h,0d1h,039h,0a1h,039h,081h,039h,0d1h,012h	; 534c  ...d.d.d.9.9.9..
	defb 0a1h,012h,081h,012h,0d0h,0f6h,0a0h,0f6h,080h,0f6h,0d0h,0d0h,0a0h,0d0h,080h,0d0h	; 535c  ................
	defb 0d0h,0b5h,0a0h,0b5h,080h,0b5h,0d0h,09eh,0a0h,09eh,080h,09eh,0d0h,08bh,0a0h,08bh	; 536c  ................
	defb 080h,08bh,0d0h,07ch,0a0h,07ch,080h,07ch,0d0h,071h,0a0h,071h,080h,071h,0d0h,06ah	; 537c  ...|.|.|.q.q.q.j
	defb 0a0h,06ah,080h,06ah,0d0h,067h,0a0h,067h,080h,067h,0ffh,023h,004h,015h,0f0h,015h	; 538c  .j.j.g.g.g.#....
	defb 0f0h,010h,0f0h,02ah,0f0h,020h,000h,000h,0e0h,010h,0e0h,00ah,0e0h,025h,0e0h,01ah	; 539c  ...*. .......%..
	defb 000h,000h,0b0h,015h,0b0h,010h,0b0h,02ah,0b0h,020h,000h,000h,0a0h,010h,0a0h,00ah	; 53ac  .......*. ......
	defb 0a0h,025h,0a0h,01ah,000h,000h,080h,015h,080h,010h,080h,02ah,080h,020h,000h,000h	; 53bc  .%.........*. ..
	defb 070h,010h,070h,00ah,070h,025h,070h,01ah,0ffh,022h,01eh,0b0h,07eh,0b0h,09fh,0ffh	; 53cc  p.p.p%p.."..~...
	defb 022h,001h,0e0h,0beh,0e0h,03eh,0e0h,0beh,0d0h,03eh,0d0h,0beh,0d0h,03eh,0c0h,0beh	; 53dc  "....>...>...>..
	defb 0c0h,03eh,0c0h,0beh,0b0h,03eh,0b0h,0beh,0b0h,03eh,0b0h,0beh,0a0h,03eh,0a0h,0beh	; 53ec  .>...>...>...>..
	defb 0a0h,03eh,0a0h,0beh,090h,03eh,090h,0beh,090h,03eh,090h,0beh,080h,03eh,080h,0beh	; 53fc  .>...>...>...>..
	defb 080h,03eh,080h,0beh,0ffh,022h,001h,0e0h,040h,0e0h,0c0h,0d0h,040h,0c0h,0c0h,0b0h	; 540c  .>..."..@...@...
	defb 040h,030h,000h,030h,000h,0e0h,0b0h,0e0h,060h,0e0h,0b0h,0e0h,060h,0d0h,0b0h,0d0h	; 541c  @0.0....`...`...
	defb 060h,0d0h,0b0h,0d0h,060h,0c0h,0b0h,0c0h,060h,0c0h,0b0h,0c0h,060h,0b0h,0b0h,0b0h	; 542c  `...`...`...`...
	defb 060h,0b0h,0b0h,0b0h,060h,0a0h,0b0h,0a0h,060h,0a0h,0b0h,0a0h,060h,090h,0b0h,090h	; 543c  `...`...`...`...
	defb 060h,090h,0b0h,090h,060h,080h,0b0h,080h,060h,080h,0b0h,080h,060h,070h,0b0h,070h	; 544c  `...`...`...`p.p
	defb 060h,070h,0b0h,070h,060h,060h,0b0h,060h,060h,060h,0b0h,060h,060h,050h,0b0h,050h	; 545c  `p.p``.```.``P.P
	defb 060h,050h,0b0h,050h,060h,040h,0b0h,040h,060h,040h,0b0h,040h,060h,030h,0b0h,030h	; 546c  `P.P`@.@`@.@`0.0
	defb 060h,030h,0b0h,030h,060h,0ffh,022h,001h,0d1h,040h,0d1h,034h,0d1h,028h,0d1h,01ch	; 547c  `0.0`."..@.4.(..
	defb 0d1h,010h,0d1h,004h,0d0h,0f8h,0d0h,0ech,0d0h,0e0h,0d0h,0d4h,0d1h,027h,0d1h,01bh	; 548c  .............'..
	defb 0d1h,00fh,0d1h,003h,0d0h,0f7h,0d0h,0e8h,0d0h,0dfh,0d0h,0d3h,0d0h,0c7h,0d0h,0bbh	; 549c  ................
	defb 0d1h,017h,0d1h,00bh,0d0h,0ddh,0d0h,0f3h,0d0h,0e7h,0d0h,0dbh,0d0h,0cfh,0d0h,0c3h	; 54ac  ................
	defb 0d0h,0b7h,0d0h,0abh,0d1h,007h,0d0h,0fbh,0d0h,0efh,0d0h,0e3h,0d0h,0d7h,0d0h,0cbh	; 54bc  ................
	defb 0d0h,0bfh,0d0h,0b3h,0d0h,0a7h,0d0h,09bh,0b0h,0f7h,0b0h,0ebh,0b0h,0dfh,0b0h,0d3h	; 54cc  ................
	defb 0b0h,0c7h,0b0h,0bbh,0b0h,0afh,0b0h,0a3h,0b0h,097h,0b0h,08bh,0b0h,07fh,090h,0e0h	; 54dc  ................
	defb 090h,0d4h,090h,0c8h,090h,0bch,090h,0b0h,090h,0a4h,090h,098h,090h,08ch,090h,080h	; 54ec  ................
	defb 090h,074h,090h,068h,090h,05ch,090h,050h,0ffh,023h,001h,01fh,0e1h,080h,0f2h,080h	; 54fc  .t.h.\.P.#......
	defb 0f3h,080h,0e4h,080h,0e5h,080h,0d6h,080h,0c7h,080h,0b8h,080h,0a9h,080h,021h,002h	; 550c  ..............!.
	defb 018h,0f0h,000h,0d0h,000h,0e0h,000h,0c0h,000h,021h,006h,01dh,0f0h,000h,0e0h,000h	; 551c  .........!......
	defb 0d0h,000h,0c0h,000h,0b0h,000h,0a0h,000h,090h,000h,080h,000h,070h,000h,060h,000h	; 552c  ............p.`.
	defb 0ffh,0d1h,0fch,088h,0e1h,004h,074h,044h,074h,0fch,023h,0e0h,009h,0ffh,0d6h,0f6h	; 553c  ......tDt.#.....
	defb 000h,0e1h,041h,0f7h,000h,041h,0f8h,000h,041h,0f9h,000h,041h,0fah,000h,04fh,0f9h	; 554c  ..A..A..A..A..O.
	defb 000h,041h,0f8h,000h,041h,0f7h,000h,041h,0f6h,000h,040h,0c0h,021h,0f7h,000h,021h	; 555c  .A..A..A..@.!..!
	defb 0f8h,000h,021h,0f9h,000h,021h,0fah,000h,02fh,0f9h,000h,021h,0f8h,000h,021h,0f7h	; 556c  ..!..!../..!..!.
	defb 000h,021h,0f6h,000h,020h,0c0h,0feh,002h,04ah,055h,0d6h,0fbh,041h,0e2h,043h,001h	; 557c  .!.. ...JU..A.C.
	defb 0fbh,022h,073h,041h,051h,07dh,043h,0fbh,041h,023h,0fbh,022h,095h,051h,071h,099h	; 558c  ."sAQ}C.A#.".Qq.
	defb 0fbh,041h,073h,053h,0feh,002h,086h,055h,0d6h,0fbh,036h,0e3h,091h,0feh,000h,082h	; 559c  .AsS...U..6.....
	defb 057h,091h,0feh,000h,082h,057h,0fbh,041h,0e2h,043h,001h,0fbh,022h,073h,041h,051h	; 55ac  W....W.A.C.."sAQ
	defb 079h,0fbh,041h,093h,073h,0fbh,021h,055h,0dch,0e1h,000h,007h,0d6h,0e2h,091h,0e1h	; 55bc  y.A.s.!U........
	defb 053h,0fch,041h,055h,071h,0fbh,022h,043h,0fch,041h,001h,021h,041h,053h,071h,0fbh	; 55cc  S.AUq."C.A.!ASq.
	defb 022h,043h,0fch,041h,001h,021h,041h,053h,071h,0fbh,021h,009h,0fch,041h,053h,071h	; 55dc  "C.A.!ASq.!..ASq
	defb 0fbh,021h,009h,0fch,041h,053h,071h,0fbh,022h,043h,0fch,041h,001h,021h,041h,053h	; 55ec  .!..ASq."C.A.!AS
	defb 071h,0fbh,022h,043h,0fch,041h,001h,021h,041h,053h,071h,0fbh,021h,009h,0fch,041h	; 55fc  q."C.A.!ASq.!..A
	defb 053h,071h,0fbh,021h,009h,0f9h,000h,0e2h,0b1h,0fah,000h,0b1h,0fbh,000h,0b1h,0fbh	; 560c  Sq.!............
	defb 041h,0e1h,001h,0c3h,0f9h,000h,0e2h,0b1h,0fah,000h,0b1h,0f9h,000h,0b1h,0fch,041h	; 561c  A..............A
	defb 0e1h,001h,0c3h,023h,003h,0fbh,011h,025h,0dch,048h,0d6h,0fch,041h,023h,043h,0f9h	; 562c  ...#...%.H..A#C.
	defb 000h,0e2h,0b1h,0fah,000h,0b1h,0fbh,000h,0b1h,0fbh,041h,0e1h,001h,0c3h,0f9h,000h	; 563c  ..........A.....
	defb 0e2h,0b1h,0fah,000h,0b1h,0f9h,000h,0b1h,0fbh,041h,0e1h,001h,0c3h,023h,003h,0fbh	; 564c  .........A...#..
	defb 011h,025h,0dch,0fah,000h,04ah,0d4h,0f9h,000h,041h,0f8h,000h,040h,0f7h,000h,040h	; 565c  .%...J...A..@..@
	defb 0f6h,000h,040h,0f5h,000h,040h,0d6h,0fbh,036h,0e3h,091h,0feh,000h,082h,057h,091h	; 566c  ..@..@..6.....W.
	defb 0feh,000h,082h,057h,051h,0feh,000h,09fh,057h,071h,0feh,006h,085h,056h,020h,040h	; 567c  ...WQ...Wq...V @
	defb 071h,081h,0feh,006h,08dh,056h,030h,050h,081h,0a1h,0feh,006h,095h,056h,050h,070h	; 568c  q....V0P.....VPp
	defb 0a1h,0e2h,002h,0cch,0cfh,0feh,0ffh,04ah,055h,0feh,000h,06ch,057h,0feh,000h,07bh	; 569c  .......JU..lW..{
	defb 057h,0a0h,0a0h,0a1h,0a1h,0a1h,0feh,000h,06ch,057h,0feh,000h,07bh,057h,0a0h,0a0h	; 56ac  W.......lW..{W..
	defb 0a1h,0a0h,0a0h,0a1h,0feh,000h,06ch,057h,0feh,000h,07bh,057h,0a0h,0a0h,0a1h,0a0h	; 56bc  ......lW..{W....
	defb 0a0h,0a1h,0feh,000h,06ch,057h,0feh,000h,07bh,057h,0a0h,0a0h,0a1h,0a0h,0a0h,0a1h	; 56cc  ....lW..{W......
	defb 0fbh,036h,0e4h,091h,0feh,000h,082h,057h,091h,0feh,000h,082h,057h,0feh,000h,06ch	; 56dc  .6.....W....W..l
	defb 057h,0e4h,051h,0feh,00ch,0eeh,056h,050h,050h,051h,051h,051h,0feh,000h,0a8h,057h	; 56ec  W.Q...VPPQQQ...W
	defb 0feh,000h,0a8h,057h,0fch,035h,051h,0feh,000h,09fh,057h,051h,0feh,000h,09fh,057h	; 56fc  ...W.5Q...WQ...W
	defb 0fch,035h,001h,001h,001h,001h,001h,001h,000h,000h,001h,0feh,002h,00eh,057h,051h	; 570c  .5............WQ
	defb 0feh,000h,09fh,057h,051h,0feh,000h,09fh,057h,0fch,035h,001h,0feh,006h,027h,057h	; 571c  ...WQ...W.5...'W
	defb 000h,000h,001h,0fch,026h,0e4h,071h,0feh,006h,032h,057h,070h,070h,071h,0fbh,027h	; 572c  ....&.q..2Wppq.'
	defb 0e4h,091h,0feh,000h,082h,057h,091h,0feh,000h,082h,057h,051h,0feh,000h,09fh,057h	; 573c  .....W....WQ...W
	defb 071h,0feh,006h,04ch,057h,020h,040h,071h,081h,0feh,006h,054h,057h,030h,050h,081h	; 574c  q..LW @q...TW0P.
	defb 0a1h,0feh,006h,05ch,057h,050h,070h,0a1h,0e3h,002h,0cch,0cfh,0feh,0ffh,0a5h,056h	; 575c  ...\WPp........V
	defb 0d6h,0fdh,035h,0e3h,001h,0feh,00ch,070h,057h,000h,000h,001h,001h,001h,0ffh,0e4h	; 576c  ..5....pW.......
	defb 0a1h,0feh,00ch,07ch,057h,0ffh,091h,0feh,005h,082h,057h,040h,070h,091h,0feh,007h	; 577c  ...|W.....W@p...
	defb 089h,057h,040h,070h,091h,071h,071h,071h,071h,071h,071h,020h,040h,071h,0feh,002h	; 578c  .W@p.qqqqqq @q..
	defb 091h,057h,0ffh,051h,051h,051h,051h,051h,000h,020h,051h,0ffh,0fdh,032h,0e3h,001h	; 579c  .W.QQQQQ. Q..2..
	defb 0fch,032h,0e2h,001h,0feh,008h,0a8h,057h,0fdh,032h,0e4h,051h,0fch,032h,0e3h,051h	; 57ac  .2.....W.2.Q.2.Q
	defb 0feh,004h,0b4h,057h,0fdh,032h,0e4h,071h,0fch,032h,0e3h,071h,0feh,004h,0c0h,057h	; 57bc  ...W.2.q.2.q...W
	defb 0ffh,0d4h,0fdh,041h,0e2h,060h,0fah,000h,060h,0f9h,000h,060h,0f8h,000h,060h,0f7h	; 57cc  ...A.`..`..`..`.
	defb 081h,060h,0d5h,0fch,051h,061h,0d4h,0fch,000h,070h,0fah,000h,070h,0f9h,000h,070h	; 57dc  .`..Qa...p..p..p
	defb 0f8h,000h,070h,0f7h,081h,070h,0d5h,0fch,051h,071h,091h,0fch,021h,0e1h,023h,0e2h	; 57ec  ..p..p..Qq..!.#.
	defb 091h,0e1h,021h,0d4h,0fah,000h,000h,0f9h,000h,000h,0f8h,000h,000h,0f7h,000h,000h	; 57fc  ..!.............
	defb 0f6h,081h,000h,0d5h,0fch,021h,0e2h,091h,0e1h,021h,003h,0e2h,091h,0e1h,021h,0d4h	; 580c  .....!...!....!.
	defb 0fah,000h,000h,0f9h,000h,000h,0f8h,000h,000h,0f7h,000h,000h,0f6h,081h,000h,0d5h	; 581c  ................
	defb 0fch,021h,0e2h,091h,0e1h,041h,023h,0e2h,091h,0e1h,041h,0d4h,0fah,000h,020h,0f9h	; 582c  .!...A#...A... .
	defb 000h,020h,0f8h,000h,020h,0f7h,000h,020h,0f6h,081h,020h,0d5h,0fch,011h,0e2h,091h	; 583c  . .. .. .. .....
	defb 0e1h,071h,061h,0feh,002h,0cdh,057h,0d5h,0fch,012h,0e1h,045h,0fch,041h,023h,0fch	; 584c  .qa...W....E.A#.
	defb 021h,021h,0fbh,001h,04bh,0fch,041h,023h,043h,0fch,022h,045h,068h,0c0h,0d4h,0f6h	; 585c  !!..K.A#C."Eh...
	defb 000h,060h,0f7h,000h,060h,0f8h,000h,060h,0f9h,000h,061h,0d5h,0fah,000h,061h,0fbh	; 586c  .`..`..`..a...a.
	defb 000h,061h,0fch,000h,066h,0fbh,000h,060h,0feh,002h,053h,058h,0feh,0ffh,0cdh,057h	; 587c  .a..f..`..SX...W
	defb 0feh,000h,0cch,058h,0feh,000h,0dah,058h,0fdh,024h,0e3h,021h,0fch,041h,0e2h,021h	; 588c  ...X...X.$.!.A.!
	defb 0feh,00ch,094h,058h,0feh,000h,0dah,058h,0fdh,024h,0e3h,021h,0fch,041h,0e2h,021h	; 589c  ...X...X.$.!.A.!
	defb 0feh,004h,0a4h,058h,0feh,000h,0dah,058h,0feh,000h,0dah,058h,0feh,000h,0cch,058h	; 58ac  ...X...X...X...X
	defb 0feh,000h,0dah,058h,0feh,000h,0dah,058h,0feh,000h,0cch,058h,0feh,0ffh,08ch,058h	; 58bc  ...X...X...X...X
	defb 0d5h,0fdh,024h,0e3h,021h,0fch,041h,0e2h,021h,0feh,008h,0cch,058h,0ffh,0fdh,024h	; 58cc  ..$.!.A.!...X..$
	defb 0e3h,001h,0fch,041h,0e2h,001h,0feh,004h,0dah,058h,0ffh,0ddh,0fch,028h,0c0h,0e3h	; 58dc  ...A.....X...(..
	defb 000h,0e4h,070h,0e3h,010h,0e4h,070h,0feh,0ffh,0ebh,058h,0ddh,0fch,028h,0c0h,0e2h	; 58ec  ..p...p...X..(..
	defb 000h,0e3h,070h,0e2h,010h,0e3h,070h,0feh,0ffh,0fbh,058h,0d5h,0fbh,021h,0e1h,001h	; 58fc  ..p...p...X..!..
	defb 0e2h,0b1h,091h,0b1h,0feh,010h,007h,059h,0e0h,001h,0e1h,0b1h,091h,0b1h,0feh,010h	; 590c  .......Y........
	defb 014h,059h,0feh,0ffh,007h,059h,0d5h,0fch,032h,0e3h,051h,0feh,008h,022h,059h,071h	; 591c  .Y...Y..2.Q.."Yq
	defb 0feh,008h,02bh,059h,0feh,0ffh,022h,059h,0d6h,0fch,000h,0e3h,074h,0c6h,0feh,008h	; 592c  ..+Y.."Y....t...
	defb 038h,059h,0d9h,0cfh,0cfh,0d6h,0f6h,000h,0e2h,053h,0f7h,000h,053h,0f8h,000h,053h	; 593c  8Y.......S..S..S
	defb 0f9h,000h,053h,0fah,000h,053h,0fbh,000h,057h,0fah,000h,057h,0f9h,000h,053h,0f8h	; 594c  ..S..S..W..W..S.
	defb 000h,053h,0f7h,000h,053h,0d6h,0f6h,000h,0e2h,077h,0f7h,000h,073h,0f8h,000h,073h	; 595c  .S..S....w..s..s
	defb 0f9h,000h,073h,0fah,000h,073h,0fbh,000h,077h,0fah,000h,073h,0f9h,000h,073h,0f8h	; 596c  ..s..s..w..s..s.
	defb 000h,073h,0f7h,000h,073h,0d2h,098h,0f8h,000h,098h,0f9h,000h,098h,0d4h,0fah,000h	; 597c  .s..s...........
	defb 098h,0d2h,0f9h,000h,098h,0f8h,000h,098h,0f7h,000h,098h,0b8h,0f8h,000h,0b8h,0f9h	; 598c  ................
	defb 000h,0b8h,0d4h,0fah,000h,0b8h,0d2h,0f9h,000h,0b8h,0f8h,000h,0b8h,0f7h,000h,0b8h	; 599c  ................
	defb 0d1h,0fbh,0dfh,0e0h,050h,070h,050h,070h,051h,0c1h,000h,020h,000h,020h,001h,0c1h	; 59ac  ....PpPpQ.. . ..
	defb 070h,090h,070h,090h,071h,0c1h,030h,050h,030h,050h,031h,0c1h,000h,020h,000h,020h	; 59bc  p.p.q.0P0P1.. . 
	defb 001h,0ceh,0feh,002h,0ach,059h,0feh,0ffh,041h,059h,0dfh,0fch,003h,0e3h,0cfh,0d4h	; 59cc  .....Y..AY......
	defb 0cbh,0feh,000h,036h,05ah,0feh,000h,036h,05ah,0feh,000h,036h,05ah,0e3h,030h,0e4h	; 59dc  ...6Z..6Z..6Z.0.
	defb 0a0h,0e3h,030h,0e4h,0a0h,0e3h,010h,0e4h,0a0h,0e3h,000h,0e4h,0a0h,0e3h,010h,0e4h	; 59ec  ..0.............
	defb 0a0h,0e3h,030h,0e4h,0a0h,0e3h,010h,0e4h,0a0h,0e3h,000h,0e4h,0a0h,0feh,002h,0e9h	; 59fc  ..0.............
	defb 059h,0e3h,050h,000h,050h,000h,030h,000h,020h,000h,030h,000h,050h,000h,030h,000h	; 5a0c  Y.P.P.0. .0.P.0.
	defb 020h,000h,070h,020h,070h,020h,050h,020h,040h,020h,050h,020h,070h,020h,050h,020h	; 5a1c   .p p P @ P p P 
	defb 040h,020h,0dah,0c9h,0d6h,0c0h,0feh,0ffh,0e5h,059h,0d9h,0fdh,013h,0e3h,010h,0e4h	; 5a2c  @ .......Y......
	defb 080h,0e3h,010h,0e4h,080h,0b0h,080h,0a0h,080h,0b0h,080h,0e3h,010h,0e4h,080h,0b0h	; 5a3c  ................
	defb 080h,0a0h,080h,0feh,002h,039h,05ah,0ffh,0d8h,0fdh,061h,0e1h,071h,070h,070h,070h	; 5a4c  .....9Z...a.qppp
	defb 070h,0feh,004h,054h,05ah,0d4h,0fch,03fh,0e3h,0b0h,0c2h,0d1h,0c0h,0d4h,0e2h,000h	; 5a5c  p..TZ..?........
	defb 0c0h,0d4h,0fbh,020h,009h,0c1h,0fch,020h,0e3h,093h,0c1h,0d1h,0c0h,0d8h,0fbh,030h	; 5a6c  ... ... .......0
	defb 0e2h,0b8h,0ffh,0d8h,0fah,051h,0e2h,070h,0c0h,070h,0fch,022h,0e3h,070h,0e2h,000h	; 5a7c  .....Q.p.p.".p..
	defb 070h,0d4h,0fch,033h,054h,0c0h,044h,0c0h,0d8h,050h,040h,000h,0d8h,0fch,030h,0e3h	; 5a8c  p..3T.D..P@...0.
	defb 077h,0d7h,0c0h,0e8h,0d4h,0fdh,030h,0e1h,020h,0c2h,0d2h,0fdh,03fh,041h,0c1h,0d8h	; 5a9c  w.....0. ...?A..
	defb 0fdh,020h,044h,0c0h,0d1h,0c0h,0d2h,009h,0c1h,0d1h,0c0h,0d8h,0e1h,028h,0c6h,0ffh	; 5aac  . D..........(..
	defb 0e8h,0d8h,0fdh,024h,0e2h,0c2h,070h,0e1h,000h,070h,0d4h,0fdh,033h,054h,0c0h,044h	; 5abc  ...$..p..p..3T.D
	defb 0c0h,0d8h,0fdh,033h,050h,040h,000h,0d8h,0fdh,03fh,0e2h,078h,0d4h,0fch,030h,0e3h	; 5acc  ...3P@...?.x..0.
	defb 070h,0c2h,0d2h,0fdh,035h,071h,0c1h,0d8h,0fch,030h,074h,0c0h,0d1h,0c0h,0d2h,0fch	; 5adc  p...5q...0t.....
	defb 030h,0e3h,049h,0c1h,0d1h,0c0h,0d8h,0fch,030h,078h,0ffh,0d5h,0fbh,001h,0e2h,0c0h	; 5aec  0.I.....0x......
	defb 0d1h,0c0h,0d5h,040h,060h,040h,080h,040h,060h,040h,0d5h,0fch,0f1h,080h,0d8h,0fch	; 5afc  ...@`@.@`@......
	defb 03fh,0e3h,040h,0c0h,040h,0d5h,0fch,030h,047h,0c0h,0d8h,0fbh,012h,090h,080h,060h	; 5b0c  ?.@.@..0G......`
	defb 0d6h,0fbh,030h,0b8h,0ffh,0e8h,0d5h,0fch,023h,0e1h,0c0h,040h,060h,040h,080h,040h	; 5b1c  ..0.....#..@`@.@
	defb 060h,040h,080h,0d1h,0c0h,0d8h,0fdh,03ch,0e2h,040h,0c0h,040h,0d4h,0fdh,030h,0bah	; 5b2c  `@.....<.@.@..0.
	defb 0d8h,0fdh,020h,0e1h,010h,0e2h,0b0h,090h,0d6h,0fdh,020h,0e1h,048h,0c7h,0ffh,0d5h	; 5b3c  .. ....... .H...
	defb 0fch,033h,0e1h,0c0h,040h,060h,040h,080h,040h,060h,040h,0d5h,080h,0d8h,0e3h,0b0h	; 5b4c  .3..@`@.@`@.....
	defb 0c0h,0b0h,0d5h,0fch,014h,0e2h,048h,0d8h,090h,0fbh,012h,080h,060h,0d6h,0fch,030h	; 5b5c  ......H.....`..0
	defb 0b8h,0ffh,0feh,000h,08bh,05bh,0ffh,0e8h,0d3h,0c0h,0feh,000h,08bh,05bh,0c6h,0ffh	; 5b6c  .....[.......[..
	defb 0d6h,0fbh,022h,0e0h,040h,0c0h,040h,040h,020h,000h,040h,0c0h,050h,078h,0ffh,0d6h	; 5b7c  ..".@.@@ .@.Px..
	defb 0fch,033h,0e1h,040h,0c0h,040h,040h,020h,000h,040h,0c0h,050h,078h,0ffh,022h,001h	; 5b8c  .3.@.@@ .@.Px.".
	defb 0a4h,010h,0c4h,010h,022h,003h,0f4h,010h,0e4h,010h,0d4h,010h,0c4h,010h,0b4h,010h	; 5b9c  ...."...........
	defb 022h,005h,0c4h,010h,0b4h,010h,0a4h,010h,0b4h,010h,0a4h,010h,094h,010h,0a4h,010h	; 5bac  "...............
	defb 094h,010h,084h,010h,0ffh,02ah,007h,000h,020h,080h,000h,02ah,003h,000h,020h,080h	; 5bbc  .....*.. ..*.. .
	defb 055h,080h,080h,080h,080h,080h,0c5h,080h,0d5h,080h,0eah,081h,010h,081h,020h,081h	; 5bcc  U............. .
	defb 020h,081h,030h,081h,030h,081h,040h,081h,040h,0ffh,023h,003h,01fh,0f4h,000h,010h	; 5bdc   .0.0.@.@.#.....
	defb 0e4h,000h,012h,0d4h,000h,014h,0c4h,000h,016h,0b4h,000h,018h,0b4h,000h,01ah,0a4h	; 5bec  ................
	defb 000h,01ch,0a4h,000h,016h,0b4h,000h,018h,0b4h,000h,01ah,0a4h,000h,01ch,0a4h,000h	; 5bfc  ................
	defb 01eh,094h,000h,01fh,094h,000h,01ah,0a4h,000h,01ch,0a4h,000h,01eh,094h,000h,01fh	; 5c0c  ................
	defb 094h,000h,0ffh,0e8h,0d6h,0fch,030h,0e1h,0cah,0d2h,002h,0feh,000h,06dh,05ch,0c0h	; 5c1c  ......0......m\.
	defb 0d2h,0e2h,072h,0c4h,052h,0c0h,0d4h,07ch,0ffh,0d6h,0fch,031h,0e1h,0cah,0d2h,001h	; 5c2c  ..r.R..|...1....
	defb 0c5h,003h,003h,003h,003h,0feh,002h,03ah,05ch,0d2h,0fch,050h,002h,0c4h,0e2h,092h	; 5c3c  .......:\..P....
	defb 0c0h,0d4h,0fah,000h,0bch,0cbh,0ffh,0d6h,0fbh,033h,0e1h,0cah,0d2h,0c0h,002h,0feh	; 5c4c  .........3......
	defb 000h,06dh,05ch,0d2h,0fch,030h,042h,0c4h,002h,0d1h,0c0h,0d4h,0fch,040h,0e1h,02ch	; 5c5c  .m\..0B......@.,
	defb 0ffh,0c4h,0e2h,072h,0c0h,0e1h,00ah,0c0h,0e1h,02ah,0c0h,07ah,0ffh,0d2h,0fbh,011h	; 5c6c  ...r.....*.z....
	defb 0e2h,0cfh,0d8h,060h,030h,0e3h,0a0h,0e2h,0a0h,060h,030h,0e1h,010h,0e2h,0a0h,060h	; 5c7c  ...`0....`0....`
	defb 0b0h,080h,040h,0e1h,030h,0e2h,0b0h,080h,0e1h,080h,030h,0e2h,0b0h,090h,060h,0e1h	; 5c8c  ..@.0.....0...`.
	defb 020h,0e2h,090h,0e1h,040h,020h,060h,040h,090h,0d8h,0f9h,000h,0e1h,0b6h,0d1h,0f8h	; 5c9c   ...@ `@........
	defb 000h,0b0h,0f7h,000h,0b0h,0f6h,000h,0b0h,0f5h,000h,0b0h,0ffh,0e8h,0d2h,0fch,011h	; 5cac  ................
	defb 0e1h,0ceh,0d2h,063h,033h,0e2h,0a3h,0e1h,0a3h,063h,033h,0e0h,013h,0e1h,0a3h,063h	; 5cbc  ...c3....c3....c
	defb 0b3h,083h,043h,0e0h,033h,0e1h,0b3h,083h,0e0h,083h,033h,0e1h,0b3h,093h,063h,0e0h	; 5ccc  ..C.3.....3...c.
	defb 023h,0e1h,093h,0e0h,043h,023h,063h,043h,093h,0d8h,0f8h,000h,0b6h,0d1h,0f7h,000h	; 5cdc  #...C#cC........
	defb 0b0h,0f6h,000h,0b0h,0f5h,000h,0b0h,0f4h,000h,0b0h,0ffh,0d2h,0fch,025h,0e2h,0ceh	; 5cec  .............%..
	defb 0d6h,0a7h,0a3h,0d2h,0bah,0c0h,0bah,0c0h,0bah,0c0h,0d8h,0fah,000h,0e1h,01eh,0d6h	; 5cfc  ................
	defb 0f9h,000h,010h,0f8h,000h,010h,0f7h,000h,010h,0f6h,000h,010h,0f5h,000h,010h,0f4h	; 5d0c  ................
	defb 000h,010h,0ffh,0ffh	; 5d1c

; ======================================================================
; CODIGO 0x5d20..0x6016  (758 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EMPIEZA LA PARTIDA. Deja la RAM del juego en su estado de salida: por donde va el decorado, donde estan las dos naves, los enemigos apagados y los sprites fuera de la pantalla. Y al final descomprime el mapa y sube los patrones de sprite, que son los mismos en las cinco fases.
; ----------------------------------------------------------------------
empieza_la_partida:
	ld a,004h		;5d20   ; la altura a la que aparece el jefe
	ld (0e3a1h),a		;5d22
	ld a,017h		;5d25
	ld (0ebf0h),a		;5d27   ; por donde empieza el decorado: la fila 23
	ld a,021h		;5d2a
	ld (0ebb0h),a		;5d2c   ; el hito de la primera nube
	ld a,0edh		;5d2f
	ld (0ebb3h),a		;5d31   ; y el de la primera melodia
	ld hl,00105h		;5d34   ; donde arranca la nave
	ld (0ebb6h),hl		;5d37   ; el hito del jefe
	ld a,h			;5d3a   ; H vale uno: la semilla de la tabla de premios
	ld (0e087h),a		;5d3b   ; la bomba del primero, cargada
	ld (0e08dh),a		;5d3e   ; y la del segundo
	ld (0eb8ch),a		;5d41   ; la tabla de premios, escrita a mano: potencia en la casilla 4
	rlca			;5d44   ; doblando cada vez
	ld (0eb90h),a		;5d45   ; doble disparo en la 8
	rlca			;5d48
	ld (0eb98h),a		;5d49   ; el brazo en la 16
	rlca			;5d4c
	ld (0eb9ch),a		;5d4d   ; el arma en la 20
	rlca			;5d50
	ld (0eba8h),a		;5d51   ; y el escudo en la 32
	ld hl,00700h		;5d54   ; el patron y el color de la nave 1
	ld (0ef82h),hl		;5d57
	ld hl,00f04h		;5d5a   ; y su segundo sprite
	ld (0ef86h),hl		;5d5d
	ld a,030h		;5d60
	ld (0e34bh),a		;5d62   ; la cuenta del aviso
	call es_el_segundo_jugador		;5d65   ; con dos jugadores
	jr nz,L_5D93		;5d68
	ld hl,00118h		;5d6a   ; cada nave tiene su sitio
	ld (0ef8ah),hl		;5d6d   ; los dos sprites del segundo
	ld (0ef8eh),hl		;5d70
	ld a,(0f0ffh)		;5d73   ; el truco que se apunto en 0xF0FF
	and 001h		;5d76   ; el bit 0 del truco
	jr z,L_5DAC		;5d78
	ld a,006h		;5d7a   ; da potencia de salida
	ld (0e083h),a		;5d7c
	ld a,010h		;5d7f
	ld (0e095h),a		;5d81   ; y dieciseis usos de arma
	ld hl,0e0b1h		;5d84   ; y campanas ya cargadas
	ld a,078h		;5d87   ; con dos tandas de veinte casillas
	call pon_veinte_alternas		;5d89
	ld a,040h		;5d8c
	call pon_veinte_alternas		;5d8e
	jr L_5DAC		;5d91
L_5D93:
	ld hl,0060ch		;5d93   ; y con uno solo, la nave va en medio
	ld (0ef8ah),hl		;5d96   ; los dos sprites
	ld hl,00f10h		;5d99
	ld (0ef8eh),hl		;5d9c
	ld a,001h		;5d9f
	ld (0e088h),a		;5da1   ; con la bomba cargada
	ld (0e08eh),a		;5da4
	ld a,030h		;5da7
	ld (0e343h),a		;5da9
L_5DAC:
	ld a,0e0h		;5dac   ; Y = 0xE0
	ld hl,0e104h		;5dae   ; los sprites de los premios
	ld de,00008h		;5db1   ; ocho bytes por sprite
	ld b,006h		;5db4   ; seis premios
L_5DB6:
	ld (hl),a			;5db6
	add hl,de			;5db7
	djnz L_5DB6		;5db8
	ld hl,0e0a1h		;5dba   ; y los de las naves
	ld b,004h		;5dbd   ; cuatro sprites
	ld e,b			;5dbf
L_5DC0:
	ld (hl),a			;5dc0   ; los sprites de las dos naves
	add hl,de			;5dc1
	djnz L_5DC0		;5dc2
	ld (0e143h),a		;5dc4   ; y los de las bombas, las campanas y las nubes
	ld (0e14dh),a		;5dc7
	ld (0e377h),a		;5dca
	ld (0e387h),a		;5dcd
	ld (0e397h),a		;5dd0
	ld (0e355h),a		;5dd3
	ld (0e35dh),a		;5dd6
	call pon_el_color_del_marcador		;5dd9   ; el marcador
	ld ix,0e160h		;5ddc   ; los catorce enemigos
	ld de,00020h		;5de0
	ld b,00eh		;5de3
L_5DE5:
	ld (ix+001h),0ffh		;5de5   ; los catorce enemigos, apagados
	ld (ix+007h),0e0h		;5de9   ; y sus sprites, fuera
	ld (ix+014h),008h		;5ded   ; con su espera de disparo
	add ix,de		;5df1
	djnz L_5DE5		;5df3
	ld hl,0e334h		;5df5   ; las dos nubes
	ld (hl),028h		;5df8
	inc hl			;5dfa
	ld (hl),028h		;5dfb
	call descomprime_el_mapa		;5dfd   ; el mapa, a la RAM
	ld de,06750h		;5e00   ; los sprites del marcador
	call sube_bloque		;5e03
	ld hl,03b80h		;5e06   ; y se releen de la VRAM, que es donde estan colocados
	ld de,0eb00h		;5e09
	ld bc,00051h		;5e0c
	call 00059h		;5e0f   ; BIOS LDIRMV - Block transfers to memory from VRAM
	ld de,08e8fh		;5e12   ; los patrones de sprite comunes: las naves y los disparos
	ld hl,01800h		;5e15
	ld bc,01100h		;5e18
	call sube_patrones_de_sprite		;5e1b
	ld de,08f9fh		;5e1e   ; y las campanas
	ld hl,01a20h		;5e21
	ld bc,00501h		;5e24
	call sube_patrones_de_sprite		;5e27
	ld de,0903fh		;5e2a   ; y un bloque suelto mas
	call sube_bloque		;5e2d
	ld hl,01d40h		;5e30   ; los ultimos, sin filtro
	ld de,04aa9h		;5e33
	ld c,000h		;5e36
	call sube_bloque_a_hl		;5e38
	ld a,(0e002h)		;5e3b   ; el bit 6 de los bits de modo
	add a,a			;5e3e
	ret p			;5e3f   ; sin el no hay musica: es la demostracion
	ld a,0d6h		;5e40   ; y con el, arranca la de la fase
	ld (0e05dh),a		;5e42
	ld a,0e2h		;5e45
	jp pide_un_sonido_si_se_juega		;5e47
pon_veinte_alternas:
	ld b,014h		;5e4a   ; veinte casillas de dos en dos
L_5E4C:
	ld (hl),a			;5e4c
	inc l			;5e4d
	inc l			;5e4e
	djnz L_5E4C		;5e4f
	ret			;5e51

; ----------------------------------------------------------------------
; EL CUADRO DE JUEGO. Lo que corre entero en cada interrupcion mientras se juega: primero se sube a la VRAM lo que se calculo en el cuadro anterior -sprites y pantalla-, y luego se calcula el siguiente. Ese orden es lo que hace que el dibujo no parpadee.
; ----------------------------------------------------------------------
el_cuadro_de_juego:
	call sube_los_sprites		;5e52   ; los sprites, a la VRAM
	call sube_la_pantalla		;5e55   ; y la pantalla
	call avanza_el_decorado		;5e58   ; el decorado avanza una fila
	call prepara_el_marcador		;5e5b   ; el marcador
	call mira_si_toca_nube		;5e5e
	call mira_si_toca_musica		;5e61
	call pasa_de_fase		;5e64
	ld a,(0e07fh)		;5e67   ; si se acabo la partida, no se calcula nada mas
	and a			;5e6a
	ret nz			;5e6b
	call saca_las_oleadas		;5e6c   ; las oleadas
	call mueve_los_grandes		;5e6f   ; y los enemigos
	call es_el_segundo_jugador		;5e72   ; el segundo jugador
	jr nz,el_cuadro_de_los_dos		;5e75
	ld a,(0e077h)		;5e77   ; mientras le quede partida
	and a			;5e7a
	jp z,lo_que_corre_siempre		;5e7b
	ld a,(0e078h)		;5e7e
	rra			;5e81
	jr nc,L_5E89		;5e82
	call se_estrella_la_uno		;5e84   ; la nave en llamas
	jr L_5EA6		;5e87
L_5E89:
	ld a,(0e087h)		;5e89   ; con potencia puesta
	and a			;5e8c
	jr z,L_5E94		;5e8d
	call nace_el_disparo_uno		;5e8f   ; va por el guion de potencia
	jr L_5EA3		;5e92
L_5E94:
	call mueve_el_marcador_de_potencia		;5e94   ; y si no, se lee el mando
	call mueve_la_nave_uno		;5e97   ; se mueve
	call la_nave_dos_sigue_a_la_uno		;5e9a   ; se dispara
	call dispara_el_uno		;5e9d   ; las bombas
	call saca_el_arma_del_uno		;5ea0   ; y los choques
L_5EA3:
	call dibuja_la_nave_uno		;5ea3   ; y se colocan sus sprites
L_5EA6:
	ld a,(0e077h)		;5ea6
	and a			;5ea9
	jp z,lo_que_corre_siempre		;5eaa
	jp lo_que_va_suelto		;5ead

; ----------------------------------------------------------------------
; CUANDO JUEGAN LOS DOS. Twin Bee tiene un truco que casi ningun juego de dos jugadores de la epoca: si las dos naves se dan la mano, se pegan y vuelan juntas. Aqui se mira si los dos mandos empujan en direcciones compatibles, y (0xE094) queda a cero en cuanto uno de los dos tira para otro lado, que es lo que las separa.
; ----------------------------------------------------------------------
el_cuadro_de_los_dos:
	ld a,(0e083h)		;5eb0   ; los bits de estado de la pareja
	ld c,a			;5eb3
	and 010h		;5eb4   ; el bit 4: van agarradas
	jr z,mueve_la_nave_del_uno		;5eb6
	rl c		;5eb8
	ld de,0e007h		;5eba   ; el mando del uno
	ld hl,0e009h		;5ebd   ; y el del dos
	jr c,L_5EC3		;5ec0
	ex de,hl			;5ec2
L_5EC3:
	ld a,(de)			;5ec3
	ld c,a			;5ec4
	ld b,(hl)			;5ec5
	or (hl)			;5ec6
	ld (0e094h),a		;5ec7   ; lo que empujan los dos juntos
	bit 2,c		;5eca   ; arriba uno y abajo el otro: se sueltan
	jr z,L_5ED2		;5ecc
	bit 3,b		;5ece
	jr nz,L_5EF2		;5ed0
L_5ED2:
	rr c		;5ed2   ; y cada direccion contraria
	jr nc,L_5EDA		;5ed4
	bit 1,b		;5ed6
	jr nz,L_5EEC		;5ed8
L_5EDA:
	rr c		;5eda
	jr nc,L_5EE2		;5edc
	bit 0,b		;5ede
	jr nz,L_5EEC		;5ee0
L_5EE2:
	rr c		;5ee2
	rr c		;5ee4
	jr nc,mueve_la_nave_del_uno		;5ee6
	bit 2,b		;5ee8
	jr z,mueve_la_nave_del_uno		;5eea
L_5EEC:
	xor a			;5eec   ; deja la marca a cero
	ld (0e094h),a		;5eed
	jr mueve_la_nave_del_uno		;5ef0
L_5EF2:
	ld hl,0e083h		;5ef2   ; y al soltarse, los dos vuelven a su estado suelto
	ld a,(hl)			;5ef5
	and 00fh		;5ef6
	ld (hl),a			;5ef8
	inc l			;5ef9
	ld a,(hl)			;5efa
	and 00fh		;5efb
	ld (hl),a			;5efd
mueve_la_nave_del_uno:
	ld a,(0e077h)		;5efe   ; el bit 0: le queda partida al primero
	rra			;5f01
	jr nc,mueve_la_nave_del_dos		;5f02
	ld a,(0e078h)		;5f04   ; el bit 0 del estado: se esta muriendo
	rra			;5f07
	jr nc,L_5F0F		;5f08
	call se_estrella_la_uno		;5f0a   ; la nave en llamas
	jr mueve_la_nave_del_dos		;5f0d
L_5F0F:
	ld a,(0e087h)		;5f0f   ; con potencia
	and a			;5f12
	jr z,L_5F1A		;5f13
	call nace_el_disparo_uno		;5f15
	jr mueve_la_nave_del_dos		;5f18
L_5F1A:
	call mueve_la_nave_uno		;5f1a
	call dibuja_la_nave_uno		;5f1d
	call dispara_el_dos		;5f20
	call saca_el_arma_del_uno		;5f23
mueve_la_nave_del_dos:
	ld a,(0e077h)		;5f26   ; y lo mismo para el segundo, con el bit 1
	rra			;5f29
	rra			;5f2a
	jr nc,L_5F50		;5f2b
	ld a,(0e078h)		;5f2d
	rra			;5f30
	rra			;5f31
	jr nc,L_5F39		;5f32
	call se_estrella_la_dos		;5f34
	jr L_5F50		;5f37
L_5F39:
	ld a,(0e088h)		;5f39
	and a			;5f3c
	jr z,L_5F44		;5f3d
	call nace_el_disparo_dos		;5f3f
	jr L_5F50		;5f42
L_5F44:
	call mueve_la_nave_dos		;5f44
	call dibuja_la_nave_dos		;5f47
	call dispara_el_dos_de_verdad		;5f4a
	call saca_el_arma_del_dos		;5f4d
L_5F50:
	ld a,(0e077h)		;5f50
	and a			;5f53
	jr z,lo_que_corre_siempre		;5f54
	call el_uno_tiene_bomba		;5f56   ; los dos apagados
	ld c,a			;5f59
	call el_dos_tiene_bomba		;5f5a
	or c			;5f5d
	call z,mira_si_se_dan_la_mano		;5f5e   ; y entonces se acaba
lo_que_va_suelto:
	call coloca_los_sprites_de_las_naves		;5f61   ; los disparos
	call mueve_los_disparos		;5f64   ; las bombas
	call mueve_las_armas		;5f67   ; los choques
	call coloca_los_disparos		;5f6a
	call coloca_las_armas		;5f6d
lo_que_corre_siempre:
	call saca_la_bomba_del_uno		;5f70   ; el decorado y las campanas van siempre, se juegue o no
	call mueve_las_bombas		;5f73   ; las bombas
	call saca_las_nubes		;5f76   ; y las nubes van siempre, se juegue o no
	call mueve_las_nubes		;5f79
	call reparte_el_premio		;5f7c
	call mira_las_campanas_contra_la_nave		;5f7f   ; quien recoge la campana
	call mueve_las_campanas		;5f82
	call saca_la_oleada_del_jefe		;5f85   ; la oleada del jefe
	call mueve_los_catorce		;5f88
	call mueve_los_enemigos		;5f8b   ; los enemigos se mueven
	call coloca_los_enemigos		;5f8e   ; y se colocan
	call recupera_la_bomba		;5f91
	call mira_los_disparos_contra_los_enemigos		;5f94
	call mira_los_disparos_contra_el_jefe		;5f97
	ld a,(0ebf2h)		;5f9a   ; con el jefe puesto no hay nubes
	and a			;5f9d
	jr nz,L_5FA9		;5f9e
	call mira_si_le_dan_a_la_nube		;5fa0
	call mira_las_naves_contra_los_grandes		;5fa3
	call mira_el_arma_contra_los_grandes		;5fa6
L_5FA9:
	ld hl,0e097h		;5fa9   ; las dos cuentas de nave recien nacida
	ld b,002h		;5fac
L_5FAE:
	ld a,(hl)			;5fae
	and a			;5faf
	jr z,L_5FB3		;5fb0
	dec (hl)			;5fb2   ; una menos
L_5FB3:
	inc l			;5fb3
	djnz L_5FAE		;5fb4
	call mira_las_naves_contra_los_enemigos		;5fb6
	call mira_las_naves_contra_los_disparos		;5fb9
	jp mira_las_naves_contra_el_jefe		;5fbc

; ----------------------------------------------------------------------
; LA DEMOSTRACION ES UNA PARTIDA GRABADA. La escena 2 monta una partida de verdad -misma RAM, misma fase, mismo codigo- y le mete el mando por la misma puerta por la que entra el del jugador: 0x600E salta a 0x481A con HL en 0xE007, que es donde 0x4821 deja lo que ha leido del mando. Lo que se juega son los 28 valores del guion de 0x6016, uno cada 32 cuadros, hasta el 0xFF que corta la partida. Y para que la misma tira de pulsaciones de siempre la misma partida hace falta que el azar tambien sea el mismo: por eso 0x5FCF pone A CERO EL REGISTRO R del Z80, que es de donde el juego saca sus numeros al azar en 0xAF75, 0xB2CE, 0xB757, 0xBE0C y 0xBE36. Sin ese `ld r,a` la demostracion se descarrilaria sola.
; ----------------------------------------------------------------------
arranca_la_demostracion:
	ld hl,02000h		;5fbf   ; por donde va el decorado
	ld (0e00bh),hl		;5fc2
	ld hl,0e070h		;5fc5   ; la RAM de partida entera
	ld de,0e071h		;5fc8
	ld bc,00f0eh		;5fcb
	xor a			;5fce
	ld r,a		;5fcf   ; el refresco a cero: asi el azar es el mismo en cada vuelta
	ld (hl),a			;5fd1
	ldir		;5fd2
	inc a			;5fd4
	ld (0e076h),a		;5fd5   ; fase 1
	ld (0e077h),a		;5fd8   ; y una nave
	ld a,01eh		;5fdb   ; con el contador de cuadros puesto
	ld (0e003h),a		;5fdd
	call empieza_la_partida		;5fe0   ; y a jugar como si hubiera alguien
monta_el_decorado:		; Sube los patrones, el color, los sprites de la fase y la primera pantalla
	call sube_los_patrones_del_decorado		;5fe3   ; los patrones del decorado
	call sube_el_color_del_decorado		;5fe6   ; y su color
	call sube_los_sprites_de_la_fase		;5fe9   ; los sprites de los enemigos de esta fase
	call sube_los_sprites		;5fec
	call monta_las_veinticuatro_filas		;5fef   ; las 24 filas
	jp sube_la_pantalla		;5ff2
gasta_el_guion_de_la_demostracion:
	ld hl,0e00ch		;5ff5   ; el reloj del guion
	dec (hl)			;5ff8
	jr nz,L_6000		;5ff9
	ld (hl),020h		;5ffb   ; cada 32 cuadros
	dec hl			;5ffd
	inc (hl)			;5ffe   ; se avanza una pulsacion
	inc hl			;5fff
L_6000:
	dec hl			;6000
	ld a,(hl)			;6001
	ld hl,06016h		;6002   ; y se saca del guion
	call suma_a_a_hl		;6005
	ld a,(hl)			;6008
	cp 0ffh		;6009   ; con 0xFF se acabo la demostracion
	ld hl,0e007h		;600b
	jp nz,guarda_lo_que_acaba_de_pulsarse		;600e   ; y si no, entra como si fuera el mando
	xor a			;6011
	ld (0e077h),a		;6012
	ret			;6015

; ----------------------------------------------------------------------
; DATOS guion_del_zumbido: Los valores que 0x6002 va soltando, uno cada 32
;   cuadros, hasta el 0xFF que apaga el aviso
;   0x6016..0x6033  (29 bytes)
DATA_guion_del_zumbido:
	defb 000h	; 6016
	defb 000h	; 6017
	defb 008h	; 6018
	defb 000h	; 6019
	defb 000h	; 601a
	defb 014h	; 601b
	defb 000h	; 601c
	defb 018h	; 601d
	defb 014h	; 601e
	defb 018h	; 601f
	defb 018h	; 6020
	defb 014h	; 6021
	defb 038h	; 6022
	defb 034h	; 6023
	defb 018h	; 6024
	defb 014h	; 6025
	defb 010h	; 6026
	defb 012h	; 6027
	defb 014h	; 6028
	defb 018h	; 6029
	defb 014h	; 602a
	defb 008h	; 602b
	defb 000h	; 602c
	defb 008h	; 602d
	defb 011h	; 602e
	defb 014h	; 602f
	defb 014h	; 6030
	defb 01ah	; 6031
	defb 0ffh	; 6032

; ======================================================================
; CODIGO 0x6033..0x60cd  (154 bytes)
; ======================================================================


niega_hl:
	xor a			;6033   ; 0 - HL, con el prestamo
	sub l			;6034
	ld l,a			;6035
	ld a,000h		;6036
	sbc a,h			;6038
	ld h,a			;6039
	ret			;603a
niega_de:
	ex de,hl			;603b
	call niega_hl		;603c
	ex de,hl			;603f
	ret			;6040
niega_bc:
	xor a			;6041   ; 0 - BC
	sub c			;6042
	ld c,a			;6043
	ld a,000h		;6044
	sbc a,b			;6046
	ld b,a			;6047
	ret			;6048
apaga_cuatro_sprites:
	push bc			;6049   ; cuatro bytes a cero
	ld b,004h		;604a
	call borra_b_bytes		;604c
	ld (hl),0e0h		;604f   ; y la Y del sprite fuera
	inc l			;6051
	ld (hl),a			;6052
	jr L_605D		;6053
apaga_siete_sprites:
	push bc			;6055
	ld b,007h		;6056
	call borra_b_bytes		;6058
	ld (hl),0e0h		;605b
L_605D:
	inc l			;605d   ; los dos ultimos bytes
	ld (hl),a			;605e
	inc l			;605f
	ld (hl),a			;6060
	pop bc			;6061
	ret			;6062
apaga_y_borra:
	ld b,007h		;6063   ; siete bytes a cero
	call borra_b_bytes		;6065
	ld (hl),0e0h		;6068
	inc l			;606a
	ld b,008h		;606b
	jr borra_b_bytes		;606d
borra_dieciseis:
	ld b,010h		;606f
borra_b_bytes:
	xor a			;6071   ; A vale cero
L_6072:
	ld (hl),a			;6072
	inc l			;6073
	djnz L_6072		;6074
	ret			;6076
cambia_la_musica:
	ld a,(0e05eh)		;6077   ; que melodia esta sonando
	cp 0d6h		;607a   ; la de la campana
	jr z,L_6096		;607c
	ld a,(0e05dh)		;607e
	cp 0e2h		;6081
	jr nc,L_609F		;6083
	cp 0dah		;6085   ; segun por donde vaya la fase
	jr c,L_609A		;6087
	ld c,0dch		;6089   ; cambia a la de mas ritmo
	jr z,L_6093		;608b
	cp 0deh		;608d
	jr nz,L_609F		;608f
	ld c,0e0h		;6091
L_6093:
	ld a,c			;6093
	jr L_609C		;6094
L_6096:
	xor a			;6096
	ld (0e05eh),a		;6097
L_609A:
	ld a,0d8h		;609a
L_609C:
	ld (0e05dh),a		;609c
L_609F:
	ld a,0e5h		;609f   ; y suena el aviso
	jr $+55		;60a1
L_60A3:
	ld a,(0e012h)		;60a3   ; lo que esta sonando en el otro canal
	cp 0dah		;60a6   ; la de la fase
	ld c,0dch		;60a8   ; se pasa a la siguiente
	jr z,$+40		;60aa
	cp 0deh		;60ac   ; o la de mas ritmo
	ld c,0e0h		;60ae   ; o a la de mas ritmo aun
	jr z,$+34		;60b0
	ld a,(0e05eh)		;60b2   ; y lo que suena en el de abajo
	cp 0dah		;60b5
	ld c,0d6h		;60b7   ; la de siempre
	jr nc,$+25		;60b9
	ld a,(0e012h)		;60bb   ; el de arriba otra vez
	cp 0d8h		;60be
	jr z,$+27		;60c0
	ld a,(0e05dh)		;60c2
	cp 0d8h		;60c5
	ld c,0d6h		;60c7
	jr z,$+9		;60c9
	jr $+11		;60cb

; ----------------------------------------------------------------------
; DATOS codigo_al_que_no_llega_nadie: `ld a,0D6h` y `ld (0E05Eh),a`: cinco
;   bytes que ningun salto alcanza. El `jr z` de 0x60C9 cae en 0x60D2 y el
;   `jr` de 0x60CB en 0x60D6, o sea justo por debajo y por encima. Hace lo
;   mismo que 0x60DB, que si se usa
;   0x60cd..0x60d2  (5 bytes)
DATA_codigo_al_que_no_llega_nadie:
	defb 03eh,0d6h,032h,05eh,0e0h	; 60cd

; ======================================================================
; CODIGO 0x60d2..0x6132  (96 bytes)
; ======================================================================


L_60D2:
	ld a,c			;60d2
	ld (0e05dh),a		;60d3
L_60D6:
	ld a,094h		;60d6
L_60D8:
	jp pide_un_sonido_si_se_juega		;60d8
L_60DB:
	ld a,0d6h		;60db   ; la melodia de la campana, fuera
	ld (0e05eh),a		;60dd
	jr L_60D6		;60e0
musica_de_vida_extra:
	ld a,(0e05dh)		;60e2   ; la que suene ahora
	cp 0dah		;60e5
	ld c,0dch		;60e7
	jr z,L_60F1		;60e9
	cp 0deh		;60eb
	ld c,0e0h		;60ed
	jr nz,L_60F5		;60ef
L_60F1:
	ld a,c			;60f1
	ld (0e05dh),a		;60f2
L_60F5:
	ld a,0e8h		;60f5   ; y encima el aviso de vida extra
	jr L_60D8		;60f7
suma_a_la_posicion:
	ld c,(hl)			;60f9   ; la velocidad horizontal
	inc l			;60fa   ; al byte alto
	ld b,(hl)			;60fb   ; la velocidad horizontal, byte alto
	inc l			;60fc
	ld a,e			;60fd   ; la vertical, sumada con su fraccion
	add a,(hl)			;60fe   ; la fraccion de la vertical
	ld (hl),a			;60ff
	inc hl			;6100   ; y el byte entero
	ld a,d			;6101
	adc a,(hl)			;6102
	ld (hl),a			;6103
	ld d,a			;6104   ; la vertical nueva, a D
	inc l			;6105
	ld a,c			;6106   ; y luego la horizontal
	add a,(hl)			;6107   ; la fraccion de la horizontal
	ld (hl),a			;6108
	inc hl			;6109   ; y el byte entero
	ld a,b			;610a
	adc a,(hl)			;610b
	ld (hl),a			;610c
	ret			;610d
prepara_el_marcador:
	ld de,(0ebb6h)		;610e   ; el hito que espera el marcador
	ld hl,(0ebf0h)		;6112   ; por donde va el decorado
	rst 20h			;6115   ; y si no ha llegado, nada
	ret nz			;6116
	ld hl,0ebb8h		;6117   ; el contador de fase
	call avanza_hasta_cinco		;611a   ; el contador de fase, uno mas
	ld hl,06132h		;611d   ; el hito siguiente
	call palabra_de_tabla		;6120   ; la palabra que le toca
	ld (0ebb6h),de		;6123   ; y se guarda
	ld a,001h		;6127   ; con la marca del jefe
	ld (0ebf2h),a		;6129
	ld (0e155h),a		;612c   ; con la de que dispara
	jp L_9648		;612f   ; y sus sprites

; ----------------------------------------------------------------------
; DATOS tabla_de_fases: Cinco palabras, una por fase, que 0x611D y 0x4113
;   meten en (0xEBB6): donde empieza cada una
;   0x6132..0x613c  (10 bytes)
DATA_tabla_de_fases:
	defw 00105h,00249h,003b1h,004f8h,006e0h	; 6132

; ======================================================================
; CODIGO 0x613c..0x61d5  (153 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL BUCLE DE LAS FASES. Hay cinco escenarios y noventa y nueve fases: (0xE07D) es el numero que se ve, en BCD, y sube de uno en uno hasta 99, mientras que (0xE076) es el escenario, y cuando su nibble bajo llega a SEIS vuelve a 0x11, o sea a la primera con el nibble alto a uno. De ahi en adelante el juego da vueltas a los mismos cinco escenarios contando vueltas en el nibble alto. Al llegar a la fase 99 se acaba la partida, y esa es la unica manera de terminar Twin Bee.
; ----------------------------------------------------------------------
pasa_de_fase:
	ld a,(0e07ch)		;613c   ; la cuenta atras del final de fase
	dec a			;613f
	ret nz			;6140   ; mientras no llegue a cero, nada
	ld (0e07ch),a		;6141   ; la cuenta, a cero
	ld (0ebf2h),a		;6144   ; y el jefe, fuera
	ld a,(0e07dh)		;6147   ; el numero de fase, en BCD
	cp 099h		;614a   ; con 99 se acabo el juego
	jr z,L_618E		;614c
	add a,001h		;614e   ; una mas
	daa			;6150
	ld (0e07dh),a		;6151
	ld hl,0e076h		;6154   ; y el escenario
	inc (hl)			;6157   ; uno mas
	ld a,(hl)			;6158
	and 00fh		;6159   ; su nibble bajo
	sub 006h		;615b   ; al llegar a seis
	jr nz,L_6171		;615d
	ld (0e3a0h),a		;615f   ; el contador de oleadas, a cero
	inc a			;6162
	ld (0e3a1h),a		;6163   ; con una oleada pendiente
	ld (0ebfdh),a		;6166   ; y sin aviso
	ld (hl),011h		;6169   ; vuelve al 0x11: primer escenario, segunda vuelta
	ld hl,0001ah		;616b   ; y el decorado, a la fila 26
	ld (0ebf0h),hl		;616e
L_6171:
	ld a,(0e07dh)		;6171   ; el numero de fase
	cp 006h		;6174   ; en la fase 6
	jr z,L_617C		;6176
	cp 011h		;6178   ; y en la 17
	jr nz,L_6180		;617a
L_617C:
	ld hl,0e07eh		;617c
	inc (hl)			;617f   ; sube la dificultad
L_6180:
	ld a,0d6h		;6180
	call suena_el_cambio		;6182
	call sube_los_patrones_de_la_fase		;6185   ; los patrones del escenario nuevo
	call sube_el_color_comun		;6188   ; su color
	jp sube_los_sprites_de_la_fase		;618b   ; y sus enemigos
L_618E:
	ld a,001h		;618e   ; la marca de partida acabada
	ld (0e07fh),a		;6190
	ld a,0d8h		;6193   ; con la melodia del final
suena_el_cambio:
	ld (0e05dh),a		;6195
	ld a,0eeh		;6198
	jp pide_un_sonido_si_se_juega		;619a
mira_si_toca_nube:
	ld de,(0ebb0h)		;619d   ; por donde va el decorado
	ld hl,(0ebf0h)		;61a1   ; comparado con el siguiente hito
	rst 20h			;61a4
	ret nz			;61a5   ; si no ha llegado, nada
	ld hl,0ebb2h		;61a6
	ld c,00ah		;61a9
	call avanza_hasta_c		;61ab
	ld hl,061d5h		;61ae   ; el hito siguiente
	call palabra_de_tabla		;61b1
	ld a,d			;61b4
	and 07fh		;61b5   ; sin el bit 15, que es una bandera
	ld d,a			;61b7
	ld (0ebb0h),de		;61b8
	ld a,(hl)			;61bc   ; y ese bit dice si toca nube
	rlca			;61bd
	and 001h		;61be
	ld (0e365h),a		;61c0
	ld (0e154h),a		;61c3
	ret z			;61c6
pon_el_color_del_marcador:
	ld hl,0efbbh		;61c7
	ld b,004h		;61ca
L_61CC:
	ld (hl),00fh		;61cc   ; el color de las cuatro cifras
	inc l			;61ce   ; cuatro bytes por sprite
	inc l			;61cf
	inc l			;61d0
	inc l			;61d1
	djnz L_61CC		;61d2
	ret			;61d4

; ----------------------------------------------------------------------
; DATOS tabla_de_fases_2: Cinco palabras mas, que 0x4131 mete en (0xEBB0)
;   0x61d5..0x61e9  (20 bytes)
DATA_tabla_de_fases_2:
	defw 00021h,080dfh,0010ch,08223h,00250h,0838bh,003b8h,084d2h	; 61d5
	defw 004ffh,086bah	; 61e5

; ======================================================================
; CODIGO 0x61e9..0x6210  (39 bytes)
; ======================================================================


mira_si_toca_musica:
	ld de,(0ebb3h)		;61e9   ; el hito de la musica
	ld hl,(0ebf0h)		;61ed
	rst 20h			;61f0
	ret nz			;61f1
	ld hl,0ebb5h		;61f2
	call avanza_hasta_cinco		;61f5
	ld hl,06210h		;61f8
	call palabra_de_tabla		;61fb
	ld a,(0e076h)		;61fe   ; el escenario
	rra			;6201
	ld a,0dah		;6202   ; uno de cada dos, una melodia
	jr c,L_6208		;6204
	ld a,0deh		;6206
L_6208:
	ld (0ebb3h),de		;6208
	ld (0e05eh),a		;620c   ; y se pide
	ret			;620f

; ----------------------------------------------------------------------
; DATOS tabla_de_fases_3: Y otras cinco, que 0x413F mete en (0xEBB3)
;   0x6210..0x621a  (10 bytes)
DATA_tabla_de_fases_3:
	defw 000ebh,0022fh,00397h,004deh,006c6h	; 6210

; ======================================================================
; CODIGO 0x621a..0x6316  (252 bytes)
; ======================================================================


avanza_hasta_cinco:
	ld c,005h		;621a
avanza_hasta_c:
	inc (hl)			;621c   ; uno mas
	ld a,(hl)			;621d
	cp c			;621e   ; y al llegar a C, vuelta a cero
	ret nz			;621f
	xor a			;6220
	ld (hl),a			;6221
	ret			;6222
mueve_el_marcador_de_potencia:
	ld hl,0e080h		;6223   ; la barra de potencia, de dos en dos
	inc (hl)			;6226   ; dos pixeles por cuadro
	inc (hl)			;6227
	ld a,(hl)			;6228
	sub 028h		;6229   ; y da la vuelta en 0x28
	ret nz			;622b
	ld (hl),a			;622c   ; y vuelve a cero
	ret			;622d
mueve_la_nave_dos:
	ld a,(0e084h)		;622e   ; el estado de la nave 2
	and 010h		;6231   ; el bit 4: agarradas
	ret nz			;6233
	ld ix,0e0ach		;6234   ; sus sprites
	ld iy,0e009h		;6238   ; su mando
	ld hl,0e090h		;623c   ; y su potencia
	ld a,002h		;623f
	ld (0ebc0h),a		;6241   ; con la marca del segundo
	ld a,(0e082h)		;6244   ; su potencia
	jr L_6264		;6247
mueve_la_nave_uno:
	ld a,(0e083h)		;6249   ; y lo mismo para la 1
	and 010h		;624c   ; el bit 4 tambien
	jp nz,mueve_las_dos_agarradas		;624e
	ld ix,0e0a0h		;6251
	ld iy,0e007h		;6255
	ld hl,0e08fh		;6259
	ld a,001h		;625c
	ld (0ebc0h),a		;625e   ; con la marca del primero
	ld a,(0e081h)		;6261   ; su potencia
L_6264:
	push hl			;6264   ; el puntero, a salvo
	ld hl,06316h		;6265   ; la velocidad que le toca a esa potencia
	call palabra_de_tabla		;6268   ; la palabra que le toca
	ld c,e			;626b   ; la velocidad, en BC
	ld b,d			;626c
	pop hl			;626d
	ld a,(hl)			;626e   ; si hay recuerdo de mando
	and a			;626f
	ld a,(iy+000h)		;6270   ; lo que se lee ahora
	jr z,L_6279		;6273   ; se usa el del cuadro
	dec (hl)			;6275   ; y si no, el que se guardo
	inc l			;6276
	inc l			;6277
	ld a,(hl)			;6278
L_6279:
	push af			;6279   ; el mando entero, a salvo
	and 003h		;627a   ; los bits de arriba y abajo
	jr nz,L_6283		;627c   ; ninguno o los dos: no se mueve
L_627E:
	ld de,00000h		;627e   ; sin velocidad
	jr L_628B		;6281
L_6283:
	cp 003h		;6283
	jr z,L_627E		;6285   ; los dos: tampoco
	rra			;6287   ; el bit 0: hacia arriba
	call c,niega_de		;6288   ; hacia arriba, la velocidad cambia de signo
L_628B:
	ld l,(ix+000h)		;628b   ; la posicion vertical
	ld h,(ix+001h)		;628e
	add hl,de			;6291   ; mas la velocidad
	ld (ix+000h),l		;6292   ; y de vuelta al bloque
	ld (ix+001h),h		;6295
	ld a,h			;6298
	cp 0afh		;6299   ; con el tope de abajo
	jr c,L_62A8		;629b   ; por debajo de 0xAF
	ld hl,0af00h		;629d   ; se clava en el tope
	ld (ix+000h),l		;62a0
	ld (ix+001h),h		;62a3
	jr L_62B5		;62a6
L_62A8:
	cp 010h		;62a8   ; y el de arriba
	jr nc,L_62B5		;62aa   ; por encima de 0x10
	ld hl,01000h		;62ac   ; y se clava en el de arriba
	ld (ix+000h),l		;62af
	ld (ix+001h),h		;62b2
L_62B5:
	ld a,(0ebc0h)		;62b5   ; la nave 1
	dec a			;62b8   ; solo la 1 deja rastro
	jr nz,L_62C7		;62b9
	ex de,hl			;62bb
	ld hl,0e0b0h		;62bc   ; deja rastro: donde estuvo, para que la 2 la siga
	ld a,(0e080h)		;62bf   ; por donde va el rastro
	add a,l			;62c2
	ld l,a			;62c3
	ld (hl),e			;62c4   ; la vertical
	inc hl			;62c5
	ld (hl),d			;62c6
L_62C7:
	pop af			;62c7   ; el mando, de vuelta
	and 00ch		;62c8   ; y ahora los bits de izquierda y derecha
	jr nz,L_62D1		;62ca
L_62CC:
	ld bc,00000h		;62cc   ; ninguno o los dos: quieta
	jr L_62DA		;62cf
L_62D1:
	cp 00ch		;62d1
	jr z,L_62CC		;62d3   ; los dos: tampoco
	bit 2,a		;62d5   ; el bit 2: a la izquierda
	call nz,niega_bc		;62d7   ; a la izquierda, la velocidad cambia de signo
L_62DA:
	ld l,(ix+002h)		;62da   ; la posicion horizontal
	ld h,(ix+003h)		;62dd
	add hl,bc			;62e0   ; mas la velocidad
	ld (ix+002h),l		;62e1
	ld (ix+003h),h		;62e4
	ld a,h			;62e7
	cp 0e8h		;62e8   ; el tope de la derecha
	jr c,L_62F7		;62ea   ; por debajo de 0xE8
	ld hl,0e800h		;62ec   ; se clava
	ld (ix+002h),l		;62ef
	ld (ix+003h),h		;62f2
	jr L_6304		;62f5
L_62F7:
	cp 008h		;62f7   ; y el de la izquierda
	jr nc,L_6304		;62f9
	ld hl,00800h		;62fb
	ld (ix+002h),l		;62fe
	ld (ix+003h),h		;6301
L_6304:
	ld a,(0ebc0h)		;6304   ; la nave 1 deja tambien aqui su rastro
	dec a			;6307
	ret nz			;6308
	ex de,hl			;6309
	ld hl,0e0d8h		;630a   ; deja rastro tambien de la horizontal
	ld a,(0e080h)		;630d
	add a,l			;6310
	ld l,a			;6311
	ld (hl),e			;6312
	inc hl			;6313
	ld (hl),d			;6314
	ret			;6315

; ----------------------------------------------------------------------
; DATOS velocidades_del_disparo: Ocho palabras que 0x6265 indexa con (0xE081),
;   el nivel de potencia: cuanto avanza el disparo por cuadro
;   0x6316..0x6326  (16 bytes)
DATA_velocidades_del_disparo:
	defw 00280h,00300h,00380h,00400h,00500h,00600h,00700h,00800h	; 6316

; ======================================================================
; CODIGO 0x6326..0x65d6  (688 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LAS DOS NAVES AGARRADAS SE MUEVEN COMO UNA. Cuando los dos jugadores se dan la mano, el mando que manda es (0xE094) -la suma de los dos, que 0x5EC7 deja a cero en cuanto uno tira para el otro lado- y las dos naves comparten posicion. El bucle de 0x6388 comprueba los topes de LAS DOS antes de mover: si a cualquiera de ellas se le acaba la pantalla, no se mueve ninguna.
; ----------------------------------------------------------------------
mueve_las_dos_agarradas:
	ld a,(0e081h)		;6326   ; la potencia del primero manda
	ld hl,06316h		;6329   ; la tabla de velocidades
	call palabra_de_tabla		;632c
	ld c,e			;632f   ; la velocidad, en BC
	ld b,d			;6330
	ld a,(0e094h)		;6331   ; el mando de la pareja
	push af			;6334   ; el mando, a salvo
	and 003h		;6335   ; los bits de arriba y abajo
	jr nz,L_633E		;6337
L_6339:
	ld de,00000h		;6339   ; ninguno o los dos: quieta
	jr L_6347		;633c
L_633E:
	cp 003h		;633e
	jr z,L_6339		;6340
	bit 0,a		;6342   ; el bit 0: hacia arriba
	call nz,niega_de		;6344
L_6347:
	pop af			;6347   ; el mando, de vuelta
	and 00ch		;6348   ; y los de izquierda y derecha
	jr nz,L_6351		;634a
L_634C:
	ld bc,00000h		;634c   ; ninguno o los dos: quieta
	jr L_635A		;634f
L_6351:
	cp 00ch		;6351
	jr z,L_634C		;6353
	bit 2,a		;6355   ; el bit 2: a la izquierda
	call nz,niega_bc		;6357
L_635A:
	ld hl,(0e0a0h)		;635a   ; la posicion vertical, compartida
	add hl,de			;635d   ; mas la velocidad
	ld (0e0a0h),hl		;635e   ; a las dos naves
	ld (0e0ach),hl		;6361
	ld a,h			;6364
	cp 0afh		;6365   ; el tope de abajo
	jr c,L_6374		;6367
	ld hl,0af00h		;6369   ; y se clavan las dos
	ld (0e0a0h),hl		;636c
	ld (0e0ach),hl		;636f
	jr L_6381		;6372
L_6374:
	cp 010h		;6374   ; y el de arriba
	jr nc,L_6381		;6376
	ld hl,01000h		;6378   ; igual arriba
	ld (0e0a0h),hl		;637b
	ld (0e0ach),hl		;637e
L_6381:
	ld hl,(0e0a2h)		;6381   ; la horizontal de la primera
	ld e,c			;6384   ; la velocidad, a DE
	ld d,b			;6385
	ld b,002h		;6386   ; y se miran las dos
L_6388:
	ld a,h			;6388
	cp 0e8h		;6389   ; el tope de la derecha
	jr nc,L_63AD		;638b
	cp 008h		;638d   ; y el de la izquierda
	jr c,L_63B2		;638f
	add hl,de			;6391   ; si cabe el paso
	ld a,h			;6392
	cp 0e8h		;6393
	ret nc			;6395   ; y si se sale, no se mueve ninguna
	cp 008h		;6396
	ret c			;6398
	ld hl,(0e0aeh)		;6399   ; se mira la otra nave
	djnz L_6388		;639c   ; la segunda vuelta
L_639E:
	ld hl,(0e0a2h)		;639e   ; y solo si caben las dos, se mueven
	add hl,de			;63a1   ; la primera se mueve
	ld (0e0a2h),hl		;63a2
	ld hl,(0e0aeh)		;63a5   ; y la segunda tambien
	add hl,de			;63a8
	ld (0e0aeh),hl		;63a9
	ret			;63ac
L_63AD:
	ld a,d			;63ad   ; contra el tope, se deja pasar si el paso va hacia dentro
	rla			;63ae   ; el bit 7 de D: el paso va hacia la izquierda
	jr c,L_639E		;63af
	ret			;63b1
L_63B2:
	ld a,d			;63b2
	rla			;63b3   ; y aqui al reves
	jr nc,L_639E		;63b4
	ret			;63b6

; ----------------------------------------------------------------------
; EL SEGUNDO JUGADOR PUEDE IR A RASTRA. Con el bit 1 del estado puesto, la nave 2 no se mueve sola: copia la posicion que la 1 tenia hace unos cuadros, sacandola del rastro circular de 40 casillas que 0x62BC y 0x6309 van dejando. De ahi la sensacion de que va enganchada por detras.
; ----------------------------------------------------------------------
la_nave_dos_sigue_a_la_uno:
	ld a,(0e083h)		;63b7
	bit 1,a		;63ba   ; el bit 1: va a rastra
	ret z			;63bc
	ld de,0e0a4h		;63bd   ; los dos sprites de la nave 2
	ld bc,00208h		;63c0   ; dos, y ocho de retraso
L_63C3:
	push bc			;63c3
	ld a,(0e080h)		;63c4   ; por donde va el rastro
	sub c			;63c7   ; ocho cuadros por detras
	jr nc,L_63CC		;63c8
	add a,028h		;63ca   ; dando la vuelta a las 40 posiciones
L_63CC:
	ld b,a			;63cc   ; el sitio del rastro
	ld hl,0e0b0h		;63cd   ; el rastro de verticales
	add a,l			;63d0   ; la entrada que le toca
	ld l,a			;63d1
	ldi		;63d2   ; la vertical
	ldi		;63d4   ; y la fraccion
	ld a,b			;63d6
	ld hl,0e0d8h		;63d7   ; y el rastro de horizontales
	add a,l			;63da
	ld l,a			;63db
	ldi		;63dc   ; y la horizontal
	ldi		;63de
	pop bc			;63e0
	ld a,c			;63e1
	add a,008h		;63e2   ; y ocho mas atras para el segundo sprite
	ld c,a			;63e4
	djnz L_63C3		;63e5   ; los dos sprites de la nave
	ret			;63e7
coloca_los_sprites_de_las_naves:
	ld a,(0e077h)		;63e8   ; los jugadores vivos
	rra			;63eb   ; el bit 0: le queda partida
	jr nc,L_63FC		;63ec
	ld ix,0e0a0h		;63ee   ; los sprites de la nave 1
	ld iy,0ef80h		;63f2
	ld hl,0e083h		;63f6
	call coloca_una_nave		;63f9
L_63FC:
	call es_el_segundo_jugador		;63fc   ; con dos jugadores
	jr z,coloca_la_pareja		;63ff   ; y agarradas, la 2 hereda los sprites de la 1
	ld a,(0e077h)		;6401   ; el bit 1: le queda partida al segundo
	rra			;6404
	rra			;6405
	ret nc			;6406
	ld ix,0e0ach		;6407
	ld iy,0ef88h		;640b
	ld hl,0e084h		;640f
coloca_una_nave:
	ld a,(ix+001h)		;6412   ; la Y, a los dos sprites de la nave
	ld (iy+000h),a		;6415
	ld (iy+004h),a		;6418
	bit 2,(hl)		;641b   ; el bit 2: se esta muriendo
	jr nz,L_6429		;641d
	ld a,(ix+003h)		;641f   ; y si no, la X normal
	ld (iy+001h),a		;6422
	ld (iy+005h),a		;6425
	ret			;6428
L_6429:
	ld a,(ix+003h)		;6429   ; muriendose, los dos sprites se separan
	sub 008h		;642c
	ld (iy+001h),a		;642e
	add a,010h		;6431
	ld (iy+005h),a		;6433
	ret			;6436
coloca_la_pareja:
	ld a,(0e077h)		;6437   ; agarradas, la 2 hereda los sprites de la 1
	rra			;643a
	ret nc			;643b
	ld l,(ix+005h)		;643c
	ld h,(ix+007h)		;643f
	ld (0ef88h),hl		;6442
	ld l,(ix+009h)		;6445
	ld h,(ix+00bh)		;6448
	ld (0ef8ch),hl		;644b
	ret			;644e
dibuja_la_nave_uno:
	ld a,(0e083h)		;644f   ; el estado de la nave 1
	bit 2,a		;6452   ; el bit 2: en llamas
	jr z,L_6468		;6454
	ld a,(0e003h)		;6456   ; y el dibujo alterna cada dos cuadros
	and 002h		;6459   ; el bit 1 del contador
	ld de,00f4ch		;645b   ; con un par de dibujos
	ld bc,00f50h		;645e
	jr nz,L_6485		;6461
	ld d,007h		;6463   ; o con el otro
	ld b,d			;6465
	jr L_6485		;6466
L_6468:
	ld a,(0e08dh)		;6468   ; el bit 0 de sus banderas: mirando arriba o abajo
	rra			;646b
	ld de,00700h		;646c   ; el par de arriba
	ld bc,00f08h		;646f   ; y el de abajo
	jr nc,L_6485		;6472
	ld a,(0e13ch)		;6474   ; con bomba cargada, el dibujo cambia
	and a			;6477
	ld e,000h		;6478   ; con otro patron
	ld c,004h		;647a
	jr z,L_6485		;647c
	rla			;647e   ; el bit 7 dice cual
	ld c,044h		;647f
	jr nc,L_6485		;6481
	ld c,048h		;6483
L_6485:
	ld hl,0ef82h		;6485   ; el bloque de sprites de la nave 1
	call escribe_dos_sprites		;6488
	call es_el_segundo_jugador		;648b   ; y con dos jugadores
	ret nz			;648e
	ld de,00118h		;648f   ; la nave 1 lleva el color del uno
	ld c,e			;6492
	ld b,d			;6493
	jr L_64CC		;6494
dibuja_la_nave_dos:
	ld a,(0e084h)		;6496   ; el estado de la nave 2
	bit 2,a		;6499   ; el bit 2: en llamas
	jr z,L_64AF		;649b
	ld a,(0e003h)		;649d   ; y el dibujo alterna cada dos cuadros
	and 002h		;64a0   ; el bit 1 del contador
	ld de,00f5ch		;64a2
	ld bc,00f60h		;64a5
	jr nz,L_64CC		;64a8
	ld d,006h		;64aa
	ld b,d			;64ac
	jr L_64CC		;64ad
L_64AF:
	ld a,(0e08eh)		;64af   ; el bit 0 de sus banderas
	rra			;64b2
	ld de,0060ch		;64b3   ; el par de arriba
	ld bc,00f14h		;64b6   ; y el de abajo
	jr nc,L_64CC		;64b9
	ld a,(0e146h)		;64bb   ; con bomba cargada, el dibujo cambia
	and a			;64be
	ld e,00ch		;64bf
	ld c,010h		;64c1
	jr z,L_64CC		;64c3
	rla			;64c5   ; el bit 7 dice cual
	ld c,054h		;64c6
	jr nc,L_64CC		;64c8
	ld c,058h		;64ca
L_64CC:
	ld hl,0ef8ah		;64cc   ; el bloque de sprites de la nave 2
escribe_dos_sprites:
	ld (hl),e			;64cf   ; el patron y el color de los dos sprites
	inc l			;64d0
	ld (hl),d			;64d1   ; y su color
	inc l			;64d2
	inc l			;64d3
	inc l			;64d4
	ld (hl),c			;64d5   ; el patron del segundo
	inc l			;64d6
	ld (hl),b			;64d7   ; y su color
	ret			;64d8

; ----------------------------------------------------------------------
; CUANDO SE ESTRELLA UNA NAVE. Se pierde todo: la potencia, las campanas y las armas. Si quedan vidas, la nave vuelve entrando por abajo; y si no, se apaga su bit en (0xE077), y cuando los dos estan apagados se acaba la partida.
; ----------------------------------------------------------------------
se_estrella_la_uno:
	xor a			;64d9
	ld (0e081h),a		;64da   ; la potencia, a cero
	ld (0e083h),a		;64dd   ; y el estado
	ld (0e093h),a		;64e0   ; las banderas
	ld (0e08fh),a		;64e3   ; y las dos marcas de rastro
	ld (0e091h),a		;64e6
	ld (0e362h),a		;64e9   ; y el nivel de oleada
	ld de,0ef82h		;64ec   ; su bloque de sprites
	ld hl,0e085h		;64ef   ; y su cuenta
	dec (hl)			;64f2   ; la cuenta de la explosion
	jr nz,L_650B		;64f3
	ld hl,0e078h		;64f5
	res 0,(hl)		;64f8   ; fuera la marca de "muriendose"
	ld hl,0e070h		;64fa   ; las vidas
	ld a,(hl)			;64fd
	and a			;64fe
	jr z,L_651E		;64ff   ; sin vidas, se acabo
	sub 001h		;6501   ; una menos, en BCD
	daa			;6503
	ld (hl),a			;6504
	ld a,001h		;6505
	ld (0e087h),a		;6507   ; y a esperar a que vuelva
	ret			;650a
L_650B:
	call es_el_segundo_jugador		;650b   ; con dos jugadores
	ld a,(hl)			;650e
	jp nz,dibuja_la_explosion		;650f
	ld a,0e0h		;6512   ; los sprites de en medio se apartan
	ld (0e0a5h),a		;6514
	ld (0e0a9h),a		;6517
	ld a,(hl)			;651a
	jp dibuja_la_explosion		;651b
L_651E:
	ld hl,01800h		;651e   ; la nave nueva entra por abajo
	ld (0ef90h),hl		;6521
	ld (0e104h),hl		;6524
	ld hl,00fa0h		;6527
	ld (0ef92h),hl		;652a
	ld (0e106h),hl		;652d
	ld de,0e07ah		;6530
	ld hl,0ef80h		;6533
	ld a,018h		;6536
	ld c,001h		;6538   ; y se apaga el bit 0 de (0xE077)
	jr pon_la_nave_nueva		;653a
se_estrella_la_dos:
	xor a			;653c   ; lo mismo para la nave 2
	ld (0e082h),a		;653d   ; la potencia del segundo, a cero
	ld (0e084h),a		;6540
	ld (0e093h),a		;6543
	ld (0e090h),a		;6546
	ld (0e092h),a		;6549
	ld (0e363h),a		;654c
	ld de,0ef8ah		;654f
	ld hl,0e086h		;6552
	dec (hl)			;6555   ; con su propia cuenta
	ld a,(hl)			;6556
	jr nz,dibuja_la_explosion		;6557
	ld hl,0e078h		;6559   ; fuera la marca de "muriendose"
	res 1,(hl)		;655c
	ld hl,0e073h		;655e   ; sus vidas
	ld a,(hl)			;6561
	and a			;6562
	jr z,L_656F		;6563   ; sin vidas, se acabo
	sub 001h		;6565   ; una menos, en BCD
	daa			;6567
	ld (hl),a			;6568
	ld a,001h		;6569
	ld (0e088h),a		;656b   ; y a esperar
	ret			;656e
L_656F:
	ld hl,0c800h		;656f   ; la nave nueva entra por la derecha
	ld (0ef98h),hl		;6572
	ld (0e114h),hl		;6575
	ld hl,00fa4h		;6578
	ld (0ef9ah),hl		;657b
	ld (0e116h),hl		;657e
	ld de,0e07bh		;6581
	ld hl,0ef88h		;6584
	ld a,0c8h		;6587
	ld c,002h		;6589
pon_la_nave_nueva:
	ld (hl),010h		;658b   ; los cuatro bytes de cada sprite de la nave
	inc l			;658d   ; el dibujo
	ld (hl),a			;658e
	inc l			;658f   ; la horizontal
	ld (hl),0a8h		;6590
	inc l			;6592
	ld (hl),00fh		;6593   ; en blanco
	inc l			;6595
	ld (hl),010h		;6596   ; el segundo sprite, misma fila
	inc l			;6598
	add a,010h		;6599   ; dieciseis dibujos mas alla
	ld (hl),a			;659b
	inc l			;659c
	ld (hl),0ach		;659d   ; ocho pixeles a la derecha
	inc l			;659f
	ld (hl),00fh		;65a0
	ld a,0c0h		;65a2   ; y el sprite siguiente, fuera
	ld (de),a			;65a4
	ld hl,0e077h		;65a5   ; los jugadores que quedan
	ld a,(hl)			;65a8
	xor c			;65a9   ; se apaga el bit del jugador
	ld (hl),a			;65aa
	ret nz			;65ab   ; y solo cuando se apagan los dos
	ld (0e05eh),a		;65ac
	ld (0e05dh),a		;65af
	ld a,0f4h		;65b2
	jp pide_un_sonido_si_se_juega		;65b4   ; suena el final
dibuja_la_explosion:
	ld hl,065e5h		;65b7   ; el fotograma de la explosion
	rra			;65ba   ; los bits 2 a 5 del contador
	rra			;65bb
	and 00fh		;65bc
	ld bc,065d6h		;65be
	add a,c			;65c1
	ld c,a			;65c2
	jr nc,L_65C6		;65c3
	inc b			;65c5
L_65C6:
	ld a,(bc)			;65c6
	add a,a			;65c7   ; la pareja de patrones
	call indexa_palabras		;65c8
	ldi		;65cb   ; el primer sprite
	ldi		;65cd
	inc e			;65cf
	inc e			;65d0
	ldi		;65d1   ; y el segundo
	ldi		;65d3
	ret			;65d5

; ----------------------------------------------------------------------
; DATOS fotogramas_de_la_explosion: Dieciseis valores que 0x65BE indexa con
;   los bits 2 a 5 del contador de la explosion: cual de las parejas de
;   dibujos toca en cada momento
;   0x65d6..0x65e6  (16 bytes)
DATA_fotogramas_de_la_explosion:
	defb 001h	; 65d6
	defb 000h	; 65d7
	defb 001h	; 65d8
	defb 000h	; 65d9
	defb 001h	; 65da
	defb 000h	; 65db
	defb 002h	; 65dc
	defb 002h	; 65dd
	defb 000h	; 65de
	defb 001h	; 65df
	defb 000h	; 65e0
	defb 001h	; 65e1
	defb 000h	; 65e2
	defb 001h	; 65e3
	defb 000h	; 65e4
	defb 000h	; 65e5

; ----------------------------------------------------------------------
; DATOS dibujos_de_la_explosion: Las parejas (patron, color) que 0x65C8
;   indexa: los dos sprites de la nave estrellandose
;   0x65e6..0x65f1  (11 bytes)
DATA_dibujos_de_la_explosion:
	defb 00fh	; 65e6
	defb 008h	; 65e7
	defb 00fh	; 65e8
	defb 01ch	; 65e9
	defb 008h	; 65ea
	defb 020h	; 65eb
	defb 00fh	; 65ec
	defb 024h	; 65ed
	defb 008h	; 65ee
	defb 028h	; 65ef
	defb 00fh	; 65f0

; ======================================================================
; CODIGO 0x65f1..0x6672  (129 bytes)
; ======================================================================


nace_el_disparo_uno:
	ld hl,0e087h		;65f1   ; las banderas del brazo del primero
	ld de,06672h		;65f4   ; y su tanda de dibujos
	ld ix,0e0a0h		;65f7
	ld iy,0ef80h		;65fb
	jr reparte_el_estado_del_brazo		;65ff
nace_el_disparo_dos:
	ld hl,0e088h		;6601
	ld de,06677h		;6604
	ld ix,0e0ach		;6607
	ld iy,0ef88h		;660b
reparte_el_estado_del_brazo:
	ld a,(hl)			;660f
	rra			;6610   ; el bit 0: sale el brazo
	jr c,saca_el_brazo		;6611
	inc l			;6613
	inc l			;6614
	rra			;6615   ; el bit 1: se recoge
	jr c,recoge_el_brazo		;6616
	rra			;6618   ; y el bit 2: sube
	jr c,sube_el_brazo		;6619
	ret			;661b
saca_el_brazo:
	xor a			;661c   ; el brazo arranca arriba del todo
	ld (ix+000h),a		;661d   ; la vertical a cero
	ld (ix+001h),0c0h		;6620   ; y la horizontal fuera de pantalla
	ld (ix+002h),a		;6624   ; sin dibujo todavia
	ld a,(de)			;6627   ; con el dibujo de su tanda
	ld (ix+003h),a		;6628
	inc de			;662b   ; los cuatro sprites que lo forman
	ld a,(de)			;662c
	ld (iy+002h),a		;662d   ; el primero
	inc de			;6630
	ld a,(de)			;6631
	ld (iy+003h),a		;6632   ; el segundo
	inc de			;6635
	ld a,(de)			;6636
	ld (iy+006h),a		;6637   ; el tercero
	inc de			;663a
	ld a,(de)			;663b
	ld (iy+007h),a		;663c   ; y el cuarto
	ld (hl),002h		;663f   ; y a esperar 2 cuadros
	inc l			;6641   ; dos bytes adelante
	inc l			;6642
	ld (hl),010h		;6643   ; luego 0x10
	inc l			;6645   ; dos mas: el paso
	inc l			;6646
	ld (hl),000h		;6647
	inc l			;6649
	inc l			;664a
	ld (hl),001h		;664b   ; y en marcha
	ret			;664d
recoge_el_brazo:
	dec (hl)			;664e   ; la cuenta
	ret nz			;664f   ; hasta que se agote
	ld (hl),018h		;6650   ; y al llegar a cero se pasa a subir
	dec l			;6652   ; dos bytes atras
	dec l			;6653
	ld (hl),004h		;6654
	ld a,093h		;6656   ; con su ruido
	jp pide_un_sonido_si_se_juega		;6658
sube_el_brazo:
	ld a,(ix+001h)		;665b   ; tres pixeles por cuadro hacia arriba
	sub 003h		;665e
	ld (ix+001h),a		;6660   ; la nueva vertical
	dec (hl)			;6663   ; la cuenta de la subida
	ret nz			;6664
	ld (hl),018h		;6665   ; hasta que se acaba la cuenta
	dec l			;6667
	dec l			;6668
	ld (hl),000h		;6669
	ld a,010h		;666b
	add a,l			;666d
	ld l,a			;666e
	ld (hl),060h		;666f
	ret			;6671

; ----------------------------------------------------------------------
; DATOS dos_guiones_de_disparo: Dos tandas de cinco bytes, la del primer
;   jugador (0x65F4) y la del segundo (0x6604)
;   0x6672..0x667c  (10 bytes)
DATA_dos_guiones_de_disparo:
	defb 040h,000h,007h,004h,00fh	; 6672
	defb 0b0h,00ch,006h,010h,00fh	; 6677

; ======================================================================
; CODIGO 0x667c..0x6750  (212 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL ABRAZO. Twin Bee tiene un truco que casi ningun juego de dos jugadores de la epoca: las dos naves pueden darse la mano y volar juntas. Aqui se mide la distancia entre las dos en las dos coordenadas y, si las dos caben en 0x22 pixeles, se enciende el bit 4 de los dos estados y a partir de ahi las mueve 0x6326 como si fueran una sola.
; ----------------------------------------------------------------------
mira_si_se_dan_la_mano:
	ld a,(0e077h)		;667c   ; los jugadores vivos
	rra			;667f   ; los dos jugadores tienen que estar vivos
	ret nc			;6680
	rra			;6681
	ret nc			;6682
	xor a			;6683   ; sin abrazo
	ld (0e093h),a		;6684   ; la marca del abrazo, a cero
	ld a,(0e083h)		;6687   ; el estado de la nave 1
	bit 4,a		;668a   ; si ya estan agarradas, nada
	ret nz			;668c
	ld a,(0e0a1h)		;668d   ; la vertical de la 1
	ld c,a			;6690   ; a salvo en C
	ld hl,0e0adh		;6691   ; y la de la 2
	ld b,(hl)			;6694   ; la de la 2, en B
	add a,010h		;6695   ; dieciseis pixeles de margen
	sub (hl)			;6697
	cp 022h		;6698   ; tienen que caber en 0x22 pixeles
	ret nc			;669a
	inc l			;669b   ; dos bytes adelante
	inc l			;669c
	ld a,(0e0a3h)		;669d   ; lo mismo con la horizontal
	ld e,a			;66a0   ; a salvo en E
	ld d,(hl)			;66a1   ; y la de la 2 en D
	add a,010h		;66a2
	sub (hl)			;66a4
	cp 022h		;66a5
	ret nc			;66a7
	ld a,b			;66a8   ; y si ademas estan casi pegadas
	inc a			;66a9
	sub c			;66aa
	cp 004h		;66ab
	jr c,L_6714		;66ad   ; se agarran directamente

; ----------------------------------------------------------------------
; POR DONDE SE DAN LA MANO. La distancia entre las dos naves se parte en ocho pasos verticales y ocho horizontales, y con esos dos numeros se entra en la tabla de 0xEB00 -que es la de 0x6750, traida de la VRAM- para sacar el dibujo del brazo que corresponde. Los dos `rra` de 0x66C8 y 0x66D5 dividen entre dos, y el `add a,a` triple de 0x66DA es el por ocho de la fila.
; ----------------------------------------------------------------------
L_66AF:
	ld hl,00000h		;66af   ; por donde se estira el brazo
	ld (0ebc0h),hl		;66b2
	ld a,002h		;66b5   ; con el brazo en el paso 2
	ld (0e08fh),a		;66b7   ; y los dos brazos se ponen en marcha
	ld (0e090h),a		;66ba
	ld hl,0ebc0h		;66bd   ; los dos signos que se acaban de dejar
	ld a,c			;66c0   ; la distancia vertical
	sub b			;66c1
	jr nc,L_66C8		;66c2
	neg		;66c4   ; en valor absoluto
	ld (hl),001h		;66c6   ; y el signo, apuntado
L_66C8:
	rra			;66c8   ; entre dos, y ocho pasos
	and 00fh		;66c9
	ld c,a			;66cb   ; la fila, en C
	inc l			;66cc   ; el signo de la horizontal
	ld a,e			;66cd   ; ahora la horizontal
	sub d			;66ce
	jr nc,L_66D5		;66cf
	neg		;66d1
	ld (hl),001h		;66d3   ; apuntado
L_66D5:
	rra			;66d5
	and 00fh		;66d6
	ld b,a			;66d8   ; la columna, en B
	ld a,c			;66d9
	add a,a			;66da   ; fila por ocho
	add a,a			;66db
	add a,a			;66dc
	add a,b			;66dd   ; mas la columna
	ld de,0eb00h		;66de   ; la tabla, que vino de la VRAM
	call suma_a_a_de		;66e1
	ld a,(de)			;66e4   ; el codigo que sale de la tabla
	ld c,a			;66e5
	ld b,002h		;66e6   ; los dos signos
	ld d,00ch		;66e8   ; la mascara del primero
L_66EA:
	ld a,(hl)			;66ea   ; el signo
	rra			;66eb
	jr nc,L_66F5		;66ec
	ld a,c			;66ee
	and d			;66ef   ; y cada uno da la vuelta a su eje
	jr z,L_66F5		;66f0
	ld a,c			;66f2
	xor d			;66f3   ; se le da la vuelta
	ld c,a			;66f4
L_66F5:
	dec l			;66f5   ; el otro signo
	ld d,003h		;66f6   ; con su mascara
	djnz L_66EA		;66f8
	ld hl,0e091h		;66fa   ; por donde se estira
	ld (hl),c			;66fd   ; el codigo, guardado
	ld a,c			;66fe
	ld de,0677dh		;66ff   ; y el dibujo que le toca
	call suma_a_a_de		;6702
	ld a,(de)			;6705   ; el dibujo
	inc l			;6706
	ld (hl),a			;6707   ; al byte de al lado
	dec a			;6708   ; con el brazo recto
	ld c,009h		;6709   ; con color 9
	jr z,L_6711		;670b
	dec a			;670d
	ld c,001h		;670e   ; o color 1
	ret nz			;6710
L_6711:
	inc l			;6711
	ld (hl),c			;6712
	ret			;6713
L_6714:
	ld hl,0e081h		;6714   ; los dos tienen que llevar la misma potencia
	ld a,(hl)			;6717   ; la potencia del uno
	inc l			;6718
	sub (hl)			;6719   ; menos la del dos
	jr nz,L_66AF		;671a
	ld hl,0e08dh		;671c   ; y las mismas armas
	ld a,(hl)			;671f   ; las armas del uno
	inc l			;6720
	and (hl)			;6721   ; contra las del dos
	jp z,L_66AF		;6722
	ld hl,0e083h		;6725
	set 4,(hl)		;6728   ; y entonces si: agarradas
	inc l			;672a   ; y la segunda nave igual
	set 4,(hl)		;672b
	ld hl,(0e0a2h)		;672d   ; la que este a la izquierda manda
	ld a,e			;6730   ; la horizontal de una
	sub d			;6731   ; menos la de la otra
	ld de,01000h		;6732   ; el hueco entre las dos, 0x10 pixeles
	ld bc,0e083h		;6735
	jr c,L_673D		;6738
	inc c			;673a   ; la otra nave manda
	ld d,0f0h		;673b   ; y el hueco, al otro lado
L_673D:
	add hl,de			;673d   ; la posicion de la pareja
	ld (0e0aeh),hl		;673e
	ld hl,(0e0a0h)		;6741   ; y las dos comparten posicion
	ld (0e0ach),hl		;6744
	ld a,(bc)			;6747   ; el estado de la que manda
	or 080h		;6748   ; con el bit 7 del estado
	ld (bc),a			;674a
	ld a,08ch		;674b   ; y suena el enganche
	jp pide_un_sonido_si_se_juega		;674d

; ----------------------------------------------------------------------
; DATOS tabla_de_acercamiento: Los 0x51 valores que 0x66E1 indexa para decidir
;   COMO se acercan las dos naves cuando van a darse la mano: nueve pasos de
;   distancia vertical por nueve de horizontal. Y como estan comprimidos, hay
;   que ver por donde llegan a la RAM: el descompresor de este cartucho solo
;   sabe escribir en la VRAM, asi que 0x5E03 los suelta en 0x3B80 -un hueco de
;   la tabla de atributos de sprites que nadie usa- y 0x5E0F los trae de
;   vuelta a 0xEB00 con LDIRMV. La VRAM hace de mesa de trabajo
;   0x6750..0x677d  (45 bytes)
DATA_tabla_de_acercamiento:
	defb 080h,03bh,081h,00ah,008h,008h,083h,002h,00ah,00ah,006h,008h,081h,002h,004h,00ah	; 6750  .;..............
	defb 004h,008h,002h,002h,005h,00ah,002h,008h,002h,002h,007h,00ah,003h,002h,006h,00ah	; 6760  ................
	defb 003h,002h,006h,00ah,004h,002h,005h,00ah,004h,002h,005h,00ah,000h	; 6770  .............

; ----------------------------------------------------------------------
; DATOS dibujos_del_brazo: Los once codigos que 0x66FF indexa con lo que salio
;   de la tabla de arriba: el dibujo del brazo estirado en cada direccion
;   0x677d..0x6788  (11 bytes)
DATA_dibujos_del_brazo:
	defb 000h	; 677d
	defb 002h	; 677e
	defb 001h	; 677f
	defb 000h	; 6780
	defb 008h	; 6781
	defb 00ah	; 6782
	defb 009h	; 6783
	defb 000h	; 6784
	defb 004h	; 6785
	defb 006h	; 6786
	defb 005h	; 6787

; ======================================================================
; CODIGO 0x6788..0x699b  (531 bytes)
; ======================================================================


saca_la_bomba_del_uno:
	ld a,(0e08bh)		;6788   ; la bomba del primero
	dec a			;678b
	jr nz,saca_la_bomba_del_dos		;678c
	ld a,(0e13ch)		;678e   ; si ya hay una en el aire, no
	and a			;6791
	jr nz,saca_la_bomba_del_dos		;6792
	ld a,(0f0ffh)		;6794   ; el truco de bombas
	and 002h		;6797
	ld a,002h		;6799
	jr z,L_679E		;679b
	xor a			;679d
L_679E:
	ld (0e08bh),a		;679e
	ld a,(0e0a3h)		;67a1   ; la bomba sale de donde este la nave
	ld hl,0e348h		;67a4
	call pon_la_bomba		;67a7
saca_la_bomba_del_dos:
	call es_el_segundo_jugador		;67aa   ; con dos jugadores
	ret z			;67ad
	ld a,(0e08ch)		;67ae   ; la bomba del segundo
	dec a			;67b1
	ret nz			;67b2
	ld a,(0e146h)		;67b3   ; si ya hay una en el aire, no
	and a			;67b6
	ret nz			;67b7
	ld a,002h		;67b8
	ld (0e08ch),a		;67ba
	ld a,(0e0afh)		;67bd   ; sale de donde este la nave
	ld hl,0e340h		;67c0
pon_la_bomba:
	ld (hl),001h		;67c3   ; viva, cayendo, con su dibujo
	inc l			;67c5
	ld (hl),0f0h		;67c6
	inc l			;67c8
	ld (hl),a			;67c9
	inc l			;67ca
	ld (hl),030h		;67cb
	ret			;67cd
apaga_la_bomba:
	xor a			;67ce   ; los ocho bytes de la bomba, a cero
	ld (hl),a			;67cf
	inc l			;67d0
	ld (hl),0e0h		;67d1   ; con el sprite fuera
	inc l			;67d3
	ld (hl),a			;67d4
	inc l			;67d5
	ld (hl),030h		;67d6   ; y su dibujo de reposo
	inc l			;67d8
	ld (hl),a			;67d9
	inc l			;67da
	ld (hl),a			;67db
	inc l			;67dc
	ld (hl),a			;67dd
	inc l			;67de
	ld (hl),a			;67df
	ret			;67e0
mueve_las_bombas:
	call cuantas_bombas		;67e1   ; una bomba por jugador
	ld hl,0e348h		;67e4   ; la bomba del primer jugador
L_67E7:
	push hl			;67e7   ; el hueco, a la pila
	ld a,(hl)			;67e8   ; si esa bomba no esta viva, nada
	and a			;67e9
	jr z,L_6811		;67ea
	inc l			;67ec
	inc (hl)			;67ed   ; una fila mas abajo
	ld a,(hl)			;67ee
	dec l			;67ef
	cp 0f0h		;67f0   ; pasado el suelo
	jr nc,L_67FD		;67f2
	cp 0c0h		;67f4   ; o antes de llegar
	jr c,L_67FD		;67f6
	call apaga_la_bomba		;67f8   ; se apaga
	jr L_6811		;67fb
L_67FD:
	ld a,004h		;67fd   ; y en la banda del suelo, parpadea
	add a,l			;67ff
	ld l,a			;6800
	ld a,(0e003h)		;6801
	and 004h		;6804
	ld (hl),009h		;6806
	jr nz,L_680C		;6808
	ld (hl),00fh		;680a
L_680C:
	ld a,08fh		;680c   ; con su ruido
	call pide_un_sonido_si_se_juega		;680e
L_6811:
	pop hl			;6811
	ld a,l			;6812
	sub 008h		;6813   ; la bomba del otro jugador, ocho bytes mas atras
	ld l,a			;6815
	djnz L_67E7		;6816
	call cuantas_bombas		;6818
	ld de,0efa8h		;681b
	ld hl,0e348h		;681e
coloca_las_bombas:
	push hl			;6821   ; y las bombas vivas, a sus sprites
	push de			;6822
	ld a,(hl)			;6823
	and a			;6824
	jr z,L_6830		;6825
	inc l			;6827
	ldi		;6828
	ldi		;682a
	ldi		;682c
	ldi		;682e
L_6830:
	pop de			;6830   ; el sprite anterior
	pop hl			;6831
	ld a,e			;6832
	sub 004h		;6833
	ld e,a			;6835
	ld a,l			;6836   ; y la bomba anterior
	sub 008h		;6837
	ld l,a			;6839
	djnz coloca_las_bombas		;683a
	ret			;683c
dispara_el_uno:
	ld a,(0e006h)		;683d   ; el gatillo
	and 010h		;6840   ; el bit 4 del mando
	ret z			;6842   ; sin gatillo, nada
	ld a,(0e083h)		;6843   ; el estado de la nave
	rra			;6846   ; el bit 0: mira hacia arriba
	jp c,L_6870		;6847
	bit 2,a		;684a   ; el bit 2: en llamas
	jp nz,L_6891		;684c
	rra			;684f   ; el bit 1: doble disparo
	jr c,L_685A		;6850   ; el bit 1 de sus banderas
L_6852:
	call hay_dos_huecos_del_uno		;6852   ; y si no hay hueco de disparo, nada
	ret nz			;6855
	ld b,001h		;6856   ; uno solo
	jr L_6865		;6858   ; y a soltarlo
L_685A:
	call hay_hueco_arriba		;685a
	jr z,L_6863		;685d   ; con hueco arriba
	call hay_hueco_abajo		;685f   ; o abajo
	ret nz			;6862
L_6863:
	ld b,003h		;6863   ; o tres a la vez
L_6865:
	ld ix,0e0a0h		;6865   ; el bloque de la nave 1
L_6869:
	ld hl,0699bh		;6869   ; con el guion normal
	xor a			;686c   ; sin sonido extra
	jp saca_los_disparos		;686d
L_6870:
	rra			;6870   ; mirando arriba, el otro guion
	jr c,L_687B		;6871   ; con doble disparo, tres
L_6873:
	call hay_dos_huecos_del_uno		;6873
	ret nz			;6876
	ld b,001h		;6877
	jr L_6886		;6879   ; y a soltarlo
L_687B:
	call hay_hueco_arriba		;687b
	jr z,L_6884		;687e   ; hueco arriba
	call hay_hueco_abajo		;6880   ; o abajo
	ret nz			;6883
L_6884:
	ld b,003h		;6884
L_6886:
	ld ix,0e0a0h		;6886   ; el bloque de la nave 1
L_688A:
	ld hl,069a2h		;688a   ; con el guion de mirar arriba
	xor a			;688d   ; sin sonido extra
	jp saca_los_disparos		;688e
L_6891:
	call hay_hueco_arriba		;6891   ; y en llamas, el disparo grande
	jr z,L_689A		;6894
	call hay_hueco_abajo		;6896
	ret nz			;6899
L_689A:
	ld hl,069a9h		;689a   ; el disparo grande
	ld ix,0e0a0h		;689d   ; el bloque de la nave 1
	ld a,0fah		;68a1   ; con su ruido
	ld b,001h		;68a3   ; una tanda
	call saca_los_disparos		;68a5   ; tres tandas seguidas
	ld ix,0e0a0h		;68a8   ; y otras dos detras, sin ruido
	ld b,001h		;68ac   ; una cada una
	call saca_una_tanda		;68ae
	ld ix,0e0a0h		;68b1
	ld b,001h		;68b5
	jp saca_una_tanda		;68b7
dispara_el_dos:
	ld a,(0e093h)		;68ba   ; la nave 2
	and a			;68bd   ; si hay arma grande en marcha, esa manda
	jp nz,dispara_el_arma_grande		;68be
	ld a,(0e006h)		;68c1   ; el gatillo del primero
	and 010h		;68c4
	ret z			;68c6
	ld a,(0e083h)		;68c7   ; el estado de la nave 1
	bit 4,a		;68ca   ; agarradas, disparan las dos a la vez
	jr nz,dispara_la_pareja		;68cc
	rra			;68ce   ; el bit 0: mira arriba
	jp c,L_6873		;68cf
	jp L_6852		;68d2
dispara_el_dos_de_verdad:
	ld a,(0e008h)		;68d5
	and 010h		;68d8   ; el gatillo del segundo
	ret z			;68da
	ld a,(0e084h)		;68db   ; el estado de la nave 2
	bit 4,a		;68de   ; agarradas: disparan juntas
	jr nz,dispara_la_pareja		;68e0
	rra			;68e2   ; el bit 0: mira arriba
	jp c,L_68F3		;68e3
	call hay_dos_huecos_del_dos		;68e6   ; sin dos huecos, nada
	ret nz			;68e9
	ld ix,0e0ach		;68ea   ; el bloque de la nave 2
	ld b,001h		;68ee   ; uno solo
	jp L_6869		;68f0
L_68F3:
	call hay_dos_huecos_del_dos		;68f3
	ret nz			;68f6
	ld ix,0e0ach		;68f7   ; el bloque de la nave 2
	ld b,001h		;68fb
	jp L_688A		;68fd
dispara_la_pareja:
	ld de,0e100h		;6900   ; los cuatro huecos de disparo
	ld b,004h		;6903
L_6905:
	ld a,(de)			;6905   ; se busca uno libre
	and a			;6906
	jr z,L_6910		;6907
	ld a,008h		;6909   ; ocho bytes hasta el siguiente
	add a,e			;690b
	ld e,a			;690c
	djnz L_6905		;690d
	ret			;690f   ; y sin hueco, no se dispara
L_6910:
	ld a,(0e083h)		;6910   ; el bit 7 dice cual de las dos manda
	rla			;6913   ; el bit 7, al acarreo
	ld ix,0e0a0h		;6914   ; la nave 1
	jr c,L_691E		;6918
	ld ix,0e0ach		;691a   ; o la nave 2
L_691E:
	xor a			;691e
	ld b,001h		;691f   ; una tanda
	ld hl,069b0h		;6921   ; con el guion de la pareja
	jr saca_los_disparos		;6924
dispara_el_arma_grande:
	rla			;6926   ; el arma grande sale de la que mande
	ld ix,0e0a0h		;6927   ; la nave 1
	jr nc,L_6931		;692b
	ld ix,0e0ach		;692d   ; o la nave 2
L_6931:
	ld (0ebc1h),ix		;6931   ; y se guarda cual es
	ld de,0e118h		;6935   ; los cuatro huecos tienen que estar libres
	ld b,004h		;6938   ; cuatro
L_693A:
	ld a,(de)			;693a   ; los cuatro huecos
	and a			;693b
	ret nz			;693c
	ld a,e			;693d   ; y hacen falta los cuatro libres
	sub 008h		;693e   ; ocho bytes atras
	ld e,a			;6940
	djnz L_693A		;6941
	ld de,0e100h		;6943   ; y ocupa los cuatro de golpe
	ld a,0fbh		;6946   ; con la marca del arma
	ld (0ebc0h),a		;6948
	ld hl,069b7h		;694b   ; y el guion del arma
	ld b,004h		;694e   ; cuatro
L_6950:
	push bc			;6950   ; cuatro tandas, una por hueco
	ld ix,(0ebc1h)		;6951   ; la nave que manda
	ld b,001h		;6955   ; uno por vuelta
	call saca_una_tanda		;6957
	pop bc			;695a
	djnz L_6950		;695b
	ret			;695d
saca_los_disparos:
	ld (0ebc0h),a		;695e   ; el sonido que hay que pedir
saca_una_tanda:
	ld c,0ffh		;6961   ; sin sonido
L_6963:
	push hl			;6963
	ld a,001h		;6964   ; el disparo, vivo
	ld (de),a			;6966
	inc e			;6967   ; su clase
	ldi		;6968   ; su clase
	ld a,0f4h		;696a   ; y su cuenta de vida
	ld (de),a			;696c
	inc e			;696d   ; y la posicion dentro de la tanda
	ld a,(0ebc0h)		;696e   ; la posicion se corrige con lo que diga el guion
	add a,(hl)			;6971
	ld (0ebc0h),a		;6972
	ld (de),a			;6975
	inc e			;6976   ; al hueco
	inc hl			;6977   ; el byte siguiente del guion
	ld a,(ix+001h)		;6978   ; la vertical, la de la nave
	ld (de),a			;697b
	inc e			;697c   ; la vertical
	ld a,(ix+003h)		;697d   ; y la horizontal, con su desvio
	add a,(hl)			;6980
	ld (de),a			;6981
	inc e			;6982   ; y la horizontal
	inc hl			;6983
	ldi		;6984   ; el patron
	ldi		;6986   ; y el color
	ld a,(hl)			;6988
	add a,e			;6989   ; el hueco siguiente
	ld e,a			;698a
	inc hl			;698b   ; y el ultimo byte es el ruido
	ld a,(hl)			;698c
	call pide_un_sonido_si_se_juega		;698d   ; y el ruido que le toca
	push de			;6990   ; el hueco, a salvo
	ld de,00004h		;6991   ; cuatro bytes mas de la nave: el otro punto de salida
	add ix,de		;6994
	pop de			;6996
	pop hl			;6997
	djnz L_6963		;6998
	ret			;699a

; ----------------------------------------------------------------------
; DATOS guion_de_los_disparos: Siete bytes por tanda: el desvio, el patron, el
;   color, el hueco siguiente y el ruido. 0x6869, 0x688A, 0x689A, 0x6921 y
;   0x694B eligen por donde entrar segun el arma que lleve la nave
;   0x699b..0x69be  (35 bytes)
DATA_guion_de_los_disparos:
	defb 001h,000h,006h,06ch,00fh,008h,081h	; 699b
	defb 002h,000h,003h,070h,00fh,008h,082h	; 69a2
	defb 001h,003h,006h,06ch,00fh,008h,084h	; 69a9
	defb 003h,000h,00ch,074h,008h,000h,086h	; 69b0
	defb 001h,002h,006h,06ch,00fh,000h,0c5h	; 69b7

; ======================================================================
; CODIGO 0x69be..0x6b5c  (414 bytes)
; ======================================================================


mueve_los_disparos:
	call es_el_segundo_jugador		;69be   ; con dos jugadores hay seis disparos, y con uno solo, cuatro
	ld b,006h		;69c1   ; seis huecos
	jr z,L_69C7		;69c3
	ld b,004h		;69c5   ; o cuatro
L_69C7:
	ld hl,0e100h		;69c7   ; el primero
L_69CA:
	ld a,(hl)			;69ca   ; si el hueco esta libre, se salta
	and a			;69cb
	ld a,008h		;69cc   ; ocho bytes hasta el siguiente
	jr z,L_69EA		;69ce
	inc l			;69d0   ; dos bytes adelante
	inc l			;69d1
	ld a,(hl)			;69d2   ; la velocidad
	inc l			;69d3   ; y la horizontal
	ld e,(hl)			;69d4
	inc l			;69d5
	add a,(hl)			;69d6   ; y se le suma a la vertical
	ld (hl),a			;69d7
	inc l			;69d8   ; al byte de la horizontal
	cp 0f0h		;69d9   ; pasado el borde de abajo, fuera
	jr nc,L_69EF		;69db
	ld a,e			;69dd
	add a,(hl)			;69de   ; la horizontal
	ld (hl),a			;69df
	cp 004h		;69e0   ; con sus dos bordes
	jr c,L_69EF		;69e2
	cp 0fch		;69e4
	jr nc,L_69EF		;69e6
	ld a,003h		;69e8   ; tres bytes hasta el siguiente
L_69EA:
	add a,l			;69ea   ; se avanza al hueco que toque
	ld l,a			;69eb
L_69EC:
	djnz L_69CA		;69ec
	ret			;69ee
L_69EF:
	ld a,l			;69ef   ; el disparo se apaga
	sub 005h		;69f0
	ld l,a			;69f2
	call apaga_cuatro_sprites		;69f3
	inc l			;69f6
	jr L_69EC		;69f7
coloca_los_disparos:
	call es_el_segundo_jugador		;69f9   ; los disparos vivos, a sus sprites
	ld b,006h		;69fc
	jr z,L_6A02		;69fe
	ld b,004h		;6a00
L_6A02:
	ld hl,0e104h		;6a02
	ld de,0ef90h		;6a05
	ld c,0ffh		;6a08
L_6A0A:
	ldi		;6a0a   ; los cuatro bytes del sprite
	ldi		;6a0c
	ldi		;6a0e
	ldi		;6a10
	ld a,004h		;6a12   ; cuatro mas hasta el siguiente disparo
	add a,l			;6a14
	ld l,a			;6a15
	djnz L_6A0A		;6a16
	ret			;6a18
hay_hueco_arriba:
	ld de,0e100h		;6a19   ; los tres huecos de arriba
	ld a,(de)			;6a1c
	ld hl,0e110h		;6a1d
	or (hl)			;6a20
	ld hl,0e120h		;6a21
	or (hl)			;6a24
	ret			;6a25
hay_hueco_abajo:
	ld de,0e108h		;6a26   ; los tres huecos de abajo
	ld a,(de)			;6a29
	ld hl,0e118h		;6a2a
	or (hl)			;6a2d
	ld hl,0e128h		;6a2e
	or (hl)			;6a31
	ret			;6a32
hay_dos_huecos_del_uno:
	ld de,0e100h		;6a33   ; uno de cada
	ld a,(de)			;6a36
	and a			;6a37
	ret z			;6a38
	ld de,0e108h		;6a39
	ld a,(de)			;6a3c
	and a			;6a3d
	ret			;6a3e
hay_dos_huecos_del_dos:
	ld de,0e110h		;6a3f   ; los dos huecos del segundo
	ld a,(de)			;6a42
	and a			;6a43
	ret z			;6a44
	ld de,0e118h		;6a45
	ld a,(de)			;6a48
	and a			;6a49
	ret			;6a4a
saca_el_arma_del_uno:
	ld a,(0e006h)		;6a4b   ; el segundo gatillo
	and 020h		;6a4e
	ret z			;6a50
	ld a,(0e08dh)		;6a51   ; y hace falta llevar el arma
	and a			;6a54
	ret z			;6a55
	ld hl,0e130h		;6a56
	ld ix,0e13ch		;6a59
	ld iy,0e0a0h		;6a5d
	jr pon_el_arma		;6a61
saca_el_arma_del_dos:
	ld a,(0e008h)		;6a63   ; el segundo gatillo del segundo jugador
	and 020h		;6a66
	ret z			;6a68
	ld a,(0e08eh)		;6a69   ; y hace falta llevar el arma
	and a			;6a6c
	ret z			;6a6d
	ld hl,0e131h		;6a6e
	ld ix,0e146h		;6a71
	ld iy,0e0ach		;6a75
pon_el_arma:
	ld a,(ix+001h)		;6a79   ; si ya hay una en el aire, no
	and a			;6a7c
	ret nz			;6a7d
	ld (ix+001h),010h		;6a7e   ; dieciseis cuadros de vida
	inc (hl)			;6a82
	ld a,(hl)			;6a83
	rra			;6a84   ; y sale alternando a un lado y a otro
	ld bc,00100h		;6a85
	ld de,00060h		;6a88
	jr c,L_6A93		;6a8b
	ld de,0ffa0h		;6a8d
	ld bc,0810eh		;6a90
L_6A93:
	ld a,(iy+001h)		;6a93   ; desde donde este la nave
	add a,003h		;6a96   ; tres pixeles mas abajo
	ld (ix+007h),a		;6a98
	ld a,(iy+003h)		;6a9b   ; y la horizontal de la nave
	add a,c			;6a9e   ; con el desvio de C
	ld (ix+009h),a		;6a9f
	ld (ix+004h),e		;6aa2   ; la velocidad que traia
	ld (ix+005h),d		;6aa5
	ld hl,0fd00h		;6aa8   ; cayendo deprisa
	ld (ix+002h),l		;6aab   ; la fraccion
	ld (ix+003h),h		;6aae   ; y el byte entero
	ld (ix+000h),b		;6ab1   ; el hueco, ocupado
	ld a,083h		;6ab4   ; con su ruido
	jp pide_un_sonido_si_se_juega		;6ab6
mueve_las_armas:
	ld hl,0e13ch		;6ab9
	exx			;6abc   ; el juego de registros de repuesto lleva la cuenta
	call cuantas_bombas		;6abd
L_6AC0:
	exx			;6ac0   ; se vuelve al juego principal
	ld a,(hl)			;6ac1   ; el hueco tiene que estar ocupado
	and a			;6ac2
	ld a,00ah		;6ac3   ; diez bytes por bomba
	jr z,L_6AD5		;6ac5
	inc l			;6ac7
	dec (hl)			;6ac8   ; se le acaba la vida
	jr z,L_6ADC		;6ac9
	inc l			;6acb
	ld e,(hl)			;6acc   ; la velocidad horizontal
	inc l			;6acd
	ld d,(hl)			;6ace   ; y la vertical
	inc l			;6acf
	call suma_a_la_posicion		;6ad0   ; y si no, se mueve
L_6AD3:
	ld a,001h		;6ad3   ; un byte hasta la siguiente
L_6AD5:
	add a,l			;6ad5   ; el arma siguiente
	ld l,a			;6ad6
	exx			;6ad7   ; la cuenta vuelve a B
	djnz L_6AC0		;6ad8
	exx			;6ada
	ret			;6adb
L_6ADC:
	dec l			;6adc   ; un byte atras: la marca
	call apaga_siete_sprites		;6add   ; y se borra de la pantalla
	jr L_6AD3		;6ae0
coloca_las_armas:
	ld hl,0e143h		;6ae2   ; el arma del primer jugador
	ld de,0efa8h		;6ae5   ; a su sprite
	ldi		;6ae8   ; la vertical
	inc l			;6aea
	ldi		;6aeb   ; y la horizontal
	ld a,06ch		;6aed   ; con su dibujo
	ld (de),a			;6aef
	inc e			;6af0
	ld a,00fh		;6af1   ; en blanco
	ld (de),a			;6af3
	call es_el_segundo_jugador		;6af4   ; y si juegan dos
	ret z			;6af7
	ld hl,0e14dh		;6af8   ; tambien la del segundo
	ld de,0efa4h		;6afb
	ldi		;6afe
	inc l			;6b00
	ldi		;6b01
	ld a,06ch		;6b03
	ld (de),a			;6b05
	inc e			;6b06
	ld a,00fh		;6b07
	ld (de),a			;6b09
	ret			;6b0a

; ----------------------------------------------------------------------
; LAS NUBES, QUE SON LAS CAMPANAS. Twin Bee saca su premio de las nubes: al dispararles cae una campana que va cambiando de color y da potencia, velocidad o escudo segun de que color se coja. Aqui nacen: hasta dos a la vez, entrando por un lado o por el otro segun el bit 0 del byte que toque de 0x6B5C, y como mucho tres nubes por tramo, que es lo que cuenta (0xE360).
; ----------------------------------------------------------------------
saca_las_nubes:
	ld a,(0e365h)		;6b0b   ; la bandera de "toca nube", que puso 0x61BC
	and a			;6b0e
	ret z			;6b0f
	ld hl,0e350h		;6b10   ; los dos huecos de nube
	ld b,002h		;6b13
L_6B15:
	ld a,(hl)			;6b15   ; ocupado, se salta
	and a			;6b16
	ld a,008h		;6b17
	jr nz,L_6B57		;6b19
	ld (hl),001h		;6b1b   ; se marca ocupado
	inc l			;6b1d
	ld a,(0e360h)		;6b1e   ; cuantas nubes van en este tramo
	cp 003h		;6b21   ; con tres ya no cuentan
	jr z,L_6B2B		;6b23
	ld (hl),001h		;6b25   ; y esta nube si cuenta
	inc a			;6b27
	ld (0e360h),a		;6b28
L_6B2B:
	inc l			;6b2b   ; al tercer byte: la horizontal
	ld de,06b5ch		;6b2c   ; la ruleta de sentidos
	ld a,(0e361h)		;6b2f   ; la rueda de sentidos
	inc a			;6b32   ; una vuelta mas de la ruleta
	ld (0e361h),a		;6b33
	and 00fh		;6b36   ; dieciseis entradas
	call suma_a_a_de		;6b38
	ld a,(de)			;6b3b   ; el byte del sentido
	rra			;6b3c   ; el bit 0
	ld de,00140h		;6b3d   ; por la derecha
	jr c,L_6B45		;6b40
	ld de,000c0h		;6b42   ; o por la izquierda
L_6B45:
	ld (hl),e			;6b45   ; la horizontal, byte bajo
	inc l			;6b46
	ld (hl),d			;6b47   ; y el alto
	inc l			;6b48
	ld (hl),000h		;6b49   ; la vertical, byte bajo
	inc l			;6b4b
	ld (hl),0f0h		;6b4c   ; arriba del todo
	inc l			;6b4e
	sla a		;6b4f   ; el dibujo, doblado
	ld (hl),a			;6b51   ; el dibujo
	inc l			;6b52
	ld (hl),078h		;6b53   ; el color
	ld a,001h		;6b55   ; hasta el siguiente hueco
L_6B57:
	add a,l			;6b57   ; ocho bytes por nube
	ld l,a			;6b58
	djnz L_6B15		;6b59
	ret			;6b5b

; ----------------------------------------------------------------------
; DATOS sentidos_de_la_nube: Dieciseis bytes que 0x6B2C indexa con (0xE361):
;   el bit 0 elige entre 0x0140 y 0x00C0
;   0x6b5c..0x6b6c  (16 bytes)
DATA_sentidos_de_la_nube:
	defb 050h	; 6b5c
	defb 0a1h	; 6b5d
	defb 020h	; 6b5e
	defb 080h	; 6b5f
	defb 0c1h	; 6b60
	defb 0d0h	; 6b61
	defb 061h	; 6b62
	defb 0e0h	; 6b63
	defb 071h	; 6b64
	defb 090h	; 6b65
	defb 041h	; 6b66
	defb 0b1h	; 6b67
	defb 030h	; 6b68
	defb 011h	; 6b69
	defb 060h	; 6b6a
	defb 091h	; 6b6b

; ======================================================================
; CODIGO 0x6b6c..0x6d74  (520 bytes)
; ======================================================================


apaga_la_nube:
	ld a,l			;6b6c   ; si contaba, se descuenta
	sub 004h		;6b6d
	ld l,a			;6b6f
	ld a,(hl)			;6b70
	and a			;6b71
	jr z,L_6B7B		;6b72
	ld a,(0e360h)		;6b74
	dec a			;6b77
	ld (0e360h),a		;6b78
L_6B7B:
	dec l			;6b7b   ; y el hueco queda libre
	xor a			;6b7c   ; los ocho bytes de la nube
	ld (hl),a			;6b7d
	inc l			;6b7e
	ld (hl),a			;6b7f
	inc l			;6b80
	inc l			;6b81
	inc l			;6b82
	ld (hl),a			;6b83
	inc l			;6b84
	ld (hl),0e0h		;6b85   ; y su sprite, fuera
	inc l			;6b87
	ld (hl),a			;6b88
	inc l			;6b89
	ld (hl),a			;6b8a
	inc l			;6b8b
	jr L_6BBE		;6b8c
mueve_las_nubes:
	ld hl,0e350h		;6b8e
	ld b,002h		;6b91
L_6B93:
	ld a,(hl)			;6b93   ; hueco vacio, nada
	and a			;6b94
	ld a,008h		;6b95   ; ocho bytes por nube
	jr z,L_6BBC		;6b97
	inc l			;6b99   ; dos bytes adelante
	inc l			;6b9a
	ld a,(hl)			;6b9b   ; la velocidad horizontal
	inc l			;6b9c
	ld c,(hl)			;6b9d   ; y la vertical
	inc l			;6b9e
	add a,(hl)			;6b9f   ; la posicion mas la velocidad
	ld (hl),a			;6ba0
	inc hl			;6ba1   ; al byte alto
	ld a,c			;6ba2
	adc a,(hl)			;6ba3
	ld (hl),a			;6ba4
	cp 0d0h		;6ba5   ; pasada la banda de abajo
	jr nc,L_6BAD		;6ba7
	cp 0c0h		;6ba9
	jr nc,apaga_la_nube		;6bab
L_6BAD:
	inc l			;6bad
	inc l			;6bae
	ld a,(0e003h)		;6baf   ; y el dibujo alterna cada 16 cuadros
	and 010h		;6bb2
	ld (hl),078h		;6bb4
	jr z,L_6BBA		;6bb6
	ld (hl),080h		;6bb8
L_6BBA:
	ld a,001h		;6bba
L_6BBC:
	add a,l			;6bbc
	ld l,a			;6bbd
L_6BBE:
	djnz L_6B93		;6bbe
	ld bc,0efb8h		;6bc0   ; los dos sprites de la primera nube
	ld hl,0e355h		;6bc3
	call coloca_una_nube		;6bc6
	ld bc,0efc0h		;6bc9
	ld hl,0e35dh		;6bcc
coloca_una_nube:
	ld e,(hl)			;6bcf   ; la posicion
	inc l			;6bd0   ; al byte siguiente
	ld d,(hl)			;6bd1   ; y la horizontal
	inc l			;6bd2
	ld a,(hl)			;6bd3   ; con su dibujo
	ld l,c			;6bd4   ; el bloque de sprites, a HL
	ld h,b			;6bd5
	ld (hl),e			;6bd6   ; al primer sprite
	inc l			;6bd7
	ld (hl),d			;6bd8   ; la horizontal
	inc l			;6bd9
	ld (hl),a			;6bda   ; el dibujo
	inc l			;6bdb
	inc l			;6bdc   ; y el color, tal cual estaba
	ld (hl),e			;6bdd   ; y el segundo sprite, medio ancho a la derecha
	inc l			;6bde   ; al byte de la horizontal
	ld e,a			;6bdf   ; el dibujo, a salvo
	ld a,010h		;6be0   ; dieciseis pixeles
	add a,d			;6be2
	ld (hl),a			;6be3
	inc l			;6be4
	ld a,004h		;6be5   ; y con el dibujo de al lado
	add a,e			;6be7
	ld (hl),a			;6be8
	ret			;6be9
mira_si_le_dan_a_la_nube:
	ld hl,0e350h		;6bea   ; las dos nubes
	ld b,002h		;6bed
L_6BEF:
	ld a,(hl)			;6bef   ; el hueco tiene que estar ocupado
	and a			;6bf0
	ld a,008h		;6bf1   ; ocho bytes por nube
	jr z,L_6C19		;6bf3
	inc l			;6bf5
	ld a,(hl)			;6bf6   ; sin nube, nada
	and a			;6bf7
	jr z,L_6C17		;6bf8
	ld a,004h		;6bfa   ; cuatro bytes adelante: la posicion
	add a,l			;6bfc
	ld l,a			;6bfd
	ld a,(hl)			;6bfe   ; la horizontal
	exx			;6bff   ; a los registros de repuesto
	ld l,a			;6c00
	exx			;6c01
	inc l			;6c02
	ld a,(hl)			;6c03   ; y la vertical
	exx			;6c04
	add a,008h		;6c05   ; ocho pixeles mas abajo: el centro
	ld h,a			;6c07
	call mira_los_disparos_contra_la_nube		;6c08   ; se mira si algun disparo le da
	exx			;6c0b
	and a			;6c0c
	ld a,002h		;6c0d   ; dos bytes atras si no le dan
	jr z,L_6C19		;6c0f
	ld a,l			;6c11
	sub 005h		;6c12   ; cinco atras: la marca de entera
	ld l,a			;6c14
	ld (hl),000h		;6c15   ; y la nube se rompe: sale la campana
L_6C17:
	ld a,007h		;6c17   ; siete bytes hasta la siguiente
L_6C19:
	add a,l			;6c19   ; se avanza al hueco que toque
	ld l,a			;6c1a
	djnz L_6BEF		;6c1b
	ret			;6c1d
se_apaga_la_campana:
	ld a,00ah		;6c1e   ; la cuenta de la campana
	add a,l			;6c20
	ld l,a			;6c21
	dec (hl)			;6c22   ; mientras dure, nada
	ld a,006h		;6c23
	jr nz,L_6C95		;6c25
	dec l			;6c27
	jr L_6C34		;6c28
la_campana_recogida:
	xor a			;6c2a   ; el nivel de la oleada, a cero
	ld (0e362h),a		;6c2b
	ld (0e363h),a		;6c2e
	ld (0e364h),a		;6c31
L_6C34:
	ld a,l			;6c34
	sub 009h		;6c35
	ld l,a			;6c37
	ld a,(0e360h)		;6c38
	dec a			;6c3b
	ld (0e360h),a		;6c3c   ; una nube menos
	call apaga_y_borra		;6c3f
	jr L_6C97		;6c42

; ----------------------------------------------------------------------
; LA CAMPANA CAMBIA DE COLOR. Cada dieciseis cuadros, el color del sprite pasa al siguiente de una rueda de cuatro -0x2C, 0x64, 0x2C y 0x68-, y de que color este cuando se recoge sale el premio. Es la mecanica de la casa: la campana no se recoge, se PELOTEA a disparos hasta que se pone del color que interesa.
; ----------------------------------------------------------------------
mueve_las_campanas:
	ld hl,0e370h		;6c44   ; las tres campanas
	ld b,003h		;6c47
L_6C49:
	push bc			;6c49   ; la cuenta, a salvo
	ld a,(hl)			;6c4a   ; el estado de la campana
	and a			;6c4b   ; apagada, nada
	ld c,a			;6c4c   ; el estado, a C
	ld a,010h		;6c4d   ; dieciseis bytes por campana
	jr z,L_6C95		;6c4f
	ld a,c			;6c51
	sub 003h		;6c52   ; con 3 se esta apagando
	jp z,se_apaga_la_campana		;6c54
	inc l			;6c57   ; dos bytes adelante
	inc l			;6c58
	ld e,(hl)			;6c59   ; la velocidad
	inc l			;6c5a
	ld d,(hl)			;6c5b   ; y el alto
	push hl			;6c5c
	ld hl,00020h		;6c5d   ; mas 0x20: caen acelerando
	add hl,de			;6c60
	ex de,hl			;6c61
	pop hl			;6c62
	dec l			;6c63   ; un byte atras
	ld (hl),e			;6c64   ; la velocidad ya acelerada
	inc l			;6c65
	ld (hl),d			;6c66
	inc l			;6c67
	call suma_a_la_posicion		;6c68   ; y se mueve
	ld a,d			;6c6b
	cp 0d1h		;6c6c   ; pasado el borde de abajo
	jr nc,L_6C74		;6c6e
	cp 0c0h		;6c70   ; dentro de la banda de recogida
	jr nc,la_campana_recogida		;6c72
L_6C74:
	inc l			;6c74   ; al byte del color
	ld a,(0e003h)		;6c75   ; cada dieciseis cuadros
	and 00fh		;6c78
	ld a,006h		;6c7a   ; seis bytes hasta la siguiente
	jr nz,L_6C95		;6c7c
	inc (hl)			;6c7e   ; cambia de color
	ld a,(hl)			;6c7f   ; el color nuevo
	inc l			;6c80
	and 003h		;6c81   ; cuatro colores en rueda
	ld (hl),02ch		;6c83   ; el primero
	jr z,L_6C93		;6c85
	dec a			;6c87
	ld (hl),064h		;6c88   ; el segundo
	jr z,L_6C93		;6c8a
	dec a			;6c8c
	ld (hl),02ch		;6c8d   ; otra vez el primero
	jr z,L_6C93		;6c8f
	ld (hl),068h		;6c91   ; y el cuarto
L_6C93:
	ld a,005h		;6c93
L_6C95:
	add a,l			;6c95
	ld l,a			;6c96
L_6C97:
	pop bc			;6c97
	djnz L_6C49		;6c98
	ld hl,0e377h		;6c9a   ; y las tres, a sus sprites
	ld de,0efach		;6c9d
	ld b,003h		;6ca0
	ld c,0ffh		;6ca2
L_6CA4:
	ldi		;6ca4   ; la vertical
	inc l			;6ca6
	ldi		;6ca7   ; la horizontal
	inc l			;6ca9
	ldi		;6caa   ; el patron
	ldi		;6cac   ; y el color
	ld a,00ah		;6cae   ; 0x0A hasta la siguiente campana
	add a,l			;6cb0
	ld l,a			;6cb1
	djnz L_6CA4		;6cb2
	ret			;6cb4
reparte_el_premio:
	ld ix,0e370h		;6cb5
	ld b,003h		;6cb9
L_6CBB:
	ld a,(ix+000h)		;6cbb
	dec a			;6cbe
	jr z,L_6CC4		;6cbf
	dec a			;6cc1
	jr nz,L_6CC9		;6cc2
L_6CC4:
	exx			;6cc4   ; y con 1 o 2, se mira si alguien la recoge
	call mira_los_disparos_contra_la_campana		;6cc5
	exx			;6cc8
L_6CC9:
	ld de,00010h		;6cc9
	add ix,de		;6ccc
	djnz L_6CBB		;6cce
	ret			;6cd0

; ----------------------------------------------------------------------
; EL DECORADO, QUE ES UNA TIRA DE FILAS. Cada fila de la pantalla es un bloque de 32 casillas de 0x6F8F, y el mapa es la lista de esos bloques. 0x6D62 traduce el codigo a direccion con cinco `add hl,hl` -indice por 32- y 0x6D17 lo copia con treinta y dos `ldi` al buffer de nombres. La cuenta cierra sola: entre 0x6F8F y 0x8E8F hay 0x1F00 bytes, o sea 248 filas exactas, y el codigo mas alto que gastan los tramos es 0xF7 = 247.
; ----------------------------------------------------------------------
avanza_el_decorado:
	ld a,(0e003h)		;6cd1   ; el contador de cuadros
	and 00fh		;6cd4   ; una fila cada dieciseis: eso es el scroll
	jr nz,monta_las_veinticuatro_filas		;6cd6
	ld a,(0ebf2h)		;6cd8   ; con el jefe puesto, el decorado se para
	and a			;6cdb
	jr nz,monta_las_veinticuatro_filas		;6cdc
	ld hl,(0ebf0h)		;6cde   ; una fila mas
	inc hl			;6ce1   ; una fila mas de mapa
	ld (0ebf0h),hl		;6ce2
	ld hl,0e3a1h		;6ce5
	dec (hl)			;6ce8   ; y una menos para la siguiente oleada
	ld hl,0e3b0h		;6ce9   ; los cinco enemigos grandes
	ld c,005h		;6cec   ; los cinco
L_6CEE:
	ld a,(hl)			;6cee   ; su clase
	and a			;6cef
	ld a,010h		;6cf0   ; 0x10 bytes hasta el siguiente
	jr z,L_6D03		;6cf2
	inc l			;6cf4   ; dos adelante: el paso
	inc l			;6cf5
	inc (hl)			;6cf6   ; se les cuenta el paso
	ld a,(hl)			;6cf7
	cp 01ah		;6cf8   ; y al llegar a 0x1A se borran
	ld a,00eh		;6cfa   ; 0x0E hasta el siguiente
	jr nz,L_6D03		;6cfc
	dec l			;6cfe   ; dos atras: el bloque entero
	dec l			;6cff
	call borra_dieciseis		;6d00
L_6D03:
	add a,l			;6d03   ; y al siguiente
	ld l,a			;6d04
	dec c			;6d05
	jr nz,L_6CEE		;6d06
monta_las_veinticuatro_filas:
	ld hl,(0ebf0h)		;6d08   ; por donde va el decorado
	ld de,0e400h		;6d0b   ; el mapa, en la RAM
	add hl,de			;6d0e   ; la fila del mapa
	call la_fila_numero		;6d0f   ; y la fila que toca
	ld de,0ec40h		;6d12   ; al buffer de la pantalla
	ld a,018h		;6d15   ; veinticuatro filas
L_6D17:
	ldi		;6d17   ; 32 casillas, una por `ldi`: sale mas barato que un bucle
	ldi		;6d19   ; 32 `ldi` seguidos, uno por casilla
	ldi		;6d1b
	ldi		;6d1d
	ldi		;6d1f
	ldi		;6d21
	ldi		;6d23
	ldi		;6d25
	ldi		;6d27
	ldi		;6d29
	ldi		;6d2b
	ldi		;6d2d
	ldi		;6d2f
	ldi		;6d31
	ldi		;6d33
	ldi		;6d35
	ldi		;6d37
	ldi		;6d39
	ldi		;6d3b
	ldi		;6d3d
	ldi		;6d3f
	ldi		;6d41
	ldi		;6d43
	ldi		;6d45
	ldi		;6d47
	ldi		;6d49
	ldi		;6d4b
	ldi		;6d4d
	ldi		;6d4f
	ldi		;6d51
	ldi		;6d53
	ldi		;6d55
	ld hl,(0ebc0h)		;6d57   ; y la fila de ABAJO en pantalla es la ANTERIOR del mapa
	dec hl			;6d5a   ; una fila mas atras
	call la_fila_numero		;6d5b   ; por eso el mapa esta guardado del reves
	dec a			;6d5e   ; una fila menos
	jr nz,L_6D17		;6d5f   ; hasta las veinticuatro
	ret			;6d61
la_fila_numero:		; Guarda el puntero del mapa en (0xEBC0) y devuelve en HL el bloque de 32 casillas
	ld (0ebc0h),hl		;6d62   ; el puntero, a salvo
	ld l,(hl)			;6d65   ; el codigo de fila
	ld h,000h		;6d66
	add hl,hl			;6d68   ; por 32
	add hl,hl			;6d69
	add hl,hl			;6d6a
	add hl,hl			;6d6b
	add hl,hl			;6d6c
	push de			;6d6d
	ld de,06f8fh		;6d6e   ; y la tabla de bloques
	add hl,de			;6d71
	pop de			;6d72
	ret			;6d73

; ----------------------------------------------------------------------
; DATOS guion_del_mapa: La lista de tramos del escenario, cerrada con 0xFF.
;   0x4613 la recorre: cada byte indexa la tabla de 0x6E01 y el tramo que
;   saque se copia entero a 0xE400
;   0x6d74..0x6e01  (141 bytes)
DATA_guion_del_mapa:
	defb 000h	; 6d74
	defb 002h	; 6d75
	defb 004h	; 6d76
	defb 006h	; 6d77
	defb 004h	; 6d78
	defb 006h	; 6d79
	defb 004h	; 6d7a
	defb 006h	; 6d7b
	defb 004h	; 6d7c
	defb 006h	; 6d7d
	defb 004h	; 6d7e
	defb 006h	; 6d7f
	defb 004h	; 6d80
	defb 006h	; 6d81
	defb 004h	; 6d82
	defb 008h	; 6d83
	defb 000h	; 6d84
	defb 000h	; 6d85
	defb 002h	; 6d86
	defb 004h	; 6d87
	defb 00ah	; 6d88
	defb 00ch	; 6d89
	defb 00eh	; 6d8a
	defb 010h	; 6d8b
	defb 00eh	; 6d8c
	defb 010h	; 6d8d
	defb 00eh	; 6d8e
	defb 010h	; 6d8f
	defb 00eh	; 6d90
	defb 010h	; 6d91
	defb 00eh	; 6d92
	defb 010h	; 6d93
	defb 00eh	; 6d94
	defb 010h	; 6d95
	defb 00eh	; 6d96
	defb 010h	; 6d97
	defb 00eh	; 6d98
	defb 000h	; 6d99
	defb 012h	; 6d9a
	defb 014h	; 6d9b
	defb 016h	; 6d9c
	defb 018h	; 6d9d
	defb 014h	; 6d9e
	defb 01ah	; 6d9f
	defb 018h	; 6da0
	defb 014h	; 6da1
	defb 016h	; 6da2
	defb 018h	; 6da3
	defb 014h	; 6da4
	defb 01ah	; 6da5
	defb 018h	; 6da6
	defb 014h	; 6da7
	defb 016h	; 6da8
	defb 018h	; 6da9
	defb 014h	; 6daa
	defb 016h	; 6dab
	defb 018h	; 6dac
	defb 014h	; 6dad
	defb 01ah	; 6dae
	defb 018h	; 6daf
	defb 014h	; 6db0
	defb 016h	; 6db1
	defb 018h	; 6db2
	defb 014h	; 6db3
	defb 01ah	; 6db4
	defb 018h	; 6db5
	defb 014h	; 6db6
	defb 016h	; 6db7
	defb 018h	; 6db8
	defb 014h	; 6db9
	defb 016h	; 6dba
	defb 018h	; 6dbb
	defb 000h	; 6dbc
	defb 000h	; 6dbd
	defb 002h	; 6dbe
	defb 004h	; 6dbf
	defb 00ah	; 6dc0
	defb 01ch	; 6dc1
	defb 01eh	; 6dc2
	defb 020h	; 6dc3
	defb 01ch	; 6dc4
	defb 01eh	; 6dc5
	defb 020h	; 6dc6
	defb 01ch	; 6dc7
	defb 01eh	; 6dc8
	defb 020h	; 6dc9
	defb 01ch	; 6dca
	defb 022h	; 6dcb
	defb 020h	; 6dcc
	defb 01ch	; 6dcd
	defb 01eh	; 6dce
	defb 020h	; 6dcf
	defb 01ch	; 6dd0
	defb 022h	; 6dd1
	defb 020h	; 6dd2
	defb 01ch	; 6dd3
	defb 01eh	; 6dd4
	defb 020h	; 6dd5
	defb 01ch	; 6dd6
	defb 01eh	; 6dd7
	defb 020h	; 6dd8
	defb 024h	; 6dd9
	defb 000h	; 6dda
	defb 000h	; 6ddb
	defb 000h	; 6ddc
	defb 000h	; 6ddd
	defb 000h	; 6dde
	defb 026h	; 6ddf
	defb 028h	; 6de0
	defb 028h	; 6de1
	defb 02ah	; 6de2
	defb 000h	; 6de3
	defb 000h	; 6de4
	defb 02ch	; 6de5
	defb 02eh	; 6de6
	defb 030h	; 6de7
	defb 032h	; 6de8
	defb 034h	; 6de9
	defb 02eh	; 6dea
	defb 030h	; 6deb
	defb 032h	; 6dec
	defb 034h	; 6ded
	defb 02eh	; 6dee
	defb 030h	; 6def
	defb 032h	; 6df0
	defb 034h	; 6df1
	defb 02eh	; 6df2
	defb 030h	; 6df3
	defb 032h	; 6df4
	defb 034h	; 6df5
	defb 02eh	; 6df6
	defb 030h	; 6df7
	defb 032h	; 6df8
	defb 034h	; 6df9
	defb 02eh	; 6dfa
	defb 036h	; 6dfb
	defb 032h	; 6dfc
	defb 038h	; 6dfd
	defb 000h	; 6dfe
	defb 000h	; 6dff
	defb 0ffh	; 6e00

; ----------------------------------------------------------------------
; DATOS tabla_de_tramos: Veintinueve punteros a los tramos de aqui abajo
;   0x6e01..0x6e3b  (58 bytes)
DATA_tabla_de_tramos:
	defw 06e3bh,06e57h,06e5eh,06e6ch,06e7eh,06e8ah,06e96h,06e98h	; 6e01
	defw 06eb6h,06eb8h,06ebah,06ec6h,06ed0h,06edbh,06ee5h,06ef0h	; 6e11
	defw 06efeh,06f06h,06f14h,06f18h,06f31h,06f4ah,06f59h,06f63h	; 6e21
	defw 06f72h,06f76h,06f7ch,06f85h,06f89h	; 6e31

; ----------------------------------------------------------------------
; DATOS tramos_del_mapa: Cada tramo es una lista de codigos de fila terminada
;   en 0xFF, y cada codigo indexa los bloques de 0x6F8F. Puestos en fila salen
;   las 1761 filas del escenario, que son 73 pantallas
;   0x6e3b..0x6f8f  (340 bytes)
DATA_tramos_del_mapa:
	defb 000h	; 6e3b
	defb 000h	; 6e3c
	defb 000h	; 6e3d
	defb 000h	; 6e3e
	defb 000h	; 6e3f
	defb 000h	; 6e40
	defb 000h	; 6e41
	defb 000h	; 6e42
	defb 000h	; 6e43
	defb 000h	; 6e44
	defb 000h	; 6e45
	defb 000h	; 6e46
	defb 001h	; 6e47
	defb 002h	; 6e48
	defb 003h	; 6e49
	defb 004h	; 6e4a
	defb 005h	; 6e4b
	defb 006h	; 6e4c
	defb 007h	; 6e4d
	defb 008h	; 6e4e
	defb 009h	; 6e4f
	defb 00ah	; 6e50
	defb 00bh	; 6e51
	defb 000h	; 6e52
	defb 000h	; 6e53
	defb 000h	; 6e54
	defb 000h	; 6e55
	defb 0ffh	; 6e56
	defb 00ch	; 6e57
	defb 00dh	; 6e58
	defb 00eh	; 6e59
	defb 00fh	; 6e5a
	defb 010h	; 6e5b
	defb 011h	; 6e5c
	defb 0ffh	; 6e5d
	defb 012h	; 6e5e
	defb 013h	; 6e5f
	defb 014h	; 6e60
	defb 015h	; 6e61
	defb 016h	; 6e62
	defb 017h	; 6e63
	defb 018h	; 6e64
	defb 019h	; 6e65
	defb 01ah	; 6e66
	defb 01bh	; 6e67
	defb 01ch	; 6e68
	defb 01dh	; 6e69
	defb 01eh	; 6e6a
	defb 0ffh	; 6e6b
	defb 01fh	; 6e6c
	defb 020h	; 6e6d
	defb 021h	; 6e6e
	defb 022h	; 6e6f
	defb 023h	; 6e70
	defb 024h	; 6e71
	defb 02ah	; 6e72
	defb 02bh	; 6e73
	defb 02ch	; 6e74
	defb 02dh	; 6e75
	defb 02eh	; 6e76
	defb 02fh	; 6e77
	defb 030h	; 6e78
	defb 031h	; 6e79
	defb 032h	; 6e7a
	defb 033h	; 6e7b
	defb 034h	; 6e7c
	defb 0ffh	; 6e7d
	defb 035h	; 6e7e
	defb 036h	; 6e7f
	defb 037h	; 6e80
	defb 038h	; 6e81
	defb 039h	; 6e82
	defb 03ah	; 6e83
	defb 03bh	; 6e84
	defb 03ch	; 6e85
	defb 03dh	; 6e86
	defb 03eh	; 6e87
	defb 03fh	; 6e88
	defb 0ffh	; 6e89
	defb 01fh	; 6e8a
	defb 020h	; 6e8b
	defb 021h	; 6e8c
	defb 022h	; 6e8d
	defb 023h	; 6e8e
	defb 024h	; 6e8f
	defb 025h	; 6e90
	defb 026h	; 6e91
	defb 027h	; 6e92
	defb 028h	; 6e93
	defb 029h	; 6e94
	defb 0ffh	; 6e95
	defb 040h	; 6e96
	defb 0ffh	; 6e97
	defb 042h	; 6e98
	defb 043h	; 6e99
	defb 044h	; 6e9a
	defb 045h	; 6e9b
	defb 046h	; 6e9c
	defb 047h	; 6e9d
	defb 048h	; 6e9e
	defb 049h	; 6e9f
	defb 04ah	; 6ea0
	defb 04bh	; 6ea1
	defb 04ch	; 6ea2
	defb 04dh	; 6ea3
	defb 04eh	; 6ea4
	defb 04fh	; 6ea5
	defb 050h	; 6ea6
	defb 051h	; 6ea7
	defb 052h	; 6ea8
	defb 053h	; 6ea9
	defb 054h	; 6eaa
	defb 055h	; 6eab
	defb 056h	; 6eac
	defb 057h	; 6ead
	defb 058h	; 6eae
	defb 059h	; 6eaf
	defb 05ah	; 6eb0
	defb 05bh	; 6eb1
	defb 05ch	; 6eb2
	defb 05dh	; 6eb3
	defb 05eh	; 6eb4
	defb 0ffh	; 6eb5
	defb 041h	; 6eb6
	defb 0ffh	; 6eb7
	defb 05fh	; 6eb8
	defb 0ffh	; 6eb9
	defb 062h	; 6eba
	defb 063h	; 6ebb
	defb 064h	; 6ebc
	defb 065h	; 6ebd
	defb 066h	; 6ebe
	defb 067h	; 6ebf
	defb 068h	; 6ec0
	defb 069h	; 6ec1
	defb 06ah	; 6ec2
	defb 06bh	; 6ec3
	defb 06ch	; 6ec4
	defb 0ffh	; 6ec5
	defb 06dh	; 6ec6
	defb 06eh	; 6ec7
	defb 06fh	; 6ec8
	defb 070h	; 6ec9
	defb 071h	; 6eca
	defb 072h	; 6ecb
	defb 073h	; 6ecc
	defb 074h	; 6ecd
	defb 075h	; 6ece
	defb 0ffh	; 6ecf
	defb 076h	; 6ed0
	defb 077h	; 6ed1
	defb 078h	; 6ed2
	defb 079h	; 6ed3
	defb 07ah	; 6ed4
	defb 07bh	; 6ed5
	defb 07ch	; 6ed6
	defb 07dh	; 6ed7
	defb 060h	; 6ed8
	defb 061h	; 6ed9
	defb 0ffh	; 6eda
	defb 07eh	; 6edb
	defb 07fh	; 6edc
	defb 080h	; 6edd
	defb 080h	; 6ede
	defb 080h	; 6edf
	defb 080h	; 6ee0
	defb 080h	; 6ee1
	defb 081h	; 6ee2
	defb 082h	; 6ee3
	defb 0ffh	; 6ee4
	defb 083h	; 6ee5
	defb 084h	; 6ee6
	defb 085h	; 6ee7
	defb 086h	; 6ee8
	defb 087h	; 6ee9
	defb 088h	; 6eea
	defb 089h	; 6eeb
	defb 08ah	; 6eec
	defb 08bh	; 6eed
	defb 08ch	; 6eee
	defb 0ffh	; 6eef
	defb 08dh	; 6ef0
	defb 08eh	; 6ef1
	defb 08fh	; 6ef2
	defb 090h	; 6ef3
	defb 091h	; 6ef4
	defb 092h	; 6ef5
	defb 093h	; 6ef6
	defb 094h	; 6ef7
	defb 095h	; 6ef8
	defb 096h	; 6ef9
	defb 097h	; 6efa
	defb 098h	; 6efb
	defb 099h	; 6efc
	defb 0ffh	; 6efd
	defb 09ah	; 6efe
	defb 09bh	; 6eff
	defb 09ch	; 6f00
	defb 09dh	; 6f01
	defb 09eh	; 6f02
	defb 09fh	; 6f03
	defb 0a0h	; 6f04
	defb 0ffh	; 6f05
	defb 0a1h	; 6f06
	defb 0a2h	; 6f07
	defb 0a3h	; 6f08
	defb 0a4h	; 6f09
	defb 0a4h	; 6f0a
	defb 0a4h	; 6f0b
	defb 0a5h	; 6f0c
	defb 0a6h	; 6f0d
	defb 0a7h	; 6f0e
	defb 0a8h	; 6f0f
	defb 0a9h	; 6f10
	defb 0aah	; 6f11
	defb 099h	; 6f12
	defb 0ffh	; 6f13
	defb 0abh	; 6f14
	defb 0ach	; 6f15
	defb 0adh	; 6f16
	defb 0ffh	; 6f17
	defb 0aeh	; 6f18
	defb 0afh	; 6f19
	defb 0afh	; 6f1a
	defb 0b0h	; 6f1b
	defb 0b1h	; 6f1c
	defb 0b2h	; 6f1d
	defb 0b3h	; 6f1e
	defb 0b4h	; 6f1f
	defb 0b5h	; 6f20
	defb 0b6h	; 6f21
	defb 0b7h	; 6f22
	defb 0b8h	; 6f23
	defb 0b9h	; 6f24
	defb 0bah	; 6f25
	defb 0bbh	; 6f26
	defb 0bch	; 6f27
	defb 0bdh	; 6f28
	defb 0beh	; 6f29
	defb 0bbh	; 6f2a
	defb 0b6h	; 6f2b
	defb 0bbh	; 6f2c
	defb 0b6h	; 6f2d
	defb 0bbh	; 6f2e
	defb 0b6h	; 6f2f
	defb 0ffh	; 6f30
	defb 0bbh	; 6f31
	defb 0b6h	; 6f32
	defb 0bbh	; 6f33
	defb 0b6h	; 6f34
	defb 0bbh	; 6f35
	defb 0b6h	; 6f36
	defb 0b7h	; 6f37
	defb 0bfh	; 6f38
	defb 0bbh	; 6f39
	defb 0b6h	; 6f3a
	defb 0bbh	; 6f3b
	defb 0bch	; 6f3c
	defb 0bdh	; 6f3d
	defb 0beh	; 6f3e
	defb 0bbh	; 6f3f
	defb 0b6h	; 6f40
	defb 0bbh	; 6f41
	defb 0b6h	; 6f42
	defb 0bbh	; 6f43
	defb 0b6h	; 6f44
	defb 0bbh	; 6f45
	defb 0b6h	; 6f46
	defb 0bbh	; 6f47
	defb 0b6h	; 6f48
	defb 0ffh	; 6f49
	defb 0bbh	; 6f4a
	defb 0b6h	; 6f4b
	defb 0bbh	; 6f4c
	defb 0b6h	; 6f4d
	defb 0bbh	; 6f4e
	defb 0c0h	; 6f4f
	defb 0c1h	; 6f50
	defb 0c2h	; 6f51
	defb 0c3h	; 6f52
	defb 0c4h	; 6f53
	defb 0c5h	; 6f54
	defb 0c6h	; 6f55
	defb 0c7h	; 6f56
	defb 0c8h	; 6f57
	defb 0ffh	; 6f58
	defb 0c9h	; 6f59
	defb 0cah	; 6f5a
	defb 0cbh	; 6f5b
	defb 0cch	; 6f5c
	defb 0cdh	; 6f5d
	defb 0ceh	; 6f5e
	defb 0cfh	; 6f5f
	defb 0d0h	; 6f60
	defb 0d1h	; 6f61
	defb 0ffh	; 6f62
	defb 0d2h	; 6f63
	defb 0d3h	; 6f64
	defb 0d4h	; 6f65
	defb 0d5h	; 6f66
	defb 0d6h	; 6f67
	defb 0d7h	; 6f68
	defb 0d8h	; 6f69
	defb 0d9h	; 6f6a
	defb 0dah	; 6f6b
	defb 0dbh	; 6f6c
	defb 0dch	; 6f6d
	defb 0ddh	; 6f6e
	defb 0deh	; 6f6f
	defb 0dfh	; 6f70
	defb 0ffh	; 6f71
	defb 0e0h	; 6f72
	defb 0e1h	; 6f73
	defb 0e2h	; 6f74
	defb 0ffh	; 6f75
	defb 0e3h	; 6f76
	defb 0e4h	; 6f77
	defb 0e5h	; 6f78
	defb 0e6h	; 6f79
	defb 0e7h	; 6f7a
	defb 0ffh	; 6f7b
	defb 0e8h	; 6f7c
	defb 0e9h	; 6f7d
	defb 0eah	; 6f7e
	defb 0ebh	; 6f7f
	defb 0ech	; 6f80
	defb 0edh	; 6f81
	defb 0eeh	; 6f82
	defb 0efh	; 6f83
	defb 0ffh	; 6f84
	defb 0f0h	; 6f85
	defb 0f1h	; 6f86
	defb 0f2h	; 6f87
	defb 0ffh	; 6f88
	defb 0f3h	; 6f89
	defb 0f4h	; 6f8a
	defb 0f5h	; 6f8b
	defb 0f6h	; 6f8c
	defb 0f7h	; 6f8d
	defb 0ffh	; 6f8e

; ----------------------------------------------------------------------
; DATOS filas_del_decorado: Los 248 bloques de 32 casillas con los que se
;   monta el escenario entero. Una fila de la pantalla cada uno
;   0x6f8f..0x8e8f  (7936 bytes)
DATA_filas_del_decorado:
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h	; 6f8f  vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,092h,09ch,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h	; 6faf  vvvvvvvvvvvvv..vvvvvvvvvvvvvvvvv
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08fh,099h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h	; 6fcf  vvvvvvvvvvvvv..vvvvvvvvvvvvvvvvv
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08ah,094h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h	; 6fef  vvvvvvvvvvvvv..vvvvvvvvvvvvvvvvv
	defb 076h,076h,076h,076h,076h,076h,076h,076h,092h,09ch,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h	; 700f  vvvvvvvv..vvvvvvvvvvvvvvvvvvvvvv
	defb 076h,076h,076h,076h,076h,076h,076h,092h,08fh,099h,09ch,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h	; 702f  vvvvvvv....vvvvvvvvvvvvvvvvvvvvv
	defb 076h,076h,076h,076h,076h,076h,092h,08fh,07ah,07eh,099h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h	; 704f  vvvvvv..z~.vvvvvvvvvvvvvvvvvvvvv
	defb 076h,076h,076h,076h,076h,076h,08fh,079h,079h,07dh,079h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h	; 706f  vvvvvv.yy}yvvvvvvvvvvvvvvvvvvvvv
	defb 076h,076h,076h,076h,076h,076h,089h,079h,079h,079h,094h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h	; 708f  vvvvvv.yyy.vvvvvvvvvvvvvvvvvvvvv
	defb 076h,076h,076h,076h,076h,076h,08bh,079h,079h,099h,09ch,076h,076h,076h,076h,076h,076h,092h,085h,09ch,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h	; 70af  vvvvvv.yy..vvvvvv...vvvvvvvvvvvv
	defb 076h,076h,076h,076h,076h,076h,076h,089h,079h,079h,099h,076h,076h,076h,076h,076h,076h,08fh,079h,099h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h	; 70cf  vvvvvvv.yy.vvvvvv.y.vvvvvvvvvvvv
	defb 076h,076h,076h,076h,076h,076h,076h,08bh,079h,079h,094h,076h,076h,076h,076h,076h,076h,08ah,079h,094h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h	; 70ef  vvvvvvv.yy.vvvvvv.y.vvvvvvvvvvvv
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,092h,085h,085h,085h,085h,085h,085h,085h	; 710f  vvvvvvvvvvvvvvvvvvvvvvvv........
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh	; 712f  vvvvvvvvvvvvvvvvvvvvvvvv........
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,089h,079h,079h,07ah,07eh,079h,079h,079h	; 714f  vvvvvvvvvvvvvvvvvvvvvvvv.yyz~yyy
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08bh,079h,079h,079h,07dh,079h,079h,079h	; 716f  vvvvvvvvvvvvvvvvvvvvvvvv.yyy}yyy
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,089h,09dh,09eh,0b6h,0a7h,0bah,079h	; 718f  vvvvvvvvvvvvvvvvvvvvvvvvv......y
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08bh,0bch,0b1h,088h,079h,088h,079h	; 71af  vvvvvvvvvvvvvvvvvvvvvvvvv....y.y
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08ah,079h,088h,079h,088h,079h	; 71cf  vvvvvvvvvvvvvvvvvvvvvvvvvv.y.y.y
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,092h,079h,088h,079h,0b0h,0a7h	; 71ef  vvvvvvvvvvvvvvvvvvvvvvvvvv.y.y..
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,092h,08fh,079h,088h,079h,09dh,09eh	; 720f  vvvvvvvvvvvvvvvvvvvvvvvvv..y.y..
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,092h,08fh,079h,079h,088h,079h,0bch,0b1h	; 722f  vvvvvvvvvvvvvvvvvvvvvvvv..yy.y..
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,092h,08fh,079h,079h,0ach,0bbh,079h,079h,079h	; 724f  vvvvvvvvvvvvvvvvvvvvvvv..yy..yyy
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,092h,08fh,079h,079h,0aeh,0adh,079h,079h,079h,079h	; 726f  vvvvvvvvvvvvvvvvvvvvvv..yy..yyyy
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,092h,08fh,079h,079h,0aeh,0adh,079h,079h,079h,0afh,0a7h	; 728f  vvvvvvvvvvvvvvvvvvvvv..yy..yyy..
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08fh,079h,079h,0aah,0adh,079h,079h,079h,079h,088h,079h	; 72af  vvvvvvvvvvvvvvvvvvvvv.yy..yyyy.y
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08ah,079h,079h,088h,079h,079h,079h,079h,079h,088h,079h	; 72cf  vvvvvvvvvvvvvvvvvvvvv.yy.yyyyy.y
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08ah,079h,0b0h,0a7h,0a7h,0a7h,0bah,079h,088h,079h	; 72ef  vvvvvvvvvvvvvvvvvvvvvv.y.....y.y
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08ah,079h,079h,079h,079h,088h,079h,088h,079h	; 730f  vvvvvvvvvvvvvvvvvvvvvvv.yyyy.y.y
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08ah,079h,079h,079h,0b0h,0a7h,0abh,079h	; 732f  vvvvvvvvvvvvvvvvvvvvvvvv.yyy...y
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,092h,079h,079h,079h,079h,079h,088h,079h	; 734f  vvvvvvvvvvvvvvvvvvvvvvvv.yyyyy.y
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,092h,08fh,079h,079h,079h,079h,0ach,0bbh,079h	; 736f  vvvvvvvvvvvvvvvvvvvvvvv..yyyy..y
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,092h,08fh,079h,079h,079h,079h,0aah,0adh,079h,079h	; 738f  vvvvvvvvvvvvvvvvvvvvvv..yyyy..yy
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,081h,08fh,079h,079h,079h,0afh,0a7h,0bbh,079h,079h,079h	; 73af  vvvvvvvvvvvvvvvvvvvvv..yyy...yyy
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,080h,079h,079h,09dh,09eh,088h,079h,079h,079h,079h,079h	; 73cf  vvvvvvvvvvvvvvvvvvvvv.yy...yyyyy
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,081h,07fh,079h,079h,0bch,0b1h,088h,079h,079h,079h,079h,0afh	; 73ef  vvvvvvvvvvvvvvvvvvvv..yy...yyyy.
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,080h,079h,07ah,07eh,079h,079h,0b0h,0a7h,0a7h,0a7h,0bah,088h	; 740f  vvvvvvvvvvvvvvvvvvvv.yz~yy......
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,092h,07fh,079h,079h,07dh,079h,079h,079h,079h,079h,079h,0b6h,0bbh	; 742f  vvvvvvvvvvvvvvvvvvv..yy}yyyyyy..
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,092h,08fh,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,088h,079h	; 744f  vvvvvvvvvvvvvvvvvv..yyy.yyyyyy.y
	defb 085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,08fh,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,088h,079h	; 746f  ...................yyyy.yyyyyy.y
	defb 09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,079h,079h,079h,079h,079h,088h,079h,079h,09dh,09eh,0afh,0a7h,0bbh,079h	; 748f  ..................yyyyy.yy.....y
	defb 079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,0afh,0a7h,0a7h,0a7h,0a7h,0bbh,079h,079h,0bch,0b1h,088h,079h,079h,079h	; 74af  yyyyyyyyyyyyyyyyyy......yy...yyy
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,07fh,079h,079h,07dh,079h,079h,079h,079h,079h,079h,0b6h,0bbh	; 74cf  vvvvvvvvvvvvvvvvvvvv.yy}yyyyyy..
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08ah,079h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h	; 74ef  vvvvvvvvvvvvvvvvvvvv.yyyyyyyyy.y
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08ah,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h	; 750f  vvvvvvvvvvvvvvvvvvvvv.yyyyyyyy.y
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,089h,079h,079h,079h,09dh,09eh,0afh,0a7h,0bbh,079h	; 752f  vvvvvvvvvvvvvvvvvvvvvv.yyy.....y
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08bh,079h,079h,079h,0bch,0b1h,088h,079h,079h,079h	; 754f  vvvvvvvvvvvvvvvvvvvvvv.yyy...yyy
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,089h,079h,079h,079h,079h,088h,09dh,09eh,079h	; 756f  vvvvvvvvvvvvvvvvvvvvvvv.yyyy...y
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08bh,079h,079h,079h,079h,088h,0bch,0b1h,079h	; 758f  vvvvvvvvvvvvvvvvvvvvvvv.yyyy...y
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,089h,079h,079h,079h,088h,079h,079h,079h	; 75af  vvvvvvvvvvvvvvvvvvvvvvvv.yyy.yyy
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08bh,079h,079h,079h,088h,079h,079h,079h	; 75cf  vvvvvvvvvvvvvvvvvvvvvvvv.yyy.yyy
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,089h,09dh,09eh,0b6h,0a7h,0bah,079h	; 75ef  vvvvvvvvvvvvvvvvvvvvvvvvv......y
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08bh,0bch,0b1h,088h,079h,088h,079h	; 760f  vvvvvvvvvvvvvvvvvvvvvvvvv....y.y
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,092h,08fh,079h,0afh,0a7h,0a7h,0a7h,0bbh,079h	; 762f  vvvvvvvvvvvvvvvvvvvvvvv..y.....y
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,092h,08fh,079h,079h,088h,079h,079h,079h,079h,079h	; 764f  vvvvvvvvvvvvvvvvvvvvvv..yy.yyyyy
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,081h,08fh,079h,079h,079h,0b0h,0a7h,0a7h,0a7h,0a7h,0a7h	; 766f  vvvvvvvvvvvvvvvvvvvvv..yyy......
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,080h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h	; 768f  vvvvvvvvvvvvvvvvvvvvv.yyyyyyyyyy
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,081h,07fh,079h,079h,0c5h,0cah,0cbh,0cfh,0ceh,079h,079h,079h	; 76af  vvvvvvvvvvvvvvvvvvvv..yy.....yyy
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,080h,079h,079h,079h,0c4h,0c7h,0c8h,0c9h,0c6h,079h,0afh,0a7h	; 76cf  vvvvvvvvvvvvvvvvvvvv.yyy.....y..
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,07fh,079h,079h,079h,079h,0d1h,0c2h,0c3h,0cdh,079h,088h,079h	; 76ef  vvvvvvvvvvvvvvvvvvvv.yyyy....y.y
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08ah,079h,07ah,07eh,079h,079h,0c0h,0c1h,079h,079h,088h,079h	; 770f  vvvvvvvvvvvvvvvvvvvv.yz~yy..yy.y
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08ah,079h,07dh,079h,079h,0cch,0d0h,079h,079h,0b0h,0a7h	; 772f  vvvvvvvvvvvvvvvvvvvvv.y}yy..yy..
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,089h,079h,079h,079h,079h,079h,079h,079h,079h,079h	; 774f  vvvvvvvvvvvvvvvvvvvvvv.yyyyyyyyy
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08bh,079h,079h,079h,079h,079h,079h,079h,079h,079h	; 776f  vvvvvvvvvvvvvvvvvvvvvv.yyyyyyyyy
	defb 09dh,09eh,0afh,0a7h,0a7h,0b4h,0bfh,079h,079h,079h,079h,079h,079h,0afh,0a7h,0a7h,0a7h,0a7h,0bbh,079h,079h,079h,09dh,09eh,079h,079h,079h,079h,0b0h,0bah,079h,079h	; 778f  .......yyyyyy......yyy..yyyy..yy
	defb 09dh,09eh,0afh,0a7h,0a7h,0bbh,079h,079h,079h,079h,079h,079h,079h,0afh,0a7h,0bbh,079h,079h,079h,079h,079h,079h,09dh,09eh,079h,079h,079h,079h,079h,088h,079h,079h	; 77af  ......yyyyyyy...yyyyyy..yyyyy.yy
	defb 0bch,0b1h,088h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h,079h,0bch,0b1h,079h,079h,079h,079h,079h,088h,079h,079h	; 77cf  ...yyyyyyyyyy.yyyyyyyy..yyyyy.yy
	defb 079h,079h,088h,079h,079h,079h,079h,079h,0afh,0a7h,0a7h,0a7h,0a9h,0bbh,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,0b4h,0bfh,079h,079h,079h,088h,079h,079h	; 77ef  yy.yyyyy......yyyyyyyyyy..yyy.yy
	defb 079h,079h,0b6h,0a7h,0bah,079h,0afh,0a7h,0bbh,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h,0b3h,076h,076h,0beh,079h,079h,079h,079h,079h,088h,079h,079h	; 780f  yy...y...yyy.yyyyyyy.vv.yyyyy.yy
	defb 079h,079h,088h,079h,088h,079h,088h,079h,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h,0b2h,077h,077h,0bdh,079h,079h,09dh,09eh,0afh,0bbh,079h,079h	; 782f  yy.y.y.yyyyy.yyyyyyy.ww.yy....yy
	defb 0a7h,0a7h,0bbh,079h,0b0h,0a7h,0bbh,079h,079h,079h,0ach,0a7h,0a8h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0bah,079h,079h,079h,079h,079h,079h,0bch,0b1h,088h,079h,079h,079h	; 784f  ...y...yyy..........yyyyyy...yyy
	defb 0a4h,0a4h,0a3h,0a3h,079h,079h,079h,079h,079h,0aeh,0adh,079h,0c8h,0c7h,0cch,0c2h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,079h,079h	; 786f  ....yyyyy..y....yyy.yyyyyyyy.yyy
	defb 0a4h,0a4h,0a3h,0a3h,079h,079h,079h,079h,0aeh,0adh,079h,079h,0a0h,0c6h,0cbh,0c1h,0afh,0a7h,0a7h,0bbh,079h,0afh,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a8h,0a7h,0bah,079h	; 788f  ....yyyy..yy........y..........y
	defb 0a3h,0a3h,0a4h,0a4h,079h,079h,079h,0aeh,0adh,079h,09dh,09eh,079h,0c5h,0cbh,0c0h,088h,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h	; 78af  ....yyy..y..y....yyyy.yyyyyyyy.y
	defb 0a3h,0a3h,0a4h,0a4h,079h,079h,0aah,0adh,079h,079h,0bch,0b1h,079h,0c3h,0cah,079h,088h,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h	; 78cf  ....yy..yy..y..y.yyyy.yyyyyyyy.y
	defb 09dh,09eh,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h,079h,079h,0b0h,0a7h,0bah,079h,079h,088h,079h,0a1h,0c8h,0c7h,0cch,0c2h,079h,079h,088h,079h	; 78ef  ..yyyy.yyyyyyyyy...yy.y.....yy.y
	defb 0bch,0b1h,079h,079h,079h,079h,088h,079h,0b3h,076h,076h,0beh,079h,079h,079h,079h,079h,079h,088h,079h,079h,088h,079h,0a0h,0c7h,0c6h,0cbh,0c1h,079h,079h,0b0h,0a7h	; 790f  ..yyyy.y.vv.yyyyyy.yy.y.....yy..
	defb 079h,079h,079h,079h,079h,079h,088h,079h,0b2h,077h,077h,0bdh,079h,079h,079h,079h,079h,079h,088h,079h,079h,088h,079h,079h,0c6h,0c6h,0cbh,0c1h,079h,079h,09dh,09eh	; 792f  yyyyyy.y.ww.yyyyyy.yy.yy....yy..
	defb 079h,079h,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,079h,088h,079h,079h,0c6h,0c6h,0cbh,0c1h,079h,079h,0bch,0b1h	; 794f  yyyyyy.yyyyyyyyyyy.yy.yy....yy..
	defb 079h,079h,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,0b0h,0a7h,0a7h,0abh,09dh,09eh,0c6h,0c6h,0cbh,0c1h,079h,079h,079h,079h	; 796f  yyyyyy.yyyyyyyyyyy..........yyyy
	defb 079h,0afh,0a7h,0a7h,0a7h,0a7h,0a8h,0a7h,0a7h,0a7h,0bah,079h,0b4h,0bfh,079h,079h,079h,079h,079h,079h,079h,088h,0bch,0b1h,0c4h,0c5h,0cbh,0c0h,0b3h,076h,076h,0beh	; 798f  y..........y..yyyyyyy........vv.
	defb 079h,088h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,079h,079h,09dh,09eh,079h,079h,079h,079h,079h,0b0h,0a7h,0bah,0cfh,0c9h,0cdh,0ceh,0b2h,077h,077h,0bdh	; 79af  y.yyyyyyyy.yyy..yyyyy........ww.
	defb 079h,088h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,079h,079h,0bch,0b1h,079h,079h,079h,079h,079h,079h,079h,088h,079h,0c3h,0cah,079h,079h,079h,079h,079h	; 79cf  y.yyyyyyyy.yyy..yyyyyyy.y..yyyyy
	defb 079h,088h,079h,0a1h,0c8h,0c7h,0cch,0c2h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h,079h	; 79ef  y.y.....yy.yyyyyyyyyyyy.yyyyyyyy
	defb 079h,088h,079h,0a0h,0c7h,0c6h,0cbh,0c1h,079h,079h,088h,079h,079h,0afh,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0bah,079h,079h,088h,079h,0afh,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h	; 7a0f  y.y.....yy.yy........yy.y.......
	defb 079h,088h,079h,079h,0c6h,0c6h,0cbh,0c1h,079h,079h,088h,079h,079h,088h,079h,079h,079h,079h,079h,079h,088h,079h,079h,088h,079h,088h,079h,079h,079h,079h,079h,079h	; 7a2f  y.yy....yy.yy.yyyyyy.yy.y.yyyyyy
	defb 079h,088h,079h,079h,0c6h,0c6h,0cbh,0c1h,079h,079h,088h,079h,079h,088h,079h,079h,079h,079h,079h,079h,0b0h,0a7h,0a7h,0abh,079h,088h,079h,079h,079h,079h,079h,079h	; 7a4f  y.yy....yy.yy.yyyyyy....y.yyyyyy
	defb 0a7h,0abh,09dh,09eh,0c6h,0c6h,0cbh,0c1h,079h,079h,088h,079h,079h,088h,079h,0a1h,0c8h,0c7h,0cch,0c2h,079h,079h,079h,088h,079h,088h,079h,079h,0a4h,0a4h,0a3h,0a3h	; 7a6f  ........yy.yy.y.....yyy.y.yy....
	defb 079h,088h,0bch,0b1h,0c4h,0c5h,0cbh,0c0h,079h,079h,088h,079h,079h,088h,079h,0a0h,0c7h,0c6h,0cbh,0c1h,079h,079h,079h,0b6h,0a7h,0bbh,079h,079h,0a4h,0a4h,0a3h,0a3h	; 7a8f  y.......yy.yy.y.....yyy...yy....
	defb 079h,0b0h,0a7h,0bah,0cfh,0c9h,0cdh,0ceh,079h,079h,088h,079h,079h,088h,079h,079h,0c6h,0c6h,0cbh,0c1h,079h,079h,079h,088h,079h,079h,079h,079h,0a3h,0a3h,0a4h,0a4h	; 7aaf  y.......yy.yy.yy....yyy.yyyy....
	defb 079h,079h,079h,088h,079h,0c3h,0cah,079h,079h,079h,088h,079h,079h,088h,079h,079h,0c6h,0c6h,0cbh,0c1h,079h,079h,079h,088h,079h,079h,079h,079h,0a3h,0a3h,0a4h,0a4h	; 7acf  yyy.y..yyy.yy.yy....yyy.yyyy....
	defb 079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,0b0h,0a7h,0a7h,0abh,09dh,09eh,0c6h,0c6h,0cbh,0c1h,09dh,09eh,079h,0b0h,0a7h,0a7h,0a7h,0a7h,0a7h,0bah,079h,079h	; 7aef  yyy.yyyyyy............y.......yy
	defb 079h,0b4h,0bfh,088h,079h,0afh,0a7h,0a7h,0b4h,0bfh,079h,079h,079h,088h,0bch,0b1h,0c4h,0c5h,0cbh,0c0h,0bch,0b1h,079h,079h,0b4h,0bfh,079h,079h,079h,088h,079h,079h	; 7b0f  y...y.....yyy.........yy..yyy.yy
	defb 079h,079h,079h,088h,079h,088h,079h,079h,079h,079h,09dh,09eh,079h,0b0h,0a7h,0bah,0cfh,0c9h,0cdh,0ceh,079h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,079h	; 7b2f  yyy.y.yyyy..y.......yyyyyyyyy.yy
	defb 0a7h,0a7h,0a7h,0bbh,079h,088h,079h,079h,079h,079h,0bch,0b1h,079h,079h,079h,088h,079h,0c3h,0cah,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,079h	; 7b4f  ....y.yyyy..yyy.y..yyyyyyyyyy.yy
	defb 085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h	; 7b6f  ................................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0a1h,0c5h,0cdh,0ceh,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h	; 7b8f  ................................
	defb 0a7h,0a7h,0a7h,0a7h,0a9h,0a7h,0a7h,0a7h,0a7h,0bbh,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0a0h,0c1h,0cbh,0c8h,0c9h,0b0h,0a7h,0a7h,0a7h,0bah,0c9h,0c9h	; 7baf  ................................
	defb 0a4h,0a4h,0a3h,0a3h,0cah,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h	; 7bcf  ................................
	defb 0a4h,0a4h,0a3h,0a3h,0b0h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0bah,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h	; 7bef  ................................
	defb 0a3h,0a3h,0a4h,0a4h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0b3h,076h,076h,0beh,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h	; 7c0f  .............vv.................
	defb 0a3h,0a3h,0a4h,0a4h,0c9h,0c9h,0c9h,0c9h,0c9h,0afh,0a7h,0bbh,0b2h,077h,077h,0bdh,0c9h,0c9h,0afh,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0abh,0c9h,0c9h	; 7c2f  .............ww.................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h	; 7c4f  ................................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,0c9h,0afh,0a7h,0a7h,0bbh,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h	; 7c6f  ................................
	defb 0c9h,0c9h,0a1h,0c5h,0c4h,0cdh,0ceh,0c9h,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,0b3h,076h,076h,0beh,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h	; 7c8f  .....................vv.........
	defb 0c9h,0c9h,0a0h,0c0h,0c3h,0cch,0c6h,0c9h,0c9h,0b0h,0a7h,0a9h,0a7h,0a7h,0a7h,0bbh,0c9h,0c9h,0c9h,0c9h,0b2h,077h,077h,0bdh,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h	; 7caf  .....................ww.........
	defb 0c9h,0c9h,0c9h,0c9h,0c3h,0c7h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h	; 7ccf  ................................
	defb 0c9h,0c9h,0c9h,0c9h,0c2h,0c7h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,0b4h,0bfh,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h	; 7cef  ................................
	defb 0c9h,0c9h,0c9h,0c9h,0d2h,0d3h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,09dh,09eh,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h	; 7d0f  ................................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0ach,0bbh,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0bch,0b1h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h	; 7d2f  ................................
	defb 0a7h,0bah,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0aeh,0adh,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h	; 7d4f  ................................
	defb 0c9h,0cah,0c9h,0c9h,0c9h,0afh,0a7h,0a7h,0d1h,0adh,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h	; 7d6f  ................................
	defb 0c9h,0cah,0c9h,0c9h,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0a1h,0c5h,0c4h,0cdh,0ceh,0c9h,0c9h,0cah,0c9h,0c9h	; 7d8f  ................................
	defb 0c9h,0b0h,0a7h,0a7h,0a7h,0abh,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0a0h,0c0h,0c3h,0cch,0c6h,0c9h,0c9h,0cah,0c9h,0c9h	; 7daf  ................................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c3h,0c7h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h	; 7dcf  ................................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0b6h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0bah,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c2h,0c7h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h	; 7def  ................................
	defb 0b3h,076h,076h,0beh,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0d2h,0d3h,0c9h,0c9h,0afh,0bbh,0c9h,0c9h	; 7e0f  .vv.............................
	defb 0b2h,077h,077h,0bdh,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0b4h,0bfh,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h,0c9h	; 7e2f  .ww.............................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0a1h,0c5h,0cdh,0ceh,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h,0c9h	; 7e4f  ................................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0a0h,0c1h,0cbh,0c8h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0afh,0a7h,0a7h,0a8h,0a7h,0bah,0c9h	; 7e6f  ................................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0a1h,0c5h,0c4h,0cdh,0ceh,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,0cah,0c9h	; 7e8f  ................................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0a0h,0c0h,0c3h,0cch,0c6h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,0cah,0c9h	; 7eaf  ................................
	defb 0a7h,0a7h,0a7h,0a7h,0a7h,0a8h,0a7h,0a7h,0a7h,0bah,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c3h,0c7h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,0cah,0c9h	; 7ecf  ................................
	defb 0b4h,0bfh,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c2h,0c7h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,0b0h,0a7h	; 7eef  ................................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0d2h,0d3h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,09dh,09eh	; 7f0f  ................................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,0c9h,0c9h,0c9h,0c9h,0bch,0b1h	; 7f2f  ................................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0afh,0a7h,0a7h,0a7h,0a7h,0a7h,0bbh,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0bch,0b1h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0afh,0bbh,0c9h,0c9h	; 7f4f  ................................
	defb 0a2h,0a2h,0a2h,0a2h,0a2h,0a6h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a6h,0a2h,0a2h,0a2h	; 7f6f  ................................
	defb 076h,076h,076h,076h,076h,0cfh,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,0cfh,076h,076h,076h	; 7f8f  vvvvv.vvvvvvvvvvvvvvvvvvvvvv.vvv
	defb 085h,085h,085h,085h,085h,0d0h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,0d0h,085h,085h,085h	; 7faf  ................................
	defb 09fh,09fh,09fh,09fh,09fh,0a5h,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,0a5h,09fh,09fh,09fh	; 7fcf  ................................
	defb 079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,0afh,0a7h,0a7h,0a7h,0bbh,079h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,078h,079h	; 7fef  yyyyyyyyyyyyyy.....yyyyyyyyy.yxy
	defb 0a7h,0a7h,0a7h,0a7h,0a9h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0bbh,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,0afh,0bbh,079h,079h,079h	; 800f  ...............yyyyyyyyyyyy..yyy
	defb 079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,079h,079h,079h	; 802f  yyyy.yyyyyyyyyyyyyyyyyyyyyy.yyyy
	defb 0b3h,076h,076h,0beh,0b6h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0bah,079h,079h,079h,088h,079h,079h,079h,079h	; 804f  .vv.....................yyy.yyyy
	defb 0b2h,077h,077h,0bdh,088h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,0afh,0a7h,0a8h,0a7h,0a7h,0a7h,0a7h	; 806f  .ww..yyyyyyyyyyyyyyyyyy.y.......
	defb 079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,0b0h,0a7h,0abh,079h,079h,079h,079h,079h,079h	; 808f  yyyy.yyyyyyyyyyyyyyyyyy...yyyyyy
	defb 079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h,07ch,086h,087h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h	; 80af  yyyy.yyyyyyy|..yyyyyyyyyy.yyyyyy
	defb 079h,0afh,0a7h,0a7h,0a8h,0a7h,0bah,079h,079h,079h,079h,079h,079h,08ch,096h,079h,079h,079h,079h,079h,0b3h,076h,076h,0beh,079h,088h,079h,079h,07ch,082h,083h,079h	; 80cf  y......yyyyyy..yyyyy.vv.y.yy|..y
	defb 079h,088h,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,0b2h,077h,077h,0bdh,0afh,0bbh,079h,079h,079h,08eh,098h,079h	; 80ef  y.yyyy.yyyyyy.yyyyyy.ww...yyy..y
	defb 079h,088h,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,088h,079h,079h,079h,078h,079h,079h,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h	; 810f  y.yyyy.yyyyyy.yyyxyyyyyy.yyyyyyy
	defb 079h,088h,079h,079h,079h,079h,0b0h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0abh,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,07bh,091h,084h,084h,084h,084h	; 812f  y.yyyy........yyyyyyyyyy.y{.....
	defb 079h,088h,079h,079h,079h,079h,079h,079h,0b4h,0bfh,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h,0afh,0a7h,0a7h,0bbh,07bh,091h,08fh,09fh,09fh,09fh,09fh	; 814f  y.yyyyyy..yyy.yyyyyyy....{......
	defb 079h,088h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,0b0h,0a7h,0bah,079h,079h,079h,079h,079h,088h,079h,079h,07bh,091h,08fh,079h,079h,079h,079h,079h	; 816f  y.yyyyyyyyyyy...yyyyy.yy{..yyyyy
	defb 079h,088h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,088h,079h,079h,07ch,08fh,079h,079h,079h,079h,079h,079h	; 818f  y.yyyyyyyyyyyyy.yyyyy.yy|.yyyyyy
	defb 0a7h,0abh,09dh,09eh,07bh,091h,084h,084h,084h,084h,09ah,079h,0afh,0a7h,0a7h,0bbh,079h,079h,079h,079h,079h,0c3h,079h,079h,079h,0c5h,079h,079h,079h,079h,079h,079h	; 81af  ....{......y....yyyyy.yyy.yyyyyy
	defb 079h,088h,0bch,0b1h,07ch,08fh,09fh,09fh,09fh,09fh,099h,079h,0c3h,079h,079h,079h,0b3h,076h,076h,0beh,079h,0b8h,0b9h,079h,079h,079h,0c5h,079h,079h,079h,079h,079h	; 81cf  y...|......y.yyy.vv.y..yyy.yyyyy
	defb 079h,0b0h,0a7h,0bah,079h,0c5h,079h,079h,079h,079h,0c1h,079h,0b8h,0b9h,079h,079h,0b2h,077h,077h,0bdh,079h,079h,0b8h,0b9h,079h,079h,079h,0c5h,0a2h,0a2h,0a2h,0a2h	; 81ef  y...y.yyyy.y..yy.ww.yy..yyy.....
	defb 079h,079h,079h,088h,079h,079h,0c5h,0a2h,0a2h,0a2h,0c4h,079h,079h,0b8h,0b5h,079h,079h,079h,079h,079h,079h,079h,079h,0b8h,0b5h,079h,079h,079h,079h,079h,079h,079h	; 820f  yyy.yy.....yy..yyyyyyyy..yyyyyyy
	defb 0b4h,0bfh,079h,088h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h	; 822f  ..y.yyyyyyyyyy.yyyyyyyyy.yyyyyyy
	defb 079h,079h,079h,088h,07ch,082h,083h,079h,079h,079h,079h,079h,079h,079h,0b0h,0a7h,0a7h,0a7h,0a7h,0bah,079h,079h,079h,079h,0b0h,0a7h,0a7h,0a7h,0bah,079h,079h,079h	; 824f  yyy.|..yyyyyyy......yyyy.....yyy
	defb 079h,079h,079h,088h,079h,08eh,098h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,079h,078h,079h,079h,079h,079h,079h,088h,07ch,086h,087h	; 826f  yyy.y..yyyyyyyyyyyy.yyxyyyyy.|..
	defb 0a7h,0a7h,0a7h,0bbh,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,0b4h,0bfh,079h,0afh,0a7h,0bbh,079h,078h,079h,078h,079h,079h,079h,079h,088h,079h,08ch,096h	; 828f  ....yyyyyyyyyy..y...yxyxyyyy.y..
	defb 084h,084h,084h,084h,084h,084h,084h,084h,084h,084h,084h,084h,09ah,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,079h,079h	; 82af  .............yyyy.yyyyyyyyyy.yyy
	defb 09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,099h,09ah,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h,0afh,0a7h,0a7h,0a8h,0a7h,0bah,079h	; 82cf  ..............yyy.yyyyyyy......y
	defb 079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,099h,09ah,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h,088h,079h,079h,079h,079h,088h,079h	; 82ef  yyyyyyyyyyyyy..yy.yyyyyyy.yyyy.y
	defb 079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,099h,079h,079h,0b0h,0a7h,0a9h,0a7h,0a7h,0a7h,0a7h,0a7h,0abh,079h,079h,079h,079h,088h,079h	; 830f  yyyyyyyyyyyyyy.yy.........yyyy.y
	defb 079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,0c4h,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,088h,079h,079h,079h,079h,088h,079h	; 832f  yyyyyyyyyyyyyy.yyyy.yyyyy.yyyy.y
	defb 079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,0c4h,079h,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,0b0h,0a7h,0a7h,0bah,079h,0b0h,0a7h	; 834f  yyyyyyyyyyyyy.yyyyy.yyyyy....y..
	defb 0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0c4h,079h,079h,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,09dh,09eh	; 836f  .............yyyyyy.yyyyyyyy.y..
	defb 079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,0afh,0bbh,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,0bch,0b1h	; 838f  yyyyyyyyyyyyyyyyyy..yyyyyyyy.y..
	defb 0a7h,0bbh,079h,079h,079h,079h,0b0h,0a7h,0a9h,0a7h,0a7h,0a7h,0a7h,0bbh,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h	; 83af  ..yyyy........yyyyyyyyyy.yyyyyyy
	defb 079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h	; 83cf  yyyyyyyy.yyyyyyyyyyyyyyy.yyyyyyy
	defb 0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a6h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a6h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h	; 83ef  ................................
	defb 076h,076h,076h,076h,076h,076h,076h,076h,0c0h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,0c0h,076h,076h,076h,076h,076h,076h,076h	; 840f  vvvvvvvv.vvvvvvvvvvvvvvv.vvvvvvv
	defb 085h,085h,085h,085h,085h,085h,085h,085h,0c2h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,085h,0c2h,085h,085h,085h,085h,085h,085h,085h	; 842f  ................................
	defb 09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,0a5h,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,0a5h,09fh,09fh,09fh,09fh,09fh,09fh,09fh	; 844f  ................................
	defb 079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h	; 846f  yyyyyyyy.yyyyyyyyyyyyyyy.yyyyyyy
	defb 079h,079h,079h,079h,079h,079h,079h,079h,0b0h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0bah,079h,079h,079h,079h,0b0h,0a7h,0a7h,0a7h,0bah,079h,079h,079h	; 848f  yyyyyyyy............yyyy.....yyy
	defb 079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,0b3h,076h,076h,0beh,079h,079h,079h,088h,07ch,086h,087h	; 84af  yyyyyyyyyyyyyyyyyyy.y.vv.yyy.|..
	defb 079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,0b4h,0bfh,079h,0afh,0a7h,0bbh,079h,0b2h,077h,077h,0bdh,079h,079h,079h,088h,079h,08ch,096h	; 84cf  yyyyyyyyyyyyyy..y...y.ww.yyy.y..
	defb 079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,079h,079h,079h,079h,079h,079h,079h,079h,088h,079h,079h,079h	; 84ef  yyyyyyyyyyyyyyyyyy.yyyyyyyyy.yyy
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,089h,079h,079h,079h,079h,0b0h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a7h,0a8h,0a7h,0a7h,0a7h	; 850f  vvvvvvvvvvvvv.yyyy..............
	defb 076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08bh,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h	; 852f  vvvvvvvvvvvvv.yyyyyyyyyyyyyyyyyy
	defb 0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh	; 854f  ................................
	defb 0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h	; 856f  ................................
	defb 0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h	; 858f  ................................
	defb 079h,079h,079h,09dh,09eh,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,09dh,09eh,079h,079h,079h,079h,079h,079h	; 85af  yyy..yyyyyyyyyyyyyyyyyyy..yyyyyy
	defb 079h,079h,079h,0bch,0b1h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,0bch,0b1h,079h,079h,079h,079h,079h,079h	; 85cf  yyy..yyyyyyyyyyyyyyyyyyy..yyyyyy
	defb 079h,079h,079h,09dh,09eh,079h,079h,079h,0e0h,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0e8h,079h,09dh,09eh,079h,079h,079h,079h,079h,079h	; 85ef  yyy..yyy...............y..yyyyyy
	defb 079h,079h,079h,0bch,0b1h,079h,079h,079h,0dfh,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0e7h,079h,0bch,0b1h,079h,079h,079h,079h,079h,079h	; 860f  yyy..yyy...............y..yyyyyy
	defb 079h,079h,079h,09dh,09eh,079h,079h,079h,0dfh,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0cch,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0e7h,079h,09dh,09eh,079h,0e0h,0cdh,0e8h,079h,079h	; 862f  yyy..yyy...............y..y...yy
	defb 079h,079h,079h,0bch,0b1h,079h,079h,079h,0dfh,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0e7h,079h,0bch,0b1h,079h,0dfh,0c8h,0e7h,079h,079h	; 864f  yyy..yyy...............y..y...yy
	defb 079h,079h,079h,09dh,09eh,079h,079h,079h,0dfh,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0cch,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0e7h,079h,09dh,09eh,079h,0dfh,0c8h,0c1h,0cdh,0cdh	; 866f  yyy..yyy...............y..y.....
	defb 079h,079h,079h,0bch,0b1h,079h,079h,079h,0dfh,0c3h,0ceh,0c5h,0c9h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0e7h,079h,0bch,0b1h,079h,0dfh,0c8h,0c1h,0c7h,0c7h	; 868f  yyy..yyy...............y..y.....
	defb 079h,079h,079h,09dh,09eh,079h,079h,079h,0dfh,0c2h,0c4h,0c6h,0cbh,0c1h,0c1h,0cch,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0e7h,079h,09dh,09eh,079h,0dfh,0c8h,0e7h,079h,079h	; 86af  yyy..yyy...............y..y...yy
	defb 079h,079h,079h,0bch,0b1h,079h,079h,079h,0dfh,0c1h,0c0h,0cah,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0e7h,079h,0bch,0b1h,079h,0dfh,0c8h,0e7h,079h,079h	; 86cf  yyy..yyy...............y..y...yy
	defb 079h,079h,079h,09dh,09eh,079h,079h,079h,0dfh,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0cch,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0e7h,079h,09dh,09eh,079h,0dfh,0c8h,0e7h,079h,079h	; 86ef  yyy..yyy...............y..y...yy
	defb 079h,079h,079h,0bch,0b1h,079h,079h,079h,0dfh,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c3h,0ceh,0c5h,0c9h,0c1h,0c1h,0e7h,079h,0bch,0b1h,079h,0dfh,0c8h,0e7h,079h,079h	; 870f  yyy..yyy...............y..y...yy
	defb 079h,079h,079h,09dh,09eh,079h,079h,079h,0dfh,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0cch,0c2h,0c4h,0c6h,0cbh,0c1h,0c1h,0e7h,079h,09dh,09eh,079h,0dfh,0c8h,0e7h,079h,079h	; 872f  yyy..yyy...............y..y...yy
	defb 079h,079h,079h,0bch,0b1h,079h,079h,079h,0dfh,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c0h,0cah,0c1h,0c1h,0c1h,0e7h,079h,0bch,0b1h,079h,0dfh,0c8h,0e7h,079h,079h	; 874f  yyy..yyy...............y..y...yy
	defb 079h,079h,079h,0bch,0b1h,079h,079h,079h,0dfh,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0e7h,079h,0bch,0b1h,079h,0dfh,0c8h,0c1h,0c7h,0c7h	; 876f  yyy..yyy...............y..y.....
	defb 079h,079h,079h,0bch,0b1h,079h,079h,079h,0deh,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0e6h,079h,0bch,0b1h,079h,0dfh,0c8h,0e7h,079h,079h	; 878f  yyy..yyy...............y..y...yy
	defb 079h,079h,079h,09dh,09eh,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,09dh,09eh,079h,0dfh,0c8h,0e7h,079h,079h	; 87af  yyy..yyyyyyyyyyyyyyyyyyy..y...yy
	defb 079h,079h,079h,0bch,0b1h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,0bch,0b1h,079h,0dfh,0c8h,0e7h,079h,079h	; 87cf  yyy..yyyyyyyyyyyyyyyyyyy..y...yy
	defb 0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0c1h,0c1h,0c1h,0cdh,0cdh	; 87ef  ................................
	defb 0c1h,0c1h,0c1h,0c1h,0c1h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h	; 880f  ................................
	defb 0c1h,0c1h,0c1h,0c1h,0e7h,0c1h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h,0c7h	; 882f  ................................
	defb 0c7h,0c7h,0c7h,0c7h,0e6h,0e7h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h	; 884f  ......yyyyyyyyyyyyyyyyyyyyyyyyyy
	defb 0c7h,0c7h,0c7h,0c7h,0c7h,0e6h,079h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h	; 886f  ......yvvvvvvvvvvvvvvvvvvvvvvvvv
	defb 079h,079h,079h,079h,079h,079h,079h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h	; 888f  yyyyyyyvvvvvvvvvvvvvvvvvvvvvvvvv
	defb 085h,085h,085h,085h,085h,085h,09ch,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,092h,085h,085h,085h,085h,085h,085h,085h,085h,085h	; 88af  .......vvvvvvvvvvvvvvv..........
	defb 09fh,09fh,09fh,09fh,09fh,09fh,099h,09ch,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,092h,08fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh	; 88cf  ........vvvvvvvvvvvvv...........
	defb 079h,079h,07ah,07eh,079h,079h,079h,099h,09ch,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,092h,08fh,09dh,09eh,079h,079h,079h,079h,079h,079h,079h,079h	; 88ef  yyz~yyy..vvvvvvvvvvv....yyyyyyyy
	defb 079h,079h,079h,07dh,079h,079h,079h,079h,099h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08fh,079h,0bch,0b1h,079h,07bh,000h,0d2h,0d1h,0d0h,0d1h,0cfh	; 890f  yyy}yyyy.vvvvvvvvvvv.y..y{......
	defb 079h,079h,079h,079h,079h,079h,079h,079h,094h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,089h,079h,079h,079h,07bh,000h,0d2h,0d1h,0cfh,0d1h,0cfh,0d0h	; 892f  yyyyyyyy.vvvvvvvvvvv.yyy{.......
	defb 085h,085h,085h,085h,09ah,079h,079h,08dh,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08bh,079h,079h,079h,0dah,000h,0d1h,0d0h,08fh,09fh,09fh,09fh	; 894f  .....yy.vvvvvvvvvvvv.yyy........
	defb 09fh,09fh,09fh,09fh,099h,079h,079h,08eh,09ch,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,092h,079h,079h,079h,0d9h,000h,0cfh,08fh,079h,079h,079h,079h	; 896f  .....yy..vvvvvvvvvvv.yyy....yyyy
	defb 079h,079h,079h,079h,0e1h,079h,079h,079h,099h,09ch,076h,076h,076h,076h,076h,076h,076h,076h,076h,092h,08fh,079h,079h,079h,079h,0d8h,08fh,079h,079h,079h,078h,079h	; 898f  yyyy.yyy..vvvvvvvvv..yyyy..yyyxy
	defb 079h,079h,079h,0a2h,0e2h,079h,079h,078h,079h,099h,076h,076h,076h,076h,092h,085h,085h,085h,085h,08fh,079h,079h,079h,079h,079h,0d9h,0d7h,079h,079h,079h,079h,079h	; 89af  yyy..yyxy.vvvv......yyyyy..yyyyy
	defb 079h,079h,0e1h,079h,079h,079h,079h,079h,079h,094h,076h,076h,076h,076h,08fh,09fh,09fh,09fh,09fh,079h,079h,079h,079h,079h,079h,0d9h,0d6h,079h,078h,079h,079h,079h	; 89cf  yy.yyyyyy.vvvv.....yyyyyy..yxyyy
	defb 079h,079h,0e2h,079h,09dh,09eh,093h,076h,076h,076h,076h,076h,076h,076h,089h,079h,0b4h,0bfh,079h,079h,079h,07ch,082h,083h,079h,079h,0d8h,0d6h,079h,079h,079h,079h	; 89ef  yy.y...vvvvvvv.y..yyy|..yy..yyyy
	defb 079h,0e1h,079h,079h,0bch,0b1h,095h,076h,076h,076h,076h,076h,076h,076h,08bh,079h,079h,079h,079h,079h,079h,079h,08eh,098h,079h,079h,079h,0d8h,0d7h,079h,079h,079h	; 8a0f  y.yy...vvvvvvv.yyyyyyy..yyy..yyy
	defb 079h,0e2h,079h,078h,079h,093h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08bh,079h,079h,079h,079h,078h,079h,079h,079h,09dh,09eh,079h,07bh,0d6h,079h,079h,079h	; 8a2f  y.yxy.vvvvvvvvv.yyyyxyyy..y{.yyy
	defb 079h,09ah,079h,079h,079h,095h,076h,076h,076h,076h,076h,076h,076h,076h,076h,092h,079h,079h,079h,079h,079h,079h,079h,079h,0bch,0b1h,07bh,000h,0d2h,079h,079h,079h	; 8a4f  y.yyy.vvvvvvvvv.yyyyyyyy..{..yyy
	defb 09ah,099h,09ah,079h,08dh,076h,076h,076h,076h,076h,076h,076h,076h,076h,092h,08fh,0b3h,076h,076h,0beh,079h,079h,079h,079h,079h,07bh,000h,0d2h,0d1h,097h,079h,079h	; 8a6f  ...y.vvvvvvvvv...vv.yyyyy{....yy
	defb 099h,09ah,099h,09ah,08eh,09ch,076h,076h,076h,076h,076h,076h,076h,076h,08fh,079h,0b2h,077h,077h,0bdh,079h,079h,079h,079h,07bh,000h,0d2h,0d0h,0d0h,08fh,079h,079h	; 8a8f  ......vvvvvvvv.y.ww.yyyy{.....yy
	defb 079h,099h,079h,099h,09ah,099h,085h,085h,09ch,076h,076h,076h,076h,076h,089h,079h,079h,079h,079h,079h,079h,079h,079h,07bh,000h,0d2h,0d1h,0cfh,08fh,079h,079h,079h	; 8aaf  y.y......vvvvv.yyyyyyyy{.....yyy
	defb 079h,0e1h,079h,079h,099h,09ah,09fh,09fh,099h,09ch,076h,076h,076h,076h,08bh,079h,079h,079h,079h,079h,079h,079h,07bh,000h,0d2h,0d0h,0d0h,08fh,079h,079h,079h,079h	; 8acf  y.yy......vvvv.yyyyyyy{.....yyyy
	defb 079h,0e2h,079h,079h,079h,099h,09ah,079h,079h,099h,09ch,076h,076h,076h,076h,089h,079h,079h,09dh,09eh,079h,07bh,000h,0d2h,0d1h,0cfh,08fh,079h,079h,079h,078h,079h	; 8aef  y.yyy..yy..vvvv.yy..y{.....yyyxy
	defb 0e1h,07ch,086h,087h,079h,079h,099h,079h,079h,079h,099h,076h,076h,076h,076h,08bh,079h,079h,0bch,0b1h,07bh,000h,0d2h,0d0h,0d0h,08fh,079h,079h,079h,079h,079h,079h	; 8b0f  .|..yy.yyy.vvvv.yy..{.....yyyyyy
	defb 0e2h,079h,08ch,096h,079h,079h,0e1h,079h,0b4h,0bfh,093h,076h,076h,076h,076h,081h,079h,079h,079h,07bh,000h,0d2h,0d1h,0cfh,08fh,079h,079h,079h,079h,079h,079h,079h	; 8b2f  .y..yy.y...vvvv.yyy{.....yyyyyyy
	defb 079h,079h,079h,079h,079h,079h,0e2h,079h,079h,079h,095h,076h,076h,076h,076h,080h,079h,079h,079h,0dah,000h,0d1h,0d0h,08fh,079h,079h,079h,079h,079h,079h,079h,079h	; 8b4f  yyyyyy.yyy.vvvv.yyy.....yyyyyyyy
	defb 09ah,079h,079h,078h,079h,0e1h,079h,079h,079h,093h,076h,076h,076h,076h,092h,07fh,079h,079h,079h,0d9h,000h,0cfh,08fh,079h,079h,079h,079h,079h,079h,079h,079h,079h	; 8b6f  .yyxy.yyy.vvvv..yyy....yyyyyyyyy
	defb 099h,09ah,079h,079h,079h,0e2h,079h,079h,079h,095h,076h,076h,076h,076h,08fh,079h,09dh,09eh,079h,0d9h,000h,08fh,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h	; 8b8f  ..yyy.yyy.vvvv.y..y...yyyyyyyyyy
	defb 079h,099h,09ah,079h,079h,09ah,079h,079h,08dh,076h,076h,076h,076h,076h,08ah,079h,0bch,0b1h,079h,079h,0d8h,0d7h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h	; 8baf  y..yy.yy.vvvvv.y..yy..yyyyyyyyyy
	defb 079h,079h,099h,09ah,079h,099h,09ah,079h,099h,09ch,076h,076h,076h,076h,076h,089h,079h,079h,079h,079h,0d9h,0d6h,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h	; 8bcf  yy..y..y..vvvvv.yyyy..yyyyyyyyyy
	defb 079h,079h,079h,099h,079h,079h,099h,09ah,079h,099h,09ch,076h,076h,076h,076h,08bh,079h,079h,079h,079h,079h,0d8h,0d7h,079h,079h,079h,079h,079h,079h,079h,079h,079h	; 8bef  yyy.yy..y..vvvv.yyyyy..yyyyyyyyy
	defb 0b4h,0bfh,079h,0e1h,079h,079h,079h,099h,079h,079h,099h,09ch,076h,076h,076h,076h,08ah,079h,079h,079h,079h,0d9h,0d6h,079h,079h,079h,079h,079h,079h,079h,079h,079h	; 8c0f  ..y.yyy.yy..vvvv.yyyy..yyyyyyyyy
	defb 079h,079h,079h,0e2h,0a2h,0a2h,079h,0e1h,079h,079h,079h,099h,076h,076h,076h,076h,076h,089h,079h,079h,079h,079h,0d8h,0d7h,079h,079h,078h,079h,079h,079h,079h,079h	; 8c2f  yyy...y.yyy.vvvvv.yyyy..yyxyyyyy
	defb 079h,079h,0e1h,0e1h,079h,0eah,0a2h,0e2h,079h,079h,079h,094h,076h,076h,076h,076h,076h,08bh,079h,079h,079h,079h,0d9h,0d6h,079h,079h,079h,079h,079h,079h,079h,079h	; 8c4f  yy..y...yyy.vvvvv.yyyy..yyyyyyyy
	defb 079h,079h,0e2h,0e2h,079h,079h,079h,079h,079h,079h,093h,076h,076h,076h,076h,076h,076h,076h,076h,089h,079h,079h,079h,0d8h,0d7h,079h,079h,079h,079h,079h,079h,079h	; 8c6f  yy..yyyyyy.vvvvvvvv.yyy..yyyyyyy
	defb 079h,0e1h,079h,09ah,079h,0b3h,076h,076h,0beh,079h,095h,076h,076h,076h,076h,076h,076h,076h,076h,08bh,079h,079h,09dh,09eh,0eah,0a2h,0a2h,079h,079h,079h,079h,079h	; 8c8f  y.y.y.vv.y.vvvvvvvv.yy.....yyyyy
	defb 079h,0e2h,079h,099h,09ah,0b2h,077h,077h,0bdh,094h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,089h,079h,0bch,0b1h,079h,079h,07bh,000h,0d6h,079h,079h,079h	; 8caf  y.y...ww..vvvvvvvvvv.y..yy{..yyy
	defb 079h,09ah,079h,079h,099h,09ah,079h,079h,093h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08bh,079h,079h,079h,079h,07bh,000h,0d2h,0d1h,097h,079h,079h	; 8ccf  y.yy..yy.vvvvvvvvvvv.yyyy{....yy
	defb 079h,099h,079h,079h,079h,099h,079h,079h,095h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,089h,079h,079h,07bh,000h,0d2h,0d1h,0cfh,08fh,079h,079h	; 8cef  y.yyy.yy.vvvvvvvvvvvv.yy{.....yy
	defb 078h,0e1h,079h,079h,079h,0e1h,079h,08dh,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08bh,079h,079h,0dah,000h,0cfh,0d0h,08fh,079h,079h,079h	; 8d0f  x.yyy.y.vvvvvvvvvvvvv.yy.....yyy
	defb 079h,0e2h,079h,079h,079h,0e2h,079h,08eh,09ch,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,092h,085h,079h,079h,0dah,000h,0d0h,08fh,079h,079h,079h,079h	; 8d2f  y.yyy.y..vvvvvvvvvvv..yy....yyyy
	defb 0e1h,079h,079h,079h,0e1h,079h,079h,079h,099h,09ch,076h,076h,076h,076h,076h,076h,076h,076h,076h,092h,08fh,079h,079h,079h,0d9h,000h,08fh,079h,079h,079h,078h,079h	; 8d4f  .yyy.yyy..vvvvvvvvv..yyy...yyyxy
	defb 0e2h,079h,079h,0a2h,0e2h,079h,079h,078h,079h,099h,076h,076h,076h,076h,092h,085h,085h,085h,085h,08fh,079h,079h,079h,079h,079h,0dah,0d7h,079h,079h,079h,079h,079h	; 8d6f  .yy..yyxy.vvvv......yyyyy..yyyyy
	defb 099h,09ah,079h,079h,079h,0e2h,079h,079h,079h,095h,076h,076h,076h,076h,08fh,079h,09dh,09eh,079h,0d9h,000h,08fh,079h,079h,000h,0dch,0d5h,0e4h,079h,079h,079h,079h	; 8d8f  ..yyy.yyy.vvvv.y..y...yy....yyyy
	defb 079h,099h,09ah,079h,079h,09ah,079h,079h,08dh,076h,076h,076h,076h,076h,08ah,079h,0bch,0b1h,079h,079h,0d8h,0d7h,079h,079h,0d8h,0dbh,0d4h,0e3h,079h,079h,079h,079h	; 8daf  y..yy.yy.vvvvv.y..yy..yy....yyyy
	defb 079h,079h,099h,09ah,079h,099h,09ah,079h,099h,09ch,076h,076h,076h,076h,076h,089h,079h,079h,079h,079h,0d9h,0d6h,079h,079h,079h,0ddh,0d3h,0e5h,079h,079h,079h,079h	; 8dcf  yy..y..y..vvvvv.yyyy..yyy...yyyy
	defb 079h,0e1h,079h,09ah,079h,079h,079h,079h,079h,079h,095h,076h,076h,076h,076h,076h,076h,076h,076h,08bh,079h,079h,09dh,09eh,0eah,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h,0a2h	; 8def  y.y.yyyyyy.vvvvvvvv.yy..........
	defb 0a2h,0e2h,079h,099h,079h,079h,079h,079h,079h,094h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08ah,079h,0bch,0b1h,079h,079h,079h,079h,079h,079h,079h,079h	; 8e0f  ..y.yyyyy.vvvvvvvvvv.y..yyyyyyyy
	defb 079h,079h,078h,0e1h,079h,079h,079h,079h,093h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,08ah,079h,079h,079h,079h,079h,079h,079h,079h,079h,079h	; 8e2f  yyx.yyyy.vvvvvvvvvvvv.yyyyyyyyyy
	defb 0a2h,0a2h,0a2h,0e2h,07ah,07eh,079h,079h,095h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h	; 8e4f  ....z~yy.vvvvvvvvvvvvvvvvvvvvvvv
	defb 079h,079h,079h,079h,079h,07dh,079h,094h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h,076h	; 8e6f  yyyyy}y.vvvvvvvvvvvvvvvvvvvvvvvv

; ----------------------------------------------------------------------
; DATOS sprites_comunes: Los patrones de sprite que no dependen de la fase:
;   las dos naves, los disparos y las campanas. 0x5E1B y 0x5E27 los suben a
;   0x1800 y 0x1A20 con 0x4743, que calcula la mitad derecha invirtiendo la
;   izquierda, y 0x5E2D remata con un bloque suelto
;   0x8e8f..0x9177  (744 bytes)
DATA_sprites_comunes:
	defb 003h,00ch,008h,018h,018h,018h,01ch,01fh,01fh,01eh,00eh,006h,002h,002h,000h,03ch	; 8e8f  ...............<
	defb 000h,000h,001h,003h,003h,001h,0c0h,0e0h,000h,001h,001h,019h,01dh,03dh,03dh,001h	; 8e9f  .............==.
	defb 000h,000h,001h,003h,003h,001h,000h,000h,000h,001h,001h,019h,01dh,03dh,03dh,001h	; 8eaf  .............==.
	defb 001h,001h,001h,011h,011h,013h,01fh,01fh,01fh,01eh,00eh,006h,002h,002h,000h,03ch	; 8ebf  ...............<
	defb 000h,006h,00eh,00eh,00eh,00ch,0c0h,0e0h,000h,001h,001h,019h,01dh,03dh,03dh,001h	; 8ecf  .............==.
	defb 000h,006h,00eh,00eh,00eh,00ch,000h,000h,000h,001h,001h,019h,01dh,03dh,03dh,001h	; 8edf  .............==.
	defb 003h,00ch,00bh,012h,014h,0d4h,0b3h,090h,0f0h,010h,018h,014h,024h,047h,045h,07dh	; 8eef  ............$GE}
	defb 000h,002h,004h,002h,010h,010h,010h,010h,021h,009h,000h,000h,0aah,060h,000h,008h	; 8eff  ........!....`..
	defb 000h,001h,003h,005h,009h,009h,009h,089h,046h,030h,01fh,006h,015h,00dh,005h,000h	; 8f0f  ........F0......
	defb 000h,000h,000h,000h,000h,004h,004h,021h,011h,00ah,001h,016h,008h,000h,000h,000h	; 8f1f  .......!........
	defb 000h,000h,000h,001h,003h,001h,001h,002h,008h,005h,002h,001h,000h,000h,000h,000h	; 8f2f  ................
	defb 001h,002h,003h,007h,00fh,00fh,01fh,01fh,01fh,01fh,03fh,03fh,07fh,061h,03bh,001h	; 8f3f  ..........??.a;.
	defb 01fh,039h,07fh,0f0h,0e7h,0aeh,0aeh,0e8h,0e8h,0aeh,0aeh,0e7h,0f0h,07fh,039h,01fh	; 8f4f  .9............9.
	defb 009h,000h,025h,011h,085h,028h,001h,0bbh,0bbh,001h,024h,089h,011h,025h,000h,009h	; 8f5f  ..%..(....$..%..
	defb 000h,040h,001h,000h,008h,005h,000h,025h,025h,000h,005h,008h,000h,001h,040h,000h	; 8f6f  .@.....%%.....@.
	defb 000h,003h,007h,00fh,01bh,019h,03dh,03fh,07bh,075h,06eh,07fh,03fh,03fh,01fh,007h	; 8f7f  ......=?{un.??..
	defb 003h,007h,00fh,01bh,019h,03dh,03bh,071h,060h,040h,064h,06eh,03fh,03fh,01fh,007h	; 8f8f  .....=;q`@dn??..
	defb 000h,000h,001h,003h,0c3h,0e1h,020h,000h,000h,001h,001h,019h,01dh,03dh,03dh,001h	; 8f9f  ...... ......==.
	defb 000h,000h,080h,0c0h,0c0h,080h,003h,007h,000h,080h,080h,098h,0b8h,0bch,0bch,080h	; 8faf  ................
	defb 007h,01ah,03dh,06ah,077h,0aah,0dch,0aah,0f6h,0abh,0ddh,02ah,077h,02ah,01dh,007h	; 8fbf  ..=jw......*w*..
	defb 083h,08ch,089h,09bh,01bh,019h,0dch,0ffh,01fh,01ch,08dh,085h,015h,099h,03dh,0bdh	; 8fcf  ..............=.
	defb 000h,006h,00eh,00eh,0ceh,0ech,020h,000h,000h,001h,001h,019h,01dh,03dh,03dh,001h	; 8fdf  ...... ......==.
	defb 000h,060h,070h,070h,070h,030h,003h,007h,000h,080h,080h,098h,0b8h,0bch,0bch,080h	; 8fef  .`ppp0..........
	defb 007h,01ah,03dh,06ah,077h,0aah,0dch,0aah,0f6h,0abh,0ddh,02ah,077h,02ah,01dh,007h	; 8fff  ..=jw......*w*..
	defb 081h,087h,089h,091h,011h,011h,0d3h,0ffh,01fh,01ch,08dh,085h,015h,099h,03dh,0bdh	; 900f  ..............=.
	defb 000h,000h,001h,00fh,07fh,07fh,05fh,04fh,027h,01bh,01dh,00ch,002h,001h,000h,000h	; 901f  ......_O'.......
	defb 00eh,079h,0fdh,0ffh,0feh,0feh,0feh,0fch,0fch,0f8h,0f8h,0f0h,070h,060h,0e0h,000h	; 902f  .y..........p`..
	defb 060h,01bh,084h,060h,0f0h,0f0h,060h,01ch,000h,084h,061h,0f3h,0f3h,061h,00ch,000h	; 903f  `..`..`...a..a..
	defb 084h,080h,0c0h,0c0h,080h,00ch,000h,082h,03ch,07eh,003h,0fdh,08bh,0beh,0b6h,07eh	; 904f  ........<~.....~
	defb 07ah,05ch,03ah,02ch,010h,024h,000h,008h,011h,000h,091h,001h,01fh,03dh,07bh,073h	; 905f  z\:,.$.......={s
	defb 0fch,0ffh,0dfh,0dfh,06fh,01fh,007h,002h,000h,000h,003h,0f7h,007h,0ffh,08ch,0feh	; 906f  ....o...........
	defb 0ffh,0dfh,0ceh,0bch,061h,000h,080h,0f0h,0ddh,0bch,0feh,003h,0ffh,087h,08fh,03eh	; 907f  ....a..........>
	defb 07fh,0ffh,0feh,0fch,061h,003h,000h,08dh,0e0h,0f8h,0fch,0fah,0fah,0f5h,0fdh,0f9h	; 908f  ....a...........
	defb 07ah,062h,044h,0b8h,0c0h,003h,000h,08ch,003h,00fh,01eh,03dh,03ch,027h,02fh,01fh	; 909f  zbD........=<'/.
	defb 01fh,00fh,003h,001h,003h,000h,082h,003h,06fh,005h,0ffh,087h,0feh,0ffh,0f7h,0cfh	; 90af  ........o.......
	defb 0eeh,074h,061h,003h,000h,08dh,0f0h,0f3h,0e7h,0feh,0feh,0ffh,07fh,03fh,0ffh,0ffh	; 90bf  .ta..........?..
	defb 0f4h,0cfh,0feh,004h,000h,094h,0c0h,070h,0b8h,0fch,0fch,0f4h,0b4h,08ch,078h,040h	; 90cf  .......p......x@
	defb 080h,000h,000h,01eh,010h,01ch,002h,002h,012h,00ch,00ah,000h,081h,06ch,004h,092h	; 90df  .............l..
	defb 081h,06ch,009h,000h,082h,010h,033h,004h,014h,081h,013h,00ah,000h,081h,06ch,004h	; 90ef  .l....3.......l.
	defb 092h,081h,06ch,009h,000h,087h,078h,041h,072h,04ah,00ah,04ah,031h,00ah,000h,081h	; 90ff  ..l...xArJ.J1...
	defb 0b6h,004h,049h,081h,0b6h,009h,000h,082h,040h,0cdh,004h,052h,081h,04dh,00ah,000h	; 910f  ..I.....@..R.M..
	defb 081h,0b6h,004h,049h,081h,0b6h,00ah,000h,086h,060h,0fch,0ffh,0ffh,07fh,003h,00ch	; 911f  ...I.....`......
	defb 000h,086h,080h,0e0h,0feh,0f9h,009h,006h,010h,000h,083h,003h,007h,00fh,003h,01fh	; 912f  ................
	defb 081h,00eh,003h,000h,08bh,006h,009h,009h,01eh,078h,0f0h,0f0h,0e0h,0c0h,0c0h,080h	; 913f  .........x......
	defb 00bh,000h,082h,018h,038h,004h,018h,081h,07eh,009h,000h,081h,07eh,003h,063h,083h	; 914f  ....8...~...~.c.
	defb 07eh,060h,060h,009h,000h,087h,03eh,063h,003h,00eh,03ch,070h,07fh,009h,000h,081h	; 915f  ~``...>c..<p....
	defb 07eh,003h,063h,083h,07eh,060h,060h,000h	; 916f  ~.c.~``.

; ======================================================================
; CODIGO 0x9177..0x9191  (26 bytes)
; ======================================================================


sube_los_sprites_de_la_fase:
	ld a,(0e076h)		;9177   ; la fase, sin la vuelta
	and 00fh		;917a
	dec a			;917c
	ld hl,09191h		;917d   ; la tabla de sprites de enemigo
	call palabra_de_tabla		;9180
	ld a,(de)			;9183   ; el primer byte dice cuantas parejas trae
	inc de			;9184
	ld b,a			;9185
	ld c,000h		;9186
	ld hl,01d80h		;9188   ; a 0x1D80
	call sube_patrones_de_sprite		;918b
	jp sube_bloque		;918e   ; y detras, un bloque suelto

; ----------------------------------------------------------------------
; DATOS tabla_de_sprites_por_fase: Cinco punteros, uno por fase, que 0x917D
;   usa para subir los enemigos que le tocan
;   0x9191..0x91a6  (21 bytes)
DATA_tabla_de_sprites_por_fase:
	defw 0919bh,09240h,092e7h,093a8h,0946ch,01d04h,0050dh,09f04h	; 9191
	defw 0bff5h,02bbch	; 91a1
	defb 03bh	; 91a5

; ----------------------------------------------------------------------
; DATOS sprites_de_los_enemigos: Los patrones de los enemigos de cada fase.
;   Cada bloque empieza por el numero de parejas que trae y sigue con los
;   datos que se comen 0x4743 y 0x4711
;   0x91a6..0x9648  (1186 bytes)
DATA_sprites_de_los_enemigos:
	defb 019h,01ch,00eh,007h,001h,000h,03ch,01dh,009h,00fh,01fh,033h,0dfh,0dch,05fh,03fh	; 91a6  ......<....3.._?
	defb 013h,01fh,00fh,007h,003h,001h,001h,001h,001h,00fh,01fh,03ch,03fh,033h,03fh,03fh	; 91b6  ...........<?3??
	defb 01ch,01fh,00fh,007h,003h,001h,001h,007h,08fh,09fh,0dfh,0ffh,0ffh,0bfh,09ch,09dh	; 91c6  ................
	defb 00dh,00eh,007h,007h,003h,000h,000h,01eh,002h,000h,09ch,003h,007h,007h,0efh,0ffh	; 91d6  ................
	defb 06fh,00bh,00bh,00dh,007h,001h,003h,001h,000h,000h,0c0h,0e0h,0e0h,0f0h,0f0h,0f7h	; 91e6  o...............
	defb 0ffh,0f6h,0f0h,0f0h,0e0h,000h,080h,003h,000h,08eh,003h,005h,007h,00fh,00fh,0efh	; 91f6  ................
	defb 0efh,06bh,00bh,00dh,007h,001h,01fh,001h,003h,000h,086h,0c0h,0e0h,0e0h,0f7h,0ffh	; 9206  .k..............
	defb 0f6h,003h,0f0h,0a5h,0e0h,000h,0f0h,000h,000h,080h,080h,084h,0c4h,0a6h,0bfh,0e7h	; 9216  ................
	defb 0f6h,0d7h,04fh,07dh,03eh,01fh,007h,000h,000h,001h,001h,021h,023h,065h,0fdh,0f7h	; 9226  ..O}>......!#e..
	defb 07bh,0abh,0b2h,0beh,07ch,0f8h,0e0h,000h,000h,000h,008h,01ch,005h,01dh,03dh,07dh	; 9236  {...|.........=}
	defb 079h,0f5h,0f5h,0f6h,0f7h,0fbh,07ch,07fh,03fh,01fh,007h,000h,000h,000h,001h,003h	; 9246  y.....|.?.......
	defb 00fh,01ch,0dfh,0efh,030h,03fh,03fh,02fh,02fh,017h,00fh,001h,003h,00fh,01ch,01fh	; 9256  ....0??//.......
	defb 00fh,010h,0e0h,0e0h,030h,03fh,03fh,02fh,02fh,017h,00fh,000h,000h,020h,027h,0ffh	; 9266  ....0??//.... '.
	defb 000h,07fh,07fh,05fh,05fh,03fh,02fh,01fh,007h,000h,000h,007h,017h,017h,057h,057h	; 9276  ...__?/.......WW
	defb 0d7h,0d6h,0d5h,0d5h,0d6h,0d7h,057h,057h,017h,017h,007h,001h,0e3h,0e3h,0ffh,0e3h	; 9286  ......WW........
	defb 043h,003h,00fh,01dh,01dh,01dh,01dh,01dh,00dh,00dh,005h,001h,003h,003h,003h,003h	; 9296  C...............
	defb 003h,001h,001h,003h,003h,003h,003h,003h,003h,003h,001h,000h,001h,00ah,0ffh,099h	; 92a6  ................
	defb 099h,0ffh,07fh,07fh,03fh,00fh,004h,007h,000h,000h,000h,080h,01eh,010h,000h,004h	; 92b6  ....?...........
	defb 007h,081h,03fh,007h,02eh,002h,016h,092h,00ah,006h,030h,070h,078h,038h,038h,01ch	; 92c6  ..?.......0px88.
	defb 0fch,05ch,05eh,02eh,02eh,017h,01bh,00dh,007h,001h,00dh,000h,002h,080h,081h,0c0h	; 92d6  .\^.............
	defb 000h,00ah,001h,001h,001h,041h,047h,047h,07fh,07fh,07fh,07fh,07ch,03dh,03dh,01ch	; 92e6  .....AGG....|==.
	defb 00fh,003h,021h,013h,00fh,04eh,033h,05ch,023h,05ch,023h,01ch,0ffh,00bh,005h,003h	; 92f6  ..!..N3\#\#.....
	defb 00ch,000h,001h,003h,016h,02fh,01ch,023h,05ch,023h,05ch,023h,05fh,01bh,025h,043h	; 9306  ...../.#\#\#_.%C
	defb 004h,008h,047h,07fh,0bah,07dh,0ffh,07fh,0ffh,0dfh,0efh,0f7h,0f3h,0d8h,0d8h,06ch	; 9316  ..G..}.........l
	defb 074h,038h,003h,06fh,0ddh,03ah,07fh,0ffh,09fh,0e7h,0fbh,0fch,0c6h,062h,070h,03ch	; 9326  t8.o.:.......bp<
	defb 018h,000h,000h,007h,00ch,00fh,01ch,01fh,01bh,01bh,00eh,00eh,077h,0c0h,08dh,03dh	; 9336  ............w..=
	defb 031h,021h,007h,00ch,00fh,01ch,01fh,01fh,01bh,00eh,00eh,007h,008h,00dh,00dh,005h	; 9346  1!..............
	defb 005h,005h,0e0h,0f0h,038h,03bh,01fh,00fh,01fh,01fh,01fh,01fh,00dh,02dh,037h,071h	; 9356  ....8;.......-7q
	defb 021h,001h,000h,000h,060h,0f3h,0ffh,0ffh,08fh,097h,01fh,01dh,06dh,06fh,035h,001h	; 9366  !...`.......mo5.
	defb 001h,000h,03dh,01dh,00fh,002h,003h,004h,007h,004h,007h,00fh,00fh,00dh,004h,086h	; 9376  ..=.............
	defb 04bh,031h,0c0h,01eh,003h,000h,083h,010h,013h,013h,005h,01fh,002h,00fh,083h,007h	; 9386  K1..............
	defb 003h,001h,003h,0c0h,083h,0c4h,0f4h,0f4h,004h,0fch,086h,03ch,038h,038h,030h,0e0h	; 9396  ...........<880.
	defb 0c0h,000h,007h,0efh,0f0h,0efh,007h,00fh,01fh,03fh,03fh,03fh,03eh,01ch,01ch,00ch	; 93a6  .........???>...
	defb 006h,002h,001h,000h,000h,0dfh,0e0h,0dfh,00fh,01fh,07fh,0ffh,0ffh,0fch,0f8h,078h	; 93b6  ...............x
	defb 01ch,006h,001h,03dh,002h,007h,018h,03fh,03fh,03fh,0ffh,080h,0ffh,03fh,03fh,03fh	; 93c6  ...=...???...???
	defb 03fh,03fh,000h,005h,005h,005h,005h,002h,007h,018h,03fh,03fh,03fh,0ffh,080h,0ffh	; 93d6  ??........???...
	defb 03fh,03fh,000h,000h,001h,003h,00bh,035h,076h,077h,06ch,01bh,03bh,03bh,01dh,02eh	; 93e6  ??.....5vwl.;;..
	defb 033h,018h,000h,018h,024h,024h,032h,012h,00fh,001h,003h,007h,00eh,00eh,01ch,01ch	; 93f6  3...$$2.........
	defb 018h,018h,010h,006h,009h,009h,009h,009h,007h,001h,001h,003h,003h,007h,007h,007h	; 9406  ................
	defb 003h,003h,001h,060h,01eh,081h,07ch,006h,07ah,081h,07ch,004h,07fh,085h,03fh,010h	; 9416  ...`..|.z.|...?.
	defb 00fh,000h,07ch,006h,07ah,004h,0fah,093h,0f6h,0ech,018h,0f0h,000h,000h,080h,080h	; 9426  ..|.z...........
	defb 0c0h,0c0h,0a0h,0a0h,0d0h,06ch,073h,03ch,03fh,01fh,007h,007h,000h,08ch,081h,0c1h	; 9436  .....ls<?.......
	defb 0c2h,0c5h,0dbh,0c6h,0deh,0dch,0d0h,0c0h,0c0h,000h,003h,010h,002h,018h,088h,014h	; 9446  ................
	defb 00ch,00ah,00dh,006h,007h,003h,001h,007h,000h,08bh,008h,088h,088h,098h,0a8h,098h	; 9456  ................
	defb 0b0h,0b0h,0a0h,080h,080h,000h,006h,003h,007h,00fh,00eh,00eh,01eh,03eh,03fh,00fh	; 9466  .............>?.
	defb 00fh,01fh,005h,005h,005h,005h,005h,000h,000h,000h,003h,007h,00fh,00eh,00eh,01eh	; 9476  ................
	defb 03fh,00fh,00fh,01fh,005h,00dh,071h,003h,003h,003h,003h,001h,007h,00fh,0feh,04dh	; 9486  ?.....q........M
	defb 02dh,01eh,00fh,00fh,007h,007h,003h,018h,019h,01fh,019h,001h,007h,00fh,0feh,04dh	; 9496  -..............M
	defb 02dh,01eh,00fh,00fh,007h,007h,003h,006h,01dh,03dh,07dh,0fdh,0feh,085h,07bh,07bh	; 94a6  -........=}...{{
	defb 085h,0feh,0fdh,07dh,03dh,01dh,006h,007h,01fh,007h,05bh,05dh,0edh,0f2h,0fdh,0fdh	; 94b6  ...}=.....[]....
	defb 0f2h,0edh,05dh,05bh,007h,01fh,007h,040h,01eh,0a9h,061h,063h,07fh,063h,027h,00ah	; 94c6  ..][...@..ac.c'.
	defb 00ah,012h,011h,010h,010h,008h,008h,006h,001h,000h,0c3h,0e3h,0ffh,0e3h,0f2h,028h	; 94d6  ...............(
	defb 028h,0a4h,044h,004h,004h,008h,008h,030h,0c0h,000h,061h,063h,07fh,063h,027h,00ah	; 94e6  (.D....0..ac.c'.
	defb 012h,012h,021h,003h,020h,002h,010h,09ah,00ch,003h,0c3h,0e3h,0ffh,0e3h,0f2h,028h	; 94f6  ..!. ..........(
	defb 024h,0a4h,04ah,00ah,002h,00ah,014h,004h,018h,0e0h,010h,014h,014h,097h,09ch,0dfh	; 9506  $.J.............
	defb 07bh,032h,006h,010h,08ah,008h,007h,010h,050h,050h,0d2h,072h,0f6h,0bch,098h,006h	; 9516  {2......PP.r....
	defb 010h,0b0h,020h,0c0h,004h,014h,014h,097h,09ch,0dfh,07bh,032h,014h,012h,015h,015h	; 9526  .. .......{2....
	defb 014h,012h,008h,007h,040h,050h,050h,0d2h,072h,0f6h,0bch,098h,050h,090h,010h,050h	; 9536  ....@PP.r...P..P
	defb 010h,090h,020h,0c0h,000h,000h,007h,01fh,03ch,07bh,0f7h,097h,097h,0f3h,078h,03ch	; 9546  .. .....<{....x<
	defb 01fh,007h,004h,000h,0dch,0e0h,0f8h,03ch,09eh,0cfh,0c9h,0c9h,08fh,01eh,03ch,0f8h	; 9556  .......<......<.
	defb 0e0h,000h,000h,00fh,00fh,00dh,00dh,00ch,00dh,00ch,00dh,00ch,00dh,00ch,00dh,00ch	; 9566  ................
	defb 00ch,00fh,00fh,0f0h,0f0h,030h,030h,0b0h,030h,0b0h,030h,0b0h,030h,0b0h,030h,0b0h	; 9576  .....00.0.0.0.0.
	defb 0b0h,0f0h,0f0h,000h,000h,001h,003h,007h,00eh,01ch,038h,073h,0e2h,0ceh,0c8h,069h	; 9586  ..........8s...i
	defb 033h,01fh,00eh,070h,0f8h,0cch,086h,03bh,023h,0e7h,08eh,09ch,038h,070h,0e0h,0c0h	; 9596  3..p...;#...8p..
	defb 080h,000h,000h,00eh,01fh,033h,061h,0dch,0c4h,0e7h,071h,039h,01ch,00eh,007h,003h	; 95a6  .....3a...q9....
	defb 001h,004h,000h,0adh,080h,0c0h,0e0h,070h,038h,01ch,0ceh,047h,073h,013h,096h,0cch	; 95b6  .......p8..Gs...
	defb 0f8h,070h,000h,001h,03ah,02eh,026h,013h,03eh,07dh,045h,03eh,01bh,033h,027h,03bh	; 95c6  .p..:.&.>}E>.3';
	defb 001h,000h,000h,080h,0dch,0e4h,0c8h,0d8h,07ch,0a2h,0beh,07ch,0c8h,064h,074h,05ch	; 95d6  ........|..|.dt\
	defb 080h,003h,000h,08bh,060h,051h,029h,015h,00fh,01ch,02ch,05eh,05eh,03ch,024h,004h	; 95e6  ....`Q)...,^^<$.
	defb 000h,0ach,003h,005h,08ah,094h,0a8h,0f0h,03ch,05eh,0bfh,0bfh,0ffh,07eh,03ch,03ch	; 95f6  ........<^...~<<
	defb 066h,000h,0c0h,0a0h,051h,029h,015h,00fh,03ch,05eh,0bfh,0bfh,0ffh,07eh,03ch,03ch	; 9606  f...Q)..<^...~<<
	defb 066h,000h,000h,006h,08ah,094h,0a8h,0f0h,038h,02ch,05eh,05eh,03eh,024h,003h,000h	; 9616  f.......8,^^>$..
	defb 0a0h,003h,013h,03bh,07ch,031h,017h,0e7h,0efh,0efh,0e7h,017h,031h,07ch,03bh,013h	; 9626  ...;|1......1|;.
	defb 003h,0c0h,0c8h,0dch,03eh,08ch,0e8h,0e7h,0f7h,0f7h,0e7h,0e8h,08ch,03eh,0dch,0c8h	; 9636  ....>........>..
	defb 0c0h,000h	; 9646

; ======================================================================
; CODIGO 0x9648..0x9671  (41 bytes)
; ======================================================================


L_9648:
	ld de,09671h		;9648   ; los sprites del jefe, iguales en las cinco fases
	ld hl,01d80h		;964b   ; a los patrones de sprite de 0x1D80
	ld bc,00401h		;964e   ; cuatro dibujos
	call sube_patrones_de_sprite		;9651
	ld a,(0e076h)		;9654   ; y los de esta fase
	and 00fh		;9657
	dec a			;9659   ; la tabla arranca en la fase 1
	ld hl,096f1h		;965a   ; los sprites propios de cada jefe
	call palabra_de_tabla		;965d
	ld hl,01e80h		;9660   ; detras de los comunes
	ld bc,00201h		;9663   ; dos dibujos
	call sube_patrones_de_sprite		;9666
	ld hl,01f00h		;9669   ; con un bloque suelto detras
	ld c,000h		;966c
	jp sube_bloque_a_hl		;966e

; ----------------------------------------------------------------------
; DATOS sprites_del_jefe: Los que 0x9648 sube a 0x1D80 en todas las fases
;   0x9671..0x96f1  (128 bytes)
DATA_sprites_del_jefe:
	defb 000h,000h,000h,002h,000h,000h,000h,000h,004h,000h,040h,000h,002h,010h,000h,00bh	; 9671  ..........@.....
	defb 000h,000h,002h,000h,041h,000h,001h,021h,081h,045h,031h,039h,019h,003h,007h,0ffh	; 9681  ....A..!.E19....
	defb 00bh,000h,010h,002h,000h,040h,000h,004h,000h,000h,000h,000h,002h,000h,000h,000h	; 9691  .....@..........
	defb 0ffh,007h,003h,019h,039h,031h,045h,081h,021h,001h,000h,041h,000h,002h,000h,000h	; 96a1  ....91E.!..A....
	defb 000h,000h,004h,000h,000h,004h,002h,001h,000h,008h,044h,000h,003h,030h,007h,0ffh	; 96b1  ..........D..0..
	defb 001h,001h,005h,001h,081h,043h,00bh,00bh,0c3h,0e3h,067h,00fh,017h,03fh,0ffh,0ffh	; 96c1  .....C....g..?..
	defb 0ffh,007h,020h,003h,000h,000h,004h,008h,001h,002h,024h,000h,000h,000h,000h,000h	; 96d1  .. .......$.....
	defb 0ffh,0ffh,03fh,017h,00fh,067h,0e3h,0c3h,00bh,00bh,023h,041h,005h,005h,021h,001h	; 96e1  ..?..g....#A..!.

; ----------------------------------------------------------------------
; DATOS tabla_de_sprites_del_jefe: Cinco punteros, uno por fase, que 0x965A
;   usa para el bloque de 0x1E80
;   0x96f1..0x96fb  (10 bytes)
DATA_tabla_de_sprites_del_jefe:
	defw 096fbh,0975dh,097edh,0986dh,098cfh	; 96f1

; ----------------------------------------------------------------------
; DATOS sprites_del_jefe_por_fase: Y sus datos
;   0x96fb..0x994a  (591 bytes)
DATA_sprites_del_jefe_por_fase:
	defb 0c0h,0c8h,0c8h,0c8h,0cch,0cch,0aeh,0afh,0b7h,0b7h,0b6h,0b4h,0d4h,0d4h,0cfh,080h	; 96fb  ................
	defb 001h,001h,003h,003h,023h,037h,037h,037h,0f7h,0f7h,077h,0f7h,0fbh,038h,0f3h,007h	; 970b  ....#777..w..8..
	defb 00fh,00ch,006h,007h,003h,001h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 971b  ................
	defb 0ffh,0ffh,07fh,037h,09bh,0ech,03fh,00fh,003h,007h,009h,013h,026h,004h,00ch,008h	; 972b  ...7..?.....&...
	defb 086h,000h,003h,00fh,01fh,03fh,03fh,003h,07fh,097h,05fh,03fh,02fh,013h,00ch,003h	; 973b  .....??..._?/...
	defb 000h,000h,0c0h,0f0h,0f8h,0fch,0fch,0feh,0feh,0fah,0fah,0f4h,0c4h,008h,030h,0c0h	; 974b  ..............0.
	defb 000h,000h,000h,020h,010h,018h,00ch,00eh,007h,01bh,03dh,07eh,05fh,05fh,04fh,023h	; 975b  ... ......=~__O#
	defb 01eh,003h,080h,047h,028h,017h,02ch,0b3h,07fh,0b0h,0e7h,0cch,05bh,0b7h,0afh,06bh	; 976b  ...G(.,.....[..k
	defb 0abh,0a9h,007h,005h,006h,006h,006h,006h,006h,006h,002h,002h,000h,000h,000h,000h	; 977b  ................
	defb 000h,000h,0b4h,0d3h,0d8h,0ech,0efh,077h,0f7h,0b8h,0dfh,0cfh,0c7h,0c4h,0c6h,0c2h	; 978b  .......w........
	defb 040h,040h,005h,000h,086h,003h,006h,005h,005h,006h,003h,00ah,000h,086h,0c0h,060h	; 979b  @@.............`
	defb 0a0h,0a0h,060h,0c0h,008h,000h,08ah,001h,007h,009h,009h,01fh,01fh,009h,009h,007h	; 97ab  ..`.............
	defb 001h,006h,000h,08ah,080h,0e0h,090h,090h,0f8h,0f8h,090h,090h,0e0h,080h,003h,000h	; 97bb  ................
	defb 0a0h,003h,00fh,01fh,039h,071h,061h,0e1h,0ffh,0ffh,0e1h,061h,071h,039h,01fh,00fh	; 97cb  ....9qa....aq9..
	defb 003h,0c0h,0f0h,0f8h,09ch,08eh,086h,087h,0ffh,0ffh,087h,086h,08eh,09ch,0f8h,0f0h	; 97db  ................
	defb 0c0h,000h,070h,02eh,011h,00eh,007h,002h,001h,001h,001h,001h,001h,000h,000h,003h	; 97eb  ..p.............
	defb 003h,007h,000h,000h,0dfh,0b9h,071h,0f9h,0edh,0e7h,0e3h,0e1h,0f3h,0f6h,0fch,078h	; 97fb  ......q........x
	defb 0bch,09ch,007h,00fh,00eh,01ch,01ch,039h,032h,065h,059h,0e0h,080h,000h,000h,000h	; 980b  .......92eY.....
	defb 000h,000h,01eh,01eh,03eh,05fh,0afh,06fh,0efh,0e7h,0e7h,0c3h,0c3h,0c3h,0c1h,041h	; 981b  ....>_.o.......A
	defb 041h,040h,08ch,019h,03fh,075h,0edh,0ddh,05fh,013h,030h,070h,078h,067h,023h,004h	; 982b  A@..?u.._.0pxg#.
	defb 000h,08ch,098h,0fch,0aeh,0b7h,0bbh,0fah,0c8h,02ch,0ceh,01eh,0e6h,0c4h,004h,000h	; 983b  .........,......
	defb 0a0h,018h,038h,078h,0b8h,01dh,01fh,00dh,01dh,01dh,01fh,013h,030h,070h,078h,067h	; 984b  ..8x........0pxg
	defb 023h,018h,01ch,01eh,01dh,0b8h,0f8h,0b0h,0b8h,0b8h,0f8h,0c8h,02ch,0ceh,01eh,0e6h	; 985b  #...........,...
	defb 0c4h,000h,000h,003h,00ch,033h,02eh,02dh,02eh,017h,00bh,005h,002h,001h,002h,005h	; 986b  .....3.-........
	defb 009h,01eh,007h,0dah,0dah,0cdh,007h,0f8h,007h,0e6h,0f6h,0f2h,0fah,07ah,0bbh,058h	; 987b  .............z.X
	defb 0aeh,0d5h,001h,000h,01fh,011h,017h,017h,017h,017h,017h,017h,01bh,00dh,007h,003h	; 988b  ................
	defb 001h,000h,06ah,0b5h,06bh,057h,017h,02bh,035h,072h,0f1h,051h,099h,08ch,0c7h,0e2h	; 989b  ..j.kW.+5r.Q....
	defb 0c2h,081h,0a0h,075h,0b7h,0b9h,0b7h,059h,02eh,01dh,06ah,0f5h,00bh,064h,0aah,0adh	; 98ab  ...u...Y..j..d..
	defb 052h,039h,011h,0aeh,0edh,09dh,0edh,09ah,074h,0b8h,056h,02fh,010h,026h,055h,0b5h	; 98bb  R9......t.V/.&U.
	defb 04ah,09ch,088h,000h,000h,000h,007h,00eh,076h,056h,056h,056h,055h,05eh,033h,00dh	; 98cb  J.......vVVVU^3.
	defb 000h,007h,00fh,017h,000h,07fh,0cch,0cch,0cch,0cch,0cch,0bbh,0ddh,0eeh,060h,09bh	; 98db  ..............`.
	defb 075h,06bh,097h,0dfh,017h,009h,007h,030h,078h,058h,078h,05ah,05bh,059h,059h,079h	; 98eb  uk.....0xXxZ[YYy
	defb 078h,078h,078h,030h,0dfh,091h,057h,0ebh,0f5h,0fbh,0f8h,07dh,07bh,0bah,0dbh,0cah	; 98fb  xxx0..W....}{...
	defb 0e2h,033h,00bh,001h,007h,000h,002h,001h,00eh,000h,002h,080h,00ch,000h,086h,001h	; 990b  .3..............
	defb 002h,005h,005h,002h,001h,00ah,000h,086h,080h,040h,0a0h,0a0h,040h,080h,007h,000h	; 991b  .........@..@...
	defb 08ch,001h,009h,01fh,00ch,009h,03bh,03bh,009h,00ch,01fh,009h,001h,004h,000h,08eh	; 992b  ......;;........
	defb 080h,090h,0f8h,030h,090h,0dch,0dch,090h,030h,0f8h,090h,080h,000h,000h,000h	; 993b  ...0....0......

; ======================================================================
; CODIGO 0x994a..0x9994  (74 bytes)
; ======================================================================


sube_los_patrones_del_decorado:
	ld de,099b2h		;994a   ; los patrones de la nave y del decorado comun
	ld hl,021e0h		;994d
	call sube_tal_cual		;9950
	ld de,09be7h		;9953   ; con su tramo espejado
	ld hl,02498h		;9956
	call sube_espejado		;9959
	ld de,09c37h		;995c
	ld hl,024e8h		;995f
	call sube_tal_cual		;9962   ; el resto
	ld de,09c8ch		;9965
	ld hl,025a8h		;9968
	call sube_espejado		;996b   ; y su espejo
sube_los_patrones_de_la_fase:
	ld a,(0e076h)		;996e   ; la fase, sin la vuelta
	and 00fh		;9971   ; sin la decena
	dec a			;9973   ; la tabla arranca en la fase 1
	ld hl,09994h		;9974   ; la tabla de patrones
	call palabra_de_tabla		;9977
	ld hl,02600h		;997a   ; a la casilla 0xC0
	call sube_tal_cual		;997d
	ld a,(0e076h)		;9980   ; otra vez la fase
	and 00fh		;9983
	dec a			;9985
	ld hl,0999eh		;9986   ; y la pareja, que va ESPEJADA
	call palabra_de_tabla_de_cuatro		;9989
	inc hl			;998c   ; el segundo puntero del par: el destino
	ld a,(hl)			;998d   ; el byte bajo
	inc hl			;998e
	ld h,(hl)			;998f   ; y el alto
	ld l,a			;9990
	jp sube_espejado		;9991

; ----------------------------------------------------------------------
; DATOS tabla_de_patrones_por_fase: Cinco punteros: el bloque de casillas que
;   cada fase sube a 0x2600
;   0x9994..0x999e  (10 bytes)
DATA_tabla_de_patrones_por_fase:
	defw 09cdbh,09d45h,09dc3h,09e49h,09e61h	; 9994

; ----------------------------------------------------------------------
; DATOS tabla_de_patrones_espejados: Cinco parejas (guion, destino) que 0x9989
;   lee con entradas de CUATRO bytes. Estas van espejadas: 0x9991 salta a
;   0x4695
;   0x999e..0x99b2  (20 bytes)
DATA_tabla_de_patrones_espejados:
	defw 09d27h,02670h	; 999e
	defw 09dc2h,02680h	; 99a2
	defw 09e40h,02698h	; 99a6
	defw 09e57h,02628h	; 99aa
	defw 09f06h,02718h	; 99ae

; ----------------------------------------------------------------------
; DATOS patrones_del_decorado: Las casillas del escenario, comprimidas. Las de
;   la 0x3C a la 0xBF son iguales en las cinco fases; de la 0xC0 arriba, cada
;   fase sube las suyas
;   0x99b2..0x9f2f  (1405 bytes)
DATA_patrones_del_decorado:
	defb 083h,000h,03fh,060h,005h,040h,089h,000h,0feh,003h,081h,001h,081h,001h,081h,055h	; 99b2  ..?`.@.........U
	defb 005h,040h,08ah,060h,03fh,055h,081h,001h,081h,001h,081h,003h,0feh,003h,000h,005h	; 99c2  .@.`?U..........
	defb 001h,002h,000h,086h,0feh,0c0h,0ffh,000h,091h,0f7h,005h,001h,085h,07fh,03fh,00fh	; 99d2  ..............?.
	defb 0e7h,0ffh,004h,0e7h,002h,0feh,002h,000h,0cfh,0feh,0c0h,0ffh,0ffh,000h,091h,0f7h	; 99e2  ................
	defb 0e7h,0ffh,0c3h,0bdh,018h,0feh,0feh,000h,000h,001h,007h,00fh,01fh,01fh,03fh,000h	; 99f2  ..............?.
	defb 000h,0e0h,0f8h,0fch,0feh,0feh,0ffh,037h,03bh,01eh,007h,001h,039h,07fh,03fh,0fdh	; 9a02  .......7;...9.?.
	defb 0fbh,0deh,0f8h,0e0h,0e0h,0c0h,0c0h,000h,000h,001h,003h,007h,007h,00fh,00fh,000h	; 9a12  ................
	defb 000h,0e0h,0f0h,0f8h,0f8h,0fch,0fch,00bh,00dh,00fh,003h,001h,007h,00fh,007h,0f4h	; 9a22  ................
	defb 0ach,0fch,0f0h,0e0h,0e0h,0c0h,0c0h,000h,004h,001h,09bh,00dh,00eh,007h,0a8h,0a8h	; 9a32  ................
	defb 0aah,0aah,0abh,0abh,0ffh,07fh,007h,003h,003h,001h,03eh,0ffh,0ffh,07fh,0bfh,0dfh	; 9a42  ..........>.....
	defb 0deh,0feh,0feh,0fch,0fch,0f8h,003h,000h,002h,001h,08bh,000h,003h,003h,000h,000h	; 9a52  ................
	defb 0a8h,0aah,0abh,02bh,0c9h,0d7h,003h,003h,08ah,001h,000h,03fh,07fh,03fh,004h,00eh	; 9a62  ...+.......?.?..
	defb 003h,002h,002h,003h,001h,003h,000h,087h,080h,040h,020h,010h,008h,003h,007h,003h	; 9a72  .........@ .....
	defb 00fh,093h,007h,003h,03fh,09ch,0feh,042h,042h,084h,0feh,09ch,0feh,07fh,0feh,0fch	; 9a82  ....?..BB.......
	defb 078h,07bh,077h,02fh,01fh,004h,000h,084h,080h,0e0h,0f0h,0d0h,003h,01fh,002h,00fh	; 9a92  x{w/............
	defb 0aah,007h,001h,07fh,0e8h,0e9h,0fbh,0f7h,0efh,0f7h,0e3h,000h,000h,001h,001h,003h	; 9aa2  ................
	defb 003h,007h,07fh,01fh,000h,080h,080h,0c0h,0c0h,0e0h,0feh,0f8h,007h,007h,00fh,00eh	; 9ab2  ................
	defb 00ch,018h,010h,000h,0e0h,0e0h,0f0h,070h,030h,018h,008h,00ah,000h,087h,03ch,066h	; 9ac2  .......p0.....<f
	defb 03ch,07eh,0ffh,0ffh,07eh,003h,000h,090h,0bfh,0ffh,0ffh,0bfh,000h,000h,03ch,000h	; 9ad2  <~..~.........<.
	defb 081h,0f0h,0ffh,07eh,000h,000h,010h,033h,003h,012h,081h,03bh,003h,000h,081h,0deh	; 9ae2  ...~...3...;....
	defb 003h,052h,089h,0deh,000h,000h,078h,043h,07ah,00ah,00ah,07bh,005h,000h,084h,001h	; 9af2  .R....xCz..{....
	defb 003h,003h,007h,004h,000h,089h,0c0h,0f0h,0d8h,0ech,007h,007h,003h,003h,001h,003h	; 9b02  ................
	defb 000h,085h,0fch,0e8h,09ch,0fch,098h,006h,000h,002h,001h,090h,006h,00fh,00fh,000h	; 9b12  ................
	defb 000h,0c0h,0d8h,0fch,0fch,0feh,0f3h,00fh,00fh,005h,006h,003h,003h,000h,0b8h,0dah	; 9b22  ................
	defb 0e5h,0f1h,0e2h,086h,0fch,030h,000h,001h,003h,027h,06fh,0efh,0ffh,0fbh,0fdh,080h	; 9b32  .....0...'o.....
	defb 0c0h,0e4h,0f6h,0f7h,0ffh,0dfh,0bfh,000h,001h,003h,007h,00fh,00fh,03fh,07fh,000h	; 9b42  .............?..
	defb 080h,0c0h,0e0h,0f0h,0f0h,0fch,0feh,07fh,07fh,03fh,03fh,07fh,07fh,03fh,00fh,0feh	; 9b52  .........??..?..
	defb 0feh,0fch,0fch,0feh,0feh,0fch,0f0h,008h,0ffh,002h,000h,006h,0ffh,088h,027h,007h	; 9b62  ..............'.
	defb 08fh,007h,027h,0dfh,057h,08fh,00ch,0ffh,090h,0d0h,080h,080h,0d0h,0e0h,0e0h,0f0h	; 9b72  ..'.W...........
	defb 0f8h,0fch,0fch,0feh,0ffh,0ffh,0feh,0fch,0f0h,003h,0e0h,095h,0f0h,018h,0e7h,081h	; 9b82  ................
	defb 000h,03ch,024h,024h,03ch,03ch,024h,024h,03ch,03ch,07eh,03ch,001h,07fh,03fh,01fh	; 9b92  .<$$<<$$<<~<..?.
	defb 01fh,003h,00fh,08ah,007h,003h,001h,001h,077h,077h,035h,035h,015h,00fh,003h,007h	; 9ba2  ........ww55....
	defb 096h,003h,001h,001h,000h,032h,047h,067h,077h,037h,017h,007h,000h,07eh,09eh,0c6h	; 9bb2  .....2Ggw7...~..
	defb 0e2h,0ech,0eeh,0ech,003h,0feh,0dfh,004h,0dbh,084h,0c1h,01eh,0ffh,0dfh,004h,0dbh	; 9bc2  ................
	defb 092h,0c1h,01eh,00fh,01eh,03ch,018h,007h,00eh,006h,000h,078h,03ch,01eh,00ch,070h	; 9bd2  .....<.....x<..p
	defb 070h,060h,001h,008h,0e7h,004h,01fh,002h,03fh,08dh,07fh,0ffh,001h,007h,00fh,01fh	; 9be2  p`......?.......
	defb 03fh,07fh,0ffh,0ffh,000h,001h,003h,003h,007h,002h,00fh,089h,0dfh,08fh,0c7h,0e3h	; 9bf2  ?...............
	defb 0f1h,0f8h,0fch,0f8h,0f0h,003h,0f8h,094h,0fch,0feh,0feh,0ffh,0fch,0f8h,0f0h,0f0h	; 9c02  ................
	defb 0e0h,0c0h,080h,000h,07fh,03fh,03fh,01fh,01fh,007h,003h,0efh,003h,0edh,085h,080h	; 9c12  .....??.........
	defb 0c0h,0f0h,0f8h,0feh,003h,0edh,085h,07fh,03fh,00fh,007h,001h,003h,0edh,085h,07fh	; 9c22  ........?.......
	defb 03fh,00fh,007h,001h,000h,090h,0dfh,0ebh,0f1h,0feh,0feh,003h,080h,0e0h,0fbh,0f7h	; 9c32  ?...............
	defb 08fh,07fh,07fh,03fh,01fh,03fh,006h,0ffh,082h,083h,078h,005h,0ffh,088h,0f8h,0c0h	; 9c42  ...?.?....x.....
	defb 000h,000h,080h,0e0h,0f8h,0feh,003h,0ffh,083h,020h,08dh,0f7h,005h,0ffh,095h,0aah	; 9c52  ......... ......
	defb 055h,0ffh,0ffh,0aah,055h,0ffh,0ffh,0bbh,0ddh,0bbh,0ddh,0bbh,0ddh,0bbh,0ddh,018h	; 9c62  U...U...........
	defb 066h,07eh,03ch,03ch,006h,018h,002h,03ch,083h,07eh,066h,018h,003h,0ffh,002h,000h	; 9c72  f~<<...<.~f.....
	defb 006h,0ffh,002h,000h,006h,0e7h,002h,000h,003h,0ffh,003h,0e7h,085h,0f3h,0f9h,0fch	; 9c82  ................
	defb 0feh,0ffh,003h,0e7h,002h,007h,003h,0e7h,085h,09fh,0cfh,0e7h,0f0h,0f8h,009h,0ffh	; 9c92  ................
	defb 08fh,07fh,03fh,09fh,0cfh,0e7h,0f3h,0f9h,0fch,0feh,0ffh,0e7h,0e7h,0e3h,0f0h,0f8h	; 9ca2  ..?.............
	defb 006h,0ffh,0a5h,0f8h,0f0h,0e3h,0e7h,0e7h,0ffh,07fh,09fh,0efh,0f7h,0d7h,0f7h,0fbh	; 9cb2  ................
	defb 0ffh,0f8h,0e0h,0c0h,080h,080h,0c0h,0e0h,0c0h,0c0h,0e0h,0f0h,0e0h,0e0h,0f8h,0ffh	; 9cc2  ................
	defb 040h,0e0h,03fh,07fh,07fh,0c0h,035h,035h,000h,081h,07fh,003h,07bh,08ch,0fbh,0f7h	; 9cd2  @.?...55....{...
	defb 0f7h,0efh,0deh,0deh,0eeh,06eh,07fh,077h,0b7h,0fbh,003h,0ffh,085h,0dfh,08fh,00eh	; 9ce2  .....n.w........
	defb 008h,000h,003h,0ffh,085h,03fh,03dh,018h,008h,000h,005h,0ffh,085h,0f8h,0c0h,000h	; 9cf2  .....?=.........
	defb 0e0h,0f8h,006h,0ffh,0a0h,00fh,02fh,027h,017h,013h,009h,004h,000h,0f0h,0f0h,0e0h	; 9d02  ....../'........
	defb 0e0h,03bh,076h,0f5h,0eeh,0ffh,0dfh,0dfh,0bfh,0b7h,077h,075h,0e5h,077h,077h,07bh	; 9d12  .;v.......wu.ww{
	defb 07bh,07fh,0bfh,0bfh,0bbh,083h,079h,000h,000h,005h,0ffh,084h,0cdh,00bh,007h,000h	; 9d22  {.....y.........
	defb 004h,0ffh,003h,000h,085h,00fh,03fh,07fh,077h,048h,003h,080h,002h,0c0h,083h,0e0h	; 9d32  ......?.wH......
	defb 01fh,01fh,000h,097h,03fh,09fh,01fh,08fh,02fh,02fh,04fh,097h,027h,087h,027h,057h	; 9d42  ....?...//O.'.'W
	defb 087h,027h,057h,087h,067h,087h,0a7h,04fh,08fh,01fh,03fh,003h,0ffh,0a4h,0feh,0fdh	; 9d52  .'W.g..O..?.....
	defb 0f9h,0f6h,0f2h,0edh,0f8h,0f7h,0ceh,095h,0abh,0afh,052h,06dh,0cdh,0d6h,0ddh,0cbh	; 9d62  ..........Rm....
	defb 0cch,09bh,0aeh,0b3h,02bh,05dh,02fh,055h,03fh,06bh,037h,04dh,075h,02dh,03bh,012h	; 9d72  ....+]/U?k7Mu-;.
	defb 00dh,002h,007h,000h,0bbh,080h,0f8h,0ffh,0cbh,0d9h,0cbh,0deh,0f7h,0adh,035h,0eeh	; 9d82  ..............5.
	defb 0ffh,007h,053h,091h,0b7h,05fh,0abh,0d7h,0ffh,05dh,0bfh,057h,0bfh,06bh,0bfh,0d7h	; 9d92  ..S.._...].W.k..
	defb 0bbh,06bh,0d5h,06fh,0bah,055h,000h,000h,0cbh,055h,0e7h,09bh,0f5h,0ffh,07eh,0aeh	; 9da2  .k.o.U...U....~.
	defb 0c0h,070h,018h,038h,0b8h,0f0h,0d0h,000h,003h,00eh,018h,01ch,01dh,00fh,00bh,000h	; 9db2  .p.8............
	defb 000h,002h,001h,086h,003h,002h,006h,00ch,00dh,019h,003h,000h,0b5h,001h,003h,007h	; 9dc2  ................
	defb 00eh,01dh,05ch,05ch,06dh,068h,07ah,066h,06eh,066h,074h,076h,06eh,06eh,0edh,0edh	; 9dd2  ..\\mhzfnftvnn..
	defb 0ddh,09dh,09dh,099h,0bbh,093h,037h,007h,000h,000h,01dh,03dh,03bh,01bh,007h,0c0h	; 9de2  ......7....=;...
	defb 0f8h,0ffh,080h,0c0h,040h,060h,0b0h,098h,0c8h,0cch,0dfh,0dfh,0cfh,0cfh,06fh,065h	; 9df2  ....@`........oe
	defb 04eh,096h,004h,000h,084h,080h,0c0h,0f0h,0b8h,008h,000h,008h,018h,08bh,000h,078h	; 9e02  N..............x
	defb 09ch,016h,013h,049h,04ch,056h,0b6h,0b7h,0b3h,003h,0bbh,092h,099h,0cch,017h,016h	; 9e12  ...ILV..........
	defb 013h,011h,031h,030h,030h,000h,0dch,073h,019h,098h,09ch,0f0h,00fh,01fh,008h,018h	; 9e22  ..100..s........
	defb 081h,05ah,006h,0dbh,081h,018h,003h,0ffh,085h,003h,001h,0fch,0feh,0ffh,003h,0ffh	; 9e32  .Z..............
	defb 085h,0c0h,01fh,030h,01fh,040h,000h,008h,018h,008h,0fch,081h,05ah,006h,0dbh,083h	; 9e42  ...0.@......Z...
	defb 018h,0fah,0f3h,006h,0e7h,088h,03fh,0dfh,0cfh,0f7h,0f3h,0fdh,0fch,0feh,000h,081h	; 9e52  ......?.........
	defb 0feh,007h,0fch,00bh,0ffh,082h,0feh,0fch,007h,0f8h,004h,0ffh,094h,0f0h,0c0h,012h	; 9e62  ................
	defb 016h,01eh,03eh,07eh,0feh,0e1h,0e0h,0e0h,0e8h,0e8h,04ch,044h,007h,0e0h,0e0h,0e9h	; 9e72  ..>~......LD....
	defb 0edh,004h,0efh,082h,000h,0ffh,006h,000h,004h,008h,004h,000h,082h,0f0h,030h,006h	; 9e82  ..............0.
	defb 000h,081h,040h,007h,0e0h,005h,000h,083h,080h,0c0h,0e0h,008h,018h,006h,000h,08fh	; 9e92  ..@.............
	defb 0ffh,000h,0f0h,080h,000h,002h,002h,006h,004h,0e0h,0eeh,0e8h,0e3h,0f7h,0f7h,003h	; 9ea2  ................
	defb 0fbh,08eh,07bh,0f9h,0fdh,0f9h,0fbh,0fbh,0e3h,0cbh,0d3h,0bdh,07dh,07dh,0fbh,0fbh	; 9eb2  ..{.........}}..
	defb 003h,0f7h,084h,077h,00fh,00fh,006h,003h,000h,002h,0ffh,099h,0d3h,0cfh,0d5h,0d9h	; 9ec2  ...w............
	defb 0ffh,000h,000h,07eh,042h,07eh,042h,07eh,042h,07eh,042h,07eh,042h,07eh,000h,07ch	; 9ed2  ...~B~B~B~B~B~.|
	defb 0ffh,0ffh,000h,001h,003h,003h,007h,002h,00fh,004h,01fh,002h,03fh,08ch,07fh,0ffh	; 9ee2  ............?...
	defb 0fch,0f8h,0f0h,0f0h,0e0h,0c0h,080h,000h,0ffh,0ffh,004h,0feh,002h,0fch,003h,0f8h	; 9ef2  ................
	defb 003h,0f0h,002h,0e0h,08fh,03eh,000h,03fh,03fh,021h,03fh,021h,03fh,021h,03fh,021h	; 9f02  .....>.??!?!?!?!
	defb 03fh,021h,03fh,000h,004h,0ffh,005h,07fh,081h,000h,016h,07fh,081h,000h,004h,0f7h	; 9f12  ?!?.............
	defb 002h,0fbh,085h,0fdh,0feh,07fh,07fh,0bfh,003h,0dfh,002h,0efh,000h	; 9f22  .............

; ======================================================================
; CODIGO 0x9f2f..0x9fae  (127 bytes)
; ======================================================================


sube_el_color_del_decorado:
	ld de,0a05ah		;9f2f   ; el color de la nave y del decorado comun
	ld hl,003b0h		;9f32
	call sube_tal_cual		;9f35
	ld de,0a087h		;9f38
	ld hl,00498h		;9f3b
	call sube_tal_cual		;9f3e

; ----------------------------------------------------------------------
; LA FASE 3 NO TIENE COLOR PROPIO. Sube el mismo bloque que las demas, pero con el bit 7 del registro C puesto, que enciende la permuta de nibbles de 0x47B5: el 12 pasa a 6, el 6 a 12 y el 5 a 9. Con eso, la misma hoja de casillas sale con otra paleta y el cartucho se ahorra un juego entero de color.
; ----------------------------------------------------------------------
sube_el_color_comun:
	ld a,(0e076h)		;9f41   ; la fase 3
	and 00fh		;9f44   ; la fase, sin la decena
	cp 003h		;9f46
	jr z,L_9F67		;9f48
	ld de,09fcch		;9f4a   ; las demas suben su color tal cual
	ld hl,001e0h		;9f4d   ; a 0x01E0 de la VRAM
	call sube_tal_cual		;9f50
	ld de,0a096h		;9f53   ; el segundo
	ld hl,004e8h		;9f56
	call sube_tal_cual		;9f59
	ld de,0a0b6h		;9f5c   ; y el tercero
	ld hl,005a8h		;9f5f
	call sube_tal_cual		;9f62
	jr sube_el_color_de_la_fase		;9f65
L_9F67:
	ld de,09fcch		;9f67   ; la fase 3, con la permuta puesta
	ld hl,001e0h		;9f6a
	ld c,080h		;9f6d   ; y la 3 lo sube con el bit 7 de C: la permuta de paleta
	call sube_tres_bancos		;9f6f
	ld de,0a096h		;9f72
	ld hl,004e8h		;9f75
	ld c,081h		;9f78
	call sube_tres_bancos		;9f7a
	ld de,0a0b6h		;9f7d
	ld hl,005a8h		;9f80
	ld c,081h		;9f83
	call sube_tres_bancos		;9f85
sube_el_color_de_la_fase:
	ld a,(0e076h)		;9f88   ; la fase
	and 00fh		;9f8b   ; sin la decena
	dec a			;9f8d   ; la tabla arranca en la fase 1
	ld hl,09faeh		;9f8e   ; la tabla de color
	call palabra_de_tabla		;9f91
	ld hl,00600h		;9f94   ; a la casilla 0xC0
	call sube_tal_cual		;9f97   ; y encima, el suyo
	ld a,(0e076h)		;9f9a   ; otra vez la fase
	and 00fh		;9f9d
	dec a			;9f9f
	ld hl,09fb8h		;9fa0   ; y la pareja, que aqui NO va espejada
	call palabra_de_tabla_de_cuatro		;9fa3
	inc hl			;9fa6   ; se salta el primer puntero
	ld a,(hl)			;9fa7   ; el byte bajo del segundo
	inc hl			;9fa8
	ld h,(hl)			;9fa9   ; y el alto
	ld l,a			;9faa
	jp sube_tal_cual		;9fab

; ----------------------------------------------------------------------
; DATOS tabla_de_color_por_fase: Cinco punteros, la pareja de la de 0x9994
;   para el color
;   0x9fae..0x9fb8  (10 bytes)
DATA_tabla_de_color_por_fase:
	defw 0a0c6h,0a0ddh,0a0ech,0a10fh,0a11ah	; 9fae

; ----------------------------------------------------------------------
; DATOS tabla_de_color_extra: Cinco parejas mas. OJO: estas NO van espejadas
;   -0x9FAB salta a 0x4699, no a 0x4695-, al reves que las de patron
;   0x9fb8..0x9fcc  (20 bytes)
DATA_tabla_de_color_extra:
	defw 0a0d0h,00670h	; 9fb8
	defw 0a0ebh,00680h	; 9fbc
	defw 0a10ah,00698h	; 9fc0
	defw 0a117h,00628h	; 9fc4
	defw 0a13ah,00718h	; 9fc8

; ----------------------------------------------------------------------
; DATOS color_del_decorado: El color de las mismas casillas. La fase 3 no
;   tiene el suyo: 0x9F67 sube el de las demas con el bit 7 de C puesto, que
;   enciende la PERMUTA de 0x47B5 y le cambia la paleta
;   0x9fcc..0xa14b  (383 bytes)
DATA_color_del_decorado:
	defb 020h,0ach,008h,04ch,003h,05ch,082h,0f5h,05ch,003h,041h,004h,04ch,081h,041h,003h	; 9fcc   ..L.\..\.A.L.A.
	defb 01ch,005h,051h,083h,05eh,051h,01ch,003h,05ch,085h,0f5h,05ch,05ch,041h,041h,005h	; 9fdc  ..Q.^Q..\..\\AA.
	defb 051h,083h,0f5h,051h,01ch,003h,07ch,005h,0ach,003h,07ch,009h,0ach,081h,0dch,003h	; 9fec  Q..Q..|...|.....
	defb 01ch,004h,0ach,003h,0dch,081h,01ch,003h,07ch,005h,0ach,003h,07ch,009h,0ach,081h	; 9ffc  ........|...|...
	defb 0dch,003h,01ch,004h,0ach,003h,0dch,081h,01ch,014h,0fch,004h,01ch,007h,0fch,081h	; a00c  ................
	defb 01ch,015h,0fch,013h,01ch,006h,08ch,084h,081h,01ch,08ch,08ch,003h,0f8h,083h,08ch	; a01c  ................
	defb 081h,01ch,016h,0fch,082h,0f1h,01ch,003h,0fch,005h,0f1h,020h,0fch,008h,0cch,007h	; a02c  ........... ....
	defb 0fch,081h,0f4h,008h,01ch,005h,0f4h,002h,0f1h,048h,0fch,081h,0feh,008h,0fch,005h	; a03c  .........H......
	defb 0feh,003h,0fch,006h,01ch,002h,01fh,006h,01ch,002h,01fh,020h,01ch,000h,010h,041h	; a04c  ........... ...A
	defb 005h,0c8h,023h,0c1h,084h,0fch,0c4h,0c4h,044h,008h,0fch,003h,0f1h,081h,0c1h,00bh	; a05c  ..#.....D.......
	defb 0c9h,00dh,094h,00fh,091h,081h,0c1h,007h,091h,081h,0c1h,007h,091h,081h,041h,004h	; a06c  ..............A.
	defb 081h,004h,0f1h,004h,081h,003h,0f1h,081h,0c1h,008h,0c5h,018h,0c4h,008h,0c8h,017h	; a07c  ................
	defb 0c9h,004h,091h,005h,0c9h,00bh,091h,005h,094h,000h,003h,0c1h,002h,0c9h,081h,091h	; a08c  ................
	defb 005h,0c1h,003h,0c9h,009h,0c1h,081h,091h,028h,0c1h,083h,09ch,091h,091h,004h,09ch	; a09c  ........(.......
	defb 002h,091h,004h,09ch,002h,091h,081h,09ch,018h,0c5h,038h,0c5h,00bh,0c1h,00dh,0c4h	; a0ac  ..........8.....
	defb 082h,0fch,0c1h,003h,04ch,083h,0c1h,0fch,0f1h,000h,010h,0fch,010h,0f5h,010h,0c1h	; a0bc  ....L...........
	defb 00ch,0c5h,014h,051h,003h,051h,005h,0c1h,004h,051h,004h,0c1h,00eh,0fch,002h,0c5h	; a0cc  ...Q.Q...Q......
	defb 000h,016h,0c2h,036h,0c1h,004h,0f1h,004h,0c2h,018h,021h,004h,0f1h,010h,0fch,000h	; a0dc  ...6......!.....
	defb 005h,086h,003h,081h,005h,086h,020h,081h,003h,061h,02ch,096h,012h,098h,002h,091h	; a0ec  ...... ..a,.....
	defb 081h,096h,004h,098h,083h,091h,061h,061h,008h,094h,008h,091h,008h,069h,004h,061h	; a0fc  ......aa.....i.a
	defb 004h,091h,000h,008h,094h,008h,0c9h,008h,091h,008h,0c5h,008h,0c1h,000h,022h,0e1h	; a10c  ..............".
	defb 00dh,0f1h,081h,0e1h,004h,0feh,005h,0f1h,036h,0feh,003h,0f1h,081h,0e1h,004h,0f1h	; a11c  ........6.......
	defb 081h,0e1h,020h,091h,081h,0c1h,007h,0f4h,002h,0f1h,00ah,0f4h,02ch,0c1h,002h,041h	; a12c  .. .........,..A
	defb 00dh,0f1h,004h,0c1h,005h,0fch,002h,0f1h,014h,0e1h,081h,0f1h,011h,0c1h,000h	; a13c  ...............

; ======================================================================
; CODIGO 0xa14b..0xa3ab  (608 bytes)
; ======================================================================


mira_los_disparos_contra_la_nube:
	call cuantos_disparos		;a14b   ; cuatro disparos con un jugador, seis con dos
	ld de,0e100h		;a14e
	call recorre_los_disparos		;a151   ; los del primero
	and a			;a154
	ret nz			;a155
	call es_el_segundo_jugador		;a156   ; y si juegan dos
	jr z,L_A176		;a159
	ld de,0e110h		;a15b
	ld b,002h		;a15e
recorre_los_disparos:
	ld a,(de)			;a160   ; hueco vacio, se salta
	and a			;a161
	ld a,008h		;a162
	jr z,L_A172		;a164
	call cabe_en_horizontal		;a166   ; el marco horizontal
	jr nc,L_A170		;a169
	call cabe_en_vertical		;a16b   ; y el vertical
	jr c,rompe_la_nube		;a16e
L_A170:
	ld a,003h		;a170
L_A172:
	add a,e			;a172
	ld e,a			;a173
	djnz recorre_los_disparos		;a174
L_A176:
	xor a			;a176
	ret			;a177
rompe_la_nube:
	ex de,hl			;a178   ; el disparo se gasta
	ld a,l			;a179
	sub 005h		;a17a
	ld l,a			;a17c
	call apaga_cuatro_sprites		;a17d
	ld hl,0e370h		;a180   ; se busca un hueco de campana
	ld a,(hl)			;a183
	and a			;a184
	jr z,L_A191		;a185
	ld hl,0e380h		;a187   ; el segundo hueco
	ld a,(hl)			;a18a
	and a			;a18b
	jr z,L_A191		;a18c
	ld hl,0e390h		;a18e   ; o el tercero
L_A191:
	xor a			;a191
	ld (hl),001h		;a192   ; y nace ahi
	inc l			;a194
	ld (hl),a			;a195
	inc l			;a196
	ld (hl),a			;a197
	inc l			;a198
	ld (hl),0feh		;a199   ; con la clase 0xFE
	inc l			;a19b
	ld (hl),080h		;a19c   ; y velocidad 0x80
	inc l			;a19e
	ld (hl),a			;a19f
	ld a,d			;a1a0
	cp 078h		;a1a1   ; mas abajo de la mitad, cae mas despacio
	jr c,L_A1A6		;a1a3
	dec (hl)			;a1a5   ; con velocidad 0x7F
L_A1A6:
	inc l			;a1a6
	xor a			;a1a7
	ld (hl),a			;a1a8
	inc l			;a1a9
	ld (hl),e			;a1aa   ; la horizontal
	inc l			;a1ab
	ld (hl),a			;a1ac
	inc l			;a1ad
	ld (hl),d			;a1ae   ; y la vertical
	inc l			;a1af
	ld (hl),a			;a1b0
	inc l			;a1b1
	ld (hl),02ch		;a1b2   ; con el primer color
	inc l			;a1b4
	ld (hl),00ah		;a1b5   ; y su dibujo
	ld a,08dh		;a1b7   ; y su ruido
	call pide_un_sonido		;a1b9
	ld a,001h		;a1bc   ; devuelve 1: la nube se rompio
	ret			;a1be
mira_los_disparos_contra_la_campana:
	ld l,(ix+007h)		;a1bf   ; donde esta la campana
	ld h,(ix+009h)		;a1c2
	call cuantos_disparos		;a1c5   ; cuatro con uno, seis con dos
	ld de,0e100h		;a1c8   ; los disparos del primero
	call recorre_los_disparos_2		;a1cb
	call es_el_segundo_jugador		;a1ce
	ret z			;a1d1
	ld de,0e110h		;a1d2   ; y los del segundo
	ld b,002h		;a1d5
recorre_los_disparos_2:
	push bc			;a1d7   ; la cuenta, a salvo
	ld a,(de)			;a1d8   ; hueco vacio, se salta
	and a			;a1d9
	ld a,008h		;a1da   ; tres bytes hasta el siguiente
	jr z,L_A1F1		;a1dc
	call cabe_en_horizontal		;a1de   ; el marco horizontal
	jr nc,L_A1EF		;a1e1
	call cabe_en_vertical		;a1e3   ; y el vertical
	jr nc,L_A1EF		;a1e6
	push hl			;a1e8   ; la campana y el hueco, a salvo
	push de			;a1e9
	call recoge_la_campana		;a1ea   ; y entonces la recoge
	pop de			;a1ed
	pop hl			;a1ee
L_A1EF:
	ld a,003h		;a1ef
L_A1F1:
	add a,e			;a1f1   ; tres bytes hasta el siguiente
	ld e,a			;a1f2
	pop bc			;a1f3
	djnz recorre_los_disparos_2		;a1f4
	ret			;a1f6

; ----------------------------------------------------------------------
; QUE DA CADA CAMPANA. El premio no sale del color que se ve: sale de un contador de 32 pasos, (0xE364), que avanza una posicion cada vez que se recoge una campana y entra en una tabla de 32 casillas que empieza en 0xEB88. Esa tabla NO esta en la ROM: la escribe a mano `empieza_la_partida` con cinco `ld` y cuatro `rlca` (0x5D41 a 0x5D51), o sea que solo cinco de las treinta y dos posiciones traen premio -1 potencia, 2 doble disparo, 4 el brazo, 8 el arma y 0x10 el escudo- y las otras veintisiete solo dan puntos. Verificado en el emulador: en 0xEB88 hay 00 00 00 00 01 00 00 00 02 ... 04 ... 08, exactamente eso.
; ----------------------------------------------------------------------
recoge_la_campana:
	ex de,hl			;a1f7   ; el disparo se gasta
	ld a,l			;a1f8
	sub 005h		;a1f9   ; cinco bytes atras
	ld l,a			;a1fb
	call apaga_cuatro_sprites		;a1fc
	ld a,(ix+001h)		;a1ff   ; y el premio depende del color que llevara
	cp 010h		;a202   ; la campana de 0x10 no da premio
	ld a,087h		;a204
	jp z,pide_un_sonido		;a206
	ld hl,0e364h		;a209   ; el contador de campanas recogidas
	inc (hl)			;a20c   ; uno mas
	ld a,(hl)			;a20d
	cp 020h		;a20e   ; vuelve a cero a las 32
	jr nz,L_A214		;a210
	ld (hl),000h		;a212   ; y vuelve a cero
L_A214:
	ld hl,0eb88h		;a214   ; y la tabla que escribio 0x5D41
	call suma_a_a_hl		;a217   ; la entrada que le toca
	ld c,(hl)			;a21a   ; el premio, en C
	call es_el_segundo_jugador		;a21b   ; con dos jugadores, cada uno tiene lo suyo
	ld iy,0e081h		;a21e   ; la potencia del primero
	ld hl,0e083h		;a222   ; y su estado
	jr z,L_A235		;a225
	ld a,(0e077h)		;a227   ; con dos jugadores
	rra			;a22a   ; el bit 0: vive el primero
	jr nc,L_A232		;a22b
	rra			;a22d   ; y el bit 1: vive el segundo
	jr nc,L_A235		;a22e
	jr L_A263		;a230   ; con los dos, van agarradas
L_A232:
	inc iy		;a232
	inc l			;a234
L_A235:
	bit 0,c		;a235   ; el bit 0: potencia
	jr z,L_A240		;a237
	ld a,(iy+000h)		;a239
	cp 007h		;a23c   ; que no pase de siete
	jr L_A271		;a23e
L_A240:
	bit 1,c		;a240   ; el bit 1: doble disparo
	jr z,L_A249		;a242
	ld a,(hl)			;a244
	and 001h		;a245
	jr L_A25E		;a247
L_A249:
	bit 2,c		;a249   ; el bit 2: el brazo, y solo para el primero
	jr z,L_A257		;a24b
	call es_el_segundo_jugador		;a24d
	jr nz,L_A257		;a250
	ld a,(hl)			;a252
	and 00eh		;a253
	jr L_A25E		;a255
L_A257:
	bit 3,c		;a257   ; el bit 3: el arma
	jr z,L_A292		;a259
	ld a,(hl)			;a25b
	and 006h		;a25c
L_A25E:
	ld a,c			;a25e
	jr z,L_A29C		;a25f
	jr L_A274		;a261
L_A263:
	bit 0,c		;a263   ; agarradas, los dos tienen que poder
	jr z,L_A277		;a265
	ld a,(0e081h)		;a267
	ld b,a			;a26a
	ld a,(0e082h)		;a26b
	and b			;a26e
	cp 007h		;a26f
L_A271:
	ld a,c			;a271
	jr c,L_A29C		;a272
L_A274:
	xor a			;a274
	jr L_A29C		;a275
L_A277:
	ld a,(0e083h)		;a277   ; el estado de las dos naves
	ld b,a			;a27a
	ld a,(0e084h)		;a27b
	and b			;a27e   ; lo que tienen las dos
	ld b,a			;a27f
	bit 1,c		;a280   ; el bit 1: doble disparo
	jr z,L_A289		;a282
	ld a,b			;a284
	and 001h		;a285
	jr L_A25E		;a287
L_A289:
	bit 3,c		;a289   ; y el bit 3: el arma
	jr z,L_A292		;a28b
	ld a,b			;a28d
	and 004h		;a28e
	jr L_A25E		;a290
L_A292:
	xor a			;a292   ; el bit 4: el escudo
	bit 4,c		;a293
	jr z,L_A29C		;a295
	ld (ix+000h),002h		;a297
	ld a,c			;a29b
L_A29C:
	ld (ix+001h),a		;a29c   ; el premio, apuntado
	and a			;a29f   ; el premio 0 es el primero
	ld c,00ah		;a2a0   ; y cada uno tiene su color de aviso
	jr z,L_A2BA		;a2a2
	rra			;a2a4   ; el bit 0
	ld c,007h		;a2a5   ; blanco
	jr c,L_A2BA		;a2a7
	rra			;a2a9   ; el bit 1
	ld c,00fh		;a2aa   ; gris
	jr c,L_A2BA		;a2ac
	rra			;a2ae   ; el bit 2
	ld c,003h		;a2af   ; verde
	jr c,L_A2BA		;a2b1
	rra			;a2b3   ; el bit 3
	ld c,008h		;a2b4   ; rojo
	jr c,L_A2BA		;a2b6
	ld c,001h		;a2b8   ; y azul para el resto
L_A2BA:
	ld (ix+00ch),c		;a2ba   ; el dibujo del cartel
	ld c,000h		;a2bd   ; sin fraccion
	ld (ix+002h),c		;a2bf
	ld (ix+003h),0feh		;a2c2   ; dos pixeles por cuadro hacia arriba
	ld a,(ix+009h)		;a2c6   ; la vertical donde nace
	cp 078h		;a2c9   ; mas abajo de la mitad, sube en vez de bajar
	jr c,L_A2CE		;a2cb
	dec c			;a2cd   ; hacia abajo
L_A2CE:
	ld (ix+004h),080h		;a2ce
	ld (ix+005h),c		;a2d2
	ld a,08dh		;a2d5   ; y suena
	jp pide_un_sonido		;a2d7
mira_las_campanas_contra_la_nave:
	ld a,(0e077h)		;a2da   ; el primer jugador
	rra			;a2dd   ; el bit 0: le queda partida
	jr nc,L_A2EE		;a2de
	call el_uno_tiene_bomba		;a2e0   ; vivo y sin morirse
	jr nz,L_A2EE		;a2e3
	call donde_esta_la_nave_uno		;a2e5   ; donde esta su nave
	ld bc,00301h		;a2e8   ; tres campanas, y el jugador 1
	call recorre_las_campanas		;a2eb
L_A2EE:
	call es_el_segundo_jugador		;a2ee   ; con dos jugadores
	ret z			;a2f1
	ld a,(0e077h)		;a2f2
	rra			;a2f5   ; el bit 1: le queda partida al segundo
	rra			;a2f6
	ret nc			;a2f7
	call el_dos_tiene_bomba		;a2f8   ; el segundo, vivo
	ret nz			;a2fb
	call donde_esta_la_nave_dos		;a2fc   ; donde esta su nave
	ld bc,00302h		;a2ff   ; tres campanas, y el jugador 2
recorre_las_campanas:
	ld de,0e370h		;a302   ; la primera campana
L_A305:
	push bc			;a305   ; la cuenta, a salvo
	ld a,(de)			;a306   ; campana apagada, nada
	and a			;a307
	ld a,010h		;a308   ; 0x10 hasta la siguiente
	jr z,L_A337		;a30a
	ld a,(de)			;a30c
	cp 003h		;a30d   ; o apagandose
	ld a,010h		;a30f
	jr z,L_A337		;a311
	ld a,(de)			;a313
	ld b,a			;a314   ; la clase, en B
	ld a,007h		;a315   ; siete adelante: la posicion
	add a,e			;a317
	ld e,a			;a318
	ld a,(de)			;a319
	inc e			;a31a
	inc e			;a31b
	add a,00fh		;a31c   ; el marco: 0x1F pixeles
	sub l			;a31e   ; menos la de la nave
	cp 01fh		;a31f
	jr nc,L_A335		;a321
	ld a,(de)			;a323   ; y la vertical
	add a,00fh		;a324
	sub h			;a326
	cp 01fh		;a327
	jr nc,L_A335		;a329
	djnz L_A332		;a32b   ; con B a uno, la recoge
	call recoge_una_campana		;a32d   ; la primera nave la recoge
	jr L_A339		;a330
L_A332:
	call choca_con_la_campana		;a332   ; y la segunda tambien
L_A335:
	ld a,007h		;a335   ; siete hasta la siguiente
L_A337:
	add a,e			;a337
	ld e,a			;a338
L_A339:
	pop bc			;a339
	djnz L_A305		;a33a
	ret			;a33c
recoge_una_campana:
	push hl			;a33d   ; la campana recogida
	ld a,e			;a33e   ; ocho bytes atras: el premio
	sub 008h		;a33f
	ld e,a			;a341
	push de			;a342   ; el hueco, a salvo
	ld a,(de)			;a343
	rra			;a344   ; el bit 0: la de velocidad
	jr c,$+110		;a345
	rra			;a347   ; el bit 1: doble disparo
	jp c,campana_de_doble_disparo		;a348
	rra			;a34b   ; el bit 2: el brazo
	jp c,campana_del_brazo		;a34c
	rra			;a34f   ; el bit 3: el arma
	jp c,campana_del_arma		;a350
	ld a,c			;a353
	dec a			;a354   ; a que jugador
	ld hl,0e362h		;a355   ; y si no, es la de puntos
	jr z,L_A35B		;a358
	inc l			;a35a
L_A35B:
	inc (hl)			;a35b   ; el nivel de puntos, uno mas
	ld a,(hl)			;a35c
	cp 004h		;a35d   ; con tope en tres
	jr c,L_A363		;a35f
	ld (hl),003h		;a361
L_A363:
	ld hl,0a3abh		;a363   ; los puntos que da cada nivel
	dec a			;a366   ; la entrada de la tabla
	ld b,a			;a367
	call indexa_palabras		;a368
	dec c			;a36b   ; a que jugador
	push bc			;a36c
	ld c,(hl)			;a36d   ; los puntos que da
	inc hl			;a36e
	ld b,(hl)			;a36f
	jr nz,L_A377		;a370
	call suma_al_primero		;a372   ; al primer jugador
	jr L_A37A		;a375
L_A377:
	call suma_al_segundo		;a377   ; o al segundo
L_A37A:
	pop bc			;a37a   ; el hueco de la campana
	ld a,08eh		;a37b   ; con su ruido
	call pide_un_sonido_si_se_juega		;a37d
	pop hl			;a380   ; la posicion, de vuelta
	pop de			;a381
	dec l			;a382   ; la campana pasa a "apagandose"
	ld (hl),003h		;a383   ; y la campana se apaga
	ld a,006h		;a385   ; seis bytes mas alla: el cartel
	add a,l			;a387
	ld l,a			;a388
	xor a			;a389
	ld (0e364h),a		;a38a   ; el contador de campanas, a cero
	ld (hl),a			;a38d   ; sin fraccion
	inc l			;a38e
	ld a,e			;a38f   ; ocho pixeles a la izquierda
	sub 008h		;a390   ; centrado sobre la campana
	ld (hl),a			;a392
	inc l			;a393
	ld (hl),000h		;a394   ; sin fraccion tampoco
	inc l			;a396
	ld (hl),d			;a397   ; y a la misma altura
	inc l			;a398
	ld (hl),010h		;a399   ; con dieciseis cuadros de cartel
	inc l			;a39b
	ld a,b			;a39c   ; el premio, por cuatro
	add a,a			;a39d
	add a,a			;a39e
	add a,088h		;a39f   ; mas 0x88: el dibujo que le toca
	ld (hl),a			;a3a1
	inc l			;a3a2
	ld (hl),00fh		;a3a3   ; en blanco
	ld a,004h		;a3a5
	add a,l			;a3a7
	ld l,a			;a3a8
	ex de,hl			;a3a9
	ret			;a3aa

; ----------------------------------------------------------------------
; DATOS velocidades_del_enemigo: Cuatro palabras que 0xA363 indexa con
;   (0xE362), el nivel de la oleada
;   0xa3ab..0xa3b3  (8 bytes)
DATA_velocidades_del_enemigo:
	defw 00005h,00010h,00050h,00100h	; a3ab

; ======================================================================
; CODIGO 0xa3b3..0xa442  (143 bytes)
; ======================================================================


campana_de_velocidad:
	dec c			;a3b3   ; el jugador que la cogio
	ld hl,0e081h		;a3b4
	jr z,L_A3BA		;a3b7
	inc l			;a3b9
L_A3BA:
	ld a,(hl)			;a3ba
	cp 007h		;a3bb   ; con siete ya no sube mas
	jr nc,remata_la_campana		;a3bd
	inc (hl)			;a3bf   ; una mas
	ld hl,0e083h		;a3c0
	ld a,(hl)			;a3c3
	and 06fh		;a3c4   ; y se apagan las armas de los dos
	ld (hl),a			;a3c6
	inc l			;a3c7
	ld a,(hl)			;a3c8
	and 06fh		;a3c9
	ld (hl),a			;a3cb
	jr remata_la_campana		;a3cc
campana_de_doble_disparo:
	dec c			;a3ce   ; el doble disparo
	ld hl,0e083h		;a3cf
	jr z,L_A3D5		;a3d2
	inc l			;a3d4
L_A3D5:
	res 3,(hl)		;a3d5   ; quita el arma
	set 0,(hl)		;a3d7   ; y pone el disparo doble
	jr remata_la_campana		;a3d9
campana_del_brazo:
	ld hl,0e083h		;a3db   ; con el brazo o el arma puestos, no
	bit 1,(hl)		;a3de
	jr nz,remata_la_campana		;a3e0
	bit 2,(hl)		;a3e2
	jr nz,remata_la_campana		;a3e4
	set 1,(hl)		;a3e6   ; y si no, el brazo
	jr remata_la_campana		;a3e8
campana_del_arma:
	dec c			;a3ea   ; el arma
	ld de,0e095h		;a3eb
	ld hl,0e083h		;a3ee
	jr z,L_A3F5		;a3f1
	inc e			;a3f3
	inc l			;a3f4
L_A3F5:
	set 2,(hl)		;a3f5   ; con su marca
	ld a,(0f0ffh)		;a3f7   ; el truco de armas
	and 004h		;a3fa
	ld a,010h		;a3fc   ; dieciseis usos
	jr z,L_A401		;a3fe
	rlca			;a400   ; o treinta y dos con el truco
L_A401:
	ld (de),a			;a401
	ld a,001h		;a402
	ld (0e151h),a		;a404
remata_la_campana:
	call cambia_la_musica		;a407   ; se cambia la musica
	pop hl			;a40a
	dec l			;a40b
	call apaga_y_borra		;a40c   ; y la campana se apaga
	push hl			;a40f
	ld hl,0e360h		;a410
	dec (hl)			;a413   ; una nube menos
	pop hl			;a414
	ex de,hl			;a415
	pop hl			;a416
	ret			;a417

; ----------------------------------------------------------------------
; EL ESCUDO AGUANTA EL GOLPE. Si la nave lleva el arma -bit 2 del estado-, un choque no la mata: se le descuentan dos usos del contador de 0xE095, y solo cuando se acaban se apaga la marca. Sin arma, el choque va directo a 0xA95D, que es la muerte.
; ----------------------------------------------------------------------
choca_con_la_campana:
	push hl			;a418   ; el jugador que choco
	ld a,c			;a419
	dec a			;a41a
	ld hl,0e083h		;a41b
	jr z,L_A421		;a41e
	inc l			;a420
L_A421:
	bit 2,(hl)		;a421   ; el bit 2: lleva arma
	jr z,L_A43B		;a423
	push de			;a425
	ex de,hl			;a426
	ld a,c			;a427
	dec a			;a428
	ld hl,0e095h		;a429
	jr z,L_A42F		;a42c
	inc l			;a42e
L_A42F:
	dec (hl)			;a42f   ; dos usos menos
	jr z,L_A435		;a430
	dec (hl)			;a432
	jr nz,L_A43F		;a433
L_A435:
	ld a,(de)			;a435
	and 0fbh		;a436   ; y al acabarse, se apaga
	ld (de),a			;a438
	jr L_A43F		;a439
L_A43B:
	push de			;a43b
	call se_muere_la_nave		;a43c   ; sin arma, la nave se estrella
L_A43F:
	pop de			;a43f
	pop hl			;a440
	ret			;a441

; ----------------------------------------------------------------------
; DATOS marco_del_enemigo: Seis parejas (minimo, maximo) que 0xA456 indexa:
;   hasta donde puede moverse cada clase
;   0xa442..0xa44e  (12 bytes)
DATA_marco_del_enemigo:
	defb 003h	; a442
	defb 013h	; a443
	defb 003h	; a444
	defb 013h	; a445
	defb 003h	; a446
	defb 013h	; a447
	defb 009h	; a448
	defb 019h	; a449
	defb 007h	; a44a
	defb 017h	; a44b
	defb 007h	; a44c
	defb 017h	; a44d

; ======================================================================
; CODIGO 0xa44e..0xa78e  (832 bytes)
; ======================================================================


cabe_en_horizontal:
	inc e			;a44e   ; el marco de choque de esa clase de enemigo
	ld a,(de)			;a44f   ; la clase del enemigo
	inc e			;a450   ; tres bytes adelante: la posicion
	inc e			;a451
	inc e			;a452
	dec a			;a453   ; por dos: la entrada de la tabla
	add a,a			;a454
	push hl			;a455
	ld hl,0a442h		;a456
	call indexa_palabras		;a459   ; la entrada de la tabla de marcos
	push hl			;a45c
	pop iy		;a45d   ; en IY, que es donde se lee comodo
	pop hl			;a45f
	ld a,(de)			;a460   ; la horizontal del disparo
cabe_en_el_marco:		; La posicion mas el minimo del marco, comparada con el maximo
	inc e			;a461   ; la posicion, mas el minimo
	add a,(iy+000h)		;a462
	sub l			;a465   ; menos la del blanco
	cp (iy+001h)		;a466   ; contra el maximo
	ret			;a469
cabe_en_vertical:
	ld a,(de)			;a46a   ; y ahora la vertical
	add a,(iy+002h)		;a46b
	sub h			;a46e   ; menos la del blanco
	cp (iy+003h)		;a46f   ; contra su maximo
	ret			;a472
mira_el_arma_contra_los_grandes:
	ld de,0e13ch		;a473   ; el arma del primer jugador
	ld hl,0e0a1h		;a476   ; y donde esta su nave
	call recorre_los_grandes		;a479
	call es_el_segundo_jugador		;a47c   ; y si juegan dos
	ret z			;a47f
	ld de,0e146h		;a480   ; el arma del segundo
	ld hl,0e0adh		;a483
recorre_los_grandes:
	ld a,(de)			;a486   ; sin arma en el aire, nada
	and a			;a487
	ret z			;a488
	inc e			;a489   ; la clase del arma
	ld a,(de)			;a48a
	cp 00fh		;a48b   ; solo cuenta cuando esta abajo del todo
	ret nz			;a48d
	ld a,(hl)			;a48e   ; la vertical de la nave
	inc l			;a48f
	inc l			;a490
	ld h,(hl)			;a491   ; y la horizontal
	sub 030h		;a492   ; 0x30 pixeles mas arriba
	ld l,a			;a494   ; ese es el punto que se compara
	ld de,0e3b0h		;a495   ; los cinco huecos de enemigo grande
	ld b,005h		;a498   ; los cinco enemigos grandes
L_A49A:
	ld a,(de)			;a49a
	and a			;a49b   ; hueco vacio, se salta
	ld a,010h		;a49c   ; 0x10 bytes hasta el siguiente
	jr z,L_A4BF		;a49e
	inc e			;a4a0   ; su clase
	ld a,(de)			;a4a1
	cp 005h		;a4a2   ; y las clases 5 arriba no valen
	ld a,00fh		;a4a4
	jr nc,L_A4BF		;a4a6
	ld a,004h		;a4a8   ; cuatro bytes adelante: la posicion
	add a,e			;a4aa
	ld e,a			;a4ab
	ld a,(de)			;a4ac
	inc e			;a4ad
	add a,00fh		;a4ae   ; el marco horizontal: 0x17
	sub l			;a4b0
	cp 017h		;a4b1
	jr nc,L_A4BD		;a4b3   ; fuera del marco, el siguiente
	ld a,(de)			;a4b5   ; y el vertical: 0x1F
	add a,00fh		;a4b6
	sub h			;a4b8
	cp 01fh		;a4b9
	jr c,rompe_el_grande		;a4bb
L_A4BD:
	ld a,00ah		;a4bd   ; 0x0A bytes hasta el siguiente
L_A4BF:
	add a,e			;a4bf
	ld e,a			;a4c0
	djnz L_A49A		;a4c1
	ret			;a4c3
rompe_el_grande:
	ex de,hl			;a4c4   ; el hueco del grande
	ld a,l			;a4c5
	sub 005h		;a4c6   ; cinco bytes atras
	ld l,a			;a4c8
	ld (hl),005h		;a4c9   ; el grande, reventado
	inc l			;a4cb   ; tres adelante
	inc l			;a4cc
	inc l			;a4cd
	ld (hl),001h		;a4ce   ; con el paso a uno
	inc l			;a4d0
	inc l			;a4d1
	inc l			;a4d2
	ld (hl),010h		;a4d3   ; con su cuenta
	inc l			;a4d5
	xor a			;a4d6   ; y las dos velocidades a cero
	ld (hl),a			;a4d7
	inc l			;a4d8
	ld (hl),a			;a4d9
	ret			;a4da
mira_las_naves_contra_los_grandes:
	ld a,(0e077h)		;a4db   ; el primer jugador
	rra			;a4de   ; el bit 0: le queda partida
	jr nc,L_A4EE		;a4df
	call el_uno_tiene_bomba		;a4e1   ; y no puede estar muriendose
	jr nz,L_A4EE		;a4e4
	call donde_esta_la_nave_uno		;a4e6
	ld c,001h		;a4e9   ; con la marca del primer jugador
	call recorre_los_grandes_2		;a4eb
L_A4EE:
	call es_el_segundo_jugador		;a4ee   ; y si juegan dos
	ret z			;a4f1
	ld a,(0e077h)		;a4f2
	rra			;a4f5   ; el bit 1: le queda partida al segundo
	rra			;a4f6
	ret nc			;a4f7
	call el_dos_tiene_bomba		;a4f8
	ret nz			;a4fb
	call donde_esta_la_nave_dos		;a4fc
	ld c,002h		;a4ff
recorre_los_grandes_2:
	ld de,0e3b0h		;a501
	ld b,005h		;a504   ; los cinco huecos de enemigo
L_A506:
	push bc			;a506   ; la cuenta, a salvo
	ld a,(de)			;a507   ; hueco vacio, se salta
	and a			;a508
	ld a,010h		;a509   ; dieciseis bytes por enemigo
	jr z,L_A53D		;a50b
	inc e			;a50d   ; el segundo byte es la clase
	ld a,(de)			;a50e
	cp 006h		;a50f   ; las clases 6 a 9 son las que chocan
	ld a,00fh		;a511   ; quince: ya se avanzo uno
	jr c,L_A53D		;a513
	ld a,(de)			;a515
	cp 00ah		;a516
	ld a,00fh		;a518
	jr nc,L_A53D		;a51a
	ld a,(de)			;a51c   ; la clase, a salvo
	ld b,a			;a51d   ; la clase, a B
	ld a,004h		;a51e   ; cuatro bytes mas alla: la posicion
	add a,e			;a520
	ld e,a			;a521
	ld a,(de)			;a522   ; la horizontal
	inc e			;a523   ; y luego la vertical
	add a,00fh		;a524   ; el marco: 0x1F en las dos
	sub l			;a526   ; contra la del disparo
	cp 01fh		;a527   ; fuera del marco, no le da
	jr nc,L_A53B		;a529
	ld a,(de)			;a52b
	add a,00fh		;a52c   ; el mismo marco en vertical
	sub h			;a52e
	cp 01fh		;a52f
	jr nc,L_A53B		;a531
	ld a,b			;a533   ; con la clase en A
	push hl			;a534
	push de			;a535
	call reparte_el_choque		;a536   ; y se reparte el choque
	pop de			;a539
	pop hl			;a53a
L_A53B:
	ld a,00ah		;a53b   ; diez bytes hasta el siguiente
L_A53D:
	add a,e			;a53d   ; se avanza al hueco que toque
	ld e,a			;a53e
	pop bc			;a53f
	djnz L_A506		;a540
	ret			;a542
reparte_el_choque:
	sub 007h		;a543   ; la clase 7 es el arma
	jr z,recoge_el_arma_del_suelo		;a545
	dec a			;a547   ; la 8, el jefe
	jr z,revienta_al_jefe		;a548
	dec a			;a54a   ; y la 9, la vida extra
	jr z,recoge_una_vida		;a54b
	ex de,hl			;a54d   ; el hueco del grande
	ld a,l			;a54e
	sub 005h		;a54f   ; cinco bytes atras: su clase
	ld l,a			;a551
	ld e,c			;a552   ; quien le dio
	ld a,(0e003h)		;a553   ; y las demas revientan, alternando dibujo
	and 003h		;a556   ; dos bits del contador de cuadros
	ld (hl),00bh		;a558   ; con el primer dibujo de explosion
	ld bc,00005h		;a55a   ; y 5 puntos
	jr z,L_A563		;a55d
	ld (hl),00ah		;a55f   ; o el segundo
	ld c,001h		;a561   ; y 1 punto
L_A563:
	ld a,006h		;a563
	add a,l			;a565
	ld l,a			;a566
	ld (hl),020h		;a567   ; con 0x20 cuadros de explosion
	dec e			;a569   ; y dan puntos al que le dio
	jr nz,L_A571		;a56a
	call suma_al_primero		;a56c   ; al primero
	jr L_A574		;a56f
L_A571:
	call suma_al_segundo		;a571   ; o al segundo
L_A574:
	ld a,08ah		;a574   ; con su ruido
	jp pide_un_sonido_si_se_juega		;a576
recoge_el_arma_del_suelo:
	ex de,hl			;a579
	ld a,l			;a57a   ; seis bytes atras
	sub 006h		;a57b
	ld l,a			;a57d
	call borra_dieciseis		;a57e   ; el enemigo se borra
	ld hl,0e083h		;a581
	ld a,(hl)			;a584   ; el estado de la nave
	and 00ah		;a585   ; con doble disparo o brazo, no
	jr nz,L_A592		;a587
	res 0,(hl)		;a589   ; y si no, se pone el arma
	ld a,008h		;a58b   ; y el bit 3: el arma
	or (hl)			;a58d
	ld (hl),a			;a58e
	call cambia_la_musica		;a58f   ; la musica cambia
L_A592:
	ret			;a592
revienta_al_jefe:
	ex de,hl			;a593
	ld a,l			;a594
	sub 006h		;a595   ; seis bytes atras
	ld l,a			;a597
	call borra_dieciseis		;a598   ; el jefe se borra
	call apaga_todos_los_enemigos		;a59b   ; y con el se van todos sus enemigos
	ld a,092h		;a59e   ; con su ruido
	jp pide_un_sonido_si_se_juega		;a5a0
recoge_una_vida:
	ex de,hl			;a5a3
	ld a,l			;a5a4
	sub 006h		;a5a5   ; seis bytes atras
	ld l,a			;a5a7
	call borra_dieciseis		;a5a8   ; y la vida extra
	dec c			;a5ab   ; a que jugador
	ld hl,0e070h		;a5ac
	jr z,L_A5B2		;a5af
	inc l			;a5b1
L_A5B2:
	ld a,(hl)			;a5b2
	cp 099h		;a5b3   ; con 99 no caben mas
	jr z,L_A5BB		;a5b5
	add a,001h		;a5b7   ; una vida mas, en BCD
	daa			;a5b9
	ld (hl),a			;a5ba
L_A5BB:
	call musica_de_vida_extra		;a5bb   ; con su musica
	ret			;a5be

; ----------------------------------------------------------------------
; LA BOMBA SE PUEDE RECOGER. Si la nave pasa por encima de su propia bomba antes de que llegue al suelo, se la vuelve a guardar: (0xE08D) queda a uno y ya puede volver a tirarla. Es lo que permite encadenar bombas sin esperar.
; ----------------------------------------------------------------------
recupera_la_bomba:
	ld a,(0e077h)		;a5bf
	rra			;a5c2   ; el bit 0: le queda partida
	jr nc,L_A5F5		;a5c3
	call el_uno_tiene_bomba		;a5c5   ; el primer jugador, vivo
	jr nz,L_A5F5		;a5c8
	call donde_esta_la_nave_uno		;a5ca   ; donde esta su nave
	ld a,(0e348h)		;a5cd   ; y su bomba, en el aire
	and a			;a5d0
	jr z,L_A5F5		;a5d1
	ld de,(0e349h)		;a5d3   ; y donde su bomba
	ld a,e			;a5d7
	add a,00fh		;a5d8   ; el marco: 0x1F en las dos
	sub l			;a5da
	cp 01fh		;a5db
	jr nc,L_A5F5		;a5dd
	ld a,d			;a5df
	add a,00fh		;a5e0
	sub h			;a5e2
	cp 01fh		;a5e3
	jr nc,L_A5F5		;a5e5
	ld hl,0e348h		;a5e7
	call apaga_la_bomba		;a5ea   ; la bomba se recoge
	ld a,001h		;a5ed
	ld (0e08dh),a		;a5ef   ; y vuelve a estar cargada
	call suena_la_bomba		;a5f2   ; y su ruido
L_A5F5:
	call es_el_segundo_jugador		;a5f5   ; y lo mismo para el segundo
	ret z			;a5f8
	ld a,(0e077h)		;a5f9   ; los jugadores vivos
	rra			;a5fc   ; el bit 1: el segundo
	rra			;a5fd
	ret nc			;a5fe
	call el_dos_tiene_bomba		;a5ff   ; si le queda bomba
	ret nz			;a602
	call donde_esta_la_nave_dos		;a603   ; y donde esta su nave, en HL
	ld a,(0e340h)		;a606   ; la bomba del segundo
	and a			;a609
	ret z			;a60a
	ld de,(0e341h)		;a60b   ; la posicion de la bomba
	ld a,e			;a60f
	add a,00fh		;a610   ; el mismo marco de 0x1F
	sub l			;a612   ; contra la de la nave
	cp 01fh		;a613   ; fuera del marco, no le da
	ret nc			;a615
	ld a,d			;a616
	add a,00fh		;a617   ; el mismo marco en vertical
	sub h			;a619
	cp 01fh		;a61a
	ret nc			;a61c
	ld hl,0e340h		;a61d   ; el hueco de la bomba del dos
	call apaga_la_bomba		;a620   ; se recoge
	ld a,001h		;a623
	ld (0e08eh),a		;a625   ; y vuelve a estar cargada
suena_la_bomba:
	ld a,091h		;a628
	jp pide_un_sonido_si_se_juega		;a62a
mira_las_naves_contra_los_disparos:
	ld a,(0e077h)		;a62d
	rra			;a630   ; el bit 0: le queda partida al primero
	jr nc,L_A646		;a631
	call el_uno_tiene_bomba		;a633
	jr nz,L_A646		;a636
	ld a,(0e097h)		;a638   ; y no puede estar recien nacido
	and a			;a63b
	jr nz,L_A646		;a63c
	call donde_esta_la_nave_uno		;a63e
	ld c,001h		;a641
	call recorre_los_disparos_del_enemigo		;a643
L_A646:
	call es_el_segundo_jugador		;a646   ; con dos jugadores
	ret z			;a649
	ld a,(0e077h)		;a64a
	rra			;a64d
	rra			;a64e
	ret nc			;a64f
	call el_dos_tiene_bomba		;a650
	ret nz			;a653
	ld a,(0e098h)		;a654   ; con la nave recien nacida no cuenta
	and a			;a657
	ret nz			;a658
	call donde_esta_la_nave_dos		;a659
	ld c,002h		;a65c
recorre_los_disparos_del_enemigo:
	ld de,0e240h		;a65e   ; los siete disparos del enemigo
	ld b,007h		;a661
L_A663:
	push bc			;a663
	ld a,(de)			;a664   ; el hueco del disparo
	and a			;a665
	ld a,020h		;a666   ; hueco vacio, se salta
	jr nz,L_A693		;a668
	inc e			;a66a
	ld a,(de)			;a66b   ; su clase
	dec a			;a66c   ; y solo la clase 1 hace dano
	ld a,01fh		;a66d
	jr nz,L_A693		;a66f
	ld a,006h		;a671   ; seis bytes adelante: la posicion
	add a,e			;a673
	ld e,a			;a674
	ld a,(de)			;a675
	inc e			;a676
	inc e			;a677
	add a,003h		;a678   ; el marco: 0x13 en horizontal
	sub l			;a67a   ; menos la de la nave
	cp 013h		;a67b
	jr nc,L_A691		;a67d
	ld a,(de)			;a67f   ; la vertical
	sub h			;a680
	cp 00dh		;a681   ; y 0x0D en vertical, que es mas estrecho
	jr nc,L_A691		;a683
	push de			;a685   ; el hueco y la nave, a salvo
	push hl			;a686
	call le_dan_a_la_nave		;a687
	pop hl			;a68a
	pop de			;a68b
	dec a			;a68c   ; si devuelve 1, la nave se murio
	jr nz,L_A691		;a68d
	pop bc			;a68f
	ret			;a690
L_A691:
	ld a,017h		;a691   ; 0x17 bytes hasta el siguiente
L_A693:
	call suma_a_a_de		;a693   ; y se avanza
	pop bc			;a696
	djnz L_A663		;a697
	ret			;a699
le_dan_a_la_nave:
	ex de,hl			;a69a   ; el disparo se gasta
	ld a,l			;a69b   ; nueve bytes atras: el bloque entero
	sub 009h		;a69c
	ld l,a			;a69e
	call apaga_ese_enemigo		;a69f
	ld a,c			;a6a2   ; el jugador al que le dieron
	dec a			;a6a3
	ld hl,0e083h		;a6a4   ; su estado
	ld de,0e08dh		;a6a7   ; y su marca de brazo
	jr z,L_A6AE		;a6aa
	inc l			;a6ac   ; el segundo, un byte mas alla
	inc e			;a6ad
L_A6AE:
	ld a,(hl)			;a6ae   ; su estado
	bit 2,a		;a6af   ; el bit 2: lleva arma
	jr nz,gasta_el_escudo		;a6b1
	ld a,(de)			;a6b3   ; con el brazo puesto
	and a			;a6b4
	jr z,L_A6DC		;a6b5
	xor a			;a6b7
	ld (de),a			;a6b8   ; solo se pierde el brazo
	dec e			;a6b9
	dec e			;a6ba
	ld a,(de)			;a6bb   ; y el estado vuelve a uno si estaba a cero
	and a			;a6bc
	jr nz,L_A6C1		;a6bd
	inc a			;a6bf
	ld (de),a			;a6c0
L_A6C1:
	ld a,090h		;a6c1   ; con su ruido
	call pide_un_sonido_si_se_juega		;a6c3
L_A6C6:
	xor a			;a6c6   ; y devuelve 0: la nave sigue viva
	ret			;a6c7
gasta_el_escudo:
	ex de,hl			;a6c8   ; sus usos de arma
	ld a,c			;a6c9
	dec a			;a6ca
	ld hl,0e095h		;a6cb
	jr z,L_A6D1		;a6ce
	inc l			;a6d0
L_A6D1:
	dec (hl)			;a6d1   ; y con arma, se gastan usos
	jr z,L_A6D6		;a6d2   ; al llegar a cero
	jr nc,L_A6C6		;a6d4   ; o pasarse
L_A6D6:
	ld a,(de)			;a6d6
	and 0fbh		;a6d7   ; hasta que se acaba
	ld (de),a			;a6d9   ; se apaga la marca del arma
	jr L_A6C6		;a6da
L_A6DC:
	call se_muere_la_nave		;a6dc   ; y sin nada, la nave se estrella
	ld a,001h		;a6df   ; y devuelve 1
	ret			;a6e1
mira_los_disparos_contra_los_enemigos:
	call cuantos_disparos		;a6e2   ; cuatro disparos con uno, seis con dos
	ld hl,0e100h		;a6e5   ; los disparos del primer jugador
	ld a,001h		;a6e8   ; con la marca del primer jugador
	ld (0ebc0h),a		;a6ea
	call recorre_los_disparos_3		;a6ed
	call es_el_segundo_jugador		;a6f0
	ret z			;a6f3
	ld hl,0e110h		;a6f4   ; y los del segundo
	ld b,002h		;a6f7   ; dos vueltas
	ld a,b			;a6f9
	ld (0ebc0h),a		;a6fa
recorre_los_disparos_3:
	push hl			;a6fd   ; el hueco, a IX
	pop ix		;a6fe   ; en IX, que es como se lee comodo
	ld a,(hl)			;a700   ; hueco de disparo vacio
	and a			;a701
	ld a,008h		;a702   ; ocho bytes por disparo
	jr z,L_A74F		;a704
	inc l			;a706   ; el segundo byte es la clase
	ld a,(hl)			;a707   ; la clase del disparo
	exx			;a708
	ld c,a			;a709   ; la clase, a salvo en C
	dec a			;a70a   ; la tabla arranca en la clase 1
	add a,a			;a70b   ; dos bytes por entrada
	ld hl,0a78eh		;a70c   ; el marco de esa clase de enemigo
	call indexa_palabras		;a70f   ; el marco de la clase, a HL
	push hl			;a712
	pop iy		;a713   ; y a IY, que se lee comodo
	exx			;a715
	inc l			;a716   ; y su posicion
	inc l			;a717
	inc l			;a718
	ld a,(hl)			;a719   ; la horizontal
	inc l			;a71a
	exx			;a71b
	ld l,a			;a71c
	exx			;a71d
	ld a,(hl)			;a71e   ; y la vertical
	exx			;a71f
	ld h,a			;a720
	ld de,0e176h		;a721   ; los catorce enemigos
	ld b,00eh		;a724
recorre_los_catorce:
	ld a,(de)			;a726   ; la clase del enemigo
	and a			;a727   ; clase cero es hueco vacio
	ld a,020h		;a728   ; hueco vacio, se salta
	jr z,L_A747		;a72a   ; treinta y dos bytes por enemigo
	ld a,e			;a72c   ; quince bytes atras: la posicion del enemigo
	sub 00fh		;a72d
	ld e,a			;a72f
	ld a,(de)			;a730   ; su horizontal
	inc e			;a731
	call cabe_en_el_marco		;a732   ; el marco horizontal
	jr nc,L_A745		;a735
	call cabe_en_vertical		;a737   ; y el vertical
	jr nc,L_A745		;a73a
	ld a,(0ebc0h)		;a73c   ; que jugador disparo
	ld b,a			;a73f   ; en B, que es lo que espera la de abajo
	call le_dan_al_enemigo		;a740
	jr L_A74C		;a743
L_A745:
	ld a,02dh		;a745   ; 0x2D adelante: el siguiente enemigo
L_A747:
	call suma_a_a_de		;a747
	djnz recorre_los_catorce		;a74a   ; el enemigo siguiente
L_A74C:
	exx			;a74c
	ld a,003h		;a74d   ; tres bytes hasta el disparo siguiente
L_A74F:
	add a,l			;a74f
	ld l,a			;a750
	djnz recorre_los_disparos_3		;a751
	ret			;a753
le_dan_al_enemigo:
	push de			;a754   ; el hueco, a salvo
	dec c			;a755   ; con las dos agarradas
	dec c			;a756
	dec c			;a757
	ld a,b			;a758
	ld bc,00001h		;a759   ; el enemigo vale un punto
	jr z,L_A766		;a75c
	dec a			;a75e   ; con C a 1
	jr nz,L_A76B		;a75f
	call suma_al_primero		;a761   ; los puntos van a los dos
	jr L_A76E		;a764
L_A766:
	push bc			;a766   ; el punto, a salvo para el segundo reparto
	call suma_al_primero		;a767
	pop bc			;a76a
L_A76B:
	call suma_al_segundo		;a76b   ; o al que fuera
L_A76E:
	pop de			;a76e
	ld a,e			;a76f   ; nueve bytes atras
	sub 009h		;a770
	ld e,a			;a772
	ld a,(de)			;a773   ; la clase del enemigo
	ld c,08bh		;a774
	cp 007h		;a776   ; las de 7 a 0x0B suenan distinto
	jr c,L_A77E		;a778
	cp 00ch		;a77a
	jr c,L_A780		;a77c
L_A77E:
	ld c,088h		;a77e
L_A780:
	ld a,c			;a780
	call pide_un_sonido_si_se_juega		;a781
	push ix		;a784
	pop hl			;a786   ; el hueco del disparo
	call apaga_cuatro_sprites		;a787   ; y el enemigo se apaga
	ex de,hl			;a78a
	jp marca_para_apagar		;a78b   ; y el enemigo, marcado

; ----------------------------------------------------------------------
; DATOS marco_del_enemigo_grande: Lo mismo para los de 0xA70C, con el minimo a
;   0x0F
;   0xa78e..0xa79a  (12 bytes)
DATA_marco_del_enemigo_grande:
	defb 00fh	; a78e
	defb 013h	; a78f
	defb 00fh	; a790
	defb 013h	; a791
	defb 00fh	; a792
	defb 013h	; a793
	defb 00fh	; a794
	defb 019h	; a795
	defb 00fh	; a796
	defb 017h	; a797
	defb 00fh	; a798
	defb 017h	; a799

; ======================================================================
; CODIGO 0xa79a..0xa906  (364 bytes)
; ======================================================================


mira_las_naves_contra_los_enemigos:
	ld a,(0e077h)		;a79a   ; el primer jugador
	rra			;a79d   ; el bit 0: le queda partida
	jr nc,L_A7B3		;a79e
	call el_uno_tiene_bomba		;a7a0   ; y no puede estar muriendose
	jr nz,L_A7B3		;a7a3
	ld a,(0e097h)		;a7a5   ; con la nave recien nacida no cuenta
	and a			;a7a8
	jr nz,L_A7B3		;a7a9
	call donde_esta_la_nave_uno		;a7ab   ; donde esta su nave
	ld c,001h		;a7ae   ; con su marca
	call recorre_los_catorce_2		;a7b0
L_A7B3:
	call es_el_segundo_jugador		;a7b3   ; con dos jugadores
	ret z			;a7b6
	ld a,(0e077h)		;a7b7
	rra			;a7ba   ; el bit 1: le queda partida al segundo
	rra			;a7bb
	ret nc			;a7bc
	call el_dos_tiene_bomba		;a7bd
	ret nz			;a7c0
	ld a,(0e098h)		;a7c1   ; y la nave sin estrenar no choca
	and a			;a7c4
	ret nz			;a7c5
	call donde_esta_la_nave_dos		;a7c6   ; donde esta
	ld c,002h		;a7c9
recorre_los_catorce_2:
	ld de,0e160h		;a7cb   ; los catorce enemigos
	ld b,00eh		;a7ce
L_A7D0:
	push bc			;a7d0
	ld a,(de)			;a7d1   ; la clase del enemigo
	and a			;a7d2
	ld a,020h		;a7d3   ; hueco vacio, se salta
	jr z,L_A810		;a7d5
	ld a,016h		;a7d7   ; 0x16 adelante: su marca de choque
	add a,e			;a7d9
	ld e,a			;a7da
	ld a,(de)			;a7db   ; y los que no chocan tampoco
	and a			;a7dc
	ld a,00ah		;a7dd   ; 0x0A hasta el siguiente
	jr z,L_A810		;a7df
	ld a,e			;a7e1   ; quince atras: la posicion
	sub 00fh		;a7e2
	ld e,a			;a7e4
	ld a,(de)			;a7e5
	inc e			;a7e6
	inc e			;a7e7
	add a,00fh		;a7e8   ; el marco: 0x1F horizontal
	sub l			;a7ea   ; menos la de la nave
	cp 01fh		;a7eb
	jr nc,L_A80E		;a7ed
	ld a,(de)			;a7ef
	add a,009h		;a7f0   ; y mas estrecho en vertical
	sub h			;a7f2
	cp 019h		;a7f3
	jr nc,L_A80E		;a7f5
	ld a,(0e078h)		;a7f7   ; y si esa nave ya se estaba muriendo, tampoco
	and c			;a7fa   ; el bit de esa nave
	jr nz,L_A80E		;a7fb
	push bc			;a7fd   ; el hueco, la posicion y la cuenta, a salvo
	push de			;a7fe
	push hl			;a7ff
	call choca_con_el_enemigo		;a800
	pop hl			;a803
	pop de			;a804
	pop bc			;a805
	ld a,(0e078h)		;a806   ; y si la nave acaba de morir
	and c			;a809
	jr z,L_A80E		;a80a
	pop bc			;a80c   ; se sale sin mirar mas
	ret			;a80d
L_A80E:
	ld a,017h		;a80e   ; 0x17 hasta el enemigo siguiente
L_A810:
	call suma_a_a_de		;a810
	pop bc			;a813
	djnz L_A7D0		;a814
	ret			;a816
choca_con_el_enemigo:
	ld a,c			;a817   ; el jugador que choco
	dec a			;a818
	ld hl,0e083h		;a819
	jr z,L_A81F		;a81c
	inc l			;a81e
L_A81F:
	bit 2,(hl)		;a81f   ; el bit 2: lleva arma
	jp z,se_muere_la_nave		;a821   ; sin ella, la nave se estrella
	push de			;a824   ; el estado, a salvo
	ex de,hl			;a825
	dec c			;a826
	ld hl,0e095h		;a827   ; sus usos de arma
	jr z,L_A82D		;a82a
	inc l			;a82c
L_A82D:
	dec (hl)			;a82d   ; dos usos menos
	dec (hl)			;a82e
	jr z,L_A835		;a82f   ; al llegar a cero
	bit 7,(hl)		;a831   ; o desbordar por debajo
	jr z,L_A839		;a833
L_A835:
	ld a,(de)			;a835
	and 0fbh		;a836   ; y al acabarse, se apaga
	ld (de),a			;a838
L_A839:
	pop de			;a839
	ex de,hl			;a83a
	ld a,l			;a83b   ; nueve bytes atras: el bloque del enemigo
	sub 009h		;a83c
	ld l,a			;a83e
	push hl			;a83f   ; y a salvo
	call marca_para_apagar		;a840   ; el enemigo tambien revienta
	pop hl			;a843
	ld a,(hl)			;a844   ; su clase
	ld c,08bh		;a845
	cp 007h		;a847   ; las clases de 7 a 0x0B suenan distinto
	jr c,L_A84F		;a849
	cp 00ch		;a84b
	jr c,L_A851		;a84d
L_A84F:
	ld c,088h		;a84f
L_A851:
	ld a,c			;a851
	jp pide_un_sonido_si_se_juega		;a852
mira_los_disparos_contra_el_jefe:
	ld a,(0e336h)		;a855   ; si no hay jefe, nada
	and a			;a858
	ret z			;a859
	ld (0ebc0h),a		;a85a   ; la marca del jefe
	ld a,(0e327h)		;a85d   ; donde esta, menos 0x10
	sub 010h		;a860
	ld l,a			;a862   ; ese es el punto de comparacion
	ld a,(0e329h)		;a863
	sub 010h		;a866
	ld h,a			;a868
	ld de,0e100h		;a869   ; los disparos del primero
	call cuantos_disparos		;a86c   ; cuatro con uno, seis con dos
	ld a,(0e077h)		;a86f   ; los disparos del primero
	rra			;a872   ; el bit 0: le queda partida
	jr nc,L_A87A		;a873
	call recorre_los_disparos_del_jugador		;a875
	and a			;a878
	ret nz			;a879
L_A87A:
	call es_el_segundo_jugador		;a87a
	ret z			;a87d
	ld de,0e110h		;a87e   ; y los del segundo
	ld b,002h		;a881
	ld a,b			;a883
	ld (0ebc0h),a		;a884
	ld a,(0e077h)		;a887
	rra			;a88a
	rra			;a88b
	ret nc			;a88c
recorre_los_disparos_del_jugador:
	push de			;a88d   ; el hueco de disparo
	pop ix		;a88e
	ld a,(de)			;a890   ; vacio, se salta
	and a			;a891
	ld a,008h		;a892
	jr z,L_A8C3		;a894
	inc e			;a896
	ld a,(de)			;a897   ; su clase
	ld c,a			;a898
	dec a			;a899
	add a,a			;a89a   ; por dos: la entrada de la tabla
	push hl			;a89b
	ld hl,0a906h		;a89c   ; el marco del jefe
	call indexa_palabras		;a89f   ; la entrada que le toca
	push hl			;a8a2
	pop iy		;a8a3   ; en IY
	pop hl			;a8a5
	inc e			;a8a6   ; tres bytes adelante: la posicion
	inc e			;a8a7
	inc e			;a8a8
	ld a,(de)			;a8a9
	call cabe_en_el_marco		;a8aa   ; el horizontal
	jr nc,L_A8C1		;a8ad
	call cabe_en_vertical		;a8af   ; y el vertical
	jr nc,L_A8C1		;a8b2
	push bc			;a8b4
	ld a,(0ebc0h)		;a8b5   ; que jugador disparo
	ld b,a			;a8b8
	push hl			;a8b9
	call le_dan_al_jefe		;a8ba
	pop hl			;a8bd
	pop bc			;a8be
	and a			;a8bf   ; si el jefe murio, se sale
	ret nz			;a8c0
L_A8C1:
	ld a,003h		;a8c1   ; tres bytes hasta el disparo siguiente
L_A8C3:
	add a,e			;a8c3
	ld e,a			;a8c4
	djnz recorre_los_disparos_del_jugador		;a8c5
	xor a			;a8c7   ; y devuelve 0: el jefe sigue vivo
	ret			;a8c8
le_dan_al_jefe:
	push ix		;a8c9
	pop hl			;a8cb   ; el hueco del disparo
	call apaga_cuatro_sprites		;a8cc   ; el disparo se gasta
	ld hl,0e335h		;a8cf   ; la vida del jefe
	dec (hl)			;a8d2
	jr z,L_A8DC		;a8d3   ; y al llegar a cero, se acabo
	ld a,087h		;a8d5
	call pide_un_sonido_si_se_juega		;a8d7
	xor a			;a8da   ; y devuelve 0
	ret			;a8db
L_A8DC:
	push bc			;a8dc   ; quien disparo, a salvo
	call marca_al_jefe_para_apagar		;a8dd   ; el jefe revienta
	pop bc			;a8e0
	dec c			;a8e1   ; con C a 3, van agarradas
	dec c			;a8e2
	dec c			;a8e3
	ld a,b			;a8e4
	ld bc,00100h		;a8e5   ; y da 100 puntos
	jr z,L_A8F2		;a8e8
	dec a			;a8ea   ; con C a 1
	jr nz,L_A8F7		;a8eb
	call suma_al_primero		;a8ed
	jr L_A8FA		;a8f0
L_A8F2:
	push bc			;a8f2   ; los puntos, a salvo para el segundo reparto
	call suma_al_primero		;a8f3
	pop bc			;a8f6
L_A8F7:
	call suma_al_segundo		;a8f7
L_A8FA:
	xor a			;a8fa   ; la musica de fondo, fuera
	ld (0e05dh),a		;a8fb
	ld a,02bh		;a8fe   ; con la del jefe muerto
	call pide_un_sonido_si_se_juega		;a900
	ld a,001h		;a903   ; y devuelve 1
	ret			;a905

; ----------------------------------------------------------------------
; DATOS marco_del_enemigo_del_jefe: Y la tercera pareja de la misma tabla, la
;   de 0xA89C
;   0xa906..0xa912  (12 bytes)
DATA_marco_del_enemigo_del_jefe:
	defb 003h	; a906
	defb 013h	; a907
	defb 003h	; a908
	defb 022h	; a909
	defb 003h	; a90a
	defb 013h	; a90b
	defb 009h	; a90c
	defb 029h	; a90d
	defb 007h	; a90e
	defb 017h	; a90f
	defb 007h	; a910
	defb 027h	; a911

; ======================================================================
; CODIGO 0xa912..0xabd3  (705 bytes)
; ======================================================================


mira_las_naves_contra_el_jefe:
	ld a,(0e077h)		;a912   ; el primer jugador, vivo
	rra			;a915   ; el bit 0: le queda partida
	jr nc,L_A92B		;a916
	call el_uno_tiene_bomba		;a918   ; y no puede estar muriendose
	jr nz,L_A92B		;a91b
	ld a,(0e097h)		;a91d   ; con la nave recien nacida no cuenta
	and a			;a920
	jr nz,L_A92B		;a921
	call donde_esta_la_nave_uno		;a923
	ld c,001h		;a926
	call choca_con_el_jefe		;a928
L_A92B:
	call es_el_segundo_jugador		;a92b   ; con dos jugadores
	ret z			;a92e
	ld a,(0e077h)		;a92f   ; el segundo, vivo
	rra			;a932
	rra			;a933
	ret nc			;a934
	call el_dos_tiene_bomba		;a935
	ret nz			;a938
	ld a,(0e098h)		;a939   ; y sin estrenar no choca
	and a			;a93c
	ret nz			;a93d
	call donde_esta_la_nave_dos		;a93e
	ld c,002h		;a941
choca_con_el_jefe:
	ld de,0e336h		;a943   ; si no hay jefe, nada
	ld a,(de)			;a946
	and a			;a947
	ret z			;a948
	ld a,e			;a949   ; quince bytes atras: la posicion del jefe
	sub 00fh		;a94a
	ld e,a			;a94c
	ld a,(de)			;a94d   ; su horizontal
	inc e			;a94e
	inc e			;a94f
	add a,00fh		;a950   ; el marco: 0x1F horizontal
	sub l			;a952   ; menos la de la nave
	cp 01fh		;a953
	ret nc			;a955
	ld a,(de)			;a956   ; y su vertical
	add a,009h		;a957   ; y 0x19 vertical
	sub h			;a959
	cp 019h		;a95a
	ret nc			;a95c

; ----------------------------------------------------------------------
; SE MUERE LA NAVE. Aqui llega todo lo que la mata: el choque con un enemigo, con el jefe o con un disparo. Se enciende su bit en (0xE078) -que es lo que hace que 0x5F04 la mande a la rutina de la explosion-, se le quitan las armas, se le tira la bomba y, si era el ultimo con vidas, se calla la musica y suena el final.
; ----------------------------------------------------------------------
se_muere_la_nave:
	ld a,c			;a95d   ; el jugador que se muere
	dec a			;a95e   ; a que jugador
	ld de,0e348h		;a95f   ; su bomba
	ld hl,0e085h		;a962   ; y su cuenta de explosion
	ld ix,0e08bh		;a965   ; y su marca de bomba
	jr z,L_A971		;a969
	ld de,0e340h		;a96b   ; las del segundo, todas un byte mas alla
	inc l			;a96e
	inc ix		;a96f
L_A971:
	ld (hl),03ch		;a971   ; 0x3C cuadros de explosion
	ex de,hl			;a973
	call apaga_la_bomba		;a974   ; la bomba se pierde
	ld (ix+000h),000h		;a977   ; y la marca de bomba, a cero
	ld a,(0e078h)		;a97b   ; y se apunta que se esta muriendo
	or c			;a97e
	ld (0e078h),a		;a97f
	ld a,c			;a982   ; solo el primer jugador
	dec a			;a983
	jr nz,L_A98A		;a984
	xor a			;a986
	ld (0e364h),a		;a987   ; el contador de campanas, a cero
L_A98A:
	ld hl,0e083h		;a98a
	ld a,(hl)			;a98d
	and 00fh		;a98e   ; se le quitan las armas
	ld (hl),a			;a990
	inc l			;a991   ; y las del otro tambien
	ld a,(hl)			;a992
	and 00fh		;a993
	ld (hl),a			;a995
	ld a,(0e077h)		;a996   ; cuantos jugadores quedan
	dec a			;a999   ; si queda algun jugador vivo
	jr z,L_A9BB		;a99a
	dec a			;a99c
	jr z,L_A9BB		;a99d
	ld a,(0e070h)		;a99f   ; o vidas
	ld hl,0e073h		;a9a2
	or (hl)			;a9a5   ; juntas
	jr nz,L_A9B8		;a9a6
	ld hl,0e078h		;a9a8
	dec c			;a9ab   ; si murio el segundo
	jr nz,L_A9B4		;a9ac
	bit 1,(hl)		;a9ae   ; se mira el bit del primero
	jr nz,L_A9BB		;a9b0
	jr L_A9B8		;a9b2
L_A9B4:
	bit 0,(hl)		;a9b4   ; y al reves
	jr nz,L_A9BB		;a9b6
L_A9B8:
	jp L_60A3		;a9b8   ; solo cambia la musica
L_A9BB:
	ld a,(0e070h)		;a9bb
	ld hl,0e073h		;a9be   ; las del otro
	or (hl)			;a9c1   ; si queda alguna, sigue la partida
	jr nz,L_A9B8		;a9c2
	ld (0e05dh),a		;a9c4   ; y si no, se calla
	ld a,031h		;a9c7   ; y suena el final
	jp pide_un_sonido_si_se_juega		;a9c9
mueve_los_grandes:
	ld hl,0e3b0h		;a9cc   ; los cinco enemigos grandes
	ld b,005h		;a9cf   ; los cinco huecos
L_A9D1:
	push bc			;a9d1
	push hl			;a9d2
	ld a,(hl)			;a9d3   ; la clase
	and a			;a9d4   ; hueco vacio, se salta
	jr z,L_AA12		;a9d5
	inc l			;a9d7
	ld a,(hl)			;a9d8   ; y cada clase tiene su tamano
	dec a			;a9d9
	ld de,00700h		;a9da   ; la clase 1 mide 7 de alto
	jr z,L_A9FB		;a9dd
	dec a			;a9df
	ld de,00905h		;a9e0   ; la 2, 9 por 5
	jr z,L_A9FB		;a9e3
	dec a			;a9e5
	ld de,00a0ah		;a9e6   ; la 3, 10 por 10
	jr z,L_A9FB		;a9e9
	dec a			;a9eb   ; la 4
	jr z,L_AA00		;a9ec
	dec a			;a9ee   ; la 5
	jr z,L_AA05		;a9ef
	cp 005h		;a9f1   ; las 5 y 6
	jr c,L_AA0A		;a9f3
	cp 007h		;a9f5   ; y las de 7 arriba
	jr c,L_AA0F		;a9f7
	jr L_AA12		;a9f9   ; y las demas no se mueven
L_A9FB:
	call el_grande_que_baja		;a9fb   ; las tres primeras bajan y disparan
	jr L_AA12		;a9fe
L_AA00:
	call el_grande_que_serpentea		;aa00   ; la 4 serpentea
	jr L_AA12		;aa03
L_AA05:
	call el_grande_que_late		;aa05   ; la 5 late
	jr L_AA12		;aa08
L_AA0A:
	call el_grande_quieto		;aa0a   ; las 5 y 6 se quedan quietas
	jr L_AA12		;aa0d
L_AA0F:
	call el_grande_que_se_apaga		;aa0f   ; y las de 7 arriba se estan apagando
L_AA12:
	pop hl			;aa12
	pop bc			;aa13
	ld de,00010h		;aa14   ; dieciseis bytes hasta el siguiente
	add hl,de			;aa17
	djnz L_A9D1		;aa18
	ld de,0e3f0h		;aa1a   ; y ahora, a dibujarlos
	ld b,005h		;aa1d   ; los cinco

; ----------------------------------------------------------------------
; LOS GRANDES SE DIBUJAN CON CASILLAS, NO CON SPRITES. Un enemigo grande no cabe en un sprite de 16x16, asi que se pinta escribiendo casillas en el buffer de la pantalla: 0xAA27 saca su guion de la tabla de 0xACCB, 0xAA41 convierte su fila en un desplazamiento -cinco `add hl,hl`, o sea por 32- y los cuatro `ldi` escriben dos casillas arriba y dos 0x1E mas alla, o sea justo debajo. Cuatro casillas por cuadro.
; ----------------------------------------------------------------------
coloca_los_grandes:
	ld a,(de)			;aa1f   ; la clase
	dec a			;aa20   ; solo la clase 1 se dibuja asi
	jr nz,L_AA61		;aa21
	push de			;aa23
	inc e			;aa24
	ld a,(de)			;aa25   ; el dibujo que le toca
	dec a			;aa26
	ld hl,0accbh		;aa27   ; la tabla de guiones
	call indexa_palabras		;aa2a   ; la entrada de la tabla
	ld a,(hl)			;aa2d   ; y el guion que sale de ella
	inc hl			;aa2e
	ld h,(hl)			;aa2f
	ld l,a			;aa30
	inc e			;aa31
	inc e			;aa32
	inc e			;aa33
	ld a,(de)			;aa34   ; el paso
	dec a			;aa35
	add a,a			;aa36   ; por dos
	call indexa_palabras		;aa37   ; el paso dentro del guion
	ex de,hl			;aa3a
	dec l			;aa3b   ; la columna
	ld c,(hl)			;aa3c
	dec l			;aa3d
	ld l,(hl)			;aa3e   ; y la fila
	ld h,000h		;aa3f
	add hl,hl			;aa41   ; la fila, por 32
	add hl,hl			;aa42
	add hl,hl			;aa43
	add hl,hl			;aa44
	add hl,hl			;aa45
	push de			;aa46
	ld de,0ec00h		;aa47   ; y el buffer de la pantalla
	add hl,de			;aa4a
	pop de			;aa4b
	ex de,hl			;aa4c
	ld a,c			;aa4d   ; mas la columna
	call suma_a_a_de		;aa4e
	ld c,0ffh		;aa51   ; sin mascara
	ldi		;aa53   ; dos casillas arriba
	ldi		;aa55
	ld a,01eh		;aa57   ; y una fila mas abajo
	call suma_a_a_de		;aa59
	ldi		;aa5c
	ldi		;aa5e   ; las otras dos
	pop de			;aa60
L_AA61:
	ld a,e			;aa61
	sub 010h		;aa62   ; 0x10 bytes atras: el grande anterior
	ld e,a			;aa64
	djnz coloca_los_grandes		;aa65
	ret			;aa67
saca_las_oleadas:
	ld a,(0e3a1h)		;aa68   ; mientras no toque esperar
	and a			;aa6b   ; con espera pendiente, nada
	ret nz			;aa6c
	call saca_una_oleada		;aa6d   ; y mientras no haya, se sacan seguidas
	jr saca_las_oleadas		;aa70
saca_una_oleada:
	ld hl,0e3a0h		;aa72   ; la oleada siguiente
	inc (hl)			;aa75   ; uno mas
	ld a,(hl)			;aa76
	ld c,a			;aa77
	ld hl,0abd3h		;aa78   ; lo que hay que esperar hasta la de despues
	call suma_a_a_hl		;aa7b   ; la tabla de esperas
	ld a,(hl)			;aa7e
	ld (0e3a1h),a		;aa7f
	ld de,0ac47h		;aa82   ; y la formacion que toca
	ld l,c			;aa85
	ld h,000h		;aa86
	add hl,de			;aa88   ; la entrada que le toca
	ld a,(hl)			;aa89
	and a			;aa8a   ; con cero, no hay oleada
	ret z			;aa8b
	and 0f0h		;aa8c   ; el nibble alto: la clase
	rra			;aa8e   ; por dos, y luego se corre a la derecha
	rra			;aa8f
	rra			;aa90
	inc a			;aa91   ; mas uno: la clase de verdad
	ld c,a			;aa92
	ld a,(hl)			;aa93   ; el mismo byte otra vez
	and 008h		;aa94   ; el bit 3 pide segunda vuelta
	jr z,L_AA9E		;aa96
	ld a,(0e076h)		;aa98   ; y en la primera no sale
	and 0f0h		;aa9b   ; el nibble alto del escenario dice la vuelta
	ret z			;aa9d
L_AA9E:
	ld a,(hl)			;aa9e
	and 007h		;aa9f   ; los tres bits bajos: el recorrido
	ld l,a			;aaa1
	ld h,000h		;aaa2
	ld e,l			;aaa4
	ld d,h			;aaa5
	add hl,hl			;aaa6   ; por tres, que es lo que ocupa cada uno
	add hl,de			;aaa7
	ld de,0acbch		;aaa8
	add hl,de			;aaab
	ld de,0e3b0h		;aaac
	ld b,005h		;aaaf   ; los cinco huecos de enemigo grande
L_AAB1:
	ld a,(de)			;aab1
	and a			;aab2
	jr z,monta_el_grande		;aab3   ; se busca uno libre
	ld a,010h		;aab5
	add a,e			;aab7
	ld e,a			;aab8
	djnz L_AAB1		;aab9
	ret			;aabb
monta_el_grande:
	ld b,c			;aabc   ; la clase, en B
	ld c,0ffh		;aabd   ; sin recorrido todavia
	ld a,001h		;aabf   ; el hueco, ocupado
	ld (de),a			;aac1   ; y ahi nace
	inc e			;aac2
	ldi		;aac3   ; con su recorrido
	xor a			;aac5   ; sin paso
	ld (de),a			;aac6
	inc e			;aac7
	ld a,b			;aac8
	ld (de),a			;aac9   ; y su clase
	inc e			;aaca
	ld a,001h		;aacb   ; y en marcha
	ld (de),a			;aacd
	inc e			;aace
	inc e			;aacf   ; dos bytes adelante
	ld a,b			;aad0   ; la clase otra vez
	rla			;aad1   ; por ocho: el dibujo
	rla			;aad2
	rla			;aad3
	ld (de),a			;aad4
	inc e			;aad5   ; dos bytes adelante
	inc e			;aad6
	ldi		;aad7   ; y donde nace
	ldi		;aad9   ; la vertical
	ret			;aadb
el_grande_que_serpentea:
	ld a,004h		;aadc   ; la posicion
	add a,l			;aade   ; cuatro bytes adelante
	ld l,a			;aadf
	ld a,(hl)			;aae0
	add a,009h		;aae1   ; nueve pixeles a la derecha
	ld e,a			;aae3   ; la horizontal, en E
	inc l			;aae4
	ld a,(hl)			;aae5
	add a,006h		;aae6   ; y seis mas abajo
	ld d,a			;aae8   ; y la vertical, en D
	inc l			;aae9   ; tres mas: la cuenta
	inc l			;aaea
	inc l			;aaeb
	dec (hl)			;aaec   ; la cuenta del recorrido
	ld a,(hl)			;aaed
	cp 030h		;aaee   ; en 0x30, 0x20 y 0x10 dispara
	jr z,el_grande_que_dispara		;aaf0
	cp 028h		;aaf2   ; y en 0x28 y 0x18 cambia de paso
	jr z,el_grande_de_paso_uno		;aaf4
	cp 020h		;aaf6
	jr z,el_grande_que_dispara		;aaf8
	cp 018h		;aafa
	jr z,el_grande_de_paso_uno		;aafc
	cp 010h		;aafe
	jr z,el_grande_que_dispara		;ab00
	and a			;ab02
	jr z,se_para_el_grande		;ab03   ; acabada la cuenta, se para
	jr avanza_el_grande		;ab05   ; y si no, sigue como iba
el_grande_que_baja:
	ld a,004h		;ab07
	add a,l			;ab09   ; cuatro bytes adelante
	ld l,a			;ab0a
	ld a,(hl)			;ab0b
	add a,e			;ab0c   ; su velocidad
	ld e,a			;ab0d
	inc l			;ab0e
	ld a,(hl)			;ab0f
	add a,d			;ab10   ; y la vertical igual
	ld d,a			;ab11
	inc l			;ab12   ; tres mas: la cuenta
	inc l			;ab13
	inc l			;ab14
	dec (hl)			;ab15   ; y su cuenta
	jr z,se_para_el_grande		;ab16
	ld a,(hl)			;ab18
	cp 020h		;ab19   ; en 0x20 dispara
	jr z,el_grande_que_dispara		;ab1b
avanza_el_grande:
	ld a,l			;ab1d
	sub 007h		;ab1e   ; siete bytes atras: el bloque
	ld l,a			;ab20
	jp pon_el_dibujo_del_grande		;ab21
se_para_el_grande:
	dec l			;ab24   ; la clase vuelve a su valor de reposo
	ld a,(hl)			;ab25   ; la clase original
	inc l			;ab26
	ld (hl),a			;ab27   ; al byte del paso
el_grande_de_paso_uno:
	ld a,l			;ab28
	sub 005h		;ab29   ; cinco bytes atras
	ld l,a			;ab2b
	ld (hl),001h		;ab2c   ; paso uno
	dec l			;ab2e   ; dos atras: la posicion
	dec l			;ab2f
	jr pon_el_dibujo_del_grande		;ab30
el_grande_que_dispara:
	ld a,l			;ab32
	sub 005h		;ab33   ; cinco bytes atras
	ld l,a			;ab35
	ld (hl),002h		;ab36   ; paso dos
	dec l			;ab38
	dec l			;ab39
	call pon_el_dibujo_del_grande		;ab3a
	jp busca_hueco_de_disparo		;ab3d   ; y suelta un disparo
el_grande_que_late:
	inc l			;ab40   ; tres bytes adelante
	inc l			;ab41
	inc l			;ab42
	ld c,(hl)			;ab43   ; la clase
	inc l			;ab44   ; tres mas: la cuenta
	inc l			;ab45
	inc l			;ab46
	dec c			;ab47   ; solo la clase 1 late
	jr nz,L_AB53		;ab48
	dec (hl)			;ab4a   ; su cuenta
	ret nz			;ab4b
	ld a,089h		;ab4c   ; con su ruido
	call pide_un_sonido_si_se_juega		;ab4e
	ld (hl),011h		;ab51   ; y 0x11 cuadros de latido
L_AB53:
	dec (hl)			;ab53   ; la cuenta del latido
	jr z,L_AB66		;ab54
	ld a,(hl)			;ab56
	and 004h		;ab57   ; el bit 2: alterna los dos dibujos
	ld c,002h		;ab59   ; con el dibujo 2
	jr nz,L_AB5E		;ab5b
	inc c			;ab5d   ; o el 3
L_AB5E:
	dec l			;ab5e   ; el paso, tres bytes atras
	dec l			;ab5f
	dec l			;ab60
	ld (hl),c			;ab61
	dec l			;ab62
	dec l			;ab63
	jr pon_el_dibujo_del_grande		;ab64
L_AB66:
	ld a,(0e3a2h)		;ab66   ; el contador del recorrido largo
	inc a			;ab69
	ld (0e3a2h),a		;ab6a
	cp 008h		;ab6d   ; en el octavo paso
	jr z,elige_el_grande_final		;ab6f
	cp 010h		;ab71   ; en el 0x10 pasa a la clase 8
	ld c,008h		;ab73
	jr z,L_AB82		;ab75
	sub 018h		;ab77   ; y en el 0x18 vuelve a empezar con la 9
	ld c,006h		;ab79
	jr nz,L_AB82		;ab7b
	ld (0e3a2h),a		;ab7d
	ld c,009h		;ab80
L_AB82:
	ld a,l			;ab82   ; seis bytes atras: la clase
	sub 006h		;ab83   ; seis bytes atras
	ld l,a			;ab85
	ld (hl),c			;ab86   ; se le cambia
	inc l			;ab87   ; tres bytes adelante
	inc l			;ab88
	inc l			;ab89
	ld (hl),001h		;ab8a   ; y se le da un paso
	ld a,l			;ab8c
	add a,004h		;ab8d   ; cuatro mas: las velocidades
	ld l,a			;ab8f
	xor a			;ab90   ; con las dos velocidades a cero
	ld (hl),a			;ab91
	inc l			;ab92   ; y la otra
	ld (hl),a			;ab93
	ld a,l			;ab94
	sub 007h		;ab95   ; siete atras: la clase
	ld l,a			;ab97
	jr pon_el_dibujo_del_grande		;ab98
elige_el_grande_final:
	call es_el_segundo_jugador		;ab9a   ; con dos jugadores
	ld c,006h		;ab9d   ; el grande 6
	jr nz,L_AB82		;ab9f
	ld a,(0e083h)		;aba1   ; o con armas puestas
	and 00ah		;aba4
	jr nz,L_AB82		;aba6
	ld c,007h		;aba8   ; sale el de la clase 7
	jr L_AB82		;abaa
el_grande_quieto:
	inc l			;abac
pon_el_dibujo_del_grande:
	ld a,(hl)			;abad   ; las clases 0 y 1 no se ven
	cp 002h		;abae
	ld c,0e0h		;abb0
	jr c,L_ABBA		;abb2
	sub 002h		;abb4   ; y las demas, por ocho: cuatro casillas por dibujo
	add a,a			;abb6
	add a,a			;abb7
	add a,a			;abb8
	ld c,a			;abb9
L_ABBA:
	inc l			;abba
	inc l			;abbb
	inc l			;abbc
	ld (hl),c			;abbd
	ret			;abbe
el_grande_que_se_apaga:
	ld a,006h		;abbf
	add a,l			;abc1
	ld l,a			;abc2
	dec (hl)			;abc3   ; su cuenta
	jr z,L_ABCC		;abc4
	ld a,l			;abc6
	sub 005h		;abc7
	ld l,a			;abc9
	jr pon_el_dibujo_del_grande		;abca
L_ABCC:
	ld a,l			;abcc
	sub 007h		;abcd
	ld l,a			;abcf
	jp borra_dieciseis		;abd0   ; y al acabarse se borra

; ----------------------------------------------------------------------
; DATOS niveles_de_la_oleada: 0xAA78 indexa aqui con (0xE3A0), que cuenta
;   oleadas, y lo que saca va a (0xE3A1)
;   0xabd3..0xac47  (116 bytes)
DATA_niveles_de_la_oleada:
	defb 004h	; abd3
	defb 00ch	; abd4
	defb 00eh	; abd5
	defb 004h	; abd6
	defb 015h	; abd7
	defb 015h	; abd8
	defb 00dh	; abd9
	defb 000h	; abda
	defb 016h	; abdb
	defb 00dh	; abdc
	defb 02ah	; abdd
	defb 004h	; abde
	defb 005h	; abdf
	defb 01dh	; abe0
	defb 050h	; abe1
	defb 00dh	; abe2
	defb 000h	; abe3
	defb 010h	; abe4
	defb 000h	; abe5
	defb 016h	; abe6
	defb 00ch	; abe7
	defb 012h	; abe8
	defb 008h	; abe9
	defb 011h	; abea
	defb 00ah	; abeb
	defb 009h	; abec
	defb 013h	; abed
	defb 005h	; abee
	defb 016h	; abef
	defb 00ch	; abf0
	defb 01ah	; abf1
	defb 000h	; abf2
	defb 016h	; abf3
	defb 004h	; abf4
	defb 03ah	; abf5
	defb 000h	; abf6
	defb 002h	; abf7
	defb 01ah	; abf8
	defb 014h	; abf9
	defb 006h	; abfa
	defb 021h	; abfb
	defb 00bh	; abfc
	defb 00ah	; abfd
	defb 014h	; abfe
	defb 013h	; abff
	defb 00dh	; ac00
	defb 008h	; ac01
	defb 018h	; ac02
	defb 00ch	; ac03
	defb 010h	; ac04
	defb 012h	; ac05
	defb 010h	; ac06
	defb 018h	; ac07
	defb 006h	; ac08
	defb 007h	; ac09
	defb 05ch	; ac0a
	defb 00eh	; ac0b
	defb 00ah	; ac0c
	defb 006h	; ac0d
	defb 008h	; ac0e
	defb 010h	; ac0f
	defb 000h	; ac10
	defb 014h	; ac11
	defb 00ah	; ac12
	defb 015h	; ac13
	defb 00bh	; ac14
	defb 011h	; ac15
	defb 002h	; ac16
	defb 01ch	; ac17
	defb 00dh	; ac18
	defb 010h	; ac19
	defb 00ch	; ac1a
	defb 010h	; ac1b
	defb 00eh	; ac1c
	defb 00ch	; ac1d
	defb 059h	; ac1e
	defb 01bh	; ac1f
	defb 01bh	; ac20
	defb 00ch	; ac21
	defb 002h	; ac22
	defb 005h	; ac23
	defb 00bh	; ac24
	defb 00dh	; ac25
	defb 014h	; ac26
	defb 00bh	; ac27
	defb 00ch	; ac28
	defb 000h	; ac29
	defb 036h	; ac2a
	defb 00bh	; ac2b
	defb 00bh	; ac2c
	defb 005h	; ac2d
	defb 003h	; ac2e
	defb 006h	; ac2f
	defb 007h	; ac30
	defb 009h	; ac31
	defb 005h	; ac32
	defb 003h	; ac33
	defb 006h	; ac34
	defb 016h	; ac35
	defb 004h	; ac36
	defb 004h	; ac37
	defb 000h	; ac38
	defb 00dh	; ac39
	defb 009h	; ac3a
	defb 004h	; ac3b
	defb 004h	; ac3c
	defb 018h	; ac3d
	defb 002h	; ac3e
	defb 004h	; ac3f
	defb 010h	; ac40
	defb 004h	; ac41
	defb 008h	; ac42
	defb 002h	; ac43
	defb 003h	; ac44
	defb 018h	; ac45
	defb 0ffh	; ac46

; ----------------------------------------------------------------------
; DATOS formaciones: 0xAA82 indexa aqui con el mismo contador: el nibble alto
;   elige la clase y el bajo, el recorrido
;   0xac47..0xacbc  (117 bytes)
DATA_formaciones:
	defb 000h	; ac47
	defb 000h	; ac48
	defb 0d1h	; ac49
	defb 0bah	; ac4a
	defb 0cah	; ac4b
	defb 0d1h	; ac4c
	defb 0d1h	; ac4d
	defb 0bah	; ac4e
	defb 0cah	; ac4f
	defb 0c1h	; ac50
	defb 0c1h	; ac51
	defb 0d1h	; ac52
	defb 0c1h	; ac53
	defb 0dah	; ac54
	defb 0b1h	; ac55
	defb 0c1h	; ac56
	defb 031h	; ac57
	defb 041h	; ac58
	defb 031h	; ac59
	defb 08ch	; ac5a
	defb 091h	; ac5b
	defb 051h	; ac5c
	defb 0b1h	; ac5d
	defb 08bh	; ac5e
	defb 071h	; ac5f
	defb 01ch	; ac60
	defb 051h	; ac61
	defb 061h	; ac62
	defb 031h	; ac63
	defb 0d1h	; ac64
	defb 0d1h	; ac65
	defb 011h	; ac66
	defb 031h	; ac67
	defb 09bh	; ac68
	defb 011h	; ac69
	defb 05ch	; ac6a
	defb 07ch	; ac6b
	defb 08ch	; ac6c
	defb 0abh	; ac6d
	defb 072h	; ac6e
	defb 082h	; ac6f
	defb 0a2h	; ac70
	defb 0a4h	; ac71
	defb 062h	; ac72
	defb 0a2h	; ac73
	defb 062h	; ac74
	defb 0d4h	; ac75
	defb 0b2h	; ac76
	defb 062h	; ac77
	defb 0c2h	; ac78
	defb 0a2h	; ac79
	defb 064h	; ac7a
	defb 054h	; ac7b
	defb 0a2h	; ac7c
	defb 05bh	; ac7d
	defb 022h	; ac7e
	defb 0dah	; ac7f
	defb 0cah	; ac80
	defb 03bh	; ac81
	defb 08ch	; ac82
	defb 042h	; ac83
	defb 034h	; ac84
	defb 044h	; ac85
	defb 014h	; ac86
	defb 084h	; ac87
	defb 0a2h	; ac88
	defb 042h	; ac89
	defb 0d4h	; ac8a
	defb 074h	; ac8b
	defb 042h	; ac8c
	defb 042h	; ac8d
	defb 092h	; ac8e
	defb 0d2h	; ac8f
	defb 0c2h	; ac90
	defb 034h	; ac91
	defb 0a4h	; ac92
	defb 034h	; ac93
	defb 033h	; ac94
	defb 03ah	; ac95
	defb 0dch	; ac96
	defb 0dch	; ac97
	defb 023h	; ac98
	defb 023h	; ac99
	defb 023h	; ac9a
	defb 023h	; ac9b
	defb 023h	; ac9c
	defb 054h	; ac9d
	defb 093h	; ac9e
	defb 033h	; ac9f
	defb 023h	; aca0
	defb 0a3h	; aca1
	defb 0d3h	; aca2
	defb 033h	; aca3
	defb 093h	; aca4
	defb 013h	; aca5
	defb 0ach	; aca6
	defb 0dch	; aca7
	defb 0c2h	; aca8
	defb 092h	; aca9
	defb 084h	; acaa
	defb 0c4h	; acab
	defb 04ah	; acac
	defb 09ah	; acad
	defb 084h	; acae
	defb 08ah	; acaf
	defb 0c4h	; acb0
	defb 044h	; acb1
	defb 0d3h	; acb2
	defb 0b2h	; acb3
	defb 044h	; acb4
	defb 0a4h	; acb5
	defb 0e4h	; acb6
	defb 084h	; acb7
	defb 043h	; acb8
	defb 024h	; acb9
	defb 033h	; acba
	defb 000h	; acbb

; ----------------------------------------------------------------------
; DATOS recorridos: Ocho grupos de tres bytes que 0xAAA8 reparte entre los
;   cinco enemigos grandes
;   0xacbc..0xaccb  (15 bytes)
DATA_recorridos:
	defb 000h,000h,000h	; acbc
	defb 001h,0c0h,080h	; acbf
	defb 002h,090h,060h	; acc2
	defb 003h,060h,040h	; acc5
	defb 004h,080h,080h	; acc8

; ----------------------------------------------------------------------
; DATOS tabla_de_dibujos_de_los_grandes: Doce punteros a los guiones de aqui
;   abajo, que 0xAA27 indexa con la clase del enemigo grande
;   0xaccb..0xace3  (24 bytes)
DATA_tabla_de_dibujos_de_los_grandes:
	defw 0ace1h,0ace9h,0acf1h,0acf9h,0ad01h,0ad0dh,0ad11h,0ad15h	; accb
	defw 0ad19h,0ad1dh,0ad21h,04b4ah	; acdb

; ----------------------------------------------------------------------
; DATOS dibujos_de_los_grandes: Los guiones de casillas de cada enemigo
;   grande: cuatro codigos por dibujo -dos arriba y dos abajo- que 0xAA53
;   escribe en el buffer de la pantalla. Un enemigo grande no cabe en un
;   sprite de 16x16, asi que se pinta con la tabla de nombres
;   0xace3..0xad25  (66 bytes)
DATA_dibujos_de_los_grandes:
	defb 04ch,04dh,046h,047h	; ace3
	defb 048h,049h,052h,053h	; ace7
	defb 054h,051h,04eh,04fh	; aceb
	defb 050h,051h,040h,044h	; acef
	defb 042h,045h,040h,041h	; acf3
	defb 042h,043h,072h,073h	; acf7
	defb 074h,075h,070h,071h	; acfb
	defb 074h,075h,03ch,03dh	; acff
	defb 03eh,03fh,068h,069h	; ad03
	defb 06ah,06bh,06ch,06dh	; ad07
	defb 06eh,06fh,055h,056h	; ad0b
	defb 057h,058h,059h,05ah	; ad0f
	defb 05bh,05ch,05dh,05eh	; ad13
	defb 05fh,060h,061h,062h	; ad17
	defb 063h,064h,065h,066h	; ad1b
	defb 061h,061h,067h,066h	; ad1f
	defb 061h,061h	; ad23

; ======================================================================
; CODIGO 0xad25..0xad60  (59 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LOS CATORCE ENEMIGOS. Cada uno ocupa 0x20 bytes desde 0xE160, y el byte 1 de su bloque dice QUE ES: ese numero entra en la tabla de cuarenta punteros de 0xAD60 y de ahi sale la rutina que lo mueve. Los valores 0xFF y 0xFE estan reservados -el primero apaga el hueco y el segundo lo deja quieto-, y por eso 0xAD42 y 0xAD51 hacen dos `inc a` antes de repartir.
; ----------------------------------------------------------------------
mueve_los_catorce:
	ld a,(0e155h)		;ad25   ; con la marca del jefe puesta, se atiende al jefe
	rra			;ad28
	jp c,L_ADB0		;ad29
	ld ix,0e160h		;ad2c   ; los catorce huecos
	ld b,00eh		;ad30   ; de 0x20 bytes cada uno
L_AD32:
	push bc			;ad32
	push ix		;ad33
	ld a,(ix+000h)		;ad35   ; su clase
	ld c,a			;ad38
	and a			;ad39   ; hueco vacio, nada
	jr z,L_AD46		;ad3a
	ld a,(ix+001h)		;ad3c   ; y su comportamiento
	and a			;ad3f
	jr z,L_AD46		;ad40
	inc a			;ad42   ; 0xFF quiere decir quieto
	call nz,le_toca_a_este_enemigo		;ad43
L_AD46:
	pop ix		;ad46   ; 0x20 bytes hasta el enemigo siguiente
	ld de,00020h		;ad48
	add ix,de		;ad4b
	pop bc			;ad4d
	djnz L_AD32		;ad4e
	ret			;ad50
le_toca_a_este_enemigo:
	inc a			;ad51   ; y 0xFE, que se esta muriendo
	jp z,revienta_el_enemigo		;ad52
	inc (ix+010h)		;ad55   ; un cuadro mas de vida
	call cuenta_para_disparar		;ad58   ; se coloca
	ld a,c			;ad5b
	dec a			;ad5c
	call reparte_por_tabla		;ad5d   ; y se le da su vuelta

; ----------------------------------------------------------------------
; DATOS tabla_de_los_cuarenta_enemigos: Los cuarenta comportamientos que
;   reparte el `call 40ABh` de 0xAD5D, con (ix+1) de indice
;   0xad60..0xadb0  (80 bytes)
DATA_tabla_de_los_cuarenta_enemigos:
	defw 0b454h,0b47ah,0b7f4h,0b244h,0b391h,0b672h,0b292h,0b3c0h	; ad60
	defw 0b15dh,0b493h,0b6e6h,0b02ah,0b155h,0b074h,0b09dh,0b320h	; ad70
	defw 0b1a3h,0b329h,0b211h,0b340h,0b41fh,0b368h,0b5ceh,0b7a4h	; ad80
	defw 0b81dh,0b1e6h,0b44bh,0b4eah,0b5b2h,0b0dch,0b7eah,0b7adh	; ad90
	defw 0afd0h,0b509h,0b56eh,0b527h,0b443h,0b7d2h,0b548h,0aff4h	; ada0

; ======================================================================
; CODIGO 0xadb0..0xadcc  (28 bytes)
; ======================================================================


L_ADB0:
	ld ix,0e320h		;adb0   ; el jefe tiene su propio bloque
	ld a,(ix+001h)		;adb4
	inc a			;adb7
	ret z			;adb8
	inc a			;adb9
	jr z,$+28		;adba
	inc (ix+010h)		;adbc
	ld a,(0e07eh)		;adbf   ; de la fase 2 en adelante se mueve
	and a			;adc2
	call nz,cuenta_para_disparar		;adc3
	call la_fase_de_uno_a_cinco		;adc6
	call reparte_por_tabla		;adc9   ; y su comportamiento, de cinco

; ----------------------------------------------------------------------
; DATOS tabla_de_los_cinco_jefes: Los cinco del `call 40ABh` de 0xADC9
;   0xadcc..0xadd6  (10 bytes)
DATA_tabla_de_los_cinco_jefes:
	defw 0b108h,0b2ech,0b3e9h,0b4c1h,0b780h	; adcc

; ======================================================================
; CODIGO 0xadd6..0xae89  (179 bytes)
; ======================================================================


acaba_la_fase:
	ld hl,0e160h		;add6   ; los catorce enemigos
	ld de,0e161h		;add9
	xor a			;addc
	ld (hl),a			;addd
	ld bc,001bfh		;adde   ; se borran de golpe: 0x1C0 bytes
	ldir		;ade1
	ld (ix+016h),a		;ade3
	bit 2,(ix+014h)		;ade6   ; el bit 2 del estado del jefe
	jr z,L_ADED		;adea
	inc a			;adec
L_ADED:
	ld (ix+00ah),a		;aded   ; el dibujo que toca
	dec (ix+014h)		;adf0   ; la cuenta del jefe
	jr nz,L_AE31		;adf3   ; mientras dure, nada
	ld hl,0e155h		;adf5   ; y al acabarse, la marca del jefe se apaga
	xor a			;adf8   ; se borra el estado
	ld (hl),a			;adf9
	ld de,0e156h		;adfa   ; y de ahi arrastra el resto
	ld c,00ah		;adfd   ; once bytes en total
	ldir		;adff
	ld (0e151h),a		;ae01   ; la marca de jefe en pantalla
	ld hl,0e321h		;ae04
	ld (hl),a			;ae07   ; su estado
	inc l			;ae08
	inc l			;ae09
	ld (hl),a			;ae0a   ; su paso
	inc l			;ae0b
	ld (hl),a			;ae0c
	inc l			;ae0d
	call borra_cuatro		;ae0e   ; se limpian sus disparos
	ld (ix+007h),0e0h		;ae11   ; y su sprite se aparta
	inc a			;ae15   ; uno
	ld (0e07ch),a		;ae16   ; la cuenta del final de fase
	ld a,(0e07dh)		;ae19   ; de la fase 0x10 en adelante
	cp 010h		;ae1c   ; la mitad del recorrido
	ld a,030h		;ae1e   ; la espera baja a la mitad
	jr c,L_AE23		;ae20
	rrca			;ae22
L_AE23:
	ld (ix+00eh),a		;ae23
	ld (ix+00fh),a		;ae26
	ld (ix+014h),028h		;ae29   ; y 0x28 cuadros de aviso
	ld (ix+015h),028h		;ae2d
L_AE31:
	call apaga_todos_los_enemigos		;ae31
	jp coloca_al_jefe		;ae34
saca_los_disparos_del_jefe:
	ld a,(0e155h)		;ae37
	and 002h		;ae3a   ; el bit 1 del estado del jefe
	ret z			;ae3c
	ld de,0e158h		;ae3d   ; cuantos disparos lleva
	ld b,007h		;ae40   ; siete huecos
	ld a,(de)			;ae42
	cp b			;ae43   ; con siete ya no caben mas
	jr nc,mueve_los_disparos_del_jefe		;ae44
	ld ix,0e160h		;ae46   ; la tabla de disparos del jefe
	ld hl,0e157h		;ae4a   ; la cuenta que decide cuando sale otro
	inc (hl)			;ae4d   ; la cuenta del destello
	push hl			;ae4e
	call la_fase_de_uno_a_cinco		;ae4f   ; la fase, de 1 a 5
	ld hl,0ae89h		;ae52   ; y lo que dura cada uno
	call suma_a_a_hl		;ae55   ; se indexa por fase
	ld b,(hl)			;ae58   ; la espera de esta fase
	pop hl			;ae59
	ld a,(hl)			;ae5a
	sub b			;ae5b   ; todavia no toca
	jr nz,mueve_los_disparos_del_jefe		;ae5c
	ld (hl),a			;ae5e   ; la cuenta vuelve a cero
	ld h,a			;ae5f   ; y H tambien
	ld a,(de)			;ae60   ; el hueco que toca, por 0x20
	ld l,a			;ae61
	add hl,hl			;ae62   ; por dos
	add hl,hl			;ae63   ; por cuatro
	add hl,hl			;ae64   ; por ocho
	add hl,hl			;ae65   ; por dieciseis
	add hl,hl			;ae66   ; por treinta y dos
	ex de,hl			;ae67
	add ix,de		;ae68   ; al hueco que toca
	ld (ix+001h),000h		;ae6a   ; y ahi nace
	inc (hl)			;ae6e   ; un disparo mas en el aire
	call pon_la_espera_de_disparo		;ae6f
mueve_los_disparos_del_jefe:
	ld b,007h		;ae72   ; los siete disparos
	ld ix,0e160h		;ae74
L_AE78:
	push bc			;ae78
	ld a,(ix+001h)		;ae79   ; el segundo byte dice si vuela
	inc a			;ae7c   ; hueco vacio, se salta
	call nz,mueve_un_disparo_del_jefe		;ae7d
	ld de,00020h		;ae80
	add ix,de		;ae83
	pop bc			;ae85
	djnz L_AE78		;ae86
	ret			;ae88

; ----------------------------------------------------------------------
; DATOS duracion_del_destello: Cinco valores que 0xAE53 indexa con 0x406A
;   0xae89..0xae8e  (5 bytes)
DATA_duracion_del_destello:
	defb 004h	; ae89
	defb 00ch	; ae8a
	defb 010h	; ae8b
	defb 004h	; ae8c
	defb 00ch	; ae8d

; ======================================================================
; CODIGO 0xae8e..0xae9e  (16 bytes)
; ======================================================================


mueve_un_disparo_del_jefe:
	inc (ix+010h)		;ae8e   ; un cuadro mas
	ld a,(ix+001h)		;ae91
	inc a			;ae94
	inc a			;ae95
	jr z,$+43		;ae96   ; 0xFE quiere decir que se esta apagando
	call la_fase_de_uno_a_cinco		;ae98
	call reparte_por_tabla		;ae9b

; ----------------------------------------------------------------------
; DATOS tabla_de_los_cinco_disparos: Los cinco del `call 40ABh` de 0xAE9B
;   0xae9e..0xaea8  (10 bytes)
DATA_tabla_de_los_cinco_disparos:
	defw 0b15dh,0b292h,0b3c0h,0b493h,0b6e6h	; ae9e

; ======================================================================
; CODIGO 0xaea8..0xb2e4  (1084 bytes)
; ======================================================================


cuenta_para_disparar:
	ld a,(ix+00fh)		;aea8   ; la cuenta hasta el proximo disparo
	and a			;aeab
	ret z			;aeac
	dec (ix+00fh)		;aead   ; una menos
	push bc			;aeb0
	push ix		;aeb1
	call z,recarga_la_espera		;aeb3   ; y al llegar a cero, dispara
	pop ix		;aeb6
	pop bc			;aeb8
	ret			;aeb9
la_fase_de_uno_a_cinco:
	ld a,(0e076h)		;aeba   ; la fase, de 1 a 5, sin la vuelta
	and 00fh		;aebd
	dec a			;aebf
	ret			;aec0
revienta_el_enemigo:
	ld (ix+016h),000h		;aec1   ; el dibujo de la explosion
	ld a,(ix+014h)		;aec5
	and 002h		;aec8
	ld b,034h		;aeca   ; alternando dos
	jr z,L_AED0		;aecc
	ld b,038h		;aece
L_AED0:
	ld c,00fh		;aed0
	call pon_el_dibujo		;aed2
	dec (ix+014h)		;aed5   ; mientras dure
	ret nz			;aed8
	jr apaga_el_enemigo		;aed9
apaga_ese_enemigo:
	push hl			;aedb
	pop ix		;aedc
apaga_el_enemigo:
	ld b,020h		;aede   ; los 0x20 bytes del hueco
	push ix		;aee0
	pop hl			;aee2
	ld a,(hl)			;aee3
L_AEE4:
	ld (hl),000h		;aee4   ; a cero
	inc l			;aee6
	djnz L_AEE4		;aee7
	sub 007h		;aee9   ; las clases 7 a 0x0B se quedan quietas
	cp 005h		;aeeb
	jr c,L_AEF3		;aeed
	ld (ix+001h),0ffh		;aeef   ; y las demas se apagan del todo
L_AEF3:
	ld (ix+007h),0e0h		;aef3   ; sprite fuera
	ld (ix+014h),008h		;aef7
	ret			;aefb
recarga_la_espera:
	ld a,(ix+000h)		;aefc   ; la clase 0x21 no recarga
	cp 021h		;aeff
	ret z			;af01
	ld a,(ix+00eh)		;af02   ; y las demas vuelven a su espera
	ld (ix+00fh),a		;af05
dispara_el_enemigo:
	ld a,(0e07eh)		;af08
	and a			;af0b   ; en la fase 1
	jr nz,L_AF16		;af0c
	ld hl,(0ebf0h)		;af0e   ; no se dispara hasta pasada la fila 0x60
	ld de,00060h		;af11
	rst 20h			;af14
	ret c			;af15
L_AF16:
	ld d,(ix+009h)		;af16   ; donde esta el enemigo
	ld e,(ix+007h)		;af19
busca_hueco_de_disparo:
	ld ix,0e240h		;af1c   ; los siete disparos del enemigo
	ld h,007h		;af20
L_AF22:
	ld a,(ix+001h)		;af22
	inc a			;af25   ; se busca uno libre
	jr z,L_AF31		;af26
	ld bc,00020h		;af28
	add ix,bc		;af2b
	dec h			;af2d
	jr nz,L_AF22		;af2e
	ret			;af30
L_AF31:
	call apunta_a_la_nave		;af31   ; y se apunta
	ld a,(ix+001h)		;af34   ; el segundo byte: si esta vivo
	and a			;af37
	ret nz			;af38
	ld bc,06c0ah		;af39   ; con su dibujo
	call pon_el_dibujo		;af3c
	ld (ix+000h),a		;af3f   ; y el hueco queda ocupado
	call apunta_y_avanza		;af42
	call al_paso_siguiente		;af45
	ld a,(0e076h)		;af48   ; la fase
	cp 003h		;af4b   ; en las fases 1 y 2
	ret nc			;af4d
	ld a,(ix+003h)		;af4e   ; los enemigos con el bit 7 se apagan al disparar
	rla			;af51   ; el bit 7 al acarreo
	ret nc			;af52
	jp apaga_el_enemigo		;af53
apunta_a_la_nave:
	call donde_esta_la_nave_uno		;af56   ; donde esta la nave 1
	call esta_cerca		;af59   ; si esta cerca, se le dispara
	ret c			;af5c
	call es_el_segundo_jugador		;af5d
	jr z,L_AF69		;af60
	call donde_esta_la_nave_dos		;af62   ; y si no, se prueba con la 2
	call esta_cerca		;af65
	ret c			;af68
L_AF69:
	ld (ix+001h),000h		;af69
	ld b,e			;af6d
	ld c,d			;af6e
	call pon_la_posicion		;af6f   ; el rumbo hacia la nave
	call elige_a_quien_apuntar		;af72

; ----------------------------------------------------------------------
; EL AZAR SALE DEL REGISTRO R. El Z80 lleva un contador de refresco que avanza con cada instruccion, y este cartucho lo usa de dado en cinco sitios -aqui, en 0xB2CE, 0xB757, 0xBE0C y 0xBE36-. Aqui desvia el disparo del enemigo unos grados a un lado o a otro: el `add a,a` y el `sra a` dejan el valor entre -64 y +63.
; ----------------------------------------------------------------------
	ld a,r		;af75   ; el refresco del Z80, que es lo mas parecido a un dado que hay aqui
	add a,a			;af77   ; doblado y con signo
	sra a		;af78
	add a,(ix+013h)		;af7a   ; se le suma al rumbo
	ld (ix+013h),a		;af7d
	ret			;af80
esta_cerca:
	ld a,e			;af81   ; 0x20 arriba y 0x20 abajo: 0x40 de margen
	add a,020h		;af82
	sub l			;af84
	cp 040h		;af85
	ret nc			;af87
	ld a,d			;af88
	add a,020h		;af89
	sub h			;af8b
	cp 040h		;af8c
	ret			;af8e
pon_el_dibujo:
	ld (ix+00ah),b		;af8f
	ld (ix+00bh),c		;af92
	ret			;af95

; ----------------------------------------------------------------------
; EL BLOQUE DE UN ENEMIGO. Son 0x20 bytes desde 0xE160, y siempre los mismos: (ix+0) el dibujo, (ix+1) la clase -que es el indice en la tabla de cuarenta-, (ix+2,3) la velocidad vertical y (ix+4,5) la horizontal, (ix+6,7) la posicion vertical con su parte fraccionaria y (ix+8,9) la horizontal, (ix+10,11) el patron y el color del sprite, (ix+14) la espera entre disparos, (ix+16) el contador de cuadros y (ix+19) el rumbo en la circunferencia de 256 grados.
; ----------------------------------------------------------------------
mueve_los_enemigos:
	ld b,00eh		;af96   ; los catorce
	ld ix,0e160h		;af98
L_AF9C:
	ld a,(ix+001h)		;af9c
	and a			;af9f   ; hueco vacio, nada
	jr z,L_AFA6		;afa0
	inc a			;afa2   ; y 0xFF quiere decir quieto
	call nz,mueve_uno		;afa3
L_AFA6:
	ld de,00020h		;afa6
	add ix,de		;afa9
	djnz L_AF9C		;afab
	ret			;afad
mueve_uno:
	push ix		;afae
	call suma_la_velocidad		;afb0   ; la vertical
	inc ix		;afb3
	inc ix		;afb5
	call suma_la_velocidad		;afb7   ; y la horizontal, dos bytes mas alla
	pop ix		;afba
	ret			;afbc
suma_la_velocidad:
	ld a,(ix+002h)		;afbd   ; la velocidad se suma con su fraccion
	add a,(ix+006h)		;afc0
	ld (ix+006h),a		;afc3
	ld a,(ix+003h)		;afc6
	adc a,(ix+007h)		;afc9
	ld (ix+007h),a		;afcc
	ret			;afcf

; ----------------------------------------------------------------------
; LOS CUARENTA COMPORTAMIENTOS. La tabla de 0xAD60 reparte por (ix+1), y cada rutina es un enemigo distinto: por donde entra, como se mueve y cuando dispara. Cinco de ellas hacen doble papel -son tambien los disparos del jefe, que la tabla de 0xAE9E vuelve a nombrar-, y las cinco de 0xADCC son los jefes de fase. Aqui van bautizadas por su numero en la tabla, que es lo unico que se puede afirmar sin jugarse cada una: el comportamiento concreto se lee en su codigo.
; ----------------------------------------------------------------------
comportamiento_32:
	ld bc,03c40h		;afd0   ; rebota en el borde de abajo
	ld e,00ah		;afd3
	call alterna_cada_ocho		;afd5
L_AFD8:
	ld a,(ix+007h)		;afd8
	sub 0afh		;afdb
	cp 010h		;afdd
	jr nc,L_AFE9		;afdf
	ld a,(ix+003h)		;afe1
	neg		;afe4   ; cambiando el signo de la velocidad
	ld (ix+003h),a		;afe6
L_AFE9:
	ld a,(ix+009h)		;afe9   ; y fuera de la pantalla, se apaga
	sub 008h		;afec
	cp 0e0h		;afee
	ret c			;aff0
	jp L_B337		;aff1
comportamiento_39:
	ld bc,0989ch		;aff4   ; el dibujo, alternando cada cuatro
	ld e,008h		;aff7
	call alterna_cada_cuatro		;aff9
	ld b,(ix+001h)		;affc
	djnz L_B00C		;afff
	ld a,(ix+007h)		;b001
	cp 010h		;b004
	ret nc			;b006
	call apunta_y_arranca		;b007
	jr al_paso_siguiente		;b00a
L_B00C:
	djnz L_B017		;b00c
	ld a,(ix+010h)		;b00e
	cp 018h		;b011
	ret c			;b013
	jp cambia_el_sentido_vertical		;b014
L_B017:
	dec b			;b017
	ret nz			;b018
	ld a,(ix+010h)		;b019   ; en el cuadro 0x18
	cp 018h		;b01c
	ret c			;b01e
	call apunta_y_arranca		;b01f   ; apunta y arranca
al_paso_siguiente:		; Pone el contador a cero y sube (ix+1)
	ld (ix+010h),000h		;b022   ; el contador, a cero
	inc (ix+001h)		;b026   ; y al paso siguiente
	ret			;b029
comportamiento_11:
	ld bc,0b008h		;b02a   ; los dos codigos del dibujo
	call pon_el_dibujo		;b02d   ; el dibujo
	ld b,(ix+001h)		;b030   ; el paso
	djnz L_B04B		;b033   ; paso 2 para abajo
	ld a,(ix+011h)		;b035   ; el bit 0 de sus banderas
	rra			;b038
	ld b,008h		;b039   ; ocho pixeles a un lado
	call nc,niega_bc		;b03b   ; o al otro
	ld a,(ix+013h)		;b03e   ; lo que le falta para la nave
	add a,b			;b041   ; con ese desvio
	sub (ix+009h)		;b042
	cp 004h		;b045   ; con cuatro pixeles de margen
	ret nc			;b047   ; fuera del margen, todavia no
	jp L_B5C8		;b048   ; y dentro, dispara
L_B04B:
	djnz L_B067		;b04b   ; paso 3 para abajo
	ld a,(ix+011h)		;b04d   ; el bit 0 de sus banderas
	and a			;b050
	ld b,0fdh		;b051   ; y va a un lado o al otro
	call nz,niega_bc		;b053
	ld (ix+005h),b		;b056   ; esa es su velocidad horizontal
	xor a			;b059   ; sin velocidad vertical: se queda a esa altura
	ld h,a			;b05a
	ld l,a			;b05b
	call pon_la_vertical		;b05c
	ld a,(ix+010h)		;b05f   ; y en el cuadro 0x0C
	cp 00ch		;b062
	ret nz			;b064
	jr al_paso_siguiente		;b065
L_B067:
	dec b			;b067   ; paso 3
	ret nz			;b068
	call baja_veinte		;b069   ; se lanza
	ld a,(ix+010h)		;b06c
	cp 018h		;b06f
	ret nz			;b071
L_B072:
	jr al_paso_siguiente		;b072
comportamiento_13:
	ld bc,0c0c4h		;b074   ; los dos dibujos, alternando cada ocho
	ld e,00dh		;b077
	call alterna_cada_ocho		;b079
L_B07C:
	ld b,(ix+001h)		;b07c   ; el paso
	djnz L_B08D		;b07f   ; paso 2 para abajo
	ld a,(ix+007h)		;b081   ; y a la altura que le toca
	add a,028h		;b084   ; 0x28 pixeles de adelanto
	sub (ix+012h)		;b086   ; contra la altura de destino
	ret c			;b089   ; antes de llegar, nada
	jp L_B5C8		;b08a   ; y al llegar, dispara
L_B08D:
	dec b			;b08d   ; segundo paso
	ret nz			;b08e
	ld de,00030h		;b08f   ; baja 0x30
	call baja_lo_que_diga_de		;b092
	ld a,(ix+010h)		;b095   ; su contador
	cp 030h		;b098   ; y en el cuadro 0x30, al paso siguiente
	ret nz			;b09a
	jr L_B072		;b09b
comportamiento_14:
	ld bc,0bc03h		;b09d   ; el dibujo
	call pon_el_dibujo		;b0a0
	ld b,(ix+001h)		;b0a3   ; el paso
	djnz L_B0B9		;b0a6   ; paso 2 para abajo
	ld a,(ix+007h)		;b0a8   ; por debajo de la fila 0x30
	cp 030h		;b0ab   ; antes de la fila 0x30 no hace nada
	ret c			;b0ad
	ld a,(ix+013h)		;b0ae   ; y con la nave a menos de ocho pixeles
	sub (ix+009h)		;b0b1   ; menos donde esta
	cp 008h		;b0b4
	ret nc			;b0b6   ; fuera de esos ocho, tampoco
L_B0B7:
	jr L_B072		;b0b7
L_B0B9:
	dec b			;b0b9   ; segundo paso
	ret nz			;b0ba
	ld a,(ix+012h)		;b0bb   ; el bit 0 de sus banderas
	rra			;b0be   ; el bit 0 de su segunda bandera
	ld bc,00030h		;b0bf   ; 0x30 de paso
	jr nc,L_B0C9		;b0c2
	call va_a_la_derecha_deprisa		;b0c4   ; a la derecha, deprisa
	jr L_B0CE		;b0c7
L_B0C9:
	ld e,c			;b0c9
	ld d,b			;b0ca
	call va_a_la_izquierda		;b0cb   ; o a la izquierda
L_B0CE:
	ld de,00030h		;b0ce   ; baja 0x30
	call baja_lo_que_diga_de		;b0d1
	ld a,(ix+010h)		;b0d4   ; y en el cuadro 0x28
	cp 028h		;b0d7
	ret nz			;b0d9
	jr L_B0B7		;b0da
comportamiento_29:
	ld bc,0c803h		;b0dc
	call pon_el_dibujo		;b0df   ; el dibujo
	ld b,(ix+001h)		;b0e2   ; el paso
	djnz L_B105		;b0e5   ; paso 2 para abajo
	call acerca_en_horizontal		;b0e7   ; se acerca en horizontal
	ld a,(ix+007h)		;b0ea   ; por debajo del borde
	cp 0e0h		;b0ed   ; por debajo de 0xE0 no cuenta
	ret nc			;b0ef
	cp 038h		;b0f0   ; o por encima de la fila 0x38
	ret c			;b0f2
	ld de,00140h		;b0f3   ; sale hacia abajo
	ld bc,00400h		;b0f6   ; con velocidad 0x0140 y 0x0400
	ld a,(ix+009h)		;b0f9   ; por el lado que le toque
	rla			;b0fc   ; el bit 7 dice de que lado esta
	call c,niega_bc		;b0fd
	call pon_las_dos_velocidades		;b100
L_B103:
	jr L_B0B7		;b103
L_B105:
	jp acerca_en_horizontal		;b105   ; y en el segundo paso, solo persigue
jefe_de_la_fase_1:
	ld b,(ix+001h)		;b108
	djnz L_B11B		;b10b   ; paso 2 para abajo
L_B10D:
	inc (ix+007h)		;b10d   ; el jefe baja un pixel por cuadro
	ld a,(ix+007h)		;b110
	cp 024h		;b113   ; hasta la fila 0x24
	call z,al_paso_siguiente		;b115   ; y ahi pasa al paso siguiente
	jp coloca_al_jefe		;b118   ; y se dibuja
L_B11B:
	djnz L_B13A		;b11b   ; paso 3 para abajo
	ld de,00018h		;b11d   ; velocidad de entrada 0x0018 y 0x0300
	ld bc,00300h		;b120
	call pon_las_dos_velocidades		;b123
L_B126:
	ld de,03480h		;b126   ; y su destino, la fila 0x34 columna 0x80
pon_el_destino_del_jefe:
	ld (ix+00ch),d		;b129   ; a donde va el jefe
	ld (ix+00dh),e		;b12c   ; el destino horizontal
	ld hl,0e155h		;b12f   ; y la marca de que dispara
	set 1,(hl)		;b132
	ld (ix+016h),001h		;b134   ; y se pone a repartir disparos
	jr L_B103		;b138
L_B13A:
	djnz L_B14D		;b13a   ; paso 3 para abajo
	call acerca_en_horizontal		;b13c
	ld c,002h		;b13f   ; con la vertical dividida entre cuatro: mas suave
	call acerca_en_vertical		;b141
L_B144:
	call mueve_uno		;b144   ; se mueve
	call coloca_al_jefe		;b147   ; se dibuja
	jp saca_los_disparos_del_jefe		;b14a   ; y suelta sus disparos
L_B14D:
	ld bc,0e080h		;b14d   ; en el ultimo paso se aparta a la esquina
	call pon_la_posicion		;b150
L_B153:
	jr L_B103		;b153
comportamiento_12:
	ld bc,0b4b8h		;b155   ; los dos dibujos, alternando cada cuatro
	ld e,00fh		;b158
	jp alterna_cada_cuatro		;b15a
comportamiento_8:		; Tambien es disparo del jefe de la fase 1
	ld (ix+000h),009h		;b15d
	ld b,(ix+001h)		;b161   ; el paso
	djnz L_B19D		;b164   ; paso 2 para abajo
apunta_al_jefe:
	ld a,(0e327h)		;b166   ; donde esta el jefe
	sub 008h		;b169   ; ocho pixeles arriba
	ld (ix+00ch),a		;b16b   ; el destino vertical
	ld a,(0e329h)		;b16e
	sub 008h		;b171   ; y ocho a la izquierda
	ld (ix+00dh),a		;b173
	ld (ix+00bh),00fh		;b176   ; el disparo, en blanco
	ld (ix+016h),001h		;b17a   ; y se pone a moverse
	ld de,00a03h		;b17e   ; con velocidad 0x0A03
	call velocidad_por_el_angulo		;b181   ; el rumbo se convierte en posicion
	ld a,(0e07eh)		;b184   ; la vuelta
	and a			;b187
	ld b,01fh		;b188
	jr z,L_B18E		;b18a
	ld b,00fh		;b18c   ; en la segunda y siguientes, el doble de a menudo
L_B18E:
	inc (ix+00fh)		;b18e   ; la cuenta del disparo
	ld a,(ix+00fh)		;b191   ; la cuenta
	and b			;b194   ; y cada 0x1F -o 0x0F- cuadros, uno
	push ix		;b195   ; el bloque, a salvo del `call`
	call z,dispara_el_enemigo		;b197
	pop ix		;b19a
	ret			;b19c
L_B19D:
	ld (ix+00ah),0e0h		;b19d   ; y en el ultimo paso, el sprite fuera
	jr L_B153		;b1a1
comportamiento_16:
	ld bc,0d0d4h		;b1a3   ; el dibujo, alternando cada cuatro
	ld e,00fh		;b1a6
	call pon_el_dibujo_y_el_paso		;b1a8   ; y el paso, en B
	djnz L_B1B8		;b1ab   ; paso 2 para abajo
	ld a,(ix+007h)		;b1ad   ; la vertical
	sub 020h		;b1b0   ; contra la fila 0x20
	cp 008h		;b1b2
	ret nc			;b1b4   ; fuera de esos ocho pixeles, nada
	jp L_B5C8		;b1b5
L_B1B8:
	djnz L_B1C8		;b1b8   ; paso 3 para abajo
cambia_el_sentido_vertical:
	ld l,(ix+002h)		;b1ba
	ld h,(ix+003h)		;b1bd   ; la velocidad vertical
	call niega_hl		;b1c0   ; cambiada de signo: sube
	call pon_la_vertical		;b1c3
	jr L_B1E3		;b1c6
L_B1C8:
	dec b			;b1c8   ; tercer paso: baja 0x68
	ret nz			;b1c9
	ld de,00068h		;b1ca
	call suma_a_la_vertical		;b1cd   ; se le suma de golpe
	ld bc,0000ch		;b1d0   ; y se va de lado
	ld a,(ix+011h)		;b1d3
	rra			;b1d6   ; al lado que le toque
	call c,niega_bc		;b1d7
	call suma_a_la_horizontal		;b1da
	ld a,(ix+010h)		;b1dd   ; su contador
	cp 018h		;b1e0   ; y a los 0x18 cuadros, al paso siguiente
	ret c			;b1e2
L_B1E3:
	jp al_paso_siguiente		;b1e3
comportamiento_25:
	ld bc,0bc07h		;b1e6   ; los dos dibujos
	ld a,(ix+001h)		;b1e9
	cp 002h		;b1ec   ; en el paso 2
	jr nz,L_B1F3		;b1ee
	ld bc,0c00fh		;b1f0   ; cambia a otro par
L_B1F3:
	call pon_el_dibujo		;b1f3
L_B1F6:
	ld b,(ix+001h)		;b1f6
	dec b			;b1f9   ; solo hace algo en el paso 1
	ret nz			;b1fa
L_B1FB:
	ld a,(ix+012h)		;b1fb   ; donde quiere estar
	ld b,(ix+007h)		;b1fe   ; donde esta
	sub b			;b201
	cp 008h		;b202   ; con ocho pixeles de margen
	ret nc			;b204
	xor a			;b205   ; se para en seco
	ld h,a			;b206
	ld l,a			;b207
	call pon_la_horizontal		;b208
	call cambia_el_sentido_vertical		;b20b   ; da la vuelta en vertical
	jp dispara_el_enemigo		;b20e
comportamiento_18:
	ld bc,0b4b8h		;b211   ; el dibujo, alternando cada cuatro
	ld e,003h		;b214
	call pon_el_dibujo_y_el_paso		;b216   ; el dibujo y el paso
	djnz L_B22B		;b219   ; paso 2 para abajo
	ld a,(ix+009h)		;b21b
	sub (ix+013h)		;b21e   ; menos el destino
	cp 008h		;b221   ; con ocho pixeles de margen, se para
	jr c,L_B1E3		;b223
	ld de,0ffd0h		;b225   ; y si no, sube 0x30
	jp suma_a_la_vertical		;b228   ; de golpe
L_B22B:
	djnz L_B238		;b22b   ; paso 3 para abajo
	ld de,00000h		;b22d   ; se para en vertical
	ld bc,00300h		;b230
	call pon_las_dos_velocidades		;b233   ; y se va de lado
L_B236:
	jr L_B1E3		;b236
L_B238:
	ld de,00040h		;b238   ; luego baja 0x40
	call suma_a_la_vertical		;b23b   ; de golpe
	ld bc,0ffd0h		;b23e   ; y se va hacia la izquierda
	jp suma_a_la_horizontal		;b241
comportamiento_3:
	ld bc,0c4c8h		;b244   ; el dibujo, alternando cada cuatro
	ld e,00fh		;b247
	call alterna_cada_cuatro		;b249
	ld b,(ix+001h)		;b24c   ; el paso
	djnz L_B25B		;b24f   ; paso 2 para abajo
	ld a,(ix+007h)		;b251   ; la vertical
	sub 030h		;b254   ; contra la fila 0x30
	cp 010h		;b256
	ret nc			;b258   ; fuera de esos 0x10 pixeles, nada
	jr L_B236		;b259
L_B25B:
	dec b			;b25b   ; paso 2
	ret nz			;b25c
	push ix		;b25d   ; dispara
	call dispara_el_enemigo		;b25f
	pop ix		;b262   ; el bloque, de vuelta
	call al_paso_siguiente		;b264   ; y al paso siguiente
	call cuenta_de_enemigo		;b267   ; el dado barato
	and 003h		;b26a   ; dos bits: cuatro salidas
	ld l,(ix+004h)		;b26c   ; la velocidad horizontal
	ld h,(ix+005h)		;b26f
	jr z,L_B27E		;b272   ; con 0, a la mitad de velocidad
	dec a			;b274
	jr z,L_B285		;b275   ; con 1, se frena en vertical
	dec a			;b277
	ret z			;b278   ; con 2, no cambia nada
	call niega_hl		;b279   ; y con 3 da la vuelta
	jr L_B282		;b27c
L_B27E:
	sra h		;b27e   ; `sra` conserva el signo
	rr l		;b280
L_B282:
	jp pon_la_horizontal		;b282
L_B285:
	ld l,(ix+002h)		;b285   ; la velocidad vertical
	ld h,(ix+003h)		;b288
	sra h		;b28b   ; a la mitad
	rr l		;b28d
	jp pon_la_vertical		;b28f
comportamiento_6:		; Tambien es disparo del jefe de la fase 2
	ld (ix+000h),007h		;b292   ; el dibujo del disparo
	ld b,(ix+001h)		;b296   ; el paso
	djnz L_B2B5		;b299   ; paso 2 para abajo
	ld bc,0e003h		;b29b   ; con su dibujo
	call pon_el_dibujo		;b29e
	call cuanto_tarda_en_saltar		;b2a1
	cp b			;b2a4   ; antes de la cuenta, nada
	ret c			;b2a5
L_B2A6:
	jr L_B236		;b2a6
cuanto_tarda_en_saltar:
	ld a,(0e07eh)		;b2a8   ; la vuelta
	and a			;b2ab   ; en la primera vuelta tarda 0x10 cuadros
	ld a,(ix+010h)		;b2ac   ; su contador
	ld b,010h		;b2af
	ret z			;b2b1
	ld b,00ah		;b2b2   ; y en las siguientes, 0x0A
	ret			;b2b4
L_B2B5:
	djnz L_B2C6		;b2b5   ; paso 2
	ld (ix+00ah),0e4h		;b2b7   ; con su dibujo
	call cuanto_tarda_en_saltar		;b2bb
	cp b			;b2be   ; contra la cuenta que toque
	ret c			;b2bf
	ld (ix+016h),001h		;b2c0   ; y se pone a moverse
	jr L_B2A6		;b2c4
L_B2C6:
	djnz L_B2CE		;b2c6   ; paso 3 para abajo
	ld bc,0e80fh		;b2c8   ; con el tercer dibujo
	jp pon_el_dibujo		;b2cb
L_B2CE:
	ld a,r		;b2ce   ; el refresco del Z80, de dado
	ld (ix+007h),a		;b2d0   ; y con el sale a una altura al azar
	and 007h		;b2d3   ; tres bits: ocho rumbos
	ld hl,0b2e4h		;b2d5
	call suma_a_a_hl		;b2d8   ; la tabla de rumbos
	ld a,(hl)			;b2db
	ld (ix+009h),a		;b2dc   ; y ese es su angulo de salida
	call apunta_y_arranca		;b2df   ; apunta y arranca
	jr L_B2A6		;b2e2

; ----------------------------------------------------------------------
; DATOS ocho_rumbos: 0xB2D5 indexa con los tres bits bajos de A: el angulo con
;   el que sale el enemigo
;   0xb2e4..0xb2ec  (8 bytes)
DATA_ocho_rumbos:
	defb 0c0h	; b2e4
	defb 060h	; b2e5
	defb 080h	; b2e6
	defb 020h	; b2e7
	defb 0a0h	; b2e8
	defb 040h	; b2e9
	defb 080h	; b2ea
	defb 0e0h	; b2eb

; ======================================================================
; CODIGO 0xb2ec..0xb540  (596 bytes)
; ======================================================================


jefe_de_la_fase_2:
	ld b,(ix+001h)		;b2ec   ; el paso del jefe
	dec b			;b2ef
	jp z,L_B10D		;b2f0
	djnz L_B301		;b2f3
	ld de,00280h		;b2f5
	ld bc,00180h		;b2f8
	call pon_las_dos_velocidades		;b2fb
	jp L_B126		;b2fe
L_B301:
	djnz L_B31D		;b301
	call acerca_en_vertical_lento		;b303
	ld a,(ix+009h)		;b306
	sub 0e0h		;b309   ; y al llegar al borde derecho
	cp 030h		;b30b
	jr nc,L_B31A		;b30d
	ld de,(0e324h)		;b30f   ; da la vuelta
	call niega_de		;b313
	ld (0e324h),de		;b316
L_B31A:
	jp L_B144		;b31a
L_B31D:
	jp L_B14D		;b31d
comportamiento_15:
	ld bc,0b00fh		;b320   ; el dibujo, sin alternar
	call pon_el_dibujo		;b323
	jp L_B07C		;b326
comportamiento_17:
	ld bc,0cc0ah		;b329   ; los dos, alternando cada ocho
	call pon_el_dibujo		;b32c
	ld a,(ix+009h)		;b32f   ; pasado el borde
	sub 008h		;b332   ; ocho pixeles de margen
	cp 0e0h		;b334
	ret c			;b336
L_B337:
	ld a,(ix+005h)		;b337   ; la velocidad horizontal cambia de signo: rebota
	neg		;b33a   ; cambiado de signo
	ld (ix+005h),a		;b33c
	ret			;b33f
comportamiento_19:
	ld bc,0b0d8h		;b340   ; los dos dibujos
	ld e,00ah		;b343
	call pon_el_dibujo_y_el_paso		;b345   ; y el paso, en B
	djnz L_B35C		;b348   ; paso 2 para abajo
	ld a,(ix+007h)		;b34a   ; por debajo de la fila 0x10
	sub 010h		;b34d   ; contra la fila 0x10
	cp 008h		;b34f
	ret nc			;b351
	ld de,00500h		;b352   ; se para y baja despacio
	ld b,e			;b355   ; y sin horizontal
	ld c,e			;b356
	call pon_las_dos_velocidades		;b357
	jr L_B38F		;b35a
L_B35C:
	dec b			;b35c   ; paso 2
	jp z,L_B686		;b35d
	dec b			;b360   ; paso 3
	ret nz			;b361
	call apunta_y_arranca		;b362   ; y luego dispara
	jp L_B5C8		;b365
comportamiento_21:
	ld bc,0bcc0h		;b368
	ld e,00eh		;b36b
	call pon_el_dibujo_y_el_paso		;b36d   ; el dibujo y el paso
	dec b			;b370   ; solo hace algo en el paso 1
	ret nz			;b371
	call elige_a_quien_apuntar		;b372   ; apunta a la nave
	ld a,(ix+007h)		;b375   ; hasta la altura que le toca
	sub (ix+012h)		;b378   ; menos su destino
	sub 008h		;b37b   ; ocho pixeles de margen
	cp 008h		;b37d
	ret nc			;b37f
	ld bc,00400h		;b380   ; velocidad 0x0400
	ld e,c			;b383   ; y sin vertical
	ld d,c			;b384
	ld a,(ix+011h)		;b385   ; y sale a un lado o a otro
	rra			;b388
	call c,niega_bc		;b389
	call pon_las_dos_velocidades		;b38c
L_B38F:
	jr L_B3D9		;b38f
comportamiento_4:
	ld bc,0c4c8h		;b391
	ld e,00fh		;b394
	call pon_el_dibujo_y_el_paso		;b396   ; el dibujo y el paso
	djnz L_B3B8		;b399   ; paso 2 para abajo
	ld a,(ix+007h)		;b39b   ; por debajo de la fila 0x60
	sub 060h		;b39e   ; contra la fila 0x60
	cp 008h		;b3a0
	ret nc			;b3a2
	call apunta_y_arranca		;b3a3   ; dispara
	ld a,(ix+009h)		;b3a6
	cp 078h		;b3a9   ; y en la mitad derecha da la vuelta
	ld b,000h		;b3ab   ; con la marca a cero
	jr c,L_B3B1		;b3ad
	ld b,008h		;b3af   ; o a ocho
L_B3B1:
	ld (ix+010h),b		;b3b1   ; y esa es su cuenta de partida
	inc (ix+001h)		;b3b4   ; al paso siguiente
	ret			;b3b7
L_B3B8:
	ld a,(ix+010h)		;b3b8   ; su contador
	and 008h		;b3bb   ; el bit 3 dice el sentido
	jp L_B43A		;b3bd
comportamiento_7:		; Tambien es disparo del jefe de la fase 3
	ld bc,0e0e4h		;b3c0
	ld e,003h		;b3c3
	call pon_el_dibujo_y_el_paso		;b3c5   ; el dibujo y el paso
	ld (ix+000h),008h		;b3c8   ; el dibujo del disparo
	djnz L_B3DC		;b3cc   ; paso 2 para abajo
	ld a,(ix+007h)		;b3ce   ; por debajo de la fila 0x40
	sub 040h		;b3d1   ; contra la fila 0x40
	cp 008h		;b3d3
	ret nc			;b3d5
	call apunta_y_arranca		;b3d6   ; dispara
L_B3D9:
	jp al_paso_siguiente		;b3d9
L_B3DC:
	dec b			;b3dc   ; paso 2
	jp z,L_B435		;b3dd
	call rumbo_al_azar		;b3e0   ; y luego persigue
	ld (ix+016h),001h		;b3e3
	jr L_B3D9		;b3e7
jefe_de_la_fase_3:
	ld b,(ix+001h)		;b3e9
	dec b			;b3ec
	jp z,L_B10D		;b3ed
	djnz L_B401		;b3f0
	ld de,00140h		;b3f2   ; el jefe de la fase 3 coge velocidad
	ld bc,00600h		;b3f5
	call pon_las_dos_velocidades		;b3f8
	ld de,02880h		;b3fb
	jp pon_el_destino_del_jefe		;b3fe
L_B401:
	dec b			;b401
	jp nz,L_B14D		;b402
	call acerca_en_horizontal		;b405   ; se acerca en horizontal
	ld a,(ix+007h)		;b408
	sub 010h		;b40b   ; y al llegar abajo del todo
	cp 080h		;b40d
	jr c,L_B41C		;b40f
	ld de,(0e322h)		;b411   ; da la vuelta
	call niega_de		;b415
	ld (0e322h),de		;b418
L_B41C:
	jp L_B144		;b41c
comportamiento_20:
	ld bc,lb4b8h		;b41f
	ld e,00fh		;b422
	call alterna_cada_ocho		;b424
	ld a,(ix+007h)		;b427   ; a la altura 0xA0
	sub 0a0h		;b42a
	cp 004h		;b42c
	push ix		;b42e
	call c,dispara_el_enemigo		;b430   ; dispara
	pop ix		;b433
L_B435:
	ld a,(ix+010h)		;b435   ; el bit 2 del contador
	and 004h		;b438
L_B43A:
	ld bc,00080h		;b43a   ; y con el, va a un lado o al otro
	jp z,L_BB2E		;b43d
	jp va_a_la_derecha_deprisa		;b440
comportamiento_36:
	ld bc,0ccd0h		;b443
	ld e,00fh		;b446
	jp alterna_cada_ocho		;b448
comportamiento_26:
	ld bc,0d40eh		;b44b
	call pon_el_dibujo		;b44e
	jp L_B1F6		;b451
comportamiento_0:
	call comportamiento_37		;b454   ; hace lo mismo que el 37
	ld (ix+00ah),0c0h		;b457   ; con otro dibujo
	ld b,(ix+001h)		;b45b
	djnz L_B473		;b45e
	ld a,(ix+007h)		;b460   ; llegado al borde de abajo
	sub 0afh		;b463
	cp 010h		;b465
	jr c,L_B4BE		;b467
	ld a,(ix+009h)		;b469   ; o al de la derecha
	sub 008h		;b46c
	cp 0e0h		;b46e
	ret c			;b470
	jr L_B4BE		;b471
L_B473:
	dec b			;b473
	ret nz			;b474
	call apunta_y_arranca		;b475   ; dispara
	jr L_B4BE		;b478
comportamiento_1:
	ld bc,0d0d4h		;b47a
	ld e,00fh		;b47d
	call pon_el_dibujo_y_el_paso		;b47f   ; el dibujo, alternando
	dec b			;b482
	jp z,L_B1FB		;b483
	dec b			;b486
	ret nz			;b487
	ld a,(ix+010h)		;b488   ; en el cuadro 0x14
	cp 014h		;b48b
	ret nz			;b48d
	call apunta_y_arranca		;b48e   ; dispara
	jr L_B4BE		;b491
comportamiento_9:		; Tambien es disparo del jefe de la fase 4
	ld bc,0e00fh		;b493
	call pon_el_dibujo		;b496
	ld (ix+000h),00ah		;b499   ; el dibujo del disparo
	ld b,(ix+001h)		;b49d
	djnz L_B4A7		;b4a0
	call apunta_y_arranca		;b4a2   ; dispara al nacer
	jr L_B4BE		;b4a5
L_B4A7:
	dec b			;b4a7
	ret z			;b4a8
	call apunta_al_jefe		;b4a9   ; y luego se pone donde el jefe
	ld a,(0e003h)		;b4ac   ; cada 0x20 cuadros
	and 01fh		;b4af
	ret nz			;b4b1
	inc (ix+018h)		;b4b2   ; avanza su contador propio
	ld a,(ix+018h)		;b4b5
L_B4B8:
	sub 004h		;b4b8   ; que da la vuelta cada cuatro
	ret nz			;b4ba
	ld (ix+018h),a		;b4bb
L_B4BE:
	jp al_paso_siguiente		;b4be
jefe_de_la_fase_4:
	ld b,(ix+001h)		;b4c1   ; el paso del jefe
	dec b			;b4c4
	jp z,L_B10D		;b4c5
	djnz L_B4D5		;b4c8
	ld bc,00800h		;b4ca   ; el jefe de la fase 4 arranca despacio
	ld e,c			;b4cd
	ld d,c			;b4ce
	call pon_las_dos_velocidades		;b4cf
	jp L_B126		;b4d2
L_B4D5:
	dec b			;b4d5
	jp nz,L_B14D		;b4d6
	ld a,(ix+010h)		;b4d9   ; el bit 7 del contador
	rla			;b4dc
	jr nc,L_B4E4		;b4dd
	call va_a_la_izquierda		;b4df   ; y con el va a un lado o a otro
	jr L_B4E7		;b4e2
L_B4E4:
	call va_a_la_derecha		;b4e4
L_B4E7:
	jp L_B144		;b4e7
comportamiento_27:
	ld bc,0b0b4h		;b4ea   ; los dibujos 0xB0 y 0xB4
	ld e,00fh		;b4ed   ; cada quince cuadros
	call pon_el_dibujo_y_el_paso		;b4ef   ; el dibujo, alternando
	dec b			;b4f2   ; el paso 1
	jp z,L_B1FB		;b4f3
	dec b			;b4f6   ; y el paso 2
	ret nz			;b4f7
	ld bc,00300h		;b4f8   ; sale hacia el lado por el que este
	ld e,c			;b4fb   ; sin vertical
	ld d,c			;b4fc
	ld a,(ix+009h)		;b4fd   ; el bit 7 de la horizontal dice el lado
	rla			;b500
	call nc,niega_bc		;b501
	call pon_las_dos_velocidades		;b504
L_B507:
	jr L_B4BE		;b507
comportamiento_33:
	ld bc,0b8bch		;b509   ; los dibujos 0xB8 y 0xBC
	ld e,007h		;b50c   ; cada siete cuadros
	call alterna_cada_ocho		;b50e
	ld a,(ix+010h)		;b511   ; la cuenta del salto
	sub 00eh		;b514   ; catorce pasos de subida
	jr nc,L_B521		;b516
	ld (ix+010h),a		;b518   ; mientras dure, sube
	ld l,a			;b51b
	ld h,0fch		;b51c   ; hacia arriba
	jp pon_la_vertical		;b51e
L_B521:
	ld de,00080h		;b521   ; y luego baja
	jp suma_a_la_vertical		;b524
comportamiento_35:
	ld bc,0cc09h		;b527
	call pon_el_dibujo		;b52a
	ld a,(ix+010h)		;b52d   ; los tres bits bajos del contador
	and 007h		;b530
	ld hl,0b540h		;b532   ; y la tabla del zigzag
	call suma_a_a_hl		;b535
	ld a,(hl)			;b538
	add a,(ix+009h)		;b539   ; se le suma a la horizontal
	ld (ix+009h),a		;b53c
	ret			;b53f

; ----------------------------------------------------------------------
; DATOS giro_de_ocho_pasos: Lo que 0xB532 suma al angulo (ix+9): cuatro pasos
;   a un lado y cuatro al otro
;   0xb540..0xb548  (8 bytes)
DATA_giro_de_ocho_pasos:
	defb 004h	; b540
	defb 003h	; b541
	defb 002h	; b542
	defb 001h	; b543
	defb 0ffh	; b544
	defb 0feh	; b545
	defb 0fdh	; b546
	defb 0fch	; b547

; ======================================================================
; CODIGO 0xb548..0xb5a2  (90 bytes)
; ======================================================================


comportamiento_38:
	ld bc,0c4c8h		;b548
	ld e,00eh		;b54b
	call pon_el_dibujo_y_el_paso		;b54d
	dec b			;b550
	ret nz			;b551
	ld a,(0e154h)		;b552   ; si toca nube, no dispara
	and a			;b555
	jr z,L_B569		;b556
	inc (ix+00fh)		;b558
	ld a,(ix+00fh)		;b55b   ; y cada 0x10 cuadros
	cp 010h		;b55e
	call z,dispara_el_enemigo		;b560   ; suelta uno
	call acerca_en_vertical_lento		;b563   ; y persigue en los dos ejes
	jp acerca_en_horizontal		;b566
L_B569:
	call apunta_y_arranca		;b569
	jr $-101		;b56c
comportamiento_34:
	ld bc,0f40ah		;b56e   ; el dibujo
	call pon_el_dibujo		;b571
	ld b,(ix+001h)		;b574
	djnz L_B587		;b577
	ld a,(ix+010h)		;b579   ; en el cuadro 8
	cp 008h		;b57c
	ret nz			;b57e
	xor a			;b57f   ; se para en seco
	ld h,a			;b580
	ld l,a			;b581
	call pon_la_vertical		;b582
	jr $+67		;b585
L_B587:
	ld a,(ix+010h)		;b587   ; en el cuadro 0x20
	cp 020h		;b58a
	jr z,L_B594		;b58c
	ld hl,0b5a2h		;b58e   ; y si no, va por la tabla de recorrido
	jp recorrido_por_tabla		;b591
L_B594:
	dec (ix+001h)		;b594   ; vuelve al paso anterior
	ld bc,00500h		;b597
	ld (ix+010h),c		;b59a
	ld e,c			;b59d
	ld d,c			;b59e
	jp pon_las_dos_velocidades		;b59f

; ----------------------------------------------------------------------
; DATOS ocho_velocidades: Ocho palabras con signo que 0xB58E gasta como
;   recorrido de entrada
;   0xb5a2..0xb5b2  (16 bytes)
DATA_ocho_velocidades:
	defw 0ff80h,0ff60h,00080h,0ff60h,00070h,000a0h,0ff70h,000a0h	; b5a2

; ======================================================================
; CODIGO 0xb5b2..0xb662  (176 bytes)
; ======================================================================


comportamiento_28:
	ld bc,0ecf0h		;b5b2
	ld e,009h		;b5b5
	call pon_el_dibujo_y_el_paso		;b5b7
	dec b			;b5ba
	ret nz			;b5bb
	ld a,(ix+012h)		;b5bc   ; hasta la altura que le toca
	sub (ix+007h)		;b5bf
	cp 018h		;b5c2
	ret nc			;b5c4
	call da_la_vuelta_deprisa		;b5c5
L_B5C8:
	call al_paso_siguiente		;b5c8   ; y entonces dispara
	jp dispara_el_enemigo		;b5cb
comportamiento_22:
	ld bc,0b0b4h		;b5ce
	ld e,003h		;b5d1   ; cada tres cuadros
	call pon_el_dibujo_y_el_paso		;b5d3
	djnz L_B60E		;b5d6   ; solo en el paso 0
	ld a,(ix+010h)		;b5d8   ; en el cuadro 0x78
	cp 078h		;b5db
	jp z,L_B603		;b5dd
	and 01fh		;b5e0   ; y cada 0x20
	jr nz,L_B5F3		;b5e2
	ld a,(ix+01ch)		;b5e4   ; cambia de sentido
	dec a			;b5e7
	ld bc,0fb00h		;b5e8   ; cinco pixeles por cuadro
	call nz,niega_bc		;b5eb
	ld d,c			;b5ee   ; sin fraccion
	ld e,c			;b5ef
	call pon_las_dos_velocidades		;b5f0
L_B5F3:
	ld hl,0b662h		;b5f3   ; con la tabla de velocidades
	call saca_dos_velocidades		;b5f6
	ld a,h			;b5f9   ; el byte alto
	call suma_a_la_vertical		;b5fa
	ld hl,0b66ah		;b5fd   ; y la tabla vertical
	jp L_B62D		;b600
L_B603:
	ld de,0fb00h		;b603   ; y al final se va hacia arriba
	ld c,e			;b606
	ld b,e			;b607
	call pon_las_dos_velocidades		;b608
L_B60B:
	jp al_paso_siguiente		;b60b
L_B60E:
	djnz L_B63D		;b60e
	ld a,(ix+010h)		;b610   ; cada 0x20 cuadros
	and 01fh		;b613
	jr nz,L_B61D		;b615
	ld de,0fb00h		;b617   ; dispara y frena
	call dispara_y_frena		;b61a
L_B61D:
	ld hl,0b66ah		;b61d   ; la otra tabla, y al reves
	call saca_dos_velocidades		;b620
	call niega_de		;b623
	ld a,h			;b626
	call suma_a_la_vertical		;b627
	ld hl,0b662h		;b62a
L_B62D:
	call suma_a_a_hl		;b62d
	ld c,(hl)			;b630
	inc hl			;b631
	ld b,(hl)			;b632
	ld a,(ix+01ch)		;b633   ; con el signo que le toque
	dec a			;b636
	call z,niega_bc		;b637
	jp suma_a_la_horizontal		;b63a
L_B63D:
	ld a,(ix+013h)		;b63d   ; hasta la mitad de la pantalla
	cp 078h		;b640
	ret nc			;b642
	jr L_B60B		;b643
saca_dos_velocidades:
	ld a,(ix+010h)		;b645   ; los bits 3 y 4 del contador: cuatro tramos
	and 018h		;b648
	rra			;b64a
	rra			;b64b
	push af			;b64c
	rra			;b64d
	call palabra_de_tabla		;b64e
	pop hl			;b651
	ret			;b652
dispara_y_frena:
	ld c,e			;b653   ; sin velocidad vertical
	ld b,e			;b654
	call pon_las_dos_velocidades		;b655
	push af			;b658
	push ix		;b659
	call dispara_el_enemigo		;b65b   ; y dispara
	pop ix		;b65e
	pop af			;b660
	ret			;b661

; ----------------------------------------------------------------------
; DATOS ocho_velocidades_del_jefe: La misma forma para 0xB5F3 y 0xB62A
;   0xb662..0xb672  (16 bytes)
DATA_ocho_velocidades_del_jefe:
	defw 00030h,00030h,0ffe0h,0ffe0h,0ffb4h,0ffb0h,0ffb0h,0ffb0h	; b662

; ======================================================================
; CODIGO 0xb672..0xb6ca  (88 bytes)
; ======================================================================


comportamiento_5:
	ld bc,0d0d4h		;b672
	ld e,00fh		;b675
	call pon_el_dibujo_y_el_paso		;b677
	djnz L_B684		;b67a
	ld a,(ix+010h)		;b67c   ; en el cuadro 8
	cp 008h		;b67f
	ret nz			;b681
L_B682:
	jr $-119		;b682
L_B684:
	djnz L_B6AC		;b684
L_B686:
	ld a,(ix+010h)		;b686   ; en el 0x18
	cp 018h		;b689
	jr z,L_B6A1		;b68b
	ld hl,0b6cah		;b68d
recorrido_por_tabla:
	and 018h		;b690   ; la entrada que toque de la tabla
	rra			;b692
	rra			;b693
	call palabra_de_tabla		;b694
	inc hl			;b697
	ld c,(hl)			;b698
	inc hl			;b699
	ld b,(hl)			;b69a
	call suma_a_la_vertical		;b69b
	jp suma_a_la_horizontal		;b69e
L_B6A1:
	ld de,00500h		;b6a1   ; y luego se va
	ld bc,0fb00h		;b6a4
	call pon_las_dos_velocidades		;b6a7
	jr L_B682		;b6aa
L_B6AC:
	djnz L_B6B6		;b6ac
	ld a,(ix+010h)		;b6ae
	cp 018h		;b6b1
	ret nz			;b6b3
L_B6B4:
	jr L_B682		;b6b4
L_B6B6:
	dec b			;b6b6
	ret nz			;b6b7
	ld a,(ix+010h)		;b6b8   ; en el cuadro 0x20
	cp 020h		;b6bb
	jr z,L_B6C4		;b6bd
	ld hl,0b6d6h		;b6bf
	jr recorrido_por_tabla		;b6c2
L_B6C4:
	call apunta_y_arranca		;b6c4   ; dispara
	jp L_B5C8		;b6c7

; ----------------------------------------------------------------------
; DATOS dos_recorridos: Dos tandas de siete palabras, la de 0xB68D y la de
;   0xB6BF
;   0xb6ca..0xb6e6  (28 bytes)
DATA_dos_recorridos:
	defw 0ff60h,00080h,0ff60h,0ff80h,000a0h,0ff80h,0ff60h,00020h	; b6ca
	defw 0ff60h,00080h,00040h,00080h,00040h,0ff80h	; b6da

; ======================================================================
; CODIGO 0xb6e6..0xb778  (146 bytes)
; ======================================================================


comportamiento_10:		; Tambien es disparo del jefe de la fase 5
	ld (ix+000h),00bh		;b6e6   ; el dibujo
	ld b,(ix+001h)		;b6ea
	djnz L_B713		;b6ed
	ld a,(ix+010h)		;b6ef   ; en el cuadro 8
	cp 008h		;b6f2
	jr z,L_B70E		;b6f4
	cp 010h		;b6f6   ; y en el 0x10
	ret nz			;b6f8
	call elige_a_quien_apuntar		;b6f9   ; apunta a la nave
	ld (ix+00ah),0e8h		;b6fc
	ld a,(ix+013h)		;b700   ; y se apunta por que lado la tiene
	cp (ix+009h)		;b703
	jr c,$-82		;b706
	ld (ix+01ch),001h		;b708
	jr $-88		;b70c
L_B70E:
	ld (ix+00ah),0e4h		;b70e
	ret			;b712
L_B713:
	djnz L_B755		;b713
	ld a,(ix+010h)		;b715   ; en el cuadro 0x20
	cp 020h		;b718
	jr z,L_B73A		;b71a
	ld de,00040h		;b71c   ; y si no, baja
	call suma_a_la_vertical		;b71f
	and 018h		;b722   ; los bits 3 y 4: cuatro tramos
	rra			;b724   ; se baja al bit 0
	rra			;b725
	rra			;b726
	ld hl,0b77ch		;b727   ; la tabla de pasos
	call suma_a_a_hl		;b72a   ; la tabla de pasos
	ld c,(hl)			;b72d   ; el paso de este tramo
	ld b,000h		;b72e   ; sin fraccion
	ld a,(ix+01ch)		;b730   ; con el signo del lado
	dec a			;b733
	call nz,niega_bc		;b734
	jp suma_a_la_horizontal		;b737
L_B73A:
	ld de,00500h		;b73a   ; y al final se va hacia abajo
	ld a,(ix+01ch)		;b73d   ; otra vez el lado
	dec a			;b740
	ld bc,00300h		;b741
	call nz,niega_bc		;b744
	call pon_las_dos_velocidades		;b747
	ld (ix+00ah),0f4h		;b74a
	ld (ix+016h),001h		;b74e
L_B752:
	jp L_B6B4		;b752
L_B755:
	dec b			;b755   ; un paso menos
	ret z			;b756
	ld a,r		;b757   ; el refresco del Z80, de dado
	rla			;b759   ; se descarta el bit 7
	ld c,a			;b75a   ; el dado, a salvo
	and 003h		;b75b   ; dos bits: cuatro rumbos
	ld hl,0b778h		;b75d
	call suma_a_a_hl		;b760   ; la tabla de rumbos
	ld a,(hl)			;b763   ; el angulo
	ld b,a			;b764
	call pon_la_posicion		;b765   ; y sale con el
	ld de,0fb00h		;b768   ; y su paso
	ld b,e			;b76b
	ld c,e			;b76c
	call pon_las_dos_velocidades		;b76d
	ld bc,0e00ah		;b770   ; el dibujo 0xE0
	call pon_el_dibujo		;b773
	jr L_B752		;b776

; ----------------------------------------------------------------------
; DATOS rumbos_y_pasos: Cuatro angulos y cuatro pasos que gastan 0xB727 y
;   0xB75D
;   0xb778..0xb780  (8 bytes)
DATA_rumbos_y_pasos:
	defb 080h	; b778
	defb 090h	; b779
	defb 0a0h	; b77a
	defb 0b0h	; b77b
	defb 008h	; b77c
	defb 010h	; b77d
	defb 010h	; b77e
	defb 008h	; b77f

; ======================================================================
; CODIGO 0xb780..0xb950  (464 bytes)
; ======================================================================


jefe_de_la_fase_5:
	ld b,(ix+001h)		;b780
	dec b			;b783
	jp z,L_B10D		;b784
	djnz L_B794		;b787
	ld de,06480h		;b789   ; el jefe de la fase 5 se queda quieto
	call pon_el_destino_del_jefe		;b78c
	ld (ix+010h),040h		;b78f   ; con el contador a 0x40
	ret			;b793
L_B794:
	dec b			;b794
	jp nz,L_B14D		;b795
	ld de,00302h		;b798   ; y suelta disparos de dos en dos
	call velocidad_por_el_angulo		;b79b
	call coloca_al_jefe		;b79e
	jp saca_los_disparos_del_jefe		;b7a1
comportamiento_23:
	ld bc,0d80fh		;b7a4
	call pon_el_dibujo		;b7a7
	jp L_B07C		;b7aa
comportamiento_31:
	ld a,(0e003h)		;b7ad   ; cada ocho cuadros
	and 007h		;b7b0
	jr nz,L_B7CF		;b7b2
	inc (ix+01ah)		;b7b4   ; cambia de dibujo
	ld a,(ix+01ah)		;b7b7
	dec a			;b7ba
	ld b,0dch		;b7bb
	jr z,L_B7CA		;b7bd
	dec a			;b7bf
	ld b,0e0h		;b7c0
	jr z,L_B7CA		;b7c2
	ld (ix+01ah),000h		;b7c4   ; y da la vuelta cada tres
	ld b,0e4h		;b7c8
L_B7CA:
	ld c,00fh		;b7ca
	call pon_el_dibujo		;b7cc
L_B7CF:
	jp L_AFD8		;b7cf
comportamiento_37:
	ld a,(0e003h)		;b7d2   ; el dibujo sale del contador de cuadros
	rra			;b7d5
	rra			;b7d6
	and 003h		;b7d7   ; dos bits: tres dibujos
	ld c,008h		;b7d9
	rra			;b7db
	jr c,L_B7E5		;b7dc
	ld c,006h		;b7de
	rra			;b7e0
	jr nc,L_B7E5		;b7e1
	ld c,009h		;b7e3
L_B7E5:
	ld b,0e8h		;b7e5
	jp pon_el_dibujo		;b7e7
comportamiento_30:
	ld bc,0c0c4h		;b7ea
	ld e,00dh		;b7ed
	call alterna_cada_ocho		;b7ef
	jr L_B7CF		;b7f2
comportamiento_2:
	ld bc,0c8cch		;b7f4   ; los dos dibujos, alternando cada ocho cuadros
	ld e,00fh		;b7f7
	call alterna_cada_ocho		;b7f9
	ld a,(ix+00ah)		;b7fc   ; el dibujo que lleve
	cp 0c8h		;b7ff   ; con el primero de los dos
	ld a,001h		;b801   ; la marca de "este dispara" se enciende
	jr z,L_B806		;b803
	dec a			;b805
L_B806:
	ld (ix+016h),a		;b806   ; y con el otro se apaga
	ld a,(ix+007h)		;b809   ; llegado al borde de abajo
	sub 0afh		;b80c   ; 0x10 pixeles de margen contra el borde
	cp 010h		;b80e
	jr c,L_B81A		;b810
	ld a,(ix+009h)		;b812   ; o al de la derecha
	sub 008h		;b815   ; y ocho contra el de la derecha
	cp 0e0h		;b817
	ret c			;b819
L_B81A:
	jp apunta_y_arranca		;b81a   ; dispara
comportamiento_24:
	ld bc,0b8bch		;b81d   ; los dos dibujos, alternando cada ocho
	ld e,002h		;b820
	call pon_el_dibujo_y_el_paso		;b822   ; y el paso, en B
	djnz L_B838		;b825   ; paso 2 para abajo
	ld a,(ix+007h)		;b827   ; llegado abajo
	sub 0afh		;b82a   ; 0x10 pixeles de margen
	cp 010h		;b82c
	ret nc			;b82e
	call velocidad_al_reves		;b82f   ; da la vuelta
	call pon_la_horizontal		;b832   ; la horizontal, cambiada de signo
	jp cambia_el_sentido_vertical		;b835   ; y tambien la vertical: rebota en la esquina
L_B838:
	dec b			;b838   ; paso 2
	ret nz			;b839
	ld a,(ix+010h)		;b83a   ; su contador
	cp 018h		;b83d   ; y en el cuadro 0x18
	ret nz			;b83f
da_la_vuelta_deprisa:
	call velocidad_al_reves		;b840
	add hl,hl			;b843   ; y al doble de velocidad
	jp pon_la_horizontal		;b844
velocidad_al_reves:
	ld l,(ix+004h)		;b847   ; la velocidad horizontal
	ld h,(ix+005h)		;b84a
	jp niega_hl		;b84d   ; del reves
angulo_hacia_la_nave:
	ld l,(ix+012h)		;b850   ; donde quiere estar
	ld a,(ix+000h)		;b853   ; la clase del enemigo
	cp 009h		;b856   ; las clases de 9 arriba apuntan a la nave
	jr nc,L_B86A		;b858
	and a			;b85a   ; la clase 0 apunta al sitio fijo
	ld h,000h		;b85b
	jr z,L_B86C		;b85d
	dec a			;b85f   ; y las clases 1 a 4
	cp 004h		;b860
	jr nc,L_B86C		;b862
	ld a,(ix+001h)		;b864   ; solo si estan en su primer paso
	and a			;b867
	jr nz,L_B86C		;b868
L_B86A:
	ld h,001h		;b86a   ; las demas apuntan a donde este la nave
L_B86C:
	ld d,001h		;b86c   ; el signo de la diferencia
	push de			;b86e
	ld de,00008h		;b86f   ; ocho pixeles de margen
	add hl,de			;b872   ; la altura de destino, con su margen
	ld e,(ix+007h)		;b873
	or a			;b876   ; menos donde esta
	sbc hl,de		;b877   ; lo que le falta en vertical
	ld a,l			;b879   ; la diferencia, sin signo
	ld b,000h		;b87a
	pop de			;b87c
	jr z,L_B886		;b87d   ; si es cero, no hay que girar
	ld b,a			;b87f
	jr nc,L_B886		;b880   ; con acarreo, la diferencia es negativa
	dec d			;b882   ; se apunta el signo
	neg		;b883   ; y se pasa a valor absoluto
	ld b,a			;b885
L_B886:
	ld h,(ix+013h)		;b886   ; y lo que le falta en horizontal
	ld a,h			;b889   ; igual con la horizontal
	add a,008h		;b88a   ; ocho pixeles de margen
	sub (ix+009h)		;b88c
	ld e,000h		;b88f
	ld c,e			;b891
	jr z,L_B89B		;b892
	ld c,a			;b894   ; el valor
	jr nc,L_B89B		;b895
	inc e			;b897   ; y su signo
	neg		;b898
	ld c,a			;b89a
L_B89B:
	ld a,d			;b89b   ; los dos signos dicen el cuadrante
	add a,e			;b89c
	cp 001h		;b89d   ; con los dos signos a uno
	jr nz,L_B8A6		;b89f   ; con uno solo
	dec d			;b8a1   ; o los dos a cero
	jr nz,L_B8A6		;b8a2
	ld a,003h		;b8a4   ; es el tercero
L_B8A6:
	ld d,a			;b8a6   ; los dos signos, juntos
	ld l,b			;b8a7
	ld h,000h		;b8a8
	ld b,c			;b8aa
	push de			;b8ab
	call divide_con_fraccion		;b8ac   ; el cociente dy/dx, con ocho bits de fraccion
	ld hl,0b991h		;b8af   ; la tabla de ocho tangentes
	ld b,040h		;b8b2   ; se arranca en el grado 0x40
L_B8B4:
	ld a,(hl)			;b8b4   ; la tangente que toca
	inc hl			;b8b5   ; la palabra siguiente
	push hl			;b8b6
	ld h,(hl)			;b8b7
	ld l,a			;b8b8
	rst 20h			;b8b9   ; se compara con el cociente
	pop hl			;b8ba
	jr c,L_B8C4		;b8bb   ; en cuanto una es menor, ese es el angulo
	inc hl			;b8bd   ; la siguiente tangente
	ld a,b			;b8be
	sub 008h		;b8bf   ; y ocho grados menos por cada una que no pasa
	ld b,a			;b8c1
	jr nz,L_B8B4		;b8c2
L_B8C4:
	pop de			;b8c4   ; el cuadrante
	dec d			;b8c5   ; el primer cuadrante se devuelve tal cual
	jr nz,L_B8CC		;b8c6
	ld a,080h		;b8c8   ; y el segundo, restado de 0x80
	sub b			;b8ca
	ret			;b8cb
L_B8CC:
	dec d			;b8cc   ; el tercero, sumado a 0x80
	jr nz,L_B8D3		;b8cd
	ld a,080h		;b8cf
	add a,b			;b8d1
	ret			;b8d2
L_B8D3:
	ld a,b			;b8d3   ; y el cuarto, cambiado de signo
	dec d			;b8d4
	ret nz			;b8d5
	neg		;b8d6
	ret			;b8d8
divide_hl_entre_b:		; Ocho vueltas de restar y desplazar: el cociente sale en L y el resto en H
	ld c,008h		;b8d9   ; ocho bits de cociente
	xor a			;b8db
L_B8DC:
	adc hl,hl		;b8dc   ; el dividendo se dobla
	ld a,h			;b8de   ; la mitad alta
	jr c,L_B8E4		;b8df
	cp b			;b8e1   ; y si cabe el divisor
	jr c,L_B8E7		;b8e2
L_B8E4:
	sub b			;b8e4   ; se resta
	ld h,a			;b8e5
	xor a			;b8e6
L_B8E7:
	ccf			;b8e7   ; el bit del cociente, invertido por el `ccf`
	dec c			;b8e8   ; una vuelta menos
	jr nz,L_B8DC		;b8e9
	rl l		;b8eb   ; y el ultimo bit entra a empujones
	ret			;b8ed
divide_con_fraccion:
	ld a,b			;b8ee   ; con divisor cero
	or a			;b8ef
	jr z,L_B900		;b8f0
	ld de,00000h		;b8f2   ; la parte entera
	call divide_hl_entre_b		;b8f5
	ld d,l			;b8f8   ; el cociente, a la parte entera
	ld l,000h		;b8f9   ; y el resto se dobla ocho veces mas
	call divide_hl_entre_b		;b8fb   ; y con el resto, otra vuelta: la fraccion
	ld e,l			;b8fe   ; para sacar los ocho bits de fraccion
	ret			;b8ff
L_B900:
	dec a			;b900   ; 0xFFFF: lo mas grande que hay
	ld d,a			;b901   ; 0xFF en las dos mitades
	ld e,a			;b902
	ret			;b903
seno_y_coseno_del_contador:
	ld b,a			;b904   ; el angulo
	ld c,000h		;b905   ; y el cuadrante, en C
	cp 041h		;b907   ; primer cuadrante
	jr c,seno_y_coseno		;b909
	inc c			;b90b   ; cuadrante 1
	cp 080h		;b90c   ; segundo: 0x80 - a
	jr nc,L_B915		;b90e
	ld a,080h		;b910
	sub b			;b912
	jr seno_y_coseno		;b913
L_B915:
	inc c			;b915   ; cuadrante 2
	cp 0c0h		;b916   ; tercero
	jr nc,L_B91E		;b918
	sub 080h		;b91a   ; el angulo, menos 0x80
	jr seno_y_coseno		;b91c
L_B91E:
	inc c			;b91e   ; cuadrante 3
	neg		;b91f   ; y 0x100 - a
seno_y_coseno:
	ld b,a			;b921
	ex af,af'			;b922   ; el angulo, a salvo en el juego de repuesto
	ld a,b			;b923
	ex af,af'			;b924
	ld hl,0b950h		;b925   ; la tabla del coseno
	call suma_a_a_hl		;b928   ; HL apunta a su entrada
	ld d,000h		;b92b
	ld e,(hl)			;b92d   ; el coseno de ese angulo
	ld a,c			;b92e   ; los cuadrantes 1 y 2
	sub 001h		;b92f   ; o sea C igual a 1 o a 2
	cp 002h		;b931
	ld a,e			;b933
	jr nc,L_B939		;b934
	dec d			;b936   ; con D a 0xFF, que es el signo
	neg		;b937   ; llevan el coseno cambiado de signo
L_B939:
	ld e,a			;b939
	ld hl,0b950h		;b93a   ; y el seno sale de la MISMA tabla
	ld a,040h		;b93d   ; entrando por 0x40 - k
	sub b			;b93f   ; 0x40 - k es el complemento del angulo
	call suma_a_a_hl		;b940
	ld b,000h		;b943
	ld a,c			;b945
	cp 002h		;b946   ; los cuadrantes 2 y 3
	ld a,(hl)			;b948
	jr nc,L_B94E		;b949
	dec b			;b94b   ; llevan el seno cambiado de signo
	neg		;b94c
L_B94E:
	ld c,a			;b94e   ; y sale en BC
	ret			;b94f

; ----------------------------------------------------------------------
; DATOS tabla_del_coseno: Los 65 valores de un cuadrante: 255 * cos(k *
;   90/64). 0xB925 la indexa con el angulo y 0xB92E arregla el signo segun el
;   cuadrante, asi que con esta sola tabla se hacen los cuatro y tambien el
;   seno, entrando por 0x40 - k. ES LA MISMA TABLA QUE LA DE KNIGHTMARE
;   (RC-739), que la tiene en 0x844E: de los 65 bytes solo se diferencian
;   TRES. Y esos tres son justo los que Konami arreglo -ver abajo-
;   0xb950..0xb991  (65 bytes)
DATA_tabla_del_coseno:
	defb 0ffh	; b950
	defb 0ffh	; b951
	defb 0ffh	; b952
	defb 0ffh	; b953
	defb 0feh	; b954
	defb 0feh	; b955
	defb 0fdh	; b956
	defb 0fch	; b957
	defb 0fbh	; b958
	defb 0f9h	; b959
	defb 0f8h	; b95a
	defb 0f6h	; b95b
	defb 0f4h	; b95c
	defb 0f3h	; b95d
	defb 0f1h	; b95e
	defb 0eeh	; b95f
	defb 0ech	; b960
	defb 0eah	; b961
	defb 0e7h	; b962
	defb 0e4h	; b963
	defb 0e1h	; b964
	defb 0deh	; b965
	defb 0dch	; b966
	defb 0d9h	; b967
	defb 0d4h	; b968
	defb 0d1h	; b969
	defb 0cdh	; b96a
	defb 0c9h	; b96b
	defb 0c5h	; b96c
	defb 0c1h	; b96d
	defb 0bdh	; b96e
	defb 0b9h	; b96f
	defb 0b5h	; b970
	defb 0b0h	; b971
	defb 0abh	; b972
	defb 0a7h	; b973
	defb 0a2h	; b974
	defb 09dh	; b975
	defb 098h	; b976
	defb 093h	; b977
	defb 08eh	; b978
	defb 088h	; b979
	defb 083h	; b97a
	defb 07eh	; b97b
	defb 078h	; b97c
	defb 073h	; b97d
	defb 069h	; b97e
	defb 067h	; b97f
	defb 061h	; b980
	defb 05ch	; b981
	defb 056h	; b982
	defb 050h	; b983
	defb 04ah	; b984
	defb 044h	; b985
	defb 03eh	; b986
	defb 038h	; b987
	defb 030h	; b988
	defb 02bh	; b989
	defb 025h	; b98a
	defb 01fh	; b98b
	defb 019h	; b98c
	defb 012h	; b98d
	defb 00ch	; b98e
	defb 006h	; b98f
	defb 000h	; b990

; ----------------------------------------------------------------------
; DATOS tangentes_del_arcotangente: Ocho palabras que 0xB8AF recorre de mayor
;   a menor comparando contra el cociente: es la busqueda que convierte una
;   pareja (dx, dy) en un angulo. El `ld b,040h` y el `sub 008h` de 0xB8BF
;   dicen que cada acierto vale ocho grados de los 256 de la circunferencia
;   0xb991..0xb9a1  (16 bytes)
DATA_tangentes_del_arcotangente:
	defw 004f6h,00266h,0017dh,000ffh,000aah,00069h,00032h,00000h	; b991

; ======================================================================
; CODIGO 0xb9a1..0xbb18  (375 bytes)
; ======================================================================


acerca_en_horizontal:
	ld c,000h		;b9a1   ; sin dividir: se acerca a saco
	ld a,(ix+009h)		;b9a3   ; donde esta en horizontal
	sub (ix+00dh)		;b9a6   ; menos donde quiere estar
	call divide_con_signo		;b9a9   ; partido entre lo que diga C
	ld b,d			;b9ac   ; y eso es lo que se le suma
	ld c,e			;b9ad
	jp suma_a_la_horizontal		;b9ae
acerca_en_vertical_lento:
	ld c,000h		;b9b1   ; sin dividir tampoco
acerca_en_vertical:
	ld a,(ix+007h)		;b9b3   ; donde esta en vertical
	sub (ix+00ch)		;b9b6   ; menos su destino
	call divide_con_signo		;b9b9
	jp suma_a_la_vertical		;b9bc
divide_con_signo:
	ld e,a			;b9bf   ; la diferencia, en la mitad baja
	ld d,000h		;b9c0   ; y la alta a cero
	add a,a			;b9c2   ; el bit 7 dice si es negativa
	jr nc,L_B9C6		;b9c3
	dec d			;b9c5   ; y entonces la alta va a 0xFF
L_B9C6:
	ld a,c			;b9c6   ; C es cuantas veces se parte
	and a			;b9c7
	jr z,L_B9CF		;b9c8   ; con cero, se deja como esta
L_B9CA:
	sra e		;b9ca   ; `sra` conserva el signo al dividir
	dec a			;b9cc
	jr nz,L_B9CA		;b9cd
L_B9CF:
	jp niega_de		;b9cf   ; y sale con el signo puesto
sale_por_el_lado_contrario:
	ld a,(ix+013h)		;b9d2   ; el rumbo
	ld b,010h		;b9d5   ; mirando a la derecha, sale por la izquierda
	ld c,000h		;b9d7
	cp 080h		;b9d9   ; con el rumbo por debajo de 0x80
	jr nc,L_B9E0		;b9db
	ld b,0e0h		;b9dd   ; y al reves
	inc c			;b9df
L_B9E0:
	ld (ix+009h),b		;b9e0   ; la posicion horizontal
	ld (ix+011h),c		;b9e3   ; y la bandera del lado
	ret			;b9e6
velocidad_por_el_angulo:
	ld a,(ix+010h)		;b9e7   ; el contador hace de angulo
	ld hl,0b950h		;b9ea   ; la tabla del coseno
	cp 040h		;b9ed   ; cada cuadrante entra en la tabla por su lado
	ld c,001h		;b9ef   ; el signo, positivo
	jr c,L_BA0E		;b9f1
	cp 080h		;b9f3
	jr nc,L_B9FF		;b9f5
	sub 080h		;b9f7   ; el segundo cuadrante entra por 0x80 - a
	neg		;b9f9
	ld c,000h		;b9fb   ; y con el signo cambiado
	jr L_BA0E		;b9fd
L_B9FF:
	cp 0c0h		;b9ff
	jr nc,L_BA09		;ba01
	ld c,000h		;ba03
	sub 080h		;ba05   ; el tercero, restando 0x80
	jr L_BA0E		;ba07
L_BA09:
	ld c,001h		;ba09   ; y el cuarto, negado
	ld b,a			;ba0b
	xor a			;ba0c
	sub b			;ba0d
L_BA0E:
	call pon_el_angulo_y_la_posicion		;ba0e   ; el valor de la tabla, escalado
	jr c,L_BA18		;ba11   ; y se suma o se resta al centro
	add a,(ix+00dh)		;ba13
	jr angulo_a_posicion		;ba16
L_BA18:
	ld b,a			;ba18
	ld a,(ix+00dh)		;ba19
	sub b			;ba1c
angulo_a_posicion:
	ld (ix+009h),a		;ba1d   ; la horizontal
	ld a,(ix+010h)		;ba20   ; ahora el otro eje
	ld hl,0b950h		;ba23   ; la tabla del coseno
	cp 040h		;ba26   ; y el cuadrante decide por donde
	jr nc,L_BA32		;ba28
	ld c,001h		;ba2a
	ld b,a			;ba2c
	ld a,040h		;ba2d   ; el primer cuadrante entra por 0x40 - a
	sub b			;ba2f
	jr L_BA4C		;ba30
L_BA32:
	cp 080h		;ba32
	jr nc,L_BA3C		;ba34
	ld c,001h		;ba36
	sub 040h		;ba38   ; el segundo, restando 0x40
	jr L_BA4C		;ba3a
L_BA3C:
	cp 0c0h		;ba3c   ; tercer cuadrante
	jr nc,L_BA48		;ba3e
	ld c,000h		;ba40
	ld b,a			;ba42
	ld a,0c0h		;ba43   ; 0xC0 - a
	sub b			;ba45
	jr L_BA4C		;ba46
L_BA48:
	ld c,000h		;ba48   ; y el cuarto, restando 0xC0
	sub 0c0h		;ba4a
L_BA4C:
	call pon_el_angulo_y_la_posicion		;ba4c
	jr c,L_BA56		;ba4f
	add a,(ix+00ch)		;ba51
	jr L_BA5B		;ba54
L_BA56:
	ld b,a			;ba56
	ld a,(ix+00ch)		;ba57
	sub b			;ba5a
L_BA5B:
	ld (ix+007h),a		;ba5b   ; la vertical
	ld a,(ix+010h)		;ba5e   ; y el angulo avanza
	add a,d			;ba61
	ld (ix+010h),a		;ba62
	ret			;ba65
pon_el_angulo_y_la_posicion:
	call suma_a_a_hl		;ba66   ; la entrada de la tabla
	ld a,(hl)			;ba69
	ld b,e			;ba6a
L_BA6B:
	srl a		;ba6b   ; el radio: dividir el coseno entre 2^E
	djnz L_BA6B		;ba6d
	rr c		;ba6f   ; y el signo sale por el acarreo
	ret			;ba71

; ----------------------------------------------------------------------
; A QUIEN APUNTAN LOS ENEMIGOS CON DOS JUGADORES. No eligen la mas cerca ni la que mas moleste: van turnandose. (0xE150) se conmuta con un `xor 1` en cada llamada, asi que un enemigo apunta a la primera nave y el siguiente a la segunda. Con un solo jugador vivo, todos van a por el.
; ----------------------------------------------------------------------
elige_a_quien_apuntar:
	call donde_esta_la_nave_uno		;ba72   ; donde esta la nave 1
	ex de,hl			;ba75   ; la posicion, a DE
	ld a,(0e077h)		;ba76   ; con los dos vivos
	dec a			;ba79   ; con uno solo vivo
	jr z,L_BA93		;ba7a
	dec a			;ba7c
	jr z,L_BA88		;ba7d
	ld hl,0e150h		;ba7f   ; la marca del turno
	ld a,(hl)			;ba82
	xor 001h		;ba83   ; se turna: un cuadro a uno y otro al otro
	ld (hl),a			;ba85   ; y se guarda para el siguiente
	jr nz,L_BA93		;ba86
L_BA88:
	call donde_esta_la_nave_dos		;ba88   ; y si no, a la que quede
	ex de,hl			;ba8b   ; su posicion
	call el_dos_tiene_bomba		;ba8c   ; y si ese esta muriendose
	jr nz,L_BA98		;ba8f
	jr L_BA9B		;ba91
L_BA93:
	call el_uno_tiene_bomba		;ba93
	jr z,L_BA9B		;ba96
L_BA98:
	ld de,08060h		;ba98   ; se apunta a un sitio fijo fuera de la pantalla
L_BA9B:
	ld a,e			;ba9b
	sub 010h		;ba9c   ; 0x10 pixeles mas arriba
	ld (ix+012h),a		;ba9e   ; el destino vertical
	ld (ix+013h),d		;baa1   ; y el horizontal
	ret			;baa4
marca_para_apagar:
	inc l			;baa5
	ld (hl),0feh		;baa6   ; la clase pasa a 0xFE
	xor a			;baa8   ; y el resto, a cero
borra_cuatro:
	inc l			;baa9   ; los cuatro bytes que quedan
	ld (hl),a			;baaa
	inc l			;baab
	ld (hl),a			;baac
	inc l			;baad
	ld (hl),a			;baae
	inc l			;baaf
	ld (hl),a			;bab0
	ret			;bab1
apaga_todos_los_enemigos:
	ld hl,0e161h		;bab2
	ld b,00eh		;bab5   ; los catorce huecos
L_BAB7:
	push hl			;bab7
	push bc			;bab8
	ld a,(hl)			;bab9   ; 0xFF: hueco vacio
	inc a			;baba
	jr z,L_BACA		;babb
	dec l			;babd
	ld a,(hl)			;babe   ; si ademas la clase es cero
	and a			;babf
	push hl			;bac0
	push af			;bac1
	call z,apaga_ese_enemigo		;bac2   ; se borra del todo
	pop af			;bac5
	pop hl			;bac6
	call nz,marca_para_apagar		;bac7   ; y si no, se marca para apagar
L_BACA:
	pop bc			;baca
	pop hl			;bacb
	ld de,00020h		;bacc   ; 0x20 bytes hasta el siguiente
	add hl,de			;bacf
	djnz L_BAB7		;bad0
	ret			;bad2
marca_al_jefe_para_apagar:
	ld hl,0e320h		;bad3   ; el hueco del jefe
	jr marca_para_apagar		;bad6
suma_a_la_vertical:
	ld l,(ix+002h)		;bad8   ; la velocidad vertical que lleva
	ld h,(ix+003h)		;badb
	add hl,de			;bade   ; mas lo que se le suma
pon_la_vertical:
	ld (ix+002h),l		;badf
	ld (ix+003h),h		;bae2
	ret			;bae5
suma_a_la_horizontal:
	ld l,(ix+004h)		;bae6   ; y lo mismo con la horizontal
	ld h,(ix+005h)		;bae9
	add hl,bc			;baec
pon_la_horizontal:
	ld (ix+004h),l		;baed
	ld (ix+005h),h		;baf0
	ret			;baf3
pon_las_dos_velocidades:		; DE la vertical y BC la horizontal
	push ix		;baf4   ; DE la vertical y BC la horizontal
	pop hl			;baf6   ; el bloque, en HL
	inc l			;baf7   ; dos bytes: la velocidad vertical
	inc l			;baf8
	ld (hl),e			;baf9
	inc l			;bafa
	ld (hl),d			;bafb
	inc l			;bafc
	ld (hl),c			;bafd   ; y otros dos: la horizontal
	inc l			;bafe
	ld (hl),b			;baff
	ret			;bb00
cuenta_de_enemigo:		; Un contador que no vuelve nunca a cero: el dado barato del cartucho
	ld hl,0e152h		;bb01
	inc (hl)			;bb04   ; uno mas, y da la vuelta sola en 256
	ld a,(hl)			;bb05
	ret			;bb06
alterna_cada_ocho:
	ld d,008h		;bb07   ; el bit 3 del contador de cuadros
	jr L_BB0D		;bb09
alterna_cada_cuatro:
	ld d,004h		;bb0b   ; o el bit 2, que alterna el doble de deprisa
L_BB0D:
	ld a,(0e003h)		;bb0d   ; el contador
	and d			;bb10
	jr nz,L_BB14		;bb11   ; con el bit puesto se queda B
	ld b,c			;bb13   ; y sin el, C
L_BB14:
	ld c,e			;bb14   ; el color va en E
	jp pon_el_dibujo		;bb15

; ----------------------------------------------------------------------
; DATOS codigo_al_que_no_llega_nadie_2: `ld de,0010h` y un `jr` a 0xBB1D, o
;   sea la variante de 0x10 de lo que hay justo debajo. Ningun salto entra
;   aqui
;   0xbb18..0xbb1d  (5 bytes)
DATA_codigo_al_que_no_llega_nadie_2:
	defb 011h,010h,000h,018h,003h	; bb18

; ======================================================================
; CODIGO 0xbb1d..0xbb25  (8 bytes)
; ======================================================================


baja_veinte:
	ld de,00020h		;bb1d
baja_lo_que_diga_de:
	call niega_de		;bb20
	jr $-75		;bb23

; ----------------------------------------------------------------------
; DATOS codigo_al_que_no_llega_nadie_3: `ld a,(ix+011h)`, `rra` y un `jr nc`:
;   seis bytes que tampoco alcanza nadie
;   0xbb25..0xbb2b  (6 bytes)
DATA_codigo_al_que_no_llega_nadie_3:
	defb 0ddh,07eh,011h,01fh,030h,005h	; bb25

; ======================================================================
; CODIGO 0xbb2b..0xbb38  (13 bytes)
; ======================================================================


va_a_la_izquierda:
	ld bc,00020h		;bb2b
L_BB2E:
	jr $-72		;bb2e
va_a_la_derecha:
	ld bc,00020h		;bb30
va_a_la_derecha_deprisa:
	call niega_bc		;bb33
	jr $-80		;bb36

; ----------------------------------------------------------------------
; DATOS codigo_al_que_no_llega_nadie_4: Y once mas, con la misma forma. Los
;   cuatro trozos huerfanos del cartucho suman 27 bytes
;   0xbb38..0xbb43  (11 bytes)
DATA_codigo_al_que_no_llega_nadie_4:
	defb 0ddh,07eh,011h,01fh,001h,010h,000h,038h,0f2h,018h,0ebh	; bb38  .~.....8...

; ======================================================================
; CODIGO 0xbb43..0xbc13  (208 bytes)
; ======================================================================


apunta_y_avanza:
	call angulo_hacia_la_nave		;bb43   ; el rumbo, en seno y coseno
	call seno_y_coseno_del_contador		;bb46   ; el seno y el coseno de ese rumbo
	push de			;bb49   ; el seno, a salvo
	ld e,c			;bb4a   ; y el coseno primero
	ld d,b			;bb4b
	call escala_la_velocidad		;bb4c   ; se escala
	call pon_la_vertical		;bb4f   ; y se le pone a los dos ejes
	pop de			;bb52
	call escala_la_velocidad		;bb53
	jp pon_la_horizontal		;bb56
escala_la_velocidad:
	bit 7,d		;bb59   ; el signo aparte
	push af			;bb5b   ; el signo, a la pila
	call nz,niega_de		;bb5c   ; y el valor, en positivo
	ld l,e			;bb5f   ; la velocidad base
	ld h,d			;bb60
	add hl,hl			;bb61   ; por dos
	ld a,(ix+000h)		;bb62   ; la clase del enemigo
	and a			;bb65
	add hl,de			;bb66   ; mas uno: van tres veces la base
	jr z,L_BB75		;bb67
	cp 007h		;bb69   ; la clase 7 no lleva el tercer sumando
	jr z,L_BB6E		;bb6b
	add hl,de			;bb6d   ; las demas llevan cuatro
L_BB6E:
	ld a,(0e07eh)		;bb6e   ; y de la fase 2 en adelante, uno mas: van mas deprisa
	and a			;bb71   ; en la primera vuelta, no
	jr z,L_BB75		;bb72
	add hl,de			;bb74   ; y en las siguientes, cinco
L_BB75:
	pop af			;bb75
	call nz,niega_hl		;bb76   ; y se le devuelve el signo
	ret			;bb79
pon_el_dibujo_y_el_paso:
	call alterna_cada_ocho		;bb7a   ; el dibujo y, de paso, el paso en B
	ld b,(ix+001h)		;bb7d   ; y el paso, en B
	ret			;bb80
coloca_los_enemigos:
	ld b,00eh		;bb81   ; los catorce
	ld ix,0e160h		;bb83
	ld de,0efc8h		;bb87   ; al bloque de sprites que les toca
L_BB8A:
	push bc			;bb8a   ; los catorce
	push ix		;bb8b
	pop hl			;bb8d
	ld a,007h		;bb8e   ; siete bytes: la posicion
	add a,l			;bb90
	ld l,a			;bb91
	call coloca_uno		;bb92
	ld bc,00020h		;bb95   ; 0x20 hasta el siguiente
	add ix,bc		;bb98
	pop bc			;bb9a
	djnz L_BB8A		;bb9b
	ret			;bb9d
coloca_uno:
	push hl			;bb9e
	ld a,(hl)			;bb9f   ; la vertical
	sub 0c0h		;bba0   ; fuera de la pantalla por abajo
	cp 020h		;bba2   ; 0x20 pixeles de margen por abajo
	call c,apaga_el_enemigo		;bba4   ; y el enemigo se apaga
	ld a,(ix+000h)		;bba7
	cp 00ah		;bbaa   ; la clase 0x0A
	jr nz,L_BBB4		;bbac
	ld a,(ix+001h)		;bbae
	and a			;bbb1
	jr z,L_BBBE		;bbb2
L_BBB4:
	ld a,(ix+009h)		;bbb4   ; y por la derecha, igual
	sub 0f8h		;bbb7   ; ocho pixeles de margen por la derecha
	cp 008h		;bbb9
	call c,apaga_el_enemigo		;bbbb
L_BBBE:
	pop hl			;bbbe
	ldi		;bbbf   ; los cuatro bytes del sprite
	inc l			;bbc1   ; saltando el byte de en medio
	ldi		;bbc2   ; la horizontal, el patron y el color
	ldi		;bbc4
	ldi		;bbc6
	ret			;bbc8
coloca_al_jefe:
	ld hl,0bc18h		;bbc9   ; el guion de casillas del jefe
	ld bc,0bc13h		;bbcc   ; los codigos de casilla
	ld de,0efb8h		;bbcf   ; y el bloque de sprites del jefe
	ld a,(0e321h)		;bbd2   ; con 0xFE, el jefe se esta muriendo
	cp 0feh		;bbd5
	jr nz,L_BBE5		;bbd7
	ld bc,0bc25h		;bbd9   ; con el juego de casillas de "muriendose"
	ld a,(0e32ah)		;bbdc   ; y si ademas lleva la marca
	and a			;bbdf
	jr z,L_BBE5		;bbe0
	ld bc,0bc2ah		;bbe2   ; el tercero
L_BBE5:
	ld a,(0e327h)		;bbe5   ; la posicion, mas el desvio de cada casilla
	add a,(hl)			;bbe8   ; el desvio de esta casilla
	ld (de),a			;bbe9   ; al bloque de sprites
	inc hl			;bbea   ; a la siguiente
	inc de			;bbeb
	ld a,(0e329h)		;bbec   ; y la vertical igual
	add a,(hl)			;bbef
	ld (de),a			;bbf0
	inc hl			;bbf1
	inc de			;bbf2
	ld a,(bc)			;bbf3   ; y su patron
	ld (de),a			;bbf4
	inc bc			;bbf5
	inc de			;bbf6
	push hl			;bbf7
	ld hl,0bc20h		;bbf8   ; el color, que depende de la fase
	call la_fase_de_uno_a_cinco		;bbfb   ; la fase, de 1 a 5
	call suma_a_a_hl		;bbfe
	ld a,(0e321h)		;bc01   ; el estado del jefe
	cp 0feh		;bc04   ; 0xFE es muriendose
	ld a,(hl)			;bc06   ; y muriendose, blanco
	jr nz,L_BC0B		;bc07
	ld a,00fh		;bc09
L_BC0B:
	ld (de),a			;bc0b   ; el color, al bloque
	pop hl			;bc0c
	inc de			;bc0d
	ld a,(bc)			;bc0e
	inc a			;bc0f   ; hasta el 0xFF que cierra el guion
	ret z			;bc10
	jr L_BBE5		;bc11

; ----------------------------------------------------------------------
; DATOS tres_juegos_de_casillas: Tres tandas cerradas por 0xFF que 0xBBC9
;   elige segun (0xE321) y (0xE32A): las casillas con las que se dibuja el
;   jefe
;   0xbc13..0xbc2f  (28 bytes)
DATA_tres_juegos_de_casillas:
	defb 0d0h	; bc13
	defb 0d8h	; bc14
	defb 0d4h	; bc15
	defb 0dch	; bc16
	defb 0ffh	; bc17
	defb 0f0h	; bc18
	defb 0f0h	; bc19
	defb 000h	; bc1a
	defb 0f0h	; bc1b
	defb 0f0h	; bc1c
	defb 000h	; bc1d
	defb 000h	; bc1e
	defb 000h	; bc1f
	defb 003h	; bc20
	defb 00fh	; bc21
	defb 007h	; bc22
	defb 00fh	; bc23
	defb 007h	; bc24
	defb 0b0h	; bc25
	defb 0b8h	; bc26
	defb 0b4h	; bc27
	defb 0bch	; bc28
	defb 0ffh	; bc29
	defb 0c0h	; bc2a
	defb 0c8h	; bc2b
	defb 0c4h	; bc2c
	defb 0cch	; bc2d
	defb 0ffh	; bc2e

; ======================================================================
; CODIGO 0xbc2f..0xbd6c  (317 bytes)
; ======================================================================


saca_la_oleada_del_jefe:
	ld a,(0e154h)		;bc2f   ; la marca de que hay jefe
	and a			;bc32   ; sin jefe, nada
	ret z			;bc33
	ld a,(0e151h)		;bc34   ; la marca de la tanda final
	and a			;bc37
	jp nz,la_tanda_del_final		;bc38
	ld hl,0e15bh		;bc3b
	ld a,(hl)			;bc3e   ; la espera hasta la oleada siguiente
	and a			;bc3f
	jr z,el_siguiente_paso_del_jefe		;bc40
	dec (hl)			;bc42   ; uno menos
L_BC43:
	ld hl,0e15dh		;bc43   ; y la espera entre uno y otro
	ld a,(hl)			;bc46   ; el reloj de entre enemigos
	and a			;bc47
	jr z,reparte_los_que_nacen		;bc48
	dec (hl)			;bc4a   ; uno menos
	ret			;bc4b
reparte_los_que_nacen:
	call elige_cuantos_huecos		;bc4c
recorre_los_catorce_3:
	ld a,(ix+001h)		;bc4f   ; el paso del enemigo
	and a			;bc52   ; solo los que estan a cero
	jr nz,L_BC7C		;bc53
	call al_paso_siguiente		;bc55   ; el enemigo arranca
	ld a,(ix+000h)		;bc58
	cp 017h		;bc5b   ; la clase 0x17
	jr nz,L_BC6D		;bc5d
	ld a,(ix+009h)		;bc5f   ; se apunta por que lado esta la nave
	cp 078h		;bc62   ; contra la mitad de la pantalla
	ld (ix+01ch),000h		;bc64   ; con la marca a cero
	jr c,L_BC6D		;bc68
	inc (ix+01ch)		;bc6a   ; o a uno
L_BC6D:
	ld a,(ix+000h)		;bc6d   ; su clase
	cp 021h		;bc70   ; la clase 0x21 no gasta espera
	jr z,L_BC7C		;bc72
	ld a,(0e15ch)		;bc74   ; y los demas recargan la espera
	ld (0e15dh),a		;bc77
	and a			;bc7a
	ret nz			;bc7b
L_BC7C:
	ld de,00020h		;bc7c   ; 0x20 bytes hasta el siguiente
	add ix,de		;bc7f
	djnz recorre_los_catorce_3		;bc81
	ret			;bc83
el_siguiente_paso_del_jefe:
	call la_fase_de_uno_a_cinco		;bc84   ; el guion del jefe de esta fase
	ld hl,0bf11h		;bc87   ; la tabla de guiones
	call palabra_de_tabla		;bc8a
	ld a,(0e156h)		;bc8d   ; por donde va
	call suma_a_a_de		;bc90   ; se avanza hasta el paso
	ld a,(de)			;bc93
	inc a			;bc94   ; y al llegar al 0xFF, vuelta a empezar
	jr nz,L_BC9D		;bc95
	xor a			;bc97
	ld (0e156h),a		;bc98   ; el paso, a cero
	jr el_siguiente_paso_del_jefe		;bc9b
L_BC9D:
	dec a			;bc9d   ; menos uno, por dos
	add a,a			;bc9e   ; dos bytes por oleada
	ld de,0bfb1h		;bc9f   ; la tabla de velocidades
	call suma_a_a_de		;bca2
	ld a,(de)			;bca5   ; el primer byte
	and 03fh		;bca6   ; los seis bits bajos: la clase
	ld (0e15ah),a		;bca8   ; la clase que sale
	ld a,(de)			;bcab
	and 0c0h		;bcac   ; y los dos altos, rotados: cuantos vienen
	rlca			;bcae   ; una vuelta
	rlca			;bcaf   ; dos vueltas
	rlca			;bcb0   ; tres: ya son los bits 0 y 1
	ld (0e159h),a		;bcb1   ; cuantos salen
	inc de			;bcb4   ; y el byte siguiente
	ld a,(de)			;bcb5   ; los cuatro bits bajos, por ocho: lo que se espera hasta la oleada siguiente
	and 00fh		;bcb6
	add a,a			;bcb8   ; por dos
	add a,a			;bcb9   ; por cuatro
	add a,a			;bcba   ; por ocho
	ld (0e15bh),a		;bcbb
	ld a,(de)			;bcbe
	and 030h		;bcbf   ; y los bits 4 y 5: lo que se espera entre uno y otro
	rrca			;bcc1   ; una vuelta
	rrca			;bcc2   ; dos: ya son los bits 2 y 3
	ld (0e15ch),a		;bcc3
	ld (0e15dh),a		;bcc6   ; y la cuenta arranca ahi
	ld a,(de)			;bcc9   ; el mismo byte otra vez
	rla			;bcca   ; el bit 7
	jr nc,L_BCDB		;bccb
	rla			;bccd   ; y el 6
	jr nc,L_BCD7		;bcce
	ld a,(0e07eh)		;bcd0   ; solo en la fase 3
	cp 002h		;bcd3
	jr nz,L_BCDB		;bcd5
L_BCD7:
	ld a,001h		;bcd7
	jr L_BCDC		;bcd9
L_BCDB:
	xor a			;bcdb
L_BCDC:
	ld (0e366h),a		;bcdc   ; deciden si estos disparan
	ld hl,0e156h		;bcdf
	inc (hl)			;bce2   ; un paso mas del guion
	ld a,(hl)			;bce3
	inc a			;bce4   ; y si desborda, se queda arriba
	jr nz,L_BCE8		;bce5
	ld (hl),a			;bce7
L_BCE8:
	ld hl,0e161h		;bce8   ; los siete primeros huecos
	ld de,00020h		;bceb
	ld bc,00700h		;bcee
L_BCF1:
	ld a,(hl)			;bcf1
	inc a			;bcf2   ; se cuentan los libres
	jr nz,L_BCF6		;bcf3
	inc c			;bcf5
L_BCF6:
	add hl,de			;bcf6
	djnz L_BCF1		;bcf7
	ld a,c			;bcf9
	cp 003h		;bcfa   ; y con menos de tres no se saca la tanda
	ret c			;bcfc
	call saca_la_tanda		;bcfd
	jp L_BC43		;bd00
elige_cuantos_huecos:
	ld a,(0e151h)		;bd03   ; con el final puesto, los catorce
	and a			;bd06
	ld b,00eh		;bd07
	jr nz,L_BD0D		;bd09
	ld b,007h		;bd0b   ; y si no, solo los siete primeros
L_BD0D:
	ld ix,0e160h		;bd0d
	ret			;bd11
saca_la_tanda:
	call elige_cuantos_huecos		;bd12
L_BD15:
	push bc			;bd15
	ld a,(ix+001h)		;bd16   ; se busca un hueco libre
	inc a			;bd19
	call z,nace_el_enemigo		;bd1a
	pop bc			;bd1d
	ld a,(0e159h)		;bd1e   ; hasta colocarlos todos
	and a			;bd21
	ret z			;bd22
	ld de,00020h		;bd23   ; treinta y dos bytes por hueco
	add ix,de		;bd26
	djnz L_BD15		;bd28
	ret			;bd2a
la_tanda_del_final:
	ld a,(0e15fh)		;bd2b   ; la espera entre tandas
	and a			;bd2e
	jr nz,L_BD56		;bd2f   ; todavia no toca
	ld a,021h		;bd31   ; la clase 0x21, uno cada vez
	ld (0e15ah),a		;bd33   ; la clase que se va a sacar
	ld a,001h		;bd36
	ld (0e159h),a		;bd38   ; uno solo
	call saca_la_tanda		;bd3b
	call reparte_los_que_nacen		;bd3e
	ld a,008h		;bd41   ; y ocho cuadros de espera
	ld (0e15fh),a		;bd43
	ld hl,0e15eh		;bd46   ; dieciseis tandas
	inc (hl)			;bd49   ; una tanda mas
	ld a,(hl)			;bd4a
	cp 010h		;bd4b   ; y se acaba
	ret c			;bd4d
	xor a			;bd4e   ; se reinicia la cuenta
	ld (hl),a			;bd4f
	inc l			;bd50   ; y la espera tambien
	ld (hl),a			;bd51
	ld (0e151h),a		;bd52   ; y se suelta la bandera del final
	ret			;bd55
L_BD56:
	ld hl,0e15fh		;bd56
	dec (hl)			;bd59   ; un cuadro menos de espera
	ret			;bd5a
pon_la_espera_de_disparo:
	ld a,(0e07eh)		;bd5b   ; la fase manda la espera entre disparos
	ld hl,0bd6ch		;bd5e
	call suma_a_a_hl		;bd61
	ld a,(hl)			;bd64
	ld (ix+00eh),a		;bd65
	ld (ix+00fh),a		;bd68
	ret			;bd6b

; ----------------------------------------------------------------------
; DATOS tres_esperas: 0xBD5E indexa con (0xE07E), la vuelta: cuanto tarda un
;   enemigo en disparar
;   0xbd6c..0xbd6f  (3 bytes)
DATA_tres_esperas:
	defb 020h	; bd6c
	defb 018h	; bd6d
	defb 010h	; bd6e

; ======================================================================
; CODIGO 0xbd6f..0xbdd9  (106 bytes)
; ======================================================================


nace_el_enemigo:
	ld hl,0e159h		;bd6f
	dec (hl)			;bd72   ; uno menos por colocar
	ld (ix+001h),000h		;bd73
	ld (ix+016h),001h		;bd77
	ld a,(0e366h)		;bd7b   ; con la marca puesta, se le da espera de disparo
	and a			;bd7e
	call nz,pon_la_espera_de_disparo		;bd7f
	ld a,(0e15ah)		;bd82
	ld (ix+000h),a		;bd85   ; su clase
	ld hl,0bee8h		;bd88   ; y cuantos pasos da
	call suma_a_a_hl		;bd8b
	ld b,(hl)			;bd8e
	djnz $+78		;bd8f
	call elige_a_quien_apuntar		;bd91   ; apunta a la nave
	call sale_por_el_lado_contrario		;bd94
rumbo_al_azar:
	call cuenta_de_enemigo		;bd97   ; el dado barato
	and 003h		;bd9a   ; dos bits: cuatro rumbos
	ld hl,0bdd9h		;bd9c   ; la tabla de rumbos
	call suma_a_a_hl		;bd9f
	ld a,(hl)			;bda2   ; el angulo
	ld (ix+00dh),a		;bda3   ; apuntado en el enemigo
	ld b,0e8h		;bda6   ; arriba del todo
	ld c,a			;bda8   ; con ese rumbo
	call pon_la_posicion		;bda9
	ld a,(ix+000h)		;bdac   ; la clase 0x1E
	cp 01eh		;bdaf   ; la mariposa
	jr z,L_BDC1		;bdb1
	cp 008h		;bdb3   ; la 8
	jp z,baja_despacio		;bdb5
	sub 01fh		;bdb8   ; y las 0x1F a 0x21
	cp 003h		;bdba
	jr c,L_BDC9		;bdbc
	jp apunta_y_avanza		;bdbe
L_BDC1:
	ld de,00060h		;bdc1   ; la vertical
	ld bc,00100h		;bdc4   ; y la horizontal
	jr L_BDD6		;bdc7
L_BDC9:
	ld a,(ix+011h)		;bdc9   ; salen a un lado o al otro
	and a			;bdcc
	ld de,00200h		;bdcd
	ld bc,00400h		;bdd0
	call nz,niega_bc		;bdd3
L_BDD6:
	jp pon_las_dos_velocidades		;bdd6

; ----------------------------------------------------------------------
; DATOS cuatro_rumbos: 0xBD9C indexa con los dos bits bajos del contador de
;   0xBB01
;   0xbdd9..0xbddd  (4 bytes)
DATA_cuatro_rumbos:
	defb 020h	; bdd9
	defb 060h	; bdda
	defb 0a0h	; bddb
	defb 0e0h	; bddc

; ======================================================================
; CODIGO 0xbddd..0xbee8  (267 bytes)
; ======================================================================


L_BDDD:
	djnz nace_con_rumbo_al_azar		;bddd
nace_por_arriba_o_por_abajo:
	call cuenta_de_enemigo		;bddf   ; el dado barato
	rra			;bde2   ; y sale por arriba
	ld a,030h		;bde3
	jr c,L_BDE8		;bde5
	rlca			;bde7   ; o por abajo
L_BDE8:
	ld (ix+007h),a		;bde8
	ld a,(ix+000h)		;bdeb
	cp 022h		;bdee   ; la clase 0x22
	jr z,L_BDF7		;bdf0
	ld bc,00805h		;bdf2
	jr L_BE03		;bdf5
L_BDF7:
	ld a,(0e152h)		;bdf7   ; alterna dos sitios
	rra			;bdfa
	ld bc,00403h		;bdfb
	jr c,L_BE03		;bdfe
	ld bc,0ecfdh		;be00
L_BE03:
	ld (ix+009h),b		;be03
	ld (ix+005h),c		;be06
	ret			;be09
nace_con_rumbo_al_azar:
	djnz L_BE28		;be0a
L_BE0C:
	ld a,r		;be0c   ; el refresco del Z80, de dado
	add a,a			;be0e
	sub 0d0h		;be0f   ; se busca un valor entre 0x30 y 0x70
	cp 040h		;be11
	jr c,L_BE0C		;be13   ; y si no cae ahi, otra vuelta
	ld b,0e8h		;be15
	ld c,a			;be17
	call pon_la_posicion		;be18
	ld a,(ix+000h)		;be1b
	cp 025h		;be1e   ; la clase 0x25 solo baja
	jr z,baja_despacio		;be20
apunta_y_arranca:
	call elige_a_quien_apuntar		;be22   ; apunta a la nave y arranca
	jp apunta_y_avanza		;be25
L_BE28:
	djnz L_BE66		;be28
	call cuenta_de_enemigo		;be2a   ; el dado barato
	rra			;be2d
	ld bc,00305h		;be2e
	jr c,L_BE36		;be31
	ld bc,0fdech		;be33
L_BE36:
	ld a,r		;be36   ; el refresco, otra vez de dado
	cp 0b0h		;be38   ; hasta que salga por debajo de 0xB0
	jr nc,L_BE36		;be3a
	ld l,000h		;be3c
	ld h,b			;be3e
	call pon_la_horizontal		;be3f
	ld b,a			;be42
	jr pon_la_posicion		;be43
nace_por_un_lado:
	call cuenta_de_enemigo		;be45   ; arriba
	rra			;be48
	ld b,0e8h		;be49
	jr c,L_BE4F		;be4b
	ld b,010h		;be4d   ; o abajo
L_BE4F:
	ld (ix+009h),b		;be4f
baja_despacio:
	ld (ix+003h),003h		;be52   ; tres pixeles por cuadro
	ret			;be56
nace_por_el_lado_contrario:
	ld a,(ix+013h)		;be57   ; segun por que lado tenga la nave
	cp 078h		;be5a
	ld bc,00805h		;be5c
	jr c,L_BE03		;be5f
	ld bc,0e8fbh		;be61
	jr L_BE03		;be64
L_BE66:
	djnz L_BE71		;be66
	ld (ix+003h),005h		;be68   ; cinco por cuadro
	ld bc,0e8c0h		;be6c
	jr pon_la_posicion		;be6f
L_BE71:
	djnz L_BE8D		;be71
	ld bc,00300h		;be73
	ld e,c			;be76
	ld d,c			;be77
	call pon_las_dos_velocidades		;be78
	ld (ix+00ch),020h		;be7b   ; y va hacia una esquina
	ld (ix+00dh),080h		;be7f
	ld bc,00880h		;be83
pon_la_posicion:
	ld (ix+007h),b		;be86
	ld (ix+009h),c		;be89
	ret			;be8c
L_BE8D:
	djnz L_BEA5		;be8d
	ld (ix+003h),0fdh		;be8f   ; sube deprisa
	ld b,0bfh		;be93
	ld hl,0e153h		;be95
	ld a,(hl)			;be98   ; y alterna los dos lados
	and a			;be99
	ld c,0e0h		;be9a
	jr z,L_BEA0		;be9c
	ld c,010h		;be9e
L_BEA0:
	xor 001h		;bea0
	ld (hl),a			;bea2
	jr pon_la_posicion		;bea3
L_BEA5:
	call elige_a_quien_apuntar		;bea5
	ld (ix+007h),0e8h		;bea8   ; arriba del todo
	call sale_por_el_lado_contrario		;beac
	ld a,(ix+000h)		;beaf   ; la clase 5
	cp 005h		;beb2
	jr z,nace_por_un_lado		;beb4
	cp 016h		;beb6   ; la 0x16
	jr z,baja_despacio		;beb8
	cp 012h		;beba   ; la 0x12
	jr z,L_BEC9		;bebc
	cp 013h		;bebe   ; la 0x13
	jr z,L_BED9		;bec0
	cp 017h		;bec2   ; y la 0x17
	jr z,nace_por_el_lado_contrario		;bec4
	jp apunta_y_avanza		;bec6
L_BEC9:
	ld a,(ix+011h)		;bec9
	and a			;becc
	ld de,00100h		;becd
	ld bc,00800h		;bed0
	call nz,niega_bc		;bed3
L_BED6:
	jp pon_las_dos_velocidades		;bed6
L_BED9:
	ld de,00700h		;bed9   ; baja deprisa
	ld bc,00300h		;bedc
	ld a,(ix+011h)		;bedf
	rra			;bee2
	call c,niega_bc		;bee3
	jr L_BED6		;bee6

; ----------------------------------------------------------------------
; DATOS pasos_de_entrada: 41 valores, uno por clase de enemigo: cuantos pasos
;   da al nacer antes de ponerse a lo suyo. 0xBD88 indexa aqui con la clase y
;   lo que saca es la cuenta del `djnz` de 0xBD8F
;   0xbee8..0xbf11  (41 bytes)
DATA_pasos_de_entrada:
	defb 000h	; bee8
	defb 003h	; bee9
	defb 003h	; beea
	defb 001h	; beeb
	defb 000h	; beec
	defb 000h	; beed
	defb 005h	; beee
	defb 000h	; beef
	defb 000h	; bef0
	defb 000h	; bef1
	defb 000h	; bef2
	defb 000h	; bef3
	defb 000h	; bef4
	defb 000h	; bef5
	defb 000h	; bef6
	defb 000h	; bef7
	defb 000h	; bef8
	defb 000h	; bef9
	defb 000h	; befa
	defb 000h	; befb
	defb 000h	; befc
	defb 000h	; befd
	defb 000h	; befe
	defb 000h	; beff
	defb 000h	; bf00
	defb 000h	; bf01
	defb 001h	; bf02
	defb 001h	; bf03
	defb 001h	; bf04
	defb 001h	; bf05
	defb 001h	; bf06
	defb 001h	; bf07
	defb 001h	; bf08
	defb 001h	; bf09
	defb 002h	; bf0a
	defb 002h	; bf0b
	defb 003h	; bf0c
	defb 003h	; bf0d
	defb 004h	; bf0e
	defb 006h	; bf0f
	defb 007h	; bf10

; ----------------------------------------------------------------------
; DATOS tabla_de_guiones_del_jefe: Cinco punteros, uno por fase
;   0xbf11..0xbf1b  (10 bytes)
DATA_tabla_de_guiones_del_jefe:
	defw 0bf1bh,0bf35h,0bf56h,0bf6fh,0bf88h	; bf11

; ----------------------------------------------------------------------
; DATOS guiones_del_jefe: La lista de clases que va soltando el jefe de cada
;   fase, cerrada con 0xFF: 0xBC8D la recorre con (0xE156) y vuelve a empezar
;   al llegar al final
;   0xbf1b..0xbfb1  (150 bytes)
DATA_guiones_del_jefe:
	defb 000h	; bf1b
	defb 000h	; bf1c
	defb 000h	; bf1d
	defb 000h	; bf1e
	defb 001h	; bf1f
	defb 001h	; bf20
	defb 001h	; bf21
	defb 002h	; bf22
	defb 002h	; bf23
	defb 002h	; bf24
	defb 003h	; bf25
	defb 003h	; bf26
	defb 004h	; bf27
	defb 021h	; bf28
	defb 000h	; bf29
	defb 001h	; bf2a
	defb 002h	; bf2b
	defb 003h	; bf2c
	defb 004h	; bf2d
	defb 000h	; bf2e
	defb 001h	; bf2f
	defb 002h	; bf30
	defb 003h	; bf31
	defb 004h	; bf32
	defb 021h	; bf33
	defb 0ffh	; bf34
	defb 005h	; bf35
	defb 005h	; bf36
	defb 005h	; bf37
	defb 006h	; bf38
	defb 006h	; bf39
	defb 007h	; bf3a
	defb 007h	; bf3b
	defb 006h	; bf3c
	defb 021h	; bf3d
	defb 007h	; bf3e
	defb 008h	; bf3f
	defb 008h	; bf40
	defb 009h	; bf41
	defb 009h	; bf42
	defb 021h	; bf43
	defb 00ah	; bf44
	defb 00ah	; bf45
	defb 00ah	; bf46
	defb 005h	; bf47
	defb 006h	; bf48
	defb 007h	; bf49
	defb 005h	; bf4a
	defb 006h	; bf4b
	defb 008h	; bf4c
	defb 005h	; bf4d
	defb 006h	; bf4e
	defb 007h	; bf4f
	defb 009h	; bf50
	defb 00ah	; bf51
	defb 008h	; bf52
	defb 007h	; bf53
	defb 021h	; bf54
	defb 0ffh	; bf55
	defb 00bh	; bf56
	defb 00bh	; bf57
	defb 00bh	; bf58
	defb 00ch	; bf59
	defb 00ch	; bf5a
	defb 00dh	; bf5b
	defb 00dh	; bf5c
	defb 00dh	; bf5d
	defb 00eh	; bf5e
	defb 00eh	; bf5f
	defb 00eh	; bf60
	defb 00fh	; bf61
	defb 00fh	; bf62
	defb 010h	; bf63
	defb 010h	; bf64
	defb 010h	; bf65
	defb 00bh	; bf66
	defb 00ch	; bf67
	defb 00dh	; bf68
	defb 00eh	; bf69
	defb 00fh	; bf6a
	defb 010h	; bf6b
	defb 00eh	; bf6c
	defb 00fh	; bf6d
	defb 0ffh	; bf6e
	defb 011h	; bf6f
	defb 011h	; bf70
	defb 011h	; bf71
	defb 012h	; bf72
	defb 012h	; bf73
	defb 012h	; bf74
	defb 013h	; bf75
	defb 013h	; bf76
	defb 014h	; bf77
	defb 014h	; bf78
	defb 014h	; bf79
	defb 021h	; bf7a
	defb 021h	; bf7b
	defb 016h	; bf7c
	defb 016h	; bf7d
	defb 016h	; bf7e
	defb 011h	; bf7f
	defb 012h	; bf80
	defb 013h	; bf81
	defb 014h	; bf82
	defb 015h	; bf83
	defb 016h	; bf84
	defb 021h	; bf85
	defb 013h	; bf86
	defb 0ffh	; bf87
	defb 017h	; bf88
	defb 017h	; bf89
	defb 017h	; bf8a
	defb 017h	; bf8b
	defb 018h	; bf8c
	defb 018h	; bf8d
	defb 018h	; bf8e
	defb 021h	; bf8f
	defb 019h	; bf90
	defb 019h	; bf91
	defb 019h	; bf92
	defb 01ah	; bf93
	defb 01ah	; bf94
	defb 01ah	; bf95
	defb 01ah	; bf96
	defb 01bh	; bf97
	defb 01bh	; bf98
	defb 01bh	; bf99
	defb 01bh	; bf9a
	defb 01ch	; bf9b
	defb 01ch	; bf9c
	defb 01ch	; bf9d
	defb 01dh	; bf9e
	defb 01dh	; bf9f
	defb 01dh	; bfa0
	defb 01eh	; bfa1
	defb 01eh	; bfa2
	defb 021h	; bfa3
	defb 01fh	; bfa4
	defb 01fh	; bfa5
	defb 020h	; bfa6
	defb 019h	; bfa7
	defb 01ah	; bfa8
	defb 01bh	; bfa9
	defb 01ch	; bfaa
	defb 01dh	; bfab
	defb 01eh	; bfac
	defb 01fh	; bfad
	defb 020h	; bfae
	defb 021h	; bfaf
	defb 0ffh	; bfb0

; ----------------------------------------------------------------------
; DATOS velocidades_del_jefe: 0xBC9F indexa con el paso del guion: los seis
;   bits bajos van a (0xE15A) y los dos altos, rotados, a (0xE159)
;   0xbfb1..0xbff7  (70 bytes)
DATA_velocidades_del_jefe:
	defb 08ch	; bfb1
	defb 018h	; bfb2
	defb 08dh	; bfb3
	defb 098h	; bfb4
	defb 08eh	; bfb5
	defb 028h	; bfb6
	defb 08fh	; bfb7
	defb 0d8h	; bfb8
	defb 09eh	; bfb9
	defb 0c8h	; bfba
	defb 090h	; bfbb
	defb 018h	; bfbc
	defb 0d1h	; bfbd
	defb 018h	; bfbe
	defb 084h	; bfbf
	defb 018h	; bfc0
	defb 09ah	; bfc1
	defb 018h	; bfc2
	defb 092h	; bfc3
	defb 098h	; bfc4
	defb 0d3h	; bfc5
	defb 0d8h	; bfc6
	defb 094h	; bfc7
	defb 018h	; bfc8
	defb 095h	; bfc9
	defb 018h	; bfca
	defb 096h	; bfcb
	defb 0efh	; bfcc
	defb 0c5h	; bfcd
	defb 01fh	; bfce
	defb 09bh	; bfcf
	defb 028h	; bfd0
	defb 0e5h	; bfd1
	defb 0f8h	; bfd2
	defb 09ch	; bfd3
	defb 028h	; bfd4
	defb 0e2h	; bfd5
	defb 0b8h	; bfd6
	defb 0c1h	; bfd7
	defb 028h	; bfd8
	defb 0e4h	; bfd9
	defb 0a8h	; bfda
	defb 067h	; bfdb
	defb 018h	; bfdc
	defb 0c2h	; bfdd
	defb 0e8h	; bfde
	defb 0e6h	; bfdf
	defb 038h	; bfe0
	defb 0e3h	; bfe1
	defb 038h	; bfe2
	defb 0dfh	; bfe3
	defb 0e8h	; bfe4
	defb 0ddh	; bfe5
	defb 028h	; bfe6
	defb 0c3h	; bfe7
	defb 028h	; bfe8
	defb 0d7h	; bfe9
	defb 018h	; bfea
	defb 0c6h	; bfeb
	defb 018h	; bfec
	defb 0d8h	; bfed
	defb 018h	; bfee
	defb 0a0h	; bfef
	defb 0e8h	; bff0
	defb 0d9h	; bff1
	defb 0d8h	; bff2
	defb 0a8h	; bff3
	defb 0e8h	; bff4
	defb 0ffh	; bff5
	defb 0ffh	; bff6

; ----------------------------------------------------------------------
; DATOS marca_oculta_de_konami: BA B7 9A AC 81 91 06 40 AA: el titulo en
;   katakana -tsu-i-n-bii-, el 0x06 de la longitud, el 07 40 del RC-740 y el
;   0xAA que cierra. Los seis ultimos son justamente los que Nemesis (RC-742)
;   va buscando por las ranuras 0, 0x80, 0x84, 0x88 y 0x8C en su rutina de
;   0x505A: asi sabe que Twin Bee esta enchufado al lado
;   0xbff7..0xc000  (9 bytes)
DATA_marca_oculta_de_konami:
	defb 0bah,0b7h,09ah,0ach,081h,091h,006h,040h,0aah	; bff7  .......@.
