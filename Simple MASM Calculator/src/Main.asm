; EXTERNAL DEPENDENCIES
INCLUDE		I:/Downloads/IRVINE32/Irvine32.inc
INCLUDELIB	I:/Downloads/IRVINE32/Irvine32.lib

; EXECUTION MODE PARAMETERS
.386
.model flat, stdcall
.stack 4096

; PROTOTYPES
ExitProcess PROTO, dwExitCode:DWORD

ENDLINE							EQU		0Dh, 0Ah, 0	; I am NOT typing allat
NEWLINE							EQU		0Dh, 0Ah

; DATA SEGMENT
.data
introText			BYTE		'=====================', NEWLINE, '= SIMPLE CALCULATOR =', NEWLINE, '=====================', NEWLINE, ENDLINE
op1					BYTE		'Please enter your first operand: ', 0
op2					BYTE		'Please enter your second operand: ', 0
choiceText			BYTE		'Enter your choice:', NEWLINE, '1.) Addition', NEWLINE, '2.) Subtraction', NEWLINE, '3.) Multiplication', NEWLINE, ': ', 0
youChose			BYTE		'You chose', 0
addMsg				BYTE		'addition', ENDLINE
subMsg				BYTE		'subtraction', ENDLINE
mulMsg				BYTE		'multiplication', ENDLINE

topCalc				BYTE		' ,-----------------, ', ENDLINE
					BYTE		'|  _______________  |', ENDLINE
					BYTE		'| /               \ |', ENDLINE
					BYTE		'| \_______________/ |', ENDLINE
					BYTE		'|                   |', ENDLINE
					BYTE		'||[ + ] [ - ] [ * ]||', ENDLINE
					BYTE		'||[ 1 ] [ 2 ] [ 3 ]||', ENDLINE
					BYTE		'||[ 4 ] [ 5 ] [ 6 ]||', ENDLINE
					BYTE		'||[ 7 ] [ 8 ] [ 9 ]||', ENDLINE
					BYTE		'||[ C ] [ 0 ] [ E ]||', ENDLINE
					BYTE		'|       [ O ]       |', ENDLINE
					BYTE		'| | S.E.T.H. INC. | |', ENDLINE
					BYTE		"'-------------------'", ENDLINE

calcStr				BYTE		'               ', 0	; the string displayed in the calculator (15 characters);
cursorX				BYTE		0
errorText			BYTE		'ERROR          ', 0
overflowText		BYTE		'ERROR: OVERFLOW', 0

sampleNum			BYTE		'-1292+1616'

flags				BYTE		0
FLAG_NUM_NEGATIVE	EQU			0
FLAG_NUM_SIGNED		EQU			1

SLEEP_TIME			EQU			5						; 5 milis in between loops to prevent excessive resource hogging

operation			BYTE		0
numCharsWritten		BYTE		0
MAX_CHARS_WRITTEN	EQU			7
totalCharsWritten	BYTE		0

sizeOfCalcLine		EQU			24						; the length of one line of the calculator ASCII art (21 for the visible text, 3 for the ENDLINE) ;
numberCalcRows		EQU			13						; how many portions (lines) the calculator consists of ;
calcDrawX			EQU			3						; the x-coord where to display calcStr on the screen ;
calcDrawY			EQU			2						; the y-coord where to display calcStr on the screen ;

OPERATION_ADD		EQU			1
OPERATION_SUB		EQU			2
OPERATION_MUL		EQU			3



; ******************** MAIN PROCEDURE ******************** ;
.code
main PROC
	; DRAW THE CALCULATOR TO SCREEN ;
	mov edx, OFFSET topCalc
	mov ecx, numberCalcRows
	calcDraw:
		call WriteString
		add edx, sizeOfCalcLine
	loop calcDraw

	call clearCalcOutput	; initialize cursor x/y position

	; start up main loop ;
	main_loop:

		
		call ReadKey
		jz continue

		cmp al, 'O'		; IMPORTANT: IF THE USER PRESSES 'O', QUIT THE PROGRAM
		je quit

		call handleUserInput
		
		continue:
		mov eax, 5
		call Delay
	jmp main_loop

	quit:
	mov dl, 0		; return cursor to original position (so exit message doesn't break calcuator appearance)							'
	mov dh, 14
	call Gotoxy
	INVOKE ExitProcess, 0
main ENDP

; ******************** START PROCEDURE DEFINITIONS ******************** ;

;************************************************************
; Takes in a 6-digit decimal string (or 5-digit if the number contained does not start with a negative symbol), and converts it to a signed DWORD.
;************************************************************
;				( PARAMS )
;	EBX: string
;	ECX: number of characters in string
;************************************************************
;				( RETURNS )
;	EAX: signed number
strToInt PROC 
	push ecx
	push edx

	mov eax, 0

	mov dl, [ebx]	; check if the first character of the string is a minus sign. If so, set FLAG_NUM_NEGATIVE in flags to true, and increment ebx by one to ignore the minus sign.
	cmp dl, '-'	
	mov edx, 0		; set total to zero
	jne parse_loop	; if the first symbol is NOT a minus sign, do not do any of the above and just start parsing.

	negative:
	add ebx, 1		; shift string away from negative sign if the number is negative.
	mov dl, [flags]
	bts edx, 0		; bts only accepts 16+ bit registers fsr
	mov [flags], dl	; set flag at bit zero to true to indicate a negative number (at the end of the function, negate number)
	mov edx, 0

	;************************************************************
	; BEGIN PARSING NUMBER
	parse_loop:
		movzx ecx, BYTE PTR [ebx]		; load next char of ebx into ecx
		call IsClDigit				; Check if the character contained in cl is a digit (0-9). Sets ZF if it is.
		jnz stop_parsing			; if the character is not a digit, stop parsing.

		; MULTIPLY TOTAL BY 10
		push edx
		push ecx

			; MULTIPLY TOTAL BY 10
			mov ecx, 10
			mov eax, edx				; load current total into eax (for multiplication)
			mul ecx						; multiply eax by 10

			; EDIT STACK-SAVED EDX (SO TOTAL GOES THROUGH POPPING AND PUSHING)
			mov [esp + 4], eax			; ESP points to last pushed byte, so add 4 to get to eax (pushed 1 away)

		; return values to registers
		pop ecx
		pop edx

		; add new digit onto total
		sub ecx, '0'					; convert character in ecx to a decimal number
		add edx, ecx					; add that decimal number to total
		inc ebx							; go to the next character
	jmp parse_loop

	stop_parsing:
	movzx eax, BYTE PTR [flags]	; check if FLAG_NUM_NEGATIVE is true. If it is, negate result number.
	btr eax, FLAG_NUM_NEGATIVE	; sets CF to true if the bit was true, and resets the read bit
	mov [flags], al				; update flags variable in-memory
	jnc after					; if FLAG_NUM_NEGATIVE was false, skip negating the number.
	neg edx						; else, negate total.

	after:
	mov eax, edx				; load total into eax (return register)

	pop edx
	pop ecx
	ret

strToInt ENDP

refreshCalcOutput PROC
	push edx

	mov dl, calcDrawX
	mov dh, calcDrawY
	call Gotoxy

	mov edx, OFFSET calcStr
	call WriteString

	pop edx
	ret
refreshCalcOutput ENDP

; AL: CHARACTER
appendSymbolToCalcOutput PROC
	push ebx
	push edx

	mov edx, OFFSET calcStr
	movzx ebx, totalCharsWritten
	add edx, ebx
	mov [edx], al
	inc ebx
	mov [totalCharsWritten], bl

	pop edx
	pop ebx
	ret
appendSymbolToCalcOutput ENDP

errorCalc PROC
	push edx
	push eax

	mov dl, calcDrawX
	mov dh, calcDrawY
	call Gotoxy

	mov edx, OFFSET errorText
	call WriteString

	call ReadChar
	call clearCalcOutput
	pop eax
	pop edx
	ret
errorCalc ENDP

overflowCalc PROC
	push edx
	push eax

	mov dl, calcDrawX
	mov dh, calcDrawY
	call Gotoxy

	mov edx, OFFSET overflowText
	call WriteString

	call ReadChar
	call clearCalcOutput
	pop eax
	pop edx
	ret
overflowCalc ENDP

IsClDigit PROC
	push eax

	mov al, cl
	call IsDigit

	pop eax
	ret
IsClDigit ENDP

clearCalcOutput PROC
	push ecx
	push edx
	push ebx

	mov edx, 0
	mov [operation], dl
	mov [totalCharsWritten], dl
	mov [numCharsWritten], dl
	movzx edx, [flags]
	btr edx, FLAG_NUM_SIGNED

	mov ecx, 15
	mov dl, ' '
	mov ebx, 0
	clrLoop:
		mov [calcStr + ebx], dl
		inc ebx
	loop clrLoop
	call refreshCalcOutput

	mov dl, calcDrawX
	mov dh, calcDrawY
	call Gotoxy

	pop ebx
	pop edx
	pop ecx
	ret
clearCalcOutput	ENDP

clearCalcOutputNoReset PROC
	push ecx
	push edx
	push ebx

	mov ecx, 15
	mov dl, ' '
	mov ebx, 0
	clrLoop:
		mov [calcStr + ebx], dl
		inc ebx
	loop clrLoop
	call refreshCalcOutput

	mov dl, calcDrawX
	mov dh, calcDrawY
	call Gotoxy

	pop ebx
	pop edx
	pop ecx
	ret
clearCalcOutputNoReset	ENDP


;************************************************************
; Takes an ASCII code and performs an action based on what was pressed. If the key isn't recognized, ignore it.								'
;************************************************************
;						( PARAMS )
; AL: ASCII code
;************************************************************
handleUserInput PROC

	; if no number has been input for operator1, don't bother checking operation, just assume that the user pressed a number. Prevents user from saying NULL + 10.			'	
	mov ah, numCharsWritten
	test ah, ah
	jz check_numbers

	;************************************************************
	check_add:			; check if the key pressed was +. If it is, we need to check if another operator has already been pressed. If so, ERROR.
	cmp al, '+'
	jne check_sub		; if the key pressed was not +, check minus next.

	mov ah, operation	; check that there is no current operator pressed. If there is, ERROR
	test ah, ah
	jz plus_pressed		; if there was no operator already pressed, then activate code for plus being pressed.
	call errorCalc		; if there was an operator already pressed, ERROR
	ret

	;************************************************************
	check_sub:			; check if the key pressed was -. If it was, check if another operator has already been pressed. If another has already been pressed, ERROR.
	cmp al, '-'
	jne check_mul

	mov ah, operation
	test ah, ah
	jz minus_pressed
	call errorCalc
	ret

	;************************************************************
	check_mul:			; check if the key pressed was *. If it was, check if another operator has already been pressed. If another has already been pressed, ERROR.
	cmp al, '*'
	jne check_clear

	mov ah, operation
	test ah, ah
	jz asterisk_pressed
	call errorCalc
	ret

	;************************************************************
	check_clear:		; check if the key pressed was 'C'. If it was, clear the calculator output.
	cmp al, 'C'
	jne check_enter
	call clearCalcOutput
	ret

	;************************************************************
	check_enter:
	cmp al, 'E'		; check if the key pressed was 'E'. If it was, perform the operation and display the result.
	jne check_numbers
	call solveInput
	ret

	;************************************************************
	check_numbers:	; check if the key pressed was a digit. If it was, add that digit to the string.
	call IsDigit
	jz number_pressed
					; check if the key pressed was a minus sign that would make the number negative
	cmp al, '-'
	jne cont
	movzx edx, [flags]
	bts edx, FLAG_NUM_SIGNED
	jc cont
	call WriteChar
	call appendSymbolToCalcOutput
	movzx edx, numCharsWritten
	inc edx
	mov [numCharsWritten], dl

	cont:
	ret
handleUserInput ENDP

plus_pressed:
	call WriteChar
	call appendSymbolToCalcOutput

	mov al, OPERATION_ADD
	mov [operation], al
	
	mov al, 0
	mov [numCharsWritten], al

	ret

minus_pressed:
	call WriteChar
	call appendSymbolToCalcOutput

	mov al, OPERATION_SUB
	mov [operation], al
	
	mov al, 0
	mov [numCharsWritten], al

	ret

asterisk_pressed:
	call WriteChar
	call appendSymbolToCalcOutput

	mov al, OPERATION_MUL
	mov [operation], al
	
	mov al, 0
	mov [numCharsWritten], al

	ret

number_pressed:
	movzx edx, [flags]
	bts edx, FLAG_NUM_SIGNED; SET FLAG_NUM_SIGNED flag to true.

	mov dl, [numCharsWritten]
	cmp dl, MAX_CHARS_WRITTEN
	
	
	jl inc_number			; if the user has written too many characters, do not do anything. Otherwise, increment numCharsWritten and echo the character on the screen.
	ret						

	inc_number:
	call WriteChar
	call appendSymbolToCalcOutput
	inc dl
	mov [numCharsWritten], dl
	ret

;****************************************************************************************;
;********** IMPORTANT: THIS IS WHERE THE ACTUAL MATH OPERATIONS ARE PERFORMED ********** ;
;****************************************************************************************;
solveInput:
	;************************************************************************************************************************************************************************************
	; Solve the equation in the calculator screen. strToInt reads until a non-digit value appears (and leaves EBX at the character that stopped the parse),
	; so we call it once to get the first value in binary (and store it in ECX), increment EBX by one (to get past the singular operator character), and store
	; the second number in EAX.

	mov ebx, OFFSET calcStr
	call strToInt			; read the first (signed) integer available in calcStr (which is what is displayed on the calculator screen)
	mov ecx, eax			; save this integer into ecx

	inc ebx					; there is an operator symbol (+ or - or *). Skip past this to parse the number behind it.
	call strToInt			; read next integer, save it into eax (default return register)

	call clearCalcOutputNoReset	; reset calculator screen without damaging important RAM variables
	
	; DO THE OPERATION ON THE TWO NUMBERS
	movzx edx, [operation]
	cmp edx, OPERATION_ADD	; check what the OPERATION_CODE is (saved in memory when the operator was input)
	je add_nums				; if it is OPERATION_ADD, jump to add_nums

	cmp edx, OPERATION_SUB
	je sub_nums				; if it is OPERATION_SUB, jump to sub_nums
	jmp mul_nums			; otherwise, it must be OPERATION_MUL, so jump to mul_nums

	; add_nums:
	; add EAX and ECX, and display the result to the calculator screen.
	;**********************************************************************
	add_nums:
	add eax, ecx

	call clearCalcOutputNoReset
	call WriteInt
	ret

	; sub_nums:
	; subtract EAX and ECX, and display the result to the calculator screen.
	;**********************************************************************
	sub_nums:
	sub ecx, eax
	mov eax, ecx	; swap values (since operator 1 is ECX, we need to subtract EAX from ECX, but WriteInt takes EAX as its parameter, meaning we need to treat EAX as operator 1)
	
	call clearCalcOutputNoReset
	call WriteInt
	ret

	; mul_nums:
	; adds EAX to itself ECX times, and displays the result to the calculator screen.
	;***********************************************************************************
	mul_nums:
	mov edx, 0
	test ecx, ecx	; if ecx is zero, automatically return 0
	jz no_loop

	mov ebx, 0		; use BTX to keep track of a temporary flag (RESULT_NEG)

	cmp ecx, 0
	jle ecx_neg
	jmp ecx_pos
	
	ecx_neg:
	bts ebx, 0		; if ECX is negative, set the RESULT_NEG flag.
	neg ecx			; do not wanna loop a negative amount of times - ECX needs to always be positive.


	ecx_pos:
	cmp eax, 0		; my fake mul operation uses add, and uses the overflow flag to detect if there was an overflow. 
	jle	eax_neg		; To prevent false overflows (-5 + -5 in binary is technically an overflow), ensure both values are positive.
	jmp mul_loop	; To keep track of the sign of the result, a flag in EBX is set to 1 for a negative result, and 0 for a positive result.

	eax_neg:
	btc ebx, 0		; toggle RESULT_NEG flag - if RESULT_NEG was already true, set it to false (neg * neg = positive), otherwise set it to true (positive * neg = neg)
	neg eax			; make EAX positive if it was negative

	; MULTIPLYING LOGIC
	mul_loop:
		add edx, eax
		jo overflow	;if there was an overflow, display ERROR: OVERFLOW on calculator
	loop mul_loop

	no_loop:
	mov eax, edx

	btc ebx, 0		; if RESULT_NEG flag is true, negate result number.
	jnc no_neg
	neg eax

	; if RESULT_NEG is false, just output the number
	no_neg:
	call clearCalcOutputNoReset
	call WriteInt
	ret

	overflow:
	call overflowCalc
	ret

END main