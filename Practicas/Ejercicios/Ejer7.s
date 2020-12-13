        .set    GPBASE,   0x3F200000
        .set    GPFSEL0,        0x00
        .set    GPSET0,         0x1c
        .set    GPCLR0,         0x28
        .set    STBASE,   0x3F003000
        .set    STCLO,          0x04
	.set	GPLEV0,	0x34
.text
	@Inicio Compatibilidad RPi3
	mrs r0, cpsr
	mov r0, #0b11010011
	msr spsr_cxsf, r0
	add r0, pc, #4
	msr ELR_hyp, r0
	eret
	@Fin

	mov 	r0, #0b11010011
	msr	cpsr_c, r0
	mov 	sp, #0x8000000	@ Inicializ. pila en modo SVC
	
	ldr     r4, =GPBASE
        mov   	r5, #0b00000000000000000001000000000000	@ GPIO4 Como salida
        str	r5, [r4, #GPFSEL0] 

        mov	r5, #0b00000000000000000000000000010000
        ldr	r0, =STBASE	@ Parametro de Sonido
	
	
bucle:	
	ldr	r1, [r4, #GPLEV0]
	
	ands	r3, r1, #0b00000000000000000000000000000100	@Comprobar boton 1
	ldreq 	r2, =1908	@ Frecuencia de sonido 1
	beq	sonar		@ Peparar Sonido
	
	ands	r3, r1, #0b00000000000000000000000000001000	@Comprobar boton 2
	ldreq 	r2, =1279	@ Frecuencia de sonido 2
	beq	sonar		@ Preparar Sonido
	
	b 	bucle	
	
sonar:
	bl esperar
	str r5, [r4, #GPSET0]
	bl esperar
	str r5, [r4, #GPCLR0]
	b sonar


esperar: 
	push	{r4,r5}
        ldr     r4, [r0, #STCLO] 
        add    	r4, r2    	  
ret1: 	
	ldr     r5, [r0, #STCLO]
        cmp	r5, r4 
        blo     ret1             
	pop	{r4,r5}
        bx      lr
	
	
