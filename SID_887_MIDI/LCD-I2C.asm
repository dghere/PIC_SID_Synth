#include <p16F887.inc>

	__config	_CONFIG1, _INTRC_OSC_CLKOUT & _WDT_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOR_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
	__config    _CONFIG2, _WRT_OFF & _BOR21V
	errorlevel -302
	errorlevel -305

#define	MCP_WRITE	0x40

#define	BAUD		.100
#define	FOSC		.4000


;	cblock 0x20
;message_data:16
;	endc

	cblock 0xf0
control_byte
address
data_byte
data_high
data_low
number
delay
row
column
character
message_index
string_index
offset
tdata
	endc

	cblock 0x20				;bank 0
message_data:16
digit_a
digit_b
digit_c
num_value
temp_value
prev_value
eep_address
write_data

voice_1_vol
voice_1_atkdec
voice_1_susrel
voice_1_wave
	endc

	org	0x00

	goto	Start
	
GetChar:
	addwf	PCL

String0:	dt		"Welcome!", 0						;0
String1:	dt		"Ghere is Here", 0					;1
String2:	dt		"Orange", 0							;2
String3:	dt		"Lower Message", 0					;3
EmptyLine:	dt		"                ", 0				;4
AtkString:	dt		"ATK:", 0							;5
DecString:	dt		"DEC:", 0							;6
SusString:	dt		"SUS:", 0							;7
RelString:	dt		"REL:", 0							;8
VoiceString:dt		"VC", 0								;9


GetStringAddress:
	addwf	PCL
	retlw	String0 - String0
	retlw	String1 - String0
	retlw	String2 - String0
	retlw	String3 - String0
	retlw	EmptyLine - String0
	retlw	AtkString - String0
	retlw	DecString - String0
	retlw	SusString - String0
	retlw	RelString - String0
	retlw	VoiceString - String0


Start:
	banksel	OSCCON
	movlw	b'01100111'
	movwf	OSCCON

	banksel	TRISA
	movlw	b'00001000'
	movwf	TRISA
	clrf	TRISB
	movlw	b'10011000'
	movwf	TRISC
	clrf	TRISD
	clrf	TRISE
	
	banksel	PORTD
	clrf	PORTD
	banksel	ANSEL
	clrf	ANSEL
	clrf	ANSELH

	call	ConfigI2C


LoadSettings:
	call	SetDefaultConfig

	;movlw	0x00
	;movwf	voice_1_atk

	movlw	0x00
	movwf	address
	call	ReadEEP
	banksel	voice_1_vol
	movwf	voice_1_vol
	incf	address, f
	call	ReadEEP
	banksel	voice_1_atkdec
	movwf	voice_1_atkdec
	incf	address, f
	call	ReadEEP
	banksel	voice_1_susrel
	movwf	voice_1_susrel


Setup:
	movlw	MCP_WRITE
	movwf	control_byte
	movlw	0x0a
	movwf	address
	movlw	b'00010000'
	movwf	data_byte
	call	I2CWriteSingle

; Port A and B to Output
	movlw	MCP_WRITE
	movwf	control_byte
	movlw	0x00
	movwf	address
	movlw	0x00
	movwf	data_byte
	call	I2CWriteSingle

	movlw	MCP_WRITE
	movwf	control_byte
	movlw	0x01
	movwf	address
	movlw	0x00
	movwf	data_byte
	call	I2CWriteSingle

	movlw	MCP_WRITE
	movwf	control_byte
	movlw	b'00000000'
	movwf	data_low
	movlw	b'00000000'
	movwf	data_high
	call	I2CWriteWord


	
Hello:
	movlw	MCP_WRITE
	movwf	control_byte
	movlw	0x12
	movwf	address
	movlw	b'00111000'
	movwf	data_low
	movlw	b'00000010'
	movwf	data_high
	call	I2CWriteWord
	call	Delay1mS
	movlw	MCP_WRITE
	movwf	control_byte
	movlw	0x13
	movwf	address
	movlw	b'00000000'
	call	I2CWriteSingle



;turn on Display
	movlw	MCP_WRITE
	movwf	control_byte
	movlw	0x12
	movwf	address
	movlw	b'00001101'
	movwf	data_low
	movlw	b'00000010'
	movwf	data_high
	call	I2CWriteWord
	call	Delay1mS
	movlw	MCP_WRITE
	movwf	control_byte
	movlw	0x13
	movwf	address
	movlw	b'00000000'
	call	I2CWriteSingle

; increment mode and shift cursor to top left
	movlw	MCP_WRITE
	movwf	control_byte
	movlw	0x12
	movwf	address
	movlw	b'00000110'
	movwf	data_low
	movlw	b'00000010'
	movwf	data_high
	call	I2CWriteWord
	call	Delay1mS
	movlw	MCP_WRITE
	movwf	control_byte
	movlw	0x13
	movwf	address
	movlw	b'00000000'
	call	I2CWriteSingle

;  clear and set cursor at home
	movlw	MCP_WRITE
	movwf	control_byte
	movlw	0x12
	movwf	address
	movlw	b'00000001'
	movwf	data_low
	movlw	b'00000010'
	movwf	data_high
	call	I2CWriteWord
	call	Delay1mS
	movlw	MCP_WRITE
	movwf	control_byte
	movlw	0x13
	movwf	address
	movlw	b'00000000'
	call	I2CWriteSingle

	movlw	MCP_WRITE
	movwf	control_byte
	movlw	0x12
	movwf	address
	movlw	b'00000010'
	movwf	data_low
	movlw	b'00000010'
	movwf	data_high
	call	I2CWriteWord
	call	Delay1mS
	movlw	MCP_WRITE
	movwf	control_byte
	movlw	0x13
	movwf	address
	movlw	b'00000000'
	call	I2CWriteSingle


	call	Greeting

	movlw	MCP_WRITE
	movwf	control_byte
	movlw	0x12
	movwf	address
	movlw	b'00000001'
	movwf	data_low
	movlw	b'00000010'
	movwf	data_high
	call	I2CWriteWord
	call	Delay1mS
	movlw	MCP_WRITE
	movwf	control_byte
	movlw	0x13
	movwf	address
	movlw	b'00000000'
	call	I2CWriteSingle

	movlw	MCP_WRITE
	movwf	control_byte
	movlw	0x12
	movwf	address
	movlw	b'00000010'
	movwf	data_low
	movlw	b'00000010'
	movwf	data_high
	call	I2CWriteWord
	call	Delay1mS
	movlw	MCP_WRITE
	movwf	control_byte
	movlw	0x13
	movwf	address
	movlw	b'00000000'
	call	I2CWriteSingle

DrawDisplay:
;	movlw	.32
;	call	WriteDecimalAsASCII

DrawADSR:
	movlw	.0
	movwf	column
	movlw	.0
	movwf	column
	call	SetCursor
	movlw	.9					; Write "VC"
	call	WriteString

	movlw	.0					;  Write Voice Number
	movwf	column
	movlw	.1
	movwf	row
	call	SetCursor
	movlw	0x01
	call	WriteDecimalAsASCII

	movlw	.3					; Write "ATK"
	movwf	column
	movlw	.0
	movwf	row
	call	SetCursor 
	movlw	.5
	call	WriteString
	banksel	voice_1_atkdec
	movf	voice_1_atkdec, w		; atk/dec value
	call	GetUpperNibble
	call	WriteDecimalAsASCII

	movlw	.10					; Write "SUS"
	movwf	column
	movlw	.0
	movwf	row
	call	SetCursor 
	movlw	.7
	call	WriteString
	banksel	voice_1_susrel
	movf	voice_1_susrel, w		; sus value
	call	GetUpperNibble
	call	WriteDecimalAsASCII

	movlw	.3					; Write "DEC"
	movwf	column
	movlw	.1
	movwf	row
	call	SetCursor 
	movlw	.6
	call	WriteString
	banksel	voice_1_atkdec
	movf	voice_1_atkdec, w		; dec value
	call	GetLowerNibble
	call	WriteDecimalAsASCII

	movlw	.10					; Write "REL"
	movwf	column
	movlw	.1
	movwf	row
	call	SetCursor 
	movlw	.8
	call	WriteString
	banksel	voice_1_susrel
	movf	voice_1_susrel, w		; rel value
	call	GetLowerNibble
	call	WriteDecimalAsASCII

	movlw	.8
	movwf	column
	movlw	.0
	movwf	row
	call	SetCursor

	goto $

GetUpperNibble:
	movwf	tdata
	rrf		tdata, f
	rrf		tdata, f
	rrf		tdata, f
	rrf		tdata, f
	movlw	0x0f
	andwf	tdata, w
	return

GetLowerNibble:
	movwf	tdata
	movlw	0x0f
	andwf	tdata, w
	return

WriteCharacter:
	movwf	data_low
	movlw	MCP_WRITE
	movwf	control_byte
	movlw	0x12
	movwf	address
	movlw	b'00000011'
	movwf	data_high
	call	I2CWriteWord
	call	Delay1mS
	movlw	MCP_WRITE
	movwf	control_byte
	movlw	0x13
	movwf	address
	movlw	b'00000000'
	call	I2CWriteSingle
	return
	

	
WriteString:
;	movf	string_index, w
	call	GetStringAddress
	movwf	offset

StringWriteLoop:
	movf	offset, w
	call	GetChar
	movwf	character
	movlw	0x00
	subwf	character, w
	btfsc	STATUS, Z
	return
	movf	character, w
	call	WriteCharacter
	incf	offset, f
	goto	StringWriteLoop

ClearLCD:
	movlw	MCP_WRITE
	movwf	control_byte
	movlw	0x12
	movwf	address
	movlw	b'00000001'
	movwf	data_low
	movlw	b'00000010'
	movwf	data_high
	call	I2CWriteWord
	call	Delay1mS
	movlw	MCP_WRITE
	movwf	control_byte
	movlw	0x13
	movwf	address
	movlw	b'00000000'
	call	I2CWriteSingle
	return
;;;;;;;;;;;;;;;;;;;;;;



Main:
	banksel	PORTD
	bsf		PORTD, 0
	goto	Main

FailMain:
	goto	FailMain

SetCursor:
	movlw	0x80
	addwf	column, f
	movlw	0x40					;  2nd row starting position
	btfsc	row, 0				;  test if row = b'00000001'
	addwf	column, f
								; at this line, column contains the position for the character
								; adjusted for the proper row	
	movlw	0x80
	movlw	MCP_WRITE
	movwf	control_byte
	movlw	0x12
	movwf	address
	movf	column, w
	movwf	data_low
	movlw	b'00000010'
	movwf	data_high
	call	I2CWriteWord
	call	Delay1mS
	movlw	MCP_WRITE
	movwf	control_byte
	movlw	0x13
	movwf	address
	movlw	b'00000000'
	call	I2CWriteSingle
	return


ConfigI2C:
	banksel	SSPCON

; Enables MSSP and uses
; PORTC pins for I2C mode
; (SSPEN set) AND
; Enables I2C Master Mode
; (SSPMx bits)
	movlw	b'00101000'
	movwf	SSPCON

; Input Levels and slew reate as I2C Standard Levels
	BANKSEL	SSPSTAT
	movlw	b'10000000'			; Slew Rate control (SMP) 100kHz
	movwf	SSPSTAT				; mode and input levels are I2C
								; loaded into SSPSTAT

; Configure Baud Rate
	banksel	SSPADD
	movlw(FOSC / (4 * BAUD))-1	; Calculate SSPADD
	movwf	SSPADD				; Set rate and setup SSPADD

	return

I2CWriteSingle:
	banksel	PORTD
	bsf		PORTD, 2
; Send START and wait for it to complete
	banksel	SSPCON2
	bsf		SSPCON2, SEN
	call	WaitMSSP

; Send and Check CONTROL byte, wait for it to complete
	movf	control_byte, w		; Load for input
	call	Send_I2C_Byte		; send byte
	call	WaitMSSP			; Wait for I2C operation
;return
	banksel	SSPCON2
	btfsc	SSPCON2, ACKSTAT	; check ACK bit
	goto	I2CFail				; failed, skipped if successful


; Send and Check ADDRESS byte wait for it to complte
	movf	address, w			; Load Address Byte
	call	Send_I2C_Byte		; Send byte
	call	WaitMSSP			; Wait for I2C operation

	banksel	SSPCON2
	btfsc	SSPCON2, ACKSTAT	; check ACK bit
	goto	I2CFail				; failed, skipped if successful

; Send and Check DATA byte wait for it to complete
	movf	data_byte, w		; Load the data byte
	call	Send_I2C_Byte		; Send byte
	call	WaitMSSP			; Wait for I2C operation

	banksel	SSPCON2
	btfsc	SSPCON2, ACKSTAT	; check ACK bit
	goto	I2CFail				; failed, skipped if successful

; Send and Check the STOP condition, wait for it to complete
	banksel	SSPCON2
	bsf		SSPCON2, PEN		; Send STOP (P) condition
	call	WaitMSSP			; Wait for I2C operation

	banksel	PORTD
	bcf		PORTD, 2
; The WRITE has successfully completed
	return

I2CWriteWord:
	banksel	PORTD
	bsf		PORTD, 2
; Send START and wait for it to complete
	banksel	SSPCON2
	bsf		SSPCON2, SEN
	call	WaitMSSP

; Send and Check CONTROL byte, wait for it to complete
	movf	control_byte, w		; Load for input
	call	Send_I2C_Byte		; send byte
	call	WaitMSSP			; Wait for I2C operation
;return
	banksel	SSPCON2
	btfsc	SSPCON2, ACKSTAT	; check ACK bit
	goto	I2CFail				; failed, skipped if successful


; Send and Check ADDRESS byte wait for it to complte
	movf	address, w			; Load Address Byte
	call	Send_I2C_Byte		; Send byte
	call	WaitMSSP			; Wait for I2C operation

	banksel	SSPCON2
	btfsc	SSPCON2, ACKSTAT	; check ACK bit
	goto	I2CFail				; failed, skipped if successful

; Send and Check DATA byte wait for it to complete
	movf	data_low, w		; Load the data byte
	call	Send_I2C_Byte		; Send byte
	call	WaitMSSP			; Wait for I2C operation

	banksel	SSPCON2
	btfsc	SSPCON2, ACKSTAT	; check ACK bit
	goto	I2CFail				; failed, skipped if successful

; Send and Check DATA byte wait for it to complete
	movf	data_high, w		; Load the data byte
	call	Send_I2C_Byte		; Send byte
	call	WaitMSSP			; Wait for I2C operation

	banksel	SSPCON2
	btfsc	SSPCON2, ACKSTAT	; check ACK bit
	goto	I2CFail				; failed, skipped if successful

; Send and Check the STOP condition, wait for it to complete
	banksel	SSPCON2
	bsf		SSPCON2, PEN		; Send STOP (P) condition
	call	WaitMSSP			; Wait for I2C operation

	banksel	PORTD
	bcf		PORTD, 2
; The WRITE has successfully completed
	return


; *** SUBROUTINES & ERROR HANDLERS ***;
; I2C Operation Failed code sequence -This will normally not
; happen, but if it does, a STOP is sent and the entire code
; is tried again
I2CFail:
	banksel	SSPCON2
	bsf		SSPCON2, PEN
	call	WaitMSSP
	
	banksel	PORTD
	bsf		PORTD, 2
;	return	
	goto	FailMain

; This routine sends the W register to SSPBUF, thus
; transmitting a byte.  The SSPIF flag is checked to ensure
; the byte has been sent.  On completion, the routine exits
Send_I2C_Byte:
	banksel	SSPBUF
	movwf	SSPBUF				; Put value into SSPBUF, sent automatically
	retlw	0					; Done, return 0

; This routine waits for the last I2C operation to complete.
; It does this by polling the SSPIF flag in PIR1.
WaitMSSP:
	banksel	PIR1
	btfss	PIR1, SSPIF			; I2C done?
	goto	$-1					; if clear, loop back
	bcf		PIR1, SSPIF			; I2C ready, clear the flag
	retlw	0					; Return 0


;;  EEPROM Code
WriteEEP:
	banksel	EEADR
	movlw	address
	movwf	FSR
	movf	INDF, 0
	movwf	EEADR
	movlw	data_byte
	movwf	FSR
	movf	INDF, 0
	movwf	EEDAT
	banksel	EECON1
	bcf		EECON1, EEPGD
	bsf		EECON1, WREN
	
	bcf		INTCON, GIE
	btfsc	INTCON, GIE
	goto	$-2
	movlw	0x55
	movwf	EECON2
	movlw	0xaa
	movwf	EECON2
	bsf		EECON1, WR
	bsf		INTCON, GIE
	btfsc	EECON1, WR				; wait for write to finish
	goto	$-1
	bcf		EECON1, WREN
;	banksel	0x00
	return

ReadEEP:
	banksel	EEADR
	movf	address, w
	movwf	EEADR
	banksel	EECON1
	bcf		EECON1, EEPGD
	bsf		EECON1, RD
	banksel	EEDAT
	movf	EEDAT, w
	bcf		STATUS, RP0
	return

WriteDecimalAsASCII:
	movwf	num_value
	call	GetDigits
	movlw	.48
	subwf	digit_c
	btfsc	STATUS, Z
	goto	WriteB
	movf	digit_c, w
	call	WriteCharacter
WriteB:
	movf	digit_b, w
	call	WriteCharacter
	movf	digit_a, w
	call	WriteCharacter
	return

GetDigits:
	banksel	digit_a
	movlw	0x00				; clear all digits
	movwf	digit_a
	movwf	digit_b
	movwf	digit_c
	movf	num_value, w
	movwf	temp_value

Test:
	movf	temp_value, w
	movwf	prev_value
	movlw	.100
	subwf	temp_value, 1
	btfss	STATUS, C
	goto	NextDigit				;  brach if patch <= 100
	incf	digit_c			;  we have found that the answer was =>100
	btfss	STATUS, Z
	goto	Test
	
	goto	AdjustASCII
NextDigit:					; the patch now is < 100, so process the same..
							; yeah, redundant code, but my assembly is rusty
	movf	prev_value, 0
	movwf	temp_value
TestFor10s:
	movf	temp_value, 0
	movwf	prev_value
	movlw	.10
	subwf	temp_value, 1
	btfss	STATUS, C
	goto	LastDigit				;  brach if patch <= 10
	incf	digit_b		;  we have found that the answer was =>10
	btfss	STATUS, Z
	goto 	TestFor10s
	goto	EqualTens
EqualTens:
	movlw	0x00
	movwf	digit_a
	goto	AdjustASCII
LastDigit:
	movf	prev_value, 0
	movwf	digit_a
AdjustASCII:
	movlw	.48
	addwf	digit_c, f
	addwf	digit_b, f
	addwf	digit_a, f
	return

Greeting:
	movlw	.4
	movwf	column
	movlw	.0
	movwf	row
	call	SetCursor
	movlw	.0
	call	WriteString
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay

	movlw	MCP_WRITE
	movwf	control_byte
	movlw	0x12
	movwf	address
	movlw	b'00000001'
	movwf	data_low
	movlw	b'00000010'
	movwf	data_high
	call	I2CWriteWord
	call	Delay1mS
	movlw	MCP_WRITE
	movwf	control_byte
	movlw	0x13
	movwf	address
	movlw	b'00000000'
	call	I2CWriteSingle
	return

Delay1mS:
	movlw     .71               ; delay ~1000uS
	movwf     delay
	decfsz    delay,f             ; this loop does 215 cycles
	goto      $-1          
	decfsz    delay,f             ; This loop does 786 cycles
	goto      $-1
	return


LongDelay:
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	call	Delay1mS
	return

SetDefaultConfig:
	call	LongDelay				; Wait for EEP
	movlw	0x00
	movwf	address
	movlw	.15
	movwf	data_byte
	call	WriteEEP

	incf	address, f
	movlw	0x94
	movwf	data_byte
	call	WriteEEP

	incf	address, f
	movlw	0xf3
	movwf	data_byte
	call	WriteEEP

	return

	end