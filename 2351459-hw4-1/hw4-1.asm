DATA SEGMENT
    NEWLINE DB 0DH, 0AH, '$'
    SPACE   DB '  ', '$'
    EQ_SIGN DB '=', '$'
    MUL_SIGN DB '*', '$'
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA
START:
    MOV AX, DATA
    MOV DS, AX

    ; --- 主程序开始 ---
    MOV CX, 9       ; 外层循环计数器 i = 9 (对应行数)
    
OUTER_LOOP:
    PUSH CX         ; 保存外层循环的计数器 (Row)
    
    MOV BX, 1       ; 内层循环计数器 j = 1 (对应列数)
    
INNER_LOOP:
    ; 准备打印表达式: Row(CX) * Col(BX)
    
    ; 1. 打印 Row (外层 CX)
    MOV AX, CX
    CALL PRINT_NUM  ; 调用子过程打印数字
    
    ; 2. 打印 '*'
    MOV AH, 09H
    LEA DX, MUL_SIGN
    INT 21H
    
    ; 3. 打印 Col (内层 BX)
    MOV AX, BX
    CALL PRINT_NUM
    
    ; 4. 打印 '='
    MOV AH, 09H
    LEA DX, EQ_SIGN
    INT 21H
    
    ; 5. 计算并打印结果
    MOV AX, CX      ; AX = Row
    MUL BL          ; AL = AX * BL (结果在AX中，因为结果<81，AL足够，但在AH中可能清零)
                    ; 注意：MUL r/m8 -> AX = AL * src
    CALL PRINT_NUM
    
    ; 6. 打印间隔空格
    MOV AH, 09H
    LEA DX, SPACE
    INT 21H
    
    INC BX          ; j++
    CMP BX, CX      ; 比较 j 和 i
    JLE INNER_LOOP  ; 如果 j <= i，继续内层循环
    
    ; --- 内层循环结束，换行 ---
    MOV AH, 09H
    LEA DX, NEWLINE
    INT 21H
    
    POP CX          ; 恢复外层循环计数器
    LOOP OUTER_LOOP ; CX--, 如果 CX != 0 跳转到 OUTER_LOOP

    ; --- 退出程序 ---
    MOV AH, 4CH
    INT 21H

; --------------------------------------------------
; 子过程：PRINT_NUM
; 功能：将AX中的数值以十进制形式打印到屏幕
; 输入：AX (数值, 0-99)
; --------------------------------------------------
PRINT_NUM PROC NEAR
    PUSH AX         ; 保护寄存器
    PUSH BX
    PUSH DX
    
    MOV BL, 10
    DIV BL          ; AX / 10 -> AL = 商(十位), AH = 余数(个位)
    
    MOV BX, AX      ; 保存结果，BL=十位, BH=个位
    
    CMP BL, 0       ; 如果十位是0，不打印（可选，为了对齐好看，这里选择不打印前导0）
    JE SKIP_TENS
    
    MOV DL, BL
    ADD DL, 30H     ; 转换为ASCII
    MOV AH, 02H
    INT 21H

SKIP_TENS:
    MOV DL, BH      ; 取出个位
    ADD DL, 30H     ; 转换为ASCII
    MOV AH, 02H
    INT 21H
    
    POP DX          ; 恢复寄存器
    POP BX
    POP AX
    RET
PRINT_NUM ENDP

CODE ENDS
    END START