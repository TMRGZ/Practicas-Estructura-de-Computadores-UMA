        .include  "inter.inc"
.text
@Inicio Compatibilidad RPi3
	mrs r0, cpsr
	mov r0, #0b11010011
	msr spsr_cxsf, r0
	add r0, pc, #4
	msr ELR_hyp, r0
	eret
@Fin

/* Agrego vector interrupcion */
        mov     r0,  #0
        ADDEXC  0x18, irq_handler

/* Inicializo la pila en modos IRQ y SVC */
        mov     r0, #0b11010010   @ Modo IRQ, FIQ&IRQ desact
        msr     cpsr_c, r0
        mov     sp, #0x8000
        mov     r0, #0b11010011   @ Modo SVC, FIQ&IRQ desact
        msr     cpsr_c, r0
        mov     sp, #0x8000000

/* Configuro leds como salida */
        ldr     r0, =GPBASE
        /* guia bits   xx999888777666555444333222111000*/
        mov     r1, #0b00001000000000000000000000000000         @ Led 9
        str     r1, [r0, #GPFSEL0]

        ldr     r1, =0b00000000000000000000000000000001         @ Led 10
        str     r1, [r0, #GPFSEL1]

/* Habilito pines GPIO 2 (boton) para interrupciones*/
        mov     r1, #0b00000000000000000000000000001100
        str     r1, [r0, #GPFEN0]
        ldr     r0, =INTBASE

/* Habilito interrupciones, local y globalmente */
        mov     r1, #0b00000000000100000000000000000000
        str     r1, [r0, #INTENIRQ2]
        mov     r0, #0b01010011   @ Modo SVC, IRQ activo
        msr     cpsr_c, r0

/* Repetir para siempre */
    bucle:  b       bucle

/* Rutina de tratamiento de interrupción */
irq_handler:
    push    {r0, r1, r2, r3}          @ Salvo registros
    ldr     r0, =GPBASE
    ldr     r1, [r0, #GPLEV0]                               @ Comprobar si botones pulsados

    ands	r2, r1, #0b00000000000000000000000000000100	    @ Comprobar boton 1
    @ guia bits        10987654321098765432109876543210
    moveq   r1, #0b00000000000000000000001000000000
    streq   r1, [r0, #GPSET0]                               @ Led 9 si pulsado
    beq     salir                                           @ Empiezo bucle si pulsado        
        
    ands	r2, r1, #0b00000000000000000000000000001000	    @ Comprobar boton 2
    moveq   r1, #0b00000000000000000000010000000000
    streq   r1, [r0, #GPSET0]                               @ Led 10 si pulsado
    beq     salir                                           @ Empiezo bucle si pulsado                              @ Led 9 si pulsado
        
    @ guia bits    10987654321098765432109876543210
    ldr     r1, =0b00000000000000000000011000000000
    str     r1, [r0, #GPCLR0]                               @ Apago si no pulso nada

    salir: 
        pop     {r0, r1, r2, r3}          @ Recupero registros
        subs    pc, lr, #4        @ Salgo de la RTI
