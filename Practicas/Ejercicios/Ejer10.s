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
        ldr     r1, =0b00001000000000000000000000000000         @ Led 9
        str     r1, [r0, #GPFSEL0]

        ldr     r1, =0b00000000001000000000000000001001         @ Led 10, 11, 17
        str     r1, [r0, #GPFSEL1]

        ldr     r1, =0b00001000001000000000000001000000         @ Led 22, 27
        str     r1, [r0, #GPFSEL2]

/* Programo contador C1 para futura interrupcion */
        ldr     r0, =STBASE
        ldr     r1, [r0, #STCLO]
        add     r1, #0x50000            @ Medio segundo
        str     r1, [r0, #STC1]

/* Habilito interrupciones, local y globalmente */
        ldr     r0, =INTBASE
        mov     r1, #0b0010
        str     r1, [r0, #INTENIRQ1]
        mov     r0, #0b01010011         @ Modo SVC, IRQ activo
        msr     cpsr_c, r0

/* Repetir para siempre */
        bucle:  b       bucle

/* Rutina de tratamiento de interrupción */
irq_handler:
        push    {r0, r1, r2}            @ Salvo registros

        ldr     r0, =ledst
        ldr     r1, [r0]
        eors    r1, #1
        str     r1, [r0]

        ldr     r0, =GPBASE
/* guia bits           10987654321098765432109876543210*/
        ldr     r1, =0b00001000010000100000111000000000
        streq   r1, [r0, #GPSET0]       @ Enciendo LED
        strne   r1, [r0, #GPCLR0]       @ Apago Led

        ldr     r0, =STBASE             @ Reseteo de interrupcion
        mov     r1, #0b0010
        str     r1, [r0, #STCS]

        ldr     r1, [r0, #STCLO]        @ Nueva espera
        ldr     r2, =500000
        add     r1, r2
        str     r1, [r0, #STC1]

        pop     {r0, r1, r2}            @ Recupero registros
        subs    pc, lr, #4              @ Salgo de la RTI
ledst:  .word 0

