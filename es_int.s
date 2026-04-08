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

		ORG 	$0
		DC.L 	$8000 			* Puntero de pila
		DC.L 	INICIO			* Excepción reset a INICIO

		ORG		$400
IMRCP:	DC.B	0				* Copia del IMR en memoria (IMR no es legible)

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

	MOVE.B			#%00100010,IMRCP	* Guardar copia del IMR
	MOVE.B			IMRCP,IMR			* Habilitar interrupciones

	MOVE.L			#RTI,$100			* Añadir la dirección de la RTI a la tabla de vectores de interrupcion

	BSR				INI_BUFS
	RTS

******************************
************ SCAN ************
******************************
SCAN:
	LINK			A6,#-8				* Marco de pila

	MOVE.L			8(A6),A0			* *Buffer
	MOVE.W			12(A6),D1			* Descriptor
	MOVE.W			14(A6),D2			* Tamano

	CMP.W			#0,D1				* Comprobar descriptor valido
	BEQ				scan_prep
	CMP.W			#1,D1
	BEQ				scan_prep

scan_error:
	MOVE.L			#-1,D0				* Poner codigo de error
	BRA				scan_fin

scan_prep:
	MOVE.W			#0,D3

scan_bc:
	CMP.W			D3,D2
	BEQ				scan_bc_f

	MOVE.L			D1,D0

	MOVE.L			A0,-4(A6)			* Guardar *buffer
	MOVE.L			D3,-8(A6)			* Guardar contador
	BSR				LEECAR
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

	MOVE.L			8(A6),A0			* *Buffer
	MOVE.W			12(A6),D2			* Descriptor
	MOVE.W			14(A6),D3			* Tamano

	CMP.W			#0,D2				* Comprobar descriptor valido
	BEQ				print_prep
	CMP.W			#1,D2
	BEQ				print_prep

print_error:
	MOVE.L			#-1,D0				* Poner codigo de error
	BRA				print_fin

print_prep:
	MOVE.W			#0,D4
	ADDQ.W			#2,D2				* Descriptor de transmision

print_bc:
	CMP.W			D4,D3
	BEQ				print_b_f

	MOVE.L			D2,D0
	MOVE.B			(A0)+,D1

	MOVE.L			D2,-4(A6)			* Guardar descriptor modificado
	MOVE.L			A0,-8(A6)			* Guardar *buffer
	MOVE.L			D4,-12(A6)			* Guardar contador
	BSR				ESCCAR
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
	CMP.W			#0,D4
	BEQ				print_fin

	SUBQ.W			#2,D2				* Recuperar descriptor original
	CMP.W			#1,D2				* Elegir línea
	BEQ				print_i_b

	* Reactivar interrupciones de la DUART A
	BSET			#0,IMRCP
	MOVE.B			IMRCP,IMR
	BRA				print_fin

print_i_b:					* Reactivar interrupciones de la DUART B
	BSET			#4,IMRCP
	MOVE.B			IMRCP,IMR

print_fin:
	UNLK			A6					* Recuperar marco de pila
	RTS

*****************************
************ RTI ************
*****************************
RTI:
    MOVEM.L 		A0-A6/D0-D7,-(A7)       	* Guarda todos los registros en la pila
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
    MOVEM.L  (A7)+,A0-A6/D0-D7
	RTE

********************************************
************ PROGRAMA PRINCIPAL ************
********************************************
INICIO: RTS

**********************************
************ INCLUDES ************
**********************************
INCLUDE bib_aux.s
