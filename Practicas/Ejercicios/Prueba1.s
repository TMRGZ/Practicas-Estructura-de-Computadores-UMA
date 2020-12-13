        .include "inter.inc"
.text
        ldr     r0, =GPBASE

        /* guia bits   xx999888777666555444333222111000*/
        mov   	r1, #0b00001000000000000000000000000000         @ Led 9
        str	    r1, [r0, #GPFSEL0]  

        ldr     r1, =0b00000000000000000000000000000001         @ Led 10
        str     r1, [r0, #GPFSEL1]


bucle:
        ldr     r1, [r0, #GPLEV0]                               @ Comprobar si botones pulsados

        ands	r2, r1, #0b00000000000000000000000000000100	@ Comprobar boton 1
        /* guia bits   10987654321098765432109876543210*/
        moveq   r1, #0b00000000000000000000001000000000
        streq   r1, [r0, #GPSET0]                               @ Led 9 si pulsado
        beq     bucle                                           @ Empiezo bucle si pulsado        
        
        ands	r2, r1, #0b00000000000000000000000000001000	@ Comprobar boton 2
        moveq   r1, #0b00000000000000000000010000000000
        streq   r1, [r0, #GPSET0]                               @ Led 10 si pulsado
        beq     bucle                                           @ Empiezo bucle si pulsado

        @ guia bits    10987654321098765432109876543210
        ldr     r3, =0b00000000000000000000011000000000
        str     r3, [r0, #GPCLR0]                               @ Apago si no pulso nada
        
        b bucle