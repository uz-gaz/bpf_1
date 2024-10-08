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
        x"00000018000000B7",
        x"00000005000001B7",
        x"000000000000100F",
        x"FFFFFFFF000002B7",
        x"0000000100000207",
        x"FFFFFFBD000003B7",
        x"FFFFF7AD00000307",
        x"00000018000000B7",
        x"00000005000001B7",
        x"000000000000100C",
        x"FFFFFFFF000002B7",
        x"0000000100000204",
        x"FFFFFFBD000003B7",
        x"FFFFF7AD00000304",
        x"00000018000000B7",
        x"00000005000001B7",
        x"000000000000101F",
        x"FFFFFFFF000002B7",
        x"0000000100000217",
        x"FFFFFFBD000003B7",
        x"FFFFF7AD00000317",
        x"00000018000000B7",
        x"00000005000001B7",
        x"000000000000101C",
        x"FFFFFFFF000002B7",
        x"0000000100000214",
        x"FFFFFFBD000003B7",
        x"FFFFF7AD00000314",
        x"00000018000000B7",
        x"00000005000001B7",
        x"000000000000102F",
        x"FFFFFFFF000002B7",
        x"0000000100000227",
        x"FFFFFFBD000003B7",
        x"FFFFF7AD00000327",
        x"00000018000000B7",
        x"00000005000001B7",
        x"000000000000102C",
        x"FFFFFFFE000002B7",
        x"0000000100000224",
        x"FFFFFFBD000003B7",
        x"FFFFF7AD00000324",
        x"00000064000000B7",
        x"00000007000001B7",
        x"000000000000103F",
        x"00000064000000B7",
        x"FFFFFFF9000001B7",
        x"000000000000103F",
        x"FFFFFF9C000000B7",
        x"00000007000001B7",
        x"000000000000103F",
        x"FFFFFF9C000000B7",
        x"FFFFFFF9000001B7",
        x"000000000000103F",
        x"00000064000000B7",
        x"00000000000001B7",
        x"000000000000103F",
        x"FFFFFF9C000000B7",
        x"00000000000001B7",
        x"000000000000103F",
        x"00000064000000B7",
        x"0000000700010037",
        x"00000064000000B7",
        x"FFFFFFF900010037",
        x"FFFFFF9C000000B7",
        x"0000000700010037",
        x"FFFFFF9C000000B7",
        x"FFFFFFF900010037",
        x"00000064000000B7",
        x"0000000000010037",
        x"FFFFFF9C000000B7",
        x"0000000000010037",
        x"00000064000000B7",
        x"00000007000001B7",
        x"000000000000103C",
        x"00000064000000B7",
        x"FFFFFFF9000001B7",
        x"000000000000103C",
        x"FFFFFF9C000000B7",
        x"00000007000001B7",
        x"000000000000103C",
        x"FFFFFF9C000000B7",
        x"FFFFFFF9000001B7",
        x"000000000000103C",
        x"00000064000000B7",
        x"00000000000001B7",
        x"000000000000103C",
        x"FFFFFF9C000000B7",
        x"00000000000001B7",
        x"000000000000103C",
        x"00000064000000B7",
        x"0000000700010034",
        x"00000064000000B7",
        x"FFFFFFF900010034",
        x"FFFFFF9C000000B7",
        x"0000000700010034",
        x"FFFFFF9C000000B7",
        x"FFFFFFF900010034",
        x"00000064000000B7",
        x"0000000000010034",
        x"FFFFFF9C000000B7",
        x"0000000000010034",
        x"00000064000000B7",
        x"00000007000001B7",
        x"000000000000109F",
        x"00000064000000B7",
        x"FFFFFFF9000001B7",
        x"000000000000109F",
        x"FFFFFF9C000000B7",
        x"00000007000001B7",
        x"000000000000109F",
        x"FFFFFF9C000000B7",
        x"FFFFFFF9000001B7",
        x"000000000000109F",
        x"00000064000000B7",
        x"00000000000001B7",
        x"000000000000109F",
        x"FFFFFF9C000000B7",
        x"00000000000001B7",
        x"000000000000109F",
        x"00000064000000B7",
        x"0000000700010097",
        x"00000064000000B7",
        x"FFFFFFF900010097",
        x"FFFFFF9C000000B7",
        x"0000000700010097",
        x"FFFFFF9C000000B7",
        x"FFFFFFF900010097",
        x"00000064000000B7",
        x"0000000000010097",
        x"FFFFFF9C000000B7",
        x"0000000000010097",
        x"00000064000000B7",
        x"00000007000001B7",
        x"000000000000109C",
        x"00000064000000B7",
        x"FFFFFFF9000001B7",
        x"000000000000109C",
        x"FFFFFF9C000000B7",
        x"00000007000001B7",
        x"000000000000109C",
        x"FFFFFF9C000000B7",
        x"FFFFFFF9000001B7",
        x"000000000000109C",
        x"00000064000000B7",
        x"00000000000001B7",
        x"000000000000109C",
        x"FFFFFF9C000000B7",
        x"00000000000001B7",
        x"000000000000109C",
        x"00000064000000B7",
        x"0000000700010094",
        x"00000064000000B7",
        x"FFFFFFF900010094",
        x"FFFFFF9C000000B7",
        x"0000000700010094",
        x"FFFFFF9C000000B7",
        x"FFFFFFF900010094",
        x"00000064000000B7",
        x"0000000000010094",
        x"FFFFFF9C000000B7",
        x"0000000000010094",
        x"0007806000000918",
        x"0100003C00000000",
        x"3803040000000818",
        x"0002000000000000",
        x"000000000000894F",
        x"0007806000000818",
        x"0100003C00000000",
        x"3803040000000918",
        x"0102000000000000",
        x"000000000000895F",
        x"0007806000000918",
        x"0100003C00000000",
        x"3803040000000818",
        x"0102000000000000",
        x"00000000000089AF",
        x"00000064000000B7",
        x"0000000200000067",
        x"00000320000000B7",
        x"0000040300000077",
        x"000000FF00000018",
        x"00000FF000000000",
        x"00000008000000C7",
        x"000000FF00000018",
        x"80000FF000000000",
        x"00000008000000C7",
        x"0000FFFF00000018",
        x"00000FF000000000",
        x"00000008000000C4",
        x"800000FF00000018",
        x"80000FF000000000",
        x"00000008000000C4",
        x"000000FD000806B7",
        x"0000007D000806B7",
        x"0000FFFD001006B7",
        x"00007FFD001006B7",
        x"FFFFFFFD002006B7",
        x"700000FD002006B7",
        x"000000FD000806B4",
        x"0000007D000806B4",
        x"0000FFFD001006B4",
        x"00007FFD001006B4",
        x"0506070800000718",
        x"0102030400000000",
        x"00000010000007D7",
        x"0506070800000718",
        x"0102030400000000",
        x"00000020000007D7",
        x"0506070800000718",
        x"0102030400000000",
        x"00000040000007D7",
        x"0506070800000718",
        x"0102030400000000",
        x"00000010000007DC",
        x"0506070800000718",
        x"0102030400000000",
        x"00000020000007DC",
        x"0506070800000718",
        x"0102030400000000",
        x"00000040000007DC",
        x"0506070800000718",
        x"0102030400000000",
        x"00000010000007D4",
        x"00000020000007D4",
        x"00000040000007D4",
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

