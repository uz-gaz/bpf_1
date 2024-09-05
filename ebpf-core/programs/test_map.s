        ; 32 bits values
        mov r9 0
loop:   
        mov r1 1    ; map id  <- 1
        mov r2 r9   ; map key <- 0..100
        call 0      ; lookup_elem(1, i);

        jeq r0 0 null

        ldx32 r3 r0 0x00
        ldx32 r4 r0 0x04 ; next elem

        ja loop_guard
null:  
        mov r3 -1
        mov r4 -1

loop_guard:
        add r9 1
        jlt r9 100 loop

        mov r1 1    ; 
        mov r2 100  ; ! out of bounds
        call 0      ; lookup_elem(0, 100) -> NULL

        mov r1 0    ; ! map 0 should not exist
        mov r2 45   ;
        call 0      ; lookup_elem(0, 45) -> NULL

;----------------------;
        mov r9 0
dummy_loop_0:
        le64 r7 ; NOOP
        le64 r7 ; NOOP
        add r9 1
        jlt r9 10 dummy_loop_0
;----------------------;

        ; 8 bits values       
        mov r1 0    ; ! map 0 should have replaced map 1 (same data)
        mov r2 45   ;
        call 0      ; lookup_elem(0, 45)

        ldx32 r3 r0 0x00
        ldx32 r4 r0 0x04 ; next elem

;----------------------;
        mov r9 0
dummy_loop_1:
        le64 r7 ; NOOP
        le64 r7 ; NOOP
        add r9 1
        jlt r9 10 dummy_loop_1
;----------------------;

        ; 16 bits values
        mov r1 0    ;
        mov r2 45   ;
        call 0      ; lookup_elem(0, 45)

        ldx32 r3 r0 0x00
        ldx32 r4 r0 0x04 ; next elem

;----------------------;
        mov r9 0
dummy_loop_2:
        le64 r7 ; NOOP
        le64 r7 ; NOOP
        add r9 1
        jlt r9 10 dummy_loop_2
;----------------------;

        ; 64 bits values
        mov r1 0    ;
        mov r2 45   ;
        call 0      ; lookup_elem(0, 45)

        ldx64 r3 r0 0x00
        ldx64 r4 r0 0x04 ; next elem


        mov r1 1    ; ! map 1 should not exist  
        mov r2 66   ;
        call 0      ; lookup_elem(0, 66) -> NULL

        ldx32 r3 r0 0x00 ; END WITH EXCEPTION: derreferencing NULL pointer (access to instruction memory is forbidden)
