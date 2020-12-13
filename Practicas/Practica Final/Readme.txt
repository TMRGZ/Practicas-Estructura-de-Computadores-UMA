Mediante FIQ hace sonidos y mediante IRQ enciende los leds y controla los tiempos
Los arrays dependen de una instruccion tipo:
	ldr   rX, [rY, +rX, LSL #2] 
		rX es el contenido del indice y por tanto comun en todos los arrays
		rY es la referencia al array usado, refluz1/2 para leds, bitson para sonidos y refret para tiempos
Al iniciar el programa queda en espera a que enciendas uno de los dos botones
Uno da un patron de leds "logico" que se enciende segun las notas reproducidas
El otro de un patron centrado en estetica
La cancion que suena es la principal de Juego de Tronos
El patron de luz se puede cambiar al vuelo, cambiando entre el logico y el estetico sin parar la cancion
Una vez terminada la cancion se para y vuelve a empezar automaticamente