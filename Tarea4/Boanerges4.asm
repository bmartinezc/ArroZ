;AsmIDE AutoLoad="Load" AutoGo="g 1100"
;*****************************************************************************
;      Tarea4: LECTURA DEL TECLADO MATRICIAL
;*****************************************************************************
;
;        FECHA: 21 OCTUBRE 2017
;        MODIFICADO: 31 OCTUBRE 2017
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
PATRON: ds 1  ;variable PATRON, indice de control del for-next iterativo
REB: ds 1     ;variable REB se utilizara para contar los rebotes
BANDERAS: ds 1   ;BANDERAS = $0:%0:%PRIMERA:%VALIDA:%TECL_LISTA
TECLA: ds 1  ;TECLA, valor de la tecla ingresado
BUFFER: ds 1  ;definimos la variable para el buffer
TMP1: ds 1    ;definimos las variables temporales que utilizaremos para validar y
TMP2: ds 1    ;cargar los valores a VALOR
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

        ;configuracion de los LEDS, PORTB
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
        Cli             ;habilitacion interrupciones mascarables

;*******************************************************************************
;               PROGRAMA PRINCIPAL
;*******************************************************************************

        CLR PATRON     ;inicializamos las variables
        CLR REB
        Clr BANDERAS    ;se inicializa TECL_LISTA=0, PRIMERA=0, VALIDA=0
        Movb #$FF,VALOR
        Movb #$FF,TECLA ;se inicializa TECLA = FF
        Movb #$FF,BUFFER
        Movb #$FF,TMP1
        Movb #$FF,TMP2
        Movb #$FF,TMP3
        Movb #$00,PORTB  ;apaga los leds
Espere  Wai             ;espera que ocurra la interrupcion RTI
        ;BANDERAS = $0:%0:%PRIMERA:%VALIDA:%TECL_LISTA
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
;Esta subrutina es llamada cuando la bandera TECL_LISTA=1, lo cual significa que
;hay una nueva tecla en la variable TECLA, esta subrutina carga el valor de
;TECLA en memoria RAM, directamente en TMP3, e indirectamente en las variables
;TMP1, TMP2, segun el valor ingresado toma decisiones, si ingresan valores
;validos de Teclas revisa si TMP1 y TMP2 estan vacios, carga primero valores en
;TMP1 y luego en TMP2, si entra un ENTER($0E) procede a carga los valores de
;TMP1 y TMP2 si existen valores validos. Si entra BORRAR($0B), procede a borrar,
;primero en TMP2 y luego en TMP1. Ademas limpia las banderas y la variable TECLA.
;...............................................................................
;             Declaracion de variables locales
;...............................................................................
;VALOR: DS 1
;Va: DS 1
;...............................................................................
;...............................................................................
TECLADO Clr Banderas        ;BANDERAS, PRIMERA($04), VALIDA($02), TECL_LISTA($01)
        Movb TECLA,TMP3 ;cargamos TECLA a TMP3 para borrar luego TECLA
        Movb #$FF,TECLA
        Ldaa TMP3
        Cmpa #$0E       ;revisamos si es ENTER($0E)
        Beq LoadV       ;cargamos valores a VALOR
        Ldaa TMP3
        Cmpa #$0B       ;revisamos si es BORRAR($0B)
        Beq DelTMP      ; si es BORRAR, borramos TMP2 o TMP1
        ;Se ingresaron datos validos distintos a ENTER y BORRAR, se cargan a TMP1 y TMP2
        Brset TMP1,$FF,toT1     ;se revisa si TMP1 y TMP2 tienen valores cargados
        Brset TMP2,$FF,toT2
        Bra Return              ;TMP1 y TMP2 estan llenos, se espera un ENTER o BORRAR
toT2    Movb TMP3,TMP2  ;TMP2 esta vacio, y TMP1 esta ocupado, se cargan valores a TMP2
        Bra Return
toT1    Movb TMP3,TMP1  ;TMP1 esta vacio, se cargan valores a TMP1
        Bra Return
        ;Hubo BORRAR($OB)
DelTMP  Brset TMP2,$FF,DelT1    ;si TMP2 =$FF, no hay valores en TMP2, se borra TMP1
        Movb #$FF,TMP2  ;limpiamos TMP2
        Bra Return
DelT1   Movb #$FF,TMP1  ;limpiamos TMP1
        Bra Return
        ;Hubo ENTER($OE)
LoadV   Brset TMP2,$FF,LoadT1 ;si TMP2 =$FF, no hay valores en TMP2, se revisa TMP1
        Ldaa TMP1       ;hay dos valores a desplegar en VALOR, TMP1 y TMP2
        Lsla        ;se realizan desplazamientos a TMP1={0000,TECLA1}->TMP1={TECLA1,0000}
        Lsla        ;c <- TMP1 <- 0
        Lsla
        Lsla
        Eora TMP2 ;R1 <- TMP1={TECLA1,0000} XOR TMP2={0000,TECLA2}, R1={TECLA1,TECLA2}
        Staa VALOR      ;VALOR <- {TECLA1,TECLA2}
        Movb #$FF,TMP1  ;limpiamos TMP1 y TMP2
        Movb #$FF,TMP2
        Bra Return
LoadT1  Brset TMP1,$FF,Return ;si TMP1 =$FF, no hay valores ingresados en RAM
        Movb TMP1,VALOR
        Movb #$FF,TMP1
Return  Rts


;...............................................................................
;              SUBRUTINA LEDS
;...............................................................................
;Esta subrutina es llamada cuando la variable VALOR es modificada con algun valor
;de tecla valido. Carga el dato guardado en VALOR a el puerto de LEDS, PORTB,
;limpia la variable VALOR antes de retornar
;...............................................................................
;             Declaracion de variables locales
;...............................................................................

;...............................................................................
;...............................................................................
LEDS    Movb VALOR,PORTB
        Movb #$FF,VALOR
        rts

 
;*******************************************************************************
;              SUBRUTINA DE SERVICIO RTI_ISR
;*******************************************************************************
; Esta subrutina es la encargada de leer el teclado, aproximadamente cada 1ms,
;y revisar si se presiono alguna tecla, ademas se encarga del manejo de rebote.
;Utilizando primeramente un BUFFER y luego guardando el valor valido en la
;variable TECLA.
;...............................................................................
;             Declaracion de variables locales
;...............................................................................
;Contador: ds 1  ;respaldo del conteo en R2(B)
;...............................................................................
;...............................................................................
RTI_ISR Brclr REB,$FF,LEER_T ;Revisa si rebote es cero, sino lo decrementa
        Dec REB
        LBra salida
LEER_T  Movb #$FF,BUFFER
        Ldaa #$EF       ;inicia LEER TECLA  PuntoA
        Staa PORTA
        Clrb
        Movb #$04, PATRON
forNext incb
        Brclr PORTA,$01,teclaIn        ;revisa primer patron
        incb
        Brclr PORTA,$02,teclaIn        ;revisa segundo patron
        incb
        Brclr PORTA,$04,teclaIn        ;revisa tercer patron
        Rola    ;c<-R1<-c, rator para meter los nuevos valores de prueba de entrada a PORTA
        Staa PORTA
        Dec PATRON
        Bne forNext     ;revisa si PATRON!=0, salta al forNext
        Bra CBUFF        ;check BUFFER=$FF
teclaIn Ldx #TECLAS      ;Encontro tecla, la guarda en BUFFER
        decb             ;decremente porq R2(A) cuenta desde 1
        Ldaa B,X
        Staa BUFFER     ;termina LEER TECLA, cargando en BUFFER usando el acumulador R2
CBUFF   Brset BUFFER,$FF,PuntoE ;si BUFFER =$FF, Nohay tecla
        Bra PuntoBC
PuntoE  Brset TECLA,$FF,salida ;PuntoE, si TECLA =$FF ha habido error de lectura
        ;BANDERAS, PRIMERA($04), VALIDA($02), TECL_LISTA($01)
        Brset BANDERAS,$02,PuntoA2;VALIDA=1?
        Ldaa BUFFER             ;TECLA=BUFFER?
        Cmpa TECLA
        Beq PuntoE1         ;TECLA=BUFFER
        Movb #$FF,TECLA        ;TECLA!=BUFFER
        Bra salida
PuntoE1 Bset BANDERAS,$02   ;VALIDA <- 1
        Bra salida
PuntoA2 Brset BUFFER,$FF,PuntoA3;Tecla Liberada si BUFFER=$FF
        Bra salida
PuntoA3 Clr BANDERAS   ;se limpian las BANDERAS y se pone TECL_LISTA <- 1
        Bset BANDERAS,$01
        Bra salida
        ;BANDERAS, PRIMERA($04), VALIDA($02), TECL_LISTA($01)
PuntoBC Brset BANDERAS,$04,PuntoE;primera!=0 se debe revisar TECLA para validarla
        Bset BANDERAS,$04        ;PRIMERA <- 1
        Movb #10,REB
        Movb BUFFER,TECLA
        Bra salida
salida  Bset CRGFLG,$80                ;resetea la bandera
        RTI