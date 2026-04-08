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
	BEQ				.Lscan_preparacion
	CMP.W			#1,D1
	BEQ				.Lscan_preparacion

.Lscan_error:
	MOVE.L			#-1,D0				* Poner codigo de error
	BRA				.Lscan_fin

.Lscan_preparacion:
	MOVE.W			#0,D3

.Lscan_bucle:
	CMP.W			D3,D2
	BEQ				.Lscan_bucle_fin

	MOVE.L			D1,D0

	MOVE.L			A0,-4(A6)			* Guardar *buffer
	MOVE.L			D3,-8(A6)			* Guardar contador
	BSR				LEECAR
	MOVE.L			-8(A6),D3			* Recuperar contador
	MOVE.L			-4(A6),A0			* Recuperar *buffer
	MOVE.L			12(A6),D1			* Recuperar descriptor
	MOVE.L			14(A6),D2			* Recuperar Tamano

	CMP.L			#-1,D0				* Comprobar si hay error
	BEQ				.Lscan_bucle_fin

	MOVE.B			D0,(A0)+			* Copiar caracter al buffer

	ADD.W			#1,D3				* Sumar contador
	BRA				.Lscan_bucle

.Lscan_bucle_fin:
	MOVE.L			D3,D0				* Valor de retorno (caracteres escritos)

.Lscan_fin:
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
	BEQ				.Lprint_preparacion
	CMP.W			#1,D2
	BEQ				.Lprint_preparacion

.Lprint_error:
	MOVE.L			#-1,D0				* Poner codigo de error
	BRA				.Lprint_fin

.Lprint_preparacion:
	MOVE.W			#0,D4
	ADDQ.W			#2,D2				* Descriptor de transmision

.Lprint_bucle:
	CMP.W			D4,D3
	BEQ				.Lprint_bucle_fin

	MOVE.L			D2,D0
	MOVE.B			(A0)+,D1

	MOVE.L			D2,-4(A6)			* Guardar descriptor modificado
	MOVE.L			A0,-8(A6)			* Guardar *buffer
	MOVE.L			D4,-12(A6)			* Guardar contador
	BSR				ESCCAR
	MOVE.L			-12(A6),D4			* Recuperar contador
	MOVE.L			-8(A6),A0			* Recuperar *buffer
	MOVE.L			-4(A6),D2			* Recuperar descriptor modificado
	MOVE.L			14(A6),D3			* Recuperar Tamano

	CMP.L			#-1,D0
	BEQ				.Lprint_bucle_fin

	ADD.W			#1,D4
	BRA				.Lprint_bucle

.Lprint_bucle_fin:
	
	MOVE.L			D4,D0				* Valor de retorno (caracteres escritos)
	CMP.W			#0,D4
	BEQ				.Lprint_fin

	SUBQ.W			#2,D2				* Recuperar descriptor original
	CMP.W			#1,D2				* Elegir línea
	BEQ				.Lprint_reset_imr_b

.Lprint_reset_imr_a:					* Reactivar interrupciones de la DUART A
	BSET			#0,IMRCP
	MOVE.B			IMRCP,IMR
	BRA				.Lprint_fin

.Lprint_reset_imr_b:					* Reactivar interrupciones de la DUART B
	BSET			#4,IMRCP
	MOVE.B			IMRCP,IMR

.Lprint_fin:
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
	BNE				.LRTI_TxTDYA
	BTST			#1,D0
	BNE				.LRTI_RxRDYA
	BTST			#4,D0
	BNE				.LRTI_TxTDYB
	BTST			#5,D0
	BNE				.LRTI_RxRDYB

	BRA				.LRTI_Fin

.LRTI_RxRDYA:
	MOVE.B			RBA,D1
	MOVE.L			#0,D0
	BSR				ESCCAR				
	BRA				.LRTI_FIN
.LRTI_RxRDYB:
	MOVE.B			RBB,D1
	MOVE.L			#1,D0
	BSR				ESCCAR
	BRA				.LRTI_FIN
.LRTI_TxTDYA:
	MOVE.L			#2,D0
	BSR				LEECAR
	CMP.L			#-1,D0
	BEQ				.LRTI_DESAB_TX_A
	MOVE.B			D0,TBA
	BRA				.LRTI_FIN
.LRTI_TxTDYB:
	MOVE.L			#3,D0
	BSR				LEECAR
	CMP.L			#-1,D0
	BEQ				.LRTI_DESAB_TX_B
	MOVE.B			D0,TBB
	BRA				.LRTI_FIN
.LRTI_DESAB_TX_A:
	BCLR			#0,IMRCP
	MOVE.B			IMRCP,IMR
	BRA				.LRTI_FIN
.LRTI_DESAB_TX_B:
	BCLR			#4,IMRCP
	MOVE.B			IMRCP,IMR
	BRA				.LRTI_FIN
.LRTI_FIN:
    MOVEM.L  (A7)+,A1-A6/D0-D6
	RTE

********************************************
************ PROGRAMA PRINCIPAL ************
********************************************

**********************************
************ INCLUDES ************
**********************************
INCLUDE bib_aux.s
