;******************************************************************************
; Safwan Kamal
; MAY 2026
; Pong
;******************************************************************************
;-------------------------------------------------------------------------------
	.cdecls C,LIST,"msp430.h"       ; Include device header file
;-------------------------------------------------------------------------------
	.def    RESET                   ; Export program entry-point to
					; make it known to linker.

delay	.macro  count
	mov #count, R15
	dec R15
	jnz $-2
	.endm

RST_HIGH	.macro
	bis.b   #BIT4, &P9OUT
	.endm

RST_LOW	.macro
	bic.b   #BIT4, &P9OUT
	.endm

CS_HIGH	.macro
	bis.b   #BIT5, &P2OUT
	.endm

CS_LOW	.macro
	bic.b   #BIT5, &P2OUT
	.endm

send_data	.macro d0, d1, d2
	mov.b   d0, R15
	call    #tft_data_sr
	.if $symlen(":d1:") > 0
	mov.b   d1, R15
	call    #tft_data_sr
	.endif
	.if $symlen(":d2:") > 0
	mov.b   d2, R15
	call    #tft_data_sr
	.endif
	.endm


tft_config	.macro  address, d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12, d13, d14, d15
	mov.b   #address, R15
	call    #tft_cmd_sr
	.if $symlen(":d0:") > 0
	mov.b   d0, R15
	call    #tft_data_sr
	.endif
	.if $symlen(":d1:") > 0
	mov.b   d1, R15
	call    #tft_data_sr
	.endif
	.if $symlen(":d2:") > 0
	mov.b   d2, R15
	call    #tft_data_sr
	.endif
	.if $symlen(":d3:") > 0
	mov.b   d3, R15
	call    #tft_data_sr
	.endif
	.if $symlen(":d4:") > 0
	mov.b   d4, R15
	call    #tft_data_sr
	.endif
	.if $symlen(":d5:") > 0
	mov.b   d5, R15
	call    #tft_data_sr
	.endif
	.if $symlen(":d6:") > 0
	mov.b   d6, R15
	call    #tft_data_sr
	.endif
	.if $symlen(":d7:") > 0
	mov.b   d7, R15
	call    #tft_data_sr
	.endif
	.if $symlen(":d8:") > 0
	mov.b   d8, R15
	call    #tft_data_sr
	.endif
	.if $symlen(":d9:") > 0
	mov.b   d9, R15
	call    #tft_data_sr
	.endif
	.if $symlen(":d10:") > 0
	mov.b   d10, R15
	call    #tft_data_sr
	.endif
	.if $symlen(":d11:") > 0
	mov.b   d11, R15
	call    #tft_data_sr
	.endif
	.if $symlen(":d12:") > 0
	mov.b   d12, R15
	call    #tft_data_sr
	.endif
	.if $symlen(":d13:") > 0
	mov.b   d13, R15
	call    #tft_data_sr
	.endif
	.if $symlen(":d14:") > 0
	mov.b   d14, R15
	call    #tft_data_sr
	.endif
	.if $symlen(":d15:") > 0
	mov.b   d15, R15
	call    #tft_data_sr
	.endif
	.endm

;-------------------------------------------------------------------------------
	.global _main
	.global __STACK_END
	.sect   .stack                  ; Make stack linker segment ?known?

	.data

Timer0Period	.word   20000
Timer1Period	.word   7000

ScreenXMin	.word   2
ScreenXMax	.word   129
ScreenYMin	.word   1
ScreenYMax	.word   128

JoystickHigh	.word   3072
JoystickLow	.word   1024

PaddleXLeft	.word   20
PaddleXRight	.word   21
PaddleStartTop	.word   20
PaddleStartBottom	.word   51
PaddlePixelCount	.word   64

BallStartX	.word   100
BallStartY	.word   40
BallStartDirection	.word   0
BallSizeMinus1	.word   2
BallPixelCount	.word   9
BallStep	.word   1
BallStepNeg	.word   -1

BallNearPaddleX	.word   23
BallWallXMin	.word   3
PaddleTopMin	.word   2

	.text                           ; Assemble to Flash memory
	.retain                         ; Ensure current section gets linked
	.retainrefs

_main
RESET	mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT	mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT



EditClock:	

	mov.b   #CSKEY_H,&CSCTL0_H      ; Unlock CS registers
	mov.w   #DCOFSEL_6,&CSCTL1      ; Set DCO setting for 8MHz
	mov.w   #SELA__VLOCLK+SELS__DCOCLK+SELM__DCOCLK,&CSCTL2 ; set ACLK = VLO
	mov.w   #DIVA__1+DIVS__1+DIVM__1,&CSCTL3 ; MCLK = SMCLK = DCO = 8MHz
	clr.b   &CSCTL0_H               ; Lock CS registers


SetupTimerA0:
	mov.w   &Timer0Period, R15
	mov.w   R15, &TA0CCR0              
	mov.w   #CCIE, &TA0CCTL0            ; Enable CCR0 interrupt
	mov.w   #TASSEL__SMCLK+ID__8+MC__UP+TACLR, &TA0CTL
					; SMCLK, /8 divider, up mode, clear timer

SetupTimerA1:
	mov.w   &Timer1Period, R15
	mov.w   R15, &TA1CCR0
	mov.w   #0, &TA1CCTL0
	mov.w   #TAIDEX_7, &TA1EX0
	mov.w   #TASSEL__SMCLK+ID__8+MC__UP+TACLR, &TA1CTL

SetupGPIO: 

	bis.b   #BIT4+BIT6+BIT7, &P1SEL0     ; Configure Uart TX/RX
	bic.b   #BIT4+BIT6+BIT7, &P1SEL1


	bis.b   #BIT4, &P9OUT ; RESET PIN
	bic.b   #BIT4, &P9OUT

	bis.b   #BIT3+BIT5, &P2DIR
	
	mov.w   #UCSWRST, &UCB0CTLW0              ; Reset & lock the UART system
	bis.w   #UCSSEL__SMCLK+UCSYNC+UCMODE_0+UCMST+UCMSB, &UCB0CTLW0        ; Use SMCLK
	mov.w   #2, &UCB0BRW                      ; Setup freq division
	bic.w   #UCSWRST, &UCB0CTLW0              ; Exit reseet mode



SetupButtons:                              
	bic.b   #BIT2+BIT1, &P1DIR     ; P1.2 and P1.1 as inputs

	bis.b   #BIT2+BIT1, &P1REN     ; Enable pull resistors
	bis.b   #BIT2+BIT1, &P1OUT     ; Select pull-up mode
	bis.b   #BIT2+BIT1, &P1IES     ; Interrupt on high-to-low edge
					; Released -> pressed

	bic.b   #BIT2+BIT1, &P1IFG     ; Clear old interrupt flags
	bis.b   #BIT2+BIT1, &P1IE      ; Enable interrupts on P3.0/P3.1


UnlockGPIO	bic.w   #LOCKLPM5,&PM5CTL0      ; Disable the GPIO power-on default
					; high-impedance mode to activate
					; previously configured port settings


SetupADC12:
	mov.w   #ADC12SHT0_2+ADC12ON+ADC12MSC,&ADC12CTL0 ; 16x, Multiple sample mode
	bis.w   #ADC12SHP+ADC12CONSEQ_3,&ADC12CTL1    ; ADCCLK = MODOSC; sampling timer
	bis.w   #ADC12RES_2,&ADC12CTL2  ; 12-bit conversion results
	bis.w   #ADC12INCH_10,&ADC12MCTL0; A10 ADC input select; Vref=AVCC; Horizontal
	bis.w   #ADC12INCH_4,&ADC12MCTL1; A4 ADC input select; Vref=AVCC; Vertical


	;     sigh! sigh! this acd interrupt hurt me a lot. if using only one direction of the joystick
	;       just enable that direction interrupt. 
	bis.w   #ADC12IE1,&ADC12IER0 ; Enable ADC conv complete interrupt
	bis.w   #ADC12ENC+ADC12SC,&ADC12CTL0 ; Start sampling/conversion

	nop
	eint
	nop
	RST_LOW
	delay   1000
	RST_HIGH
	delay   60000
	delay   60000


Configuration:
; Reset the Device
	tft_config  0x11
	delay   60000
	delay   60000

; Configure the device
	tft_config  0xB1,#0x02,#0x35,#0x36
	tft_config  0xB2,#0x02,#0x35,#0x36
	tft_config  0xB3,#0x02,#0x35,#0x36,#0x02,#0x35,#0x36
	tft_config  0xB4,#0x07
	tft_config  0xC0,#0x02,#0x02
	tft_config  0xC1,#0xC5
	tft_config  0xC2,#0x0D,#0x00
	tft_config  0xC3,#0x8D,#0x1A
	tft_config  0xC4,#0x8D,#0xEE
	tft_config  0xC5,#0x51,#0x4D
	tft_config  0xE0,#0x0A,#0x1C,#0x0C,#0x14,#0x33,#0x2B,#0x24,#0x28,#0x27,#0x25,#0x2C,#0x39,#0x00,#0x05,#0x03,#0x0D
	tft_config  0xE1,#0x0A,#0x1C,#0x0C,#0x14,#0x33,#0x2B,#0x24,#0x28,#0x27,#0x25,#0x2C,#0x39,#0x00,#0x05,#0x03,#0x0D
	tft_config  0x3A,#0x06
	tft_config  0x29
	delay   1000
	tft_config  0x36,#0x40

	call #CanvasReset

Mainloop:

	jmp Mainloop
	nop

;------------------------------------------------------------------------------
;           Subroutines
;------------------------------------------------------------------------------

tft_cmd_sr:
	CS_LOW
	bic.b       #BIT3, &P2OUT
	call        #spi_byte
	CS_HIGH
	ret

tft_data_sr:
	CS_LOW
	bis.b       #BIT3, &P2OUT
	call        #spi_byte
	CS_HIGH
	ret

spi_byte: 
spiT1	bit.w       #UCTXIFG, &UCB0IFG
	jz          spiT1
	mov.b       R15, &UCB0TXBUF
spiT2	bit.w       #UCBUSY, &UCB0STATW
	jnz         spiT2
	ret


ColorFiller:
	ret
	
WhiteBakgroundSetter:
; Setup for writing to display
	tft_config  0x2A,#0x00,&ScreenXMin,#0x00,&ScreenXMax ; X cord to start at
	tft_config  0x2B,#0x00,&ScreenYMin,#0x00,&ScreenYMax ; Y cord to start at
	tft_config  0x2C ; BEGIN

	mov.w       #16384, R12
FillW	send_data   #0xFF, #0xFF, #0xFF ; BGR
	dec.w       R12
	jnz         FillW
	delay       50000
	ret



MovePaddle:

	;       Essentially, everytime we move, we just draw one row of black pixels in front of the the paddle
	;       and one row of white pixels at the back
	cmp.w   #1,R4
	jz      LoadR8White
LoadR8Black
	call    #LoadBlack
	jmp     TopPixelMove
LoadR8White
	call    #LoadWhite
TopPixelMove            
	tft_config  0x2A,#0x00,&PaddleXLeft,#0x00,&PaddleXRight
	tft_config  0x2B,#0x00,R8,#0x00,R8
	tft_config  0x2C

	; 2 * 1 = 2 pixels
	mov.w       #2, R12

TopMovePaddleLoop
	send_data   R10, R11, R13      ; black pixel, BGR
	dec.w       R12
	jnz         TopMovePaddleLoop



	cmp.w   #-1,R4
	jz      LoadR9White
LoadR9Black
	call    #LoadBlack
	jmp     BottomPixelMove
LoadR9White
	call    #LoadWhite
	
BottomPixelMove            
	tft_config  0x2A,#0x00,&PaddleXLeft,#0x00,&PaddleXRight
	tft_config  0x2B,#0x00,R9,#0x00,R9
	tft_config  0x2C

	mov.w       #2, R12

BottomMovePaddleLoop
	send_data   R10, R11, R13      ; black pixel, BGR
	dec.w       R12
	jnz         BottomMovePaddleLoop

	
	ret


DrawPaddle:

	;   Loading Blacks
	call        #LoadBlack

	tft_config  0x2A,#0x00,&PaddleXLeft,#0x00,&PaddleXRight
	tft_config  0x2B,#0x00,R8,#0x00,R9
	tft_config  0x2C

	; 4 * 4 = 16 pixels
	mov.w       &PaddlePixelCount, R12

DrawPaddleLoop
	send_data   R10, R11, R13      ; black pixel, BGR
	dec.w       R12
	jnz         DrawPaddleLoop
	ret


DrawBall:
	;       R6->X, R7->Y
	; call        #LoadBlack

	mov.w       R6,R5
	add.w       &BallSizeMinus1,R5
	tft_config  0x2A,#0x00,R6,#0x00,R5

	mov.w       R7,R5
	add.w       &BallSizeMinus1,R5
	tft_config  0x2B,#0x00,R7,#0x00,R5
	tft_config  0x2C

	; 4 * 4 = 16 pixels
	mov.w       &BallPixelCount, R12

DrawBallLoop:
	send_data   R10, R11, R13      ; black pixel, BGR
	dec.w       R12
	jnz         DrawBallLoop

	ret       

MoveBall:
	;   we will use R14 as the ball movement mode. 0->(Up,Up),1->(Up,Down),2->(Down,Up),3->(Down,Down)
	mov.w   R14,R5
	add.w   R5, R5               ; R14 = R14 * 2

	add.w   R5, PC                ; Jump into table below

	jmp     UpRight                    ; index 0
	jmp     UpLeft                  ; index 1
	jmp     DownRight                  ; index 2
	jmp     DownLeft                ; index 3

UpRight:
	call    #LoadWhite
	call    #DrawBall
	call    #LoadBlack
	add.w   &BallStep, R6
	add.w   &BallStep, R7
	call    #DrawBall
	jmp     MoveBallOver
UpLeft:
	call    #LoadWhite
	call    #DrawBall
	call    #LoadBlack
	add.w   &BallStepNeg, R6
	add.w   &BallStep, R7
	call    #DrawBall
	jmp     MoveBallOver
DownRight:
	call    #LoadWhite
	call    #DrawBall
	call    #LoadBlack
	add.w   &BallStep, R6
	add.w   &BallStepNeg, R7
	call    #DrawBall
	jmp     MoveBallOver
DownLeft:
	call    #LoadWhite
	call    #DrawBall
	call    #LoadBlack
	add.w   &BallStepNeg, R6
	add.w   &BallStepNeg, R7
	call    #DrawBall
	jmp     MoveBallOver
MoveBallOver:
	call    #LoadBlack
	ret             

;  The primary colors we use for this

LoadBlack:
	mov.w   #0x00, R10             ; B
	mov.w   #0x00, R11             ; G
	mov.w   #0x00, R13             ; R  
	ret
LoadWhite:
	mov.w   #0xFF, R10             ; B
	mov.w   #0xFF, R11             ; G
	mov.w   #0xFF, R13             ; R 
	ret


CanvasReset:
	; Setup for writing to display

	tft_config  0x2A,#0x00,&ScreenXMin,#0x00,&ScreenXMax ; X cord to start at
	tft_config  0x2B,#0x00,&ScreenYMin,#0x00,&ScreenYMax ; Y cord to start at
	tft_config  0x2C ; BEGIN

	call        #WhiteBakgroundSetter  
	
	mov.w       &PaddleStartTop, R8     ; row start
	mov.w       &PaddleStartBottom, R9     ; row end = row_start + 31 for now
	call        #DrawPaddle
			
	mov.w       &BallStartX, R6    ; Ball X
	mov.w       &BallStartY, R7     ; Ball Y
	mov.w       &BallStartDirection, R14     ; Ball Direction Mode. Starting with UpRight
	call        #DrawBall

	ret
	
;------------------------------------------------------------------------------
;           Interrupt Service Routines
;------------------------------------------------------------------------------

; This is for the JoyStick

ADC12_ISR:	add.w       &ADC12IV,PC             ; add offset to PC
	reti                            ; Vector  0:  No interrupt
	reti                            ; Vector  2:  ADC12MEMx Overflow
	reti                            ; Vector  4:  Conversion time overflow
	reti                            ; Vector  6:  ADC12HI
	reti                            ; Vector  8:  ADC12LO
	reti                            ; Vector 10:  ADC12IN
	reti                            ;     jmp         MEM0                    ; Vector 12:  ADC12MEM0 Interrupt
	jmp         MEM1                ; Vector 14:  ADC12MEM1
	reti                            ; Vector 16:  ADC12MEM2
	reti                            ; Vector 18:  ADC12MEM3
	reti                            ; Vector 20:  ADC12MEM4
	reti                            ; Vector 22:  ADC12MEM5
	reti                            ; Vector 24:  ADC12MEM6
	reti                            ; Vector 26:  ADC12MEM7
	reti                            ; Vector 28:  ADC12MEM8
	reti                            ; Vector 30:  ADC12MEM9
	reti                            ; Vector 32:  ADC12MEM10
	reti                            ; Vector 34:  ADC12MEM11
	reti                            ; Vector 36:  ADC12MEM12
	reti                            ; Vector 38:  ADC12MEM13
	reti                            ; Vector 40:  ADC12MEM14
	reti                            ; Vector 42:  ADC12MEM15
	reti                            ; Vector 44:  ADC12MEM16
	reti                            ; Vector 46:  ADC12MEM17
	reti                            ; Vector 48:  ADC12MEM18
	reti                            ; Vector 50:  ADC12MEM19
	reti                            ; Vector 52:  ADC12MEM20
	reti                            ; Vector 54:  ADC12MEM21
	reti                            ; Vector 56:  ADC12MEM22
	reti                            ; Vector 58:  ADC12MEM23
	reti                            ; Vector 60:  ADC12MEM24
	reti                            ; Vector 62:  ADC12MEM25
	reti                            ; Vector 64:  ADC12MEM26
	reti                            ; Vector 66:  ADC12MEM27
	reti                            ; Vector 68:  ADC12MEM28
	reti                            ; Vector 70:  ADC12MEM29
	reti                            ; Vector 72:  ADC12MEM30
	reti                            ; Vector 74:  ADC12MEM31
	reti                            ; Vector 76:  ADC12RDY

; For our pong game we do not need to use the left and right.
; So we can just use R8 and R9 for joystick
MEM1:        
	; call        #CheckBallBounds
	; bit.w       #CCIFG, &TA1CCTL0
	; jz          ExitADCISR

CheckUp     
	mov.w       &JoystickHigh, R5
	cmp.w       R5,&ADC12MEM1       ; ADCMEM > 3/4 Vcc
	jlo         CheckDown              ; No, check the other condition

	;     We have to be careful about moving the "eraser"
	;     The eraser should move only after the erasing is done i.e. the function call is done 
	;     Shifting the window up       
	mov.w       #1,R4                   ; Will use this as the direction register
	cmp.w       &ScreenYMax,R9
	jge         ExitADCISR
	add.w       R4,R8
	call        #MovePaddle
	add.w       R4,R9
	delay       50000
	; bic.w       #CCIFG, &TA1CCTL0
	call        #MoveBall
	call        #CheckBallBounds
	reti
CheckDown
	;      Shifting the window down
	mov.w       &JoystickLow, R5
	cmp.w       R5,&ADC12MEM1
	jge         ExitADCISR
	mov.w       #-1,R4                   ; Will use this as the direction register
	cmp.w       &PaddleTopMin,R8
	jlo         ExitADCISR
	add.w       R4,R9
	call        #MovePaddle
	add.w       R4,R8
	delay       50000
	; bic.w       #CCIFG, &TA1CCTL0
	call        #MoveBall
	call        #CheckBallBounds
	reti 

ExitADCISR
	reti


; This is for handling the button inputs

PORT1_ISR:
	add.w       &P1IV, PC              ; Use P1IV for Port 1 interrupts

	reti                            ; 0: no interrupt
	reti                            ; 2: P1.0 interrupt, not used here
	jmp         Left_Pressed_ISR          ; 4: P1.1 interrupt
	jmp         Right_Pressed_ISR          ; 6: P1.2 interrupt
	reti                            ; 8: P1.3
	reti                            ; 10: P1.4
	reti                            ; 12: P1.5
	reti                            ; 14: P1.6
	reti                            ; 16: P1.7

Left_Pressed_ISR:
	call        #CanvasReset
	reti


Right_Pressed_ISR:
	reti

	
TIMER0_A0_ISR:
	call        #MoveBall
	call        #CheckBallBounds
	reti



CheckBallBounds:

	; First compare if the left side hit is from the wall or the paddle
	cmp.w       &BallNearPaddleX,R6
	jlo         checkPaddleHit

	; Bound Comparisons      
	cmp.w       &ScreenYMax,R7
	jge         flipDown
	cmp.w       &BallWallXMin,R7
	jlo         flipUp
	cmp.w       &ScreenXMax,R6
	jge         flipLeft
	jmp         noBound

checkPaddleHit
	; If lower than 3, wall ball hit the left wall, and thus game over.
	cmp.w       &BallWallXMin,R6
	jlo         gameOver 
	; Checking if ball is within the paddle width
	cmp.w       &PaddleXLeft,R6
	jlo         noBound
	; Paddle Hit Potentially
	cmp.w       R9,R7
	jge         noBound
	cmp.w       R8,R7
	jlo         noBound
	; Paddle Hit
BallPaddleHit
	call        #LoadWhite
	call        #DrawBall
	add.w       &BallStep,R6
	call        #LoadBlack
	call        #DrawBall
	jmp         flipRight
	ret

flipDown
	; UpRight(0) + 2 -> DownRight, UpLeft(1) + 2 -> DownLeft
	add.w       #2,R14     
	ret
flipUp
	; DownRight(2) - 2 -> UpRight, DownLeft(3) - 2 -> UpLeft
	add.w       #-2,R14
	ret
flipLeft
	; UpRight(0) + 1 -> UpLeft, DownRight(2) + 1 -> DownLeft
	add.w       #1,R14
	ret

flipRight
	; UpLeft(1) - 1 -> UpRight, DownLeft(3) - 1 -> DownRight
	add.w       #-1,R14
	ret

gameOver
	call        #CanvasReset
	ret

noBound:
	ret

;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------
	.sect       ".reset"                ; MSP430 RESET Vector
	.short      RESET                   ;
	.sect       ADC12_VECTOR            ; ADC12 Vector
	.short      ADC12_ISR               ;
	.sect       TIMER0_A0_VECTOR
	.short      TIMER0_A0_ISR
	.sect       PORT1_VECTOR
	.short      PORT1_ISR
	.end