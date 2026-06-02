;******************************************************************************
; Safwan Kamal
; MAY 2026
; Pong
;******************************************************************************

;------------------------------------------------------------------------------
; Register usage notes
;------------------------------------------------------------------------------
; R4  = paddle movement direction.
;       #1 = one direction, #-1 = opposite direction.
;
; R5  = temporary scratch register.
;       Used for ball draw end coordinate and jump-table offset in MoveBall. (Can use)
;
; R6  = ball X coordinate.
; R7  = ball Y coordinate.
;
; R8  = paddle top Y coordinate.
; R9  = paddle bottom Y coordinate.
;
; // Potentially can use these 3 in other places
; R10 = blue color byte for TFT pixel writes.
; R11 = green color byte for TFT pixel writes.
; R13 = red color byte for TFT pixel writes.
;
; R12 = loop counter.
;       Used by fill loops, paddle draw loops, ball draw loops, and buzzer note loops.
;
; R14 = ball direction state.
;       0 = UpRight, 1 = UpLeft, 2 = DownRight, 3 = DownLeft.
;
; R15 = general subroutine/macro argument register.
;       Used by delay, send_data, tft_config, tft_cmd_sr, tft_data_sr, and spi_byte. (Can Use)
;------------------------------------------------------------------------------

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

	.sect 	".const"

Timer0Period	.word   20000
Timer1Period	.word   511

ScreenXMin	.word   2
ScreenXMax	.word   129
ScreenYMin	.word   1
ScreenYMax	.word   128

FlipOffset1	.word 1
FlipOffsetNeg1 .word -1
FlipOffset2	.word 2
FlipOffsetNeg2 .word -2

JoystickHigh	.word   3072
JoystickLow	.word   1024

PaddleXLeft	.word   20
PaddleXRight	.word   21
PaddleStartTop	.word   20
PaddleStartBottom	.word   51
PaddlePixelCount	.word   64

BallStartX	.word   70
BallStartY	.word   60
BallStartDirection	.word   0
BallSizeMinus1	.word   2
BallPixelCount	.word   9
; BallStep	.word   1
; BallStepNeg	.word   -1

BallNearPaddleX	.word   23
BallWallXMin	.word   3
PaddleTopMin	.word   2
PaddleHitFlag	.word	1
PaddleNotHitFlag .word  0

; Game State Variables
	.bss 	GameState, 2
	.bss	ScoreDigit1, 2
	.bss	ScoreDigit2, 2
	.bss	ScoreDigit3, 2
	.bss	ScoreDigit4, 2
	.bss	ScoreDigit5, 2
	.bss	ScoreDigit6, 2
	.bss 	CurrentDigit, 2

	.bss 	BallStep, 2
	.bss	BallStepNeg, 2

	
; LED CONSTS
; High Segments
SEGA        .set    1000000000000000b
SEGB        .set    0100000000000000b
SEGC        .set    0010000000000000b
SEGD        .set    0001000000000000b
SEGE        .set    0000100000000000b
SEGF        .set    0000010000000000b
SEGG        .set    0000001000000000b
SEGM        .set    0000000100000000b
; Low Segments (MSB padded)
SEGH        .set    0000000010000000b
SEGJ        .set    0000000001000000b
SEGK        .set    0000000000100000b
SEGP        .set    0000000000010000b
SEGQ        .set    0000000000001000b
SEGN        .set    0000000000000010b
SEGDP       .set    0000000000000001b

	.text                           ; Assemble to Flash memory
	.retain                         ; Ensure current section gets linked
	.retainrefs

_main
RESET	mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT	mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT

;------------------------------------------------------------------------------
;           Hard reset / clean startup state
;------------------------------------------------------------------------------
HardResetState:
	nop
	dint                                ; Disable global interrupts immediately
	nop
	
	; Clear general-purpose registers used by the game.
	; Do NOT clear R0, R1, R2, or R3.
	; R0 = PC, R1 = SP, R2 = SR/constant generator, R3 = constant generator.
	clr.w   R4
	clr.w   R5
	clr.w   R6
	clr.w   R7
	clr.w   R8
	clr.w   R9
	clr.w   R10
	clr.w   R11
	clr.w   R12
	clr.w   R13
	clr.w   R14
	clr.w   R15

	; Stop and clear Timer0_A
	mov.w   #TACLR, &TA0CTL
	mov.w   #0, &TA0CCTL0
	mov.w   #0, &TA0CCR0

	; Stop and clear Timer1_A
	mov.w   #TACLR, &TA1CTL
	mov.w   #0, &TA1CCTL0
	mov.w   #0, &TA1CCR0
	mov.w   #0, &TA1EX0

	; Reset ADC state
	bic.w   #ADC12ENC, &ADC12CTL0
	mov.w   #0, &ADC12IER0
	mov.w   #0, &ADC12IFGR0
	mov.w   #0, &ADC12CTL0
	mov.w   #0, &ADC12CTL1
	mov.w   #0, &ADC12CTL2
	mov.w   #0, &ADC12MCTL0
	mov.w   #0, &ADC12MCTL1

	; Reset eUSCI_B0 / SPI state
	mov.w   #UCSWRST, &UCB0CTLW0
	mov.w   #0, &UCB0BRW
	mov.w   #0, &UCB0IE
	mov.w   #0, &UCB0IFG

	; Clear Port 1 interrupt setup/flags before reconfiguring buttons/SPI pins
	mov.b   #0, &P1IE
	mov.b   #0, &P1IFG
	mov.b   #0, &P1SEL0
	mov.b   #0, &P1SEL1

	; Clear Port 2 interrupt flags and set TFT control pins safe
	mov.b   #0, &P2IE
	mov.b   #0, &P2IFG
	mov.b   #0, &P2SEL0
	mov.b   #0, &P2SEL1
	bis.b   #BIT3+BIT5+BIT7, &P2DIR          ; D/C and CS as outputs
	bis.b   #BIT5, &P2OUT               ; CS high/inactive
	bic.b   #BIT3, &P2OUT               ; D/C low default

	; Clear Port 9 state for TFT reset pin
	mov.b   #0, &P9SEL0
	mov.b   #0, &P9SEL1
	bis.b   #BIT4, &P9DIR               ; TFT reset as output
	bis.b   #BIT4, &P9OUT               ; Reset pin high/inactive


	; Game Variables
	mov.w	#0, &GameState
	mov.w	#0, &ScoreDigit1
	mov.w 	#0, &ScoreDigit2
	mov.w 	#0, &ScoreDigit3
	mov.w 	#0, &ScoreDigit4
	mov.w 	#0, &ScoreDigit5
	mov.w 	#0, &ScoreDigit6
	mov.w 	#1, &BallStep
	mov.w 	#-1, &BallStepNeg

	; Clear any lingering GPIO lock state later in normal setup,
	; but keep this here too so output settings can actually take effect.
	bic.w   #LOCKLPM5, &PM5CTL0

	; Give BoosterPack/TFT power a moment to settle after cold plug-in
	delay   60000
	delay   60000
	delay   60000


LCD_SETUP:

	mov.w   #1111111111000000b, &LCDCPCTL0 ; Enable specific segments
	mov.w   #1111000000111111b, &LCDCPCTL1 ; (only the 6 digits)
	mov.w   #0000000011110000b, &LCDCPCTL2 ;


	bis.w   #LCDPRE__16+LCD4MUX, &LCDCCTL0 ; ACLK/16/2=1024Hz
	bis.w   #LCDCLRM, &LCDCMEMCTL          ; Clear LCD memory
	bis.w   #LCDON, &LCDCCTL0              ; Turn the LCD ON


EditClock:	

	mov.b   #CSKEY_H,&CSCTL0_H      ; Unlock CS registers
	mov.w   #DCOFSEL_6,&CSCTL1      ; Set DCO setting for 8MHz
	mov.w   #SELS__DCOCLK+SELM__DCOCLK,&CSCTL2 ; set ACLK = 32kHz (By Default)
	mov.w   #DIVA__1+DIVS__1+DIVM__1,&CSCTL3 ; MCLK = SMCLK = DCO = 8MHz
	clr.b   &CSCTL0_H               ; Lock CS registers


SetupTimerA0:
; 	One memory opperand each operation
	mov.w   &Timer0Period, R15
	mov.w   R15, &TA0CCR0              
	mov.w   #CCIE, &TA0CCTL0            ; Enable CCR0 interrupt
	mov.w   #TASSEL__SMCLK+ID__8+MC__UP+TACLR, &TA0CTL
					; SMCLK, /8 divider, up mode, clear timer

SetupTimerA1:
	mov.w   &Timer1Period, R15
	mov.w   R15, &TA1CCR0
	mov.w   #CCIE, &TA1CCTL0			; Enabling CCIE for TA1
	mov.w   #TAIDEX_7, &TA1EX0
	mov.w   #TASSEL__ACLK+ID__8+MC__UP+TACLR, &TA1CTL

SetupGPIO: 


	bis.b   #BIT4+BIT6+BIT7, &P1SEL0     ; Configure Uart TX/RX
	bic.b   #BIT4+BIT6+BIT7, &P1SEL1

	bis.b   #BIT4, &P9DIR        		; TFT RESET pin as output
	bis.b   #BIT4, &P9OUT 				; RESET PIN
	bic.b   #BIT4, &P9OUT

	; Bit7 is for buzzer
	bis.b   #BIT3+BIT5+BIT7, &P2DIR
	
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
			delay	60000
			delay	60000
			delay	60000
			delay 	60000
			delay 	60000


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

	nop
	eint
	nop

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
	cmp.w   &BallStep,R4
	jeq     LoadR8White
LoadR8Black
	call    #LoadBlack
	jmp     TopPixelMove
LoadR8White
	call    #LoadWhite
TopPixelMove            
	tft_config  0x2A,#0x00,&PaddleXLeft,#0x00,&PaddleXRight

	; extra bit of logic to accomodate different paddle speeds
	; for speed = 1 -> need to draw only 1 pixel-width paddle left to right pixel layer
	; but for other speeds, need to draw multiple layers
	mov.w		R8,R12
	add.w		&BallStep,R12
	add.w		#-1,R12
	tft_config  0x2B,#0x00,R8,#0x00,R12
	tft_config  0x2C

	; 2 * ballstep (paddlespeed too for now) pixels being drawn
	mov.w       &BallStep,R12
	add.w		&BallStep,R12

TopMovePaddleLoop
	send_data   R10, R11, R13      ; black pixel, BGR
	dec.w       R12
	jnz         TopMovePaddleLoop



	cmp.w   &BallStepNeg,R4
	jeq     LoadR9White
LoadR9Black
	call    #LoadBlack
	jmp     BottomPixelMove
LoadR9White
	call    #LoadWhite
	
BottomPixelMove            
	tft_config  0x2A,#0x00,&PaddleXLeft,#0x00,&PaddleXRight
	mov.w		R9,R12
	add.w		&BallStep,R12
	add.w		#-1,R12
	tft_config  0x2B,#0x00,R9,#0x00,R12
	tft_config  0x2C

	mov.w       &BallStep,R12
	add.w		&BallStep,R12

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

PaddleTune:
	call		#PlayLowNote
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
	call    #LoadRed
	add.w   &BallStep, R6
	add.w   &BallStep, R7
	call    #DrawBall
	jmp     MoveBallOver
UpLeft:
	call    #LoadWhite
	call    #DrawBall
	call    #LoadRed
	add.w   &BallStepNeg, R6
	add.w   &BallStep, R7
	call    #DrawBall
	jmp     MoveBallOver
DownRight:
	call    #LoadWhite
	call    #DrawBall
	call    #LoadRed
	add.w   &BallStep, R6
	add.w   &BallStepNeg, R7
	call    #DrawBall
	jmp     MoveBallOver
DownLeft:
	call    #LoadWhite
	call    #DrawBall
	call    #LoadRed
	add.w   &BallStepNeg, R6
	add.w   &BallStepNeg, R7
	call    #DrawBall
	jmp     MoveBallOver
MoveBallOver:
	call    #LoadRed
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
LoadRed:
	mov.w   #0x00, R10             ; B
	mov.w   #0x00, R11             ; G
	mov.w   #0xFF, R13             ; R 
	ret


; Buzzer note helpers
; Buzzer is j4.0 on the expansion board, which is conencted to pin2.7 on the main board
; Sending PWM signals really


PlayVeryLowNote:
	mov.w   #200, R12

veryLowLoop
	bis.b   #BIT7, &P2OUT
	delay   2000
	bic.b   #BIT7, &P2OUT
	delay   2000

	dec.w   R12
	jnz     veryLowLoop

	ret

PlayLowNote:
	mov.w   #200, R12

lowLoop
	bis.b   #BIT7, &P2OUT
	delay   900
	bic.b   #BIT7, &P2OUT
	delay   900

	dec.w   R12
	jnz     lowLoop

	ret


PlayMidNote:
	mov.w   #250, R12

midLoop
	bis.b   #BIT7, &P2OUT
	delay   600
	bic.b   #BIT7, &P2OUT
	delay   600

	dec.w   R12
	jnz     midLoop

	ret


PlayHighNote:
	mov.w   #300, R12

highLoop
	bis.b   #BIT7, &P2OUT
	delay   350
	bic.b   #BIT7, &P2OUT
	delay   350

	dec.w   R12
	jnz     highLoop

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
	call		#LoadRed
	call        #DrawBall

	mov.w  		#-1,&ScoreDigit1
	mov.w  		#0,&ScoreDigit2
	mov.w  		#0,&ScoreDigit3
	mov.w  		#0,&ScoreDigit4
	mov.w  		#0,&ScoreDigit5
	mov.w  		#0,&ScoreDigit6 
	mov.w 		#1, &BallStep
	mov.w 		#-1, &BallStepNeg

gameStart
	bit.b		#BIT2,&P1IN
	jnz			gameStart
	mov.w 		#1,&GameState

	bis.w   	#LCDCLRM, &LCDCMEMCTL          ; Clear LCD memory

	ret

CheckBallBounds:

	; First compare if the left side hit is from the wall or the paddle
	cmp.w       &BallNearPaddleX,R6
	jlo         checkPaddleHit

	; Bound Comparisons      
	cmp.w       &ScreenYMax,R7
	jge         flipDown
	cmp.w       &ScreenYMin,R7
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
	call		#PaddleTune
	call        #LoadWhite
	call        #DrawBall
	; Offeseting the ball to the right after the paddle hit, so that there is not 
	; weird multi-collision scenario
	jmp         paddleHitFlipRight

flipDown
	; UpRight(0) + 2 -> DownRight, UpLeft(1) + 2 -> DownLeft
	mov.w		&ScreenYMax,R7
	add.w 		&FlipOffsetNeg2,R7
	add.w       #2,R14     
	jmp			CheckBallBounds
flipUp
	; DownRight(2) - 2 -> UpRight, DownLeft(3) - 2 -> UpLeft
	call        #LoadWhite
	call        #DrawBall
	; Weird edge case solve
	mov.w 		&ScreenYMin,R7
	add.W		&FlipOffset2,R7
	call        #LoadRed
	call        #DrawBall
	add.w       #-2,R14
	jmp			CheckBallBounds
flipLeft
	; UpRight(0) + 1 -> UpLeft, DownRight(2) + 1 -> DownLeft
	mov.w		&ScreenXMax,R6
	add.w		&FlipOffsetNeg2,R6
	add.w       #1,R14
	jmp 		CheckBallBounds

flipRight
	; UpLeft(1) - 1 -> UpRight, DownLeft(3) - 1 -> DownRight
paddleNotHit
	mov.w 		&ScreenXMin,R6
	add.w		&FlipOffset2,R6
	add.w       #-1,R14

	jmp			CheckBallBounds
paddleHitFlipRight
	mov.w 		&BallNearPaddleX,R6
	add.w		&FlipOffset2,R6
	call        #LoadRed
	call        #DrawBall
	add.w       #-1,R14
	; call		#DrawPaddle
	jmp 		CheckBallBounds

gameOver
	call		#GameOverTune
	call        #CanvasReset
	jmp			noBound
	

noBound
	ret


GameOverTune:
	call		#PlayMidNote
	delay		10000
	call		#PlayLowNote
	delay		10000
	call		#PlayVeryLowNote
	delay		10000
	call		#PlayVeryLowNote
	delay		10000
	ret

LCDWrite:

            ; cmp.w   #1, R15         ; Check what char to display
            ; jlo     LCDWriteEnd     ; Leave if displaying nothing
			add.w 	R5,R5
			add.w 	#54,R5
            mov.w   CHAR(R5), R5  ; Load our pattern to display
            add.w   &CurrentDigit, PC         ; Jump in the jump table!
; Jump Table (like a switch statement), completely breaks if R14 > 5!
            jmp     LCDDig6         ; A1
            jmp     LCDDig5         ; A2
            jmp     LCDDig4         ; A3
            jmp     LCDDig3         ; A4
            jmp     LCDDig2         ; A5
            jmp     LCDDig1         ; A6
LCDDig1     mov.b   R5, &LCDM11
            swpb    R5
            mov.b   R5, &LCDM10
            jmp		LCDWriteEnd
LCDDig2     mov.b   R5, &LCDM7
            swpb    R5
            mov.b   R5, &LCDM6
            jmp		LCDWriteEnd
LCDDig3     mov.b   R5, &LCDM5
            swpb    R5
            mov.b   R5, &LCDM4
            jmp		LCDWriteEnd
LCDDig4     mov.b   R5, &LCDM20
            swpb    R5
            mov.b   R5, &LCDM19
            jmp		LCDWriteEnd
LCDDig5     mov.b   R5, &LCDM16
            swpb    R5
            mov.b   R5, &LCDM15
            jmp		LCDWriteEnd
LCDDig6     mov.b   R5, &LCDM9
            swpb    R5
            mov.b   R5, &LCDM8
			
LCDWriteEnd	
			ret

;------------------------------------------------------------------------------
;           Look Up Tables
;------------------------------------------------------------------------------
	

CHAR:       .word   SEGA+SEGB+SEGC+SEGE+SEGF+SEGG+SEGM ; A
            .word   SEGA+SEGD+SEGE+SEGF+SEGG+SEGK+SEGN ; B
            .word   SEGA+SEGD+SEGE+SEGF ; C
            .word   SEGA+SEGB+SEGC+SEGD+SEGE+SEGF ; D
            .word   SEGA+SEGD+SEGE+SEGF+SEGG+SEGM ; E
            .word   SEGA+SEGE+SEGF+SEGG+SEGM ; F
            .word   SEGA+SEGC+SEGD+SEGE+SEGF+SEGM ; G
            .word   SEGB+SEGC+SEGE+SEGF+SEGG+SEGM ; H
            .word   SEGA+SEGD+SEGJ+SEGP ; I
            .word   SEGA+SEGB+SEGC+SEGD+SEGE ; J
            .word   SEGE+SEGF+SEGG+SEGK+SEGN ; K
            .word   SEGD+SEGE+SEGF ; L
            .word   SEGB+SEGC+SEGE+SEGF+SEGH+SEGK ; M
            .word   SEGB+SEGC+SEGE+SEGF+SEGH+SEGN ; N
            .word   SEGA+SEGB+SEGC+SEGD+SEGE+SEGF+SEGH+SEGK+SEGQ+SEGN ; O
            .word   SEGA+SEGB+SEGE+SEGF+SEGG+SEGM ; P
            .word   SEGA+SEGB+SEGC+SEGD+SEGE+SEGF+SEGN ; Q
            .word   SEGA+SEGB+SEGE+SEGF+SEGG+SEGM+SEGN ; R
            .word   SEGA+SEGC+SEGD+SEGF+SEGG+SEGM ; S
            .word   SEGA+SEGJ+SEGP ; T
            .word   SEGB+SEGC+SEGD+SEGE+SEGF ; U
            .word   SEGE+SEGF+SEGQ+SEGK ; V
            .word   SEGB+SEGC+SEGE+SEGF+SEGQ+SEGN ; W
            .word   SEGH+SEGK+SEGQ+SEGN ; X
            .word   SEGH+SEGK+SEGP ; Y
            .word   SEGA+SEGD+SEGK+SEGQ ; Z
SPACE:      .word   0       ; Space
DIGIT:      .word   SEGA+SEGB+SEGC+SEGD+SEGE+SEGF ; 0
            .word   SEGB+SEGC   ; 1
            .word   SEGA+SEGB+SEGD+SEGE+SEGG+SEGM ; 2
            .word   SEGA+SEGB+SEGC+SEGD+SEGG+SEGM   ;3
            .word   SEGB+SEGC+SEGF+SEGG+SEGM    ; 4
            .word   SEGA+SEGC+SEGD+SEGF+SEGG+SEGM   ; 5
            .word   SEGA+SEGC+SEGD+SEGE+SEGF+SEGG+SEGM ; 6
            .word   SEGA+SEGB+SEGC  ; 7
            .word   SEGA+SEGD+SEGH+SEGK+SEGQ+SEGN ; 8
            .word   SEGA+SEGB+SEGC+SEGD+SEGF+SEGG+SEGM ; 9

;------------------------------------------------------------------------------
;           Interrupt Service Routines
;------------------------------------------------------------------------------

; This is for the JoyStick

ADC12_ISR:	
	cmp.w 		#0, &GameState
	jeq			ExitADCISR
	add.w       &ADC12IV,PC             ; add offset to PC
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
	cmp.w       &JoystickHigh,&ADC12MEM1       ; ADCMEM > 3/4 Vcc
	jlo         CheckDown              ; No, check the other condition

	;     We have to be careful about moving the "eraser"
	;     The eraser should move only after the erasing is done i.e. the function call is done 
	;     Shifting the window up       
	mov.w       &BallStep,R4                   ; Will use this as the direction register
	cmp.w       &ScreenYMax,R9
	; Will have to change this for different paddle speeds
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
	cmp.w       &JoystickLow,&ADC12MEM1
	jge         ExitADCISR
	mov.w       &BallStepNeg,R4                   ; Will use this as the direction register
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
	cmp.w 		#0, &GameState
	jeq			ExitPort1ISR
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

Left_Pressed_ISR
	mov.w 		#0, &GameState
	call        #CanvasReset
	reti


Right_Pressed_ISR
	jmp			ExitPort1ISR

ExitPort1ISR
	reti

	

	
TIMER0_A0_ISR:
BallMoveCheck:
	call        #MoveBall
	call        #CheckBallBounds
	reti

ExitTimer0A0ISR
	reti




Timer1_A0_ISR:
ScoreUpdater:
Digit1
	cmp.w 	#9,&ScoreDigit1
	jeq		Digit2
	add.w	#1,&ScoreDigit1
	
	mov.w	&ScoreDigit1,R5
	mov.w	#0,&CurrentDigit
	call	#LCDWrite
	reti
Digit2
	mov.w	#0,&ScoreDigit1
	mov.w	#2,&BallStep
	mov.w	#-2,&BallStepNeg
	cmp.w 	#9,&ScoreDigit2
	jeq		Digit3
	add.w	#1,&ScoreDigit2
	
	mov.w	&ScoreDigit1,R5
	mov.w	#0,&CurrentDigit
	call	#LCDWrite
	mov.w	&ScoreDigit2,R5
	mov.w	#2,&CurrentDigit
	call	#LCDWrite
	reti
Digit3
	mov.w	#0,&ScoreDigit2
	cmp.w 	#9,&ScoreDigit3
	jeq		Digit4
	add.w	#1,&ScoreDigit3
	
	mov.w	&ScoreDigit1,R5
	mov.w	#0,&CurrentDigit
	call	#LCDWrite
	mov.w	&ScoreDigit2,R5
	mov.w	#2,&CurrentDigit
	call	#LCDWrite
	mov.w	&ScoreDigit3,R5
	mov.w	#4,&CurrentDigit
	call	#LCDWrite

Digit4
	reti




;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------
	.sect       ".reset"                ; MSP430 RESET Vector
	.short      RESET                   ;
	.sect       ADC12_VECTOR            ; ADC12 Vector
	.short      ADC12_ISR               ;
	.sect       TIMER0_A0_VECTOR
	.short      TIMER0_A0_ISR
	.sect       TIMER1_A0_VECTOR
	.short      Timer1_A0_ISR
	.sect       PORT1_VECTOR
	.short      PORT1_ISR
	.end