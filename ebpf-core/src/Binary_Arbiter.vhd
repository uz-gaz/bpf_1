--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Binary arbiter to control Shared Memory access.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity Binary_Arbiter is
    port ( 	
        clk : in std_logic;
        reset : in std_logic;
        bus_frame : in std_logic;
        req : in std_logic_vector(1 downto 0);
        granted : out std_logic_vector(1 downto 0)
    );
end Binary_Arbiter;

architecture Behavioral of Binary_Arbiter is
    signal PRIO : std_logic;
    signal sig_granted : std_logic_vector(1 downto 0);
begin

    SYNC_PROC: process (clk)
    begin
        if (clk'event and clk = '1') then
            if (reset = '1') then
                PRIO <= '0';
            elsif (sig_granted(0) = '1') then
                PRIO <= '1';
            elsif (sig_granted(1) = '1') then
                PRIO <= '0';
            end if;
        end if;
    end process;

    sig_granted(0) <= not bus_frame and ((req(0) and not PRIO) or (req(0) and not req(1)));
    sig_granted(1) <= not bus_frame and ((req(1) and     PRIO) or (req(1) and not req(0)));

    granted(0) <= sig_granted(0);
    granted(1) <= sig_granted(1);

end Behavioral;