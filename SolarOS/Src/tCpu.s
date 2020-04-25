NVIC_INT_CTRL      	EQU     0xE000ED04; �жϿ��ƼĴ���
NVIC_SYSPRI2     	EQU     0xE000ED22; ϵͳ���ȼ��Ĵ���(���ȼ�14).
NVIC_PENDSV_PRI     EQU     	  0xFF; PendSV���ȼ�(���).
NVIC_PENDSVSET     	EQU     0x10000000; PendSV����ֵ	
	
    AREA CODE,CODE,READONLY, ALIGN=3
		
	PRESERVE8
    THUMB
		
	EXPORT tTaskEnterCritical  ;�����ٽ���
	EXPORT tTaskExitCritical   ;�˳��ٽ���
    
tTaskEnterCritical          ;PRIMASK���Ǹ�ֻ�е�һ���صļĴ�������������1�󣬾͹ص����п����ε��쳣��
                            ;ֻʣ��NMI��Ӳfault������Ӧ������ȱʡֵ��0����ʾû�й��ж�
    MRS     R0, PRIMASK  	;��ȡPRIMASK��R0,R0Ϊ����ֵ 
    CPSID   I				;PRIMASK=1,���ж�(NMI��Ӳ��FAULT������Ӧ)
    BX      LR			    ;����

tTaskExitCritical
    MSR     PRIMASK, R0	   	;��ȡR0��PRIMASK��,R0Ϊ����
    BX      LR				;����

;*********************************************************************************************************
;*	�� �� ��  :   PendSV_Handler
;*	����˵��  :   ���жϷ��������ִ�������л������浱ǰ�����ֳ����ָ���һ������ֳ�
;*	��    ��  :   ��
;*	�� �� ֵ  :   ��
;*********************************************************************************************************
PendSV_Handler  PROC
    EXPORT PendSV_Handler;PendSV�쳣������
	IMPORT  currentTask                        ;����ȫ�ֱ���currentTask 
    IMPORT  nextTask                           ;����ȫ�ֱ���nextTask 
		
    MRS     R0, PSP                            ;��ȡ��ǰ����Ķ�ջָ���ֵ 
    CBZ     R0, PendSVHandler_nosave           ;������tTaskRunFirst��������ִ�����汣��Ĵ����Ĳ�����ֱ��ִ��PendSVHandler_nosave���ָ��Ĵ��� 
                                               
    STMDB   R0!, {R4-R11}                      ;��R4-R11�⣬�����Ĵ������Զ����棬������Ҫ�ֶ�����R4-R11     
                                             
    LDR     R1, =currentTask                   ;����ջ��λ��currentTask����Ϊ��tTask���ݽṹ�У�stackλ����ʼλ�ã����Ա���currentTask
    LDR     R1, [R1]                           ;Ҳ���Ǳ����˶�ջ��ջ��
    STR     R0, [R1]                           

PendSVHandler_nosave                           ;�ָ���һ����ļĴ���
                                       
    LDR     R0, =currentTask                   
    LDR     R1, =nextTask                      
    LDR     R2, [R1]                           
    STR     R2, [R0]                           ;��currentTask����ΪnextTask����һ�����Ϊ��ǰ����
 
    LDR     R0, [R2]                           ;��currentTask�Ķ�ջ�п�ʼ�ָ��Ĵ���
    LDMIA   R0!, {R4-R11}                      ;�ָ�R4-R11�Ĵ���

    MSR     PSP, R0                            ;�ָ���ջָ�뵽PSP
    ORR     LR, LR, #0x04                      ;ʹ��PSP��ָ��Ķ�ջΪ��ǰ�Ķ�ջ��PendSVʹ�õ���MSP
    BX      LR                                 ;�˳�PendSV�쳣����
	ENDP

;*********************************************************************************************************
;*	�� �� ��  :   tTaskSwitch
;*	����˵��  :   ����PENDSV�ж�
;*	��    ��  :   ��
;*	�� �� ֵ  :   ��
;*********************************************************************************************************
tTaskSwitch PROC
	EXPORT tTaskSwitch         ;PENDSV�жϴ�������
	LDR		R0,=NVIC_INT_CTRL
	LDR		R1,=NVIC_PENDSVSET
	STR		R1,[R0]            ;����PendSV�쳣
	BX      LR   ;��LR�Ĵ��������ݸ��Ƶ�PC�Ĵ����� ���Ӷ�ʵ�ֺ����ķ���
    ENDP

;*********************************************************************************************************
;*	�� �� ��  :   tTaskRunFirst
;*	����˵��  :   ����PSP�Ĵ���Ϊ0������ǵ�һ��ִ�������л�������PENDSV�ж����ȼ�Ϊ��Ͳ��������ж�
;*	��    ��  :   ��
;*	�� �� ֵ  :   ��
*********************************************************************************************************
tTaskRunFirst PROC
	EXPORT tTaskRunFirst
	MOVS	R0,#0    ;�����ջ����Ϊ0
	MSR		PSP,R0   ;PSP���㣬��Ϊ�״��������л��ı�־	
		
    LDR		R0,=NVIC_SYSPRI2   
	LDR		R1,=NVIC_PENDSV_PRI  ;����PENDSV�жϵ����ȼ�Ϊ���
	STRB	R1,[R0]
	
	LDR		R0,=NVIC_INT_CTRL
	LDR		R1,=NVIC_PENDSVSET
	STR		R1,[R0]              ;����PendSV�쳣,��PENDSV�жϷ��������ִ�������л�
		
	BX      LR   ;��LR�Ĵ��������ݸ��Ƶ�PC�Ĵ����� ���Ӷ�ʵ�ֺ����ķ���
    ENDP

	END
;no more