;*****************************************************************************
;      Tarea4: LECTURA DEL TECLADO MATRICIAL
;*****************************************************************************
;
;        FECHA: 21 OCTUBRE 2017
;        MODIFICADO: 21 OCTUBRE 2017
;        AUTOR: BMARTINEZC
;        VERSION: 1.0
;
; Descripcion: Este progragama permitira la lectura de un teclado matricial, utilizando
; la Interrupcion de tiempo real (RTI) para leer el teclado matricial cada 1ms.
; El teclado matricial tiene el siguiente formato:
;                        1-2-3
;                        4-5-6
;                        7-8-9
;                        B-0-E
;
; Donde B corresponde a BACK y tiene la funcion de borrar un valor antes ingresado,
; E corresponde a ENTER, tiene la funcion de cargar los valores a la variable VALOR.
; Si VALOR posee un valor valido, se procedera a desplegar su valor en los LEDs.
; El valor mas cercano a 1ms que se puede obtener al modificar los parametros
; N y M es 1.024ms, y existen varias posibles combinaciones de N y M, en este
; programa se utiliza #$MN M=1,N=7 o M=4,N=0 1.024ms
;...............................................................................

;...............................................................................
;                         ESTRUCTURAS DE DATOS GLOBALES
;...............................................................................
        org $1000
PATRON: ds 1  ;variable PATRON, indice de control del for-next iterativo4
REB: ds 1     ;variable REB se utilizara para contar los rebotes
BANDERAS: ds 1   ;BANDERAS = $0:%0:%PRIMERA:%VALIDA:%TECL_LISTA
TECLA: ds 1  ;TECLA valor de la tecla ingresado
BUFFER: ds 1  ;definimos las pariables para el buffer
TMP1: ds 1    ;definimos las variables temporales que utilizaremos para validar y
TMP2: ds 1    ;cargar los valores a PATRON
TMP3: ds 1
VALOR:  ds 1    ;variable utilizada por subrutina TECLADO y LEDS
        org $1010
TECLAS: db $01,$02,$03,$04,$05,$06,$07,$08,$09,$B,$0,$E ;se define la tabla TECLAS
;...............................................................................

;*******************************************************************************
;               INCLUSION DEL ARCHIVO DE NOMBRES DE REGISTROS
;*******************************************************************************
#include registers.inc
;*******************************************************************************
;                     DEFINICION DE VECTORES DE INTERRUPCIONES
;*******************************************************************************
        org $3E70       ;se trabajara con Debug12, RTI
        dw  RTI_ISR
;*******************************************************************************
;               CONFIGURACION DEL HARDWARE
;*******************************************************************************
        org $1100
        ;puerto leds

        ;configuracion de los LEDS
        movb #$FF,DDRB   ;Puerto B como salidas
        Bset DDRJ, $02   ;posicion 1 PORTJ como salida
        Bclr PTJ, $02    ;habilita los LEDS, se pone en 0 posicion 1 PORTJ
        ;configuracion RTI
        movb #$80,CRGINT ;Habilita(ENABLE) la interrupcion de RTI
        movb #$40,RTICTL ;#$MN, M=4, N=0, Tic_RTI = 1.024ms
        ;PORTA, parte alta como salidas, parte baja como entradas
        movb #$F0,DDRA
        Bset PUCR, $01 ;PORTA pull-up, PUCR control register
        ;inicio de la pila y habilitacion de interrupciones mascarables
        Lds  #$3BFF        ;inicializamos la pila
        Cli             ;habilitag interrupciones mascarables

;*******************************************************************************
;               PROGRAMA PRINCIPAL
;*******************************************************************************

        CLR PATRON     ;inicializamos las variables
        CLR REB
        Movb #$0F,TECLA ;se inicializa TECL_LISTA=0, TECLA = FF
        Movb #$FF,BUFFER
        Movb #$FF,TMP1
        Movb #$FF,TMP2
        Movb #$FF,TMP3
        Movb #$FF,VALOR
        Movb #0,PORTB  ;apaga los leds
Espere  Wai             ;espera que ocurra la interrupcion RTI
        ;BANDERAS = $0:%0:%Primera:%VALIDA:%TECL_LISTA
        ;BANDERAS, PRIMERA($04), VALIDA($02), TECL_LISTA($01)
        Brclr BANDERAS,$01,Espere  ;se revisa el valor de TECL_LISTA en el nible mas significativo de TECLA
        Jsr TECLADO     ;se llama a la subrutina TECLADO
        Brset VALOR,$FF,Espere ;si VALOR =$FF, no ha habido cambios en VALOR
        Jsr LEDS        ;se llama a la subrutina TECLADO, si ha habido cambios en VALOR
        Bra Espere
        
;*******************************************************************************
;               SUBRUTINAS GENERALES
;*******************************************************************************

 
;...............................................................................
;              SUBRUTINA TECLADO
;...............................................................................
;...............................................................................
;             Declaracion de variables locales
;...............................................................................
;VALOR: DS 1
Va: DS 1
;...............................................................................
;...............................................................................
TECLADO Movb TECLA,VALOR
        Movb $FF,TECLA
        ;BANDERAS, PRIMERA($04), VALIDA($02), TECL_LISTA($01)
        Bclr Banderas,$01
        Rts


;...............................................................................
;              SUBRUTINA LEDS
;...............................................................................
;...............................................................................
;             Declaracion de variables locales
;...............................................................................

;...............................................................................
;...............................................................................
LEDS    Movb VALOR,PORTB
        Movb $FF,VALOR
        rts

 
;*******************************************************************************
;              SUBRUTINA DE SERVICIO RTI_ISR
;*******************************************************************************
; Esta subrutina es la encargada de leer el teclado, y revisar si hubo o hubieron,
; teclas validas, ademas se encarga del manejo de rebote.
;...............................................................................
;             Declaracion de variables locales
;...............................................................................

;...............................................................................
;...............................................................................
RTI_ISR ;falta check REB,BUFFER=FF
	Ldaa #$EF       ;inicia LEER TECLA
        Staa PORTA
        Clrb
        Movb #$04, PATRON
forNext incb
        Brclr PORTA,$01,teclaIn        ;revisa primer patron
        incb
        Brclr PORTA,$02,teclaIn        ;revisa segundo patron
        incb
        Brclr PORTA,$04,teclaIn        ;revisa tercer patron
        Sec                 ;c=1
        Rola    ;c<-R1<-c, rator para meter los nuevos valores de prueba de entrada a PORTA
        Staa PORTA
        Dec PATRON
        Bne forNext     ;revisa si PATRON!=0, salta al forNext
        Bra CHECKBUF	;check BUFFER=$FF
teclaIn Ldx TECLAS      ;Encontro tecla, la guarda en BUFFER
        Ldaa B,X
        Staa BUFFER     ;termina LEER TECLA
CHECKBUF
        
salida  Bset CRGFLG,$80                ;resetea la bandera
        RTI