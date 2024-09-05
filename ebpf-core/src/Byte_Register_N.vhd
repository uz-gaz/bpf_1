--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Generic size register
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity Byte_Register_N is
    generic ( SIZE : positive := 64 );

    port (
        clk : in std_logic;
        reset : in std_logic;
        load : in std_logic_vector((SIZE / 8) - 1 downto 0);

        input : in std_logic_vector (SIZE - 1 downto 0);
        output : out std_logic_vector (SIZE - 1 downto 0)
    );
end Byte_Register_N;

architecture Behavioral of Byte_Register_N is
begin
    SYNC_PROC: process (clk)
    begin
        if (clk'event and clk = '1') then
            if (reset = '1') then
                output <= ( others => '0');
            else
                for k in 0 to load'length - 1 loop
                    if (load(k) = '1') then
                        output(8*(k+1)-1 downto (8*k)) <= input(8*(k+1)-1 downto (8*k));
                    end if;
                end loop;
            end if;        
        end if;
   end process;
end Behavioral;
