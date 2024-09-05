--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Generic multiplexer for any input and seletor width.
--
-- Comment:      Adapted from this answer on stack overflow:
--                   https://stackoverflow.com/a/28514135
--               Requires compilation with standard 2008 of VHDL.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- As anonymous arrays can't be used and neither be declared inside entities
-- it is needed to declare a type inside a package in order to be used by
-- the Multiplexer entity.
package bus_array_pkg is
    type Bus_Array is array (natural range <>) of std_logic_vector;
end package;

-- Once a package is compiled, even though the next entity is written within the
-- same file, it is necessary to tell the compiler again which libraries we use.
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.bus_array_pkg.all;

entity Multiplexer is
    generic (
        BUS_WIDTH : positive;
        SEL_WIDTH : positive
    );

    port (
        input : in Bus_Array (2**SEL_WIDTH - 1 downto 0) (BUS_WIDTH - 1 downto 0);
        sel : in std_logic_vector(SEL_WIDTH - 1 downto 0);
        output : out std_logic_vector(BUS_WIDTH - 1 downto 0)
    );
end Multiplexer;

architecture Behavioral of Multiplexer is
begin
    output <= input(conv_integer(sel));
end Behavioral;