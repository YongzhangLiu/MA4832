GPIO_PORTF_DATA_R  EQU 0x400253FC
GPIO_PORTF_DIR_R   EQU 0x40025400
GPIO_PORTF_AFSEL_R EQU 0x40025420
GPIO_PORTF_PUR_R   EQU 0x40025510
GPIO_PORTF_DEN_R   EQU 0x4002551C
GPIO_PORTF_AMSEL_R EQU 0x40025528
GPIO_PORTF_PCTL_R  EQU 0x4002552C
GPIO_PORTF_LOCK_R  EQU 0x40025520
GPIO_PORTF_CR_R    EQU 0x40025524
PF0                EQU 0x40025004	; 	SW2 - negative logic
PF1                EQU 0x40025008	;	RED LED
PF2                EQU 0x40025010	; 	BLUE LED - ORIG
PF3                EQU 0x40025020	;	GREEN LED
PF4                EQU 0x40025040	;	SW1 - ORIG -negative logic
PFA		   EQU 0x40025038	; 	3 colours : 0011 1000
SYSCTL_RCGCGPIO_R  EQU 0x400FE608	

        AREA    |.text|, CODE, READONLY, ALIGN=2
        THUMB
        EXPORT  Start

Start

; initialize PF 1-3 output, PF4 an input, 
; enable digital I/O, ensure alt. functions off.
; Input: none, Output: none, Modifies: R0, R1

	; activate clock for Port F
    LDR R1, =SYSCTL_RCGCGPIO_R      
    LDR R0, [R1]                 
    ORR R0, R0, #0x20               ; set bit 5 to turn on clock
    STR R0, [R1]                  
    NOP								; allow time for clock to finish
      
	
    ; Unlock SW2 at PF0
	LDR R1, =GPIO_PORTF_LOCK_R
	LDR R0, =0x4C4F434B ; password
	STR R0, [R1] ;Unlock GPIOCR
	LDR R1, =GPIO_PORTF_CR_R
	LDR R0, [R1]
	ORR R0, #0x01 ; Unlock PF pin 0
	  
    
	;set direction register
    LDR R1, =GPIO_PORTF_DIR_R       
    LDR R0, [R1]                    
    ORR R0, R0, #0x0E               	; PF 1,2,3 output 
    BIC R0, R0, #0x11               	; Make PF4 & PF0 built-in button input
    STR R0, [R1]    
	
	; regular port function
    LDR R1, =GPIO_PORTF_AFSEL_R     
    LDR R0, [R1]                     
    BIC R0, R0, #0x1E               ; 0 means disable alternate function
    STR R0, [R1] 
	
	; pull-up resistors on switch pins
    LDR R1, =GPIO_PORTF_PUR_R       ; R1 = &GPIO_PORTF_PUR_R
    LDR R0, [R1]                    ; R0 = [R1]
    ORR R0, R0, #0x11               ; R0 = R0|0x10 (enable pull-up on PF4)
    STR R0, [R1]                    ; [R1] = R0

	; enable digital port
    LDR R1, =GPIO_PORTF_DEN_R       ; 7) enable Port F digital port
    LDR R0, [R1]                    
    ORR R0,#0x0E                    ; 1 means enable digital I/O
    ORR R0, R0, #0x11               ; R0 = R0|0x10 (enable digital I/O on PF4)
    STR R0, [R1]    
    	
    LDR R4, =PF4                    ; R4 = &PF4
	
	MOV R12, #0 ; init counter
	
loop                                ; in this loop, the appliance (PF2) toggles when the switch is released
	CMP R12, #0
	LDRGE R1, =PF1
	CMP R12, #1
	LDRGE R1, =PF2
	CMP R12, #2
	LDRGE R1, =PF3
	CMP R12, #3
	LDRGE R1, =PFA
	
    BL  SSR_On
waitforpress1                       ; proceed only when the button is pressed
    LDR R0, [R4]                    ; R0 = [R4] (read status of PF4)
    TST R0, #0x1 << 4                   ; R0 == 0x10?
    BEQ waitforpress1               ; if so, spin
waitforrelease1                     ; proceed only when the button is released
	MOV R5, #0xFF0
	BL Delay
	
	LDR R0, [R4]                    ; R0 = [R4] (read status of PF4)
    TST R0, #0x1 << 4                  ; R0 != 0x10?
    BNE waitforrelease1             ; if so, spin
    BL  SSR_Off
waitforpress2                       ; proceed only when the button is pressed
    LDR R0, [R4]                    ; R0 = [R4] (read status of PF4)
    TST R0, #0x1 << 4                   ; R0 == 0x10?
    BEQ waitforpress2               ; if so, spin
waitforrelease2                     ; proceed only when the button is released
    LDR R0, [R4]                    ; R0 = [R4] (read status of PF4)
    TST R0, #0x1 << 4                   ; R0 != 0x10?
    BNE waitforrelease2             ; if so, spin
    B   loop

;------------SSR_On------------
; Make PF2 high.
; Input: none
; Output: none
; Modifies: R0, R1
SSR_On
    MOV R0, #0x0E                   ; R0 = 0x04 (turn on the appliance) 1110
    STR R0, [R1]                    ; [R1] = R0, write to PF2
    BX  LR                          ; return
;------------SSR_Off------------
; Make PF2 low.
; Input: none
; Output: none
; Modifies: R0, R1
SSR_Off
    MOV R0, #0x00                   ; R0 = 0x00 (turn off the appliance)
    STR R0, [R1]                    ; [R1] = R0, write to PF2
	
	ADD R12, #1 ; increment
	CMP R12, #3 ; reset if >3
	MOVGT R12, #0
	
    BX  LR                          ; return
    
SSR_Toggle
    LDR R0, [R1]                    ; previous value
    EOR R0, R0, #0x0E               ; flip bit 2: 0x04 1: 0x02
    STR R0, [R1]                    ; affect just PF2
    BX  LR
Delay
	SUBS R5, #1
	BGT Delay
	BX LR

    ALIGN                           ; make sure the end of this section is aligned
    END                             ; end of file
