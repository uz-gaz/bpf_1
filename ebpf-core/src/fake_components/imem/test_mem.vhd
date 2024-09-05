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
        x"0000014700000A7A",
        x"000000000000A079",
        x"0000101BFFF80A62",
        x"00000000FFF8A161",
        x"0000021FFFF40A62",
        x"00000000FFF4A261",
        x"000003E7FFF00A6A",
        x"00000000FFF0A369",
        x"00000042FFEE0A6A",
        x"00000000FFEEA469",
        x"00000CA0FFEC0A6A",
        x"00000000FFECA569",
        x"000002F4FFEA0A6A",
        x"00000000FFEAA669",
        x"0000000BFFE80A72",
        x"00000000FFE8A071",
        x"00000016FFE70A72",
        x"00000000FFE7A171",
        x"00000021FFE60A72",
        x"00000000FFE6A271",
        x"0000002CFFE50A72",
        x"00000000FFE5A371",
        x"00000037FFE40A72",
        x"00000000FFE4A471",
        x"00000042FFE30A72",
        x"00000000FFE3A571",
        x"0000004DFFE20A72",
        x"00000000FFE2A671",
        x"00000058FFE10A72",
        x"00000000FFE1A771",
        x"FFFFFEB900000918",
        x"FFFFFFFF00000000",
        x"0000000000009A7B",
        x"000000000000A079",
        x"FFFFEFE500000918",
        x"FFFFFFFF00000000",
        x"00000000FFF89A63",
        x"00000000FFF8A181",
        x"FFFFFDE100000918",
        x"FFFFFFFF00000000",
        x"00000000FFF49A63",
        x"00000000FFF4A281",
        x"FFFFFC1900000918",
        x"FFFFFFFF00000000",
        x"00000000FFF09A6B",
        x"00000000FFF0A389",
        x"FFFFFFBE00000918",
        x"FFFFFFFF00000000",
        x"00000000FFEE9A6B",
        x"00000000FFEEA489",
        x"FFFFF36000000918",
        x"FFFFFFFF00000000",
        x"00000000FFEC9A6B",
        x"00000000FFECA589",
        x"FFFFFD0C00000918",
        x"FFFFFFFF00000000",
        x"00000000FFEA9A6B",
        x"00000000FFEAA689",
        x"FFFFFFF500000918",
        x"FFFFFFFF00000000",
        x"00000000FFE89A73",
        x"00000000FFE8A091",
        x"FFFFFFEA00000918",
        x"FFFFFFFF00000000",
        x"00000000FFE79A73",
        x"00000000FFE7A191",
        x"FFFFFFDF00000918",
        x"FFFFFFFF00000000",
        x"00000000FFE69A73",
        x"00000000FFE6A291",
        x"FFFFFFD400000918",
        x"FFFFFFFF00000000",
        x"00000000FFE59A73",
        x"00000000FFE5A391",
        x"FFFFFFC900000918",
        x"FFFFFFFF00000000",
        x"00000000FFE49A73",
        x"00000000FFE4A491",
        x"FFFFFFBE00000918",
        x"FFFFFFFF00000000",
        x"00000000FFE39A73",
        x"00000000FFE3A591",
        x"FFFFFFB300000918",
        x"FFFFFFFF00000000",
        x"00000000FFE29A73",
        x"00000000FFE2A691",
        x"FFFFFFA800000918",
        x"FFFFFFFF00000000",
        x"00000000FFE19A73",
        x"00000000FFE1A791",
        x"FFFFFFE800000818",
        x"FFFFFFFF00000000",
        x"00000003FFE00A7A",
        x"00000000FFE08ADB",
        x"00000000FFE0A079",
        x"00000003FFD80A62",
        x"00000000FFD88AC3",
        x"00000000FFD8A161",
        x"00000003FFD40A62",
        x"00000000FFD48AC3",
        x"00000000FFD4A281",
        x"FFFFFFCB00000318",
        x"FFFFFFFF00000000",
        x"00000042FFD00A7A",
        x"00000001FFD03ADB",
        x"00000000FFD0A679",
        x"FFFFFFCB00000418",
        x"FFFFFFFF00000000",
        x"00000040FFC80A62",
        x"00000001FFC84AC3",
        x"00000000FFC8A761",
        x"FFFFFFCB00000518",
        x"FFFFFFFF00000000",
        x"0000003EFFC40A62",
        x"00000001FFC45AC3",
        x"00000000FFC4A881",
        x"0007806000000918",
        x"0100003C00000000",
        x"3803040000000818",
        x"0002000000000000",
        x"00000000FFC08A7B",
        x"00000040FFC09ADB",
        x"00000000FFC0A079",
        x"0007806000000918",
        x"0100003C00000000",
        x"3803040000000818",
        x"0102000000000000",
        x"00000000FFB08A7B",
        x"00000051FFB09ADB",
        x"00000000FFB0A079",
        x"0007806000000918",
        x"0100003C00000000",
        x"3803040000000818",
        x"0102000000000000",
        x"00000000FFA08A7B",
        x"000000A1FFA09ADB",
        x"00000000FFA0A079",
        x"00000003FF600A7A",
        x"00000018000009B7",
        x"000000E1FF609ADB",
        x"00000000FF60A879",
        x"00000000000091BF",
        x"00000007FF600A7A",
        x"00000023000009B7",
        x"00000007000000B7",
        x"000000F1FF609ADB",
        x"00000000000002BF",
        x"00000000FF60A879",
        x"FFFFFFE0FF600A7A",
        x"FFFFFFDE000000B7",
        x"000003D5000009B7",
        x"000000F1FF609ADB",
        x"00000000FF60A879",
        x"000000000000100F",
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

