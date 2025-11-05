; 1. PE4 ADC sampling using SS3
; 2. PF 1-3 LED control based on ADC value
; 3. PA 4-7 dip switch 1-4 input
; 4. PD 0-1 external LEDs PD0 red, PD1 green
; 5. PF4 built-in button input (initialized, not used)



; GPIO PE
GPIO_PORTE_AFSEL_R 	EQU 0x40024420
GPIO_PORTE_DEN_R   	EQU 0x4002451C
GPIO_PORTE_AMSEL_R 	EQU 0x40024528
; GPIO PF
GPIO_PORTF_DATA_R  	EQU 0x400253FC 		; all pins, 3FC = 00 11_1111_11 00
GPIO_PORTF_DIR_R   	EQU 0x40025400
GPIO_PORTF_AFSEL_R 	EQU 0x40025420
GPIO_PORTF_PUR_R   	EQU 0x40025510
GPIO_PORTF_DEN_R   	EQU 0x4002551C
GPIO_PORTF_AMSEL_R 	EQU 0x40025528
GPIO_PORTF_PCTL_R  	EQU 0x4002552C
; GPIO PA
GPIO_PORTA_DATA_R  	EQU 0x400043FC
GPIO_PORTA_DIR_R   	EQU 0x40004400
GPIO_PORTA_AFSEL_R 	EQU 0x40004420
GPIO_PORTA_PUR_R   	EQU 0x40004510
GPIO_PORTA_DEN_R   	EQU 0x4000451C
GPIO_PORTA_AMSEL_R 	EQU 0x40004528
GPIO_PORTA_PCTL_R  	EQU 0x4000452C
PA_4567				EQU 0x400043C0		; PortA bit 4-7. 0x3C0 = 0b00 11110000 00
;GPIO PD
GPIO_PORTD_DATA_R  	EQU 0x400073FC
GPIO_PORTD_DIR_R   	EQU 0x40007400
GPIO_PORTD_AFSEL_R 	EQU 0x40007420
GPIO_PORTD_PUR_R   	EQU 0x40007510
GPIO_PORTD_DEN_R   	EQU 0x4000751C
GPIO_PORTD_AMSEL_R 	EQU 0x40007528
GPIO_PORTD_PCTL_R  	EQU 0x4000752C
; ADC0	
ADC0_ACTSS_R   		EQU 0x40038000
ADC0_PC_R           EQU	0x40038FC4
ADC0_SSPRI_R        EQU	0x40038020
ADC0_EMUX_R			EQU	0x40038014
ADC0_SSMUX2_R       EQU 0x40038080
ADC0_SSCTL2_R       EQU	0x40038084
ADC0_SSMUX3_R       EQU 0x400380A0
ADC0_SSCTL3_R       EQU 0x400380A4
ADC0_IM_R           EQU 0x40038008
ADC0_PSSI_R			EQU 0x40038028
ADC0_RIS_R			EQU	0x40038004	
ADC0_SSFIFO2_R		EQU	0x40038088
ADC0_SSFIFO3_R		EQU 0x400380A8	
ADC0_ISC_R			EQU	0x4003800C	
; RCGC
SYSCTL_RCGCGPIO_R  	EQU 0x400FE608		; GPIO run mode clock gating control
SYSCTL_RCGCADC_R 	EQU 0x400FE638		; ADC run mode clock gating control
; Variables
VOLT_1				EQU 1241		; 4096 * 1/3.3
VOLT_2				EQU 2482 
PF1                	EQU 0x40025008	;	RED LED
PF2                	EQU 0x40025010	; 	BLUE LED - ORIG
PF3                	EQU 0x40025020	;	GREEN LED
PF_ALL	   			EQU 0x40025038	; 	3 colours

PD0 			  	EQU 0x40007004	;	RED EXTERNAL LED
PD1 			  	EQU 0x40007008	;	GREEN EXTERNAL LED
PD_ALL				EQU 0x4000700C  ; 


		THUMB
		AREA    DATA, ALIGN=4 
		EXPORT  Result [DATA,SIZE=4]
Result  SPACE   4


		AREA    |.text|, CODE, READONLY, ALIGN=2
		THUMB
		EXPORT  Start

Start
		; activate clock for ADEF	
		LDR R1, =SYSCTL_RCGCGPIO_R 	; R1 = address of SYSCTL_RCGCGPIO_R
		LDR R0, [R1]                	; 
		ORR R0, R0, #0x39     	; turn on GPIOE clock ADEF  0011_1001
		STR R0, [R1]                  
		NOP				; allow time for clock to finish
		NOP
		NOP
		
		; Wait for GPIO to be ready - read back to ensure clock is stable
		LDR R0, [R1]
		NOP
		NOP

; initialize Port E
InitPE
		; no need to unlock PE4
		; enable alternate function
		LDR R1, =GPIO_PORTE_AFSEL_R     
		LDR R0, [R1]                     
		ORR R0, R0, #0x10      		; enable alternate function on PE4
		STR R0, [R1] 
		
		; disable digital port
		LDR R1, =GPIO_PORTE_DEN_R   	
		LDR R0, [R1]                    
		BIC R0, R0, #0x10               ; disable digital I/O on PE4
		STR R0, [R1]    
	 			
		; enable analog mode
		LDR R1, =GPIO_PORTE_AMSEL_R     
		LDR R0, [R1]                    
		ORR R0, R0, #0x10    			; enable PE4 analog function
		STR R0, [R1]       

		; activate clock for ADC0
		LDR R1, =SYSCTL_RCGCADC_R 		 
		LDR R0, [R1]                	 
		ORR R0, R0, #0x01           	; activate ADC0
		STR R0, [R1]                  
	  
		BL Delay						; delay subroutine -> allow time for clock to finish

InitADC	
		LDR R1, =ADC0_PC_R       
		LDR R0, [R1]           
		BIC R0, R0, #0x0F				; clear max sample rate field
		ORR R0, R0, #0x1     			; configure for 125K samples/sec
		STR R0, [R1]    

		LDR R1, =ADC0_SSPRI_R       
		LDR R0, =0x0123           		; SS3 is highest priority
		STR R0, [R1]    

		LDR R1, =ADC0_ACTSS_R       
		LDR R0, [R1]           
		BIC R0, R0, #0x08				; disable SS3 before configuration to 
		STR R0, [R1]    				; prevent erroneous execution if a trigger event were to occur

		LDR R1, =ADC0_EMUX_R       
		LDR R0, [R1]           
		BIC R0, R0, #0xF000				; SS3 is software trigger
		STR R0, [R1]    

		LDR R1, =ADC0_SSMUX3_R      
		LDR R0, [R1]           
		BIC R0, R0, #0x000F				; clear SS3 field
		ADD R0, R0, #9					; set channel -> select input pin AIN9
		STR R0, [R1]    

		LDR R1, =ADC0_SSCTL3_R       
		LDR R0, =0x0006           		; configure 1st sample -> not reading Temp sensor, not differentially sampled,
		STR R0, [R1]    				; assert raw interrupt signal at the end of conversion, first sample is last sample
		
		LDR R1, =ADC0_IM_R     
		LDR R0, [R1]           
		BIC R0, R0, #0x0008				; disable SS3 interrupts
		STR R0, [R1]    
		
		LDR R1, =ADC0_ACTSS_R      
		LDR R0, [R1]           
		ORR R0, R0, #0x0008     		; enable SS3
		STR R0, [R1] 
InitPF
		; no need to unlock PF2
		; disable analog functionality
		LDR R1, =GPIO_PORTF_AMSEL_R     
		LDR R0, [R1]                    
		BIC R0, #0x0E                  	; 0 means analog is off
		STR R0, [R1]       
		
		;configure as GPIO
		LDR R1, =GPIO_PORTF_PCTL_R      
		LDR R0, [R1]   
		BIC R0, R0, #0x00000FF0		; Clears bit 1 & 2
		BIC R0, R0, #0x000FF000	        ; Clears bit 3 & 4
		STR R0, [R1]     
		
		;set direction register
		LDR R1, =GPIO_PORTF_DIR_R       
		LDR R0, [R1]                    
		ORR R0, R0, #0x0E               	; PF 1,2,3 output 
		BIC R0, R0, #0x10               	; Make PF4 built-in button input
		STR R0, [R1]    
		
		; regular port function
		LDR R1, =GPIO_PORTF_AFSEL_R     
		LDR R0, [R1]                     
		BIC R0, R0, #0x1E               ; 0 means disable alternate function
		STR R0, [R1] 
		
		; pull-up resistors on switch pins
		LDR R1, =GPIO_PORTF_PUR_R       ; R1 = &GPIO_PORTF_PUR_R
		LDR R0, [R1]                    ; R0 = [R1]
		ORR R0, R0, #0x10               ; R0 = R0|0x10 (enable pull-up on PF4)
		STR R0, [R1]                    ; [R1] = R0

		; enable digital port
		LDR R1, =GPIO_PORTF_DEN_R       ; 7) enable Port F digital port
		LDR R0, [R1]                    
		ORR R0,#0x0E                    ; 1 means enable digital I/O
		ORR R0, R0, #0x10               ; R0 = R0|0x10 (enable digital I/O on PF4)
		STR R0, [R1]    
InitPA
		; no need to unlock Port A bits
		; disable analog mode
		LDR R1, =GPIO_PORTA_AMSEL_R     
		LDR R0, [R1]                    
		BIC R0, R0, #0xF0    			; disable analog mode on PortA bit 4-7
		STR R0, [R1]       
	
		;configure as GPIO
		LDR R1, =GPIO_PORTA_PCTL_R      
		LDR R0, [R1]  
		BIC R0, R0,#0x00FF0000			; clear PortA bit 4 & 5
		BIC R0, R0,#0XFF000000			; clear PortA bit 6 & 7 
		STR R0, [R1]     
    
		;set direction register
		LDR R1, =GPIO_PORTA_DIR_R       
		LDR R0, [R1]                    
		BIC R0, R0, #0xF0     			; set PortA bit 4-7 input (0: input, 1: output)
		STR R0, [R1]    
	
		; disable alternate function
		LDR R1, =GPIO_PORTA_AFSEL_R     
		LDR R0, [R1]                     
		BIC R0, R0, #0xF0      			; disable alternate function on PortA bit 4-7
		STR R0, [R1] 

		; pull-up resistors on switch pins
		LDR R1, =GPIO_PORTA_PUR_R      	; 
		LDR R0, [R1]                   	; 
		ORR R0, R0, #0xF0              	; enable pull-up on PortA bit 4-7
		STR R0, [R1]                   

		; enable digital port
		LDR R1, =GPIO_PORTA_DEN_R   	
		LDR R0, [R1]                    
		ORR R0, R0, #0xF0               ; enable digital I/O on PortA bit 4-7
		STR R0, [R1]	
InitPD
		; no need to unlock Port D bits
		; disable analog mode
		LDR R1, =GPIO_PORTD_AMSEL_R     
		LDR R0, [R1]                    
		BIC R0, R0, #0x03    			; disable analog mode on PortD bit 0-1
		STR R0, [R1]       
	
		;configure as GPIO
		LDR R1, =GPIO_PORTD_PCTL_R      
		LDR R0, [R1]  
		BIC R0, R0, #0x000000FF			; clear PortD bit 0 & 1
		STR R0, [R1]     
	
		;set direction register
		LDR R1, =GPIO_PORTD_DIR_R       
		LDR R0, [R1]                    
		ORR R0, R0, #0x03     			; set PortD bit 0-1 output (0: input, 1: output)
		STR R0, [R1]    
	
		; disable alternate function
		LDR R1, =GPIO_PORTD_AFSEL_R     
		LDR R0, [R1]                     
		BIC R0, R0, #0x03      			; disable alternate function on PortD bit 0-1
		STR R0, [R1] 

		; enable digital port
		LDR R1, =GPIO_PORTD_DEN_R   	
		LDR R0, [R1]                    
		ORR R0, R0, #0x03               ; enable digital I/O on PortD bit 0-1
		STR R0, [R1]

		 ; Set initial state HIGH to test voltage
		; LDR R1, =GPIO_PORTD_DATA_R
		; MOV R0, #0x03                    ; Set both PD0 and PD1 HIGH
		; STR R0, [R1]
Off_All
		LDR R12, =PF_ALL
		BL Output_Low
		LDR R12, =PD_ALL
		BL Output_Low

Loop	
; Read dip switch status
		LDR R1, =PA_4567
		LDR R0, [R1]					; R0 = dip switch status
		LSR R0, #4
		MOV R3, R0

; LED control based on dip switch 1-2
		TST R3, #0x1					; check switch 1 
		LDREQ R12, =PD0					; if 0, switch 1 is ON -> turn off RED LED
		BLEQ Output_Low ; Flipped since active low
		LDRNE R12, =PD0					; if 1, switch 1 is OFF -> turn on RED LED
		BLNE Output_High	

		TST R3, #0x2					; check switch 2
		LDREQ R12, =PD1					; if 0, switch 2 is ON -> turn off GREEN LED
		BLEQ Output_Low
		LDRNE R12, =PD1					; if 1, switch 2 is OFF -> turn on GREEN LED
		BLNE Output_High

; Sample ADC value & load to memory
		LDR R1, =ADC0_PSSI_R      
		MOV R0, #0x08					; initiate sampling in the SS3  
		STR R0, [R1]    
		
		LDR R1, =ADC0_RIS_R   			; R1 = address of ADC Raw Interrupt Status
		LDR R0, [R1]           			; check end of a conversion
		CMP	R0, #0x08    				; when a sample has completed conversion -> a raw interrupt is enabled
		BNE	Loop    
		
		LDR R1, =ADC0_SSFIFO3_R			; load SS3 result FIFO into R1
		LDR R0,[R1]
		LDR R2, =Result					; store data
		STR R0,[R2]						; store PE4 reading in addr 0x20000000
		
; Decide LED behavior based on ADC value	
		LDR R12, =VOLT_1
		CMP R0, R12
		BLE Case1
		LDR R12, =VOLT_2
		CMP R0, R12
		BLE Case2
		BGT Case3
		
Case1
		; Everything turned off
		LDR R12, =PF1 ; Red
		BL Output_Low
		LDR R12, =PF3 ; Green
		BL Output_Low
		B EndCases
Case2
		; Flicker green, turn off red
		LDR R12, =PF1 ; Red
		BL Output_Low
		LDR R12, =PF3 ; Green
		BL Output_Toggle
		BL Delay
		B EndCases
Case3
		; Flicker red, turn off green
		LDR R12, =PF1 ; Red
		BL Output_Toggle
		LDR R12, =PF3 ; Green
		BL Output_Low
		BL Delay
		B EndCases
EndCases
		LDR R1, =ADC0_ISC_R
		LDR R0, [R1]
		ORR R0, R0, #08					; acknowledge conversion (SS3)
		STR R0, [R1]
	
		B Loop	

; Function Subroutines
Delay									; Delay subroutine
		MOV R7,#0xFF000
					
Countdown
		SUBS R7, #1						; subtract and set the flags based on the result
		BNE Countdown		 
		
		BX LR   						; return from subroutine
		
Output_High
		; R12 holds pin param
		MOV R1, R12                    
		MOV R0, #0x0F                  
		STR R0, [R1]                   
		BX  LR                          ; return

Output_Low
		MOV R1, R12          
		MOV R0, #0x00          
		STR R0, [R1]                   
		BX  LR                          ; return
    
Output_Toggle
		MOV R1, R12                   
		LDR R0, [R1]                    ; previous value
		EOR R0, R0, #0x0F               ; flip bit 2: 0x04 1: 0x02
		STR R0, [R1]                    
		BX  LR

		ALIGN                			; make sure the end of this section is aligned
		END                  			; end of file

