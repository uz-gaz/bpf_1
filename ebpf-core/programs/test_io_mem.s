; This test copies content from BPF_MEM_PACKET_BASE (h8000) up to
; BPF_FRAME_POINTER (h89F8) into shared memory (h9000).

        mov r0 0x8000

L1:     ldx64 r1 r0 0x0000
        stx64 r0 r1 0x1000

        add r0 8
        jlt r0 0x8A00 L1


        mov r0 0x9000
        ld64 r2 0x0001000000010000

L2:     addx64 r0 r2 0x0000 ; Add both halves

        add r0 8
        jlt r0 0x9A00 L2

        exit
