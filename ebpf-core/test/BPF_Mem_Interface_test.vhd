--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Unit test for BPF_Mem_Interface.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.bpf.all;

entity BPF_Mem_Interface_Testbench is
end BPF_Mem_Interface_Testbench;

architecture Behavioral of BPF_Mem_Interface_Testbench is

    component BPF_Mem_Interface is
        port (
            clk : in std_logic;
            reset : in std_logic;
    
            addr : in std_logic_vector (63 downto 0);
            input : in std_logic_vector (63 downto 0);
            write_en : in std_logic;
            read_en : in std_logic;
            size : in std_logic_vector (1 downto 0);
    
            atomic : in std_logic;
            op : in std_logic_vector (3 downto 0);
            cmpxchg_token : in std_logic_vector (63 downto 0);
            
            ready : out std_logic;
            output : out std_logic_vector (63 downto 0)
        );
    end component;

    function to_64b (constant x: in integer) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(x, 64));
    end to_64b;

    function to_32b (constant x: in integer) return std_logic_vector is
    begin
        return (31 downto 0 => '0') & std_logic_vector(to_signed(x, 32));
    end to_32b;
    
    function to_16b (constant x: in integer) return std_logic_vector is
    begin
        return (47 downto 0 => '0') & std_logic_vector(to_signed(x, 16));
    end to_16b;

    function to_8b (constant x: in integer) return std_logic_vector is
    begin
        return (55 downto 0 => '0') & std_logic_vector(to_signed(x, 8));
    end to_8b;


    constant CLK_PERIOD : time := 10 ns;

    signal clk, reset : std_logic;
    signal addr, input, output, cmpxchg_token, fetch_value : std_logic_vector (63 downto 0);
    signal write_en, read_en, atomic, ready : std_logic;
    signal size : std_logic_vector (1 downto 0);
    signal op : std_logic_vector (3 downto 0);

    signal test_done : std_logic;

begin

    tested_unit: BPF_Mem_Interface
        port map (
            clk => clk,
            reset => reset,
            addr => addr,
            input => input,
            write_en => write_en,
            read_en => read_en,
            size => size,
            atomic => atomic,
            op => op,
            cmpxchg_token => cmpxchg_token,
            ready => ready,
            output => output
        );

    CLK_PROC: process
    begin
        if (test_done /= '1') then
            CLK <= '0';
            wait for CLK_PERIOD / 2;
            CLK <= '1';
            wait for CLK_PERIOD / 2;
        else
            wait;
        end if;
    end process;


    TEST_PROC: process
        variable test_ok : std_logic;
    begin
        test_ok := '1';
        test_done <= '0';

        reset <= '1';
        addr <= (others => '0');
        input <= (others => '0');
        write_en <= '0';
        read_en <= '0';
        size <= "00";
        atomic <= '0';
        op <= "0000";
        cmpxchg_token <= (others => '0');

        wait until clk = '1'; -- Sync ALU clk with test
        ------------------------------------------------------------------------
        reset <= '0';

        -- Test STORE + LOAD ---------------------------------------------------
        atomic <= '0';

        -- 64b data
        write_en <= '1'; addr <= x"0000000000000000"; size <= BPF_SIZE64;
        read_en <= '0';  input <= to_64b(327);
        wait on clk until clk = '1' and ready = '1';
        write_en <= '0'; addr <= x"0000000000000000"; size <= BPF_SIZE64;
        read_en <= '1';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if output = to_64b(327) then report "Test STORE64 + LOAD: OK" severity note;
        else test_ok := '0'; report "Test STORE64 + LOAD: failed" severity note; end if;

        -- 32b data
        write_en <= '1'; addr <= x"0000000000000008"; size <= BPF_SIZE32;
        read_en <= '0';  input <= to_32b(4123);
        wait on clk until clk = '1' and ready = '1';
        write_en <= '0'; addr <= x"0000000000000008"; size <= BPF_SIZE32;
        read_en <= '1';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if output = to_32b(4123) then report "Test STORE32 + LOAD [0]: OK" severity note;
        else test_ok := '0'; report "Test STORE32 + LOAD [0]: failed" severity note; end if;

        write_en <= '1'; addr <= x"000000000000000C"; size <= BPF_SIZE32;
        read_en <= '0';  input <= to_32b(543);
        wait on clk until clk = '1' and ready = '1';
        write_en <= '0'; addr <= x"000000000000000C"; size <= BPF_SIZE32;
        read_en <= '1';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if output = to_32b(543) then report "Test STORE32 + LOAD [1]: OK" severity note;
        else test_ok := '0'; report "Test STORE32 + LOAD [1]: failed" severity note; end if;

        -- 16b data
        write_en <= '1'; addr <= x"0000000000000010"; size <= BPF_SIZE16;
        read_en <= '0';  input <= to_16b(999);
        wait on clk until clk = '1' and ready = '1';
        write_en <= '0'; addr <= x"0000000000000010"; size <= BPF_SIZE16;
        read_en <= '1';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if output = to_16b(999) then report "Test STORE16 + LOAD [0]: OK" severity note;
        else test_ok := '0'; report "Test STORE16 + LOAD [0]: failed" severity note; end if;

        write_en <= '1'; addr <= x"0000000000000012"; size <= BPF_SIZE16;
        read_en <= '0';  input <= to_16b(66);
        wait on clk until clk = '1' and ready = '1';
        write_en <= '0'; addr <= x"0000000000000012"; size <= BPF_SIZE16;
        read_en <= '1';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if output = to_16b(66) then report "Test STORE16 + LOAD [1]: OK" severity note;
        else test_ok := '0'; report "Test STORE16 + LOAD [1]: failed" severity note; end if;

        write_en <= '1'; addr <= x"0000000000000014"; size <= BPF_SIZE16;
        read_en <= '0';  input <= to_16b(3232);
        wait on clk until clk = '1' and ready = '1';
        write_en <= '0'; addr <= x"0000000000000014"; size <= BPF_SIZE16;
        read_en <= '1';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if output = to_16b(3232) then report "Test STORE16 + LOAD [2]: OK" severity note;
        else test_ok := '0'; report "Test STORE16 + LOAD [2]: failed" severity note; end if;

        write_en <= '1'; addr <= x"0000000000000016"; size <= BPF_SIZE16;
        read_en <= '0';  input <= to_16b(756);
        wait on clk until clk = '1' and ready = '1';
        write_en <= '0'; addr <= x"0000000000000016"; size <= BPF_SIZE16;
        read_en <= '1';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if output = to_16b(756) then report "Test STORE16 + LOAD [3]: OK" severity note;
        else test_ok := '0'; report "Test STORE16 + LOAD [3]: failed" severity note; end if;

        -- 8b data
        write_en <= '1'; addr <= x"0000000000000018"; size <= BPF_SIZE8;
        read_en <= '0';  input <= to_8b(11);
        wait on clk until clk = '1' and ready = '1';
        write_en <= '0'; addr <= x"0000000000000018"; size <= BPF_SIZE8;
        read_en <= '1';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if output = to_8b(11) then report "Test STORE8 + LOAD [0]: OK" severity note;
        else test_ok := '0'; report "Test STORE8 + LOAD [0]: failed" severity note; end if;

        write_en <= '1'; addr <= x"0000000000000019"; size <= BPF_SIZE8;
        read_en <= '0';  input <= to_8b(22);
        wait on clk until clk = '1' and ready = '1';
        write_en <= '0'; addr <= x"0000000000000019"; size <= BPF_SIZE8;
        read_en <= '1';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if output = to_8b(22) then report "Test STORE8 + LOAD [1]: OK" severity note;
        else test_ok := '0'; report "Test STORE8 + LOAD [1]: failed" severity note; end if;

        write_en <= '1'; addr <= x"000000000000001A"; size <= BPF_SIZE8;
        read_en <= '0';  input <= to_8b(33);
        wait on clk until clk = '1' and ready = '1';
        write_en <= '0'; addr <= x"000000000000001A"; size <= BPF_SIZE8;
        read_en <= '1';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if output = to_8b(33) then report "Test STORE8 + LOAD [2]: OK" severity note;
        else test_ok := '0'; report "Test STORE8 + LOAD [2]: failed" severity note; end if;

        write_en <= '1'; addr <= x"000000000000001B"; size <= BPF_SIZE8;
        read_en <= '0';  input <= to_8b(44);
        wait on clk until clk = '1' and ready = '1';
        write_en <= '0'; addr <= x"000000000000001B"; size <= BPF_SIZE8;
        read_en <= '1';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if output = to_8b(44) then report "Test STORE8 + LOAD [3]: OK" severity note;
        else test_ok := '0'; report "Test STORE8 + LOAD [3]: failed" severity note; end if;

        write_en <= '1'; addr <= x"000000000000001C"; size <= BPF_SIZE8;
        read_en <= '0';  input <= to_8b(55);
        wait on clk until clk = '1' and ready = '1';
        write_en <= '0'; addr <= x"000000000000001C"; size <= BPF_SIZE8;
        read_en <= '1';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if output = to_8b(55) then report "Test STORE8 + LOAD [4]: OK" severity note;
        else test_ok := '0'; report "Test STORE8 + LOAD [4]: failed" severity note; end if;

        write_en <= '1'; addr <= x"000000000000001D"; size <= BPF_SIZE8;
        read_en <= '0';  input <= to_8b(66);
        wait on clk until clk = '1' and ready = '1';
        write_en <= '0'; addr <= x"000000000000001D"; size <= BPF_SIZE8;
        read_en <= '1';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if output = to_8b(66) then report "Test STORE8 + LOAD [5]: OK" severity note;
        else test_ok := '0'; report "Test STORE8 + LOAD [5]: failed" severity note; end if;

        write_en <= '1'; addr <= x"000000000000001E"; size <= BPF_SIZE8;
        read_en <= '0';  input <= to_8b(77);
        wait on clk until clk = '1' and ready = '1';
        write_en <= '0'; addr <= x"000000000000001E"; size <= BPF_SIZE8;
        read_en <= '1';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if output = to_8b(77) then report "Test STORE8 + LOAD [6]: OK" severity note;
        else test_ok := '0'; report "Test STORE8 + LOAD [6]: failed" severity note; end if;

        write_en <= '1'; addr <= x"000000000000001F"; size <= BPF_SIZE8;
        read_en <= '0';  input <= to_8b(88);
        wait on clk until clk = '1' and ready = '1';
        write_en <= '0'; addr <= x"000000000000001F"; size <= BPF_SIZE8;
        read_en <= '1';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if output = to_8b(88) then report "Test STORE8 + LOAD [7]: OK" severity note;
        else test_ok := '0'; report "Test STORE8 + LOAD [7]: failed" severity note; end if;


        -- Test STORE + ADD + LOAD -----------------------------------------
        op <= BPF_ADD;

        -- 64b data
        write_en <= '1'; addr <= x"0000000000000020"; size <= BPF_SIZE64;
        read_en <= '0';  input <= to_64b(3); atomic <= '0';
        wait on clk until clk = '1' and ready = '1';
        write_en <= '1'; addr <= x"0000000000000020"; size <= BPF_SIZE64;
        read_en <= '0';  input <= to_64b(24); atomic <= '1';
        wait on clk until clk = '1' and ready = '1';
        write_en <= '0'; addr <= x"0000000000000020"; size <= BPF_SIZE64;
        read_en <= '1'; atomic <= '0';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if output = to_64b(27) then report "Test ADD64 + LOAD: OK" severity note;
        else test_ok := '0'; report "Test ADD64 + LOAD: failed" severity note; end if;

        -- 32b data
        write_en <= '1'; addr <= x"0000000000000028"; size <= BPF_SIZE32;
        read_en <= '0';  input <= to_32b(3); atomic <= '0';
        wait on clk until clk = '1' and ready = '1';
        write_en <= '1'; addr <= x"0000000000000028"; size <= BPF_SIZE32;
        read_en <= '0';  input <= to_32b(24); atomic <= '1';
        wait on clk until clk = '1' and ready = '1';
        write_en <= '0'; addr <= x"0000000000000028"; size <= BPF_SIZE32;
        read_en <= '1'; atomic <= '0';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if output = to_32b(27) then report "Test ADD32 + LOAD [0]: OK" severity note;
        else test_ok := '0'; report "Test ADD32 + LOAD [0]: failed" severity note; end if;

        write_en <= '1'; addr <= x"000000000000002C"; size <= BPF_SIZE32;
        read_en <= '0';  input <= to_32b(3); atomic <= '0';
        wait on clk until clk = '1' and ready = '1';
        write_en <= '1'; addr <= x"000000000000002C"; size <= BPF_SIZE32;
        read_en <= '0';  input <= to_32b(24); atomic <= '1';
        wait on clk until clk = '1' and ready = '1';
        write_en <= '0'; addr <= x"000000000000002C"; size <= BPF_SIZE32;
        read_en <= '1'; atomic <= '0';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if output = to_32b(27) then report "Test ADD32 + LOAD [1]: OK" severity note;
        else test_ok := '0'; report "Test ADD32 + LOAD [1]: failed" severity note; end if;


        -- 64b fetch
        fetch_value <= (others => '0');
        write_en <= '1'; addr <= x"0000000000000030"; size <= BPF_SIZE64;
        read_en <= '0';  input <= to_64b(3); atomic <= '0';
        wait on clk until clk = '1' and ready = '1';
        write_en <= '1'; addr <= x"0000000000000030"; size <= BPF_SIZE64;
        read_en <= '1';  input <= to_64b(24); atomic <= '1';
        wait on clk until clk = '1' and ready = '1';
        fetch_value <= output; 
        write_en <= '0'; addr <= x"0000000000000030"; size <= BPF_SIZE64;
        read_en <= '1'; atomic <= '1';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if fetch_value = to_64b(3) and output = to_64b(27) then report "Test ADD64|FETCH + LOAD: OK" severity note;
        else test_ok := '0'; report "Test ADD64|FETCH + LOAD: failed" severity note; end if;


        -- Test STORE + OR + LOAD -----------------------------------------
        op <= BPF_OR;

        -- 64b data
        write_en <= '1'; addr <= x"0000000000000040"; size <= BPF_SIZE64;
        read_en <= '0';  input <= "0000000100000000000000000011110000000000000001111000000001100000"; atomic <= '0';
        wait on clk until clk = '1' and ready = '1';
        write_en <= '1'; addr <= x"0000000000000040"; size <= BPF_SIZE64;
        read_en <= '0';  input <= "0000000000000010000000000000000000111000000000110000010000000000"; atomic <= '1';
        wait on clk until clk = '1' and ready = '1';
        write_en <= '0'; addr <= x"0000000000000040"; size <= BPF_SIZE64;
        read_en <= '1'; atomic <= '0';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if output = "0000000100000010000000000011110000111000000001111000010001100000" then report "Test OR64 + LOAD: OK" severity note;
        else test_ok := '0'; report "Test OR64 + LOAD: failed" severity note; end if;


        -- Test STORE + AND + LOAD -----------------------------------------
        op <= BPF_AND;

        -- 64b data
        write_en <= '1'; addr <= x"0000000000000050"; size <= BPF_SIZE64;
        read_en <= '0';  input <= "0000000100000000000000000011110000000000000001111000000001100000"; atomic <= '0';
        wait on clk until clk = '1' and ready = '1';
        write_en <= '1'; addr <= x"0000000000000050"; size <= BPF_SIZE64;
        read_en <= '0';  input <= "0000000100000010000000000000000000111000000000110000010000000000"; atomic <= '1';
        wait on clk until clk = '1' and ready = '1';
        write_en <= '0'; addr <= x"0000000000000050"; size <= BPF_SIZE64;
        read_en <= '1'; atomic <= '0';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if output = "0000000100000000000000000000000000000000000000110000000000000000" then report "Test AND64 + LOAD: OK" severity note;
        else test_ok := '0'; report "Test AND64 + LOAD: failed" severity note; end if;


        -- Test STORE + XOR + LOAD -----------------------------------------
        op <= BPF_XOR;

        -- 64b data
        write_en <= '1'; addr <= x"0000000000000060"; size <= BPF_SIZE64;
        read_en <= '0';  input <= "0000000100000000000000000011110000000000000001111000000001100000"; atomic <= '0';
        wait on clk until clk = '1' and ready = '1';
        write_en <= '1'; addr <= x"0000000000000060"; size <= BPF_SIZE64;
        read_en <= '0';  input <= "0000000100000010000000000000000000111000000000110000010000000000"; atomic <= '1';
        wait on clk until clk = '1' and ready = '1';
        write_en <= '0'; addr <= x"0000000000000060"; size <= BPF_SIZE64;
        read_en <= '1'; atomic <= '0';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if output = "0000000000000010000000000011110000111000000001001000010001100000" then report "Test XOR64 + LOAD: OK" severity note;
        else test_ok := '0'; report "Test XOR64 + LOAD: failed" severity note; end if;


        -- Test STORE + XCHG + LOAD -----------------------------------------
        op <= BPF_XCHG;

        -- 64b data
        fetch_value <= (others => '0');
        write_en <= '1'; addr <= x"00000000000000A0"; size <= BPF_SIZE64;
        read_en <= '0';  input <= to_64b(3); atomic <= '0';
        wait on clk until clk = '1' and ready = '1';
        write_en <= '1'; addr <= x"00000000000000A0"; size <= BPF_SIZE64;
        read_en <= '1';  input <= to_64b(24); atomic <= '1';
        wait on clk until clk = '1' and ready = '1';
        fetch_value <= output; 
        write_en <= '0'; addr <= x"00000000000000A0"; size <= BPF_SIZE64;
        read_en <= '1'; atomic <= '1';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if fetch_value = to_64b(3) and output = to_64b(24) then report "Test XCHG64 + LOAD: OK" severity note;
        else test_ok := '0'; report "Test XCHG64 + LOAD: failed" severity note; end if;

        -- 32b data
        fetch_value <= (others => '0');
        write_en <= '1'; addr <= x"00000000000000A8"; size <= BPF_SIZE32;
        read_en <= '0';  input <= to_32b(3); atomic <= '0';
        wait on clk until clk = '1' and ready = '1';
        write_en <= '1'; addr <= x"00000000000000A8"; size <= BPF_SIZE32;
        read_en <= '1';  input <= to_32b(24); atomic <= '1';
        wait on clk until clk = '1' and ready = '1';
        fetch_value <= output; 
        write_en <= '0'; addr <= x"00000000000000A8"; size <= BPF_SIZE32;
        read_en <= '1'; atomic <= '1';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if fetch_value = to_32b(3) and output = to_32b(24) then report "Test XCHG32 + LOAD [0]: OK" severity note;
        else test_ok := '0'; report "Test XCHG32 + LOAD [0]: failed" severity note; end if;

        fetch_value <= (others => '0');
        write_en <= '1'; addr <= x"00000000000000AC"; size <= BPF_SIZE32;
        read_en <= '0';  input <= to_32b(3); atomic <= '0';
        wait on clk until clk = '1' and ready = '1';
        write_en <= '1'; addr <= x"00000000000000AC"; size <= BPF_SIZE32;
        read_en <= '1';  input <= to_32b(24); atomic <= '1';
        wait on clk until clk = '1' and ready = '1';
        fetch_value <= output; 
        write_en <= '0'; addr <= x"00000000000000AC"; size <= BPF_SIZE32;
        read_en <= '1'; atomic <= '1';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if fetch_value = to_32b(3) and output = to_32b(24) then report "Test XCHG32 + LOAD [1]: OK" severity note;
        else test_ok := '0'; report "Test XCHG32 + LOAD [1]: failed" severity note; end if;


        -- Test STORE + CMPXCHG + LOAD -----------------------------------------
        op <= BPF_CMPXCHG;

        -- 64b data
        fetch_value <= (others => '0'); cmpxchg_token <= to_64b(3); -- Equal -> DO XCHG
        write_en <= '1'; addr <= x"00000000000000A0"; size <= BPF_SIZE64;
        read_en <= '0';  input <= to_64b(3); atomic <= '0';
        wait on clk until clk = '1' and ready = '1';
        write_en <= '1'; addr <= x"00000000000000A0"; size <= BPF_SIZE64;
        read_en <= '1';  input <= to_64b(24); atomic <= '1';
        wait on clk until clk = '1' and ready = '1';
        fetch_value <= output; 
        write_en <= '0'; addr <= x"00000000000000A0"; size <= BPF_SIZE64;
        read_en <= '1'; atomic <= '1';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if fetch_value = to_64b(3) and output = to_64b(24) then report "Test CMPXCHG64 + LOAD (true): OK" severity note;
        else test_ok := '0'; report "Test CMPXCHG64 + LOAD (true): failed" severity note; end if;

        fetch_value <= (others => '0'); cmpxchg_token <= to_64b(4); -- Not equal -> DO NOTHING
        write_en <= '1'; addr <= x"00000000000000A8"; size <= BPF_SIZE64;
        read_en <= '0';  input <= to_64b(3); atomic <= '0';
        wait on clk until clk = '1' and ready = '1';
        write_en <= '1'; addr <= x"00000000000000A8"; size <= BPF_SIZE64;
        read_en <= '1';  input <= to_64b(24); atomic <= '1';
        wait on clk until clk = '1' and ready = '1';
        fetch_value <= output; 
        write_en <= '0'; addr <= x"00000000000000A8"; size <= BPF_SIZE64;
        read_en <= '1'; atomic <= '1';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if fetch_value = to_64b(3) and output = to_64b(3) then report "Test CMPXCHG64 + LOAD (false): OK" severity note;
        else test_ok := '0'; report "Test CMPXCHG64 + LOAD (false): failed" severity note; end if;

        -- 32b data
        fetch_value <= (others => '0'); cmpxchg_token <= to_32b(3); -- Equal -> DO XCHG
        write_en <= '1'; addr <= x"00000000000000B0"; size <= BPF_SIZE32;
        read_en <= '0';  input <= to_32b(3); atomic <= '0';
        wait on clk until clk = '1' and ready = '1';
        write_en <= '1'; addr <= x"00000000000000B0"; size <= BPF_SIZE32;
        read_en <= '1';  input <= to_32b(24); atomic <= '1';
        wait on clk until clk = '1' and ready = '1';
        fetch_value <= output; 
        write_en <= '0'; addr <= x"00000000000000B0"; size <= BPF_SIZE32;
        read_en <= '1'; atomic <= '1';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if fetch_value = to_32b(3) and output = to_32b(24) then report "Test CMPXCHG32 + LOAD (true) [0]: OK" severity note;
        else test_ok := '0'; report "Test CMPXCHG32 + LOAD (true) [0]: failed" severity note; end if;

        fetch_value <= (others => '0'); cmpxchg_token <= to_32b(4); -- Not equal -> DO NOTHING
        write_en <= '1'; addr <= x"00000000000000B8"; size <= BPF_SIZE32;
        read_en <= '0';  input <= to_32b(3); atomic <= '0';
        wait on clk until clk = '1' and ready = '1';
        write_en <= '1'; addr <= x"00000000000000B8"; size <= BPF_SIZE32;
        read_en <= '1';  input <= to_32b(24); atomic <= '1';
        wait on clk until clk = '1' and ready = '1';
        fetch_value <= output; 
        write_en <= '0'; addr <= x"00000000000000B8"; size <= BPF_SIZE32;
        read_en <= '1'; atomic <= '1';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if fetch_value = to_32b(3) and output = to_32b(3) then report "Test CMPXCHG32 + LOAD (false) [0]: OK" severity note;
        else test_ok := '0'; report "Test CMPXCHG32 + LOAD (false) [0]: failed" severity note; end if;

        
        fetch_value <= (others => '0'); cmpxchg_token <= to_32b(3); -- Equal -> DO XCHG
        write_en <= '1'; addr <= x"00000000000000C4"; size <= BPF_SIZE32;
        read_en <= '0';  input <= to_32b(3); atomic <= '0';
        wait on clk until clk = '1' and ready = '1';
        write_en <= '1'; addr <= x"00000000000000C4"; size <= BPF_SIZE32;
        read_en <= '1';  input <= to_32b(24); atomic <= '1';
        wait on clk until clk = '1' and ready = '1';
        fetch_value <= output; 
        write_en <= '0'; addr <= x"00000000000000C4"; size <= BPF_SIZE32;
        read_en <= '1'; atomic <= '1';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if fetch_value = to_32b(3) and output = to_32b(24) then report "Test CMPXCHG32 + LOAD (true) [1]: OK" severity note;
        else test_ok := '0'; report "Test CMPXCHG32 + LOAD (true) [1]: failed" severity note; end if;

        fetch_value <= (others => '0'); cmpxchg_token <= to_32b(4); -- Not equal -> DO NOTHING
        write_en <= '1'; addr <= x"00000000000000CC"; size <= BPF_SIZE32;
        read_en <= '0';  input <= to_32b(3); atomic <= '0';
        wait on clk until clk = '1' and ready = '1';
        write_en <= '1'; addr <= x"00000000000000CC"; size <= BPF_SIZE32;
        read_en <= '1';  input <= to_32b(24); atomic <= '1';
        wait on clk until clk = '1' and ready = '1';
        fetch_value <= output; 
        write_en <= '0'; addr <= x"00000000000000CC"; size <= BPF_SIZE32;
        read_en <= '1'; atomic <= '1';
        wait on clk until clk = '1' and ready = '1'; wait for CLK_PERIOD / 2;
        if fetch_value = to_32b(3) and output = to_32b(3) then report "Test CMPXCHG32 + LOAD (false) [1]: OK" severity note;
        else test_ok := '0'; report "Test CMPXCHG32 + LOAD (false) [1]: failed" severity note; end if;

        ------------------------------------------------------------------------
        if test_ok = '1' then report "== All tests OK!! ==" severity note;
        else report "== Some tests failed ==" severity note; end if;

        test_done <= '1';
        wait;
    end process;


end Behavioral;