; == Test STORE + LOAD ==

        st64 r10 -0x00 327 ;
        ldx64 r0 r10 -0x00 ; r0 = 327


        st32 r10 -0x08 4123;
        ldx32 r1 r10 -0x08 ; r1 = 4123

        st32 r10 -0x0C 543 ;
        ldx32 r2 r10 -0x0C ; r2 = 543


        st16 r10 -0x10 999 ;
        ldx16 r3 r10 -0x10 ; r3 = 999

        st16 r10 -0x12 66  ;
        ldx16 r4 r10 -0x12 ; r4 = 66

        st16 r10 -0x14 3232;
        ldx16 r5 r10 -0x14 ; r5 = 3232

        st16 r10 -0x16 756 ;
        ldx16 r6 r10 -0x16 ; r6 = 756


        st8 r10 -0x18 11  ;
        ldx8 r0 r10 -0x18 ; r0 = 11

        st8 r10 -0x19 22  ;
        ldx8 r1 r10 -0x19 ; r1 = 22

        st8 r10 -0x1A 33  ;
        ldx8 r2 r10 -0x1A ; r2 = 33

        st8 r10 -0x1B 44  ;
        ldx8 r3 r10 -0x1B ; r3 = 44

        st8 r10 -0x1C 55  ;
        ldx8 r4 r10 -0x1C ; r4 = 55

        st8 r10 -0x1D 66  ;
        ldx8 r5 r10 -0x1D ; r5 = 66

        st8 r10 -0x1E 77  ;
        ldx8 r6 r10 -0x1E ; r6 = 77

        st8 r10 -0x1F 88  ;
        ldx8 r7 r10 -0x1F ; r7 = 88

; == Test STORE + LOADSX ==

        ld64 r9 -327      ;
        stx64 r10 r9 -0x00 ;
        ldx64 r0 r10 -0x00 ; r0 = -327


        ld64 r9 -4123      ;
        stx32 r10 r9 -0x08  ;
        ldxs32 r1 r10 -0x08 ; r1 = -4123

        ld64 r9 -543       ;
        stx32 r10 r9 -0x0C  ;
        ldxs32 r2 r10 -0x0C ; r2 = -543


        ld64 r9 -999       ;
        stx16 r10 r9 -0x10  ;
        ldxs16 r3 r10 -0x10 ; r3 = -999

        ld64 r9 -66        ;
        stx16 r10 r9 -0x12  ;
        ldxs16 r4 r10 -0x12 ; r4 = -66

        ld64 r9 -3232      ;
        stx16 r10 r9 -0x14  ;
        ldxs16 r5 r10 -0x14 ; r5 = -3232

        ld64 r9 -756       ;
        stx16 r10 r9 -0x16  ;
        ldxs16 r6 r10 -0x16 ; r6 = -756


        ld64 r9 -11       ;
        stx8 r10 r9 -0x18  ;
        ldxs8 r0 r10 -0x18 ; r0 = -11

        ld64 r9 -22       ;
        stx8 r10 r9 -0x19  ;
        ldxs8 r1 r10 -0x19 ; r1 = -22

        ld64 r9 -33       ;
        stx8 r10 r9 -0x1A  ;
        ldxs8 r2 r10 -0x1A ; r2 = -33

        ld64 r9 -44       ;
        stx8 r10 r9 -0x1B  ;
        ldxs8 r3 r10 -0x1B ; r3 = -44

        ld64 r9 -55       ;
        stx8 r10 r9 -0x1C  ;
        ldxs8 r4 r10 -0x1C ; r4 = -55

        ld64 r9 -66       ;
        stx8 r10 r9 -0x1D  ;
        ldxs8 r5 r10 -0x1D ; r5 = -66

        ld64 r9 -77       ;
        stx8 r10 r9 -0x1E  ;
        ldxs8 r6 r10 -0x1E ; r6 = -77

        ld64 r9 -88       ;
        stx8 r10 r9 -0x1F  ;
        ldxs8 r7 r10 -0x1F ; r7 = -88

; == Test STORE + ADD + LOAD ==

        ld64 r8 -24        ;
        st64 r10 -0x20 3    ;
        addx64 r10 r8 -0x20 ;
        ldx64 r0 r10 -0x20  ; r0 = -21

        st32 r10 -0x28 3    ;
        addx32 r10 r8 -0x28 ;
        ldx32 r1 r10 -0x28  ; r1 = 0xFFFFFFFFFFFFFFEB

        st32 r10 -0x2C 3    ;
        addx32 r10 r8 -0x2C ;
        ldxs32 r2 r10 -0x2C ; r2 = -21


        ld64 r3 -53         ;
        st64 r10 -0x30 66    ;
        addfx64 r10 r3 -0x30 ; r3 = 66
        ldx64 r6 r10 -0x30   ; r6 = 13

        ld64 r4 -53         ;
        st32 r10 -0x38 64    ;
        addfx32 r10 r4 -0x38 ; r4 = 64
        ldx32 r7 r10 -0x38   ; r7 = 11

        ld64 r5 -53         ;
        st32 r10 -0x3C 62    ;
        addfx32 r10 r5 -0x3C ; r5 = 62
        ldxs32 r8 r10 -0x3C  ; r8 = 9

; == Test STORE + OR|AND|XOR + LOAD ==

        ld64 r9 72057851736457312 ; 0000000100000000000000000011110000000000000001111000000001100000
        ld64 r8 562950893143040   ; 0000000000000010000000000000000000111000000000110000010000000000
        stx64 r10 r8 -0x40         ; 
        orx64 r10 r9 -0x40         ;    
        ldx64 r0 r10 -0x40    ; r0 = 0000000100000010000000000011110000111000000001111000010001100000 (72620802629403744)

        ld64 r9 72057851736457312 ; 0000000100000000000000000011110000000000000001111000000001100000
        ld64 r8 72620544931070976 ; 0000000100000010000000000000000000111000000000110000010000000000
        stx64 r10 r8 -0x50         ;
        andfx64 r10 r9 -0x50       ; r9 = (72620544931070976)
        ldx64 r0 r10 -0x50    ; r0 = 0000000100000000000000000000000000000000000000110000000000000000 (72057594038124544)

        ld64 r9 72057851736457312 ; 0000000100000000000000000011110000000000000001111000000001100000
        ld64 r8 72620544931070976 ; 0000000100000010000000000000000000111000000000110000010000000000
        stx64 r10 r8 -0x60         ;
        xorfx64 r10 r9 -0x60       ; r9 = (72620544931070976)
        ldx64 r0 r10 -0x60         ; r0 = 0000000000000010000000000011110000111000000001001000010001100000 (563208591279200)

; == Test STORE + XCHG|CMPXCHG + LOAD ==

        st64 r10 -0xA0 3     ;
        mov r9 24           ;
        xchgx64 r10 r9 -0xA0 ; r9 = 3
        ldx64 r8 r10 -0xA0   ; r8 = 24
        mov r1 r9 ; (!) wait for xchgx64 to finish MEM stage, then consume r9 from MEM-WB buffer


        st64 r10 -0xA0 7        ;
        mov r9 35              ;
        mov r0 7               ; Equal -> exchange
        cmpxchgx64 r10 r9 -0xA0 ; r0 = 7  (!) get r0 from MEM
        mov r2 r0 ; (!) stop 1 cycle and wait for cmpxchgx64 to finish MEM stage, then consume r0 from MEM-WB buffer
        ldx64 r8 r10 -0xA0      ; r8 = 35

        st64 r10 -0xA0 -32      ;
        mov r0 -34             ; Not Equal -> not exchange 
        mov r9 981             ;
        cmpxchgx64 r10 r9 -0xA0 ; r0 = -32   (!) get r0 from WB
        ldx64 r8 r10 -0xA0      ; r8 = -32
        add r0 r1 ; (!) wait for cmpxchgx64 to finish MEM stage, then consume r0 from MEM-WB buffer -> r0 = -32 + 3 = -29

        exit