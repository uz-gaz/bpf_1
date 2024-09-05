# eBPF Assembler

This is a fork from [emilmasoumi/ebpf-assembler](https://github.com/emilmasoumi/ebpf-assembler/tree/2d61982decd00b34e87a8a33aa44a218faec5812) with added support for all non-legacy nor 64-bit immediate instructions (except for `ld64`) present in [Linux's eBPF ISA specification](https://www.kernel.org/doc/html/latest/bpf/standardization/instruction-set.html).


A disassembler is provided and can be used with:
```bash
./disas-ebpf <file-with-object-code>
```

Symbolic names are resolved during parsing and the bytecode is statically type checked during compile time.

Instructions that have 32-bit equivalents are suffixed with `32`. For example:
`mov32 r0 8` or `jne32 r1 r2 label`. 

--------
##### Building:
```bash
make
```

--------
##### Usage:
```bash
./ebpf-as <source> [options]
options:
    {-o --output} <arg>:
        Output to the succeeding argument.
    {-h --help}:
        Print this usage message.
```

--------
##### Example:
```bash
    mov r1 64     ; comment
    mov32 r2 32
    jlt r2 r1 end
    jge r1 r2 end
loop:
    sub r1 1
    add32 r2 1
    jle r1 r2 loop
    end:
    mov r0 0
    exit
```

#### ALU instructions:

##### 64-bit:

| Mnemonic         | Pseudocode
|------------------|-------------------------
|` add dst imm      `|` dst += imm`
|` add dst src      `|` dst += src`
|` sub dst imm      `|` dst -= imm`
|` sub dst src      `|` dst -= src`
|` mul dst imm      `|` dst *= imm`
|` mul dst src      `|` dst *= src`
|` div dst imm      `|` dst /= imm [unsigned]`
|` div dst src      `|` dst /= src [unsigned]`
|` sdiv dst imm     `|` dst /= imm [signed]`
|` sdiv dst src     `|` dst /= src [signed]`
|` mod dst imm      `|` dst %= imm [unsigned]`
|` mod dst src      `|` dst %= src [unsigned]`
|` smod dst imm     `|` dst %= imm [signed]`
|` smod dst src     `|` dst %= src [signed]`
|` or dst imm       `| dst |`= imm`
|` or dst src       `| dst |`= src`
|` and dst imm      `|` dst &= imm`
|` and dst src      `|` dst &= src`
|` lsh dst imm      `|` dst <<= imm`
|` lsh dst src      `|` dst <<= src`
|` rsh dst imm      `|` dst >>= imm [logical]`
|` rsh dst src      `|` dst >>= src [logical]`
|` arsh dst imm     `|` dst >>= imm [arithmetic]`
|` arsh dst src     `|` dst >>= src [arithmetic]`
|` neg dst          `|` dst = dst`
|` xor dst imm      `|` dst ^= imm`
|` xor dst src      `|` dst ^= src`
|` mov dst imm      `|` dst = imm`
|` mov dst src      `|` dst = src`
|` movsx8 dst imm   `|` dst = *(int8_t *) imm`
|` movsx8 dst src   `|` dst = *(int8_t *) src`
|` movsx16 dst imm  `|` dst = *(int16_t *) imm`
|` movsx16 dst src  `|` dst = *(int16_t *) src`
|` movsx32 dst imm  `|` dst = *(int32_t *) imm`
|` movsx32 dst src  `|` dst = *(int32_t *) src`
-----------------------------------------

##### 32-bit:
| Mnemonic           | Pseudocode
|--------------------|-------------------------
|` add32 dst imm      `|` dst += imm`
|` add32 dst src      `|` dst += src`
|` sub32 dst imm      `|` dst -= imm`
|` sub32 dst src      `|` dst -= src`
|` mul32 dst imm      `|` dst *= imm`
|` mul32 dst src      `|` dst *= src`
|` div32 dst imm      `|` dst /= imm [unsigned]`
|` div32 dst src      `|` dst /= src [unsigned]`
|` sdiv32 dst imm     `|` dst /= imm [signed]`
|` sdiv32 dst src     `|` dst /= src [signed]`
|` mod32 dst imm      `|` dst %= imm [unsigned]`
|` mod32 dst src      `|` dst %= src [unsigned]`
|` smod32 dst imm     `|` dst %= imm [signed]`
|` smod32 dst src     `|` dst %= src [signed]`
|` or32 dst imm       `| dst |`= imm`
|` or32 dst src       `| dst |`= src`
|` and32 dst imm      `|` dst &= imm`
|` and32 dst src      `|` dst &= src`
|` lsh32 dst imm      `|` dst <<= imm`
|` lsh32 dst src      `|` dst <<= src`
|` rsh32 dst imm      `|` dst >>= imm [logical]`
|` rsh32 dst src      `|` dst >>= src [logical]`
|` arsh32 dst imm     `|` dst >>= imm [arithmetic]`
|` arsh32 dst src     `|` dst >>= src [arithmetic]`
|` neg32 dst          `|` dst = dst`
|` xor32 dst imm      `|` dst ^= imm`
|` xor32 dst src      `|` dst ^= src`
|` mov32 dst imm      `|` dst = imm`
|` mov32 dst src      `|` dst = src`
|` mov32sx8 dst imm   `|` dst = *(int8_t *) imm`
|` mov32sx8 dst src   `|` dst = *(int8_t *) src`
|` mov32sx16 dst imm  `|` dst = *(int16_t *) imm`
|` mov32sx16 dst src  `|` dst = *(int16_t *) src`
-------------------------------------------

#### Endianess conversion (Byteswap) instructions:
| Mnemonic    | Pseudocode
|-------------|-------------------
|` le16 dst    `|` dst = host_to_little_endian16(dst)`
|` le32 dst    `|` dst = host_to_little_endian32(dst)`
|` le64 dst    `|` dst = host_to_little_endian64(dst)`
|` be16 dst    `|` dst = host_to_big_endian16(dst)`
|` be32 dst    `|` dst = host_to_big_endian32(dst)`
|` be64 dst    `|` dst = host_to_big_endian64(dst)`
|` bswap16 dst `|` dst = byte_swap16(dst)`
|` bswap32 dst `|` dst = byte_swap32(dst)`
|` bswap64 dst `|` dst = byte_swap64(dst)`
-------------------------------

#### Atomic operations:
| Mnemonic               | Pseudocode
|------------------------|--------------------------------------------
|` addx32 dst src off     `|` *(uint32_t *) (dst + off16) += src`
|` addx64 dst src off     `|` *(uint64_t *) (dst + off16) += src`
|` andx32 dst src off     `|` *(uint32_t *) (dst + off16) &= src`
|` andx64 dst src off     `|` *(uint64_t *) (dst + off16) &= src`
|` orx32 dst src off      | *(uint32_t *) (dst + off16) `|`= src`
|` orx64 dst src off      | *(uint64_t *) (dst + off16) `|`= src`
|` xorx32 dst src off     `|` *(uint32_t *) (dst + off16) ^= src`
|` xorx64 dst src off     `|` *(uint64_t *) (dst + off16) ^= src`
|` addfx32 dst src off    `|` src = atomic_fetch_add32(dst + off16, src)`
|` addfx64 dst src off    `|` src = atomic_fetch_add64(dst + off16, src)`
|` andfx32 dst src off    `|` src = atomic_fetch_and32(dst + off16, src)`
|` andfx64 dst src off    `|` src = atomic_fetch_and64(dst + off16, src)`
|` orfx32 dst src off     `|` src = atomic_fetch_or32(dst + off16, src)`
|` orfx64 dst src off     `|` src = atomic_fetch_or64(dst + off16, src)`
|` xorfx32 dst src off    `|` src = atomic_fetch_xor32(dst + off16, src)`
|` xorfx64 dst src off    `|` src = atomic_fetch_xor64(dst + off16, src)`
|` xchgx32 dst src off    `|` src = atomic_xchg32(dst + off16, src)`
|` xchgx64 dst src off    `|` src = atomic_xchg64(dst + off16, src)`
|` cmpxchgx32 dst src off `|` r0 = atomic_cmpxchg32(dst + off16, r0, src)`
|` cmpxchgx64 dst src off `|` r0 = atomic_cmpxchg64(dst + off16, r0, src)`
----------------------------------------------------------------------

#### Memory instructions:
| Mnemonic            | Pseudocode
|---------------------|-------------------------------------------
|` ld64 dst imm        `|` dst = imm [64b immediate]`
|` ldx8 dst src off    `|` dst = *(uint8_t *) (src + off)`
|` ldx16 dst src off   `|` dst = *(uint16_t *) (src + off)`
|` ldx32 dst src off   `|` dst = *(uint32_t *) (src + off)`
|` ldx64 dst src off   `|` dst = *(uint64_t *) (src + off)`
|` ldxs8 dst src off   `|` dst = *(int8_t *) (src + off)`
|` ldxs16 dst src off  `|` dst = *(int64_t *) (src + off)`
|` ldxs32 dst src off  `|` dst = *(int32_t *) (src + off)`
|` st8 dst off imm     `|` *(uint8_t *) (dst + off) = imm`
|` st16 dst off imm    `|` *(uint16_t *) (dst + off) = imm`
|` st32 dst off imm    `|` *(uint32_t *) (dst + off) = imm`
|` st64 dst off imm    `|` *(uint64_t *) (dst + off) = imm`
|` stx8 dst src off    `|` *(uint8_t *) (dst + off) = src`
|` stx16 dst src off   `|` *(uint16_t *) (dst + off) = src`
|` stx32 dst src off   `|` *(uint32_t *) (dst + off) = src`
|` stx64 dst src off   `|` *(uint64_t *) (dst + off) = src`
|` stxx8 dst src off   `|` *(uint8_t *) (dst + off16) += src`
|` stxx16 dst src off  `|` *(uint16_t *) (dst + off16) += src`
|` stxx32 dst src off  `|` *(uint32_t *) (dst + off16) += src`
|` stxx64 dst src off  `|` *(uint64_t *) (dst + off16) += src`
--------------------------------------------------------------------

#### Branch instructions:

##### 64-bit:
| Mnemonic         | Pseudocode
|------------------|-------------------------------------------
|` ja off           `|` PC += off ; Jump Always`
|` jeq dst imm off  `|` PC += off if dst == imm`
|` jeq dst src off  `|` PC += off if dst == src`
|` jgt dst imm off  `|` PC += off if dst > imm`
|` jgt dst src off  `|` PC += off if dst > src`
|` jge dst imm off  `|` PC += off if dst >= imm`
|` jge dst src off  `|` PC += off if dst >= src`
|` jlt dst imm off  `|` PC += off if dst < imm`
|` jlt dst src off  `|` PC += off if dst < src`
|` jle dst imm off  `|` PC += off if dst <= imm`
|` jle dst src off  `|` PC += off if dst <= src`
|` jset dst imm off `|` PC += off if dst & imm`
|` jset dst src off `|` PC += off if dst & src`
|` jne dst imm off  `|` PC += off if dst != imm`
|` jne dst src off  `|` PC += off if dst != src`
|` jsgt dst imm off `|` PC += off if dst > imm [signed]`
|` jsgt dst src off `|` PC += off if dst > src [signed]`
|` jsge dst imm off `|` PC += off if dst >= imm [signed]`
|` jsge dst src off `|` PC += off if dst >= src [signed]`
|` jslt dst imm off `|` PC += off if dst < imm [signed]`
|` jslt dst src off `|` PC += off if dst < src [signed]`
|` jsle dst imm off `|` PC += off if dst <= imm [signed]`
|` jsle dst src off `|` PC += off if dst <= src [signed]`
|` call imm         `|` r0 = f(r1, r2, ..., r5); Function call`
|` rel imm          `|` r0 = f(r1, r2, ..., r5); Relative function call`
|` exit             `|` return r0; Return from function or exit program`
---------------------------------------------------------------

##### 32-bit:
| Mnemonic           | Pseudocode
|--------------------|---------------------------------
|` jal imm            `|` PC += imm ; Jump Always (Long Offset)`
|` jeq32 dst imm off  `|` PC += off if dst == imm`
|` jeq32 dst src off  `|` PC += off if dst == src`
|` jgt32 dst imm off  `|` PC += off if dst > imm`
|` jgt32 dst src off  `|` PC += off if dst > src`
|` jge32 dst imm off  `|` PC += off if dst >= imm`
|` jge32 dst src off  `|` PC += off if dst >= src`
|` jlt32 dst imm off  `|` PC += off if dst < imm`
|` jlt32 dst src off  `|` PC += off if dst < src`
|` jle32 dst imm off  `|` PC += off if dst <= imm`
|` jle32 dst src off  `|` PC += off if dst <= src`
|` jset32 dst imm off `|` PC += off if dst & imm`
|` jset32 dst src off `|` PC += off if dst & src`
|` jne32 dst imm off  `|` PC += off if dst != imm`
|` jne32 dst src off  `|` PC += off if dst != src`
|` jsgt32 dst imm off `|` PC += off if dst > imm [signed]`
|` jsgt32 dst src off `|` PC += off if dst > src [signed]`
|` jsge32 dst imm off `|` PC += off if dst >= imm [signed]`
|` jsge32 dst src off `|` PC += off if dst >= src [signed]`
|` jslt32 dst imm off `|` PC += off if dst < imm [signed]`
|` jslt32 dst src off `|` PC += off if dst < src [signed]`
|` jsle32 dst imm off `|` PC += off if dst <= imm [signed]`
|` jsle32 dst src off `|` PC += off if dst <= src [signed]`
--------------------------------------------------------
