        .include  "inter.inc"
.text 
    /* Notas */    
        .set FA, 1433     @ Retardo para nota Fa = F
        .set SOLs, 1204 @ Retardo para nota SOLs = Gs
        .set LA, 1136     @ Retardo para nota La = A
        .set LAs, 1072
        .set SI, 1012
        .set DO, 1915
        .set RE, 1706
        .set SOL, 1278

        .set DOH, 956    @ Retardo para nota DoH = cH
        .set DOHs, 902
        .set REH, 851
        .set REHs, 803

        .set MIH, 758     @ Retardo para nota MIH = eH
        .set FAH, 716     @ Retardo para nota FAH = FH
        .set FAHs, 676
        .set SOLH, 638
        .set SOLHs, 602
        .set LAH, 568
        .set SILEN, 555  @silencio


    /* duraciones */
        .set NG,  500000
        .set CORP,  375000
        .set COR,    250000
        .set FUS,   125000
        .set BL, 1000000


@ Inicio Compatibilidad RPi3
	    mrs r0, cpsr
	    mov r0, #0b11010011
	    msr spsr_cxsf, r0
	    add r0, pc, #4
	    msr ELR_hyp, r0
	    eret
@ Fin

/* Agrego vector interrupcion */
        mov     r0,  #0
        ADDEXC  0x18, irq_handler
		addexc	0x1c, fiq_handler

/* Inicializo la pila en modos IRQ y SVC */
        mov     r0, #0b11010010         @ Modo IRQ, FIQ&IRQ desact
        msr     cpsr_c, r0
        mov     sp, #0x8000
        mov     r0, #0b11010011         @ Modo SVC, FIQ&IRQ desact
        msr     cpsr_c, r0
        mov     sp, #0x8000000

/* Configuro GPIOs como salida */
        ldr     r0, =GPBASE
        @ guia bits    xx999888777666555444333222111000
        ldr     r1, =0b00001000000000000001000000000000         @ Led 9 y altavoz
        str     r1, [r0, #GPFSEL0]

        ldr     r1, =0b00000000001000000000000000001001         @ Led 10, 11, 17
        str     r1, [r0, #GPFSEL1]

        ldr     r1, =0b00001000001000000000000001000000         @ Led 22, 27
        str     r1, [r0, #GPFSEL2]

/* Programo contador C1 para futura interrupcion */
        ldr     r0, =STBASE
        ldr     r1, [r0, #STCLO]
        add     r1, #2000                          @ Medio segundo
        str     r1, [r0, #STC1]                 @ C1
        str     r1, [r0, #STC3]                 @ C3
		
/* Habilito interrupciones, local y globalmente */
        ldr     r0, =INTBASE
        mov     r1, #0b0010
        str     r1, [r0, #INTENIRQ1]			@ C1 a IRQ
        
		mov		r1, #0b10000011
		str		r1, [r0, #INTFIQCON]			@ C3 a FIQ
		
		mov     r0, #0b00010011                 @ Modo SVC, IRQ, FIQ activo
        msr     cpsr_c, r0

/* Repetir para siempre */
    bucle:  b       bucle

irq_handler:									@ Controla luz
	/* Inicializar GPBASE, cuenta */    
        push	{r0, r1, r2}
        ldr     r0, =GPBASE
        ldr     r4, =refret
	    ldr     r1, =cuenta
    /* Apagar leds */ 
        @ guia bits    10987654321098765432109876543210
        ldr     r2, =0b00001000010000100000111000000000
        str     r2, [r0, #GPCLR0]               @ Apago Leds
    /* Controlar contador */   
        ldr     r2, [r1]
        subs    r2, #1
        moveq   r2, #6                          @ Contador de secuencia
        str     r2, [r1]
    /* Nuevas luces desde el array */    
        ldr     r2, [r1, +r2, LSL #2]           @ Buscar parte de la secuencia
        str     r2, [r0, #GPSET0]

    /* Reset C1 */
        ldr     r0, =STBASE
        mov     r2, #0b0010
        str     r2, [r0, #STCS]
    /* Nueva espera C1 */
        ldr     r2, [r0, #STCLO]
        @ldr     r1, =200000
        
        ldr     r5, [r1]
        ldr     r1, [r4, +r5, LSL #2]
        
        add     r2, r1
        str     r2, [r0, #STC1]
	/* Salida */
        pop 	{r0, r1, r2}
	    subs	pc, lr, #4
	
fiq_handler:									@ Controla sonido
    /* Inicializar GPBASE, bitson */
        ldr     r8, =GPBASE
        ldr     r9, =bitson
        ldr     r11, =cuenta
	    
	/* Invertir estado bitson */
	    ldr     r10, [r9]
        eors    r10, #1
        str     r10, [r9]
    
	/* Leer nueva frecuencia */
        ldr     r10, [r11]
        ldr     r9, [r9, +r10, LSL #2]

    /* Funcionamiento de altavoz */
	    mov     r10, #0b10000
        streq   r10, [r8, #GPSET0]               @ Escribir altavoz
        strne   r10, [r8, #GPCLR0]               @ Apagar altavoz
	
	/* Reset Temp C3 */
	    ldr     r8, =STBASE
        mov     r10, #0b1000
        str     r10, [r8, #STCS]
	
	/* Nuevo retardo con array */
        ldr     r10, [r8, #STCLO]
	    add     r10, r9
        str     r10, [r8, #STC3]
	/* Salida */
	    subs	pc, lr, #4

	

cuenta:     .word 1       
luces:      .word 0b0000000000100000000000000000
            .word 0b0000000000000000100000000000
            .word 0b0000000000000000010000000000
            .word 0b0000000000000000001000000000
            .word 0b1000000000000000000000000000
            .word 0b0000010000000000000000000000

bitson:     .word 0
sonidos:	.word RE
			.word LA
			.word SOL
			.word FA
			.word RE
			.word LA

refret:     .word 0
retardos:	.word NG
			.word NG
			.word COR
			.word COR
			.word NG
			.word NG
