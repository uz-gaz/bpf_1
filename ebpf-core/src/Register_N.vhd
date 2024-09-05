--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Generic size register
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity Register_N is
    generic ( SIZE : positive := 64 );

    port (
        clk : in std_logic;
        reset : in std_logic;
        load : in std_logic;

        input : in std_logic_vector (SIZE - 1 downto 0);
        output : out std_logic_vector (SIZE - 1 downto 0)
    );
end Register_N;

architecture Behavioral of Register_N is
begin
    SYNC_PROC: process (clk)
    begin
        if (clk'event and clk = '1') then
            if (reset = '1') then
                output <= ( others => '0');
            elsif (load = '1') then 
                output <= input;
            end if;        
        end if;
   end process;
end Behavioral;
