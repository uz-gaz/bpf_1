; == Test ADD ==

        mov r0 24 ; A
        mov r1 5  ; B
        add r0 r1 ; r0 = 29

        mov r2 -1 ; A
        add r2 1  ; r2 = 0

        mov r3 -67    ; A
        add r3 -2131  ; r3 = -2198

        mov r0 24 ; A
        mov r1 5  ; B
        add32 r0 r1 ; r0 = 29

        mov r2 -1 ; A
        add32 r2 1  ; r2 = 0

        mov r3 -67    ; A
        add32 r3 -2131  ; r3 = 00000000FFFFF76A (-2198)

; == Test SUB ==

        mov r0 24 ; A
        mov r1 5  ; B
        sub r0 r1 ; r0 = 19

        mov r2 -1 ; A
        sub r2 1  ; r2 = -2

        mov r3 -67    ; A
        sub r3 -2131  ; r3 = 2064

        mov r0 24 ; A
        mov r1 5  ; B
        sub32 r0 r1 ; r0 = 19

        mov r2 -1 ; A
        sub32 r2 1  ; r2 = 00000000FFFFFFFE (-2)

        mov r3 -67    ; A
        sub32 r3 -2131  ; r3 = 2064

; == Test MUL ==

        mov r0 24 ; A
        mov r1 5  ; B
        mul r0 r1 ; r0 = 120

        mov r2 -1 ; A
        mul r2 1  ; r2 = -1

        mov r3 -67    ; A
        mul r3 -2131  ; r3 = 142777

        mov r0 24 ; A
        mov r1 5  ; B
        mul32 r0 r1 ; r0 = 120

        mov r2 -2 ; A
        mul32 r2 1  ; r2 = 00000000FFFFFFFE (-2)

        mov r3 -67    ; A
        mul32 r3 -2131  ; r3 = 142777

; == Test DIV ==

        mov r0 100 ; A
        mov r1 7   ; B
        div r0 r1 ; r0 = 14

        mov r0 100 ; A
        mov r1 -7  ; B
        div r0 r1 ; r0 = 0

        mov r0 -100 ; A
        mov r1 7    ; B
        div r0 r1   ; r0 = 2 635 249 153 387 078 788

        mov r0 -100 ; A
        mov r1 -7   ; B
        div r0 r1   ; r0 = 0

        mov r0 100 ; A
        mov r1 0   ; B
        div r0 r1  ; r0 = 0

        mov r0 -100 ; A
        mov r1 0    ; B
        div r0 r1   ; r0 = 0


        mov r0 100 ; A
        sdiv r0 7 ; r0 = 14

        mov r0 100 ; A
        sdiv r0 -7 ; r0 = -14

        mov r0 -100 ; A
        sdiv r0 7   ; r0 = -14

        mov r0 -100 ; A
        sdiv r0 -7  ; r0 = 14

        mov r0 100 ; A
        sdiv r0 0  ; r0 = 0

        mov r0 -100 ; A
        sdiv r0 0   ; r0 = 0


        mov r0 100  ; A
        mov r1 7    ; B
        div32 r0 r1 ; r0 = 14

        mov r0 100  ; A
        mov r1 -7   ; B
        div32 r0 r1 ; r0 = 0

        mov r0 -100 ; A
        mov r1 7    ; B
        div32 r0 r1 ; r0 = 613 566 742

        mov r0 -100 ; A
        mov r1 -7   ; B
        div32 r0 r1 ; r0 = 0

        mov r0 100  ; A
        mov r1 0    ; B
        div32 r0 r1 ; r0 = 0

        mov r0 -100 ; A
        mov r1 0    ; B
        div32 r0 r1 ; r0 = 0


        mov r0 100  ; A
        sdiv32 r0 7 ; r0 = 14

        mov r0 100   ; A
        sdiv32 r0 -7 ; r0 = 00000000FFFFFFF2

        mov r0 -100 ; A
        sdiv32 r0 7 ; r0 = 00000000FFFFFFF2

        mov r0 -100  ; A
        sdiv32 r0 -7 ; r0 = 14

        mov r0 100  ; A
        sdiv32 r0 0 ; r0 = 0

        mov r0 -100 ; A
        sdiv32 r0 0 ; r0 = 0

; == Test MOD ==

        mov r0 100 ; A
        mov r1 7   ; B
        mod r0 r1 ; r0 = 2

        mov r0 100 ; A
        mov r1 -7  ; B
        mod r0 r1 ; r0 = 100

        mov r0 -100 ; A
        mov r1 7    ; B
        mod r0 r1   ; r0 = 0

        mov r0 -100 ; A
        mov r1 -7   ; B
        mod r0 r1   ; r0 = -100 (full dividend, as div equals 0)

        mov r0 100 ; A
        mov r1 0   ; B
        mod r0 r1  ; r0 = 100

        mov r0 -100 ; A
        mov r1 0    ; B
        mod r0 r1   ; r0 = -100


        mov r0 100 ; A
        smod r0 7 ; r0 = 2

        mov r0 100 ; A
        smod r0 -7 ; r0 = -2

        mov r0 -100 ; A
        smod r0 7   ; r0 = -2

        mov r0 -100 ; A
        smod r0 -7  ; r0 = 2

        mov r0 100 ; A
        smod r0 0  ; r0 = 100

        mov r0 -100 ; A
        smod r0 0   ; r0 = -100


        mov r0 100  ; A
        mov r1 7    ; B
        mod32 r0 r1 ; r0 = 2

        mov r0 100  ; A
        mov r1 -7   ; B
        mod32 r0 r1 ; r0 = 100

        mov r0 -100 ; A
        mov r1 7    ; B
        mod32 r0 r1 ; r0 = 2

        mov r0 -100 ; A
        mov r1 -7   ; B
        mod32 r0 r1 ; r0 = 00000000FFFFFF9C

        mov r0 100  ; A
        mov r1 0    ; B
        mod32 r0 r1 ; r0 = 100

        mov r0 -100 ; A
        mov r1 0    ; B
        mod32 r0 r1 ; r0 = 00000000FFFFFF9C


        mov r0 100  ; A
        smod32 r0 7 ; r0 = 2

        mov r0 100   ; A
        smod32 r0 -7 ; r0 = 00000000FFFFFFFE

        mov r0 -100 ; A
        smod32 r0 7 ; r0 = 00000000FFFFFFFE

        mov r0 -100  ; A
        smod32 r0 -7 ; r0 = 2

        mov r0 100  ; A
        smod32 r0 0 ; r0 = 100

        mov r0 -100 ; A
        smod32 r0 0 ; r0 = 00000000FFFFFF9C    (PC + 1: 163)


; == Test OR | AND | XOR ==

        ld64 r9 72057851736457312 ; 0000000100000000000000000011110000000000000001111000000001100000
        ld64 r8 562950893143040   ; 0000000000000010000000000000000000111000000000110000010000000000
        or r9 r8             ; r9 = 0000000100000010000000000011110000111000000001111000010001100000 (72620802629403744)

        ld64 r8 72057851736457312 ; 0000000100000000000000000011110000000000000001111000000001100000
        ld64 r9 72620544931070976 ; 0000000100000010000000000000000000111000000000110000010000000000
        and r9 r8            ; r9 = 0000000100000000000000000000000000000000000000110000000000000000 (72057594038124544)

        ld64 r9 72057851736457312 ; 0000000100000000000000000011110000000000000001111000000001100000
        ld64 r8 72620544931070976 ; 0000000100000010000000000000000000111000000000110000010000000000
        xor r9 r8            ; r9 = 0000000000000010000000000011110000111000000001001000010001100000 (563208591279200)


; == Test LSH | RSH ==

        mov r0 100  ; A
        lsh r0 2    ; r0 = 400

        mov r0 800  ; A
        rsh r0 1027 ; r0 = (800 >> 3) = 100


; == Test ARSH ==

        ld64 r0 0x00000FF0000000FF  ; A
        arsh r0 8    ; r0 = 0x0000000FF0000000

        ld64 r0 0x80000FF0000000FF  ; A
        arsh r0 8    ; r0 = 0xFF80000FF0000000


        ld64 r0 0x00000FF00000FFFF  ; A
        arsh32 r0 8    ; r0 = 0x00000000000000FF

        ld64 r0 0x80000FF0800000FF  ; A
        arsh32 r0 8    ; r0 = 0x00000000FF800000


; == Test MOVSX ==

        movsx8  r6 0xFD         ; r6 = -3
        movsx8  r6 0x7D         ; r6 = 125
        movsx16  r6 0xFFFD      ; r6 = -3
        movsx16  r6 0x7FFD      ; r6 = 32 765
        movsx32  r6 0xFFFFFFFD  ; r6 = -3
        movsx32  r6 0x700000FD  ; r6 = 1 879 048 445

        mov32sx8  r6 0xFD         ; r6 = 00000000FFFFFFFD
        mov32sx8  r6 0x7D         ; r6 = 125
        mov32sx16  r6 0xFFFD      ; r6 = 00000000FFFFFFFD
        mov32sx16  r6 0x7FFD      ; r6 = 32 762


; == Test END ==

        ld64 r7 0x0102030405060708 ;
        bswap16 r7 ; r7 = 0000000000000807

        ld64 r7 0x0102030405060708 ;
        bswap32 r7 ; r7 = 0000000008070605

        ld64 r7 0x0102030405060708 ;
        bswap64 r7 ; r7 = 0807060504030201


        ld64 r7 0x0102030405060708 ;
        be16 r7 ; r7 = 0000000000000807

        ld64 r7 0x0102030405060708 ;
        be32 r7 ; r7 = 0000000008070605

        ld64 r7 0x0102030405060708 ;
        be64 r7 ; r7 = 0807060504030201

        ld64 r7 0x0102030405060708 ;
        le16 r7 ; do nothing
        le32 r7 ; do nothing
        le64 r7 ; do nothing

        exit