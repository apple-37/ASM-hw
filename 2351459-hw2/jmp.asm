
DATA SEGMENT
    CRLF DB 0DH, 0AH, '$' 
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA

MAIN:
    MOV AX, DATA
    MOV DS, AX

    MOV DL, 'a'         
    MOV BL, 0           

PRINT_LOOP:
    MOV AH, 02H
    INT 21H
    INC DL              
    INC BL              

    CMP BL, 13
    JNE CONTINUE_LOOP   

    PUSH DX            
    LEA DX, CRLF
    MOV AH, 09H
    INT 21H
    POP DX              
    MOV BL, 0           

CONTINUE_LOOP:
    CMP DL, 'z'
    JBE PRINT_LOOP      

    MOV AH, 4CH
    INT 21H

CODE ENDS
END MAIN