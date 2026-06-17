TITLE "Proyecto Final: Semáforo Inteligente Interactivo"
    #include <p16f887.inc>
    

    ; --- BITS DE CONFIGURACIÓN ---
    __CONFIG _CONFIG1, _LVP_OFF & _FCMEN_OFF & _IESO_OFF & _BOR_OFF & _CP_OFF & _MCLRE_ON & _PWRTE_ON & _WDT_OFF & _XT_OSC
    __CONFIG _CONFIG2, _WRT_OFF & _BOR21V

;====================================================================
; 1. MEMORIA DE VARIABLES
;====================================================================
UNI             EQU 0x20    
DEC             EQU 0x21    
W_TEMP          EQU 0x22    
STATUS_TEMP     EQU 0x23    
MULTI_DISPLAY   EQU 0x24    
ESTADO_ACTUAL   EQU 0x25    ; Máquina de estados (0x00=Verde, 0x01=Amarillo, 0x02=Rojo, 0x04=Noche)
ESTADO_ANTERIOR EQU 0x26    ; Memoria para comparar si el estado cambió (y no spamear la consola)
SEG_RESTANTES   EQU 0x27    ; Cuenta regresiva de los segundos de la luz actual
CONT_TMR0       EQU 0x28    ; Contador de desbordes del Timer0 para formar 1 segundo exacto
CONT_DELAY1     EQU 0x29    ; Variable para contar los bucles de la demora de 1ms
CONT_DELAY2     EQU 0x2A    ; Variable para contar los bucles largos del servo (18ms / 19ms)

;====================================================================
; 2. VECTORES DE RESET E INTERRUPCIÓN
;====================================================================
    ORG 0x00            
    GOTO INICIO        

    ORG 0x04            
ISR
    MOVWF   W_TEMP
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP
    
    ; Forzar Banco 0 de seguridad
    BANKSEL PORTA

    BTFSC   INTCON, T0IF
    GOTO    ISR_TMR0
    
    BTFSC   INTCON, INTF    
    GOTO    ISR_RB0
    
    GOTO    FIN_ISR

;====================================================================
; 3. RUTINAS DE INTERRUPCIÓN (ISR)
;====================================================================
ISR_TMR0
    BCF     INTCON, T0IF
    MOVLW   D'237'          
    MOVWF   TMR0

    CLRF    PORTA            ; Apaga los dos displays un microsegundo antes de cambiar los números para que no quede un "brillo fantasma" del número anterior.
    
        INCF    MULTI_DISPLAY, F  
    MOVF    MULTI_DISPLAY, W  
    XORLW   0x02              
    BTFSC   STATUS, Z         
    CLRF    MULTI_DISPLAY     
    
    ;Decidimos que display prender
    MOVF    MULTI_DISPLAY, W 
    XORLW   0x00              
    BTFSC   STATUS, Z         
    GOTO    MOSTRAR_UNI       
    GOTO    MOSTRAR_DEC       

MOSTRAR_UNI
    MOVF    UNI, W 
    CALL    TABLA       
    MOVWF   PORTD       
    BSF     PORTA, 0    
    GOTO    CONTAR_TIEMPO

MOSTRAR_DEC
    MOVF    DEC, W 
    CALL    TABLA       
    MOVWF   PORTD       
    BSF     PORTA, 1    

CONTAR_TIEMPO
    DECFSZ  CONT_TMR0, F
    GOTO    FIN_ISR
    MOVLW   D'206'          ;1 segundo
    MOVWF   CONT_TMR0
    
    MOVF    ESTADO_ACTUAL, W
    XORLW   0x04            
    BTFSC   STATUS, Z
    GOTO    DECREMENTAR_NOCHE 
    
    MOVF    SEG_RESTANTES, F
    BTFSS   STATUS, Z       
    DECF    SEG_RESTANTES, F
    GOTO    FIN_ISR

DECREMENTAR_NOCHE
    DECF    SEG_RESTANTES, F  
    GOTO    FIN_ISR

ISR_RB0
    MOVF    ESTADO_ACTUAL, W
    XORLW   0x00
    BTFSS   STATUS, Z
    GOTO    SALIR_BOTON
    
    MOVF    SEG_RESTANTES, F
    BTFSC   STATUS, Z       
    GOTO    SALIR_BOTON
    
    CALL    TX_BOTON_DETECTADO
    CLRF    SEG_RESTANTES   
    
SALIR_BOTON
    BCF     INTCON, INTF    
    GOTO    FIN_ISR

FIN_ISR
    SWAPF   STATUS_TEMP, W
    MOVWF   STATUS
    SWAPF   W_TEMP, F
    SWAPF   W_TEMP, W
    RETFIE


; 4. TABLAS 

TABLA
    ADDWF   PCL, F          
    RETLW   b'00111111' ; 0
    RETLW   b'00000110' ; 1
    RETLW   b'01011011' ; 2
    RETLW   b'01001111' ; 3
    RETLW   b'01100110' ; 4
    RETLW   b'01101101' ; 5
    RETLW   b'01111101' ; 6
    RETLW   b'00000111' ; 7
    RETLW   b'01111111' ; 8
    RETLW   b'01101111' ; 9
    RETLW   b'01000000' ; 10 - Guión
    RETLW   b'00000000' ; 11 - Apagado


; 5. CONFIGURACIÓN INICIAL 

INICIO 
    BANKSEL TRISA
    MOVLW   b'00100000'    ;RA5 LDR, RA0 y RA1 transistores disp.
    MOVWF   TRISA
    MOVLW   b'00000001'    ;RB0
    MOVWF   TRISB
    MOVLW   b'10000000'    ;RC7:RX , RC6:TX , RC2:Servo
    MOVWF   TRISC
    CLRF    TRISD          ;segm
    CLRF    TRISE          ;buzzer

    BANKSEL ANSEL
    MOVLW   b'00010000'    ;adc
    MOVWF   ANSEL
    CLRF    ANSELH
    BANKSEL ADCON0
    MOVLW   b'10010001' 
    MOVWF   ADCON0
    BANKSEL ADCON1
    MOVLW   b'00000000' 
    MOVWF   ADCON1

    BANKSEL OPTION_REG
    MOVLW   B'00000111' 
    MOVWF   OPTION_REG
    BANKSEL TMR0
    MOVLW   D'237'
    MOVWF   TMR0

    BANKSEL BAUDCTL
    CLRF    BAUDCTL       
    BANKSEL SPBRGH
    CLRF    SPBRGH        
    BANKSEL TXSTA
    MOVLW   b'00100100'   
    MOVWF   TXSTA
    BANKSEL RCSTA
    MOVLW   b'10000000'   ;RX TX d comunicacion
    MOVWF   RCSTA
    BANKSEL SPBRG
    MOVLW   D'25'         
    MOVWF   SPBRG

    BANKSEL PORTA
    CLRF    PORTA
    CLRF    PORTB
    CLRF    PORTC
    CLRF    PORTD
    CLRF    PORTE
    
    CLRF    UNI
    CLRF    DEC
    CLRF    MULTI_DISPLAY
    MOVLW   D'206'
    MOVWF   CONT_TMR0
    
    CLRF    ESTADO_ACTUAL
    MOVLW   0xFF            
    MOVWF   ESTADO_ANTERIOR
    MOVLW   D'5'
    MOVWF   SEG_RESTANTES

    BSF     INTCON, INTE    
    BSF     INTCON, T0IE    
    BSF     INTCON, GIE


; 6. BUCLE PRINCIPAL (MÁQUINA DE ESTADOS)

PROGRAMA_PRINCIPAL
    BANKSEL ADCON0
    BSF     ADCON0, GO      
ESPERA_ADC
    BTFSC   ADCON0, GO
    GOTO    ESPERA_ADC
    
    BANKSEL ADRESH
    MOVLW   D'50'           
    SUBWF   ADRESH, W       
    BTFSS   STATUS, C       
    GOTO    ES_DE_NOCHE    
    ; CONFIRMAMOS que es de dia, y ahora vemos si esta amaneciendo
    MOVF    ESTADO_ACTUAL, W
    XORLW   0x04            
    BTFSS   STATUS, Z
    GOTO    COMPROBAR_CAMBIO   
    ;recien amanece (el estado anterior era noche)
    MOVLW   0x02
    MOVWF   ESTADO_ACTUAL
    MOVLW   D'10'           
    MOVWF   SEG_RESTANTES
    GOTO    COMPROBAR_CAMBIO 

ES_DE_NOCHE
    MOVLW   0x04
    MOVWF   ESTADO_ACTUAL   

COMPROBAR_CAMBIO
    MOVF    ESTADO_ACTUAL, W
    XORWF   ESTADO_ANTERIOR, W
    BTFSC   STATUS, Z          ;Para no repetir el mensaje muchas veces por segundo
    GOTO    EVALUAR_LUCES   

    MOVF    ESTADO_ACTUAL, W
    MOVWF   ESTADO_ANTERIOR
    CALL    MANDAR_REPORTE_SERIAL

EVALUAR_LUCES
    MOVF    ESTADO_ACTUAL, W
    XORLW   0x00
    BTFSC   STATUS, Z
    CALL    VERDE

    MOVF    ESTADO_ACTUAL, W
    XORLW   0x01
    BTFSC   STATUS, Z
    CALL    AMARILLO

    MOVF    ESTADO_ACTUAL, W
    XORLW   0x02
    BTFSC   STATUS, Z
    CALL    ROJO

    MOVF    ESTADO_ACTUAL, W
    XORLW   0x04
    BTFSC   STATUS, Z
    CALL    NOCHE

    CALL    SEPARAR_DIGITOS
    GOTO    PROGRAMA_PRINCIPAL 


; 7. RUTINAS DE CONTROL DE LUCES Y SERVO

VERDE
    BSF     PORTB, 7        
    BCF     PORTB, 6        
    BCF     PORTB, 5        
    BCF     PORTE, 0        
    
    BCF     INTCON, GIE     
    BSF     PORTC, 2        
    CALL    DELAY_2MS       
    BCF     PORTC, 2        
    BSF     INTCON, GIE     
    CALL    DELAY_18MS      

    MOVF    SEG_RESTANTES, F
    BTFSS   STATUS, Z
    RETURN                  

    MOVLW   0x01            
    MOVWF   ESTADO_ACTUAL
    MOVLW   D'2'            
    MOVWF   SEG_RESTANTES
    RETURN

AMARILLO
    BCF     PORTB, 7        
    BSF     PORTB, 6        
    BCF     PORTB, 5        
    BCF     PORTE, 0        

    BCF     INTCON, GIE     
    BSF     PORTC, 2
    CALL    DELAY_2MS
    BCF     PORTC, 2
    BSF     INTCON, GIE     
    CALL    DELAY_18MS

    MOVF    SEG_RESTANTES, F
    BTFSS   STATUS, Z
    RETURN

    MOVLW   0x02            
    MOVWF   ESTADO_ACTUAL
    MOVLW   D'10'           
    MOVWF   SEG_RESTANTES
    RETURN

ROJO
    BSF     PORTB, 5        
    BCF     PORTB, 7        
    BCF     PORTB, 6        

    BCF     INTCON, GIE     
    BSF     PORTC, 2
    CALL    DELAY_1MS       
    BCF     PORTC, 2
    BSF     INTCON, GIE     
    CALL    DELAY_19MS      

    BTFSC   SEG_RESTANTES, 0 
    BSF     PORTE, 0         
    BTFSS   SEG_RESTANTES, 0
    BCF     PORTE, 0         

    MOVF    SEG_RESTANTES, F
    BTFSS   STATUS, Z
    RETURN                  

    BCF     PORTE, 0        
    CLRF    ESTADO_ACTUAL   
    MOVLW   D'5'            
    MOVWF   SEG_RESTANTES
    RETURN

NOCHE
    BCF     PORTB, 7        
    BCF     PORTB, 5        
    BCF     PORTE, 0        

    BCF     INTCON, GIE     
    BSF     PORTC, 2
    CALL    DELAY_1MS       
    BCF     PORTC, 2
    BSF     INTCON, GIE     
    CALL    DELAY_19MS      

    BTFSC   SEG_RESTANTES, 0 
    BSF     PORTB, 6         
    BTFSS   SEG_RESTANTES, 0
    BCF     PORTB, 6         
    RETURN

;====================================================================
; 8. RUTINAS AUXILIARES Y DELAYS
;====================================================================
SEPARAR_DIGITOS
    MOVF    ESTADO_ACTUAL, W
    XORLW   0x00            
    BTFSC   STATUS, Z
    GOTO    CARGAR_GUIONES
    MOVF    ESTADO_ACTUAL, W
    XORLW   0x01            
    BTFSC   STATUS, Z
    GOTO    CARGAR_GUIONES
    MOVF    ESTADO_ACTUAL, W
    XORLW   0x04            
    BTFSC   STATUS, Z
    GOTO    APAGAR_PANTALLAS

    MOVF    SEG_RESTANTES, W
    MOVWF   UNI              
    CLRF    DEC              
    
    XORLW   D'10'            
    BTFSS   STATUS, Z        
    RETURN                   

    CLRF    UNI              
    MOVLW   D'1'
    MOVWF   DEC              
    RETURN
    
CARGAR_GUIONES
    MOVLW   D'10'           
    MOVWF   UNI
    MOVWF   DEC
    RETURN

APAGAR_PANTALLAS
    MOVLW   D'11'           
    MOVWF   UNI
    MOVWF   DEC
    RETURN

DELAY_1MS
    MOVLW   D'250'
    MOVWF   CONT_DELAY1
L_1MS
    NOP
    DECFSZ  CONT_DELAY1, F
    GOTO    L_1MS
    RETURN

DELAY_2MS
    CALL    DELAY_1MS
    CALL    DELAY_1MS
    RETURN

DELAY_18MS
    MOVLW   D'18'
    MOVWF   CONT_DELAY2
L_18MS
    CALL    DELAY_1MS
    DECFSZ  CONT_DELAY2, F
    GOTO    L_18MS
    RETURN

DELAY_19MS
    MOVLW   D'19'
    MOVWF   CONT_DELAY2
L_19MS
    CALL    DELAY_1MS
    DECFSZ  CONT_DELAY2, F
    GOTO    L_19MS
    RETURN


; 9. RUTINAS DE COMUNICACIÓN SERIAL Y TEXTOS 

; <editor-fold defaultstate="collapsed" desc="--> CLIC ACÁ PARA ABRIR LOS TEXTOS SERIALES <--">

MANDAR_REPORTE_SERIAL
    MOVF    ESTADO_ACTUAL, W
    XORLW   0x00
    BTFSC   STATUS, Z
    GOTO    TXT_VERDE
    MOVF    ESTADO_ACTUAL, W
    XORLW   0x01
    BTFSC   STATUS, Z
    GOTO    TXT_AMARILLO
    
    MOVF    ESTADO_ACTUAL, W
    XORLW   0x02
    BTFSC   STATUS, Z
    GOTO    TXT_ROJO
    MOVF    ESTADO_ACTUAL, W
    XORLW   0x04
    BTFSC   STATUS, Z
    GOTO    TXT_NOCHE
    RETURN

TXT_VERDE
    MOVLW   '['
    CALL    UART_CARACTER
    MOVLW   'V'
    CALL    UART_CARACTER
    MOVLW   'E'
    CALL    UART_CARACTER
    MOVLW   'R'
    CALL    UART_CARACTER
    MOVLW   'D'
    CALL    UART_CARACTER
    MOVLW   'E'
    CALL    UART_CARACTER
    MOVLW   ']'
    CALL    UART_CARACTER
    CALL    TX_BARRERA_CERRADA  
    CALL    TX_SENSOR_DIA
    RETURN

TXT_AMARILLO
    MOVLW   '['
    CALL    UART_CARACTER
    MOVLW   'A'
    CALL    UART_CARACTER
    MOVLW   'M'
    CALL    UART_CARACTER
    MOVLW   'A'
    CALL    UART_CARACTER
    MOVLW   'R'
    CALL    UART_CARACTER
    MOVLW   'I'
    CALL    UART_CARACTER
    MOVLW   'L'
    CALL    UART_CARACTER
    MOVLW   'L'
    CALL    UART_CARACTER
    MOVLW   'O'
    CALL    UART_CARACTER
    MOVLW   ']'
    CALL    UART_CARACTER
    CALL    TX_BARRERA_CERRADA  
    CALL    TX_SENSOR_DIA
    RETURN

TXT_ROJO
    MOVLW   '['
    CALL    UART_CARACTER
    MOVLW   'R'
    CALL    UART_CARACTER
    MOVLW   'O'
    CALL    UART_CARACTER
    MOVLW   'J'
    CALL    UART_CARACTER
    MOVLW   'O'
    CALL    UART_CARACTER
    MOVLW   ']'
    CALL    UART_CARACTER
    CALL    TX_BARRERA_ABIERTA  
    CALL    TX_SENSOR_DIA
    RETURN

TXT_NOCHE
    MOVLW   '['
    CALL    UART_CARACTER
    MOVLW   'N'
    CALL    UART_CARACTER
    MOVLW   'O'
    CALL    UART_CARACTER
    MOVLW   'C'
    CALL    UART_CARACTER
    MOVLW   'H'
    CALL    UART_CARACTER
    MOVLW   'E'
    CALL    UART_CARACTER
    MOVLW   ']'
    CALL    UART_CARACTER
    CALL    TX_BARRERA_ABIERTA  
    CALL    TX_SENSOR_OSCURO
    RETURN

UART_CARACTER
    BANKSEL PIR1
WAIT_TX
    BTFSS   PIR1, TXIF      ;TXIF letra cargada = 0
    GOTO    WAIT_TX
    BANKSEL TXREG
    MOVWF   TXREG           ;txreg transforma las letras en unos y ceros
    BANKSEL PORTA           
    RETURN

TX_BOTON_DETECTADO
    MOVLW   'B'
    CALL    UART_CARACTER
    MOVLW   'o'
    CALL    UART_CARACTER
    MOVLW   't'
    CALL    UART_CARACTER
    MOVLW   'o'
    CALL    UART_CARACTER
    MOVLW   'n'
    CALL    UART_CARACTER
    MOVLW   ' '
    CALL    UART_CARACTER
    MOVLW   'p'
    CALL    UART_CARACTER
    MOVLW   'e'
    CALL    UART_CARACTER
    MOVLW   'a'
    CALL    UART_CARACTER
    MOVLW   't'
    CALL    UART_CARACTER
    MOVLW   'o'
    CALL    UART_CARACTER
    MOVLW   'n'
    CALL    UART_CARACTER
    MOVLW   ' '
    CALL    UART_CARACTER
    MOVLW   'd'
    CALL    UART_CARACTER
    MOVLW   'e'
    CALL    UART_CARACTER
    MOVLW   't'
    CALL    UART_CARACTER
    MOVLW   'e'
    CALL    UART_CARACTER
    MOVLW   'c'
    CALL    UART_CARACTER
    MOVLW   't'
    CALL    UART_CARACTER
    MOVLW   'a'
    CALL    UART_CARACTER
    MOVLW   'd'
    CALL    UART_CARACTER
    MOVLW   'o'
    CALL    UART_CARACTER
    MOVLW   D'13'
    CALL    UART_CARACTER
    MOVLW   D'10'
    CALL    UART_CARACTER
    RETURN

TX_BARRERA_ABIERTA
    MOVLW   ' '
    CALL    UART_CARACTER
    MOVLW   'B'
    CALL    UART_CARACTER
    MOVLW   'A'
    CALL    UART_CARACTER
    MOVLW   'R'
    CALL    UART_CARACTER
    MOVLW   'R'
    CALL    UART_CARACTER
    MOVLW   'E'
    CALL    UART_CARACTER
    MOVLW   'R'
    CALL    UART_CARACTER
    MOVLW   'A'
    CALL    UART_CARACTER
    MOVLW   ':'
    CALL    UART_CARACTER
    MOVLW   'A'
    CALL    UART_CARACTER
    MOVLW   'B'
    CALL    UART_CARACTER
    MOVLW   'I'
    CALL    UART_CARACTER
    MOVLW   'E'
    CALL    UART_CARACTER
    MOVLW   'R'
    CALL    UART_CARACTER
    MOVLW   'T'
    CALL    UART_CARACTER
    MOVLW   'A'
    CALL    UART_CARACTER
    RETURN

TX_BARRERA_CERRADA
    MOVLW   ' '
    CALL    UART_CARACTER
    MOVLW   'B'
    CALL    UART_CARACTER
    MOVLW   'A'
    CALL    UART_CARACTER
    MOVLW   'R'
    CALL    UART_CARACTER
    MOVLW   'R'
    CALL    UART_CARACTER
    MOVLW   'E'
    CALL    UART_CARACTER
    MOVLW   'R'
    CALL    UART_CARACTER
    MOVLW   'A'
    CALL    UART_CARACTER
    MOVLW   ':'
    CALL    UART_CARACTER
    MOVLW   'C'
    CALL    UART_CARACTER
    MOVLW   'E'
    CALL    UART_CARACTER
    MOVLW   'R'
    CALL    UART_CARACTER
    MOVLW   'R'
    CALL    UART_CARACTER
    MOVLW   'A'
    CALL    UART_CARACTER
    MOVLW   'D'
    CALL    UART_CARACTER
    MOVLW   'A'
    CALL    UART_CARACTER
    RETURN

TX_SENSOR_DIA
    MOVLW   ' '
    CALL    UART_CARACTER
    MOVLW   'S'
    CALL    UART_CARACTER
    MOVLW   'E'
    CALL    UART_CARACTER
    MOVLW   'N'
    CALL    UART_CARACTER
    MOVLW   'S'
    CALL    UART_CARACTER
    MOVLW   'O'
    CALL    UART_CARACTER
    MOVLW   'R'
    CALL    UART_CARACTER
    MOVLW   ':'
    CALL    UART_CARACTER
    MOVLW   'D'
    CALL    UART_CARACTER
    MOVLW   'I'
    CALL    UART_CARACTER
    MOVLW   'A'
    CALL    UART_CARACTER
    MOVLW   D'13'
    CALL    UART_CARACTER
    MOVLW   D'10'
    CALL    UART_CARACTER
    RETURN

TX_SENSOR_OSCURO
    MOVLW   ' '
    CALL    UART_CARACTER
    MOVLW   'S'
    CALL    UART_CARACTER
    MOVLW   'E'
    CALL    UART_CARACTER
    MOVLW   'N'
    CALL    UART_CARACTER
    MOVLW   'S'
    CALL    UART_CARACTER
    MOVLW   'O'
    CALL    UART_CARACTER
    MOVLW   'R'
    CALL    UART_CARACTER
    MOVLW   ':'
    CALL    UART_CARACTER
    MOVLW   'O'
    CALL    UART_CARACTER
    MOVLW   'S'
    CALL    UART_CARACTER
    MOVLW   'C'
    CALL    UART_CARACTER
    MOVLW   'U'
    CALL    UART_CARACTER
    MOVLW   'R'
    CALL    UART_CARACTER
    MOVLW   'O'
    CALL    UART_CARACTER
    MOVLW   D'13'
    CALL    UART_CARACTER
    MOVLW   D'10'
    CALL    UART_CARACTER
    RETURN

; </editor-fold>
    END