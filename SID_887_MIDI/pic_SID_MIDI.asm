; Program to drive SID using 16f887 and a shift register
; Github version


#include <p16F887.inc>

	__config	_CONFIG1, _INTRC_OSC_CLKOUT & _WDT_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOR_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
	__config    _CONFIG2, _WRT_OFF & _BOR21V
	errorlevel -302
	errorlevel -305

#define	MCP_WRITE	0x40

;#define	LC01CTRLIN	0xa0
;#define	LC01CTRLOUT	0xa1
;#define	LC01ADDR	0x12
;#define	LC01DATA	0x34
#define	BAUD		.100
#define	FOSC		.4000

;SID Read/Write Control bit
SIDRW	equ	1						; PORTE  old PORTB
;Shift Register
SER		equ	5						; PORTC  old PORTB
SRCLK	equ	0						; PORTC  old PORTB
RCLK	equ	1						; PORTC  old PORTA
SRCLR	equ	0						; PORTE  old PORTA

; Set Serial Buffer Length
RX_BUFF_LEN	EQU		.80
TX_BUFF_LEN	EQU		RX_BUFF_LEN

; Buffer status bits
TX_BUFF_FULL	EQU		0
TX_BUFF_EMPTY	EQU		1
RX_BUFF_FULL	EQU		2
RX_BUFF_EMPTY	EQU		3



	cblock 0x20
tobereturned
;delay
sidaddress
freqH
freqL
counter
attdec
susrel
pulseWidthH
pulseWidthL
note_index
;EUSART

rx_start_ptr
rx_end_ptr
tx_start_ptr
tx_end_ptr
buffer_data
midi_byte
midi_data1
midi_data2
prev_command

digit_a
digit_b
digit_c
num_value
temp_value
prev_value

multip
product
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

	cblock 0x70
w_temp
status_temp
pcl_save
fsr_temp

flags

control_byte
address
data_byte
data_high
data_low
tableLow
	endc



	cblock 0xa0
rx_buffer:RX_BUFF_LEN
	endc

	cblock 0x120
tx_buffer:TX_BUFF_LEN
	endc


; executed upon reset
	org		0x0000
ResetCode:
	clrf	PCLATH
	goto	Start

; executed upon interrupt
	org		0x0004
InterruptCode:
	movwf	w_temp
	swapf	STATUS, w
	clrf	STATUS
	movwf	status_temp
	movf	PCLATH, w
	movwf	pcl_save
	clrf	PCLATH
	movf	FSR, w
	movwf	fsr_temp

	banksel	INTCON
	bcf		INTCON, 7			; disable interrupts
	
	banksel	PIR1				; check for interrupt on serial
	btfsc	PIR1, RCIF
	bsf		STATUS, RP0
	btfsc	PIE1, RCIE
	goto	GetSerialData

	goto	ExitInterrupt

GetSerialData:
	banksel	RCSTA
	btfsc	RCSTA, OERR
	goto	ErrSerialOver
	btfsc	RCSTA, FERR
	goto	ErrSerialFrame

	btfsc	flags, RX_BUFF_FULL
	goto	RxOverErr
	movf	RCREG, w
	call	PutRxBuffer

	goto	ExitInterrupt

ErrSerialOver:
	banksel	RCSTA
	bcf		RCSTA, CREN
	nop
	bsf		RCSTA, CREN
	goto	ExitInterrupt

ErrSerialFrame:
RxOverErr:
	banksel	RCREG
	movf	RCREG, w
	goto	ExitInterrupt



ExitInterrupt:
	movf	fsr_temp, w
	movwf	FSR
	movf	pcl_save, w
	movwf	PCLATH
	swapf	status_temp, w
	movwf	STATUS
	swapf	w_temp, f
	swapf	w_temp, w

	banksel	INTCON
	bsf		INTCON, 7				; enable peripheral interrupts again
	bsf		INTCON, 6

	retfie




;	org 0x200



HighFreqLookup:
	clrf	PCLATH
	addwf	PCL
	dt		0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x02
	dt		0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x03, 0x03, 0x03, 0x03, 0x03, 0x04
	dt		0x04, 0x04, 0x04, 0x05, 0x05, 0x05, 0x06, 0x06, 0x06, 0x07, 0x07, 0x08
	dt		0x08, 0x09, 0x09, 0x0a, 0x0a, 0x0b, 0x0c, 0x0c, 0x0d, 0x0e, 0x0f, 0x10
	dt		0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x18, 0x19, 0x1b, 0x1c, 0x1e, 0x20
	dt		0x22, 0x24, 0x26, 0x28, 0x2b, 0x2d, 0x30, 0x33, 0x36, 0x39, 0x3d, 0x40
	dt		0x44, 0x48, 0x4c, 0x51, 0x56, 0x5b, 0x60, 0x66, 0x6c, 0x73, 0x7a, 0x81
	dt		0x89, 0x91, 0x99, 0xa3, 0xac, 0xb7, 0xc1, 0xcd, 0xd9, 0xe6, 0xf4
LowFreqLookup:
	clrf	PCLATH
	addwf	PCL
	dt		0x12, 0x23, 0x34, 0x46, 0x5a, 0x6e, 0x84, 0x8b, 0xb3, 0xcd, 0xe9, 0x06
	dt		0x25, 0x45, 0x68, 0x8c, 0xb3, 0xdc, 0x08, 0x36, 0x67, 0x9b, 0xd2, 0x0c
	dt		0x49, 0x8b, 0xd0, 0x19, 0x67, 0xb9, 0x10, 0x6c, 0xce, 0x35, 0xa3, 0x17
	dt		0x93, 0x15, 0x9f, 0x32, 0xcd, 0x72, 0x20, 0xd8, 0x9c, 0x6b, 0x46, 0x2f
	dt		0x25, 0x2a, 0x3f, 0x64, 0x9a, 0xe3, 0x3f, 0x81, 0x38, 0xd6, 0x80, 0x5e
	dt		0x4b, 0x55, 0x7e, 0xc8, 0x34, 0xc6, 0x7f, 0x61, 0x6f, 0xac, 0x1a, 0xbc
	dt		0x95, 0xa9, 0xfc, 0x8f, 0x69, 0x8c, 0xfe, 0x02, 0xdf, 0x58, 0x34, 0x78
	dt		0x2b, 0x53, 0xf7, 0x1f, 0xd2, 0x19, 0xfc, 0x85, 0xbd, 0xb0, 0x67


NoteLookup:  ; Each note is 3 bytes, so Note * 3 = Address for start of string
;	addwf	PCL
	addlw	LOW(NoteTableStart)
	movwf	tableLow
	movlw	HIGH(NoteTableStart)
	btfsc	STATUS, C
	addlw	.1
	movwf	PCLATH
	movf	tableLow, w
	movwf	PCL

NoteTableStart:
	dt		"C0 ", "C0#", "D0 ", "D0#", "E0 ", "F0 ", "F0#", "G0 ", "G0#", "A0 ", "A0#", "B0 "
	dt		"C1 ", "C1#", "D1 ", "D1#", "E1 ", "F1 ", "F1#", "G1 ", "G1#", "A1 ", "A1#", "B1 "
	dt		"C2 ", "C2#", "D2 ", "D2#", "E2 ", "F2 ", "F2#", "G2 ", "G2#", "A2 ", "A2#", "B2 "
	dt		"C3 ", "C3#", "D3 ", "D3#", "E3 ", "F3 ", "F3#", "G3 ", "G3#", "A3 ", "A3#", "B3 "
	dt		"C4 ", "C4#", "D4 ", "D4#", "E4 ", "F4 ", "F4#", "G4 ", "G4#", "A4 ", "A4#", "B4 "
	dt		"C5 ", "C5#", "D5 ", "D5#", "E5 ", "F5 ", "F5#", "G5 ", "G5#", "A5 ", "A5#", "B5 "
	dt		"C6 ", "C6#", "D6 ", "D6#", "E6 ", "F6 ", "F6#", "G6 ", "G6#", "A6 ", "A6#", "B6 "
	dt		"C7 ", "C7#", "D7 ", "D7#", "E7 ", "F7 ", "F7#", "G7 ", "G7#", "A7 ", "A7#"



Start:
	call	InitPIC
	call	InitShiftRegister
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay


	call	InitSID
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	
	call	ConfigI2C
	call	SetupMCP

	
	movlw	.48
	call	WriteString
	

;	goto	FailMain
	banksel	PORTA
	bcf		PORTA, 0
	
;	goto $
MainLoop:
	banksel	freqH
	movlw	0x1c
	movwf	freqH
	movlw	0xd6
	movwf	freqL
	call 	PlayNote
	clrf	note_index
Repeat:
	banksel	freqH
	btfsc	flags, RX_BUFF_EMPTY
	goto	Repeat
	call	GetRxBuffer								; rx buffer not empty so read it

;	goto	Repeat
	movwf	midi_byte	
	movlw	0xf0
	andwf	midi_byte, f
	movlw	0x90
	subwf	midi_byte, w
	btfss	STATUS, Z
	goto	Repeat
	
	btfsc	flags, RX_BUFF_EMPTY
	goto	$-1
	call	GetRxBuffer
	movwf	midi_data1
	
	
	
	nop
	btfsc	flags, RX_BUFF_EMPTY
	goto	$-1
	call	GetRxBuffer
	movwf	midi_data2
	movlw	0x00
	subwf	midi_data2
	btfss	STATUS, Z
	goto	NoteOn
	call	StopNote
	goto	Repeat

; the following until NoteOn: works without interrupts. saving for later
	banksel	PIR1
	btfss	PIR1, RCIF
	goto	$-1 
	movf	RCREG, W
	movwf	midi_byte	
	movlw	0xf0
	andwf	midi_byte, f
	movlw	0x90
	subwf	midi_byte, w
	btfss	STATUS, Z
	goto Repeat
	banksel	PIR1
	btfss	PIR1, RCIF
	goto	$-1
	movf	RCREG, W
	movwf	midi_data1
	btfss	PIR1, RCIF
	goto	$-1
	movf	RCREG, w
	movwf	midi_data2
	movlw	0x00
	subwf	midi_data2
	btfss	STATUS, Z
	goto	NoteOn
	call	StopNote
	goto	Repeat
NoteOn:
	call	ClearLCD
	banksel midi_data1
	movf	midi_data1, w
	call	WriteString
	movf	midi_data1, w
	call	HighFreqLookup
	movwf	freqH
	movf	midi_data1, w
	call	LowFreqLookup
	movwf	freqL
	call 	PlayNote
	rrf		midi_byte, f
	rrf		midi_byte, f
	rrf		midi_byte, f
	rrf		midi_byte, w
	andlw	0x0f
	movwf	PORTB
	banksel	RCSTA
	btfss	RCSTA, OERR
	goto	Repeat
	bcf		RCSTA, CREN
	call	Delay1mS
	bcf		RCSTA, CREN

	goto Repeat

FailMain:
	banksel	PORTA
	bcf		PORTA, 0
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	bsf		PORTA, 0
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	call	LongDelay
	goto	FailMain

InitSID:
	banksel	sidaddress
	call	ClearSID

	movlw	0x73
	movwf	attdec
	movlw	0xf2
	movlw	susrel
	call	InitVoice1
	call	InitVoice2
	call	InitVoice3

	; Set master volume to 15
	bsf		PORTE, SIDRW				; SID read mode
	call	Delay1mS
	call	Delay1mS
	movlw	.24
	movwf	sidaddress
	call	AddressToOutputs
	movlw	0x0f
	movwf	PORTD
	bcf		PORTE, SIDRW				; SID write mode
	call	Delay1mS

	return

InitVoice1:
	; Set voice 1 Attack/Decay
	bsf		PORTE, SIDRW				; SID read mode
	call	Delay1mS
	call	Delay1mS
	movlw	.5
	movwf	sidaddress
	call	AddressToOutputs
	movf	attdec, w
	movwf	PORTD
	bcf		PORTE, SIDRW				; SID write mode
	call	Delay1mS

; Set voice 1 Sustain/Release
	bsf		PORTE, SIDRW				; SID read mode
	call	Delay1mS
	call	Delay1mS
	movlw	.6
	movwf	sidaddress
	call	AddressToOutputs
	movf	susrel, w
	movwf	PORTD
	bcf		PORTE, SIDRW				; SID write mode
	call	Delay1mS

	return

InitVoice2:
	banksel	PORTB
; Set voice 2 Attack/Decay
	bsf		PORTE, SIDRW				; SID read mode
	call	Delay1mS
	call	Delay1mS
	movlw	.12
	movwf	sidaddress
	call	AddressToOutputs
	movf	attdec, w
	movwf	PORTD
	bcf		PORTE, SIDRW				; SID write mode
	call	Delay1mS

; Set voice 2 Sustain/Release
	bsf		PORTE, SIDRW				; SID read mode
	call	Delay1mS
	call	Delay1mS
	movlw	.13
	movwf	sidaddress
	call	AddressToOutputs
	movf	susrel, w
	movwf	PORTD
	bcf		PORTE, SIDRW				; SID write mode
	call	Delay1mS

	return

InitVoice3:
	return

;MainLoop:
;	incf	address
;	call	AddressToOutputs
;	call	Delay1mS



PlayNote:
	banksel	PORTB
; voice 1
	bsf		PORTE, SIDRW			;  SID read mode
	call	Delay1mS
	call	Delay1mS
	banksel	sidaddress
	movlw	.1
	movwf	sidaddress
	call	AddressToOutputs
	movf	freqH, w
	movwf	PORTD
	bcf		PORTE, SIDRW			;  SID write mode
	call	Delay1mS

	bsf		PORTE, SIDRW			;  SID read mode
	call	Delay1mS
	call	Delay1mS
	movlw	.0
	movwf	sidaddress
	call	AddressToOutputs
	movf	freqL, w
	movwf	PORTD
	bcf		PORTE, SIDRW			;  SID write mode
	call	Delay1mS

;  Set waveform and gate
	bsf		PORTE, SIDRW			;  SID read mode
	call	Delay1mS
	call	Delay1mS
	movlw	.4
	movwf	sidaddress
	call	AddressToOutputs
	movlw	b'00100001'
	movwf	PORTD
	bcf		PORTE, SIDRW			;  SID write mode
	call	Delay1mS
	return

StopNote:
	banksel	PORTB
	bsf		PORTE, SIDRW			;  SID read mode
	call	Delay1mS
	call	Delay1mS
	movlw	.4
	movwf	sidaddress
	call	AddressToOutputs
	movf	b'01000000'
	movwf	PORTD
	bcf		PORTE, SIDRW			;  SID write mode
	call	Delay1mS

	return

InitPIC:

	banksel	OSCCON
	movlw	b'01100111'
	movwf	OSCCON					; Oscillator set to 4 MHz

	banksel	OPTION_REG
	bcf		OPTION_REG, T0CS
	bcf		OPTION_REG, PS2
	bcf		OPTION_REG, PS1
	bcf		OPTION_REG, PS0

	;bcf		PIE2, EEIE

	banksel	TRISA
	movlw	b'00001000'
	movwf	TRISA
	clrf	TRISB
	movlw	b'10011000'
	movwf	TRISC
	clrf	TRISD
	clrf	TRISE

	banksel	ANSEL
	clrf	ANSEL
	clrf	ANSELH

	banksel	PORTA
	bcf		PORTA, 0

	call	InitRxBuffer
	call	EnableMIDI

	call	LongDelay
	return



InitShiftRegister:
	banksel	PORTB
	bcf		PORTC, SRCLK
	bcf		PORTC, RCLK
	bcf		PORTC, SER
	call	ClearRegister
	return

SetSerialHigh:
	banksel	PORTB
	bsf		PORTC, SER
	nop
	bsf		PORTC, SRCLK
	nop
	bcf		PORTC, SRCLK
	return

SetSerialLow:
	banksel	PORTB
	bcf		PORTC, SER
	nop
	bsf		PORTC, SRCLK
	nop
	bcf		PORTC, SRCLK
	return

SetOutputs:
	banksel	PORTA
	bsf	PORTC, RCLK
	nop
	BCF	PORTC, RCLK
	return

ClearRegister:
	banksel	PORTA
	bcf	PORTA, SRCLR
	nop
	BSF	PORTA, SRCLR
	return

;called with value to be written in 'address'
AddressToOutputs:
	call	ClearRegister
	banksel	PORTB
	bcf		PORTC, SER
	btfsc	sidaddress, 0
	call	SetSerialHigh
	btfss	sidaddress, 0
	call	SetSerialLow
	bcf		PORTC, SER
	btfsc	sidaddress, 1
	call	SetSerialHigh
	btfss	sidaddress, 1
	call	SetSerialLow
	bcf		PORTC, SER
	btfsc	sidaddress, 2
	call	SetSerialHigh
	btfss	sidaddress, 2
	call	SetSerialLow
	bcf		PORTC, SER
	btfsc	sidaddress, 3
	call	SetSerialHigh
	btfss	sidaddress, 3
	call	SetSerialLow
	bcf		PORTC, SER
	btfsc	sidaddress, 4
	call	SetSerialHigh
	btfss	sidaddress, 4
	call	SetSerialLow
;	bcf		PORTC, SER
;	btfsc	address, 5
;	call	SetSerialHigh
;	btfss	address, 5
;	call	SetSerialLow
	
	call	SetOutputs

;	call	LongDelay
;	call	LongDelay

	return


	

ClearSID:
	banksel	PORTA
	movlw	0x00
	movwf	sidaddress					; Set address to 0 for clear
ClearSIDLoop:	
	bsf		PORTE, SIDRW			; R/~W set for read
	call	Delay1mS				; wait to avoid garbage
	call	Delay1mS
	call	AddressToOutputs		; set Address on SID A0-A4
	clrf	PORTD					; clear SID data D0-D7
	bcf		PORTE, SIDRW			; SID write mode
	call	Delay1mS
	incf	sidaddress
	movlw	.25
	subwf	sidaddress, w
	btfss	STATUS, Z				;  if address bit 5 set, add = 32 so exit
	goto	ClearSIDLoop
	return

InitRxBuffer:
	bcf		STATUS, RP0
	bcf		STATUS, RP1				; Bank 0
	movlw	LOW rx_buffer			; Get RxBuffer address
	movwf	rx_start_ptr				; Put in Rx Start Ptr
	movwf	rx_end_ptr				; Also put in Rx End Ptr
	bcf		flags, RX_BUFF_FULL		; Clear Rx buffer full flag
	bsf		flags, RX_BUFF_EMPTY		; Clear Rx buffer empty flag
	return

; Store data received on the RX buffer
PutRxBuffer:
	bcf		STATUS, RP0
	bcf		STATUS, RP1
	btfsc	flags, RX_BUFF_FULL
	goto	RxBuffFullErr
	movwf	buffer_data				; store for later
	btfss	buffer_data, 7			; test if status command
	goto	StoreData				; not set, is not status command
	movwf	buffer_data			; store back in w 
	movwf	prev_command			; store as previous command for use later
StoreData:
	bankisel	rx_buffer
	movf	rx_end_ptr, w
	movwf	FSR
	movf	buffer_data, w
	movwf	INDF

;  test for wrap around
	movlw	LOW rx_buffer + RX_BUFF_LEN - 1	; find end of buffer
	xorwf	rx_end_ptr, w
	movlw	LOW rx_buffer
	btfss	STATUS, Z
	incf	rx_end_ptr, w
	movwf	rx_end_ptr

; Test if buffer is full
	subwf	rx_start_ptr, w
	btfsc	STATUS, Z
	bsf		flags, RX_BUFF_FULL
	bcf		flags, RX_BUFF_EMPTY
	return

RxBuffFullErr:
	return

; Get data from the receive buffer
GetRxBuffer:
	bcf		STATUS, RP0
	bcf		STATUS, RP1				; Bank 0
	btfsc	flags, RX_BUFF_EMPTY	; Is the Receive buffer empty?
	goto	RxBuffEmptyErr			; Handle it if so
	
	bsf		STATUS, RP0				; Bank 1
	bcf		PIE1, RCIE				; Disable Rx interrupts
	bcf		STATUS, RP0				; Bank 0
	
	BANKISEL	rx_buffer			; Set bit for Bank indirect addressing
	movf	rx_start_ptr, W			; Get the start pointer
	movwf	FSR						; Put into FSR

; test for buffer pointer wraparound
	movlw	LOW rx_buffer + RX_BUFF_LEN - 1	; Get last address of the buffer
	xorwf	rx_start_ptr, W			; Compare with StartPointer
	movlw	LOW rx_buffer			; Load first address of the buffer
	btfss	STATUS, Z				; Is it at the last address?
	incf	rx_start_ptr, W			; No, then increment it
	movwf	rx_start_ptr				; Store the new value
	bcf		flags, RX_BUFF_FULL		; Buffer mustn't be full

; Test if buffer is empty
	xorwf	rx_end_ptr, W				; Compare Start to End
	btfsc	STATUS, Z				; Is it the same?
	bsf		flags, RX_BUFF_EMPTY	; If the same, the buffer is empty
	movf	INDF, W					; get the data from the buffer (indirectly)
;	movwf	tobereturned
	bsf		STATUS, RP0				; Bank 1
	bsf		PIE1, RCIE				; Turn interrupts back on
	bcf		STATUS, RP0				; Bank 0
	return							; return with databyte in w

; Simply return zero if buffer is empty
RxBuffEmptyErr:
	bsf		STATUS, RP0
	bcf		STATUS, RP1				; Bank 1
	bsf		PIE1, RCIE				; Enable Rx interrupts
	bcf		STATUS, RP0				; Bank 0
	retlw	0 

; MIDI init
EnableMIDI:
	banksel	ANSEL
	clrf	ANSEL
	clrf	ANSELH

	banksel	SPBRGH
	movlw	0x00
	movwf	SPBRGH
	movlw	0x01				;  Use for 4MHz system clock
;	movlw	0x0f				;  Use for 8MHz system clock
	movwf	SPBRG
;	bsf		TXSTA, BRGH
;	bcf		BAUDCTL, BRG16			; Set for 31250 baud
	bcf		TXSTA, SYNC				; Asynchronous
	bsf		PIE1, RCIE				; Receive Interrupt enable
	bsf		INTCON, GIE				; Global Interrupt enable
	bsf		INTCON, PEIE			; Peripheral Interrupt enable

;	banksel	RCSTA					; Page 0
;	bsf		RCSTA, SPEN				; Enable Serial Port
;	bsf		RCSTA, CREN				; Enable Receive
;	bcf		STATUS, RP0				; return to page 0 (just in case)
; old is commented above
; "new" is below
	bcf		TXSTA, SYNC
	banksel	RCSTA
	bsf		RCSTA, SPEN
	bsf		RCSTA, CREN
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
	banksel	PORTA
	bsf		PORTA, 0
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

	banksel	PORTA
	bcf		PORTA, 0
; The WRITE has successfully completed
	return

I2CWriteWord:
	banksel	PORTA
	bsf		PORTA, 0
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

	banksel	PORTA
	bcf		PORTA, 0
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
	
;	banksel	PORTA
;	bsf		PORTA, 0
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


SetupMCP:
	banksel	control_byte
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

;	goto	FailMain
	
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
;	Note number 0 - 97 (or whatever) will be in w
;   Address of the note is note number * 3
;	product will old the product
	banksel product
	movwf	multip
	clrf	product
	movlw	0x03
	movwf	tdata
	
	movf	multip, w
multiLoop:
	addwf	product, f
	decf	tdata, f
	btfss	STATUS, Z
	goto	multiLoop;
	movf	product, w
	movwf	offset

	movlw	0x04
	movwf	tdata
StringWriteLoop:
	movf	offset, w
	call	NoteLookup
	movwf	character
	decf	tdata, f
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


	end