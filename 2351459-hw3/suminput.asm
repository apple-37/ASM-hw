; suminput.asm - 接收用户输入的数字N，计算1到N的和并显示
; 包含两个核心转换逻辑：输入(字符串->数字) 和 输出(数字->字符串)

DATA SEGMENT
    PROMPT      DB 'Enter a number (1-100): $'
    BUFFER      DB 4, 0, 4 DUP('$')  ; DOS 输入缓冲区
    ; 字节1 (4):  缓冲区最大可容纳字符数 (3个数字+'Enter')
    ; 字节2 (0):  实际输入的字符数 (由DOS填充)
    ; 后面字节:   实际输入的字符内容
    CRLF        DB 0DH, 0AH, '$'     ; 换行符
DATA ENDS

STACK SEGMENT
    DW 128 DUP(0)
STACK ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:STACK

; (这里直接复用上面那个完美的 PRINT_DEC 子程序)
; ===================================================================
; 子程序: PRINT_DEC (代码同上，此处为简洁省略，实际使用时需复制过来)
; ===================================================================
PRINT_DEC PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    MOV CX, 0
CONVERT_LOOP:
    MOV DX, 0
    MOV BX, 10
    DIV BX
    ADD DL, '0'
    PUSH DX
    INC CX
    CMP AX, 0
    JNE CONVERT_LOOP
PRINT_LOOP:
    POP DX
    MOV AH, 02H
    INT 21H
    LOOP PRINT_LOOP
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_DEC ENDP


; ===================================================================
; 主程序: MAIN
; ===================================================================
MAIN:
    ; --- 初始化 ---
    MOV AX, DATA
    MOV DS, AX
    MOV AX, STACK
    MOV SS, AX

    ; 1. 提示用户输入
    LEA DX, PROMPT
    MOV AH, 09H
    INT 21H

    ; 2. 读取用户输入的字符串 (使用 0Ah 功能)
    LEA DX, BUFFER
    MOV AH, 0AH
    INT 21H

    ; 打印一个换行，让输出格式更美观
    LEA DX, CRLF
    MOV AH, 09H
    INT 21H

    ; 3. 将输入的字符串转换为数字，结果存入 BX
    MOV BX, 0           ; BX 存放转换后的数字结果，清零
    MOV CX, 0           
    MOV CL, BUFFER+1    ; 从缓冲区第二个字节获取输入字符串的实际长度
    LEA SI, BUFFER+2    ; SI 指向字符串的第一个字符

CONVERT_INPUT_LOOP:
    ; 核心逻辑: result = result * 10 + (currentChar - '0')
    MOV AX, 10
    MUL BX              ; AX = BX * 10 (MUL指令会把结果存入DX:AX)
    MOV BX, AX          ; 将 result * 10 的结果存回 BX
    
    MOV AL, [SI]        ; 取出当前字符 (如 '1')
    SUB AL, '0'         ; 将字符 '1' 转换为数字 1
    MOV AH, 0           ; 清空 AH, 使得 AX = AL
    ADD BX, AX          ; BX = (result*10) + 当前数字

    INC SI              ; 指向下一个字符
    LOOP CONVERT_INPUT_LOOP

    ; 此时，用户输入的数字 N 已经存在了 BX 寄存器中

    ; 4. 计算 1+...+N 的和
    MOV AX, 0           ; AX 用于累加
    MOV CX, BX          ; 设置循环次数为用户输入的 N

CALC_SUM_LOOP:
    ADD AX, CX
    LOOP CALC_SUM_LOOP

    ; 5. 调用子程序打印结果
    CALL PRINT_DEC

    ; 6. 程序退出
    MOV AH, 4CH
    INT 21H

CODE ENDS
END MAIN