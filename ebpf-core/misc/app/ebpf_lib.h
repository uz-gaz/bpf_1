#ifndef __EBPF_LIB_H_
#define __EBPF_LIB_H_

#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <sys/_types.h>

#include "platform.h"
#include "xparameters.h"


uint8_t bpf_axi_read_8b(size_t addr)
{
    return *(volatile uint8_t *) (XPAR_BPF_AXI_PERIPHERAL_0_BASEADDR + addr);
}

uint16_t bpf_axi_read_16b(size_t addr)
{
    return *(volatile uint16_t *) (XPAR_BPF_AXI_PERIPHERAL_0_BASEADDR + addr);
}

uint32_t bpf_axi_read_32b(size_t addr)
{
    return *(volatile uint32_t *) (XPAR_BPF_AXI_PERIPHERAL_0_BASEADDR + addr);
}

uint64_t bpf_axi_read_64b(size_t addr)
{
    return *(volatile uint64_t *) (XPAR_BPF_AXI_PERIPHERAL_0_BASEADDR + addr);
}

void bpf_axi_write_8b(size_t addr, uint8_t value)
{
    *(volatile uint8_t *) (XPAR_BPF_AXI_PERIPHERAL_0_BASEADDR + addr) = value;
}

void bpf_axi_write_16b(size_t addr, uint16_t value)
{
    *(volatile uint16_t *) (XPAR_BPF_AXI_PERIPHERAL_0_BASEADDR + addr) = value;
}

void bpf_axi_write_32b(size_t addr, uint32_t value)
{
    *(volatile uint32_t *) (XPAR_BPF_AXI_PERIPHERAL_0_BASEADDR + addr) = value;
}

void bpf_axi_write_64b(size_t addr, uint64_t value)
{
    *(volatile uint64_t *) (XPAR_BPF_AXI_PERIPHERAL_0_BASEADDR + addr) = value;
}



enum bpf_peripheral_address
{
    BPF_MEM_INST_BASE   = 0x0000,
    BPF_MEM_PACKET_BASE = 0x8000,
    BPF_MEM_STACK_BASE  = 0x8800,
    BPF_MEM_SHARED_BASE = 0x9000,
    BPF_MEM_SHARED_FLUSH_BUFFER = 0x8FFF,
    
    BPF_CORE_CTRL   = 0x8A00,
    BPF_CORE_INPUT  = 0x8A08,
    BPF_CORE_OUTPUT = 0x8A10,

    BPF_MAP_BASE    = 0x8A18,

    BPF_FRAME_POINTER = 0x89F8
};

struct bpf_core_ctrl_reg
{
    unsigned reg_dst : 4;
    unsigned reg_write : 1;
    unsigned sleep : 1;
    unsigned sleeping : 1;
    unsigned exception : 1;
    unsigned finish : 1;
    unsigned reset : 1;
    uint64_t __padding : 54;
};

struct bpf_core_ctrl_reg bpf_core_get_ctrl_reg()
{
    struct bpf_core_ctrl_reg ctrl_reg;
    uint64_t value = bpf_axi_read_64b(BPF_CORE_CTRL);
    memcpy(&ctrl_reg, &value, sizeof(uint64_t));
    return ctrl_reg;
}

void bpf_core_set_ctrl_reg(struct bpf_core_ctrl_reg ctrl_reg)
{
    uint64_t value;
    memcpy(&value, &ctrl_reg, sizeof(uint64_t));
    bpf_axi_write_64b(BPF_CORE_CTRL, value);
}



typedef uint64_t bpf_instruction_t;

int bpf_load_program(bpf_instruction_t* program, int length)
{
    struct bpf_core_ctrl_reg ctrl_reg = bpf_core_get_ctrl_reg();
    if (!(ctrl_reg.finish || ctrl_reg.exception || ctrl_reg.sleeping))
        return -1;

    for (int i = 0; i < length; ++i)
        bpf_axi_write_64b(BPF_MEM_INST_BASE + 8*i, program[i]);
    
    return 0;
}


void bpf_start_program()
{
    struct bpf_core_ctrl_reg ctrl_reg;

    // Start over
    ctrl_reg.reset = 1;
    bpf_core_set_ctrl_reg(ctrl_reg);
    
    // Load frame pointer
    ctrl_reg.reset = 0;
    ctrl_reg.sleep = 1;
    ctrl_reg.reg_write = 1;
    ctrl_reg.reg_dst = 10;
    bpf_core_set_ctrl_reg(ctrl_reg);
    bpf_axi_write_64b(BPF_CORE_INPUT, BPF_FRAME_POINTER);

    // Start execution
    ctrl_reg.sleep = 0;
    ctrl_reg.reg_write = 0;
    bpf_core_set_ctrl_reg(ctrl_reg);
}

void bpf_sleep_program()
{
    struct bpf_core_ctrl_reg ctrl_reg = bpf_core_get_ctrl_reg();
    if (ctrl_reg.finish || ctrl_reg.exception || ctrl_reg.sleeping)
        return;

    ctrl_reg.reset = 0;
    ctrl_reg.sleep = 1;
    ctrl_reg.reg_write = 0;
    bpf_core_set_ctrl_reg(ctrl_reg);

    // Await until processor stops
    while (!(ctrl_reg.finish || ctrl_reg.exception || ctrl_reg.sleeping)) 
        ctrl_reg = bpf_core_get_ctrl_reg();
}

int bpf_awake_program()
{
    struct bpf_core_ctrl_reg ctrl_reg = bpf_core_get_ctrl_reg();
    if (ctrl_reg.finish || ctrl_reg.exception)
        return -1;

    ctrl_reg.sleep = 0;
    bpf_core_set_ctrl_reg(ctrl_reg);

    return 0;
}

enum bpf_program_end_cause
{
    BPF_FINISH = 0,
    BPF_EXCEPTION = -1
};

int bpf_await_program()
{
    struct bpf_core_ctrl_reg ctrl_reg = bpf_core_get_ctrl_reg();
    while (!(ctrl_reg.finish || ctrl_reg.exception || ctrl_reg.sleeping)) 
        ctrl_reg = bpf_core_get_ctrl_reg();
    
    if (ctrl_reg.finish)
        return BPF_FINISH;
    else
        return BPF_EXCEPTION;
}

uint64_t bpf_core_get_program_result()
{
    return bpf_axi_read_64b(BPF_CORE_OUTPUT);
}



enum bpf_map_type
{
    BPF_MAP_TYPE_ARRAY
};

struct bpf_map_entry
{
    unsigned base_ptr : 12;
    unsigned key_size : 2;
    unsigned val_size : 2;
    unsigned max_entries : 15;
    unsigned valid : 1;
};

struct bpf_map_entry _bpf_map_get_entry(size_t id)
{
    struct bpf_map_entry map_reg;
    uint32_t value = bpf_axi_read_32b(BPF_MAP_BASE + (4 * id));
    memcpy(&map_reg, &value, sizeof(uint32_t));
    return map_reg;
}

void _bpf_map_set_entry(struct bpf_map_entry map_reg, size_t id)
{
    uint32_t value;
    memcpy(&value, &map_reg, sizeof(uint32_t));
    bpf_axi_write_32b(BPF_MAP_BASE, value + (4 * id));
}

enum bpf_map_alloc_state
{
    BPF_MAP_ALLOC_STATE_HALF_TOP, 
    BPF_MAP_ALLOC_STATE_HALF_BOT, 
    BPF_MAP_ALLOC_STATE_FULL, 
    BPF_MAP_ALLOC_STATE_EMPTY
};

const unsigned BPF_MAP_MAX_SIZE = 3584 * 8; // bytes
// TODO: these should be on a different file .c
unsigned bpf_map_next_ptr_v = 0;
enum bpf_map_alloc_state bpf_map_alloc_state_v = 0;

unsigned _bpf_compact_size(unsigned sz)
{
    switch (sz) {
        case 8:  return 0;
        case 16: return 1;
        case 32: return 2;
        case 64: return 3;
        default: return 0;
    }
}

uint64_t _bpf_mask_from_size(unsigned sz)
{
    switch (sz) {
        case 0: return 0x000000FF;
        case 1: return 0x0000FFFF;
        case 2: return 0x00FFFFFF;
        case 3: return 0xFFFFFFFF;
        default: return 0;
    }
}

int bpf_create_map(enum bpf_map_type type, unsigned key_size, unsigned val_size, unsigned max_entries)
{
    struct bpf_map_entry map_reg;
    unsigned aux_next_ptr, id;
    map_reg.base_ptr = bpf_map_next_ptr_v / 8;

    if (type != BPF_MAP_TYPE_ARRAY)
        return -1;

    aux_next_ptr = bpf_map_next_ptr_v + (val_size * max_entries / 8) * 8; // align 8 bytes
    if (aux_next_ptr > BPF_MAP_MAX_SIZE)
        return -1;

    switch (bpf_map_alloc_state_v) {
    case BPF_MAP_ALLOC_STATE_EMPTY:

        id = 0;
        bpf_map_next_ptr_v = aux_next_ptr; 
        if (bpf_map_next_ptr_v == BPF_MAP_MAX_SIZE)
            bpf_map_alloc_state_v = BPF_MAP_ALLOC_STATE_FULL;
        else
            bpf_map_alloc_state_v = BPF_MAP_ALLOC_STATE_HALF_TOP;

        break;
    case BPF_MAP_ALLOC_STATE_HALF_TOP:

        id = 1;
        bpf_map_next_ptr_v = aux_next_ptr; 
        bpf_map_alloc_state_v = BPF_MAP_ALLOC_STATE_FULL;

        break;
    case BPF_MAP_ALLOC_STATE_HALF_BOT:

        id = 0;
        bpf_map_next_ptr_v = aux_next_ptr; 
        bpf_map_alloc_state_v = BPF_MAP_ALLOC_STATE_FULL;

        break;
    case BPF_MAP_ALLOC_STATE_FULL:
        return -1;
    default:
        return -1;
    }

    map_reg.valid = 1;
    map_reg.key_size = _bpf_compact_size(key_size);
    map_reg.val_size = _bpf_compact_size(val_size);
    map_reg.max_entries = max_entries;
    _bpf_map_set_entry(map_reg, id);

    return id;
}

int bpf_delete_map(unsigned id)
{
    struct bpf_map_entry map_reg;

    if (id >= 2)
        return -1;

    switch (bpf_map_alloc_state_v) {
    case BPF_MAP_ALLOC_STATE_EMPTY:
        return -1;
    case BPF_MAP_ALLOC_STATE_HALF_TOP:

        if (id != 0)
            return -1;

        bpf_map_next_ptr_v = 0; 
        bpf_map_alloc_state_v = BPF_MAP_ALLOC_STATE_EMPTY;

        break;
    case BPF_MAP_ALLOC_STATE_HALF_BOT:

        if (id != 1)
            return -1;

        bpf_map_next_ptr_v = 0; 
        bpf_map_alloc_state_v = BPF_MAP_ALLOC_STATE_EMPTY;

        break;
    case BPF_MAP_ALLOC_STATE_FULL:

        map_reg = _bpf_map_get_entry(id);
        
        if (id == 1)
        {
            bpf_map_next_ptr_v = map_reg.base_ptr * 8; 
            bpf_map_alloc_state_v = BPF_MAP_ALLOC_STATE_HALF_TOP;
        }
        else // id == 0
        {
            bpf_map_next_ptr_v = 0; 
            bpf_map_alloc_state_v = BPF_MAP_ALLOC_STATE_HALF_BOT;
        }
        break;
    default:
        return -1;
    }

    map_reg.valid = 0;  
    _bpf_map_set_entry(map_reg, id);

    return 0;
}

void *bpf_lookup_elem(unsigned id, uint64_t key)
{
    struct bpf_map_entry map_reg;
    uint64_t key_masked;
    size_t elem_ptr;    

    if (id >= 2)
        return NULL;

    map_reg = _bpf_map_get_entry(id);

    if (!map_reg.valid)
        return NULL;

    key_masked = key & _bpf_mask_from_size(map_reg.key_size);

    if (key_masked >= map_reg.max_entries)
        return NULL;

    elem_ptr = (map_reg.base_ptr * 8) + (key_masked << map_reg.val_size);

    return (void *) (XPAR_BPF_AXI_PERIPHERAL_0_BASEADDR + elem_ptr);
}

#endif