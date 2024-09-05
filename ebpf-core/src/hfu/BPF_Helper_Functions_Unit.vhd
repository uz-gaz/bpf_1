--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Module that encapsulates BPF helper functions logic, assuming
--               that it receives function identifier on ID stage and
--               executes it on MEM stage with stable operands r1-r5.
--
-- Comm:         No argument is ready until MEM stage. Functions could partially
--               execute on EX stage if arguments are not needed for the task.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.bpf.all;

entity BPF_Helper_Functions_Unit is
    port (
        clk : in std_logic;
        reset : in std_logic;

        function_id : in std_logic_vector (31 downto 0);

        -- Only signal when its going to advance, otherwise it could generate
        -- incorrect state inside HFU
        go_ID : in std_logic;
        go_EX : in std_logic;

        num_params : out std_logic_vector (2 downto 0); -- Info for Hazard Unit
        error_function_id : out std_logic; -- Info for Exception Unit

        -- Five function parameters
        p1, p2, p3, p4, p5 : in std_logic_vector (63 downto 0);

        await_EX : out std_logic;
        await_MEM : out std_logic;
        error_execution : out std_logic; -- Info for Exception Unit
        result : out std_logic_vector (63 downto 0);

        -- MAP Unit bus
        HFU_MAP_ena : out std_logic;
        HFU_MAP_id : out std_logic_vector(0 downto 0);
        HFU_MAP_output : in std_logic_vector(31 downto 0);

        HFU_MAP_req : out std_logic;
        HFU_MAP_granted : in std_logic;
        HFU_MAP_bus_frame : out std_logic
    );
end BPF_Helper_Functions_Unit;

architecture Behavioral of BPF_Helper_Functions_Unit is

    component Register_N is
        generic ( SIZE : positive := 64 );
        port (
            clk : in std_logic;
            reset : in std_logic;
            load : in std_logic;
            input : in std_logic_vector (SIZE - 1 downto 0);
            output : out std_logic_vector (SIZE - 1 downto 0)
        );
    end component;

    -- --

    signal LOOKUP_error : std_logic;
    signal LOOKUP_elem_ptr : std_logic_vector(14 downto 0);
    signal LOOKUP_bus, LOOKUP_key_masked, LOOKUP_key : std_logic_vector(63 downto 0);
    signal LOOKUP_id : std_logic_vector(0 downto 0);

    -- --

    signal map_info : std_logic_vector(31 downto 0);
    signal keysz, valsz : std_logic_vector(1 downto 0);
    signal max_entries : std_logic_vector(14 downto 0);
    signal base_ptr : std_logic_vector(14 downto 0);
    signal valid, save_map_info : std_logic;

    -- --

    type HFUState_t is (
            INIT_S,
            ERROR_ID_S,

            -- bpf_lookup_elem(map_id, key)
            LOOKUP_EX_S, LOOKUP_MEM_REQ_S, LOOKUP_MEM_S

        );
    signal hfu_state, hfu_next_state : HFUState_t;

begin

    map_info_reg_block: Register_N
        generic map ( SIZE => 32 )
        port map (
            clk => clk,
            reset => reset,
            load => save_map_info,
            input => HFU_MAP_output,
            output => map_info
        );

    -- -- -- 
    valid <= map_info(31);
    max_entries <= map_info(30 downto 16);
    valsz <= map_info(15 downto 14);
    keysz <= map_info(13 downto 12);
    base_ptr <= map_info(11 downto 0) & "000";
    -- -- -- 

    ----------------------------------------------------------------------------
    -- Lookup element ----------------------------------------------------------

    LOOKUP_bus <=
        (others => '0') when LOOKUP_error = '1' else        -- 'bpf_lookup_elem' returns NULL if element does not exist
        (47 downto 0 => '0') & (('0' & LOOKUP_elem_ptr) + BPF_MEM_SHARED_BASE_U16);   -- elem_ptr is actually an offset, but a full pointer is needed

    LOOKUP_error <=
        '1' when LOOKUP_key_masked > max_entries else
        '1' when valid = '0' else
        '0';

    LOOKUP_id <= p1(0 downto 0);
    LOOKUP_key <= p2;

    LOOKUP_key_masked <=
        (55 downto 0 => '0') & LOOKUP_key(7 downto 0) when keysz = "00" else
        (47 downto 0 => '0') & LOOKUP_key(15 downto 0) when keysz = "01" else
        (31 downto 0 => '0') & LOOKUP_key(31 downto 0) when keysz = "10" else
        LOOKUP_key(63 downto 0); -- when keysz = "11";
    
      -- elem_ptr := base_ptr + (key * valsz)              [BPF_MAP_TYPE_ARRAY]
    LOOKUP_elem_ptr <= base_ptr + std_logic_vector(shift_left(unsigned(LOOKUP_key_masked(14 downto 0)), conv_integer(valsz)));

    ----------------------------------------------------------------------------

    HFU_MAP_id <= LOOKUP_id;
    result <= LOOKUP_bus;

    ----------------------------------------------------------------------------

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

    CONTROL_PROC: process
        (
            hfu_state, go_ID, go_EX, function_id,
            p1, p2, p3, p4, p5,
            HFU_MAP_granted
        )

        variable dispatch_state : boolean;

    begin
        -- Default values
        hfu_next_state <= hfu_state;
        await_EX <= '0';
        await_MEM <= '0';

        HFU_MAP_ena <= '0';
        HFU_MAP_req <= '0';
        HFU_MAP_bus_frame <= '0';

        save_map_info <= '0';

        error_function_id <= '0';
        error_execution <= '0';

        dispatch_state := false;
        
        if (hfu_state = INIT_S) then
            dispatch_state := true;
        
        -- LOOKUP --
        elsif (hfu_state = LOOKUP_EX_S) then
            if (go_EX = '1') then
                hfu_next_state <= LOOKUP_MEM_REQ_S;
            end if;
        elsif (hfu_state = LOOKUP_MEM_REQ_S) then
            await_MEM <= '1';
            HFU_MAP_req <= '1';
            if (HFU_MAP_granted = '1') then
                hfu_next_state <= LOOKUP_MEM_S;

                HFU_MAP_ena <= '1';
                save_map_info <= '1';
            --else -- HFU_MAP_granted = '0'
            end if;
        elsif (hfu_state = LOOKUP_MEM_S) then
            dispatch_state := true;

        -- ERROR --
        elsif (hfu_state = ERROR_ID_S) then
            error_function_id <= '1';
        end if;


        if (dispatch_state) then
            -- Dispatch
            if (go_ID = '1' and function_id = x"00000000") then
                hfu_next_state <= LOOKUP_EX_S;

            elsif (go_ID = '1') then -- Not available function
                hfu_next_state <= ERROR_ID_S;
            else
                hfu_next_state <= INIT_S;
            end if;
        end if;
    
    end process;  
    
    num_params <= 
        "010" when function_id = x"00000000" else
        "000";

end Behavioral;
