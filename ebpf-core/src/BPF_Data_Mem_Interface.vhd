--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Data memory interface for a BPF processor IO/MEM system, in
--               order to translate memory and atomic operation requests to
--               Block RAM compatible signals. Also translates addresses.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.bpf.all;

entity BPF_Data_Mem_Interface is
    port (
        clk : in std_logic;
        reset : in std_logic;

        -- input --
        DMEM_addr : in std_logic_vector (63 downto 0);
        DMEM_input : in std_logic_vector (63 downto 0);
        DMEM_write_en : in std_logic;
        DMEM_read_en : in std_logic;
        DMEM_size : in std_logic_vector (1 downto 0);

        DMEM_atomic : in std_logic;
        DMEM_op : in std_logic_vector (3 downto 0);
        DMEM_cmpxchg_token : in std_logic_vector (63 downto 0);
        
        DMEM_ready : out std_logic;
        DMEM_error : out std_logic;
        DMEM_output : out std_logic_vector (63 downto 0);

        -- Translated signals --
        DATAIF_ena : out std_logic;
        DATAIF_addra : out std_logic_vector(11 downto 0);
        DATAIF_dina : out std_logic_vector(63 downto 0);
        DATAIF_douta : in std_logic_vector(63 downto 0);
        DATAIF_wea : out std_logic_vector(7 downto 0);
        DATAIF_shared : out std_logic; -- 'shared' --(implies)-> 'ena'

        -- Arbiter signals --
        ARB_DATA_request : out std_logic;
        ARB_DATA_bus_frame : out std_logic;
        ARB_DATA_granted : in std_logic
    );
end BPF_Data_Mem_Interface;
    
architecture Behavioral of BPF_Data_Mem_Interface is

    component Register_N is
        generic ( SIZE : positive := 64 );
        port (
            clk : in std_logic;
            reset : in std_logic;
            load : in std_logic;
            input : in std_logic_vector (SIZE - 1 downto 0);
            output : out std_logic_vector (SIZE - 1 downto 0)
        );
    end component;

    component Delayed_Register_N is
        generic ( SIZE : positive := 64 );
        port (
            clk : in std_logic;
            reset : in std_logic;
            load : in std_logic;
    
            input : in std_logic_vector (SIZE - 1 downto 0);
            output : out std_logic_vector (SIZE - 1 downto 0)
        );
    end component;

    signal is_mem_shared, is_mem_unshared, is_addr_inside_space, granted, bus_frame, request : std_logic;
    signal translated_addr : std_logic_vector(11 downto 0);
    
    signal go, error, ready, do_write, do_read, do_save, store_modified : std_logic;

    signal write_en, read_en, mem_re, mem_we, is_cmpxchg_op, do_xchg, atomic : std_logic;

    signal din, dout, saved_dout, alu_output, xchg_output : std_logic_vector(63 downto 0);
    signal input, output, operand_A, operand_B : std_logic_vector(63 downto 0);

    signal wea : std_logic_vector(7 downto 0);
    signal size, saved_size : std_logic_vector(1 downto 0);
    signal sel_8b, saved_sel_8b : std_logic_vector(2 downto 0);
    signal sel_16b, saved_sel_16b : std_logic_vector(1 downto 0);
    signal sel_32b, saved_sel_32b : std_logic;

    signal size_info_reg_input, size_info_reg_output : std_logic_vector(4 downto 0);

    type byte_array is array(7 downto 0) of std_logic_vector(7 downto 0);
    signal in_bytes, out_bytes : byte_array;

    type DataMemState_t is (INIT_S, MODIFY_WRITE_S, ERROR_S);
    signal datamem_state, datamem_next_state : DataMemState_t;

begin

    is_addr_inside_space <= '1' when DMEM_addr(63 downto 16) = (47 downto 0 => '0') else '0';
    is_mem_unshared <= '1' when DMEM_addr(15 downto 11) = "10000" or DMEM_addr(15 downto 9) = "1000100" else '0';
    is_mem_shared <= '1' when DMEM_addr(15 downto 12) >= "1001" else '0';

    translated_addr <= "000" & DMEM_addr(11 downto 3) when is_mem_unshared = '1' else DMEM_addr(14 downto 3);

    error <= (write_en or read_en) and not (is_addr_inside_space and (is_mem_unshared or is_mem_shared));
    DMEM_error <= error;
    DMEM_ready <= ready;

    granted <= ARB_DATA_granted;
    ARB_DATA_bus_frame <= bus_frame;
    ARB_DATA_request <= request;

    write_en <= DMEM_write_en;
    read_en <= DMEM_read_en;

    mem_re <= do_read;
    mem_we <= do_write and ((not is_cmpxchg_op) or (is_cmpxchg_op and do_xchg));

    atomic <= DMEM_atomic;

    -- BRAM signals ------------------------------------------------------------
    DATAIF_ena <= mem_re or mem_we;
    DATAIF_addra <= translated_addr;
    DATAIF_shared <= is_mem_shared and (mem_re or mem_we);
    DATAIF_dina <= din;
    dout <= DATAIF_douta;
    DATAIF_wea <= wea;
    ----------------------------------------------------------------------------

    -- Saved info for output (directly used by WB stage)

    read_value_reg: Delayed_Register_N
    --read_value_reg: Register_N
        generic map ( SIZE => 64 )
        port map (
            clk => clk,
            reset => reset,
            load => do_save,
            input => dout,
            output => saved_dout
        );

    size_info_reg: Register_N
        generic map ( SIZE => 5 )
        port map (
            clk => clk,
            reset => reset,
            load => do_save,
            input => size_info_reg_input,
            output => size_info_reg_output
        );

    size_info_reg_input <= size & sel_8b;
    
    saved_size <= size_info_reg_output(4 downto 3);
    saved_sel_8b <= size_info_reg_output(2 downto 0);
    
    saved_sel_16b <= saved_sel_8b(2 downto 1);
    saved_sel_32b <= saved_sel_8b(2);

    -- BYTE EXCHANGE -----------------------------------------------------------
    size <= DMEM_size;
    sel_8b <= DMEM_addr(2 downto 0);
    sel_16b <= sel_8b(2 downto 1);
    sel_32b <= sel_8b(2);

    input <= DMEM_input;

    in_bytes(0) <= input(7 downto 0);
    in_bytes(1) <= input(15 downto 8);
    in_bytes(2) <= input(23 downto 16);
    in_bytes(3) <= input(31 downto 24);
    in_bytes(4) <= input(39 downto 32);
    in_bytes(5) <= input(47 downto 40);
    in_bytes(6) <= input(55 downto 48);
    in_bytes(7) <= input(63 downto 56);
    
    wea(0) <= mem_we when (size = BPF_SIZE8 and sel_8b = "000") or (size = BPF_SIZE16 and sel_16b = "00") or (size = BPF_SIZE32 and sel_32b = '0') or size = BPF_SIZE64 else '0';
    wea(1) <= mem_we when (size = BPF_SIZE8 and sel_8b = "001") or (size = BPF_SIZE16 and sel_16b = "00") or (size = BPF_SIZE32 and sel_32b = '0') or size = BPF_SIZE64 else '0';
    wea(2) <= mem_we when (size = BPF_SIZE8 and sel_8b = "010") or (size = BPF_SIZE16 and sel_16b = "01") or (size = BPF_SIZE32 and sel_32b = '0') or size = BPF_SIZE64 else '0';
    wea(3) <= mem_we when (size = BPF_SIZE8 and sel_8b = "011") or (size = BPF_SIZE16 and sel_16b = "01") or (size = BPF_SIZE32 and sel_32b = '0') or size = BPF_SIZE64 else '0';
    wea(4) <= mem_we when (size = BPF_SIZE8 and sel_8b = "100") or (size = BPF_SIZE16 and sel_16b = "10") or (size = BPF_SIZE32 and sel_32b = '1') or size = BPF_SIZE64 else '0';
    wea(5) <= mem_we when (size = BPF_SIZE8 and sel_8b = "101") or (size = BPF_SIZE16 and sel_16b = "10") or (size = BPF_SIZE32 and sel_32b = '1') or size = BPF_SIZE64 else '0';
    wea(6) <= mem_we when (size = BPF_SIZE8 and sel_8b = "110") or (size = BPF_SIZE16 and sel_16b = "11") or (size = BPF_SIZE32 and sel_32b = '1') or size = BPF_SIZE64 else '0';
    wea(7) <= mem_we when (size = BPF_SIZE8 and sel_8b = "111") or (size = BPF_SIZE16 and sel_16b = "11") or (size = BPF_SIZE32 and sel_32b = '1') or size = BPF_SIZE64 else '0';
    
    xchg_output(7 downto 0)   <= in_bytes(0) when (size = BPF_SIZE8 and sel_8b = "000") else in_bytes(0) when (size = BPF_SIZE16 and sel_16b = "00") else in_bytes(0) when (size = BPF_SIZE32 and sel_32b = '0') else in_bytes(0);
    xchg_output(15 downto 8)  <= in_bytes(0) when (size = BPF_SIZE8 and sel_8b = "001") else in_bytes(1) when (size = BPF_SIZE16 and sel_16b = "00") else in_bytes(1) when (size = BPF_SIZE32 and sel_32b = '0') else in_bytes(1);
    xchg_output(23 downto 16) <= in_bytes(0) when (size = BPF_SIZE8 and sel_8b = "010") else in_bytes(0) when (size = BPF_SIZE16 and sel_16b = "01") else in_bytes(2) when (size = BPF_SIZE32 and sel_32b = '0') else in_bytes(2);
    xchg_output(31 downto 24) <= in_bytes(0) when (size = BPF_SIZE8 and sel_8b = "011") else in_bytes(1) when (size = BPF_SIZE16 and sel_16b = "01") else in_bytes(3) when (size = BPF_SIZE32 and sel_32b = '0') else in_bytes(3);
    xchg_output(39 downto 32) <= in_bytes(0) when (size = BPF_SIZE8 and sel_8b = "100") else in_bytes(0) when (size = BPF_SIZE16 and sel_16b = "10") else in_bytes(0) when (size = BPF_SIZE32 and sel_32b = '1') else in_bytes(4);
    xchg_output(47 downto 40) <= in_bytes(0) when (size = BPF_SIZE8 and sel_8b = "101") else in_bytes(1) when (size = BPF_SIZE16 and sel_16b = "10") else in_bytes(1) when (size = BPF_SIZE32 and sel_32b = '1') else in_bytes(5);
    xchg_output(55 downto 48) <= in_bytes(0) when (size = BPF_SIZE8 and sel_8b = "110") else in_bytes(0) when (size = BPF_SIZE16 and sel_16b = "11") else in_bytes(2) when (size = BPF_SIZE32 and sel_32b = '1') else in_bytes(6);
    xchg_output(63 downto 56) <= in_bytes(0) when (size = BPF_SIZE8 and sel_8b = "111") else in_bytes(1) when (size = BPF_SIZE16 and sel_16b = "11") else in_bytes(3) when (size = BPF_SIZE32 and sel_32b = '1') else in_bytes(7);

    -- BYTE SELECTION ----------------------------------------------------------
    out_bytes(0) <= saved_dout(7 downto 0);
    out_bytes(1) <= saved_dout(15 downto 8);
    out_bytes(2) <= saved_dout(23 downto 16);
    out_bytes(3) <= saved_dout(31 downto 24);
    out_bytes(4) <= saved_dout(39 downto 32);
    out_bytes(5) <= saved_dout(47 downto 40);
    out_bytes(6) <= saved_dout(55 downto 48);
    out_bytes(7) <= saved_dout(63 downto 56);
    
    output(7 downto 0)   <= out_bytes(0) when (saved_size = BPF_SIZE8 and saved_sel_8b = "000") or (saved_size = BPF_SIZE16 and saved_sel_16b = "00") or (saved_size = BPF_SIZE32 and saved_sel_32b = '0') or saved_size = BPF_SIZE64 else
                            out_bytes(1) when (saved_size = BPF_SIZE8 and saved_sel_8b = "001") else
                            out_bytes(2) when (saved_size = BPF_SIZE8 and saved_sel_8b = "010") or (saved_size = BPF_SIZE16 and saved_sel_16b = "01") else
                            out_bytes(3) when (saved_size = BPF_SIZE8 and saved_sel_8b = "011") else
                            out_bytes(4) when (saved_size = BPF_SIZE8 and saved_sel_8b = "100") or (saved_size = BPF_SIZE16 and saved_sel_16b = "10") or (saved_size = BPF_SIZE32 and saved_sel_32b = '1') else
                            out_bytes(5) when (saved_size = BPF_SIZE8 and saved_sel_8b = "101") else
                            out_bytes(6) when (saved_size = BPF_SIZE8 and saved_sel_8b = "110") or (saved_size = BPF_SIZE16 and saved_sel_16b = "11") else
                            out_bytes(7) when (saved_size = BPF_SIZE8 and saved_sel_8b = "111");
                           
    output(15 downto 8)  <= out_bytes(1) when (saved_size = BPF_SIZE16 and saved_sel_16b = "00") or (saved_size = BPF_SIZE32 and saved_sel_32b = '0') or saved_size = BPF_SIZE64 else
                            out_bytes(3) when (saved_size = BPF_SIZE16 and saved_sel_16b = "01") else
                            out_bytes(5) when (saved_size = BPF_SIZE16 and saved_sel_16b = "10") or (saved_size = BPF_SIZE32 and saved_sel_32b = '1') else
                            out_bytes(7) when (saved_size = BPF_SIZE16 and saved_sel_16b = "11") else x"00";

    output(23 downto 16) <= out_bytes(2) when (saved_size = BPF_SIZE32 and saved_sel_32b = '0') or saved_size = BPF_SIZE64 else
                            out_bytes(6) when (saved_size = BPF_SIZE32 and saved_sel_32b = '1') else x"00";
    output(31 downto 24) <= out_bytes(3) when (saved_size = BPF_SIZE32 and saved_sel_32b = '0') or saved_size = BPF_SIZE64 else
                            out_bytes(7) when (saved_size = BPF_SIZE32 and saved_sel_32b = '1') else x"00";
    
    output(39 downto 32) <= out_bytes(4) when saved_size = BPF_SIZE64 else x"00";
    output(47 downto 40) <= out_bytes(5) when saved_size = BPF_SIZE64 else x"00";
    output(55 downto 48) <= out_bytes(6) when saved_size = BPF_SIZE64 else x"00";
    output(63 downto 56) <= out_bytes(7) when saved_size = BPF_SIZE64 else x"00";

    DMEM_output <= output;
    ----------------------------------------------------------------------------


    -- BRAM input multiplexer
    din <= alu_output when store_modified = '1' else xchg_output;

    -- ALU ---------------------------------------------------------------------
    operand_A <= saved_dout;
    operand_B <= input(31 downto 0) & (31 downto 0 => '0') when size = BPF_SIZE32 and sel_32b = '1' else input;

    is_cmpxchg_op <= '1' when DMEM_op = BPF_CMPXCHG and atomic = '1' else '0';
    
    do_xchg <= '1' when DMEM_cmpxchg_token(31 downto 0) = saved_dout(63 downto 32) and size = BPF_SIZE32 and sel_32b = '1' else
               '1' when DMEM_cmpxchg_token = saved_dout else '0';

    alu_output <= operand_A + operand_B when DMEM_op = BPF_ADD and atomic = '1' else
                  operand_A or operand_B when DMEM_op = BPF_OR and atomic = '1' else
                  operand_A and operand_B when DMEM_op = BPF_AND and atomic = '1' else
                  operand_A xor operand_B when DMEM_op = BPF_XOR and atomic = '1' else
                  operand_B;
    ----------------------------------------------------------------------------

    -- Control -----------------------------------------------------------------

    SYNC_PROC: process (clk)
    begin
        if (clk'event and clk = '1') then
            if (reset = '1') then
                datamem_state <= INIT_S;
            else
                datamem_state <= datamem_next_state;
            end if;        
        end if;
    end process;

    MEM_CONTROL: process (datamem_state, read_en, write_en, atomic, size, is_mem_shared, granted, error, request)
    begin
        -- Default values
        datamem_next_state <= datamem_state;

        do_write <= '0';
        do_read <= '0';
        do_save <= '0';
        ready <= '1';
        store_modified <= '0';
        request <= '0';
        bus_frame <= '0';

        if (error = '1') then
            datamem_next_state <= ERROR_S;

        elsif (datamem_state = INIT_S) then
            request <= is_mem_shared and (write_en or read_en);
            
            if (request = '1' and granted = '0') then
                --datamem_next_state <= INIT_S;
                ready <= '0';
            elsif (read_en = '1' and write_en = '0') then
                --datamem_next_state <= INIT_S;
                do_read <= '1';
                do_save <= '1';
                ready <= '1';
            elsif (read_en = '0' and write_en = '1' and atomic = '0') then
                --datamem_next_state <= INIT_S;
                do_write <= '1';
                store_modified <= '0';
                ready <= '1';
            elsif (write_en = '1' and atomic = '1') then
                datamem_next_state <= MODIFY_WRITE_S;
                do_read <= '1';
                do_save <= '1';
                ready <= '0';
            end if;
            
        elsif (datamem_state = MODIFY_WRITE_S) then
            datamem_next_state <= INIT_S;
            do_write <= '1';
            ready <= '1';
            store_modified <= '1';
            bus_frame <= is_mem_shared;
        end if;
        
    end process;
end Behavioral;
