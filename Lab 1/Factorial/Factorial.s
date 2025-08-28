	EXPORT Start
	AREA Factorial, CODE, READONLY
Start
		ENTRY
		MOV		R0, #5 			; n = 5
		STMFD	SP!, {R0}			; initial store into stack
		BL		Fac
		BL 		Program_End
		;		R0 = n
		;		R1 = n-1
		;		R3 = ans
Fac		STMFD	SP!, {R0-R1, LR}	; store state at top of function
		LDR		R0, [SP, #12] 		; retrive n without poping
		CMP		R0, #1 			; check if n <= 1
		MOVLE	R3, #1 			; ans = 1
		BLE		Done				; current recursion done
		;		if not, continue execution
		SUB		R1, R0, #1 		; R1 = n-1
		STMFD	SP!, {R1}			; store R1
		BL		Fac				; call Fac(n-1)
		LDMFD	SP!, {R1}			; remember to pop R1
		MUL		R3, R3, R0		; Fac(n) * Fac(n-1)
Done		
		LDMFD	SP!, {R0-R1, LR}	; restore previous state
		MOV		PC, LR			; resume next resursion

Program_End 
		END