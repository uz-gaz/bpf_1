--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Testbench for BPF_Data_Path.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BPF_Data_Path_Testbench is
end BPF_Data_Path_Testbench;

architecture Behavioral of BPF_Data_Path_Testbench is

    component BPF_Data_Path is
        port (
            clk : in std_logic;
            reset : in std_logic;

            -- Temporary signals to test exception control
            --IF_gen_exception : in std_logic;
            --ID_gen_exception : in std_logic;
            --EX_gen_exception : in std_logic;
            --MEM_gen_exception : in std_logic;
    
            CORE_sleep : in std_logic;
            CORE_reg_dst : in std_logic_vector (3 downto 0);
            CORE_reg_write : in std_logic;
            CORE_reg_input : in std_logic_vector (63 downto 0);
    
            CORE_sleeping : out std_logic;
            CORE_finish : out std_logic;
            CORE_exception : out std_logic;
            CORE_output : out std_logic_vector (63 downto 0)
        );
    end component;

    function to_64b (constant x: in integer) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(x, 64));
    end to_64b;

    constant CLK_PERIOD : time := 10 ns;
    constant NUM_CLKS : natural := 1000;

    signal clk, reset : std_logic;
    signal CORE_sleep : std_logic;
    signal CORE_reg_dst : std_logic_vector (3 downto 0);
    signal CORE_reg_write : std_logic;
    signal CORE_reg_input : std_logic_vector (63 downto 0);
    signal CORE_sleeping : std_logic;
    signal CORE_finish : std_logic;
    signal CORE_exception : std_logic;
    signal CORE_output : std_logic_vector (63 downto 0);

    signal IF_gen_exception : std_logic;
    signal ID_gen_exception : std_logic;
    signal EX_gen_exception : std_logic;
    signal MEM_gen_exception : std_logic;

begin

    tested_unit: BPF_Data_Path
        port map (
            clk => clk,
            reset => reset,

            --IF_gen_exception => IF_gen_exception,
            --ID_gen_exception => ID_gen_exception,
            --EX_gen_exception => EX_gen_exception,
            --MEM_gen_exception => MEM_gen_exception,

            CORE_sleep => CORE_sleep,
            CORE_reg_dst => CORE_reg_dst,
            CORE_reg_write => CORE_reg_write,
            CORE_reg_input => CORE_reg_input,
            CORE_sleeping => CORE_sleeping,
            CORE_finish => CORE_finish,
            CORE_exception => CORE_exception,
            CORE_output => CORE_output
        );

    CLK_PROC: process
        variable cycles : natural := 0;
    begin
        if (cycles /= NUM_CLKS) then
            CLK <= '0';
            wait for CLK_PERIOD / 2;
            CLK <= '1';
            wait for CLK_PERIOD / 2;
            cycles := cycles + 1;
        else
            wait;
        end if;
    end process;


    TEST_PROC: process
    begin
        reset <= '1';

        IF_gen_exception <= '0'; 
        ID_gen_exception <= '0'; 
        EX_gen_exception <= '0'; 
        MEM_gen_exception <= '0';

        CORE_sleep <= '0';
        CORE_reg_dst <= (others => '0');
        CORE_reg_write <= '0';
        CORE_reg_input <= (others => '0');
        
        wait on clk until clk = '1';
        reset <= '0';


        -- Check if reset works
        --wait for 13 * CLK_PERIOD;
        --reset <= '1';
        --wait for CLK_PERIOD;
        --reset <= '0';


        ------------------------------------------------------------------------
        -- Check if processor can sleep and wake up ----------------------------
        ------------------------------------------------------------------------

        /* -- For "decode_test" 
        wait for 13 * CLK_PERIOD; -- this makes it stop on a division
        CORE_sleep <= '1';
        wait on clk until clk = '1' and CORE_sleeping = '1';
        -- rest asleep a few cycles
        wait for 2 * CLK_PERIOD;
        CORE_sleep <= '0';
        */

        /*-- For "test_branch"
        wait for 3 * CLK_PERIOD; -- this makes it stop on an unconditional jump
        CORE_sleep <= '1';
        wait on clk until clk = '1' and CORE_sleeping = '1';
        CORE_sleep <= '0';

        wait for 4 * CLK_PERIOD; -- this makes it stop on a not taken branch
        CORE_sleep <= '1';
        wait on clk until clk = '1' and CORE_sleeping = '1';
        CORE_sleep <= '0';

        wait for 2 * CLK_PERIOD; -- this makes it stop on a taken branch
        CORE_sleep <= '1';
        wait on clk until clk = '1' and CORE_sleeping = '1';
        CORE_sleep <= '0';
        */


        ------------------------------------------------------------------------
        -- Exception test ------------------------------------------------------
        ------------------------------------------------------------------------

        /*-- Better testing on "test_alu"
        wait for 4 * CLK_PERIOD;
        CORE_sleep <= '1'; -- Check prevalence if more than one exception occurs in the same cycle and over sleep
        IF_gen_exception <= '1';
        ID_gen_exception <= '1';
        EX_gen_exception <= '1';
        MEM_gen_exception <= '1';
        wait for 4 * CLK_PERIOD;
        CORE_sleep <= '0';
        wait for 2 * CLK_PERIOD;
        reset <= '1';
        IF_gen_exception <= '0';
        ID_gen_exception <= '0';
        EX_gen_exception <= '0';
        MEM_gen_exception <= '0';
        wait for 1 * CLK_PERIOD;
        reset <= '0';


        wait for 4 * CLK_PERIOD;
        -- Check correction if exceptions occur in different cycles 
        ID_gen_exception <= '1';
        wait for 1 * CLK_PERIOD;
        MEM_gen_exception <= '1';
        wait for 4 * CLK_PERIOD;
        reset <= '1';
        ID_gen_exception <= '0';
        MEM_gen_exception <= '0';
        wait for 1 * CLK_PERIOD;
        reset <= '0';


        wait for 4 * CLK_PERIOD;
        -- Check correction if exceptions occur in different cycles 
        IF_gen_exception <= '1';
        wait for 1 * CLK_PERIOD;
        EX_gen_exception <= '1';
        wait for 4 * CLK_PERIOD;
        reset <= '1';
        IF_gen_exception <= '0';
        EX_gen_exception <= '0';
        wait for 1 * CLK_PERIOD;
        reset <= '0';


        wait for 4 * CLK_PERIOD;
        -- Check correction if exceptions occur in different cycles 
        IF_gen_exception <= '1';
        wait for 2 * CLK_PERIOD;
        MEM_gen_exception <= '1';
        wait for 4 * CLK_PERIOD;
        reset <= '1';
        IF_gen_exception <= '0';
        MEM_gen_exception <= '0';
        wait for 1 * CLK_PERIOD;
        reset <= '0';
        */

        ------------------------------------------------------------------------
        -- Exceptions over finish flag -----------------------------------------
        ------------------------------------------------------------------------

        /*-- For "test_branch"
        wait for 177 * CLK_PERIOD;
        -- IF exception does not consolidate if exit instruction is on decode
        IF_gen_exception <= '1';
        wait for 6 * CLK_PERIOD;
        reset <= '1';
        IF_gen_exception <= '0';
        wait for 1 * CLK_PERIOD;
        reset <= '0';


        wait for 176 * CLK_PERIOD;
        -- ID exception does consolidate if exit instruction is on decode -> finish flag never set
        ID_gen_exception <= '1';
        wait for 6 * CLK_PERIOD;
        reset <= '1';
        ID_gen_exception <= '0';
        wait for 1 * CLK_PERIOD;
        reset <= '0';


        wait for 176 * CLK_PERIOD;
        -- EX exception does consolidate if exit instruction is on decode
        EX_gen_exception <= '1';
        wait for 6 * CLK_PERIOD;
        reset <= '1';
        EX_gen_exception <= '0';
        wait for 1 * CLK_PERIOD;
        reset <= '0';


        wait for 176 * CLK_PERIOD;
        -- MEM exception does consolidate if exit instruction is on decode
        MEM_gen_exception <= '1';
        wait for 6 * CLK_PERIOD;
        reset <= '1';
        MEM_gen_exception <= '0';
        wait for 1 * CLK_PERIOD;
        reset <= '0';
        */

        wait;
    end process;

end Behavioral;