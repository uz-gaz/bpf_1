--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Fake BRAM component that replaces Xilinx's IP for simulating
--               out of the Vivado environment.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity Block_Mem_base is
    generic (
        WIDTH : natural;
        DEPTH : natural
    );
    port (
        clka : in std_logic;
        ena : in std_logic;

        addra : in std_logic_vector(integer(ceil(log2(real(DEPTH)))) - 1 downto 0);
        dina : in std_logic_vector(WIDTH - 1 downto 0);
        douta : out std_logic_vector(WIDTH - 1 downto 0);
        wea : in std_logic_vector((WIDTH / 8) - 1 downto 0)
    );
end Block_Mem_base;

architecture Behavioral of Block_Mem_base is

    type word_array is array(0 to DEPTH - 1) of std_logic_vector(WIDTH - 1 downto 0);
    signal RAM : word_array := (others => (others => '0'));

begin

    process (clka)
    begin
        if (clka'event and clka = '1') then

            for k in 0 to wea'length - 1 loop
                if (ena = '1' and wea(k) = '1') then
                    RAM(conv_integer(addra))(8*(k+1)-1 downto (8*k)) <= dina(8*(k+1)-1 downto (8*k));
                end if;
            end loop;
            
        end if;
    end process;

    process (clka)
    begin
        if (clka'event and clka = '1') then
            douta <= (WIDTH - 1 downto 0 => '0');
            if (ena = '1' and unsigned(addra) < DEPTH) then
                douta <= RAM(conv_integer(addra));
            end if;
        end if;
    end process;
    

end Behavioral;

