--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Data memory interface for a BPF processor.
--
-- Comm:         This component is replaced by "BPF_Data_Mem_Interface" when
--               using real BRAM IPs, but can be useful to test isolated core.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.bpf.all;

entity BPF_Mem_Interface is
    port (
        clk : in std_logic;
        reset : in std_logic;

        -- Memory access interface
        addr : in std_logic_vector (63 downto 0);
        input : in std_logic_vector (63 downto 0);
        write_en : in std_logic;
        read_en : in std_logic;
        size : in std_logic_vector (1 downto 0);

        -- Atomic operations interface
        atomic : in std_logic;
        op : in std_logic_vector (3 downto 0);
        cmpxchg_token : in std_logic_vector (63 downto 0);
        
        ready : out std_logic;
        output : out std_logic_vector (63 downto 0)
    );
end BPF_Mem_Interface;

architecture Behavioral of BPF_Mem_Interface is

    component Stack_RAM is
        port (
            clk : in std_logic;
            addr : in std_logic_vector (5 downto 0);
            input : in std_logic_vector (63 downto 0);
            write_en : in std_logic;
            read_en : in std_logic;
            output : out std_logic_vector (63 downto 0)
        );
    end component;

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


    signal do_read, do_write, do_xchg, do_save, store_modified : std_logic;

    signal alu_output, ram_input, ram_output : std_logic_vector (63 downto 0);
    signal alu_raw_output, read_word, read_value : std_logic_vector (63 downto 0);

    signal is_cmpxchg_op : std_logic;

    signal mem_re, mem_we : std_logic;

    signal sel_8b : std_logic_vector(2 downto 0);
    signal sel_16b : std_logic_vector(1 downto 0);
    signal sel_32b : std_logic;

    signal read_value_8b : std_logic_vector(7 downto 0);
    signal read_value_16b : std_logic_vector(15 downto 0);
    signal read_value_32b : std_logic_vector(31 downto 0);

    signal alu_output_8b : std_logic_vector(63 downto 0);
    signal alu_output_16b : std_logic_vector(63 downto 0);
    signal alu_output_32b : std_logic_vector(63 downto 0);


    signal raw_saved_size : std_logic_vector(4 downto 0);
    signal saved_size : std_logic_vector(1 downto 0);

    signal saved_sel_8b : std_logic_vector(2 downto 0);
    signal saved_sel_16b : std_logic_vector(1 downto 0);
    signal saved_sel_32b : std_logic;

    signal saved_value_8b : std_logic_vector(7 downto 0);
    signal saved_value_16b : std_logic_vector(15 downto 0);
    signal saved_value_32b : std_logic_vector(31 downto 0);

    
    type State_t is (INIT, MODIFY_WRITE);
    signal state, next_state : State_t;

begin

    ram_input <= alu_output when store_modified = '1' else input;

    is_cmpxchg_op <= '1' when op = BPF_CMPXCHG and atomic = '1' else '0';

    mem_re <= do_read;
    mem_we <= do_write and ((not is_cmpxchg_op) or (is_cmpxchg_op and do_xchg));

    stack_memory: Stack_RAM
        port map (
            clk => clk,
            addr => addr(8 downto 3),
            input => ram_input,
            write_en => mem_we,
            read_en => mem_re,
            output => ram_output
        );

    read_value_reg: Register_N
        generic map ( SIZE => 64 )
        port map (
            clk => clk,
            reset => reset,
            load => do_save,
            input => ram_output,
            output => read_word
        );

    size_info_reg: Register_N
        generic map ( SIZE => 5 )
        port map (
            clk => clk,
            reset => reset,
            load => do_save,
            input => size & sel_8b,
            output => raw_saved_size
        );

    do_xchg <= '1' when cmpxchg_token = read_value and size = BPF_SIZE64 else
               '1' when cmpxchg_token(31 downto 0) = read_value(31 downto 0) and size = BPF_SIZE32 else '0';

    alu_raw_output <= read_value + input when op = BPF_ADD and atomic = '1' else
                      read_value or input when op = BPF_OR and atomic = '1' else
                      read_value and input when op = BPF_AND and atomic = '1' else
                      read_value xor input when op = BPF_XOR and atomic = '1' else
                      input;

    -- Byte selector -----------------------------------------------------------

    sel_8b <= addr(2 downto 0);
    sel_16b <= addr(2 downto 1);
    sel_32b <= addr(2);

    saved_sel_8b <= raw_saved_size(2 downto 0);
    saved_sel_16b <= raw_saved_size(2 downto 1);
    saved_sel_32b <= raw_saved_size(2);

    saved_size <= raw_saved_size(4 downto 3);

    saved_value_8b <= read_word(7 downto 0)   when saved_sel_8b = "000" else
                      read_word(15 downto 8)  when saved_sel_8b = "001" else
                      read_word(23 downto 16) when saved_sel_8b = "010" else
                      read_word(31 downto 24) when saved_sel_8b = "011" else
                      read_word(39 downto 32) when saved_sel_8b = "100" else
                      read_word(47 downto 40) when saved_sel_8b = "101" else
                      read_word(55 downto 48) when saved_sel_8b = "110" else
                      read_word(63 downto 56) when saved_sel_8b = "111";

    saved_value_16b <= read_word(15 downto 0)  when saved_sel_16b = "00" else
                       read_word(31 downto 16) when saved_sel_16b = "01" else
                       read_word(47 downto 32) when saved_sel_16b = "10" else
                       read_word(63 downto 48) when saved_sel_16b = "11";
    
    saved_value_32b <= read_word(31 downto 0)  when saved_sel_32b = '0' else
                       read_word(63 downto 32) when saved_sel_32b = '1';

    read_value <= (55 downto 0 => '0') & saved_value_8b when saved_size = BPF_SIZE8 else
                  (47 downto 0 => '0') & saved_value_16b when saved_size = BPF_SIZE16 else
                  (31 downto 0 => '0') & saved_value_32b when saved_size = BPF_SIZE32 else
                  read_word when saved_size = BPF_SIZE64;

    output <= read_value;

    -- Byte exchanger ----------------------------------------------------------

    alu_output_8b(7 downto 0)   <= alu_raw_output(7 downto 0) when sel_8b = "000" else read_word(7 downto 0);
    alu_output_8b(15 downto 8)  <= alu_raw_output(7 downto 0) when sel_8b = "001" else read_word(15 downto 8);
    alu_output_8b(23 downto 16) <= alu_raw_output(7 downto 0) when sel_8b = "010" else read_word(23 downto 16);
    alu_output_8b(31 downto 24) <= alu_raw_output(7 downto 0) when sel_8b = "011" else read_word(31 downto 24);
    alu_output_8b(39 downto 32) <= alu_raw_output(7 downto 0) when sel_8b = "100" else read_word(39 downto 32);
    alu_output_8b(47 downto 40) <= alu_raw_output(7 downto 0) when sel_8b = "101" else read_word(47 downto 40);
    alu_output_8b(55 downto 48) <= alu_raw_output(7 downto 0) when sel_8b = "110" else read_word(55 downto 48);
    alu_output_8b(63 downto 56) <= alu_raw_output(7 downto 0) when sel_8b = "111" else read_word(63 downto 56);

    alu_output_16b(15 downto 0)  <= alu_raw_output(15 downto 0) when sel_16b = "00" else read_word(15 downto 0);
    alu_output_16b(31 downto 16) <= alu_raw_output(15 downto 0) when sel_16b = "01" else read_word(31 downto 16);
    alu_output_16b(47 downto 32) <= alu_raw_output(15 downto 0) when sel_16b = "10" else read_word(47 downto 32);
    alu_output_16b(63 downto 48) <= alu_raw_output(15 downto 0) when sel_16b = "11" else read_word(63 downto 48);

    alu_output_32b(31 downto 0)  <= alu_raw_output(31 downto 0) when sel_32b = '0' else read_word(31 downto 0);
    alu_output_32b(63 downto 32) <= alu_raw_output(31 downto 0) when sel_32b = '1' else read_word(63 downto 32);

    alu_output <= alu_output_8b when size = BPF_SIZE8 else
                  alu_output_16b when size = BPF_SIZE16 else
                  alu_output_32b when size = BPF_SIZE32 else
                  alu_raw_output when size = BPF_SIZE64;
  
    ----------------------------------------------------------------------------

    -- Control -----------------------------------------------------------------

    SYNC_PROC: process (clk)
    begin
       if (clk'event and clk = '1') then
          if (reset = '1') then
             state <= INIT;
          else
             state <= next_state;
          end if;        
       end if;
    end process;

    MEM_CONTROL: process (state, read_en, write_en, atomic, size)
    begin
        -- Default values
        do_write <= '0';
        do_read <= '0';
        do_save <= '0';
        ready <= '1';
        store_modified <= '0';

        if (state = INIT) then

            -- STORE 64b
            if (read_en = '0' and write_en = '1' and atomic = '0' and size = BPF_SIZE64) then
                --next_state <= INIT;
                do_write <= '1';
                ready <= '1';
                store_modified <= '0';

            -- LOAD
            elsif (read_en = '1' and write_en = '0') then
                --next_state <= INIT;
                do_read <= '1';
                do_save <= '1';
                ready <= '1';

            -- STORE < 64b | ATOMIC
            elsif (write_en = '1') then
                next_state <= MODIFY_WRITE;
                do_read <= '1';
                do_save <= '1';
                ready <= '0';
            end if;
            
        elsif (state = MODIFY_WRITE) then
            next_state <= INIT;
            do_write <= '1';
            ready <= '1';
            store_modified <= '1';
        end if;
    end process;   

end Behavioral;
