; sum.asm - 计算 1-100 的和，并将结果 5050 打印到屏幕
; 这份代码是健壮的，子程序中包含了完整的寄存器保护。

DATA SEGMENT
    ; 本程序的数据很简单，无需在数据段定义变量
DATA ENDS

STACK SEGMENT
    DW 128 DUP(0)       ; 为堆栈分配 256 字节空间
STACK ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:STACK

; ===================================================================
; 子程序: PRINT_DEC
; 功能:   将 AX 寄存器中的无符号十进制数转换为字符串并打印
; 输入:   AX = 要打印的数字
; 输出:   无
; 破坏:   无 (所有使用的寄存器都被保存和恢复)
; ===================================================================
PRINT_DEC PROC
    ; --- 保护现场：保存所有将被修改的寄存器 ---
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV CX, 0           ; CX 用作数字位数计数器，清零

CONVERT_LOOP:
    ; --- 核心转换逻辑：反复除以10取余数 ---
    MOV DX, 0           ; 关键步骤！执行 16 位除法前，必须将 DX 清零
    MOV BX, 10          ; 除数是 10
    DIV BX              ; 执行 AX / BX, 商在 AX, 余数在 DX

    ADD DL, '0'         ; 将数字余数 (0-9) 转换为 ASCII 字符 ('0'-'9')
    PUSH DX             ; 将该字符压入堆栈。注意：低位的数字先入栈
    INC CX              ; 位数计数器加 1
    CMP AX, 0           ; 商是否为 0？
    JNE CONVERT_LOOP    ; 如果商不为 0，继续循环

PRINT_LOOP:
    ; --- 从堆栈中弹出字符并打印 ---
    ; 由于FILO(先进后出)特性，现在先弹出的是最高位的数字
    POP DX              ; 将字符从堆栈弹出到 DX
    MOV AH, 02H         ; DOS 功能号：显示单个字符
    INT 21H             ; DL 中是要显示的字符
    LOOP PRINT_LOOP     ; 根据之前计数的位数 CX，循环打印

    ; --- 恢复现场：按相反顺序恢复寄存器 ---
    POP DX
    POP CX
    POP BX
    POP AX
    RET                 ; 子程序返回
PRINT_DEC ENDP

; ===================================================================
; 主程序: MAIN
; ===================================================================
MAIN:
    ; --- 初始化段寄存器 ---
    MOV AX, DATA
    MOV DS, AX
    MOV AX, STACK
    MOV SS, AX

    ; --- 计算 1+2+...+100 ---
    MOV AX, 0           ; AX 用于累加，初始为 0
    MOV CX, 100         ; CX 作为循环计数器，从 100 开始

SUM_LOOP:
    ADD AX, CX          ; 累加: AX = AX + CX (100, 99, 98...)
    LOOP SUM_LOOP       ; CX 减 1，不为 0 则跳转

    ; 循环结束后, AX 中存放着结果 5050 (十六进制为 13BAh)
    
    ; --- 调用子程序打印结果 ---
    CALL PRINT_DEC      ; 调用我们写的子程序来显示 AX 中的数字

    ; --- 程序正常退出 ---
    MOV AH, 4CH         ; DOS 功能号：带返回值退出
    INT 21H             ; 调用 DOS 中断

CODE ENDS
END MAIN