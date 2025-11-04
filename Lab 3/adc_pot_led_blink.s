; adc_two_ch.s
; samples two ADC channels, PortE bit 4 (PE4) and bit 5 (PE5), using Sample Sequencer 2 (SS2)

; GPIO_PORTE and ADC0 address

GPIO_PORTE_AFSEL_R 	EQU 0x40024420
GPIO_PORTE_DEN_R   	EQU 0x4002451C
GPIO_PORTE_AMSEL_R 	EQU 0x40024528
	
GPIO_PORTF_DATA_R  	EQU 0x400253FC
GPIO_PORTF_DIR_R   	EQU 0x40025400
GPIO_PORTF_AFSEL_R 	EQU 0x40025420
GPIO_PORTF_PUR_R   	EQU 0x40025510
GPIO_PORTF_DEN_R   	EQU 0x4002551C
GPIO_PORTF_AMSEL_R 	EQU 0x40025528
GPIO_PORTF_PCTL_R  	EQU 0x4002552C
	
ADC0_ACTSS_R   		EQU 0x40038000
ADC0_PC_R           EQU	0x40038FC4
ADC0_SSPRI_R        EQU	0x40038020
ADC0_EMUX_R			EQU	0x40038014
ADC0_SSMUX2_R       EQU 0x40038080
ADC0_SSCTL2_R       EQU	0x40038084
ADC0_IM_R           EQU 0x40038008
ADC0_PSSI_R			EQU 0x40038028
ADC0_RIS_R			EQU	0x40038004	
ADC0_SSFIFO2_R		EQU	0x40038088	
ADC0_ISC_R			EQU	0x4003800C	
	
SYSCTL_RCGCGPIO_R  	EQU 0x400FE608		; GPIO run mode clock gating control

SYSCTL_RCGCADC_R 	EQU 0x400FE638		; ADC run mode clock gating control

VOLT_1				EQU 819
VOLT_2				EQU 1638
PF1                	EQU 0x40025008	;	RED LED
PF2                	EQU 0x40025010	; 	BLUE LED - ORIG
PF3                	EQU 0x40025020	;	GREEN LED
PFA		   			EQU 0x40025038	; 	3 colours :


		THUMB
		AREA    DATA, ALIGN=4 
		EXPORT  Result [DATA,SIZE=4]
Result  SPACE   4


		AREA    |.text|, CODE, READONLY, ALIGN=2
		THUMB
		EXPORT  Start

Start

; initialize Port E
; activate clock for PortE
InitPE
		LDR R1, =SYSCTL_RCGCGPIO_R 		; R1 = address of SYSCTL_RCGCGPIO_R
		LDR R0, [R1]                	; 
		ORR R0, R0, #0x10           	; turn on GPIOE clock
		STR R0, [R1]                  
		NOP								; allow time for clock to finish
		NOP
		NOP   
		
; no need to unlock PE4 and PE5

; select alternate function
		LDR R1, =GPIO_PORTE_AFSEL_R     
		LDR R0, [R1]                     
		ORR R0, R0, #0x30      			; enable alternate function on PE4 and PE5
		STR R0, [R1] 

; disable digital port
		LDR R1, =GPIO_PORTE_DEN_R   	
		LDR R0, [R1]                    
		BIC R0, R0, #0x30               ; disable digital I/O on PE4 and PE5
		STR R0, [R1]    
		
; enable analog mode
		LDR R1, =GPIO_PORTE_AMSEL_R     
		LDR R0, [R1]                    
		ORR R0, R0, #0x30    			; enable PE4 & PE5 analog function 0011 0000
		STR R0, [R1]       
			
; activate clock for ADC0	 
		LDR R1, =SYSCTL_RCGCADC_R 		 
		LDR R0, [R1]                	 
		ORR R0, R0, #0x01           	; activate ADC0
		STR R0, [R1]                  
	  
		BL Delay						; delay subroutine -> allow time for clock to finish
		
		LDR R1, =ADC0_PC_R       
		LDR R0, [R1]           
		BIC R0, R0, #0x0F				; clear max sample rate field
		ORR R0, R0, #0x1     			; configure for 125K samples/sec
		STR R0, [R1]    

		LDR R1, =ADC0_SSPRI_R       
		LDR R0, =0x1023           		; SS2 is highest priority
		STR R0, [R1]    

		LDR R1, =ADC0_ACTSS_R       
		LDR R0, [R1]           
		BIC R0, R0, #0x0004				; disable SS2 before configuration to 
		STR R0, [R1]    				; prevent erroneous execution if a trigger event were to occur

		LDR R1, =ADC0_EMUX_R       
		LDR R0, [R1]           
		BIC R0, R0, #0x0F00				; SS2 is software trigger
		STR R0, [R1]    

		LDR R1, =ADC0_SSMUX2_R      
		LDR R0, [R1]           
		BIC R0, R0, #0x00FF				; clear SS2 field
		ADD R0, R0, #0x89				; set channel -> select input pin AIN8 and AIN9
		STR R0, [R1]    

		LDR R1, =ADC0_SSCTL2_R       
		LDR R0, =0x0060          		; configure sample -> not reading Temp sensor, not differentially sampled,
		STR R0, [R1]    				; assert raw interrupt signal at the end of conversion, second sample is last sample
		
		LDR R1, =ADC0_IM_R     
		LDR R0, [R1]           
		BIC R0, R0, #0x0004				; disable SS2 interrupts
		STR R0, [R1]    
		
		LDR R1, =ADC0_ACTSS_R      
		LDR R0, [R1]           
		ORR R0, R0, #0x0004     		; enable SS2
		STR R0, [R1]    
InitPF
		; activate clock for Port F
		LDR R1, =SYSCTL_RCGCGPIO_R      
		LDR R0, [R1]                 
		ORR R0, R0, #0x20               ; set bit 5 to turn on clock
		STR R0, [R1]                  
		NOP								; allow time for clock to finish
		NOP
		NOP        
		
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
			

Loop		
		LDR R1, =ADC0_PSSI_R      
		MOV R0, #0x04					; initiate sampling in SS2
		STR R0, [R1]    
		
		LDR R1, =ADC0_RIS_R   			; R1 = address of ADC Raw Interrupt Status
		LDR R0, [R1]           			; check end of a conversion
		CMP	R0, #0x04    				; when a sample has completed conversion -> a raw interrupt is enabled
		BNE	Loop    
			
		LDR R1, =ADC0_SSFIFO2_R			; load SS2 result FIFO into R1
		LDR R2, =Result
		LDR R0,[R1]
		STR R0,[R2]				; store PE4 reading in addr 0x20000000 & 0x20000001
		
		LDR R0,[R1]
		ADD R2, R2, #04
		STR R0,[R2]				; store PE5 reading in addr 0x20000004 & 0x20000005
		
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
		BL SSR_Off
		LDR R12, =PF3 ; Green
		BL SSR_Off
		B EndCases
Case2
		; Flicker green, turn off red
		LDR R12, =PF1 ; Red
		BL SSR_Off
		LDR R12, =PF3 ; Green
		BL SSR_Toggle
		BL Delay
		B EndCases
Case3
		; Flicker red, turn off green
		LDR R12, =PF1 ; Red
		BL SSR_Toggle
		LDR R12, =PF3 ; Green
		BL SSR_Off
		BL Delay
		B EndCases
EndCases

		LDR R1, =ADC0_ISC_R
		LDR R0, [R1]
		ORR R0, R0, #04					; acknowledge conversion
		STR R0, [R1]
	
		B Loop	
Delay									; Delay subroutine
		MOV R7,#0xFF000
					
Countdown
		SUBS R7, #1						; subtract and set the flags based on the result
		BNE Countdown		 
		
		BX LR   						; return from subroutine
		
SSR_On
		; R12 holds pin param
		MOV R1, R12                    ; R1 = &PF2
		MOV R0, #0x0E                   ; R0 = 0x04 (turn on the appliance)
		STR R0, [R1]                    ; [R1] = R0, write to PF2
		BX  LR                          ; return

SSR_Off
		MOV R1, R12                    ; R1 = &PF2
		MOV R0, #0x00                   ; R0 = 0x00 (turn off the appliance)
		STR R0, [R1]                    ; [R1] = R0, write to PF2
		BX  LR                          ; return
    
SSR_Toggle
		MOV R1, R12                    ; R1 is 0x40025010
		LDR R0, [R1]                    ; previous value
		EOR R0, R0, #0x0E               ; flip bit 2: 0x04 1: 0x02
		STR R0, [R1]                    ; affect just PF2
		BX  LR

		ALIGN                			; make sure the end of this section is aligned
		END                  			; end of file

