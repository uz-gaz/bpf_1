--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Fake stack RAM for testing. Size: 64 x 64 bits words (512B).
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity Stack_RAM is
    port (
        clk : in std_logic;
        addr : in std_logic_vector (5 downto 0); -- 64 * 64 bits
        input : in std_logic_vector (63 downto 0);
        write_en : in std_logic;
        read_en : in std_logic;
        output : out std_logic_vector (63 downto 0)
    );
end Stack_RAM;

architecture Behavioral of Stack_RAM is

    type words_array is array(0 to 63) of std_logic_vector(63 downto 0);
    signal RAM : words_array := ( 10 => x"0123456789abcdef", others => x"0000000000000000");

begin

    process (clk)
    begin
        if (clk'event and clk = '1') then
            if (write_en = '1') then
                RAM(conv_integer(addr)) <= input;
            end if;
        end if;
    end process;

    output <= RAM(conv_integer(addr)) when read_en = '1' else (63 downto 0 => '0');

end Behavioral;