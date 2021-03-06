$MOD186
$EP
NAME TIMER

; =========================================================================
; Main Timer Driver Program
; Author: Vaghul Aditya Balaji

; This file contains proprietary information and cannot be copied 
; or distributed without prior permission from the author.
; =========================================================================

public	serial_rec_action, timer2_action
extrn	print_char:far, print_2hex:far, iodefine:far
extrn   set_timer2:far, disable_timer2:far


;IO Setup for 80C188 
	UMCR    	 		EQU    0FFA0H ; Upper Memory Control Register
	LMCR   		 		EQU    0FFA2H ; Lower Memory control Register         
	PCSBA        		EQU    0FFA4H ; Peripheral Chip Select Base Address
	MPCS         		EQU    0FFA8H ; MMCS and PCS Alter Control Register
	INT0CON      		EQU    0FF38H
	EOI          		EQU    0FF22H
	IMASK        		EQU    0FF28H	
	PORTA        		EQU    0080H
	PORTB        		EQU    0081H
	PORTC        		EQU    0082H
	CWR          		EQU    0083H
	TIMER2_LEN	 		EQU    80
	LINE1_LIMIT  		EQU    100
	LINE2_LIMIT  		EQU    50
	LCD_DISPLAY_LIMIT   EQU    16
	ROLL_LIMIT   		EQU    10

	
STACK_SEG	SEGMENT
	DB	256 DUP(?)
	TOS	LABEL	WORD
STACK_SEG	ENDS


DATA_SEG	SEGMENT
	TIMER2_MESS	  DB  10,13,'TIMER2 INTERRUPT    '
	T_COUNT		  DB  2FH
	T_COUNT_SET	  DB  2FH
	REC_MESS	  DB  10,13,'Period of timer =     '
	
	;LCD Variables
	DISP_LINE1    DB  25 DUP(' ')
				  DB  25 DUP(' ')
				  DB  25 DUP(' ')
				  DB  25 DUP(' ')
	DISP_LINE2    DB  25 DUP(' ')
				  DB  25 DUP(' ')
	LINE1_COUNT   DB  00H
	LINE2_COUNT   DB  00H
	TIMER2_COUNT  DW  0000H
	ROLL_COUNT    DB  00H
	
	;Serial Variables
	RECEIVE_FLAG  DB  00H
	LINE2_FLAG    DB  00H
	LCD_ID        DB  'L3002]'
	LCD_START     DB  00H
	LCD_FLAG	  DB  00H
	START_READ    DB  00H
DATA_SEG	ENDS


CODE_SEG	SEGMENT

	PUBLIC		START

ASSUME	CS:CODE_SEG, SS:STACK_SEG, DS:DATA_SEG

START:
;initialize stack area
	MOV	AX,STACK_SEG		
	MOV	SS,AX
	MOV	SP,TOS
	
	MOV AX, DATA_SEG
	MOV DS, AX

; Initialize the on-chip peripherals
	CALL FAR PTR IODEFINE
		
; Initialize MPCS to MAP peripheral to IO address	
	MOV DX, MPCS
	MOV AX, 0083H
	OUT DX, AX

; PCSBA initial, set the parallel port start from 00H
	MOV DX, PCSBA
	MOV AX, 0003H ; Peripheral starting address 00H no READY, No Waits
	OUT DX, AX

; Initialize LMCS 
    MOV DX, LMCR
    MOV AX, 01C4H  ; Starting address 1FFFH, 8K, No waits, last should be 5H for 1 waits      
    OUT DX, AX

; ######################### Start of User Main Routine ###########################
	
    STI
	
	MOV DX, CWR
	MOV AX, 80H
	OUT DX, AL
	
NEXT:
	JMP NEXT
	
; ######################### End of User Main Routine #############################


;Procedure for initializing the LCD system and setting it up for display
LCD_INITIALIZE PROC FAR
	PUSH AX
	PUSH CX
	PUSH DX

; ****Time Delay of 60ms****	
	XOR CX, CX
	MOV CX, 30000	

DELAY_60ms:
	LOOP DELAY_60ms
	
	XOR CX, CX

; *****Function Set****
	XOR AX, AX
	MOV DX, PORTC
	MOV AL, 08H
	OUT DX, AL

	XOR AX, AX
	MOV DX, PORTB
	MOV AL, 3CH
	OUT DX, AL

	XOR AX, AX
	MOV DX, PORTC
	MOV AL, 00H
	OUT DX, AL
; **********************

; ****Time Delay of 5ms****	
	XOR CX, CX
	MOV CX, 2500

DELAY_5ms:
	LOOP DELAY_5ms
	
	XOR CX, CX	

; *****Function Set****
	XOR AX, AX
	MOV DX, PORTC
	MOV AL, 08H
	OUT DX, AL

	XOR AX, AX
	MOV DX, PORTB
	MOV AL, 3CH
	OUT DX, AL

	XOR AX, AX
	MOV DX, PORTC
	MOV AL, 00H
	OUT DX, AL
; **********************

; ****Time Delay of 100us****	
	XOR CX, CX
	MOV CX, 50

DELAY_100us:
	LOOP DELAY_100us
	
	XOR CX, CX

; *****Function Set****
	XOR AX, AX
	MOV DX, PORTC
	MOV AL, 08H
	OUT DX, AL

	XOR AX, AX
	MOV DX, PORTB
	MOV AL, 3CH
	OUT DX, AL

	XOR AX, AX
	MOV DX, PORTC
	MOV AL, 00H
	OUT DX, AL
; **********************

; *****Function Set****
	XOR AX, AX
	MOV DX, PORTC
	MOV AL, 08H
	OUT DX, AL

	XOR AX, AX
	MOV DX, PORTB
	MOV AL, 3CH
	OUT DX, AL

	XOR AX, AX
	MOV DX, PORTC
	MOV AL, 00H
	OUT DX, AL
; **********************

	CALL LCD_POLL

; *****Switching off Display****
	XOR AX, AX
	MOV DX, PORTC
	MOV AL, 08H
	OUT DX, AL

	XOR AX, AX
	MOV DX, PORTB
	MOV AL, 08H
	OUT DX, AL

	XOR AX, AX
	MOV DX, PORTC
	MOV AL, 00H
	OUT DX, AL
; **********************

	CALL LCD_POLL

; *****Clear the LCD****
	XOR AX, AX
	MOV DX, PORTC
	MOV AL, 08H
	OUT DX, AL

	XOR AX, AX
	MOV DX, PORTB
	MOV AL, 01H
	OUT DX, AL

	XOR AX, AX
	MOV DX, PORTC
	MOV AL, 00H
	OUT DX, AL
; **********************

	CALL LCD_POLL

; *****Enable Entry Mode****
	XOR AX, AX
	MOV DX, PORTC
	MOV AL, 08H
	OUT DX, AL

	XOR AX, AX
	MOV DX, PORTB
	MOV AL, 06H
	OUT DX, AL

	XOR AX, AX
	MOV DX, PORTC
	MOV AL, 00H
	OUT DX, AL
; **********************

	CALL LCD_POLL

LCD_INIT_END:
	POP DX
	POP CX
	POP AX
	RET
LCD_INITIALIZE ENDP


;Procedure for displaying characters on the LCD
LCD_DISPLAY PROC FAR
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX

; *****Set First Line****
	XOR AX, AX
	MOV DX, PORTC
	MOV AL, 08H
	OUT DX, AL

	XOR AX, AX
	MOV DX, PORTB
	MOV AL, 80H
	OUT DX, AL

	XOR AX, AX
	MOV DX, PORTC
	MOV AL, 00H
	OUT DX, AL
; **********************

	CALL LCD_POLL

; *****Switching on Display****
	XOR AX, AX
	MOV DX, PORTC
	MOV AL, 08H
	OUT DX, AL

	XOR AX, AX
	MOV DX, PORTB
	MOV AL, 0CH
	OUT DX, AL

	XOR AX, AX
	MOV DX, PORTC
	MOV AL, 00H
	OUT DX, AL
; **********************

	CALL LCD_POLL

	XOR BX, BX
	XOR CX, CX
	MOV CL, DS:LINE1_COUNT	
	CMP CL, LCD_DISPLAY_LIMIT
	JLE LINE1_LOOP
	MOV CL, LCD_DISPLAY_LIMIT

; **********To display Characters in first line************
LINE1_LOOP:
	XOR AX, AX
	MOV DX, PORTC
	MOV AL, 0AH
	OUT DX, AL

	XOR AX, AX
	MOV DX, PORTB
	MOV AL, DS:DISP_LINE1[BX]
	OUT DX, AL

	XOR AX, AX
	MOV DX, PORTC
	MOV AL, 02H
	OUT DX, AL

	CALL LCD_POLL
	
	INC BX
	LOOP LINE1_LOOP
; **********************************************************

; *****Set Second Line****
	XOR AX, AX
	MOV DX, PORTC
	MOV AL, 08H
	OUT DX, AL

	XOR AX, AX
	MOV DX, PORTB
	MOV AL, 0C0H
	OUT DX, AL

	XOR AX, AX
	MOV DX, PORTC
	MOV AL, 00H
	OUT DX, AL
; **********************

	CALL LCD_POLL

	XOR CX, CX
	XOR BX, BX
	MOV CL, DS:LINE2_COUNT
	CMP CL, LCD_DISPLAY_LIMIT
	JLE LINE2_LOOP
	MOV CL, LCD_DISPLAY_LIMIT

; **********To display Characters in second line************
LINE2_LOOP:
	XOR AX, AX
	MOV DX, PORTC
	MOV AL, 0AH
	OUT DX, AL

	XOR AX, AX
	MOV DX, PORTB
	MOV AL, DS:DISP_LINE2[BX]
	OUT DX, AL

	XOR AX, AX
	MOV DX, PORTC
	MOV AL, 02H
	OUT DX, AL

	CALL LCD_POLL
	
	INC BX
	LOOP LINE2_LOOP
; **********************************************************

LCD_DISP_END:
	POP DX
	POP CX
	POP BX
	POP AX
	RET
LCD_DISPLAY ENDP


;Procedure for checking the busy flag on the LCD to make sure it is ready to receive input
LCD_POLL PROC NEAR
	PUSH AX
	PUSH DX

	MOV DX, CWR
	MOV AL, 82H
	OUT DX, AL

BUSY_POLL:	
	MOV AL, 0CH
	MOV DX, PORTC
	OUT DX, AL
		
	MOV DX, PORTB
	IN AL, DX		
	AND AL, 80H		
	MOV AH, AL

	MOV AL, 04H
	MOV DX, PORTC
	OUT DX, AL	
	
	CMP AH, 00H	
	JNZ BUSY_POLL
	
	MOV DX, CWR
	MOV AL, 80H
	OUT DX, AL

LCD_POLL_END:	
	POP DX
	POP AX
	RET
LCD_POLL ENDP


;Procedure that is called when a character is received via serial
SERIAL_REC_ACTION PROC FAR
	PUSH CX
	PUSH BX
	PUSH AX

	CMP LCD_START, 01H
	JE LCD_RECEIVE_START
	
	CMP START_READ, 01H
	JE START_READING_ID_VALUES
	
	CMP AL, '['
	JE START_READING_ID
	JMP TERMINATE_COMMUNICATION
	
START_READING_ID:
	INC LCD_FLAG
	MOV START_READ, 01H
	JMP TERMINATE_COMMUNICATION
	
START_READING_ID_VALUES:
	XOR BX, BX
	MOV BL, LCD_FLAG
	DEC BX	
	CMP AL, LCD_ID[BX]
	JNE TERMINATE_COMMUNICATION
	CMP LCD_FLAG, 06H
	JNE NORMAL_ID_CHECK
	MOV LCD_START, 01H
	MOV AL, '*'
	CALL FAR PTR PRINT_CHAR
	MOV AL, '1'
	CALL FAR PTR PRINT_CHAR
	MOV AL, '*'
	CALL FAR PTR PRINT_CHAR
	JMP TERMINATE_COMMUNICATION
	
NORMAL_ID_CHECK:
	INC LCD_FLAG
	JMP END_SERIAL_COMMUNICATION

INITIALIZE_TERMINATE_SERIAL:
	MOV LCD_START, 00H
	MOV LCD_FLAG, 00H
	MOV START_READ, 00H
	
TERMINATE_COMMUNICATION:
	JMP SERIAL_END
	
LCD_RECEIVE_START:
	CMP LINE2_FLAG, 01H
	JE RECEIVE_LINE2	
	
	CMP AL, '>'
	JE SWITCH_TO_LINE2	
	
	CMP RECEIVE_FLAG, 01H
	JE RECEIVE_CHARACTER
	
	CMP	AL,'<'
	JE SET_RECEIVE_FLAG
	
	JMP SERIAL_END
	
RECEIVE_LINE2:		
	CMP AL, '}'
	JE FIRST_JUMP_DISPLAY_LCD
	
	CMP RECEIVE_FLAG, 01H
	JE FIRST_JUMP_RECEIVE_CHAR_LINE2
	
	CMP	AL,'{'
	JE FIRST_JUMP_RECEIVE_FLAG_LINE2		
	
	JMP SERIAL_END
	
RECEIVE_CHARACTER:
	CMP LINE1_COUNT, LINE1_LIMIT
	JE END_SERIAL_COMMUNICATION
	XOR BX, BX
	MOV BL, LINE1_COUNT
	MOV DISP_LINE1[BX], AL
	INC LINE1_COUNT
	JMP SERIAL_END
	
FIRST_JUMP_DISPLAY_LCD:
	JMP DISPLAY_ON_LCD
	
FIRST_JUMP_RECEIVE_FLAG_LINE2:
	JMP SET_RECEIVE_FLAG_LINE2
	
FIRST_JUMP_RECEIVE_CHAR_LINE2:
	JMP RECEIVE_CHARACTER_LINE2
	
SET_RECEIVE_FLAG:
	MOV LINE1_COUNT, 00H
	MOV RECEIVE_FLAG, 01H
	CALL FAR PTR DISABLE_TIMER2
	JMP SERIAL_END
	
SWITCH_TO_LINE2:
	CMP LINE1_COUNT, LCD_DISPLAY_LIMIT
	JLE NORMAL_DISPLAY_LCD_LINE1
	XOR BX, BX
	MOV BL, LINE1_COUNT
	MOV DISP_LINE1[BX], ' '
	INC LINE1_COUNT
	MOV BL, LINE1_COUNT
	MOV DISP_LINE1[BX], '-'
	INC LINE1_COUNT
	MOV BL, LINE1_COUNT
	MOV DISP_LINE1[BX], '-'
	INC LINE1_COUNT
	MOV BL, LINE1_COUNT
	MOV DISP_LINE1[BX], ' '
	INC LINE1_COUNT

NORMAL_DISPLAY_LCD_LINE1:
	CMP RECEIVE_FLAG, 00H
	JE END_SERIAL_COMMUNICATION
	CMP LINE1_COUNT, 00H
	JE RECEIVE_CHARACTER		
	MOV RECEIVE_FLAG, 00H
	MOV LINE2_FLAG, 01H
	
END_SERIAL_COMMUNICATION:
	JMP SERIAL_END	
	
RECEIVE_CHARACTER_LINE2:
	CMP LINE2_COUNT, LINE2_LIMIT
	JE END_SERIAL_COMMUNICATION
	XOR BX, BX
	MOV BL, LINE2_COUNT
	MOV DISP_LINE2[BX], AL
	INC LINE2_COUNT
	JMP SERIAL_END
	
SET_RECEIVE_FLAG_LINE2:
	MOV LINE2_COUNT, 00H
	MOV RECEIVE_FLAG, 01H
	JMP SERIAL_END
	
DISPLAY_ON_LCD:
	CMP LINE2_COUNT, LCD_DISPLAY_LIMIT
	JLE NORMAL_DISPLAY_LCD_LINE2
	XOR BX, BX
	MOV BL, LINE2_COUNT
	MOV DISP_LINE2[BX], ' '
	INC LINE2_COUNT
	MOV BL, LINE2_COUNT
	MOV DISP_LINE2[BX], ' '
	INC LINE2_COUNT
	MOV BL, LINE2_COUNT
	MOV DISP_LINE2[BX], ' '
	INC LINE2_COUNT
	
NORMAL_DISPLAY_LCD_LINE2:
	CMP RECEIVE_FLAG, 00H
	JE SERIAL_END
	CMP LINE2_COUNT, 00H
	JE RECEIVE_CHARACTER_LINE2	
	MOV RECEIVE_FLAG, 00H
	MOV LINE2_FLAG, 00H	
	MOV LCD_START, 00H
	MOV LCD_FLAG, 00H
	MOV START_READ, 00H
	MOV ROLL_COUNT, 00H
	MOV TIMER2_COUNT, 0000H
	CALL FAR PTR LCD_INITIALIZE
	CALL FAR PTR LCD_DISPLAY
	CALL FAR PTR SET_TIMER2
	
SERIAL_END:
	POP AX
	POP	BX
	POP	CX
	RET
SERIAL_REC_ACTION ENDP


;Main Timer2 Procedure
TIMER2_ACTION PROC FAR
	PUSH AX
	PUSH BX
	PUSH CX
		
	INC TIMER2_COUNT
	CMP TIMER2_COUNT, TIMER2_LEN
	JNE TIMER2_END		
	MOV TIMER2_COUNT, 0000H	
	INC ROLL_COUNT
	CMP ROLL_COUNT, ROLL_LIMIT
	JL TIMER2_END
	MOV ROLL_COUNT, LCD_DISPLAY_LIMIT
	
	CMP LINE1_COUNT, LCD_DISPLAY_LIMIT
	JLE LINE2_SCROLL

	XOR BX, BX
	MOV AH, DISP_LINE1[0]
	MOV CL, LINE1_COUNT
	DEC CL

SWITCH_ARRAY_ELEMENTS_LINE1:
	MOV AL, DISP_LINE1[BX+1]
	MOV DISP_LINE1[BX], AL
	INC BX
	LOOP SWITCH_ARRAY_ELEMENTS_LINE1
	XOR BX, BX
	MOV BL, LINE1_COUNT
	MOV DISP_LINE1[BX-1], AH		
	CALL FAR PTR LCD_DISPLAY	
	
LINE2_SCROLL:
	CMP LINE2_COUNT, LCD_DISPLAY_LIMIT
	JLE TIMER2_END
	
	XOR BX, BX
	MOV AH, DISP_LINE2[0]
	MOV CL, LINE2_COUNT
	DEC CL

SWITCH_ARRAY_ELEMENTS_LINE2:
	MOV AL, DISP_LINE2[BX+1]
	MOV DISP_LINE2[BX], AL
	INC BX
	LOOP SWITCH_ARRAY_ELEMENTS_LINE2
	XOR BX, BX
	MOV BL, LINE2_COUNT
	MOV DISP_LINE2[BX-1], AH		
	CALL FAR PTR LCD_DISPLAY

TIMER2_END:
	POP CX
	POP BX
	POP AX
	RET
TIMER2_ACTION ENDP


CODE_SEG	ENDS
END