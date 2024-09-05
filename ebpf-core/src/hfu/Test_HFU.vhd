--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Module that encapsulates BPF helper functions logic, assuming
--               that it receives function identifier on ID stage and
--               executes it on MEM stage with stable operands r1-r5.
--
-- Comm:         This is a test oriented entity that does not implement any
--               valuable helper function.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.bpf.all;

entity BPF_Helper_Functions_Unit is
    port (
        clk : in std_logic;
        reset : in std_logic;

        function_id : in std_logic_vector (31 downto 0);
        go_ID : in std_logic; -- Must be ON the cycle call is on ID stage and can continue to EX
        go_EX : in std_logic; -- Must be ON the cycle call is on EX stage and can continue to MEM

        num_params : out std_logic_vector (2 downto 0); -- Info for Hazard Unit
        error_function_id : out std_logic; -- Info for Exception Unit

        -- Five function parameters
        p1, p2, p3, p4, p5 : in std_logic_vector (63 downto 0);

        await : out std_logic;
        error_execution : out std_logic; -- Info for Exception Unit
        result : out std_logic_vector (63 downto 0)
    );
end BPF_Helper_Functions_Unit;

architecture Behavioral of BPF_Helper_Functions_Unit is

    type HFUState_t is (
        INIT_S,

        FUNCTION0_EX_S, FUNCTION0_MEM_S, -- Receives 0 parameters
        FUNCTION1_EX_S, FUNCTION1_MEM_S, -- Receives 1 parameters
        FUNCTION2_EX_S, FUNCTION2_MEM_S, -- Receives 2 parameters
        FUNCTION3_EX_S, FUNCTION3_MEM_S, -- Receives 3 parameters
        FUNCTION4_EX_S, FUNCTION4_MEM_S, -- Receives 4 parameters
        FUNCTION5_EX_S, FUNCTION5_MEM_S, -- Receives 5 parameters
        ERROR_FUNCTION_EX_S, ERROR_FUNCTION_MEM_S, -- Throws execution error

        EXECUTION_ERROR_S
        );
    signal hfu_state, hfu_next_state : HFUState_t;

begin

    SYNC_PROC: process (clk)
    begin
        if (clk'event and clk = '1') then
            if (reset = '1') then
                hfu_state <= INIT_S;
            else
                hfu_state <= hfu_next_state;
            end if;        
        end if;
    end process;

    CONTROL_PROC: process (hfu_state, go_ID, go_EX, function_id, p1, p2, p3, p4, p5)
    
        -- Last execution hfu_state of any function MUST be able to dispatch, and
        -- MUST do so setting this signal to 1
        variable dispatch_state : std_logic;
        
    begin
        -- Default values
        hfu_next_state <= hfu_state;
        dispatch_state := '0';

        await <= '0';
        result <= x"0000000000000000";
        num_params <= "000";

        error_function_id <= '0';
        error_execution <= '0';

        if (hfu_state = INIT_S) then
            dispatch_state := '1';

        ------------------------------------------------------------------------
        ------------------------------------------------------------------------

        -- Custom functions --
        elsif (hfu_state = FUNCTION0_EX_S and go_EX = '1') then
            hfu_next_state <= FUNCTION0_MEM_S;
        elsif (hfu_state = FUNCTION0_MEM_S) then
            dispatch_state := '1';
            result <= x"FFFFFFFFFFFFFFFF";


        elsif (hfu_state = FUNCTION1_EX_S and go_EX = '1') then
            hfu_next_state <= FUNCTION1_MEM_S;
        elsif (hfu_state = FUNCTION1_MEM_S) then
            dispatch_state := '1';
            result <= p1;


        elsif (hfu_state = FUNCTION2_EX_S and go_EX = '1') then
            hfu_next_state <= FUNCTION2_MEM_S;
        elsif (hfu_state = FUNCTION2_MEM_S) then
            dispatch_state := '1';
            result <= p1 or p2;


        elsif (hfu_state = FUNCTION3_EX_S and go_EX = '1') then
            hfu_next_state <= FUNCTION3_MEM_S;
        elsif (hfu_state = FUNCTION3_MEM_S) then
            dispatch_state := '1';
            result <= p1 or p2 or p3;


        elsif (hfu_state = FUNCTION4_EX_S and go_EX = '1') then
            hfu_next_state <= FUNCTION4_MEM_S;
        elsif (hfu_state = FUNCTION4_MEM_S) then
            dispatch_state := '1';
            result <= p1 or p2 or p3 or p4;


        elsif (hfu_state = FUNCTION5_EX_S and go_EX = '1') then
            hfu_next_state <= FUNCTION5_MEM_S;
        elsif (hfu_state = FUNCTION5_MEM_S) then
            dispatch_state := '1';
            result <= p1 or p2 or p3 or p4 or p5;


        elsif (hfu_state = ERROR_FUNCTION_EX_S and go_EX = '1') then
            hfu_next_state <= ERROR_FUNCTION_MEM_S;
        elsif (hfu_state = ERROR_FUNCTION_MEM_S) then
            hfu_next_state <= EXECUTION_ERROR_S;
            error_execution <= '1';


        
        elsif (hfu_state = EXECUTION_ERROR_S) then
            error_execution <= '1';
        end if;


        -- DISPATCH ------------------------------------------------------------
        ------------------------------------------------------------------------
        if (dispatch_state = '1') then
            hfu_next_state <= INIT_S;
            
            -- Custom functions --
            if (go_ID = '1' and function_id = x"00000000") then
                hfu_next_state <= FUNCTION0_EX_S;
            elsif (go_ID = '1' and function_id = x"00000001") then
                hfu_next_state <= FUNCTION1_EX_S;
            elsif (go_ID = '1' and function_id = x"00000002") then
                hfu_next_state <= FUNCTION2_EX_S;
            elsif (go_ID = '1' and function_id = x"00000003") then
                hfu_next_state <= FUNCTION3_EX_S;
            elsif (go_ID = '1' and function_id = x"00000004") then
                hfu_next_state <= FUNCTION4_EX_S;
            elsif (go_ID = '1' and function_id = x"00000005") then
                hfu_next_state <= FUNCTION5_EX_S;
            elsif (go_ID = '1' and function_id = x"FFFFFFFF") then
                hfu_next_state <= ERROR_FUNCTION_EX_S;

            
            elsif (go_ID = '1') then -- Not available function
                error_function_id <= '1';
            end if;
        end if;



        -- This has to be assigned even though GO signal is not ON --
        if (function_id = x"00000000") then
            num_params <= "000";
        elsif (function_id = x"00000001") then
            num_params <= "001";
        elsif (function_id = x"00000002") then
            num_params <= "010";
        elsif (function_id = x"00000003") then
            num_params <= "011";
        elsif (function_id = x"00000004") then
            num_params <= "100";
        elsif (function_id = x"00000005") then
            num_params <= "101";
        elsif (function_id = x"FFFFFFFF") then
            num_params <= "101";
        end if;

    end process;  
    

end Behavioral;
