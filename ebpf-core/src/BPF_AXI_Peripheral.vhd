--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Set of BPF core and IO/MEM system encapsulated in a
--               peripheral with AXI4 Lite interface.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity BPF_AXI_Peripheral is
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
        S_AXI_rready : in std_logic
    );
end BPF_AXI_Peripheral;

architecture Behavioral of BPF_AXI_Peripheral is

    component BPF_IO_Mem_System is
        port (
            -- AXI slave interface
            S_AXI_aclk : in std_logic;
            S_AXI_aresetn : in std_logic;
    
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
    end component;

    component BPF_Core is
        port (
            clk : in std_logic;
    
            -- Signals to control execution
            CORE_reset : in std_logic;
            CORE_sleep : in std_logic;
            CORE_reg_dst : in std_logic_vector (3 downto 0);
            CORE_reg_write : in std_logic;
            CORE_reg_input : in std_logic_vector (63 downto 0);
    
            CORE_sleeping : out std_logic;
            CORE_finish : out std_logic;
            CORE_exception : out std_logic;
            CORE_output : out std_logic_vector (63 downto 0);
    
            -- Signals to communicate with data memory
            DMEM_addr : out std_logic_vector (63 downto 0);
            DMEM_input : out std_logic_vector (63 downto 0);
            DMEM_write_en : out std_logic;
            DMEM_read_en : out std_logic;
            DMEM_size : out std_logic_vector (1 downto 0);
    
            DMEM_atomic : out std_logic;
            DMEM_op : out std_logic_vector (3 downto 0);
            DMEM_cmpxchg_token : out std_logic_vector (63 downto 0);
            
            DMEM_ready : in std_logic;
            DMEM_error : in std_logic;
            DMEM_output : in std_logic_vector (63 downto 0);
    
            -- Signals to communicate with instruction memory
            IMEM_addr : out std_logic_vector (11 downto 0);
            IMEM_read_en : out std_logic;
            IMEM_output : in std_logic_vector (63 downto 0);
    
            -- Signals to communicate with map interface
              -- MAP Unit bus
            HFU_MAP_ena : out std_logic;
            HFU_MAP_id : out std_logic_vector(0 downto 0);
            HFU_MAP_output : in std_logic_vector(31 downto 0);

            HFU_MAP_req : out std_logic;
            HFU_MAP_granted : in std_logic;
            HFU_MAP_bus_frame : out std_logic
        );
    end component;

    signal CORE_reset : std_logic;
    signal CORE_sleep : std_logic;
    signal CORE_reg_dst : std_logic_vector (3 downto 0);
    signal CORE_reg_write : std_logic;
    signal CORE_reg_input : std_logic_vector (63 downto 0);

    signal CORE_sleeping : std_logic;
    signal CORE_finish : std_logic;
    signal CORE_exception : std_logic;
    signal CORE_output : std_logic_vector (63 downto 0);

    signal DMEM_addr : std_logic_vector (63 downto 0);
    signal DMEM_input : std_logic_vector (63 downto 0);
    signal DMEM_write_en : std_logic;
    signal DMEM_read_en : std_logic;
    signal DMEM_size : std_logic_vector (1 downto 0);

    signal DMEM_atomic : std_logic;
    signal DMEM_op : std_logic_vector (3 downto 0);
    signal DMEM_cmpxchg_token : std_logic_vector (63 downto 0);
    
    signal DMEM_ready : std_logic;
    signal DMEM_error : std_logic;
    signal DMEM_output : std_logic_vector (63 downto 0);

    signal IMEM_addr : std_logic_vector (11 downto 0);
    signal IMEM_read_en : std_logic;

    signal IMEM_output : std_logic_vector (63 downto 0);

    signal HFU_MAP_ena : std_logic;
    signal HFU_MAP_id : std_logic_vector(0 downto 0);
    signal HFU_MAP_output : std_logic_vector(31 downto 0);

    signal HFU_MAP_req : std_logic;
    signal HFU_MAP_granted : std_logic;
    signal HFU_MAP_bus_frame : std_logic;

begin

    IO_MEM_system_block: BPF_IO_Mem_System
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
    
            S_AXI_araddr=> S_AXI_araddr,
            S_AXI_arprot => S_AXI_arprot,
            S_AXI_arvalid => S_AXI_arvalid,
            S_AXI_arready => S_AXI_arready,
            
            S_AXI_rdata => S_AXI_rdata,
            S_AXI_rresp => S_AXI_rresp,
            S_AXI_rvalid => S_AXI_rvalid,
            S_AXI_rready => S_AXI_rready,
    
            CORE_reset => CORE_reset, 
            CORE_sleep => CORE_sleep, 
            CORE_reg_dst => CORE_reg_dst,  
            CORE_reg_write => CORE_reg_write, 
            CORE_reg_input => CORE_reg_input,  
    
            CORE_sleeping => CORE_sleeping, 
            CORE_finish => CORE_finish, 
            CORE_exception => CORE_exception, 
            CORE_output => CORE_output,  

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
    
            IMEM_addr => IMEM_addr,  
            IMEM_read_en => IMEM_read_en, 
    
            IMEM_output => IMEM_output,

            HFU_MAP_ena => HFU_MAP_ena, 
            HFU_MAP_id => HFU_MAP_id,
            HFU_MAP_output => HFU_MAP_output,

            HFU_MAP_req => HFU_MAP_req, 
            HFU_MAP_granted => HFU_MAP_granted, 
            HFU_MAP_bus_frame => HFU_MAP_bus_frame
        );

    BPF_core_block: BPF_Core
        port map (
            clk => S_AXI_aclk,
    
            CORE_reset => CORE_reset, 
            CORE_sleep => CORE_sleep, 
            CORE_reg_dst => CORE_reg_dst,  
            CORE_reg_write => CORE_reg_write, 
            CORE_reg_input => CORE_reg_input,  
    
            CORE_sleeping => CORE_sleeping, 
            CORE_finish => CORE_finish, 
            CORE_exception => CORE_exception, 
            CORE_output => CORE_output,  
    
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
    
            IMEM_addr => IMEM_addr,  
            IMEM_read_en => IMEM_read_en, 
            IMEM_output => IMEM_output,

            HFU_MAP_ena => HFU_MAP_ena, 
            HFU_MAP_id => HFU_MAP_id,
            HFU_MAP_output => HFU_MAP_output,

            HFU_MAP_req => HFU_MAP_req, 
            HFU_MAP_granted => HFU_MAP_granted, 
            HFU_MAP_bus_frame => HFU_MAP_bus_frame
        );

end Behavioral;