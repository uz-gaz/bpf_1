--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  IO and memory system for BPF processor to be used as
--               peripheral using an AXI4 Lite bus.
--
-- Comm:         This implementation assumes AXI write address and data
--               handshakes occur simultaneously. That means 'awready' and
--               'wready' will be set only at the same cycle in which both
--               'awvalid' and 'wvalid' are active.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.bpf.all;

entity BPF_IO_Mem_System is
    port (
        -- AXI slave interface
        S_AXI_aclk : in std_logic;
        S_AXI_aresetn : in std_logic; -- This Signal is Active LOW

        S_AXI_awaddr : in std_logic_vector(31 downto 0);
        S_AXI_awprot : in std_logic_vector(2 downto 0);
        S_AXI_awvalid : in std_logic;
        S_AXI_awready : out std_logic;

        S_AXI_wdata : in std_logic_vector(31 downto 0);
        S_AXI_wstrb : in std_logic_vector(3 downto 0);
        S_AXI_wvalid : in std_logic;
        S_AXI_wready : out std_logic;

        S_AXI_bresp : out std_logic_vector(1 downto 0);
        S_AXI_bvalid : out std_logic;
        S_AXI_bready : in std_logic;

        S_AXI_araddr: in std_logic_vector(31 downto 0);
        S_AXI_arprot : in std_logic_vector(2 downto 0);
        S_AXI_arvalid : in std_logic;
        S_AXI_arready : out std_logic;
        
        S_AXI_rdata : out std_logic_vector(31 downto 0);
        S_AXI_rresp : out std_logic_vector(1 downto 0);
        S_AXI_rvalid : out std_logic;
        S_AXI_rready : in std_logic;

        -- Signals to control execution
        CORE_reset : out std_logic;
        CORE_sleep : out std_logic;
        CORE_reg_dst : out std_logic_vector (3 downto 0);
        CORE_reg_write : out std_logic;
        CORE_reg_input : out std_logic_vector (63 downto 0);

        CORE_sleeping : in std_logic;
        CORE_finish : in std_logic;
        CORE_exception : in std_logic;
        CORE_output : in std_logic_vector (63 downto 0);

        -- Signals to communicate with data memory
        DMEM_addr : in std_logic_vector (63 downto 0);
        DMEM_input : in std_logic_vector (63 downto 0);
        DMEM_write_en : in std_logic;
        DMEM_read_en : in std_logic;
        DMEM_size : in std_logic_vector (1 downto 0);

        DMEM_atomic : in std_logic;
        DMEM_op : in std_logic_vector (3 downto 0);
        DMEM_cmpxchg_token : in std_logic_vector (63 downto 0);
        
        DMEM_ready : out std_logic;
        DMEM_error : out std_logic;
        DMEM_output : out std_logic_vector (63 downto 0);

        -- Signals to communicate with instruction memory
        IMEM_addr : in std_logic_vector (11 downto 0);
        IMEM_read_en : in std_logic;

        IMEM_output : out std_logic_vector (63 downto 0);

        -- MAP Unit bus
        HFU_MAP_ena : in std_logic;
        HFU_MAP_id : in std_logic_vector(0 downto 0);
        HFU_MAP_output : out std_logic_vector(31 downto 0);

        HFU_MAP_req : in std_logic;
        HFU_MAP_granted : out std_logic;
        HFU_MAP_bus_frame : in std_logic
    );
end BPF_IO_Mem_System;

architecture Behavioral of BPF_IO_Mem_System is

    component Block_Mem_Inst is
        port (
            clka : in std_logic;
            ena : in std_logic;
    
            addra : in std_logic_vector(11 downto 0);
            dina : in std_logic_vector(63 downto 0);
            douta : out std_logic_vector(63 downto 0);
            wea : in std_logic_vector(7 downto 0)
        );
    end component;

    component Block_Mem_Unshared is
        port (
            clka : in std_logic;
            ena : in std_logic;
    
            addra : in std_logic_vector(8 downto 0);
            dina : in std_logic_vector(63 downto 0);
            douta : out std_logic_vector(63 downto 0);
            wea : in std_logic_vector(7 downto 0)
        );
    end component;

    component Block_Mem_Shared is
        port (
            clka : in std_logic;
            ena : in std_logic;
    
            addra : in std_logic_vector(11 downto 0);
            dina : in std_logic_vector(63 downto 0);
            douta : out std_logic_vector(63 downto 0);
            wea : in std_logic_vector(7 downto 0)
        );
    end component;

    component BPF_Map_Unit is
        port (
            clk : in std_logic;
            reset : in std_logic;

            MAP_id : in std_logic_vector(0 downto 0);
            MAP_write_en : in std_logic;
            MAP_input : in std_logic_vector(31 downto 0);
            MAP_output : out std_logic_vector(31 downto 0)
        );
    end component;

    component BPF_Data_Mem_Interface is
        port (
            clk : in std_logic;
            reset : in std_logic;
    
            -- Input --
            DMEM_addr : in std_logic_vector (63 downto 0);
            DMEM_input : in std_logic_vector (63 downto 0);
            DMEM_write_en : in std_logic;
            DMEM_read_en : in std_logic;
            DMEM_size : in std_logic_vector (1 downto 0);
    
            DMEM_atomic : in std_logic;
            DMEM_op : in std_logic_vector (3 downto 0);
            DMEM_cmpxchg_token : in std_logic_vector (63 downto 0);
            
            DMEM_ready : out std_logic;
            DMEM_error : out std_logic;
            DMEM_output : out std_logic_vector (63 downto 0);
    
            -- Translated signals --
            DATAIF_ena : out std_logic;
            DATAIF_addra : out std_logic_vector(11 downto 0);
            DATAIF_dina : out std_logic_vector(63 downto 0);
            DATAIF_douta : in std_logic_vector(63 downto 0);
            DATAIF_wea : out std_logic_vector(7 downto 0);
            DATAIF_shared : out std_logic;
    
            -- Arbiter signals --
            ARB_DATA_request : out std_logic;
            ARB_DATA_bus_frame : out std_logic;
            ARB_DATA_granted : in std_logic
        );
    end component;

    component BPF_AXI_Controller is
        port (
            -- AXI slave interface
            S_AXI_aclk : in std_logic;    -- Global Clock Signal
            S_AXI_aresetn : in std_logic; -- Global Reset Signal. This Signal is Active LOW
    
            S_AXI_awaddr : in std_logic_vector(31 downto 0);
            S_AXI_awprot : in std_logic_vector(2 downto 0);
            S_AXI_awvalid : in std_logic;
            S_AXI_awready : out std_logic;
    
            S_AXI_wdata : in std_logic_vector(31 downto 0);
            S_AXI_wstrb : in std_logic_vector(3 downto 0);
            S_AXI_wvalid : in std_logic;
            S_AXI_wready : out std_logic;
    
            S_AXI_bresp : out std_logic_vector(1 downto 0);
            S_AXI_bvalid : out std_logic;
            S_AXI_bready : in std_logic;
    
            S_AXI_araddr: in std_logic_vector(31 downto 0);
            S_AXI_arprot : in std_logic_vector(2 downto 0);
            S_AXI_arvalid : in std_logic;
            S_AXI_arready : out std_logic;
            
            S_AXI_rdata : out std_logic_vector(31 downto 0);
            S_AXI_rresp : out std_logic_vector(1 downto 0);
            S_AXI_rvalid : out std_logic;
            S_AXI_rready : in std_logic;
    
            AXIC_ena : out std_logic;
            AXIC_addra : out std_logic_vector(11 downto 0);
            AXIC_dina : out std_logic_vector(63 downto 0);
            AXIC_douta : in std_logic_vector(63 downto 0);
            AXIC_wea : out std_logic_vector(7 downto 0);
            AXIC_shared : out std_logic;
            AXIC_unshared : out std_logic;
            AXIC_inst : out std_logic;
            AXIC_map : out std_logic;
    
            ARB_AXIC_request : out std_logic;
            ARB_AXIC_bus_frame : out std_logic;
            ARB_AXIC_granted : in std_logic;
    
            CORE_reset : out std_logic;
            CORE_sleep : out std_logic;
            CORE_reg_dst : out std_logic_vector (3 downto 0);
            CORE_reg_write : out std_logic;
            CORE_reg_input : out std_logic_vector (63 downto 0);
    
            CORE_sleeping : in std_logic;
            CORE_finish : in std_logic;
            CORE_exception : in std_logic;
            CORE_output : in std_logic_vector (63 downto 0);

            AXIC_MAP_id : out std_logic_vector(0 downto 0);
            AXIC_MAP_write_en : out std_logic;
            AXIC_MAP_input : out std_logic_vector(31 downto 0);
            AXIC_MAP_output : in std_logic_vector(31 downto 0);
        
            AXIC_MAP_req : out std_logic;
            AXIC_MAP_granted : in std_logic;
            AXIC_MAP_bus_frame : out std_logic
        );
    end component;

    component Binary_Arbiter is
        port ( 	
            clk : in std_logic;
            reset : in std_logic;
            bus_frame : in std_logic;
            req : in std_logic_vector(1 downto 0);
            granted : out std_logic_vector(1 downto 0)
        );
    end component;

    signal INST_ena : std_logic;
    signal INST_addra : std_logic_vector(11 downto 0);
    signal INST_dina, INST_douta : std_logic_vector(63 downto 0);
    signal INST_wea : std_logic_vector(7 downto 0);

    signal UNSHARED_ena : std_logic;
    signal UNSHARED_addra : std_logic_vector(8 downto 0);
    signal UNSHARED_dina, UNSHARED_douta : std_logic_vector(63 downto 0);
    signal UNSHARED_wea : std_logic_vector(7 downto 0);

    signal SHARED_ena : std_logic;
    signal SHARED_addra : std_logic_vector(11 downto 0);
    signal raw_shared_addra : std_logic_vector(11 downto 0);
    signal SHARED_dina, SHARED_douta : std_logic_vector(63 downto 0);
    signal SHARED_wea : std_logic_vector(7 downto 0);
    

    signal DATAIF_ena : std_logic;
    signal DATAIF_addra : std_logic_vector(11 downto 0);
    signal DATAIF_dina : std_logic_vector(63 downto 0);
    signal DATAIF_douta : std_logic_vector(63 downto 0);
    signal DATAIF_wea : std_logic_vector(7 downto 0);
    signal DATAIF_shared : std_logic;
    signal DATAIF_unshared : std_logic;
    signal DATAIF_read_from_shared : std_logic;

    signal ARB_DATA_request : std_logic;
    signal ARB_DATA_bus_frame : std_logic;
    signal ARB_DATA_granted : std_logic;

    signal INSTIF_ena : std_logic;
    signal INSTIF_addra : std_logic_vector(11 downto 0);
    signal INSTIF_dina : std_logic_vector(63 downto 0);
    signal INSTIF_douta : std_logic_vector(63 downto 0);
    signal INSTIF_wea : std_logic_vector(7 downto 0);

    -- AXI controller --
    signal AXIC_ena : std_logic;
    signal AXIC_addra : std_logic_vector(11 downto 0);
    signal AXIC_dina : std_logic_vector(63 downto 0);
    signal AXIC_douta : std_logic_vector(63 downto 0);
    signal AXIC_wea : std_logic_vector(7 downto 0);
    signal AXIC_shared : std_logic;
    signal AXIC_unshared : std_logic;
    signal AXIC_inst : std_logic;
    signal AXIC_map : std_logic;

    signal ARB_AXIC_request : std_logic;
    signal ARB_AXIC_bus_frame : std_logic;
    signal ARB_AXIC_granted : std_logic;

    signal MAP_id : std_logic_vector(0 downto 0);
    signal MAP_write_en : std_logic;
    signal MAP_input : std_logic_vector(31 downto 0);
    signal MAP_output : std_logic_vector(31 downto 0);


    signal AXIC_MAP_id : std_logic_vector(0 downto 0);
    signal AXIC_MAP_write_en : std_logic;
    signal AXIC_MAP_input : std_logic_vector(31 downto 0);
    signal AXIC_MAP_output : std_logic_vector(31 downto 0);

    signal AXIC_MAP_req : std_logic;
    signal AXIC_MAP_granted : std_logic;
    signal AXIC_MAP_bus_frame : std_logic;

    signal MAP_ARBITER_bus_frame : std_logic;
    signal MAP_ARBITER_req, MAP_ARBITER_granted : std_logic_vector(1 downto 0);

    -- -- --

    signal clk : std_logic;
    signal reset : std_logic;

    signal arbiter_bus_frame : std_logic;
    signal arbiter_req, arbiter_granted : std_logic_vector(1 downto 0);

begin

    clk <= S_AXI_aclk;
    reset <= not S_AXI_aresetn;

    ----------------------------------------------------------------------------
    -- DATA MEMORY INTERFACE ---------------------------------------------------
    ----------------------------------------------------------------------------

    data_mem_iface_i : BPF_Data_Mem_Interface
        port map (
            clk => clk,
            reset => reset,

            DMEM_addr => DMEM_addr,
            DMEM_input => DMEM_input,
            DMEM_write_en => DMEM_write_en,
            DMEM_read_en => DMEM_read_en,
            DMEM_size => DMEM_size,
            DMEM_atomic => DMEM_atomic,
            DMEM_op => DMEM_op,
            DMEM_cmpxchg_token => DMEM_cmpxchg_token,
            DMEM_ready => DMEM_ready,
            DMEM_error => DMEM_error,
            DMEM_output => DMEM_output,

            DATAIF_ena => DATAIF_ena,
            DATAIF_addra => DATAIF_addra,
            DATAIF_dina => DATAIF_dina,
            DATAIF_douta => DATAIF_douta,
            DATAIF_wea => DATAIF_wea,
            DATAIF_shared => DATAIF_shared,

            ARB_DATA_request => ARB_DATA_request,
            ARB_DATA_bus_frame => ARB_DATA_bus_frame,
            ARB_DATA_granted => ARB_DATA_granted
        );

    DATAIF_unshared <= not DATAIF_shared;

    process (clk)
    begin
        if (clk'event and clk = '1') then
            if (DATAIF_ena = '1') then 
                DATAIF_read_from_shared <= DATAIF_shared;
            end if;        
        end if;
    end process;

    -- DMEM reads from 2 different BRAMs
    DATAIF_douta <= SHARED_douta when DATAIF_read_from_shared = '1' else UNSHARED_douta;

    ----------------------------------------------------------------------------
    -- INSTRUCTION MEMORY INTERFACE --------------------------------------------
    ----------------------------------------------------------------------------

    INSTIF_ena <= IMEM_read_en;
    INSTIF_addra <= IMEM_addr;
    --INSTIF_dina <= (others => '0'); -- Unused
    IMEM_output <= INSTIF_douta;
    INSTIF_wea <= "00000000"; -- Unused


    -- IMEM always reads from same BRAM
    INSTIF_douta <= INST_douta;

    ----------------------------------------------------------------------------
    -- AXI CONTROLLER ----------------------------------------------------------
    ----------------------------------------------------------------------------

    axi_controller_block: BPF_AXI_Controller
        port map (
            S_AXI_aclk => S_AXI_aclk,
            S_AXI_aresetn => S_AXI_aresetn,
    
            S_AXI_awaddr => S_AXI_awaddr,
            S_AXI_awprot => S_AXI_awprot,
            S_AXI_awvalid => S_AXI_awvalid,
            S_AXI_awready => S_AXI_awready, 
    
            S_AXI_wdata => S_AXI_wdata, 
            S_AXI_wstrb => S_AXI_wstrb, 
            S_AXI_wvalid => S_AXI_wvalid, 
            S_AXI_wready => S_AXI_wready, 
            S_AXI_bresp => S_AXI_bresp,
            S_AXI_bvalid => S_AXI_bvalid,
            S_AXI_bready => S_AXI_bready,
    
            S_AXI_araddr => S_AXI_araddr,
            S_AXI_arprot => S_AXI_arprot,
            S_AXI_arvalid => S_AXI_arvalid,
            S_AXI_arready => S_AXI_arready,
            
            S_AXI_rdata => S_AXI_rdata,
            S_AXI_rresp => S_AXI_rresp,
            S_AXI_rvalid => S_AXI_rvalid,
            S_AXI_rready => S_AXI_rready,
    
            AXIC_ena => AXIC_ena,
            AXIC_addra => AXIC_addra,
            AXIC_dina => AXIC_dina,
            AXIC_douta => AXIC_douta,
            AXIC_wea => AXIC_wea,
            AXIC_shared => AXIC_shared,
            AXIC_unshared => AXIC_unshared,
            AXIC_inst => AXIC_inst,
            AXIC_map => AXIC_map,
    
            ARB_AXIC_request => ARB_AXIC_request, 
            ARB_AXIC_bus_frame => ARB_AXIC_bus_frame, 
            ARB_AXIC_granted => ARB_AXIC_granted, 
    
            CORE_reset => CORE_reset, 
            CORE_sleep => CORE_sleep, 
            CORE_reg_dst => CORE_reg_dst, 
            CORE_reg_write => CORE_reg_write, 
            CORE_reg_input => CORE_reg_input, 
    
            CORE_sleeping => CORE_sleeping, 
            CORE_finish => CORE_finish, 
            CORE_exception => CORE_exception, 
            CORE_output => CORE_output,

            AXIC_MAP_id => AXIC_MAP_id,
            AXIC_MAP_write_en => AXIC_MAP_write_en,
            AXIC_MAP_input => AXIC_MAP_input, 
            AXIC_MAP_output => AXIC_MAP_output, 
        
            AXIC_MAP_req => AXIC_MAP_req, 
            AXIC_MAP_granted => AXIC_MAP_granted, 
            AXIC_MAP_bus_frame => AXIC_MAP_bus_frame
        );

    AXIC_douta <= INST_douta when AXIC_inst = '1' else
                  UNSHARED_douta when AXIC_unshared = '1' else
                  SHARED_douta;-- when AXIC_shared = '1';

    ----------------------------------------------------------------------------
    -- INSTRUCTION MEMORY ------------------------------------------------------
    ----------------------------------------------------------------------------
  
    mem_instruction_block: Block_Mem_Inst
        port map (
            clka => clk,
            ena => INST_ena,
            addra => INST_addra,
            dina => INST_dina,
            douta => INST_douta,
            wea => INST_wea
        );

    INST_ena <= (AXIC_inst and AXIC_ena) or INSTIF_ena;
    INST_addra <= AXIC_addra when (AXIC_inst = '1' and AXIC_ena = '1') else INSTIF_addra;
    INST_dina <= AXIC_dina;
    INST_wea <= AXIC_wea when (AXIC_inst = '1' and AXIC_ena = '1') else INSTIF_wea;

    ----------------------------------------------------------------------------
    -- UNSHARED MEMORY -----------------------------------------------------------
    ----------------------------------------------------------------------------

    mem_unshared_block: Block_Mem_Unshared
        port map (
            clka => clk,
            ena => UNSHARED_ena,
            addra => UNSHARED_addra,
            dina => UNSHARED_dina,
            douta => UNSHARED_douta,
            wea => UNSHARED_wea
        );

    UNSHARED_ena <= (AXIC_unshared and AXIC_ena) or (DATAIF_unshared and DATAIF_ena);
    UNSHARED_addra <= AXIC_addra(8 downto 0) when (AXIC_unshared = '1' and AXIC_ena = '1') else DATAIF_addra(8 downto 0);
    UNSHARED_dina <= AXIC_dina when (AXIC_unshared = '1' and AXIC_ena = '1') else DATAIF_dina;
    UNSHARED_wea <= AXIC_wea when (AXIC_unshared = '1' and AXIC_ena = '1') else DATAIF_wea;

    ----------------------------------------------------------------------------
    -- SHARED MEMORY -----------------------------------------------------------
    ----------------------------------------------------------------------------

    mem_shared_block: Block_Mem_Shared
        port map (
            clka => clk,
            ena => SHARED_ena,
            addra => SHARED_addra,
            dina => SHARED_dina,
            douta => SHARED_douta,
            wea => SHARED_wea
        );

    SHARED_ena <= (AXIC_shared and AXIC_ena) or (DATAIF_shared and DATAIF_ena) ;
    raw_shared_addra <= AXIC_addra when (AXIC_shared = '1' and AXIC_ena = '1') else DATAIF_addra;
    -- Fix addr offset subtracting 1 only to the 3 msb
    SHARED_addra <= (raw_shared_addra(11 downto 9) - "001") & raw_shared_addra(8 downto 0); 
    SHARED_dina <= AXIC_dina when (AXIC_shared = '1' and AXIC_ena = '1') else DATAIF_dina;
    SHARED_wea <= AXIC_wea when (AXIC_shared = '1' and AXIC_ena = '1') else DATAIF_wea;


    -- Arbiter --

    arbiter_block: Binary_Arbiter
        port map ( 	
            clk => clk,
            reset => reset,
            bus_frame => arbiter_bus_frame,
            req => arbiter_req,
            granted => arbiter_granted
        );

    arbiter_bus_frame <= ARB_DATA_bus_frame or ARB_AXIC_bus_frame;
    arbiter_req <= (
        0 => ARB_DATA_request,
        1 => ARB_AXIC_request
    );
    ARB_DATA_granted <= arbiter_granted(0);
    ARB_AXIC_granted <= arbiter_granted(1);

    -- Map unit ----------------------------------------------------------

    map_unit_block: BPF_Map_Unit
        port map (
            clk => clk,
            reset => reset,

            MAP_id => MAP_id,
            MAP_write_en => MAP_write_en,
            MAP_input => MAP_input,
            MAP_output => MAP_output
        );
        
    MAP_id <= HFU_MAP_id when HFU_MAP_ena = '1' else AXIC_MAP_id;
    MAP_write_en <= AXIC_MAP_write_en;
    MAP_input <= AXIC_MAP_input;

    AXIC_MAP_output <= MAP_output;
    HFU_MAP_output <= MAP_output;

      -- -- --
    map_arbiter_block: Binary_Arbiter
        port map ( 	
            clk => clk,
            reset => reset,
            bus_frame => MAP_ARBITER_bus_frame,
            req => MAP_ARBITER_req,
            granted => MAP_ARBITER_granted
        );

    MAP_ARBITER_bus_frame <= HFU_MAP_bus_frame or AXIC_MAP_bus_frame;
    MAP_ARBITER_req <= (
        0 => HFU_MAP_req,
        1 => AXIC_MAP_req
    );
    HFU_MAP_granted <= MAP_ARBITER_granted(0);
    AXIC_MAP_granted <= MAP_ARBITER_granted(1);

    ----------------------------------------------------------------------------

end Behavioral;