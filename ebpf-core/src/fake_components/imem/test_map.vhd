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
        x"00000000000009B7",
        x"00000001000001B7",
        x"00000000000092BF",
        x"0000000000000085",
        x"0000000000030015",
        x"0000000000000361",
        x"0000000000040461",
        x"0000000000020005",
        x"FFFFFFFF000003B7",
        x"FFFFFFFF000004B7",
        x"0000000100000907",
        x"00000064FFF509A5",
        x"00000001000001B7",
        x"00000064000002B7",
        x"0000000000000085",
        x"00000000000001B7",
        x"0000002D000002B7",
        x"0000000000000085",
        x"00000000000009B7",
        x"00000040000007D4",
        x"00000040000007D4",
        x"0000000100000907",
        x"0000000AFFFC09A5",
        x"00000000000001B7",
        x"0000002D000002B7",
        x"0000000000000085",
        x"0000000000000361",
        x"0000000000040461",
        x"00000000000009B7",
        x"00000040000007D4",
        x"00000040000007D4",
        x"0000000100000907",
        x"0000000AFFFC09A5",
        x"00000000000001B7",
        x"0000002D000002B7",
        x"0000000000000085",
        x"0000000000000361",
        x"0000000000040461",
        x"00000000000009B7",
        x"00000040000007D4",
        x"00000040000007D4",
        x"0000000100000907",
        x"0000000AFFFC09A5",
        x"00000000000001B7",
        x"0000002D000002B7",
        x"0000000000000085",
        x"0000000000000379",
        x"0000000000040479",
        x"00000001000001B7",
        x"00000042000002B7",
        x"0000000000000085",
        x"0000000000000361",

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

