NVIC_INT_CTRL      	EQU     0xE000ED04; 中断控制寄存器
NVIC_SYSPRI2     	EQU     0xE000ED22; 系统优先级寄存器(优先级14).
NVIC_PENDSV_PRI     EQU     	  0xFF; PendSV优先级(最低).
NVIC_PENDSVSET     	EQU     0x10000000; PendSV触发值	
	
    AREA CODE,CODE,READONLY, ALIGN=3
		
	PRESERVE8
    THUMB
		
	EXPORT tTaskEnterCritical  ;进入临界区
	EXPORT tTaskExitCritical   ;退出临界区
    
tTaskEnterCritical          ;PRIMASK这是个只有单一比特的寄存器。在它被置1后，就关掉所有可屏蔽的异常，
                            ;只剩下NMI和硬fault可以响应。它的缺省值是0，表示没有关中断
    MRS     R0, PRIMASK  	;读取PRIMASK到R0,R0为返回值 
    CPSID   I				;PRIMASK=1,关中断(NMI和硬件FAULT可以响应)
    BX      LR			    ;返回

tTaskExitCritical
    MSR     PRIMASK, R0	   	;读取R0到PRIMASK中,R0为参数
    BX      LR				;返回

;*********************************************************************************************************
;*	函 数 名  :   PendSV_Handler
;*	功能说明  :   在中断服务程序中执行任务切换，保存当前任务现场，恢复下一任务的现场
;*	形    参  :   无
;*	返 回 值  :   无
;*********************************************************************************************************
PendSV_Handler  PROC
    EXPORT PendSV_Handler;PendSV异常处理函数
	IMPORT  currentTask                        ;导入全局变量currentTask 
    IMPORT  nextTask                           ;导入全局变量nextTask 
		
    MRS     R0, PSP                            ;获取当前任务的堆栈指针的值 
    CBZ     R0, PendSVHandler_nosave           ;若是由tTaskRunFirst触发，则不执行下面保存寄存器的操作，直接执行PendSVHandler_nosave，恢复寄存器 
                                               
    STMDB   R0!, {R4-R11}                      ;除R4-R11外，其它寄存器会自动保存，所以需要手动保存R4-R11     
                                             
    LDR     R1, =currentTask                   ;保存栈顶位置currentTask，因为在tTask数据结构中，stack位于起始位置，所以保存currentTask
    LDR     R1, [R1]                           ;也就是保存了堆栈的栈顶
    STR     R0, [R1]                           

PendSVHandler_nosave                           ;恢复下一任务的寄存器
                                       
    LDR     R0, =currentTask                   
    LDR     R1, =nextTask                      
    LDR     R2, [R1]                           
    STR     R2, [R0]                           ;将currentTask设置为nextTask，下一任务变为当前任务
 
    LDR     R0, [R2]                           ;从currentTask的堆栈中开始恢复寄存器
    LDMIA   R0!, {R4-R11}                      ;恢复R4-R11寄存器

    MSR     PSP, R0                            ;恢复堆栈指针到PSP
    ORR     LR, LR, #0x04                      ;使用PSP所指向的堆栈为当前的堆栈，PendSV使用的是MSP
    BX      LR                                 ;退出PendSV异常处理
	ENDP

;*********************************************************************************************************
;*	函 数 名  :   tTaskSwitch
;*	功能说明  :   触发PENDSV中断
;*	形    参  :   无
;*	返 回 值  :   无
;*********************************************************************************************************
tTaskSwitch PROC
	EXPORT tTaskSwitch         ;PENDSV中断触发函数
	LDR		R0,=NVIC_INT_CTRL
	LDR		R1,=NVIC_PENDSVSET
	STR		R1,[R0]            ;触发PendSV异常
	BX      LR   ;把LR寄存器的内容复制到PC寄存器里 ，从而实现函数的返回
    ENDP

;*********************************************************************************************************
;*	函 数 名  :   tTaskRunFirst
;*	功能说明  :   设置PSP寄存器为0，标记是第一次执行任务切换，配置PENDSV中断优先级为最低并触发该中断
;*	形    参  :   无
;*	返 回 值  :   无
*********************************************************************************************************
tTaskRunFirst PROC
	EXPORT tTaskRunFirst
	MOVS	R0,#0    ;任务堆栈设置为0
	MSR		PSP,R0   ;PSP清零，作为首次上下文切换的标志	
		
    LDR		R0,=NVIC_SYSPRI2   
	LDR		R1,=NVIC_PENDSV_PRI  ;设置PENDSV中断的优先级为最低
	STRB	R1,[R0]
	
	LDR		R0,=NVIC_INT_CTRL
	LDR		R1,=NVIC_PENDSVSET
	STR		R1,[R0]              ;触发PendSV异常,在PENDSV中断服务程序中执行任务切换
		
	BX      LR   ;把LR寄存器的内容复制到PC寄存器里 ，从而实现函数的返回
    ENDP

	END
;no more