	EXPORT Begin
	AREA factorial, CODE, READONLY
	
Begin

	; R1: n, R12: ans
	MOV SP, #0xFF000000 ;init FD stack
	MOVS R0, #10 ;load n
	BL Fac
	END
	
	
Fac
	STMFD SP!, {R1-R3, LR} 	;transparent subroutine stuff
	LDR R1, [SP, #16] 		;read value of n
	;initial check
	CMP R1, #1 				;compare if LE 1
	MOVLS R12, #1 			;ans = 1
	BLS Done				;finish if n LE 1
	
	SUB R2, R1, #1			;subtract 1
	
	
	LDMFD SP!, {R1-R3, LR} ;transparent subroutine stuff
Done
	
	