#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include <sys/_intsup.h>

#include "xil_printf.h"

#include "ebpf_lib.h"

#define PRINT_ENABLE 1

#define PRINT(fmt, ...) \
{ \
    if (PRINT_ENABLE) \
        xil_printf(fmt, ##__VA_ARGS__); \
}

bpf_instruction_t program[] = 
    {
        #include "programs/test_mem.txt"
    };

int main()
{
    int end_cause;
    uint64_t result;

    init_platform();

    PRINT("Loading program...\n\r");

    if (bpf_load_program(program, sizeof(program)/sizeof(bpf_instruction_t)) < 0)
    {
        PRINT("FAIL\n\r");
        goto exit_point;
    }

    PRINT("OK\n\r");
    PRINT("Start of execution\n\r");

    bpf_start_program();
    
    end_cause = bpf_await_program();
    result = bpf_core_get_program_result();

    if (end_cause == BPF_FINISH)
    {
        PRINT("Program finished with result: %llx\n\r", result);
    }
    else {
        PRINT("Program threw an exception at PC = %llu\n\r", result);
    }
        
exit_point:
    cleanup_platform();
    return 0;
}