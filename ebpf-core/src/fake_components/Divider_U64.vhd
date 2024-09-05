--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Fake Divider unit that replaces Xilinx's IP for simulating
--               out of the Vivado environment.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity Divider_U64 is
    port (
        aclk : in std_logic;
        aresetn : in std_logic;
        s_axis_divisor_tvalid : in std_logic;
        s_axis_divisor_tready : out std_logic;
        s_axis_divisor_tdata : in std_logic_vector(63 downto 0);
        s_axis_dividend_tvalid : in std_logic;
        s_axis_dividend_tready : out std_logic;
        s_axis_dividend_tdata : in std_logic_vector(63 downto 0);
        m_axis_dout_tvalid : out std_logic;
        m_axis_dout_tdata : out std_logic_vector(127 downto 0)
  );
end Divider_U64;

architecture Behavioral of Divider_U64 is

    signal clk : std_logic;

    signal a : std_logic_vector(63 downto 0);
    signal b : std_logic_vector(63 downto 0);
    signal result : std_logic_vector(127 downto 0);
    signal ok_a, ok_b, ok_result : std_logic;

    signal cycles_to_divide : integer := 0;
    signal reset_cycles : integer := 0;
    signal cycles_not_ready : integer := 0;

    signal divide : std_logic := '0';
begin

    clk <= aclk;

    b <= s_axis_divisor_tdata;
    a <= s_axis_dividend_tdata;
    m_axis_dout_tdata <= result;

    ok_a <= s_axis_dividend_tvalid;
    ok_b <= s_axis_divisor_tvalid;
    m_axis_dout_tvalid <= ok_result;

    process(clk)
        variable dividend, divisor : unsigned (63 downto 0);
        variable quotient : unsigned (63 downto 0);
        variable remainder : unsigned (63 downto 0);
    begin
        if (clk'event and clk = '1') then
            if (aresetn = '0') then
                if (reset_cycles = 1) then
                    -- reset
                    cycles_to_divide <= 0;
                    divide <= '0';
                    ok_result <= '0';
                    result <= (others => 'X'); -- To show the output isn't valid yet

                    s_axis_divisor_tready <= '0';
                    s_axis_dividend_tready <= '0';
                    cycles_not_ready <= 0;

                    reset_cycles <= 0;
                else 
                    reset_cycles <= reset_cycles + 1;
                end if;
            else
                reset_cycles <= 0;
            
                ok_result <= '0';
                result <= (others => 'X'); -- To show the output isn't valid yet

                s_axis_divisor_tready <= '0';
                s_axis_dividend_tready <= '0';

                if (cycles_not_ready = 4) then
                    s_axis_divisor_tready <= '1';
                    s_axis_dividend_tready <= '1';

                    cycles_not_ready <= 0;
                else
                    cycles_not_ready <= cycles_not_ready + 1;
                end if;
    
                if (divide = '1') then
                    if (cycles_to_divide = 5) then -- Divide...
    
                        quotient := dividend / divisor;
                        remainder := dividend rem divisor;
        
                        result <= std_logic_vector(quotient) & std_logic_vector(remainder);
        
                        ok_result <= '1';
                        cycles_to_divide <= 0;
    
                        divide <= '0';
                    else
                        cycles_to_divide <= cycles_to_divide + 1;
                    end if;
                else 
                    cycles_to_divide <= 0;
                end if;
            end if;            
        end if;

        if (ok_a = '1' and ok_b = '1' and
                s_axis_divisor_tready = '1' and s_axis_dividend_tready = '1')
        then
            divide <= '1';

            dividend := unsigned(a);
            divisor := unsigned(b);
        end if;
    end process;
end architecture;