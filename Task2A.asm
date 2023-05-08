.DEF DL1 = R24		; define register for delay1
.DEF DL2 = R25		; define register for delay2
.EQU MIN = 0x01F4	; min value of duty cycle = 0.5ms (500 microseconds)
.EQU MAX = 0x09C4	; max value of duty cycle = 2.5ms (2500 microseconds)
.EQU STEP = 0x64	; step by 0.1ms (100 microseconds)

LDI R16, 0XFF
STS DDRD, R16		; port D is output (255)

LDI R16, HIGH(MIN)
STS OCR1AH, R16		; store high byte 
LDI R17, LOW(MIN)
STS OCR1AL, R17		; store low byte

; WGM10 = 0, WGM11 = WGM12 = WGM13 = 1  -> Fast PWM where TOP = ICR1
; COM1A1 = 1, COM1A0 = 0 -> non-inverted mode
; CS10 = 1, CS11 = CS12 = 0 -> no prescaling
; COM1A0, CS11 and CS12 already 0 so we don't set them

LDI R16, (1<<WGM11) | (1<<COM1A1)
STS TCCR1A, R16
LDI R17, (1<<WGM13) | (1<<WGM12) | (1<<CS10)
STS TCCR1B, R17

CBI DDRB, 0		; PINΒ0 will be used to increase duty cycle
CBI DDRB, 1		; PINΒ1 will be used to decrease duty cycle

main:			; loop between scan0 and scan1 till switch is pressed
				; and if so, go to move delay and then loop again
	scan0:
		SBIS PINB, 0 		; skip rjmp if PINB0 = 1 (if switch is pressed)
		RJMP scan1			; PC jump to check if PINB1 of switch is pressed
		LDI R16, OCR1AH		; R16 contains high byte of OCR1A
		LDI R17, OCR1AL		; R17 contains low byte of OCR1A
		CPI R16, HIGH(MAX)	; compare high bytes (OCR1AH and HIGH(MAX))
		CPI R17, LOW(MAX)	; compare low bytes (OCR1AL and LOW(MAX))
		BREQ scan1			; if we have max duty cycle, branch to scan1
		LDI R18, STEP		; load 0x64 to R18
		ADD R16, R18		; R16 += 0x64
		LDI R18, 0X00		; R18 = 0X00
		ADD R17, R18		; R17 += 0X00
		STS OCR1AH, R17		; store R17 to high byte of OCR1A
		STS OCR1AL, R16		; store R16 to low byte of OCR1A
		RJMP move			; jump to move the servo
		
	scan1:
		SBIS PINB, 1 		; skip rjmp if PINB1 = 1 (if switch is pressed)
		RJMP scan0			; PC jump to check if PINB0 of switch is pressed
		LDI R16, OCR1AH
		LDI R17, OCR1AL
		CPI R16, HIGH(MIN)	; compare high bytes (OCR1AH and HIGH(MIN))
		CPI R17, LOW(MIN)	; compare low bytes (OCR1AL and LOW(MIN))
		BREQ scan0			; if we have min duty cycle, branch to scan0
		LDI R18, STEP		; load 0x64 to R18
		SUB R16, R18		; R16 -= 0X64
		LDI R18, 0X00		; R18 = 0X00
		SUB R17, R18		; R17 -= 0X00
		STS OCR1AH, R17		; store R17 to high byte of OCR1A
		STS OCR1AL, R16		; store R16 to low byte of OCR1A
		RJMP move			; jump to move the servo
		
	move:					; time delay in order to move the servo
		LDI DL1, 100		; total delay time = DL1*DL2 = 100*1ms = 100ms
		delay1:
			LDI DL2, 250	; DL2 = 250(hex) = 1(decimal) so DL2 = 1ms
		delay2:				; 
			NOP				; 1 clock cycle wait
			DEC DL2			; 1 clock cycle (DL2 = DL2 - 1)
			BRNE delay2		; 2 clock cycles if true, 1 cycle if false
							; repeat until counter DL2 = 0
			DEC DL1			; 1 clock cycle (DL1 = DL1 - 1)
			BRNE delay1		; 2 clock cycles if true, 1 cycle if false
							; repeat until counter DL1 = 0
	RJMP main		; jump back to beginning of main
