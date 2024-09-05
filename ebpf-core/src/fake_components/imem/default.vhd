--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Fake instruction RAM for testing. Size: 4096 x 64 bits
--               instructions.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity Inst_RAM is
    port (
        clk : in std_logic;
        addr : in std_logic_vector (11 downto 0);
        input : in std_logic_vector (63 downto 0);
        write_en : in std_logic;
        read_en : in std_logic;
        output : out std_logic_vector (63 downto 0)
    );
end Inst_RAM;

architecture Behavioral of Inst_RAM is

    type inst_array is array(0 to 4096) of std_logic_vector(63 downto 0);
    signal RAM : inst_array := (
        x"00000040000001B7",
        x"00000020000002B4",
        x"00000000000412AD",
        x"000000000003213D",
        x"0000000100000117",
        x"0000000100000204",
        x"00000000FFFC21BD",
        x"00000000000000B7",
        x"0000000000000095",

        others => x"0000000000000000"
    );

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