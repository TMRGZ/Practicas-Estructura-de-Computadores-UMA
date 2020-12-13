        .include  "inter.inc"
.text
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

/* Inicializo la pila en modos IRQ y SVC */
        mov     r0, #0b11010010         @ Modo IRQ, FIQ&IRQ desact
        msr     cpsr_c, r0
        mov     sp, #0x8000
        mov     r0, #0b11010011         @ Modo SVC, FIQ&IRQ desact
        msr     cpsr_c, r0
        mov     sp, #0x8000000

/* Configuro GPIOs como salida */
        ldr     r0, =GPBASE
/* guia bits           xx999888777666555444333222111000*/
        ldr     r1, =0b00001000000000000001000000000000         @ Led 9 y altavoz
        str     r1, [r0, #GPFSEL0]

        ldr     r1, =0b00000000001000000000000000001001         @ Led 10, 11, 17
        str     r1, [r0, #GPFSEL1]

        ldr     r1, =0b00001000001000000000000001000000         @ Led 22, 27
        str     r1, [r0, #GPFSEL2]

/* Programo contador C1 para futura interrupcion */
        ldr     r0, =STBASE
        ldr     r1, [r0, #STCLO]
        add     r1, #2                          @ Medio segundo
        str     r1, [r0, #STC1]                 @ C1
        str     r1, [r0, #STC3]                 @ C3

/* Habilito interrupciones, local y globalmente */
        ldr     r0, =INTBASE
        mov     r1, #0b1010
        str     r1, [r0, #INTENIRQ1]
        mov     r0, #0b01010011                 @ Modo SVC, IRQ activo
        msr     cpsr_c, r0

/* Repetir para siempre */
bucle:  b       bucle

/* Rutina de tratamiento de interrupción */
irq_handler:
        push    {r0, r1, r2, r3}                @ Salvo registros

        ldr     r0, =STBASE
        ldr     r1, =GPBASE
        ldr     r2, [r0, #STCS]
        ands    r2, #0b0010                     @ Seleccionar sonido o luz
        beq     sonido                          @ Ir a sonido

        luz:
                ldr     r2, =cuenta
        /* guia bits           10987654321098765432109876543210*/
                ldr     r3, =0b00001000010000100000111000000000
                str     r3, [r1, #GPCLR0]               @ Apago Leds
                ldr     r3, [r2]
                subs    r3, #1
                moveq   r3, #6                          @ Contador de secuencia
                str     r3, [r2]
                ldr     r3, [r2, +r3, LSL #2]           @ Buscar parte de la secuencia
                str     r3, [r1, #GPSET0]

                mov     r3, #0b0010                     @ Reset C1
                str     r3, [r0, #STCS]

                ldr     r3, [r0, #STCLO]                @ Nueva espera C1
                ldr     r2, =200000
                add     r3, r2
                str     r3, [r0, #STC1]

                ldr     r3, [r0, #STCS]
                ands    r3, #0b0100
                beq     final                           @ Evitar hacer el sonido si hago luz
        
        sonido:
                ldr     r2, =bitson
                ldr     r3, [r2]
                eors    r3, #1                          @ Invertir estado
                str     r3, [r2]
                mov     r3, #0b10000
                streq   r3, [r1, #GPSET0]               @ Escribir altavoz
                strne   r3, [r1, #GPCLR0]               @ Apagar altavoz

                mov     r3, #0b1000                     @ Reset C3
                str     r3, [r0, #STCS]

                ldr     r3, [r0, #STCLO]                @ Nueva espera C3
                ldr     r2, =1136                       @ Invertir 440 y dividir entre 2
                add     r3, r2
                str     r3, [r0, #STC3]

        final:
                pop     {r0, r1, r2, r3}                @ Recupero registros
                subs    pc, lr, #4                      @ Salgo de la RTI

bitson:     .word 0
cuenta:     .word 1       
secuen:     .word 0b1000000000000000000000000000
            .word 0b0000010000000000000000000000
            .word 0b0000000000100000000000000000
            .word 0b0000000000000000100000000000
            .word 0b0000000000000000010000000000
            .word 0b0000000000000000001000000000