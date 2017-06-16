;------------------------------------------------------------------------
;  File Name: timer.asm
;  Author: Fang Yuan
;  Mail: yfang@nju.edu.cn
;  Created Time: Mon 12 Jun 2017 10:48:31 AM CST
;------------------------------------------------------------------------

.286
data    SEGMENT
counter DB      0
hour    DB      0
minute  DB      0
second  DB      0
oldint8 DD      0
data    ENDS

code    SEGMENT
        ASSUME  cs:code, ds:data
init8259 PROC
        mov     AL, 00010011B
        out     20H, AL
        mov     AL, 00001000B
        out     21H, AL
        mov     AL, 00000010B
        out     21H, AL    
        ret
init8259 ENDP

init8253 PROC
        mov     AL, 00110110B
        out     43H, AL
        mov     AX, 2000h
        out     40H, AL         
        mov     AL, AH
        out     40H, AL
        ret
init8253 ENDP

print   MACRO   val
        mov     AL, val
        shr     AL, 1
        shr     AL, 1
        shr     AL, 1
        shr     AL, 1
        add     AL, '0'
        STOSB
        mov     AL, 01000111B
        STOSB
        mov     AL, val
        and     AL, 00001111B
        add     AL, '0'
        STOSB
        mov     AL, 01000111B
        STOSB
        mov     AL, ':'
        STOSB
        mov     AL, 01000111B
        STOSB
        ENDM

display PROC
        mov    AX, data
        mov    DS, AX
        CLD
        mov     AX, 0B800H
        mov     ES, AX
        mov     DI, 0

        print   hour
        print   minute
        print   second
        mov     AL, 'A'
        STOSB
        mov     AL, 01000111B
        STOSB
        ret
display ENDP

gettime PROC
        mov     AL, second
        add     AL, 1
        daa
        mov     second, AL
        cmp     AL, 60H
        jl      noadjust
        mov     second, 0
        mov     AL, minute
        add     AL, 1
        daa
        mov     minute, AL
        cmp     AL, 60H
        jl      noadjust
        mov     minute, 0
        mov     AL, hour
        add     AL, 1
        daa
        mov     hour, AL
noadjust:
        ret
gettime ENDP

int8    PROC
        pusha
        mov     AX, data
        mov     DS, AX
        add     counter, 1
        cmp     counter, 18
        jl      exitint8

        mov     counter, 0
        call    gettime
        call    display

exitint8:
        mov     AL, 20H
        out     20H, AL
        popa
        iret
int8    ENDP

int8_init PROC
        mov     AX, data
        mov     DS, AX
        mov     AX, 0
        mov     ES, AX
        mov     BX, 8*4
        mov     AX, OFFSET int8
        xchg    ES:[BX], AX
        mov     word ptr oldint8, AX
        mov     AX, SEG  int8
        xchg    ES:[BX + 2], AX
        mov     word ptr oldint8+2, AX
        ret
int8_init ENDP

resetint8 PROC
        mov     AX, 0
        mov     ES, AX
        mov     BX, 8*4
        mov     AX, word ptr oldint8
        mov     ES:[BX], AX
        mov     AX, word ptr oldint8 +2
        mov     ES:[BX+2], AX
        ret
resetint8 ENDP

keyboard PROC
        mov     AH, 1
        int     21H
        cmp     AL, '0'
        jnz     keyboard
        ret
keyboard ENDP

main    PROC
        cli
        call    init8259
        call    init8253
        call    int8_init
        sti
        mov     AL, 11111100B
        out     21H, AL
        call    keyboard
        call    resetint8
        mov     AH, 4CH
        int     21H
main    ENDP

code    ENDS
        END     main
