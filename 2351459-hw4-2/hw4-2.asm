DATA SEGMENT
    ; 定义图片中的数据 (9行数据)
    ; 注意：这看似是一个9x9矩阵。
    ; 为了简化，我们将这些数据视为连续的字节流。
    ; 图片数据还原：
    TABLE DB 7, 2, 3, 4, 5, 6, 7, 8, 9          ; Row 1
          DB 2, 4, 7, 8, 10, 12, 14, 16, 18     ; Row 2
          DB 3, 6, 9, 12, 15, 18, 21, 24, 27    ; Row 3
          DB 4, 8, 12, 16, 7, 24, 28, 32, 36    ; Row 4
          DB 5, 10, 15, 20, 25, 30, 35, 40, 45  ; Row 5
          DB 6, 12, 18, 24, 30, 7, 42, 48, 54   ; Row 6 
          DB 7, 14, 21, 28, 35, 42, 49, 56, 63  ; Row 7
          DB 8, 16, 24, 32, 40, 48, 56, 7, 72   ; Row 8
          DB 9, 18, 27, 36, 45, 54, 63, 72, 81  ; Row 9

    MSG_ERR DB ' error', 0DH, 0AH, '$'
    SPACE   DB ' ', '$'
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA
START:
    MOV AX, DATA
    MOV DS, AX

    MOV SI, 0       ; SI 用作 TABLE 的索引指针
    
    MOV CX, 1       ; CX = 当前行号 (Row: 1-9)

ROW_LOOP:
    MOV BX, 1       ; BX = 当前列号 (Col: 1-9)

COL_LOOP:
    ; 1. 计算正确结果: Expected = Row * Col
    MOV AX, CX
    MUL BL          ; AL = CX * BX
    
    ; 2. 读取内存中的数据: Actual = TABLE[SI]
    MOV DL, TABLE[SI]
    
    ; 3. 比较 Correct vs Actual
    CMP AL, DL
    JE  NEXT_ITEM   ; 如果相等，检查下一个
    
    ; 4. 如果不相等，报错
    ; 保存寄存器环境
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; 传递参数：Row在CX, Col在BX
    CALL PRINT_ERROR_MSG
    
    POP DX
    POP CX
    POP BX
    POP AX

NEXT_ITEM:
    INC SI          ; 移动数据指针
    INC BX          ; 列号+1
    CMP BX, 9
    JLE COL_LOOP    ; 如果列 <= 9，继续

    INC CX          ; 行号+1
    CMP CX, 9
    JLE ROW_LOOP    ; 如果行 <= 9，继续

    ; 退出
    MOV AH, 4CH
    INT 21H

; --------------------------------------------------
; 子过程：PRINT_ERROR_MSG
; 功能：输出 "Row Col error"
; 输入：CX = Row, BX = Col
; --------------------------------------------------
PRINT_ERROR_MSG PROC NEAR
    ; 打印行号
    MOV AX, CX
    CALL PRINT_DIGIT
    
    ; 打印空格
    MOV AH, 09H
    LEA DX, SPACE
    INT 21H
    
    ; 打印列号
    MOV AX, BX
    CALL PRINT_DIGIT
    
    ; 打印错误文本
    MOV AH, 09H
    LEA DX, MSG_ERR
    INT 21H
    
    RET
PRINT_ERROR_MSG ENDP

; 简单的个位数打印 (假设行/列都是1-9)
PRINT_DIGIT PROC NEAR
    PUSH DX
    ADD AL, 30H
    MOV DL, AL
    MOV AH, 02H
    INT 21H
    POP DX
    RET
PRINT_DIGIT ENDP

CODE ENDS
    END START