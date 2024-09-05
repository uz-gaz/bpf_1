; 64 bit ALU instructions
add  r6 64
add  r6 r4
sub  r6 64 
sub  r6 r4 
mul  r6 64
mul  r6 r4 
div  r6 64 
div  r6 r4
sdiv  r6 64 
sdiv  r6 r4
or   r6 64 
or   r6 r4 
and  r6 64 
and  r6 r4 
lsh  r6 64
lsh  r6 r4
rsh  r6 64
rsh  r6 r4
neg  r6    
mod  r6 64
mod  r6 r4
smod  r6 64
smod  r6 r4 
xor  r6 64 
xor  r6 r4 
mov  r6 64 
mov  r6 r4
movsx8  r6 64 
movsx8  r6 r4
movsx16  r6 64 
movsx16  r6 r4
movsx32  r6 64 
movsx32  r6 r4
arsh r6 64 
arsh r6 r4

; 32 bit ALU instructions
add32  r3 32
add32  r3 r2 
sub32  r3 32 
sub32  r3 r2 
mul32  r3 32 
mul32  r3 r2 
div32  r3 32 
div32  r3 r2
sdiv32  r3 32 
sdiv32  r3 r2 
or32   r3 32 
or32   r3 r2
and32  r3 32
and32  r3 r2
lsh32  r3 32 
lsh32  r3 r2 
rsh32  r3 32 
rsh32  r3 r2
neg32  r3    
mod32  r3 32
mod32  r3 r2
smod32  r3 32
smod32  r3 r2 
xor32  r3 32 
xor32  r3 r2 
mov32  r3 32
mov32  r3 r2
mov32sx8  r3 32
mov32sx8  r3 r2
mov32sx16  r3 32
mov32sx16  r3 r2
arsh32 r3 32
arsh32 r3 r2

; Byteswap instructions
le16 r7 
le32 r7 
le64 r7 
be16 r7 
be32 r7 
be64 r7
bswap16 r7
bswap32 r7
bswap64 r7

; Atomic operations
;addx8      r1 r5 54
;addx16     r1 r5 54
addx32     r1 r5 54
addx64     r1 r5 54
;andx8      r1 r5 54
;andx16     r1 r5 54
andx32     r1 r5 54
andx64     r1 r5 54
;orx8       r1 r5 54
;orx16      r1 r5 54
orx32      r1 r5 54
orx64      r1 r5 54
;xorx8      r1 r5 54
;xorx16     r1 r5 54
xorx32     r1 r5 54
xorx64     r1 r5 54
;addfx8     r1 r5 54
;addfx16    r1 r5 54
addfx32    r1 r5 54
addfx64    r1 r5 54
;andfx8     r1 r5 54
;andfx16    r1 r5 54
andfx32    r1 r5 54
andfx64    r1 r5 54
;orfx8      r1 r5 54
;orfx16     r1 r5 54
orfx32     r1 r5 54
orfx64     r1 r5 54
;xorfx8     r1 r5 54
;xorfx16    r1 r5 54
xorfx32    r1 r5 54
xorfx64    r1 r5 54
;xchgx8     r1 r5 54
;xchgx16    r1 r5 54
xchgx32    r1 r5 54
xchgx64    r1 r5 54
;cmpxchgx8  r1 r5 54
;cmpxchgx16 r1 r5 54
cmpxchgx32 r1 r5 54
cmpxchgx64 r1 r5 54
; 16 and 8 bit wide operations are not supported, but could be tested

; Memory instructions
ld64    r7 -10
; Legacy packet access instructions not supported
; ldabs8  80
; ldabs16 80
; ldabs32 80
; ldabs64 80
; ldind8  r9 80
; ldind16 r9 80
; ldind32 r9 80
; ldind64 r9 80
ldx8    r7 r9 101
ldx16   r7 r9 101
ldx32   r7 r9 101
ldx64   r7 r9 101
ldxs8   r7 r9 101
ldxs16  r7 r9 101
ldxs32  r7 r9 101
st8     r7 101 80
st16    r7 101 80
st32    r7 101 80
st64    r7 101 80
stx8    r7 r9 101
stx16   r7 r9 101
stx32   r7 r9 101
stx64   r7 r9 101

; 64 bit Jump instructions
ja  L1; Uses offset
L1: jeq  r1 12 L2
L2: jeq  r1 r10 L3
L3: jgt  r1 12 L4
L4: jgt  r1 r10 L5
L5: jge  r1 12 L6
L6: jge  r1 r10 L7
L7: jlt  r1 12 L8
L8: jlt  r1 r10 L9
L9: jle  r1 12 L10
L10: jle  r1 r10 L11
L11: jset r1 12 L12
L12: jset r1 r10 L13
L13: jne  r1 12 L14
L14: jne  r1 r10 L15
L15: jsgt r1 12 L16
L16: jsgt r1 r10 L17
L17: jsge r1 12 L18
L18: jsge r1 r10 L19
L19: jslt r1 12 L20
L20: jslt r1 r10 L21
L21: jsle r1 12 L22
L22: jsle r1 r10 L23
L23: call 12
;rel  12 ; Not supported in this processor

; 32 bit Jump instructions
jal L24 ; Uses immediate
L24: jeq32  r1 12 L25
L25: jeq32  r1 r10 L26
L26: jgt32  r1 12 L27
L27: jgt32  r1 r10 L28
L28: jge32  r1 12 L29
L29: jge32  r1 r10 L30
L30: jlt32  r1 12 L31
L31: jlt32  r1 r10 L32
L32: jle32  r1 12 L33
L33: jle32  r1 r10 L34
L34: jset32 r1 12 L35
L35: jset32 r1 r10 L36
L36: jne32  r1 12 L37
L37: jne32  r1 r10 L38
L38: jsgt32 r1 12 L39
L39: jsgt32 r1 r10 L40
L40: jsge32 r1 12 L41
L41: jsge32 r1 r10 L42
L42: jslt32 r1 12 L43
L43: jslt32 r1 r10 L44
L44: jsle32 r1 12 L45
L45: jsle32 r1 r10 L46
L46:

exit