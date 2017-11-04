;AsmIDE AutoLoad="Load" AutoGo="g 1500"
;*******************************************************************************
;             Ejemplo GPIO
;
;*******************************************************************************


;*******************************************************************************
  ;         ESTRUCTURAS DE DATOS
;*******************************************************************************

#include "../registers.inc"

;*******************************************************************************
;           CONFIGURACION DE HARDWARE
;*******************************************************************************

        ORG $1500

        Movb #$FF, DDRB
        Bset DDRJ, $02        ;definimos como salida para poder escribirle
        Bclr PTJ, $02         ;habilita los LEDs, se pone posicion1 en PTJ en cero para activar LEDS
        Movb #$00,DDRH        ;pone el puerto H como entradas
        ;Movb #$0f, DDRP
        ;Movb #$0f, PTP

;*******************************************************************************
;             Programa Principal
;*******************************************************************************
;    Movb #%10101010 PORTB

REPITA        Movb PTIH, PORTB
        Bra REPITA
        