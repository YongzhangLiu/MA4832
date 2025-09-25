.section .bss 
	pointer1: .space 4
.data
	var1: .int 0x123456
	.align 2
	var2: .byte 0x42
	.align 1
	var3: .short 0x1234
	.align 1
.section .text
.global Start
.type Start, %function

Start: 
	ENTRY:
	LDR R0, =pointer1
	
	LDR R0, [R0]
	LDR R1, =var1
	LDR R1, [R1]
	LDR R2, =var2
	LDR R2, [R2]
	LDR R3, =var3
	LDR R3, [R3]
	NOP

stop:	
	B	stop			@stop program
	SWI 0
