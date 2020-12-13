        .include  "inter.inc"
.text 
    /* Notas 500000/frec */    
        /* FAes */
            .set FA, 1433
            .set FAH, 716    
            .set FAHs, 676
        
        /* LAes */
            .set LA, 1136     
            .set LAs, 1072
            .set LAH, 568
			.set LAb, 2272

        /* SIes */
            .set SI, 1012
            .set SIs, 1072
			.set SIb, 2024
			.set SIH, 506

        /* DOes */
            .set DO, 1915
            .set DOH, 956    
            .set DOHs, 902
			.set DOHH, 478
        
        /* SOLes */
            .set SOL, 1278
            .set SOLs, 1204 
            .set SOLH, 638
            .set SOLHs, 602
			.set SOLb, 2551

        /* REes */
            .set RE, 1706
            .set REH, 851
            .set REHs, 803
        
        /* MIes */
            .set MI, 1515
            .set MIH, 758
            .set MIHs, 803
        
        /* SILENCIO */
            .set SILEN, 20
        

    /* LUCES */
        /* Rojas */
            @ guia bits   10987654321098765432109876543210
            .set    RI, 0b00000000000000000000001000000000
            .set    RD, 0b00000000000000000000010000000000

        /* Verdes */
            @ guia bits   10987654321098765432109876543210
            .set    VI, 0b00000000010000000000000000000000
            .set    VD, 0b00001000000000000000000000000000

        /* Naranjas */
            @ guia bits   10987654321098765432109876543210
            .set    NI, 0b00000000000000000000100000000000
            .set    ND, 0b00000000000000100000000000000000

        /* Apagado */
            @ guia bits   10987654321098765432109876543210
            .set    AP, 0b00000000000000000000000000000000

    /* duraciones */
        /*.set    NG,      500000
        .set    CORP,    375000
        .set    COR,     250000
        .set    FUS,     125000
        .set    BL,     1000000
        .set    SEMICOR, 125000
        .set    NGP,     750000*/

		.set    NG, 750000
        .set    CORP, 562500
        .set    COR, 375000
        .set    FUS, 187500
        .set    BL, 1500000
        .set    SEMICOR, 187500
        .set    NGP, 1125000

/* Inicio Compatibilidad RPi3 */
	    mrs r0, cpsr
	    mov r0, #0b11010011
	    msr spsr_cxsf, r0
	    add r0, pc, #4
	    msr ELR_hyp, r0
	    eret

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
/* Configurar botones para interrumpir */
        mov     r1, #0b00000000000000000000000000001100
        str     r1, [r0, #GPFEN0]

/* Programo contadores C1 y C3 para futuras interrupciones */
        ldr     r0, =STBASE
        ldr     r1, [r0, #STCLO]
        add     r1, #2                          
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

irq_handler:									            @ Controla luz    
    /* Inicializar GPBASE, cuenta */    
        push	{r0, r1, r2}
        ldr     r0, =GPBASE
		ldr     r1, =contador
		
    /* Leer boton para iniciar */
        ldr     r5, =pulsador
		
		/* Patron 1 */
            ldr     r6, [r0, #GPEDS0]                           @ Ver estado de boton
            ands    r6, #0b00000000000000000000000000000100     @ Comprobar si se pulsa
            movne   r6, #1                                      @ Si pulsa preparar 1
            strne   r6, [r5]                                    @ Meter 1 en pulsador
            movne   r6, #0b00000000000000000000000000001100	
	        strne   r6, [r0, #GPEDS0]
        
        /* Patron 2 */
            ldr     r6, [r0, #GPEDS0]                           @ Ver estado de boton
            ands    r6, #0b00000000000000000000000000001000     @ Comprobar si se pulsa
            movne   r6, #2                                      @ Si pulsa preparar 2
            strne   r6, [r5]                                    @ Meter 2 en pulsador
            movne   r6, #0b00000000000000000000000000001100	
	        strne   r6, [r0, #GPEDS0]
        
        /* No patron */
            ldr     r6, [r5]                                    @ Leer contenido pulsador
            cmp     r6, #0                                      @ Mirar si hay un 0
            beq     finluz                                      @ Si lo hay no hacer nada

    /* Apagar leds */ 
        @ guia bits    10987654321098765432109876543210
        ldr     r2, =0b00001000010000100000111000000000
        str     r2, [r0, #GPCLR0]               @ Apago Leds
    
	/* Controlar contador */   
		ldr     r2, [r1]
        subs    r2, #1
        moveq   r2, #157                                      @ Contador de secuencia
        str     r2, [r1]
    /* Nuevas luces desde el array */    
        cmp     r6, #1
		ldreq   r7, =refluz1
        ldreq   r2, [r7, +r2, LSL #2]                       @ Buscar parte de patron 1
        
        cmp     r6, #2
		ldreq   r8, =refluz2
        ldreq   r2, [r8, +r2, LSL #2]                       @ Buscar parte de patron 2
        
        str     r2, [r0, #GPSET0]

    finluz:
    /* Reset Temp C1 */
        ldr     r0, =STBASE
        mov     r2, #0b0010
        str     r2, [r0, #STCS]
    
    /* Nueva espera C1 */
        ldr     r2, [r0, #STCLO]
        ldr     r5, [r1]
        cmp     r6, #0                                      @ Boton pulsado?
        ldrne   r4, =refret
		ldrne   r1, [r4, +r5, LSL #2]                       @ Manejo Array si boton pulsado
        add     r2, r1
        str     r2, [r0, #STC1]

	/* Salida */
        pop 	{r0, r1, r2}
	    subs	pc, lr, #4
	
fiq_handler:									            @ Controla sonido
    /* Inicializar GPBASE y bitson */
        ldr     r8, =GPBASE
		ldr     r9, =bitson
        
    /* Comprobacion del boton */    
        ldr     r5, =pulsador
		ldr     r6, [r5]
        cmp     r6, #0
        beq     finsonido
	    
	/* Invertir estado bitson */
		ldr     r10, [r9]
        eors    r10, #1
        str     r10, [r9]
    
	/* Leer nueva frecuencia */
        ldr     r11, =contador
		ldr     r10, [r11]
        ldr     r9, [r9, +r10, LSL #2]

    /* Funcionamiento de altavoz */
	    mov     r10, #0b10000
        streq   r10, [r8, #GPSET0]                          @ Escribir altavoz
        strne   r10, [r8, #GPCLR0]                          @ Apagar altavoz
	
	finsonido:
    /* Reset Temp C3 */
        ldr     r8, =STBASE
        mov     r10, #0b1000
        str     r10, [r8, #STCS]
	
	/* Nueva espera C3 */
        ldr     r10, [r8, #STCLO]
	    add     r10, r9
        str     r10, [r8, #STC3]
	/* Salida */
        subs	pc, lr, #4

pulsador:   .word 0											@ 0 Desactivado, 1 Patron Logico, 2 Patron Estetico
contador:   .word 1											@ Contador de la secuencia

refluz1:    .word 0       
luces1:     .word AP										@ Patron Logico
			.word AP
			.word RI + RD + NI + ND + VI + VD    @ DOH A LA VEZ
			.word AP
			.word RI + RD + NI + ND + VI
			.word RI + RD + NI + ND
			.word RI + RD + NI
			.word RI + RD
			.word RI
			.word AP
			.word RI + RD + NI + ND + VI + VD
			.word RI + RD + VI + VD
			.word RI + RD + VD
			.word RI + VD
			.word RD + VI
			.word NI + ND @
			.word RI + NI + ND + VD
			.word AP
			.word RI + VD
			.word NI + ND
			.word RD + NI + ND + VI
			.word AP
			.word RD + NI + ND + VI
			.word RD + VI	@
			.word RI + RD + VI + VD
			.word AP
			.word NI + ND
			.word RI + RD + VI + VD
			.word RI + VD
			.word AP
			.word NI + ND
			.word RD + ND + VD @ FIN QUINTA TODO OK
            .word RD
            .word AP
            .word RD + ND + VD
            .word RD + ND
			.word RD     
			.word AP
			.word RD
			.word RI + NI + VI @
            .word RI        
			.word AP
			.word RI + NI + VI
			.word RI + NI
			.word RI   
			.word AP
			.word RI
			.word RI + RD + NI + ND + VI + VD @
			.word VI + VD         
			.word AP
			.word RI + RD + NI + ND + VI + VD
			.word NI + ND + VI + VD
			.word VI + VD
			.word AP
			.word NI + ND + VI + VD
			.word RI + RD + NI + ND + VI + VD @
            .word VI + VD         
			.word AP
			.word RD + NI + ND + VI + VD
			.word NI + ND + VI + VD
            .word VI + VD
			.word AP
			.word RI + RD + NI + ND + VI + VD
			.word RI + RD + NI + ND @ FIN CUARTA LINEA 
            .word RI + RD      
			.word AP
			.word RI + RD + NI + ND + VI + VD
			.word RI + RD + NI + ND
            .word RI + RD     
			.word AP
			.word RI + RD + NI + ND + VI + VD
			.word RI + RD + NI + ND @  
            .word RI + RD     
			.word AP
			.word RI + RD + NI + ND + VI + VD
			.word RI + RD + NI + ND  
            .word RI + RD    
			.word AP
			.word RI + RD + NI + ND
			.word RI + RD + NI			@  
			.word RI + RD + NI + ND + VI 
			.word RI + RD + NI + ND + VI + VD
            .word RI + RD + NI + ND + VI
			.word RI + RD + NI + ND @
			.word RI + RD
			.word RI + RD			
			.word RI + RD + NI + ND + VI + VD 
			.word RI + RD + NI + ND  @ FIN TERCERA LINEA
			.word RI + RD             
			.word AP
            .word RI + RD + NI + ND + VI + VD
			.word RI + RD + NI + ND
			.word RI + RD  
			.word AP
			.word RI + RD + NI + ND + VI + VD
			.word RI + RD + NI + ND @
            .word RI + RD            
			.word AP
			.word RI + RD + NI + ND + VI + VD
			.word RI + RD + NI + ND
			.word RI + RD  
			.word AP
			.word RI + RD + NI
			.word RI + RD + NI + ND		@
            .word RI + RD             
			.word RI
			.word RI + RD + NI + ND + VI + VD
			.word RI + RD + NI + ND  
			.word RI + RD
			.word RI                            @
            .word RI + RD + NI + ND + VI + VD
			.word AP                            @ FIN SEGUNDA LINEA
			.word RI + RD + NI + ND + VI + VD  
			.word RI + RD + NI + ND
			.word RI + RD
			.word AP  
			.word RI + RD + NI + ND + VI + VD  
			.word RI + RD + NI + ND           @
			.word RI + RD
			.word AP
			.word RI + RD + NI + ND + VI + VD  
			.word RI + RD + NI + ND
			.word RI + RD
			.word AP
            .word RI                        
			.word RI + RD                     @      
			.word RI + RD + NI + ND
			.word RI  
			.word RI + RD + NI + ND + VI + VD
			.word RI + RD
            .word RI + RD + NI + ND
			.word RI + RD + NI                    @
			.word RI + RD + NI + ND + VI + VD
			.word RI + RD + NI + ND @ FIN PRIMERA LINEA     
			.word RI + RD
			.word AP
			.word RI + RD + NI + ND + VI + VD
            .word RI + RD + NI + ND     
			.word RI + RD
			.word AP
			.word RI + RD + NI + ND + VI + VD    
            .word RI + RD + NI + ND @     
			.word RI + RD
			.word AP
			.word RI + RD + NI + ND + VI + VD   
            .word RI + RD + NI + ND     
			.word RI + RD
			.word AP
			.word RI   
			.word RI + RD + NI + ND 	@
			.word RI + RD
            .word AP
			.word RI + RD + NI + ND + VI + VD
			.word RI + RD + NI + ND
			.word RI + RD
			.word RI + RD + NI + ND + VI + VD @
			.word RI + RD + NI

refluz2:    .word 0
luces2:     .word RI + RD + NI + ND + VI + VD				@ Patron Estetico
			.word RD + NI + ND + VI + VD
			.word NI + ND + VI + VD
			.word ND + VI + VD
			.word VI + VD
			.word VD
			.word VI + VD
			.word ND + VI + VD
			.word NI + ND + VI + VD
			.word RD + NI + ND + VI + VD
			.word RI + RD + NI + ND + VI + VD
			.word RI + RD + NI + ND + VI
			.word RI + RD + NI + ND
			.word RI + RD + NI
			.word RI + RD
			.word RI
			.word RI + RD
			.word RI + RD + NI    
			.word RI + RD + NI + ND 
			.word RI + RD + NI + ND + VI
            .word RI + RD + NI + ND + VI + VD
			.word RD + NI + ND + VI + VD
			.word NI + ND + VI + VD
			.word ND + VI + VD
			.word VI + VD   
			.word VD
			.word VI + VD
            .word ND + VI + VD
			.word NI + ND + VI + VD
			.word RD + NI + ND + VI + VD
			.word RI + RD + NI + ND + VI + VD
			.word RI + RD + NI + ND + VI        @ FIN QUINTA LINEA
            .word RI + RD + NI + ND
            .word RI + RD + NI
            .word RI + RD
            .word RI    
            .word RI + RD       
			.word RI + RD + NI
			.word RI + RD + NI + ND
			.word RI + RD + NI + ND + VI    
            .word RI + RD + NI + ND + VI + VD    
			.word RD + NI + ND + VI + VD
			.word NI + ND + VI + VD
			.word ND + VI + VD    
            .word VI + VD       
			.word VD
			.word VI + VD
			.word ND + VI + VD    
			.word NI + ND + VI + VD 
			.word RD + NI + ND + VI + VD
            .word RI + RD + NI + ND + VI + VD
			.word RI + RD + NI + ND + VI
			.word RI + RD + NI + ND
			.word RI + RD + NI
			.word RI + RD   
			.word RI    
            .word RI + RD       
			.word RI + RD + NI
			.word RI + RD + NI + ND
			.word RI + RD + NI + ND + VI    
            .word RI + RD + NI + ND + VI + VD    
			.word RD + NI + ND + VI + VD
			.word NI + ND + VI + VD
			.word ND + VI + VD    
            .word VI + VD       
			.word VD
			.word VI + VD
			.word ND + VI + VD    
			.word NI + ND + VI + VD 
			.word RD + NI + ND + VI + VD
            .word RI + RD + NI + ND + VI + VD
			.word RI + RD + NI + ND + VI
			.word RI + RD + NI + ND
			.word RI + RD + NI
			.word RI + RD   
			.word RI    
            .word RI + RD       
			.word RI + RD + NI
			.word RI + RD + NI + ND
			.word RI + RD + NI + ND + VI    
            .word RI + RD + NI + ND + VI + VD    
			.word RD + NI + ND + VI + VD
			.word NI + ND + VI + VD
			.word ND + VI + VD    
            .word VI + VD       
			.word VD
			.word VI + VD
			.word ND + VI + VD    
			.word NI + ND + VI + VD 
			.word RD + NI + ND + VI + VD
            .word RI + RD + NI + ND + VI + VD
			.word RI + RD + NI + ND + VI
			.word RI + RD + NI + ND
			.word RI + RD + NI
			.word RI + RD   
			.word RI    
            .word RI + RD       
			.word RI + RD + NI
			.word RI + RD + NI + ND
			.word RI + RD + NI + ND + VI    
            .word RI + RD + NI + ND + VI + VD    
			.word RD + NI + ND + VI + VD
			.word NI + ND + VI + VD
			.word ND + VI + VD    
            .word VI + VD       
			.word VD
			.word VI + VD
			.word ND + VI + VD    
			.word NI + ND + VI + VD 
			.word RD + NI + ND + VI + VD
            .word RI + RD + NI + ND + VI + VD
			.word RI + RD + NI + ND + VI
			.word RI + RD + NI + ND
			.word RI + RD + NI
			.word RI + RD   
			.word RI    
            .word RI + RD       
			.word RI + RD + NI
			.word RI + RD + NI + ND
			.word RI + RD + NI + ND + VI    
            .word RI + RD + NI + ND + VI + VD    
			.word RD + NI + ND + VI + VD
			.word NI + ND + VI + VD
			.word ND + VI + VD    
            .word VI + VD       
			.word VD
			.word VI + VD
			.word ND + VI + VD    
			.word NI + ND + VI + VD 
			.word RD + NI + ND + VI + VD
            .word RI + RD + NI + ND + VI + VD
			.word RI + RD + NI + ND + VI
			.word RI + RD + NI + ND
			.word RI + RD + NI
			.word RI + RD   
			.word RI
			.word RI    
            .word RI + RD       
			.word RI + RD + NI
			.word RI + RD + NI + ND
			.word RI + RD + NI + ND + VI    
            .word RI + RD + NI + ND + VI + VD    
			.word RD + NI + ND + VI + VD
			.word NI + ND + VI + VD
			.word ND + VI + VD    
            .word VI + VD       
			.word VD
			.word VI + VD
			.word ND + VI + VD    
			.word NI + ND + VI + VD 
			.word RD + NI + ND + VI + VD
            .word RI + RD + NI + ND + VI + VD
			.word RI + RD + NI + ND + VI
			.word RI + RD + NI + ND
			.word RI + RD + NI
			.word RI + RD   
			.word RI

bitson:     .word 0
sonidos:    .word SILEN										@ Patron Sonoro
			.word SILEN
			.word DOHH      @ DOH A LA VEZ y FIN
			.word SIH
			.word LAH
			.word SOLH
			.word DOH
			.word SIs
			.word LAs
			.word SOL
			.word DO
			.word SIb
			.word LAb
			.word SOLb
			.word DO
			.word RE		@
			.word MI
			.word SOLb
			.word RE
			.word MI
			.word FA
			.word LAb
			.word FA
			.word MI		@
			.word RE
			.word LAb
			.word MI
			.word RE
			.word DO
			.word LAb
			.word MI
			.word FA        @ FIN QUINTA LINEA
            .word MI
            .word DO
            .word SOL
            .word FA
            .word MI
            .word DO
            .word SOL
            .word LAs       @
            .word FA   
            .word DO
            .word LAs 
            .word SOL
            .word FA   
            .word DO
            .word LAs
            .word SIs       @
            .word SOL
            .word MI
            .word SIs   
            .word LAs
            .word SOL
            .word MI
            .word SIs
            .word DOH       @
            .word LAs
            .word MI
            .word DOH 
            .word SIs
            .word LAs
            .word MI
            .word DOH
            .word SIs       @ FIN CUARTA LINEA
            .word LAs
            .word FA
            .word DOH
            .word SIs       
            .word LAs
            .word FA
            .word DOH
            .word SIs       @
            .word LAs
            .word FA
            .word DOH
            .word SIs
            .word LAs
            .word FA
            .word DOH
            .word SIs       @
            .word REH
            .word MIHs
			.word REH
			.word DOH       @
			.word SIs    
			.word SIs
			.word FAH
            .word DOH     @ FIN TERCERA LINEA
			.word SIs
			.word SOL
			.word REH    
            .word DOH       
			.word SIs
			.word SOL
			.word REH    
            .word DOH     @  
			.word SIs
			.word SOL
			.word REH    
            .word DOH       
			.word SIs
			.word SOL
			.word REH    
			.word FAH      @
			.word MIHs
            .word DOH
			.word SOLH
			.word FAH
			.word MIHs
			.word DOH      @
			.word SOLH
            .word FA    @ FIN SEGUNDA LINEA
            .word DOH
            .word SIs
            .word LAs
            .word FA
            .word DOH  
            .word SIs   @
            .word LAs
            .word FA
            .word DOH
            .word SIs
            .word LAs
            .word FA
            .word DOH
            .word REH   @
            .word MIHs
            .word SIs
            .word FAH    
            .word REH
            .word MIHs
            .word SIs     @
            .word FAH
            .word DOH     @ FIN PRIMERA LINEA
			.word SIs
			.word SOL
			.word REH    
            .word DOH       
			.word SIs
			.word SOL
			.word REH    
            .word DOH     @  
			.word SIs
			.word SOL
			.word REH    
            .word DOH       
			.word SIs
			.word SOL
			.word REH    
			.word FAH      @
			.word MIHs
            .word DOH
			.word SOLH
			.word FAH
			.word MIHs
			.word DOH      @
			.word SOLH
            

refret:     .word 0
retardos:	.word COR										@ Patron Retardos
			.word COR
			.word NG      @ DOH A LA VEZ
			.word SEMICOR
			.word SEMICOR
			.word COR
			.word COR 
			.word SEMICOR @
			.word SEMICOR
			.word COR
			.word COR 
			.word SEMICOR
			.word SEMICOR
			.word COR
			.word COR 
			.word SEMICOR @
			.word SEMICOR
			.word COR
			.word COR 
			.word SEMICOR 
			.word SEMICOR
			.word COR
			.word COR
			.word SEMICOR @
			.word SEMICOR
			.word COR
			.word COR
			.word SEMICOR
			.word SEMICOR
			.word COR
			.word COR 
			.word SEMICOR  @  FIN QUINTA LINEA   
			.word SEMICOR
			.word COR     
			.word COR
            .word SEMICOR       
			.word SEMICOR
			.word COR     
			.word COR
            .word SEMICOR  @     
			.word SEMICOR
			.word COR     
			.word COR
            .word SEMICOR       
			.word SEMICOR
			.word COR     
			.word COR
            .word SEMICOR  @     
			.word SEMICOR
			.word COR     
			.word COR
            .word SEMICOR       
			.word SEMICOR
			.word COR     
			.word COR
            .word SEMICOR  @     
			.word SEMICOR
			.word COR     
			.word COR
            .word SEMICOR       
			.word SEMICOR
			.word COR     
			.word COR
            .word SEMICOR   @ FIN CUARTA LINEA      
			.word SEMICOR
			.word COR     
			.word COR
            .word SEMICOR       
			.word SEMICOR
			.word COR     
			.word COR
            .word SEMICOR   @       
			.word SEMICOR
			.word COR     
			.word COR
            .word SEMICOR       
			.word SEMICOR
			.word COR     
			.word COR
			.word CORP      @
			.word CORP
            .word CORP
			.word CORP
            .word SEMICOR   @
			.word SEMICOR
			.word NG
			.word NGP
            .word SEMICOR   @ FIN TERCERA LINEA 
			.word SEMICOR
			.word COR     
			.word COR     
            .word SEMICOR       
			.word SEMICOR
			.word COR     
			.word COR     
			.word SEMICOR   @    
			.word SEMICOR
			.word COR     
			.word COR     
            .word SEMICOR       
			.word SEMICOR
			.word COR     
			.word COR           
			.word SEMICOR   @
			.word SEMICOR
            .word NG
			.word NG
			.word SEMICOR
			.word SEMICOR
			.word NGP       @
			.word NGP
			.word NG        @ FIN SEGUNDA LINEA
			.word COR
            .word SEMICOR
			.word SEMICOR
			.word COR
			.word COR 
			.word SEMICOR   @
			.word SEMICOR
			.word COR
			.word COR 
			.word SEMICOR
			.word SEMICOR
			.word COR
			.word COR
            .word SEMICOR   @
			.word SEMICOR
			.word NG
			.word NG          
			.word SEMICOR
			.word SEMICOR
            .word NGP       @
			.word NGP
			.word SEMICOR   @ FIN PRIMERA LINEA 
			.word SEMICOR
			.word COR     
			.word COR     
            .word SEMICOR       
			.word SEMICOR
			.word COR     
			.word COR     
			.word SEMICOR   @    
			.word SEMICOR
			.word COR     
			.word COR     
            .word SEMICOR       
			.word SEMICOR
			.word COR     
			.word COR           
			.word SEMICOR   @
			.word SEMICOR
            .word NG
			.word NG
			.word SEMICOR
			.word SEMICOR
			.word NGP       @
			.word NGP
            