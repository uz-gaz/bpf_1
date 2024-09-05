--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Register Bank module for a BPF core
--
-- Comment:      Based on the RegBank entity provided for the project of
--               Computer Architecture and Organization II, subject of 
--               Computer Engineering degree from the University of Zaragoza.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity BPF_Register_Bank is
    port (
        clk : in std_logic;
        reset : in std_logic;

        reg_A : in std_logic_vector (3 downto 0);
        reg_B : in std_logic_vector (3 downto 0);
        reg_W : in std_logic_vector (3 downto 0);
        input : in std_logic_vector (63 downto 0);
        write_en : in std_logic;
        r0_write_en : in std_logic;
        get_params : in std_logic_vector (1 downto 0);

        output_A : out std_logic_vector (63 downto 0);
        output_B : out std_logic_vector (63 downto 0);
        output_R0 : out std_logic_vector (63 downto 0)
    );
end BPF_Register_Bank;

architecture Behavioral of BPF_Register_Bank is

    type Reg_Array is array (0 to 10) of std_logic_vector (63 downto 0);
    signal reg_file : Reg_Array;

    signal get_params_1_2_3, get_params_4_5 : std_logic;
    
begin

    SYNC_PROC: process (clk)
    begin 
        -- Writes on low edge while register buffers are written on high edge
        -- so input data is glitch free. Otherwise it would come from a just
        -- updated register and data would become unstable.
        if (clk'event and clk = '0') then
            if reset = '1' then 	
                for i in 0 to 10 loop
                    reg_file(i) <= (others => '0');
                end loop;
            else
                if write_en = '1' and reg_W <= "1010" then
                    reg_file(conv_integer(reg_W)) <= input;
                end if;
                if r0_write_en = '1' then
                    reg_file(0) <= input;
                end if;
            end if;
        end if;
    end process;

    get_params_1_2_3 <= get_params(0);
    get_params_4_5 <= get_params(1);
    
    output_A <= reg_file(2) when get_params_1_2_3 = '1' else
                reg_file(4) when get_params_4_5 = '1' else
                reg_file(conv_integer(reg_A)) when reg_A <= "1010" else (others => '0');
    output_B <= reg_file(3) when get_params_1_2_3 = '1' else
                reg_file(5) when get_params_4_5 = '1' else
                reg_file(conv_integer(reg_B)) when reg_B <= "1010" else (others => '0');

    output_R0 <= reg_file(1) when get_params_1_2_3 = '1' else
                 reg_file(0);
    
end Behavioral;