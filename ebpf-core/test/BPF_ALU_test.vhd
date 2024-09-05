--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Unit test for BPF_ALU.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.bpf.all;

entity BPF_ALU_Testbench is
end BPF_ALU_Testbench;

architecture Behavioral of BPF_ALU_Testbench is

    component BPF_ALU is
        port (
            clk : in std_logic;
            reset : in std_logic;
            alu_en : in std_logic;
            operand_A : in std_logic_vector (63 downto 0);
            operand_B : in std_logic_vector (63 downto 0);
            op_alu : in std_logic_vector (3 downto 0);
            op_64b : in std_logic;
            signed_alu : in std_logic;
            sx_size : in std_logic_vector (1 downto 0);

            alu_ready : out std_logic;
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

    constant CLK_PERIOD : time := 10 ns;

    signal clk, reset, alu_en : std_logic;
    signal operand_A, operand_B, output : std_logic_vector (63 downto 0);
    signal op_64b, signed_alu, alu_ready : std_logic;
    signal op_alu : std_logic_vector (3 downto 0);
    signal sx_size : std_logic_vector (1 downto 0);

    signal test_done : std_logic;

begin

    tested_unit: BPF_ALU
        port map (
            clk => clk,
            reset => reset,
            alu_en => alu_en,
            operand_A => operand_A,
            operand_B => operand_B,
            op_alu => op_alu,
            op_64b => op_64b,
            signed_alu => signed_alu,
            sx_size => sx_size,
            alu_ready => alu_ready,
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

        op_alu <= "0000";
        op_64b <= '0';
        signed_alu <= '0';
        sx_size <= "00";
        operand_A <= (63 downto 0 => '0');
        operand_B <= (63 downto 0 => '0');

        alu_en <= '1';
        reset <= '1';

        wait until clk = '1'; -- Sync ALU clk with test

        reset <= '0';

        -- Test ADD ------------------------------------------------------------
        op_alu <= BPF_ADD;

        -- alu 64b
        op_64b <= '1';     operand_A <= to_64b(24);
        signed_alu <= '0'; operand_B <= to_64b(5);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(29) then report "Test ADD.1: OK" severity note;
        else test_ok := '0'; report "Test ADD.1: failed" severity note; end if;

        op_64b <= '1';     operand_A <= to_64b(-1);
        signed_alu <= '0'; operand_B <= to_64b(1);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(0) then report "Test ADD.2: OK" severity note;
        else test_ok := '0'; report "Test ADD.2: failed" severity note; end if;

        op_64b <= '1';     operand_A <= to_64b(-67);
        signed_alu <= '0'; operand_B <= to_64b(-2131);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(-2198) then report "Test ADD.3: OK" severity note;
        else test_ok := '0'; report "Test ADD.3: failed" severity note; end if;

        -- alu 32b
        op_64b <= '0';     operand_A <= to_32b(24);
        signed_alu <= '0'; operand_B <= to_32b(5);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(29) then report "Test ADD32.1: OK" severity note;
        else test_ok := '0'; report "Test ADD32.1: failed" severity note; end if;

        op_64b <= '0';     operand_A <= to_32b(-1);
        signed_alu <= '0'; operand_B <= to_32b(1);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(0) then report "Test ADD32.2: OK" severity note;
        else test_ok := '0'; report "Test ADD32.2: failed" severity note; end if;

        op_64b <= '0';     operand_A <= to_32b(-67);
        signed_alu <= '0'; operand_B <= to_32b(-2131);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(-2198) then report "Test ADD32.3: OK" severity note;
        else test_ok := '0'; report "Test ADD32.3: failed" severity note; end if;

        -- Test SUB ------------------------------------------------------------
        op_alu <= BPF_SUB;

        -- alu 64b
        op_64b <= '1';     operand_A <= to_64b(24);
        signed_alu <= '0'; operand_B <= to_64b(5);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(19) then report "Test SUB.1: OK" severity note;
        else test_ok := '0'; report "Test SUB.1: failed" severity note; end if;

        op_64b <= '1';     operand_A <= to_64b(-1);
        signed_alu <= '0'; operand_B <= to_64b(1);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(-2) then report "Test SUB.2: OK" severity note;
        else test_ok := '0'; report "Test SUB.2: failed" severity note; end if;

        op_64b <= '1';     operand_A <= to_64b(-67);
        signed_alu <= '0'; operand_B <= to_64b(-2131);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(2064) then report "Test SUB.3: OK" severity note;
        else test_ok := '0'; report "Test SUB.3: failed" severity note; end if;

        -- alu 32b
        op_64b <= '0';     operand_A <= to_32b(24);
        signed_alu <= '0'; operand_B <= to_32b(5);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(19) then report "Test SUB32.1: OK" severity note;
        else test_ok := '0'; report "Test SUB32.1: failed" severity note; end if;

        op_64b <= '0';     operand_A <= to_32b(-1);
        signed_alu <= '0'; operand_B <= to_32b(1);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(-2) then report "Test SUB32.2: OK" severity note;
        else test_ok := '0'; report "Test SUB32.2: failed" severity note; end if;

        op_64b <= '0';     operand_A <= to_32b(-67);
        signed_alu <= '0'; operand_B <= to_32b(-2131);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(2064) then report "Test SUB32.3: OK" severity note;
        else test_ok := '0'; report "Test SUB32.3: failed" severity note; end if;

        -- Test MUL ------------------------------------------------------------
        op_alu <= BPF_MUL;

        -- alu 64b
        op_64b <= '1';     operand_A <= to_64b(24);
        signed_alu <= '0'; operand_B <= to_64b(5);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(120) then report "Test MUL.1: OK" severity note;
        else test_ok := '0'; report "Test MUL.1: failed" severity note; end if;

        op_64b <= '1';     operand_A <= to_64b(-12);
        signed_alu <= '0'; operand_B <= to_64b(32);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(-384) then report "Test MUL.2: OK" severity note;
        else test_ok := '0'; report "Test MUL.2: failed" severity note; end if;

        op_64b <= '1';     operand_A <= to_64b(-67);
        signed_alu <= '0'; operand_B <= to_64b(-2131);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(142777) then report "Test MUL.3: OK" severity note;
        else test_ok := '0'; report "Test MUL.3: failed" severity note; end if;

        -- alu 32b
        op_64b <= '0';     operand_A <= to_32b(24);
        signed_alu <= '0'; operand_B <= to_32b(5);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(120) then report "Test MUL32.1: OK" severity note;
        else test_ok := '0'; report "Test MUL32.1: failed" severity note; end if;

        op_64b <= '0';     operand_A <= to_32b(-12);
        signed_alu <= '0'; operand_B <= to_32b(32);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(-384) then report "Test MUL32.2: OK" severity note;
        else test_ok := '0'; report "Test MUL32.2: failed" severity note; end if;

        op_64b <= '0';     operand_A <= to_32b(-67);
        signed_alu <= '0'; operand_B <= to_32b(-2131);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(142777) then report "Test MUL32.3: OK" severity note;
        else test_ok := '0'; report "Test MUL32.3: failed" severity note; end if;

        -- Test DIV ------------------------------------------------------------
        op_alu <= BPF_DIV;

        -- Unsigned alu 64b
        op_64b <= '1';     operand_A <= to_64b(100);
        signed_alu <= '0'; operand_B <= to_64b(7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(14) then report "Test DIV.1: OK" severity note;
        else test_ok := '0'; report "Test DIV.1: failed" severity note; end if;
        
        op_64b <= '1';     operand_A <= to_64b(100);
        signed_alu <= '0'; operand_B <= to_64b(-7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(0) then report "Test DIV.2: OK" severity note;
        else test_ok := '0'; report "Test DIV.2: failed" severity note; end if;

        op_64b <= '1';     operand_A <= to_64b(-100); -- 18 446 744 073 709 551 516
        signed_alu <= '0'; operand_B <= to_64b(7);
        wait on clk until clk = '1' and alu_ready = '1';
        -- output = 2 635 249 153 387 078 788
        if output = "0010010010010010010010010010010010010010010010010010010010000100" then report "Test DIV.3: OK" severity note;
        else test_ok := '0'; report "Test DIV.3: failed" severity note; end if;

        op_64b <= '1';     operand_A <= to_64b(-100);
        signed_alu <= '0'; operand_B <= to_64b(-7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(0) then report "Test DIV.4: OK" severity note;
        else test_ok := '0'; report "Test DIV.4: failed" severity note; end if;

        op_64b <= '1';     operand_A <= to_64b(100);
        signed_alu <= '0'; operand_B <= to_64b(0);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(0) then report "Test DIV.5: OK" severity note;
        else test_ok := '0'; report "Test DIV.5: failed" severity note; end if;
        
        op_64b <= '1';     operand_A <= to_64b(-100);
        signed_alu <= '0'; operand_B <= to_64b(0);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(0) then report "Test DIV.6: OK" severity note;
        else test_ok := '0'; report "Test DIV.6: failed" severity note; end if;

        -- Signed alu 64b
        op_64b <= '1';     operand_A <= to_64b(100);
        signed_alu <= '1'; operand_B <= to_64b(7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(14) then report "Test SDIV.1: OK" severity note;
        else test_ok := '0'; report "Test SDIV.1: failed" severity note; end if;

        op_64b <= '1';     operand_A <= to_64b(100);
        signed_alu <= '1'; operand_B <= to_64b(-7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(-14) then report "Test SDIV.2: OK" severity note;
        else test_ok := '0'; report "Test SDIV.2: failed" severity note; end if;

        op_64b <= '1';     operand_A <= to_64b(-100);
        signed_alu <= '1'; operand_B <= to_64b(7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(-14) then report "Test SDIV.3: OK" severity note;
        else test_ok := '0'; report "Test SDIV.3: failed" severity note; end if;

        op_64b <= '1';     operand_A <= to_64b(-100);
        signed_alu <= '1'; operand_B <= to_64b(-7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(14) then report "Test SDIV.4: OK" severity note;
        else test_ok := '0'; report "Test SDIV.4: failed" severity note; end if;

        op_64b <= '1';     operand_A <= to_64b(100);
        signed_alu <= '1'; operand_B <= to_64b(0);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(0) then report "Test SDIV.5: OK" severity note;
        else test_ok := '0'; report "Test SDIV.5: failed" severity note; end if;
        
        op_64b <= '1';     operand_A <= to_64b(-100);
        signed_alu <= '1'; operand_B <= to_64b(0);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(0) then report "Test SDIV.6: OK" severity note;
        else test_ok := '0'; report "Test SDIV.6: failed" severity note; end if;

        -- Unsigned alu 32b
        op_64b <= '0';     operand_A <= to_32b(100);
        signed_alu <= '0'; operand_B <= to_32b(7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(14) then report "Test DIV32.1: OK" severity note;
        else test_ok := '0'; report "Test DIV32.1: failed" severity note; end if;
        
        op_64b <= '0';     operand_A <= to_32b(100);
        signed_alu <= '0'; operand_B <= to_32b(-7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(0) then report "Test DIV32.2: OK" severity note;
        else test_ok := '0'; report "Test DIV32.2: failed" severity note; end if;

        op_64b <= '0';     operand_A <= to_32b(-100); -- 4 294 967 196
        signed_alu <= '0'; operand_B <= to_32b(7);
        wait on clk until clk = '1' and alu_ready = '1';
        -- output = 613 566 742
        if output = ((31 downto 0 => '0') & "00100100100100100100100100010110") then report "Test DIV32.3: OK" severity note;
        else test_ok := '0'; report "Test DIV32.3: failed" severity note; end if;

        op_64b <= '0';     operand_A <= to_32b(-100);
        signed_alu <= '0'; operand_B <= to_32b(-7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(0) then report "Test DIV32.4: OK" severity note;
        else test_ok := '0'; report "Test DIV32.4: failed" severity note; end if;

        op_64b <= '0';     operand_A <= to_32b(100);
        signed_alu <= '0'; operand_B <= to_32b(0);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(0) then report "Test DIV32.5: OK" severity note;
        else test_ok := '0'; report "Test DIV32.5: failed" severity note; end if;
        
        op_64b <= '0';     operand_A <= to_32b(-100);
        signed_alu <= '0'; operand_B <= to_32b(0);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(0) then report "Test DIV32.6: OK" severity note;
        else test_ok := '0'; report "Test DIV32.6: failed" severity note; end if;

        -- Signed alu 32b
        op_64b <= '0';     operand_A <= to_32b(100);
        signed_alu <= '1'; operand_B <= to_32b(7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(14) then report "Test SDIV32.1: OK" severity note;
        else test_ok := '0'; report "Test SDIV32.1: failed" severity note; end if;

        op_64b <= '0';     operand_A <= to_32b(100);
        signed_alu <= '1'; operand_B <= to_32b(-7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(-14) then report "Test SDIV32.2: OK" severity note;
        else test_ok := '0'; report "Test SDIV32.2: failed" severity note; end if;

        op_64b <= '0';     operand_A <= to_32b(-100);
        signed_alu <= '1'; operand_B <= to_32b(7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(-14) then report "Test SDIV32.3: OK" severity note;
        else test_ok := '0'; report "Test SDIV32.3: failed" severity note; end if;

        op_64b <= '0';     operand_A <= to_32b(-100);
        signed_alu <= '1'; operand_B <= to_32b(-7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(14) then report "Test SDIV32.4: OK" severity note;
        else test_ok := '0'; report "Test SDIV32.4: failed" severity note; end if;

        op_64b <= '0';     operand_A <= to_32b(100);
        signed_alu <= '1'; operand_B <= to_32b(0);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(0) then report "Test SDIV32.5: OK" severity note;
        else test_ok := '0'; report "Test SDIV32.5: failed" severity note; end if;
        
        op_64b <= '0';     operand_A <= to_32b(-100);
        signed_alu <= '1'; operand_B <= to_32b(0);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(0) then report "Test SDIV32.6: OK" severity note;
        else test_ok := '0'; report "Test SDIV32.6: failed" severity note; end if;
        
        -- Test OR ------------------------------------------------------------
        op_alu <= BPF_OR;

        -- alu 64b
        op_64b <= '1';     operand_A <= "0000000100000000000000000011110000000000000001111000000001100000";
        signed_alu <= '0'; operand_B <= "0000000000000010000000000000000000111000000000110000010000000000";
        wait on clk until clk = '1' and alu_ready = '1';
        if output = "0000000100000010000000000011110000111000000001111000010001100000" then report "Test OR.1: OK" severity note;
        else test_ok := '0'; report "Test OR.1: failed" severity note; end if;

        -- alu 32b
        op_64b <= '0';     operand_A <= "0000000100000000000000000011110000000000000001111000000001100000";
        signed_alu <= '0'; operand_B <= "0000000000000010000000000000000000111000000000110000010000000000";
        wait on clk until clk = '1' and alu_ready = '1';
        if output = "0000000000000000000000000000000000111000000001111000010001100000" then report "Test OR32.1: OK" severity note;
        else test_ok := '0'; report "Test OR32.1: failed" severity note; end if;

        -- Test AND ------------------------------------------------------------
        op_alu <= BPF_AND;

        -- alu 64b
        op_64b <= '1';     operand_A <= "0000000100000000000000000011110000000000000001111000000001100000";
        signed_alu <= '0'; operand_B <= "0000000100000010000000000000000000111000000000110000010000000000";
        wait on clk until clk = '1' and alu_ready = '1';
        if output = "0000000100000000000000000000000000000000000000110000000000000000" then report "Test AND.1: OK" severity note;
        else test_ok := '0'; report "Test AND.1: failed" severity note; end if;

        -- alu 32b
        op_64b <= '0';     operand_A <= "0000000100000000000000000011110000000000000001111000000001100000";
        signed_alu <= '0'; operand_B <= "0000000100000010000000000000000000111000000000110000010000000000";
        wait on clk until clk = '1' and alu_ready = '1';
        if output = "0000000000000000000000000000000000000000000000110000000000000000" then report "Test AND32.1: OK" severity note;
        else test_ok := '0'; report "Test AND32.1: failed" severity note; end if;

        -- Test LSH ------------------------------------------------------------
        op_alu <= BPF_LSH;

        -- alu 64b
        op_64b <= '1';     operand_A <= "0000000100000000000000000011110000000000000001111000000001100000";
        signed_alu <= '0'; operand_B <= to_64b(8);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = "0000000000000000001111000000000000000111100000000110000000000000" then report "Test LSH.1: OK" severity note;
        else test_ok := '0'; report "Test LSH.1: failed" severity note; end if;
        
        op_64b <= '1';     operand_A <= "0000000100000000000000000011110000000000000001111000000001100000";
        signed_alu <= '0'; operand_B <= to_64b(4_194_240) or to_64b(8); --overflow -> use mask for operand B
        wait on clk until clk = '1' and alu_ready = '1';
        -- Same result
        if output = "0000000000000000001111000000000000000111100000000110000000000000" then report "Test LSH.2: OK" severity note;
        else test_ok := '0'; report "Test LSH.2: failed" severity note; end if;

        
        -- alu 32b
        op_64b <= '0';     operand_A <= "0000000100000000000000000011110000000000000001111000000001100000";
        signed_alu <= '0'; operand_B <= to_64b(8);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = "0000000000000000000000000000000000000111100000000110000000000000" then report "Test LSH32.1: OK" severity note;
        else test_ok := '0'; report "Test LSH32.1: failed" severity note; end if;
        
        op_64b <= '0';     operand_A <= "0000000100000000000000000011110000000000000001111000000001100000";
        signed_alu <= '0'; operand_B <= to_64b(4_194_240) or to_64b(8); --overflow -> use mask for operand B
        wait on clk until clk = '1' and alu_ready = '1';
        -- Same result
        if output = "0000000000000000000000000000000000000111100000000110000000000000" then report "Test LSH32.2: OK" severity note;
        else test_ok := '0'; report "Test LSH32.2: failed" severity note; end if;

        -- Test RSH ------------------------------------------------------------
        op_alu <= BPF_RSH;

        -- alu 64b
        op_64b <= '1';     operand_A <= "0000000100000000000000000011110000000000000001111000000001100000";
        signed_alu <= '0'; operand_B <= to_64b(8);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = "0000000000000001000000000000000000111100000000000000011110000000" then report "Test RSH.1: OK" severity note;
        else test_ok := '0'; report "Test RSH.1: failed" severity note; end if;
        
        op_64b <= '1';     operand_A <= "0000000100000000000000000011110000000000000001111000000001100000";
        signed_alu <= '0'; operand_B <= to_64b(4_194_240) or to_64b(8); --overflow -> use mask for operand B
        wait on clk until clk = '1' and alu_ready = '1';
        -- Same result
        if output = "0000000000000001000000000000000000111100000000000000011110000000" then report "Test RSH.2: OK" severity note;
        else test_ok := '0'; report "Test RSH.2: failed" severity note; end if;

        
        -- alu 32b
        op_64b <= '0';     operand_A <= "0000000100000000000000000011110000000000000001111000000001100000";
        signed_alu <= '0'; operand_B <= to_64b(8);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = "0000000000000000000000000000000000111100000000000000011110000000" then report "Test RSH32.1: OK" severity note;
        else test_ok := '0'; report "Test RSH32.1: failed" severity note; end if;
        
        op_64b <= '0';     operand_A <= "0000000100000000000000000011110000000000000001111000000001100000";
        signed_alu <= '0'; operand_B <= to_64b(4_194_240) or to_64b(8); --overflow -> use mask for operand B
        wait on clk until clk = '1' and alu_ready = '1';
        -- Same result
        if output = "0000000000000000000000000000000000111100000000000000011110000000" then report "Test RSH32.2: OK" severity note;
        else test_ok := '0'; report "Test RSH32.2: failed" severity note; end if;


        -- Test NEG ------------------------------------------------------------
        op_alu <= BPF_NEG;

        -- alu 64b
        op_64b <= '1';     operand_A <= "0000000100000000000000000011110000000000000001111000000001100000";
        signed_alu <= '0'; operand_B <= to_64b(0);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = "1111111011111111111111111100001111111111111110000111111110011111" then report "Test NEG.1: OK" severity note;
        else test_ok := '0'; report "Test NEG.1: failed" severity note; end if;

        -- alu 32b
        op_64b <= '0';     operand_A <= "0000000100000000000000000011110000000000000001111000000001100000";
        signed_alu <= '0'; operand_B <= to_32b(0);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = "0000000000000000000000000000000011111111111110000111111110011111" then report "Test NEG32.1: OK" severity note;
        else test_ok := '0'; report "Test NEG32.1: failed" severity note; end if;


        -- Test MOD ------------------------------------------------------------
        op_alu <= BPF_MOD;

        -- Unsigned alu 64b
        op_64b <= '1';     operand_A <= to_64b(100);
        signed_alu <= '0'; operand_B <= to_64b(7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(2) then report "Test MOD.1: OK" severity note;
        else test_ok := '0'; report "Test MOD.1: failed" severity note; end if;
        
        op_64b <= '1';     operand_A <= to_64b(100);
        signed_alu <= '0'; operand_B <= to_64b(-7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(100) then report "Test MOD.2: OK" severity note;
        else test_ok := '0'; report "Test MOD.2: failed" severity note; end if;

        op_64b <= '1';     operand_A <= to_64b(-100); -- 18 446 744 073 709 551 516
        signed_alu <= '0'; operand_B <= to_64b(7);
        wait on clk until clk = '1' and alu_ready = '1';
        -- output = 2 635 249 153 387 078 788
        if output = to_64b(0) then report "Test MOD.3: OK" severity note;
        else test_ok := '0'; report "Test MOD.3: failed" severity note; end if;

        op_64b <= '1';     operand_A <= to_64b(-100);
        signed_alu <= '0'; operand_B <= to_64b(-7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = "1111111111111111111111111111111111111111111111111111111110011100" then report "Test MOD.4: OK" severity note;
        else test_ok := '0'; report "Test MOD.4: failed" severity note; end if;

        op_64b <= '1';     operand_A <= to_64b(100);
        signed_alu <= '0'; operand_B <= to_64b(0);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(100) then report "Test MOD.5: OK" severity note;
        else test_ok := '0'; report "Test MOD.5: failed" severity note; end if;
        
        op_64b <= '1';     operand_A <= to_64b(-100);
        signed_alu <= '0'; operand_B <= to_64b(0);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(-100) then report "Test MOD.6: OK" severity note;
        else test_ok := '0'; report "Test MOD.6: failed" severity note; end if;

        -- Signed alu 64b
        op_64b <= '1';     operand_A <= to_64b(100);
        signed_alu <= '1'; operand_B <= to_64b(7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(2) then report "Test SMOD.1: OK" severity note;
        else test_ok := '0'; report "Test SMOD.1: failed" severity note; end if;

        op_64b <= '1';     operand_A <= to_64b(100);
        signed_alu <= '1'; operand_B <= to_64b(-7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(-2) then report "Test SMOD.2: OK" severity note;
        else test_ok := '0'; report "Test SMOD.2: failed" severity note; end if;

        op_64b <= '1';     operand_A <= to_64b(-100);
        signed_alu <= '1'; operand_B <= to_64b(7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(-2) then report "Test SMOD.3: OK" severity note;
        else test_ok := '0'; report "Test SMOD.3: failed" severity note; end if;

        op_64b <= '1';     operand_A <= to_64b(-100);
        signed_alu <= '1'; operand_B <= to_64b(-7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(2) then report "Test SMOD.4: OK" severity note;
        else test_ok := '0'; report "Test SMOD.4: failed" severity note; end if;

        op_64b <= '1';     operand_A <= to_64b(100);
        signed_alu <= '1'; operand_B <= to_64b(0);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(100) then report "Test SMOD.5: OK" severity note;
        else test_ok := '0'; report "Test SMOD.5: failed" severity note; end if;
        
        op_64b <= '1';     operand_A <= to_64b(-100);
        signed_alu <= '1'; operand_B <= to_64b(0);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_64b(-100) then report "Test SMOD.6: OK" severity note;
        else test_ok := '0'; report "Test SMOD.6: failed" severity note; end if;

        -- Unsigned alu 32b
        op_64b <= '0';     operand_A <= to_32b(100);
        signed_alu <= '0'; operand_B <= to_32b(7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(2) then report "Test MOD32.1: OK" severity note;
        else test_ok := '0'; report "Test MOD32.1: failed" severity note; end if;
        
        op_64b <= '0';     operand_A <= to_32b(100);
        signed_alu <= '0'; operand_B <= to_32b(-7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(100) then report "Test MOD32.2: OK" severity note;
        else test_ok := '0'; report "Test MOD32.2: failed" severity note; end if;

        op_64b <= '0';     operand_A <= to_32b(-100); -- 4 294 967 196
        signed_alu <= '0'; operand_B <= to_32b(7);
        wait on clk until clk = '1' and alu_ready = '1';
        -- output = 613 566 742
        if output = to_32b(2) then report "Test MOD32.3: OK" severity note;
        else test_ok := '0'; report "Test MOD32.3: failed" severity note; end if;

        op_64b <= '0';     operand_A <= to_32b(-100);
        signed_alu <= '0'; operand_B <= to_32b(-7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = ((31 downto 0 => '0') & "11111111111111111111111110011100") then report "Test MOD32.4: OK" severity note;
        else test_ok := '0'; report "Test MOD32.4: failed" severity note; end if;

        op_64b <= '0';     operand_A <= to_32b(100);
        signed_alu <= '0'; operand_B <= to_32b(0);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(100) then report "Test MOD32.5: OK" severity note;
        else test_ok := '0'; report "Test MOD32.5: failed" severity note; end if;
        
        op_64b <= '0';     operand_A <= to_32b(-100);
        signed_alu <= '0'; operand_B <= to_32b(0);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(-100) then report "Test MOD32.6: OK" severity note;
        else test_ok := '0'; report "Test MOD32.6: failed" severity note; end if;

        -- Signed alu 32b
        op_64b <= '0';     operand_A <= to_32b(100);
        signed_alu <= '1'; operand_B <= to_32b(7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(2) then report "Test SMOD32.1: OK" severity note;
        else test_ok := '0'; report "Test SMOD32.1: failed" severity note; end if;

        op_64b <= '0';     operand_A <= to_32b(100);
        signed_alu <= '1'; operand_B <= to_32b(-7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(-2) then report "Test SMOD32.2: OK" severity note;
        else test_ok := '0'; report "Test SMOD32.2: failed" severity note; end if;

        op_64b <= '0';     operand_A <= to_32b(-100);
        signed_alu <= '1'; operand_B <= to_32b(7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(-2) then report "Test SMOD32.3: OK" severity note;
        else test_ok := '0'; report "Test SMOD32.3: failed" severity note; end if;

        op_64b <= '0';     operand_A <= to_32b(-100);
        signed_alu <= '1'; operand_B <= to_32b(-7);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(2) then report "Test SMOD32.4: OK" severity note;
        else test_ok := '0'; report "Test SMOD32.4: failed" severity note; end if;

        op_64b <= '0';     operand_A <= to_32b(100);
        signed_alu <= '1'; operand_B <= to_32b(0);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(100) then report "Test SMOD32.5: OK" severity note;
        else test_ok := '0'; report "Test SMOD32.5: failed" severity note; end if;
        
        op_64b <= '0';     operand_A <= to_32b(-100);
        signed_alu <= '1'; operand_B <= to_32b(0);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = to_32b(-100) then report "Test SMOD32.6: OK" severity note;
        else test_ok := '0'; report "Test SMOD32.6: failed" severity note; end if;

        -- Test XOR ------------------------------------------------------------
        op_alu <= BPF_XOR;

        -- alu 64b
        op_64b <= '1';     operand_A <= "0000000100000000000000000011110000000000000001111000000001100000";
        signed_alu <= '0'; operand_B <= "0000000100000010000000000000000000111000000000110000010000000000";
        wait on clk until clk = '1' and alu_ready = '1';
        if output = "0000000000000010000000000011110000111000000001001000010001100000" then report "Test XOR.1: OK" severity note;
        else test_ok := '0'; report "Test XOR.1: failed" severity note; end if;

        -- alu 32b
        op_64b <= '0';     operand_A <= "0000000100000000000000000011110000000000000001111000000001100000";
        signed_alu <= '0'; operand_B <= "0000000100000010000000000000000000111000000000110000010000000000";
        wait on clk until clk = '1' and alu_ready = '1';
        if output = "0000000000000000000000000000000000111000000001001000010001100000" then report "Test XOR32.1: OK" severity note;
        else test_ok := '0'; report "Test XOR32.1: failed" severity note; end if;


        -- Test MOV ------------------------------------------------------------
        op_alu <= BPF_MOV;

        -- mundane MOV alu 64b
        op_64b <= '1';     operand_A <= to_64b(0); sx_size <= BPF_SIZE64;
        signed_alu <= '0'; operand_B <= x"0102030405060708";
        wait on clk until clk = '1' and alu_ready = '1';
        if output = x"0102030405060708" then report "Test MOV.1: OK" severity note;
        else test_ok := '0'; report "Test MOV.1: failed" severity note; end if;

        -- mundane MOV alu 32b
        op_64b <= '0';     operand_A <= to_32b(0); sx_size <= BPF_SIZE64;
        signed_alu <= '0'; operand_B <= x"0102030405060708";
        wait on clk until clk = '1' and alu_ready = '1';
        if output = x"0000000005060708" then report "Test MOV32.1: OK" severity note;
        else test_ok := '0'; report "Test MOV32.1: failed" severity note; end if;

        -- MOVSX8 alu 64b
        op_64b <= '1';     operand_A <= to_64b(0); sx_size <= BPF_SIZE8;
        signed_alu <= '0'; operand_B <= x"01020304050607F8";
        wait on clk until clk = '1' and alu_ready = '1';
        if output = x"FFFFFFFFFFFFFFF8" then report "Test MOVSX8.1: OK" severity note;
        else test_ok := '0'; report "Test MOVSX8.1: failed" severity note; end if;
        
        op_64b <= '1';     operand_A <= to_64b(0); sx_size <= BPF_SIZE8;
        signed_alu <= '0'; operand_B <= x"0102030405060708";
        wait on clk until clk = '1' and alu_ready = '1';
        if output = x"0000000000000008" then report "Test MOVSX8.2: OK" severity note;
        else test_ok := '0'; report "Test MOVSX8.2: failed" severity note; end if;

        -- MOVSX8 alu 32b
        op_64b <= '0';     operand_A <= to_64b(0); sx_size <= BPF_SIZE8;
        signed_alu <= '0'; operand_B <= x"01020304050607F8";
        wait on clk until clk = '1' and alu_ready = '1';
        if output = x"00000000FFFFFFF8" then report "Test MOVSX8_32.1: OK" severity note;
        else test_ok := '0'; report "Test MOVSX8_32.1: failed" severity note; end if;
        
        op_64b <= '0';     operand_A <= to_64b(0); sx_size <= BPF_SIZE8;
        signed_alu <= '0'; operand_B <= x"0102030405060708";
        wait on clk until clk = '1' and alu_ready = '1';
        if output = x"0000000000000008" then report "Test MOVSX8.2: OK" severity note;
        else test_ok := '0'; report "Test MOVSX8_32.2: failed" severity note; end if;

        -- MOVSX16 alu 64b
        op_64b <= '1';     operand_A <= to_64b(0); sx_size <= BPF_SIZE16;
        signed_alu <= '0'; operand_B <= x"010203040506F708";
        wait on clk until clk = '1' and alu_ready = '1';
        if output = x"FFFFFFFFFFFFF708" then report "Test MOVSX16.1: OK" severity note;
        else test_ok := '0'; report "Test MOVSX16.1: failed" severity note; end if;
        
        op_64b <= '1';     operand_A <= to_64b(0); sx_size <= BPF_SIZE16;
        signed_alu <= '0'; operand_B <= x"0102030405060708";
        wait on clk until clk = '1' and alu_ready = '1';
        if output = x"0000000000000708" then report "Test MOVSX16.2: OK" severity note;
        else test_ok := '0'; report "Test MOVSX16.2: failed" severity note; end if;

        -- MOVSX16 alu 32b
        op_64b <= '0';     operand_A <= to_64b(0); sx_size <= BPF_SIZE16;
        signed_alu <= '0'; operand_B <= x"010203040506F708";
        wait on clk until clk = '1' and alu_ready = '1';
        if output = x"00000000FFFFF708" then report "Test MOVSX16_32.1: OK" severity note;
        else test_ok := '0'; report "Test MOVSX16_32.1: failed" severity note; end if;
        
        op_64b <= '0';     operand_A <= to_64b(0); sx_size <= BPF_SIZE16;
        signed_alu <= '0'; operand_B <= x"0102030405060708";
        wait on clk until clk = '1' and alu_ready = '1';
        if output = x"0000000000000708" then report "Test MOVSX16.2: OK" severity note;
        else test_ok := '0'; report "Test MOVSX16_32.2: failed" severity note; end if;

        -- MOVSX32 alu 64b
        op_64b <= '1';     operand_A <= to_64b(0); sx_size <= BPF_SIZE32;
        signed_alu <= '0'; operand_B <= x"01020304F5060708";
        wait on clk until clk = '1' and alu_ready = '1';
        if output = x"FFFFFFFFF5060708" then report "Test MOVSX32.1: OK" severity note;
        else test_ok := '0'; report "Test MOVSX32.1: failed" severity note; end if;
        
        op_64b <= '1';     operand_A <= to_64b(0); sx_size <= BPF_SIZE32;
        signed_alu <= '0'; operand_B <= x"0102030405060708";
        wait on clk until clk = '1' and alu_ready = '1';
        if output = x"0000000005060708" then report "Test MOVSX32.2: OK" severity note;
        else test_ok := '0'; report "Test MOVSX32.2: failed" severity note; end if;

        -- MOVSX32 alu 32b
        op_64b <= '0';     operand_A <= to_64b(0); sx_size <= BPF_SIZE32;
        signed_alu <= '0'; operand_B <= x"01020304F5060708";
        wait on clk until clk = '1' and alu_ready = '1';
        if output = x"00000000F5060708" then report "Test MOVSX32_32.1: OK" severity note;
        else test_ok := '0'; report "Test MOVSX32_32.1: failed" severity note; end if;
        
        op_64b <= '0';     operand_A <= to_64b(0); sx_size <= BPF_SIZE32;
        signed_alu <= '0'; operand_B <= x"0102030405060708";
        wait on clk until clk = '1' and alu_ready = '1';
        if output = x"0000000005060708" then report "Test MOVSX32.2: OK" severity note;
        else test_ok := '0'; report "Test MOVSX32_32.2: failed" severity note; end if;
        
        -- Test ARSH ------------------------------------------------------------
        op_alu <= BPF_ARSH;

        -- alu 64b
        op_64b <= '1';     operand_A <= "0000000100000000000000000011110000000000000001111000000001100000";
        signed_alu <= '0'; operand_B <= to_64b(8);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = "0000000000000001000000000000000000111100000000000000011110000000" then report "Test ARSH.1: OK" severity note;
        else test_ok := '0'; report "Test ARSH.1: failed" severity note; end if;
        
        op_64b <= '1';     operand_A <= "0000000100000000000000000011110000000000000001111000000001100000";
        signed_alu <= '0'; operand_B <= to_64b(4_194_240) or to_64b(8); --overflow -> use mask for operand B
        wait on clk until clk = '1' and alu_ready = '1';
        -- Same result
        if output = "0000000000000001000000000000000000111100000000000000011110000000" then report "Test ARSH.2: OK" severity note;
        else test_ok := '0'; report "Test ARSH.2: failed" severity note; end if;

        op_64b <= '1';     operand_A <= "1000000100000000000000000011110000000000000001111000000001100000";
        signed_alu <= '0'; operand_B <= to_64b(8);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = "1111111110000001000000000000000000111100000000000000011110000000" then report "Test ARSH.3: OK" severity note;
        else test_ok := '0'; report "Test ARSH.3: failed" severity note; end if;
        
        op_64b <= '1';     operand_A <= "1000000100000000000000000011110000000000000001111000000001100000";
        signed_alu <= '0'; operand_B <= to_64b(4_194_240) or to_64b(8); --overflow -> use mask for operand B
        wait on clk until clk = '1' and alu_ready = '1';
        -- Same result
        if output = "1111111110000001000000000000000000111100000000000000011110000000" then report "Test ARSH.4: OK" severity note;
        else test_ok := '0'; report "Test ARSH.4: failed" severity note; end if;

        
        -- alu 32b
        op_64b <= '0';     operand_A <= "0000000000000000000000000000000001000000000001111000000001100000";
        signed_alu <= '0'; operand_B <= to_64b(8);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = "0000000000000000000000000000000000000000010000000000011110000000" then report "Test ARSH32.1: OK" severity note;
        else test_ok := '0'; report "Test ARSH32.1: failed" severity note; end if;
        
        op_64b <= '0';     operand_A <= "0000000000000000000000000000000001000000000001111000000001100000";
        signed_alu <= '0'; operand_B <= to_64b(4_194_240) or to_64b(8); --overflow -> use mask for operand B
        wait on clk until clk = '1' and alu_ready = '1';
        -- Same result
        if output = "0000000000000000000000000000000000000000010000000000011110000000" then report "Test ARSH32.2: OK" severity note;
        else test_ok := '0'; report "Test ARSH32.2: failed" severity note; end if;
        
        op_64b <= '0';     operand_A <= "0000000000000000000000000000000011000000000001111000000001100000";
        signed_alu <= '0'; operand_B <= to_64b(8);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = "0000000000000000000000000000000011111111110000000000011110000000" then report "Test ARSH32.1: OK" severity note;
        else test_ok := '0'; report "Test ARSH32.1: failed" severity note; end if;
        
        op_64b <= '0';     operand_A <= "0000000000000000000000000000000011000000000001111000000001100000";
        signed_alu <= '0'; operand_B <= to_64b(4_194_240) or to_64b(8); --overflow -> use mask for operand B
        wait on clk until clk = '1' and alu_ready = '1';
        -- Same result
        if output = "0000000000000000000000000000000011111111110000000000011110000000" then report "Test ARSH32.2: OK" severity note;
        else test_ok := '0'; report "Test ARSH32.2: failed" severity note; end if;

        
        -- Test END ------------------------------------------------------------
        op_alu <= BPF_END;

        op_64b <= '1';     operand_A <= x"0102030405060708";
        signed_alu <= '0'; operand_B <= to_64b(64);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = x"0807060504030201" then report "Test END.1: OK" severity note;
        else test_ok := '0'; report "Test END.1: failed" severity note; end if;

        op_64b <= '1';     operand_A <= x"0102030405060708";
        signed_alu <= '0'; operand_B <= to_64b(32);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = x"0000000008070605" then report "Test END.2: OK" severity note;
        else test_ok := '0'; report "Test END.2: failed" severity note; end if;

        op_64b <= '1';     operand_A <= x"0102030405060708";
        signed_alu <= '0'; operand_B <= to_64b(16);
        wait on clk until clk = '1' and alu_ready = '1';
        if output = x"0000000000000807" then report "Test END.3: OK" severity note;
        else test_ok := '0'; report "Test END.3: failed" severity note; end if;

        ------------------------------------------------------------------------
        if test_ok = '1' then report "== All tests OK!! ==" severity note;
		else report "== Some tests failed ==" severity note; end if;

        test_done <= '1';
        wait;
    end process;

end Behavioral;
