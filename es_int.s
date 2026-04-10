* Definicion de equivalencias
*********************************

MR1A	EQU		$EFFC01			* de modo A (escritura)
MR2A	EQU		$EFFC01			* de modo A (2a escritura)
SRA		EQU		$EFFC03			* de estado A (lectura)
CSRA	EQU		$EFFC03			* de seleccion de reloj A (escritura)
CRA		EQU		$EFFC05			* de control A (escritura)
TBA		EQU		$EFFC07			* buffer transmision A (escritura)
RBA		EQU		$EFFC07			* buffer recepcion A  (lectura)
ACR		EQU		$EFFC09			* de control auxiliar
IMR		EQU		$EFFC0B			* de mascara de interrupcion A (escritura)
ISR		EQU		$EFFC0B			* de estado de interrupcion A (lectura)
MR1B	EQU		$EFFC11			* de modo B (escritura)
MR2B	EQU		$EFFC11			* de modo B (2a escritura)
CRB		EQU		$EFFC15			* de control A (escritura)
TBB		EQU		$EFFC17			* buffer transmision B (escritura)
RBB		EQU		$EFFC17			* buffer recepcion B (lectura)
SRB		EQU		$EFFC13			* de estado B (lectura)
CSRB	EQU		$EFFC13			* de seleccion de reloj B (escritura)

IVR		EQU		$EFFC19			* Vector de interrupcion
ISR		EQU		$EFFC0B			* Estado de interrupcion
IMR		EQU		$EFFC0B			* Mascara de interrupcion

CR		EQU		$0D				* Carriage Return
LF		EQU		$0A				* Line Feed
FLAGT	EQU		2				* Flag de transmision
FLAGR	EQU		0				* Flag de recepcion

* Inicialización
		ORG 	$0
		DC.L 	$8000 			* Puntero de pila
		DC.L 	INICIO			* Excepción reset a INICIO

* Código
		ORG		$400
IMRCP:	DC.W	0				* Copia del IMR en memoria (IMR no es legible)
								* W para que las instrucciones estén alineadas después

******************************
************ INIT ************
******************************
INIT:
	MOVE.B			#%00010000,CRA		* Reiniciar a MR1A
	MOVE.B			#%00010000,CRB		* Reiniciar a MR1B
	MOVE.B			#%00000011,MR1A		* establecer 8 bits/caracter A
	MOVE.B			#%00000011,MR1B		* establecer 8 bits/caracter B
	MOVE.B			#%00000000,MR2A		* Desactivar eco A
	MOVE.B			#%00000000,MR2B		* Desactivar eco B
	MOVE.B			#%11001100,CSRA		* 38400 bps
	MOVE.B			#%11001100,CSRB		* 38400 bps
	MOVE.B			#%00000000,ACR
	MOVE.B			#%00000101,CRA		* Full duplex
	MOVE.B			#%00000101,CRB		* Full duplex

	MOVE.B			#$40,IVR			* Vector de interrupcion
	MOVE.L			#RTI,$100			* Añadir la dirección de la RTI a la tabla de vectores de interrupcion

	BSR				INI_BUFS

	MOVE.B			#%00100010,IMRCP	* Guardar copia del IMR
	MOVE.B			IMRCP,IMR			* Habilitar interrupciones

	RTS

******************************
************ SCAN ************
******************************
SCAN:
	LINK			A6,#-8				* Marco de pila

	EOR.L			D1,D1				* Limpiar basura de registros
	EOR.L			D2,D2

	MOVE.L			8(A6),A0			* *Buffer
	MOVE.W			12(A6),D1			* Descriptor
	MOVE.W			14(A6),D2			* Tamano

	CMP.L			#0,D1				* Comprobar descriptor valido
	BEQ				scan_prep
	CMP.L			#1,D1
	BEQ				scan_prep

scan_error:
	MOVE.L			#-1,D0				* Poner codigo de error
	BRA				scan_fin

scan_prep:
	EOR.L			D3,D3				* Contador

scan_bc:
	CMP.L			D3,D2
	BEQ				scan_bc_f

	MOVE.L			D1,D0

	MOVE.L			A0,-4(A6)			* Guardar *buffer
	MOVE.L			D3,-8(A6)			* Guardar contador
	BSR				LEECAR

	EOR.L			D1,D1				* Limpiar basura de registros
	EOR.L			D2,D2

	MOVE.L			-8(A6),D3			* Recuperar contador
	MOVE.L			-4(A6),A0			* Recuperar *buffer
	MOVE.W			12(A6),D1			* Recuperar descriptor
	MOVE.W			14(A6),D2			* Recuperar Tamano

	CMP.L			#-1,D0				* Comprobar si hay error
	BEQ				scan_bc_f

	MOVE.B			D0,(A0)+			* Copiar caracter al buffer

	ADD.W			#1,D3				* Sumar contador
	BRA				scan_bc

scan_bc_f:
	MOVE.L			D3,D0				* Valor de retorno (caracteres escritos)

scan_fin:
	UNLK			A6					* Recuperar marco de pila
	RTS

*******************************
************ PRINT ************
*******************************
PRINT:
	LINK			A6,#-12				* Marco de pila

	EOR.L			D2,D2				* Limpiar basura de registros
	EOR.L			D3,D3

	MOVE.L			8(A6),A0			* *Buffer
	MOVE.W			12(A6),D2			* Descriptor
	MOVE.W			14(A6),D3			* Tamano

	CMP.L			#0,D2				* Comprobar descriptor valido
	BEQ				print_prep
	CMP.L			#1,D2
	BEQ				print_prep

print_error:
	MOVE.L			#-1,D0				* Poner codigo de error
	BRA				print_fin

print_prep:
	EOR.L			D4,D4				* Contador
	ADDQ.W			#2,D2				* Descriptor de transmision

print_bc:
	CMP.L			D4,D3
	BEQ				print_b_f

	EOR.L			D1,D1				* Limpiar basura de registros

	MOVE.L			D2,D0
	MOVE.B			(A0)+,D1

	MOVE.L			D2,-4(A6)			* Guardar descriptor modificado
	MOVE.L			A0,-8(A6)			* Guardar *buffer
	MOVE.L			D4,-12(A6)			* Guardar contador
	BSR				ESCCAR

	EOR.L			D3,D3				* Limpiar basura de registros

	MOVE.L			-12(A6),D4			* Recuperar contador
	MOVE.L			-8(A6),A0			* Recuperar *buffer
	MOVE.L			-4(A6),D2			* Recuperar descriptor modificado
	MOVE.W			14(A6),D3			* Recuperar Tamano

	CMP.L			#-1,D0
	BEQ				print_b_f

	ADD.W			#1,D4
	BRA				print_bc

print_b_f:
	
	MOVE.L			D4,D0				* Valor de retorno (caracteres escritos)
	CMP.L			#0,D4
	BEQ				print_fin

	SUBQ.W			#2,D2				* Recuperar descriptor original
	CMP.L			#1,D2				* Elegir línea
	BEQ				print_i_b

										* Reactivar interrupciones de la DUART A
	BSET			#0,IMRCP
	MOVE.B			IMRCP,IMR
	BRA				print_fin

print_i_b:								* Reactivar interrupciones de la DUART B
	BSET			#4,IMRCP
	MOVE.B			IMRCP,IMR

print_fin:
	UNLK			A6					* Recuperar marco de pila
	RTS

*****************************
************ RTI ************
*****************************
RTI:
    MOVEM.L 		A0-A6/D0-D7,-(A7)	* Guarda todos los registros en la pila

	EOR.L			D0,D0				* Limpiar basura de registros
	EOR.L			D1,D1

	MOVE.B			ISR,D0
	AND.B			IMRCP,D0		

	BTST			#0,D0
	BNE				RTI_TxTA
	BTST			#1,D0
	BNE				RTI_RxRA
	BTST			#4,D0
	BNE				RTI_TxTB
	BTST			#5,D0
	BNE				RTI_RxRB

	BRA				RTI_FIN

RTI_RxRA:
	MOVE.B			RBA,D1
	MOVE.L			#0,D0
	BSR				ESCCAR				
	BRA				RTI_FIN
RTI_RxRB:
	MOVE.B			RBB,D1
	MOVE.L			#1,D0
	BSR				ESCCAR
	BRA				RTI_FIN
RTI_TxTA:
	MOVE.L			#2,D0
	BSR				LEECAR
	CMP.L			#-1,D0
	BEQ				RTI_D_TX_A
	MOVE.B			D0,TBA
	BRA				RTI_FIN
RTI_TxTB:
	MOVE.L			#3,D0
	BSR				LEECAR
	CMP.L			#-1,D0
	BEQ				RTI_DI_TX_B
	MOVE.B			D0,TBB
	BRA				RTI_FIN
RTI_D_TX_A:
	BCLR			#0,IMRCP
	MOVE.B			IMRCP,IMR
	BRA				RTI_FIN
RTI_DI_TX_B:
	BCLR			#4,IMRCP
	MOVE.B			IMRCP,IMR
	BRA				RTI_FIN
RTI_FIN:
    MOVEM.L  (A7)+,A0-A6/D0-D7			* Restaura todos los registros en la pila
	RTE

********************************************
************ PROGRAMA PRINCIPAL ************
********************************************
BUFFER: DS.B    2100        * Buffer para lectura y escritura de caracteres
PARDIR: DC.L    0           * Dirección que se pasa como parámetro
PARTAM: DC.W    0           * Tamaño que se pasa como parámetro
CONTC:  DC.W    0           * Contador de caracteres a imprimir
DESA:   EQU     0           * Descriptor línea A
DESB:   EQU     1           * Descriptor línea B
TAMBS:  EQU     30          * Tamaño de bloque para SCAN
TAMBP:  EQU     7           * Tamaño de bloque para PRINT

        * Manejadores de excepciones
INICIO: MOVE.L  #BUS_ERROR,8      * Bus error handler
        MOVE.L  #ADDRESS_ER,12    * Address error handler
        MOVE.L  #ILLEGAL_IN,16    * Illegal instruction handler
        MOVE.L  #PRIV_VIOLT,32    * Privilege violation handler
        MOVE.L  #ILLEGAL_IN,40    * Illegal instruction handler
        MOVE.L  #ILLEGAL_IN,44    * Illegal instruction handler

        BSR     INIT
        MOVE.W  #$2000,SR         * Permite interrupciones

BUCPR:  MOVE.W  #TAMBS,PARTAM     * Inicializa parámetro de tamaño
        MOVE.L  #BUFFER,PARDIR    * Parámetro BUFFER = comienzo del buffer
OTRAL:  MOVE.W  PARTAM,-(A7)      * Tamaño de bloque
        MOVE.W  #DESA,-(A7)       * Puerto A
        MOVE.L  PARDIR,-(A7)      * Dirección de lectura
ESPL:   BSR     SCAN
        ADD.L   #8,A7             * Restablece la pila
        ADD.L   D0,PARDIR         * Calcula la nueva dirección de lectura
        SUB.W   D0,PARTAM         * Actualiza el número de caracteres leídos
        BNE     OTRAL             * Si no se han leído todas los caracteres
                                  * del bloque se vuelve a leer

        MOVE.W  #TAMBS,CONTC      * Inicializa contador de caracteres a imprimir
        MOVE.L  #BUFFER,PARDIR    * Parámetro BUFFER = comienzo del buffer
OTRAE:  MOVE.W  #TAMBP,PARTAM     * Tamaño de escritura = Tamaño de bloque
ESPE:   MOVE.W  PARTAM,-(A7)      * Tamaño de escritura
        MOVE.W  #DESB,-(A7)       * Puerto B
        MOVE.L  PARDIR,-(A7)      * Dirección de escritura
        BSR     PRINT
        ADD.L   #8,A7             * Restablece la pila
        ADD.L   D0,PARDIR         * Calcula la nueva dirección del buffer
        SUB.W   D0,CONTC          * Actualiza el contador de caracteres
        BEQ     SALIR             * Si no quedan caracteres se acaba
        SUB.W   D0,PARTAM         * Actualiza el tamaño de escritura
        BNE     ESPE              * Si no se ha escrito todo el bloque se insiste
        CMP.L   #TAMBP,CONTC      * Si el nº de caracteres que quedan es menor que
                                  * el tamaño establecido se imprime ese número
        BHI     OTRAE             * Siguiente bloque
        MOVE.W  CONTC,PARTAM
        BRA     ESPE              * Siguiente bloque

SALIR:  BRA     BUCPR

BUS_ERROR:      BREAK             * Bus error handler
                NOP
ADDRESS_ER:     BREAK             * Address error handler
                NOP
ILLEGAL_IN:     BREAK             * Illegal instruction handler
                NOP
PRIV_VIOLT:     BREAK             * Privilege violation handler
                NOP

**********************************
************ INCLUDES ************
**********************************
INCLUDE bib_aux.s
