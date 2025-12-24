; int0_handler_fixed.asm - INT0溢出中断服务程序
; 重写INT0中断向量，处理溢出异常

.MODEL SMALL
.STACK 100h

.DATA
    overflow_msg    DB 'Overflow Exception (INT0) - Overflow detected!', 0dh, 0ah, '$'
    overflow_count  DW 0                    ; Overflow counter
    old_int0_seg    DW ?                    ; Save original INT0 segment
    old_int0_off    DW ?                    ; Save original INT0 offset
    newline         DB 0dh, 0ah, '$'
    install_msg     DB 'INT0 handler installed successfully!', 0dh, 0ah, '$'
    test_msg        DB 0dh, 0ah, 'Starting overflow tests...', 0dh, 0ah, '$'
    complete_msg    DB 0dh, 0ah, 'Test completed! Total overflows: ', '$'
    times_msg       DB ' times', 0dh, 0ah, '$'
    total_msg       DB ' overflow exceptions', 0dh, 0ah, '$'

.CODE

; 新的INT0中断处理程序
new_int0_handler PROC FAR
    ; 保存所有寄存器
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    PUSH BP
    PUSH DS
    PUSH ES
    
    ; 设置数据段
    MOV AX, @DATA
    MOV DS, AX
    
    ; 增加溢出计数器
    INC overflow_count
    
    ; 显示溢出消息
    MOV AH, 09h
    MOV DX, OFFSET overflow_msg
    INT 21h
    
    ; 显示溢出次数
    MOV AX, overflow_count
    CALL print_number
    
    ; 显示"次"字
    MOV AH, 09h
    MOV DX, OFFSET times_msg
    INT 21h
    
    ; 恢复所有寄存器
    POP ES
    POP DS
    POP BP
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    
    ; 从中断返回
    IRET
new_int0_handler ENDP

; 打印数字函数 (AX = 要打印的数字)
print_number PROC
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    MOV CX, 0           ; 位数计数器
    MOV BX, 10          ; 除数
    
    ; 处理0的特殊情况
    CMP AX, 0
    JNE convert_loop
    MOV SI, 0
    PUSH SI
    INC CX
    JMP print_digits
    
convert_loop:
    XOR DX, DX          ; DX清零
    DIV BX              ; AX / 10，余数在DX
    PUSH DX             ; 保存余数
    INC CX              ; 位数加1
    CMP AX, 0
    JNE convert_loop
    
print_digits:
    POP DX              ; 取出数字
    ADD DL, '0'         ; 转换为ASCII
    MOV AH, 02h
    INT 21h
    LOOP print_digits
    
    POP SI
    POP DX
    POP CX
    POP BX
    RET
print_number ENDP

; 测试溢出函数
test_overflow PROC
    PUSH AX
    PUSH DX
    
    ; 显示测试消息
    MOV AH, 09h
    MOV DX, OFFSET test_msg
    INT 21h
    
    ; 测试1: 字节溢出 - 更明显的溢出
    MOV AL, 120         ; 较大的正数
    ADD AL, 50          ; 明显溢出: 120 + 50 = 170 > 127
    INTO                ; 如果溢出，触发INT0
    
    ; 测试2: 字溢出 - 更明显的溢出
    MOV AX, 32000       ; 较大的正数
    ADD AX, 5000        ; 明显溢出: 32000 + 5000 = 37000 > 32767
    INTO                ; 如果溢出，触发INT0
    
    ; 测试3: 负数溢出 - 更明显的溢出
    MOV AL, -120        ; 较小的负数
    SUB AL, 50          ; 明显溢出: -120 - 50 = -170 < -128
    INTO                ; 如果溢出，触发INT0
    
    ; 显示测试完成消息
    MOV AH, 09h
    MOV DX, OFFSET complete_msg
    INT 21h
    
    ; 显示总的溢出次数
    MOV AX, overflow_count
    CALL print_number
    
    MOV AH, 09h
    MOV DX, OFFSET total_msg
    INT 21h
    
    POP DX
    POP AX
    RET
test_overflow ENDP

; 主程序 - 安装新的INT0处理程序
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    
    ; 保存原INT0中断向量 (INT0 = 向量4)
    MOV AX, 3504h       ; AH=35h (获取中断向量), AL=04h (INT0)
    INT 21h             ; 返回: ES:BX = 原中断向量
    MOV old_int0_seg, ES
    MOV old_int0_off, BX
    
    ; 安装新的INT0处理程序 (INT0 = 向量4)
    MOV AX, 2504h       ; AH=25h (设置中断向量), AL=04h (INT0)
    MOV DX, OFFSET new_int0_handler
    MOV CX, SEG new_int0_handler
    PUSH DS             ; 保存当前数据段
    MOV DS, CX
    INT 21h
    POP DS              ; 恢复数据段
    
    ; 显示安装成功消息
    MOV AH, 09h
    MOV DX, OFFSET install_msg
    INT 21h
    
    ; 测试溢出
    CALL test_overflow
    
    ; 恢复原来的INT0中断向量 (INT0 = 向量4)
    MOV AX, 2504h       ; AH=25h (设置中断向量), AL=04h (INT0)
    MOV DX, old_int0_off
    MOV CX, old_int0_seg
    PUSH DS             ; 保存当前数据段
    MOV DS, CX
    INT 21h
    POP DS              ; 恢复数据段
    
    ; 程序结束
    MOV AH, 4Ch
    INT 21h

MAIN ENDP

END MAIN