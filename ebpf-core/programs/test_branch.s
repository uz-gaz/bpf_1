L0:
        ja  L1
        mov r0 -1
        mov r1 -1
        mov r2 -1

L1:
        jal  L2
        mov r0 -1
        mov r1 -1
        mov r2 -1

; == EQ ==
L2:
        mov r8 23
        jeq r8 24 L2 ; Not taken (if fail infinite loop)
        mov r9 23
        jeq r8 r9 L3 ; Taken
        mov r0 -1 
        mov r1 -1
        mov r2 -1

; == NE ==
L3:
        mov r8 23
        jne r8 23 L3 ; Not taken
        mov r9 24
        jne r8 r9 L4 ; Taken
        mov r0 -1 
        mov r1 -1
        mov r2 -1

; == GT ==
L4:
        mov r8 23
        jgt r8 23 L4 ; Not taken

        mov r8 14
        mov r9 15
        jgt r8 r9 L4 ; Not taken
        
        mov r8 16
        mov r9 7
        jgt r8 r9 L5 ; Taken
        mov r0 -1 
        mov r1 -1
        mov r2 -1

; == GE ==
L5:
        mov r8 23
        jge r8 23 L6 ; Taken
        mov r0 -1 
        mov r1 -1
        mov r2 -1
L6:
        mov r8 14
        mov r9 15
        jge r8 r9 L6 ; Not taken
        
        mov r8 16
        mov r9 7
        jge r8 r9 L7 ; Taken
        mov r0 -1 
        mov r1 -1
        mov r2 -1

; == SGT ==
L7:
        mov r8 23
        jsgt r8 23 L7 ; Not taken

        mov r8 14
        mov r9 15
        jsgt r8 r9 L7 ; Not taken
        
        mov r8 16
        mov r9 7
        jsgt r8 r9 L8 ; Taken
        mov r0 -1 
        mov r1 -1
        mov r2 -1

L8:
        mov r8 -23
        mov r9 -17
        jsgt r8 r9 L8 ; Not taken
        
        mov r8 -42
        jsgt r8 -52 L9 ; Taken
        mov r0 -1 
        mov r1 -1
        mov r2 -1


; == SGE ==
L9:
        mov r8 23
        jsge r8 23 L10 ; Taken
        mov r0 -1 
        mov r1 -1
        mov r2 -1
L10:
        mov r8 14
        mov r9 15
        jsge r8 r9 L10 ; Not taken
        
        mov r8 16
        mov r9 7
        jsge r8 r9 L11 ; Taken
        mov r0 -1 
        mov r1 -1
        mov r2 -1

L11:
        mov r8 -23
        mov r9 -17
        jsge r8 r9 L11 ; Not taken
        
        mov r8 -42
        jsge r8 -52 L12 ; Taken
        mov r0 -1 
        mov r1 -1
        mov r2 -1

; == LT ==
L12:
        mov r8 23
        jlt r8 23 L12 ; Not taken

        mov r8 14
        mov r9 15
        jlt r8 r9 L13 ; Taken
        mov r0 -1 
        mov r1 -1
        mov r2 -1

L13:
        mov r8 16
        mov r9 7
        jlt r8 r9 L13 ; Not taken

; == LE ==
L14:
        mov r8 23
        jle r8 23 L15 ; Taken
        mov r0 -1 
        mov r1 -1
        mov r2 -1
L15:
        mov r8 14
        mov r9 15
        jle r8 r9 L16 ; Taken
        mov r0 -1 
        mov r1 -1
        mov r2 -1
L16:
        mov r8 16
        mov r9 7
        jle r8 r9 L16 ; Not taken

; == SLT ==
L17:
        mov r8 23
        jslt r8 23 L18 ; Not taken

        mov r8 14
        mov r9 15
        jslt r8 r9 L18 ; Taken
        mov r0 -1 
        mov r1 -1
        mov r2 -1
L18:        
        mov r8 16
        mov r9 7
        jslt r8 r9 L18 ; Not taken
        

L19:
        mov r8 -23
        mov r9 -17
        jslt r8 r9 L20 ; Taken
        mov r0 -1 
        mov r1 -1
        mov r2 -1
L20:
        mov r8 -42
        jslt r8 -52 L20 ; Not taken
        
; == SLE ==
L21:
        mov r8 23
        jsle r8 23 L22 ; Taken
        mov r0 -1 
        mov r1 -1
        mov r2 -1
L22:
        mov r8 14
        mov r9 15
        jsle r8 r9 L23 ; Taken
        mov r0 -1 
        mov r1 -1
        mov r2 -1
L23:
        mov r8 16
        mov r9 7
        jsle r8 r9 L23 ; Not taken

L24:
        mov r8 -23
        mov r9 -17
        jslt r8 r9 L25 ; Taken
        mov r0 -1 
        mov r1 -1
        mov r2 -1
L25:
        mov r8 -42
        jslt r8 -52 L25 ; Not taken
        
        ja L26


; == END OF TEST ==
L_end:
        ;div...
        exit
        mov r0 -2
        mov r1 -2
        mov r2 -2

; == SET ==
L26:
        mov r8 23
        jset r8 1 L27 ; Taken
        mov r0 -1 
        mov r1 -1
        mov r2 -1
L27:
        mov r8 8
        mov r9 4
        jset r8 r9 L27; Not taken

        mov r8 -1
        mov r9 75
        jset r8 r9 L28; ; Taken
        mov r0 -1 
        mov r1 -1
        mov r2 -1


; == 32 bit cases == 

; == SGT ==
L28:
        mov32 r8 -23
        mov32 r9 -17
        jsgt32 r8 r9 L28 ; Not taken
        
        mov32 r8 -42
        jsgt32 r8 -52 L29 ; Taken
        mov r0 -1 
        mov r1 -1
        mov r2 -1


; == SGE ==
L29:
        mov32 r8 -23
        mov32 r9 -17
        jsge r8 r9 L29 ; Not taken
        
        mov32 r8 -42
        jsge32 r8 -52 L30 ; Taken
        mov r0 -1 
        mov r1 -1
        mov r2 -1

; == SLT ==
L30:
        mov32 r8 -23
        mov32 r9 -17
        jslt32 r8 r9 L31 ; Taken
        mov r0 -1 
        mov r1 -1
        mov r2 -1
L31:
        mov32 r8 -42
        jslt32 r8 -52 L31 ; Not taken
        
; == SLE ==
L32:
        mov32 r8 -23
        mov32 r9 -17
        jslt32 r8 r9 L33 ; Taken
        mov r0 -1 
        mov r1 -1
        mov r2 -1
L33:
        mov32 r8 -42
        jslt32 r8 -52 L33 ; Not taken

        

; == some edge cases ==

        ; taken branch after taken branch
        jeq r0 r0 L34
        jeq r1 r1 L_error

L34:
        ; unconditional jump after taken branch
        jeq r2 r2 L35
        jeq r3 r3 L_error

L35:
        ja L_end

L_error:
        mov r0 -1 
        mov r1 -1
        mov r2 -1