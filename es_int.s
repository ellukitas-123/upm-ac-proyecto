* Definici�n de equivalencias
*********************************

MR1A    EQU     $EFFC01       * de modo A (escritura)
MR2A    EQU     $EFFC01       * de modo A (2� escritura)
SRA     EQU     $EFFC03       * de estado A (lectura)
CSRA    EQU     $EFFC03       * de seleccion de reloj A (escritura)
CRA     EQU     $EFFC05       * de control A (escritura)
TBA     EQU     $EFFC07       * buffer transmision A (escritura)
RBA     EQU     $EFFC07       * buffer recepcion A  (lectura)
ACR		EQU		$EFFC09	      * de control auxiliar
IMR     EQU     $EFFC0B       * de mascara de interrupcion A (escritura)
ISR     EQU     $EFFC0B       * de estado de interrupcion A (lectura)
MR1B    EQU     $EFFC11       * de modo B (escritura)
MR2B    EQU     $EFFC11       * de modo B (2� escritura)
CRB     EQU     $EFFC15	      * de control A (escritura)
TBB     EQU     $EFFC17       * buffer transmision B (escritura)
RBB		EQU		$EFFC17       * buffer recepcion B (lectura)
SRB     EQU     $EFFC13       * de estado B (lectura)
CSRB	EQU		$EFFC13    	  * de seleccion de reloj B (escritura)

IVR		EQU		$EFFC19		  	* Vector de interrupcion
IMR		EQU		$EFFC0B		  	* Mascara de interrupcion


CR		EQU		$0D	      		* Carriage Return
LF		EQU		$0A	      		* Line Feed
FLAGT	EQU		2	      		* Flag de transmisi�n
FLAGR   EQU     0	      		* Flag de recepci�n

INIT:
	MOVE.B          #%00010000,CRA      * Reiniciar a MR1A
	MOVE.B          #%00010000,CRB      * Reiniciar a MR1B
	MOVE.B          #%00000011,MR1A     * establecer 8 bits/caracter A
	MOVE.B          #%00000011,MR1B     * establecer 8 bits/caracter B
	MOVE.B          #%00000000,MR2A     * Desactivar eco A
	MOVE.B          #%00000000,MR2B     * Desactivar eco B
	MOVE.B          #%11001100,CSRA     * 38400 bps
	MOVE.B          #%11001100,CSRB     * 38400 bps
	MOVE.B          #%00000000,ACR      
	MOVE.B          #%00000101,CRA      * Full duplex
	MOVE.B          #%00000101,CRB      * Full duplex

	MOVE.B 			#$40,IVR			* Vector de interrupción
	MOVE.B 			#%00100010, IMR		* Habilitar interrupciones

	* Recordar poner la RTI por aquí (Rutina de tratamiento de interrupcion)

	BSR 			INI_BUFS
	RTS

* Esto debe quedarse al final
INCLUDE bib_aux.s
