--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Generic size register that saves data 1 cycle after
--               setting load signal. If load is set, it will forward input,
--               otherwise it will output saved data.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity Delayed_Register_N is
    generic ( SIZE : positive := 64 );

    port (
        clk : in std_logic;
        reset : in std_logic;
        load : in std_logic;

        input : in std_logic_vector (SIZE - 1 downto 0);
        output : out std_logic_vector (SIZE - 1 downto 0)
    );
end Delayed_Register_N;

architecture Behavioral of Delayed_Register_N is

    signal use_saved_data, next_state, save : std_logic;
    signal saved_data : std_logic_vector(SIZE - 1 downto 0);

begin

    SYNC_PROC: process (clk)
    begin
        if (clk'event and clk = '1') then
            if (reset = '1') then
                use_saved_data <= '0';
                saved_data <= (others => '0');
            else
                use_saved_data <= next_state;
                if (save = '1') then
                    saved_data <= input;
                end if;
            end if;        
        end if;
    end process;

    CTRL_PROC: process (use_saved_data, load)
    begin
        save <= '0';

        if (use_saved_data <= '0') then
            if (load = '1') then
                next_state <= '0';
            else
                next_state <= '1';
                save <= '1';
            end if;

        else
            if (load = '1') then
                next_state <= '0';
            else
                next_state <= '1';
            end if;

        end if;
   end process;

   output <= saved_data when use_saved_data = '1' else input;

end Behavioral;
