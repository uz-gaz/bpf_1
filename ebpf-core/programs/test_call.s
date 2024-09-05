; Warning! This test only works with "hfu/Test_HFU.vhd"
; as the HFU entity. In order to test it using "launch-core-testbench.sh" it has to be executed
; using --hfu=Test_HFU option

        mov r1 0x000A0000
        mov r2 0x0000B000
        mov r3 0x00000C00
        mov r4 0x000000D0
        mov r5 0x0000000F

        call 0 ; does not receive parameters -> r0 = -1

        call 1 ; receives 1 parameter -> r0 = r1 = 0x000A0000

        mov r8 16
        div r8 4 ; Test if stays on INIT_S state
        call 2 ; receives 2 parameters -> r0 = r1|r2 = 0x000AB000

        mov r8 16
        st8 r10 0x00 2 ; Test if stays on F...._EX_S state while st8 blockes pipeline
        call 3 ; receives 3 parameters -> r0 = r1|r2|r3 = 0x000ABC00

        call 4 ; receives 4 parameters -> r0 = r1|r2|r3|r4 = 0x000ABCD0

        call 5 ; receives 5 parameters -> r0 = r1|r2|r3|r4|r5 = 0x000ABCDF


;-- 1 parameter dependency -----------------------------------------------------
        mov r1 0x00010000
        call 1 ; r0 = 0x00010000 ; get r1 from MEM, don't stop
        mov r8 r0 ; get r0 from WB, don't stop
        mov r9 r0 ; get r0 from RegBank, don't stop

        st64 r10 0x00 0x00020000
        ldx64 r1 r10 0x00
        call 1 ; r0 = 0x00020000 ; get r1 from WB, stop on ID stage while ldx64 is on MEM

        mov r1 0x00030000 
        st64 r10 0x00 0xFFFFFFFF
        ldx64 r2 r10 0x00
        call 1 ; r0 = 0x00030000 ; get r1 from RegBank, don't stop because of r2

;-- 2 parameters dependency ----------------------------------------------------
        mov r2 0x0000F000

        mov r1 0x00010000
        call 2 ; r0 = 0x0001F000 ; get r1 from MEM, don't stop
        mov r8 r0 ; get r0 from WB, don't stop
        mov r9 r0 ; get r0 from RegBank, don't stop

        st64 r10 0x00 0x00020000
        ldx64 r1 r10 0x00
        call 2 ; r0 = 0x0002F000 ; get r1 from WB, stop on ID stage while ldx64 is on MEM

        mov r1 0x00030000 
        st64 r10 0x00 0xFFFFFFFF
        ldx64 r3 r10 0x00
        call 2 ; r0 = 0x0003F000 ; get r1 from RegBank, don't stop because of r3


        mov r1 0x000F0000

        mov r2 0x00001000
        call 2 ; r0 = 0x000F1000 ; get r2 from MEM, don't stop
        mov r8 r0 ; get r0 from WB, don't stop
        mov r9 r0 ; get r0 from RegBank, don't stop

        st64 r10 0x00 0x00002000
        ldx64 r2 r10 0x00
        call 2 ; r0 = 0x000F2000 ; get r2 from WB, stop on ID stage while ldx64 is on MEM

        mov r2 0x00003000 
        st64 r10 0x00 0xFFFFFFFF
        ldx64 r3 r10 0x00
        call 2 ; r0 = 0x000F3000 ; get r2 from RegBank, don't stop because of r3

    
;-- 3 parameters dependency ----------------------------------------------------
        mov r2 0x0000F000
        mov r3 0x00000F00

        mov r1 0x00010000
        call 3 ; r0 = 0x0001FF00 ; get r1 from MEM, don't stop
        mov r8 r0 ; get r0 from WB, don't stop
        mov r9 r0 ; get r0 from RegBank, don't stop

        st64 r10 0x00 0x00020000
        ldx64 r1 r10 0x00
        call 3 ; r0 = 0x0002FF00 ; get r1 from WB, stop on ID stage while ldx64 is on MEM

        mov r1 0x00030000 
        st64 r10 0x00 0xFFFFFFFF
        ldx64 r4 r10 0x00
        call 3 ; r0 = 0x0003FF00 ; get r1 from RegBank, don't stop because of r4


        mov r1 0x000F0000
        mov r3 0x00000F00

        mov r2 0x00001000
        call 3 ; r0 = 0x000F1F00 ; get r2 from MEM, don't stop
        mov r8 r0 ; get r0 from WB, don't stop
        mov r9 r0 ; get r0 from RegBank, don't stop

        st64 r10 0x00 0x00002000
        ldx64 r2 r10 0x00
        call 3 ; r0 = 0x000F2F00 ; get r2 from WB, stop on ID stage while ldx64 is on MEM

        mov r2 0x00003000 
        st64 r10 0x00 0xFFFFFFFF
        ldx64 r4 r10 0x00
        call 3 ; r0 = 0x000F3F00 ; get r2 from RegBank, don't stop because of r4

        
        mov r1 0x000F0000
        mov r2 0x0000F000

        mov r3 0x00000100
        call 3 ; r0 = 0x000FF100 ; get r3 from MEM, don't stop
        mov r8 r0 ; get r0 from WB, don't stop
        mov r9 r0 ; get r0 from RegBank, don't stop

        st64 r10 0x00 0x00000200
        ldx64 r3 r10 0x00
        call 3 ; r0 = 0x000FF200 ; get r3 from WB, stop on ID stage while ldx64 is on MEM

        mov r3 0x00000300 
        st64 r10 0x00 0xFFFFFFFF
        ldx64 r4 r10 0x00
        call 3 ; r0 = 0x000FF300 ; get r3 from RegBank, don't stop because of r4

;-- 4 parameters dependency ----------------------------------------------------
        mov r2 0x0000F000
        mov r3 0x00000F00
        mov r4 0x000000F0

        mov r1 0x00010000
        call 4 ; r0 = 0x0001FFF0 ; get r1 from MEM, don't stop
        mov r8 r0 ; get r0 from WB, don't stop
        mov r9 r0 ; get r0 from RegBank, don't stop

        st64 r10 0x00 0x00020000
        ldx64 r1 r10 0x00
        call 4 ; r0 = 0x0002FFF0 ; get r1 from WB, stop on ID stage while ldx64 is on MEM

        mov r1 0x00030000 
        st64 r10 0x00 0xFFFFFFFF
        ldx64 r5 r10 0x00
        call 4 ; r0 = 0x0003FFF0 ; get r1 from RegBank, don't stop because of r5


        mov r1 0x000F0000
        mov r3 0x00000F00
        mov r4 0x000000F0

        mov r2 0x00001000
        call 4 ; r0 = 0x000F1FF0 ; get r2 from MEM, don't stop
        mov r8 r0 ; get r0 from WB, don't stop
        mov r9 r0 ; get r0 from RegBank, don't stop

        st64 r10 0x00 0x00002000
        ldx64 r2 r10 0x00
        call 4 ; r0 = 0x000F2FF0 ; get r2 from WB, stop on ID stage while ldx64 is on MEM

        mov r2 0x00003000 
        st64 r10 0x00 0xFFFFFFFF
        ldx64 r5 r10 0x00
        call 4 ; r0 = 0x000F3FF0 ; get r2 from RegBank, don't stop because of r5

        
        mov r1 0x000F0000
        mov r2 0x0000F000
        mov r4 0x000000F0

        mov r3 0x00000100
        call 4 ; r0 = 0x000FF1F0 ; get r3 from MEM, don't stop
        mov r8 r0 ; get r0 from WB, don't stop
        mov r9 r0 ; get r0 from RegBank, don't stop

        st64 r10 0x00 0x00000200
        ldx64 r3 r10 0x00
        call 4 ; r0 = 0x000FF2F0 ; get r3 from WB, stop on ID stage while ldx64 is on MEM

        mov r3 0x00000300 
        st64 r10 0x00 0xFFFFFFFF
        ldx64 r5 r10 0x00
        call 4 ; r0 = 0x000FF3F0 ; get r3 from RegBank, don't stop because of r5


        mov r1 0x000F0000
        mov r2 0x0000F000
        mov r3 0x00000F00

        mov r4 0x00000010
        call 4 ; r0 = 0x000FFF10 ; get r4 from RegBank, stop while mov is on EX stage
        mov r8 r0 ; get r0 from WB, don't stop
        mov r9 r0 ; get r0 from RegBank, don't stop

        st64 r10 0x00 0x00000020
        ldx64 r4 r10 0x00
        call 4 ; r0 = 0x000FFF20 ; get r4 from WB, stop on ID stage while ldx64 is on MEM

        mov r4 0x00000030 
        st64 r10 0x00 0xFFFFFFFF
        ldx64 r5 r10 0x00
        call 4 ; r0 = 0x000FFF30 ; get r4 from RegBank, don't stop because of r5
        
;-- 5 parameters dependency ----------------------------------------------------
        mov r2 0x0000F000
        mov r3 0x00000F00
        mov r4 0x000000F0
        mov r5 0x0000000F

        mov r1 0x00010000
        call 5 ; r0 = 0x0001FFF0 ; get r1 from MEM, don't stop
        mov r8 r0 ; get r0 from WB, don't stop
        mov r9 r0 ; get r0 from RegBank, don't stop

        st64 r10 0x00 0x00020000
        ldx64 r1 r10 0x00
        call 5 ; r0 = 0x0002FFFF ; get r1 from WB, stop on ID stage while ldx64 is on MEM

        mov r1 0x00030000 
        st64 r10 0x00 0xFFFFFFFF
        ldx64 r6 r10 0x00
        call 5 ; r0 = 0x0003FFFF ; get r1 from RegBank, don't stop because of r6


        mov r1 0x000F0000
        mov r3 0x00000F00
        mov r4 0x000000F0
        mov r5 0x0000000F

        mov r2 0x00001000
        call 5 ; r0 = 0x000F1FFF ; get r2 from MEM, don't stop
        mov r8 r0 ; get r0 from WB, don't stop
        mov r9 r0 ; get r0 from RegBank, don't stop

        st64 r10 0x00 0x00002000
        ldx64 r2 r10 0x00
        call 5 ; r0 = 0x000F2FFF ; get r2 from WB, stop on ID stage while ldx64 is on MEM

        mov r2 0x00003000 
        st64 r10 0x00 0xFFFFFFFF
        ldx64 r6 r10 0x00
        call 5 ; r0 = 0x000F3FFF ; get r2 from RegBank, don't stop because of r6

        
        mov r1 0x000F0000
        mov r2 0x0000F000
        mov r4 0x000000F0
        mov r5 0x0000000F

        mov r3 0x00000100
        call 5 ; r0 = 0x000FF1FF ; get r3 from MEM, don't stop
        mov r8 r0 ; get r0 from WB, don't stop
        mov r9 r0 ; get r0 from RegBank, don't stop

        st64 r10 0x00 0x00000200
        ldx64 r3 r10 0x00
        call 5 ; r0 = 0x000FF2FF ; get r3 from WB, stop on ID stage while ldx64 is on MEM

        mov r3 0x00000300 
        st64 r10 0x00 0xFFFFFFFF
        ldx64 r6 r10 0x00
        call 5 ; r0 = 0x000FF3FF ; get r3 from RegBank, don't stop because of r6


        mov r1 0x000F0000
        mov r2 0x0000F000
        mov r3 0x00000F00
        mov r5 0x0000000F

        mov r4 0x00000010
        call 5 ; r0 = 0x000FFF1F ; get r4 from RegBank, stop while mov is on EX stage
        mov r8 r0 ; get r0 from WB, don't stop
        mov r9 r0 ; get r0 from RegBank, don't stop

        st64 r10 0x00 0x00000020
        ldx64 r4 r10 0x00
        call 5 ; r0 = 0x000FFF2F ; get r4 from WB, stop on ID stage while ldx64 is on MEM

        mov r4 0x00000030 
        st64 r10 0x00 0xFFFFFFFF
        ldx64 r6 r10 0x00
        call 5 ; r0 = 0x000FFF3F ; get r4 from RegBank, don't stop because of r6


        mov r1 0x000F0000
        mov r2 0x0000F000
        mov r3 0x00000F00
        mov r4 0x000000F0

        mov r5 0x00000001
        call 5 ; r0 = 0x000FFFF1 ; get r5 from RegBank, stop while mov is on EX stage
        mov r8 r0 ; get r0 from WB, don't stop
        mov r9 r0 ; get r0 from RegBank, don't stop

        st64 r10 0x00 0x00000002
        ldx64 r5 r10 0x00
        call 5 ; r0 = 0x000FFFF2 ; get r5 from WB, stop on ID stage while ldx64 is on MEM

        mov r5 0x00000003 
        st64 r10 0x00 0xFFFFFFFF
        ldx64 r6 r10 0x00
        call 5 ; r0 = 0x000FFFF3 ; get r5 from RegBank, don't stop because of r6



        call -1 ; generates exception in MEM stage