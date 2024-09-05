--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Register buffer for transition between stages IF-ID
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity Buffer_IF_ID is
    port (
        clk : in std_logic;
        reset : in std_logic;
        load : in std_logic;

        IF_IR : in std_logic_vector (63 downto 0);
        IF_PC1 : in std_logic_vector (11 downto 0);
        IF_discard : in std_logic; -- Control signal -> inst in IF is a NOOP
        IF_call_2 : in std_logic; -- Control signal -> inst in IF is a NOOP but reads r4-r5

        ID_IR : out std_logic_vector (63 downto 0);
        ID_PC1 : out std_logic_vector (11 downto 0);
        ID_discard : out std_logic;
        ID_call_2 : out std_logic
    );
end Buffer_IF_ID;

architecture Behavioral of Buffer_IF_ID is

    component Delayed_Register_N is
    --component Register_N is
        generic ( SIZE : positive := 64 );
        port (
            clk : in std_logic;
            reset : in std_logic;
            load : in std_logic;
    
            input : in std_logic_vector (SIZE - 1 downto 0);
            output : out std_logic_vector (SIZE - 1 downto 0)
        );
    end component;


begin

    SYNC_PROC: process (clk)
    begin
        if (clk'event and clk = '1') then
            if (reset = '1') then
                --ID_IR <= ( others => '0');
                ID_PC1 <= ( others => '0');
                ID_discard <= '1'; -- Necessary as IR made of 0s is not a valid instruction
                ID_call_2 <= '0';
            elsif (load = '1') then 
                --ID_IR <= IF_IR;
                ID_PC1 <= IF_PC1;
                ID_discard <= IF_discard;
                ID_call_2 <= IF_call_2;
            end if;        
        end if;
    end process;

    IR_reg_block: Delayed_Register_N 
    --IR_reg_block: Register_N 
        generic map ( SIZE => 64 )
        port map(
            clk => clk,
            reset => reset,
            load => load,

            input => IF_IR,
            output => ID_IR
        );

end Behavioral;