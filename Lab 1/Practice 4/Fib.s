	EXPORT Start
	AREA test, CODE, READONLY

Start
	ENTRY
	MOV R0, #9
	STMFD SP!, {R0}
	BL Fib
; R4: n	
; R5: n-1 or n-2
; R6: temp
; R12: Result
Fib 
	STMFD SP!, {R4-R6, LR}
	LDR R4, [SP, #16]
	CMP R4, #1
	MOVEQ R12, #0
	CMP R4, #2
	MOVEQ R12, #1
	BLE Done
	SUB R5, R4, #1
	STMFD SP!, {R5}
	BL Fib
	LDMFD SP!, {R5}
	MOV R6, R12
	SUB R5, R4, #2
	STMFD SP!, {R5}
	BL Fib
	LDMFD SP!, {R5}
	ADD R12, R12, R6
Done
	LDMFD SP!, {R4-R6, LR}
	BX LR
	END