DATA SEGMENT
    CRLF DB 0DH, 0AH, '$' 
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA

MAIN:
    MOV AX, DATA
    MOV DS, AX

    MOV DL, 'a'         
    MOV CX, 2           

OUTER_LOOP:
    PUSH CX             
    MOV CX, 13          

INNER_LOOP:
    MOV AH, 02H
    INT 21H
    INC DL              
    LOOP INNER_LOOP     

    PUSH DX    
    
    LEA DX, CRLF
    MOV AH, 09H
    INT 21H
    
    POP DX              

    POP CX              
    LOOP OUTER_LOOP     

    MOV AH, 4CH
    INT 21H

CODE ENDS
END MAIN