--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Component that controlls bpf maps info.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.bpf.all;

entity BPF_Map_Unit is
    port (
        clk : in std_logic;
        reset : in std_logic;

        MAP_id : in std_logic_vector(0 downto 0);
        MAP_write_en : in std_logic;
        MAP_input : in std_logic_vector(31 downto 0);
        MAP_output : out std_logic_vector(31 downto 0)
    );
end BPF_Map_Unit;

architecture Behavioral of BPF_Map_Unit is

    type map_reg_array is array(0 to 1) of std_logic_vector(31 downto 0);
    signal map_reg_file : map_reg_array := ( others => x"00000000");

    signal map_reg_out : std_logic_vector(31 downto 0);

begin

    process (clk)
    begin
        if (clk'event and clk = '1') then
            if (MAP_write_en = '1') then
                map_reg_file(conv_integer(MAP_id)) <= MAP_input;
            end if;
        end if;
    end process;

    map_reg_out <= map_reg_file(conv_integer(MAP_id));

    MAP_output <= map_reg_out;

end Behavioral;