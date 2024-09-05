--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  AXI controller for a BPF processor IO/MEM system, in order to
--               translate memory and flow control requests to
--               Block RAM compatible signals. Also translates addresses and
--               access control registers.
--
-- Comm:         AXI4 Lite Interface: 
--               https://www.realdigital.org/doc/a9fee931f7a172423e1ba73f66ca4081
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity BPF_AXI_Controller is
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
end BPF_AXI_Controller;

architecture Behavioral of BPF_AXI_Controller is

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

    component Delayed_Register_N is
        generic ( SIZE : positive := 64 );
        port (
            clk : in std_logic;
            reset : in std_logic;
            load : in std_logic;
    
            input : in std_logic_vector (SIZE - 1 downto 0);
            output : out std_logic_vector (SIZE - 1 downto 0)
        );
    end component;

    component Byte_Register_N is
        generic ( SIZE : positive := 64 );
        port (
            clk : in std_logic;
            reset : in std_logic;
            load : in std_logic_vector((SIZE / 8) - 1 downto 0);
    
            input : in std_logic_vector (SIZE - 1 downto 0);
            output : out std_logic_vector (SIZE - 1 downto 0)
        );
    end component;

    signal clk, reset : std_logic;
    
    signal addra, awaddr, araddr : std_logic_vector(15 downto 0);
    signal wdata, rdata : std_logic_vector(31 downto 0);
    signal awvalid, awready, wvalid, wready, arvalid, arready, rvalid, rready, bvalid, bready : std_logic;
    signal awprot, arprot : std_logic_vector(2 downto 0); -- These two are ignored
    signal bresp, rresp : std_logic_vector(1 downto 0);
    signal wstrb : std_logic_vector(3 downto 0);

    signal sv_addra : std_logic_vector(15 downto 0);
    signal sv_wdata : std_logic_vector(31 downto 0);
    signal sv_wstrb : std_logic_vector(3 downto 0);

    signal wr_shared_0, wr_shared_1, rd_shared_0, rd_shared_1 : std_logic;
    signal shared_flush, no_buffered_action, update_buffer_state : std_logic;
    signal wr_save_shared, wr_shared_from_buffer, wea_7_4, wea_3_0 : std_logic;
    signal no_mem_access, write_64b : std_logic;

    signal request, granted, bus_frame, req_state : std_logic;
    signal axi_read_req, axi_write_req, axi_req : std_logic;
    signal flush_n_read, flush_n_write, do_write, do_read : std_logic;
    signal save_axi_ch, from_saved_ch : std_logic;

    signal is_mem_inst, is_mem_unshared, is_mem_ctrl, is_mem_shared : std_logic;
    signal is_ctrl_reg, is_ctrl_input_0, is_ctrl_input_1 : std_logic;
    signal is_ctrl_output_0, is_ctrl_output_1, is_map_unit : std_logic;
    
    signal lock_required, wr_32b, effective_shared_flush : std_logic;
    signal buff_addra : std_logic_vector(15 downto 0);
    signal same_addra, is_mem_access, no_real_shared_mem_access : std_logic;

    signal ctrl_reg_input, ctrl_reg_output : std_logic_vector(6 downto 0);
    signal ctrl_reg_rdata, ctrl_rdata : std_logic_vector(31 downto 0);
    signal ctrl_core_input_reg_output, ctrl_rd_buff_input : std_logic_vector(63 downto 0);
    signal ctrl_core_input_reg_input, ctrl_input_rdata, ctrl_output_rdata : std_logic_vector(31 downto 0);
    signal ctrl_core_input_reg_load_0, ctrl_core_input_reg_load_1 : std_logic_vector(3 downto 0);
    signal ctrl_core_input_reg_output_0, ctrl_core_input_reg_output_1 : std_logic_vector(31 downto 0);

    signal axi_map_reg_load : std_logic;
    signal map_rdata : std_logic_vector(31 downto 0);

    signal shared_rd_buff_in, shared_rd_buff_out : std_logic_vector(63 downto 0);
    signal shared_wr_buff_in, shared_wr_buff_out : std_logic_vector(31 downto 0);

    signal mem_en, load_rd_buff : std_logic;
    signal mem_rdata : std_logic_vector(31 downto 0);
    signal mem_din_usual, mem_din_flush : std_logic_vector(63 downto 0);
    signal mem_wea_usual, mem_wea_flush : std_logic_vector(7 downto 0);
    signal buff_wea : std_logic_vector(3 downto 0);

    signal awaddr_reg_load : std_logic;
    signal awaddr_reg_input, awaddr_reg_output : std_logic_vector(15 downto 0);

    signal wdata_reg_load : std_logic;
    signal wdata_reg_input, wdata_reg_output : std_logic_vector(31 downto 0);

    signal wstrb_reg_load : std_logic;
    signal wstrb_reg_input, wstrb_reg_output : std_logic_vector(3 downto 0);

    signal buff_addra_reg_load : std_logic;
    signal buff_addra_reg_input, buff_addra_reg_output : std_logic_vector(15 downto 0);

    signal buff_op_flag_reg_in, buff_op_flag_reg_out : std_logic_vector(11 downto 0);

    signal buff_is_mem_inst, buff_is_mem_unshared, buff_is_mem_ctrl, buff_is_mem_shared : std_logic;
    signal buff_is_ctrl_reg, buff_is_ctrl_input_0, buff_is_ctrl_input_1 : std_logic;
    signal buff_is_ctrl_output_0, buff_is_ctrl_output_1 : std_logic;
    signal buff_is_mem_access, buff_shared_flush, buff_is_map_unit : std_logic;

    type axi_state_t is (
        INIT_S,
        READ_S, WRITE_S,
        FLUSH_N_READ_S, FLUSH_N_WRITE_S
    );
    signal axi_state, axi_next_state : axi_state_t;

    type buff_state_t is (
        EMPTY_S,
        STORE_1_S, STORE_0_S,
        LOAD_1_S, LOAD_0_S
    );
    signal buff_state, buff_next_state : buff_state_t;

begin

    clk <= S_AXI_aclk;
    reset <= not S_AXI_aresetn;

    ----------------------------------------------------------------------------
    awaddr_reg_block: Register_N
        generic map ( SIZE => 16 )
        port map (
            clk => clk,
            reset => reset, 
            load => awaddr_reg_load,
            input => awaddr_reg_input,
            output => awaddr_reg_output
        );

    awaddr_reg_load <= save_axi_ch;
    awaddr_reg_input <= addra(15 downto 0);
    sv_addra <= awaddr_reg_output;

    wdata_reg_block: Register_N
        generic map ( SIZE => 32 )
        port map (
            clk => clk,
            reset => reset, 
            load => wdata_reg_load,
            input => wdata_reg_input,
            output => wdata_reg_output
        );

    wdata_reg_load <= save_axi_ch;
    wdata_reg_input <= S_AXI_wdata;
    sv_wdata <= wdata_reg_output;
    
    wstrb_reg_block: Register_N
        generic map ( SIZE => 4 )
        port map (
            clk => clk,
            reset => reset, 
            load => wstrb_reg_load,
            input => wstrb_reg_input,
            output => wstrb_reg_output
        );

    wstrb_reg_load <= save_axi_ch;
    wstrb_reg_input <= S_AXI_wstrb;
    sv_wstrb <= wstrb_reg_output;
    
    -- Address channel
    awaddr <= S_AXI_awaddr(15 downto 0);
    awvalid <= S_AXI_awvalid; S_AXI_awready <= awready; awprot <= S_AXI_awprot;

    araddr <= S_AXI_araddr(15 downto 0);
    arvalid <= S_AXI_arvalid; S_AXI_arready <= arready; arprot <= S_AXI_arprot;
    -- Write channel
    wdata <= sv_wdata when from_saved_ch = '1' else S_AXI_wdata;
    wvalid <= S_AXI_wvalid; S_AXI_wready <= wready;
    wstrb <= sv_wstrb when from_saved_ch = '1' else S_AXI_wstrb;
    -- Write ack channel
    S_AXI_bresp <= bresp; S_AXI_bvalid <= bvalid; bready <= S_AXI_bready;
    -- Read channel
    S_AXI_rresp <= rresp; S_AXI_rvalid <= rvalid; rready <= S_AXI_rready; S_AXI_rdata <= rdata;
    
    bresp <= "00";
    rresp <= "00";

    axi_read_req <= arvalid;
    axi_write_req <= (awvalid and wvalid) and (not axi_read_req);

    axi_req <= (axi_read_req or axi_write_req) or from_saved_ch;

    ----------------------------------------------------------------------------

    is_mem_inst <= axi_req when addra(15) = '0' else '0';
    is_mem_unshared <= axi_req when addra(15 downto 11) = "10000" or addra(15 downto 9) = "1000100" else '0';
    is_mem_ctrl <= axi_req when addra(15 downto 9) = "1000101" else '0';
    is_mem_shared <= axi_req when addra(15 downto 12) >= "1001" else '0';

    
    is_ctrl_reg      <= '1' when is_mem_ctrl = '1' and addra(8 downto 2) = "0000000" else '0';
    is_ctrl_input_0  <= '1' when is_mem_ctrl = '1' and addra(8 downto 2) = "0000010" else '0';
    is_ctrl_input_1  <= '1' when is_mem_ctrl = '1' and addra(8 downto 2) = "0000011" else '0';
    is_ctrl_output_0 <= '1' when is_mem_ctrl = '1' and addra(8 downto 2) = "0000100" else '0';
    is_ctrl_output_1 <= '1' when is_mem_ctrl = '1' and addra(8 downto 2) = "0000101" else '0';
    is_map_unit      <= '1' when is_mem_ctrl = '1' and addra(8 downto 2) > "0000101" else '0';

    ----------------------------------------------------------------------------
    
    buff_addra_reg_block: Register_N
        generic map ( SIZE => 16 )
        port map (
            clk => clk,
            reset => reset,
            load => buff_addra_reg_load,
            input => buff_addra_reg_input,
            output => buff_addra_reg_output
        );

    -- To know from where to get rdata
    buff_op_flag_reg_block: Register_N
        generic map ( SIZE => 12 )
        port map (
            clk => clk,
            reset => reset,
            load => buff_addra_reg_load,
            input => buff_op_flag_reg_in,
            output => buff_op_flag_reg_out
        );

    buff_op_flag_reg_in <= (
        0 => is_mem_inst,
        1 => is_mem_unshared,
        2 => is_mem_ctrl,
        3 => is_mem_shared,

        4 => is_ctrl_reg,
        5 => is_ctrl_input_0,
        6 => is_ctrl_input_1,
        7 => is_ctrl_output_0,
        8 => is_ctrl_output_1,

        9 => shared_flush,
        10 => is_mem_access,
        11 => is_map_unit
    );

    buff_is_mem_inst <= buff_op_flag_reg_out(0);
    buff_is_mem_unshared <= buff_op_flag_reg_out(1);
    buff_is_mem_ctrl <= buff_op_flag_reg_out(2);
    buff_is_mem_shared <= buff_op_flag_reg_out(3);

    buff_is_ctrl_reg <= buff_op_flag_reg_out(4);
    buff_is_ctrl_input_0 <= buff_op_flag_reg_out(5);
    buff_is_ctrl_input_1 <= buff_op_flag_reg_out(6);
    buff_is_ctrl_output_0 <= buff_op_flag_reg_out(7);
    buff_is_ctrl_output_1 <= buff_op_flag_reg_out(8);

    buff_shared_flush <= buff_op_flag_reg_out(9);
    buff_is_mem_access <= buff_op_flag_reg_out(10);
    buff_is_map_unit <= buff_op_flag_reg_out(11);
      -- -- --

    buff_addra_reg_load <= do_read or wr_save_shared;
    buff_addra_reg_input <= addra(15 downto 0);
    buff_addra <= buff_addra_reg_output;

    addra <= sv_addra when from_saved_ch = '1' else
             araddr when axi_read_req = '1' else awaddr;
    same_addra <= '1' when buff_addra(15 downto 3) = addra(15 downto 3) else '0';

    wr_32b <= '1' when wstrb = "1111" else '0';

    wr_shared_0 <= axi_write_req when is_mem_shared = '1' and addra(2) = '0' and wr_32b = '1' else '0';
    wr_shared_1 <= axi_write_req when is_mem_shared = '1' and addra(2) = '1' and wr_32b = '1' else '0';
    rd_shared_0 <= axi_read_req when is_mem_shared = '1' and addra(2) = '0' and wr_32b = '1' else '0';
    rd_shared_1 <= axi_read_req when is_mem_shared = '1' and addra(2) = '1' and wr_32b = '1' else '0';

    shared_flush <= axi_write_req when addra(15 downto 3) = "1000111111111" else '0';
    --no_buffered_action -- Not necessary to be defined

    effective_shared_flush <= '1' when shared_flush = '1' and (buff_state = STORE_0_S or buff_state = STORE_1_S) else '0';

    is_mem_access <=
        '1' when is_mem_inst = '1' or is_mem_shared = '1' or is_mem_unshared = '1' else
        '1' when effective_shared_flush = '1' else '0';
    
    no_real_shared_mem_access <= 
        '1' when buff_state = LOAD_0_S and rd_shared_1 = '1' and same_addra = '1' else
        '1' when buff_state = LOAD_1_S and rd_shared_0 = '1' and same_addra = '1' else
        '1' when buff_state = EMPTY_S and wr_shared_1 = '1' else
        '1' when buff_state = EMPTY_S and wr_shared_0 = '1' else '0';

    -- TODO: change when adding maps
    lock_required <= '0' when no_real_shared_mem_access = '1' else
                     '1' when is_mem_shared = '1' else
                     '1' when effective_shared_flush = '1' else '0';
    
    flush_n_read <= '1' when (buff_state = STORE_0_S or buff_state = STORE_1_S) and axi_read_req = '1' and axi_state = INIT_S else '0';
    flush_n_write <= '0' when buff_state = STORE_1_S and (shared_flush = '1' or (wr_shared_0 = '1' and same_addra = '1')) else
                     '0' when buff_state = STORE_0_S and (shared_flush = '1' or (wr_shared_1 = '1' and same_addra = '1')) else
                     '1' when (buff_state = STORE_0_S or buff_state = STORE_1_S) and axi_write_req = '1' and axi_state = INIT_S else '0';

    request <= req_state and ((flush_n_read or flush_n_write or lock_required) or (is_map_unit));

    ----------------------------------------------------------------------------

    ARB_AXIC_request <= req_state and (flush_n_read or flush_n_write or lock_required);
    ARB_AXIC_bus_frame <= bus_frame and is_mem_shared;

    AXIC_MAP_req <= req_state and (is_map_unit);
    AXIC_MAP_bus_frame <= bus_frame and is_map_unit;

    granted <= ARB_AXIC_granted or AXIC_MAP_granted;

    ----------------------------------------------------------------------------
    -- MAP REGISTER ------------------------------------------------------------
    ----------------------------------------------------------------------------

    axi_map_reg_block: Register_N
        generic map ( SIZE => 32 )
        port map (
            clk => clk,
            reset => reset,
            load => axi_map_reg_load,
            input => AXIC_MAP_output,
            output => map_rdata
        );

    axi_map_reg_load <= do_read and is_map_unit;

    AXIC_MAP_input <= wdata;
    AXIC_MAP_write_en <= do_write when wstrb = "1111" and is_map_unit = '1' else '0';
    AXIC_MAP_id <= addra(2 downto 2);

    ----------------------------------------------------------------------------
    -- CONTROL REGISTER --------------------------------------------------------
    ----------------------------------------------------------------------------

    CRTL_REG_SAVE_PROC: process (clk)
    begin
        if (clk'event and clk = '1') then
            if (reset = '1') then
                ctrl_reg_output <= "1100000"; -- sleep and reset core when peripheral reset
            elsif (do_write = '1' and is_ctrl_reg = '1') then
                if (wstrb(0) = '1') then
                    ctrl_reg_output(5 downto 0) <= ctrl_reg_input(5 downto 0);
                end if;
                if (wstrb(1) = '1') then
                    -- Reset is actually bit 9, not 6, so it's saved with a different byte enable
                    ctrl_reg_output(6) <= ctrl_reg_input(6); 
                end if;
            end if;        
        end if;
    end process;

    ctrl_reg_input <= wdata(9) & wdata(5 downto 0);

    ctrl_reg_rdata <= (21 downto 0 => '0') & ctrl_reg_output(6) & CORE_finish & CORE_exception & CORE_sleeping & ctrl_reg_output(5 downto 0);

    CORE_reset <= reset or ctrl_reg_output(6);
    CORE_sleep <= ctrl_reg_output(5);
    CORE_reg_write <= ctrl_reg_output(4);
    CORE_reg_dst <= ctrl_reg_output(3 downto 0);

    ctrl_core_input_reg_load_0 <= wstrb when do_write = '1' and is_ctrl_input_0 = '1' else "0000";
    ctrl_core_input_reg_output(31 downto 0) <= ctrl_core_input_reg_output_0;

    ctrl_core_input_reg_0_block: Byte_Register_N
        generic map ( SIZE => 32 )
        port map (
            clk => clk,
            reset => reset,
            load => ctrl_core_input_reg_load_0,
            input => ctrl_core_input_reg_input,
            output => ctrl_core_input_reg_output_0
        );

    ctrl_core_input_reg_load_1 <= wstrb when do_write = '1' and is_ctrl_input_1 = '1' else "0000";
    ctrl_core_input_reg_output(63 downto 32) <= ctrl_core_input_reg_output_1;

    ctrl_core_input_reg_1_block: Byte_Register_N
        generic map ( SIZE => 32 )
        port map (
            clk => clk,
            reset => reset,
            load => ctrl_core_input_reg_load_1,
            input => ctrl_core_input_reg_input,
            output => ctrl_core_input_reg_output_1
        );

    ctrl_core_input_reg_input <= wdata;
    CORE_reg_input <= ctrl_core_input_reg_output;

    ctrl_input_rdata <= ctrl_core_input_reg_output(63 downto 32) when buff_is_ctrl_input_1 = '1' else ctrl_core_input_reg_output(31 downto 0);
    ctrl_output_rdata <= CORE_output(63 downto 32) when buff_is_ctrl_output_1 = '1' else CORE_output(31 downto 0);
    
    ----------------------------------------------------------------------------
    -- MEMORY ------------------------------------------------------------------
    ----------------------------------------------------------------------------

    load_rd_buff <= do_read and not no_mem_access;

    --shared_rd_buff_block: Register_N
    shared_rd_buff_block: Delayed_Register_N
        generic map ( SIZE => 64 )
        port map (
            clk => clk,
            reset => reset,
            load => load_rd_buff,
            input => shared_rd_buff_in,
            output => shared_rd_buff_out
        );

    shared_wr_buff_block: Register_N
        generic map ( SIZE => 32 )
        port map (
            clk => clk,
            reset => reset,
            load => wr_save_shared,
            input => shared_wr_buff_in,
            output => shared_wr_buff_out
        );

    mem_en <= '0' when (is_mem_inst = '1' or is_mem_unshared = '1') and (CORE_sleeping = '0' and CORE_exception = '0' and CORE_finish = '0') else 
              '0' when no_mem_access = '1' else
              '1' when (do_read = '1' or do_write = '1') and is_mem_access = '1' else '0';

    shared_rd_buff_in <= AXIC_douta;
    mem_rdata <= shared_rd_buff_out(63 downto 32) when buff_addra(2) = '1' else shared_rd_buff_out(31 downto 0);

    shared_wr_buff_in <= wdata;

    wr_shared_from_buffer <= (flush_n_write or flush_n_read) or shared_flush;

    mem_din_usual <= wdata & shared_wr_buff_out when addra(2) = '1' else shared_wr_buff_out & wdata;
    mem_din_flush <= shared_wr_buff_out & wdata when buff_addra(2) = '1' else wdata & shared_wr_buff_out;
    AXIC_dina <= mem_din_flush when wr_shared_from_buffer = '1' else mem_din_usual;
    
    buff_wea <= (3 downto 0 => write_64b);
    mem_wea_usual <= wstrb & buff_wea when addra(2) = '1' else buff_wea & wstrb;
    mem_wea_flush <= "11110000" when buff_addra(2) = '1' else "00001111";
    AXIC_wea <= mem_wea_flush when wr_shared_from_buffer = '1' and do_write = '1' else
                mem_wea_usual when wr_shared_from_buffer = '0' and do_write = '1' else
                "00000000";

    AXIC_ena <= mem_en;
    AXIC_addra <= buff_addra(14 downto 3) when wr_shared_from_buffer = '1' else addra(14 downto 3); -- 64 bit word access

    AXIC_shared <= (is_mem_shared or shared_flush) when mem_en = '1' else (buff_is_mem_shared or buff_shared_flush);
    AXIC_unshared <= is_mem_unshared when mem_en = '1' else buff_is_mem_unshared;
    AXIC_inst <= is_mem_inst when mem_en = '1' else buff_is_mem_inst;
    AXIC_map <= '0'; --TODO: change when adding maps


    rdata <= 
        mem_rdata when buff_is_mem_access = '1' else
        ctrl_input_rdata when (buff_is_ctrl_input_0 = '1' or buff_is_ctrl_input_1 = '1') else
        ctrl_output_rdata when (buff_is_ctrl_output_0 = '1' or buff_is_ctrl_output_1 = '1') else
        ctrl_reg_rdata when buff_is_ctrl_reg = '1' else 
        map_rdata; -- when buff_is_map_unit = '1'

    ----------------------------------------------------------------------------
    -- STATE MACHINES ----------------------------------------------------------
    ----------------------------------------------------------------------------

    SYNC_PROC: process (clk)
    begin
        if (clk'event and clk = '1') then
            if (reset = '1') then
                axi_state <= INIT_S;
                buff_state <= EMPTY_S;
            else
                axi_state <= axi_next_state;
                if (update_buffer_state = '1') then
                    buff_state <= buff_next_state;
                end if;
            end if;
        end if;
    end process;

    BUFF_CONTROL: process (
        buff_state, update_buffer_state,
        same_addra,
        rd_shared_0, rd_shared_1,
        wr_shared_0, wr_shared_1,
        shared_flush, no_buffered_action
    )
        variable UBS : boolean; -- Alias for readability

    begin
        -- Default values
        buff_next_state <= buff_state;

        UBS := update_buffer_state = '1';

        wr_save_shared <= '0';
        wea_7_4 <= '0';
        wea_3_0 <= '0';
        no_mem_access <= '0';
        write_64b <= '0';

        if (buff_state = EMPTY_S) then

            if (UBS and wr_shared_1 = '1') then
                buff_next_state <= STORE_1_S;
                wr_save_shared <= '1';
                no_mem_access <= '1';

            elsif (UBS and wr_shared_0 = '1') then
                buff_next_state <= STORE_0_S;
                wr_save_shared <= '1';
                no_mem_access <= '1';

            elsif (UBS and rd_shared_1 = '1') then
                buff_next_state <= LOAD_1_S;

            elsif (UBS and rd_shared_0 = '1') then
                buff_next_state <= LOAD_0_S;
            end if;
            
        elsif (buff_state = STORE_1_S) then
            wea_7_4 <= '1';

            if (UBS and wr_shared_1 = '1') then
                buff_next_state <= STORE_1_S;
                wr_save_shared <= '1';

            elsif (UBS and wr_shared_0 = '1' and same_addra = '0') then
                buff_next_state <= STORE_0_S;
                wr_save_shared <= '1';

            elsif (UBS and rd_shared_1 = '1') then
                buff_next_state <= LOAD_1_S;

            elsif (UBS and rd_shared_0 = '1') then
                buff_next_state <= LOAD_0_S;

            elsif (UBS and (wr_shared_0 = '1' and same_addra = '1')) then
                buff_next_state <= EMPTY_S;
                write_64b <= '1';

            elsif (UBS) then -- shared_flush or no_buffered_action
                buff_next_state <= EMPTY_S;
            end if;

        elsif (buff_state = STORE_0_S) then
            wea_3_0 <= '1';

            if (UBS and wr_shared_0 = '1') then
                buff_next_state <= STORE_0_S;
                wr_save_shared <= '1';
            
            elsif (UBS and wr_shared_1 = '1' and same_addra = '0') then
                buff_next_state <= STORE_1_S;
                wr_save_shared <= '1';

            elsif (UBS and rd_shared_1 = '1') then
                buff_next_state <= LOAD_1_S;

            elsif (UBS and rd_shared_0 = '1') then
                buff_next_state <= LOAD_0_S;

            elsif (UBS and (wr_shared_1 = '1' and same_addra = '1')) then
                buff_next_state <= EMPTY_S;
                write_64b <= '1';

            elsif (UBS) then -- shared_flush or no_buffered_action
                buff_next_state <= EMPTY_S;
            end if;

        elsif (buff_state = LOAD_1_S) then

            if (UBS and rd_shared_1 = '1') then
                buff_next_state <= LOAD_1_S;

            elsif (UBS and wr_shared_1 = '1') then
                buff_next_state <= STORE_1_S;
                wr_save_shared <= '1';
                no_mem_access <= '1';

            elsif (UBS and wr_shared_0 = '1') then
                buff_next_state <= STORE_0_S;
                wr_save_shared <= '1';
                no_mem_access <= '1';

            elsif (UBS and rd_shared_0 = '1' and same_addra = '1') then
                buff_next_state <= EMPTY_S;
                no_mem_access <= '1';

            elsif (UBS and rd_shared_0 = '1' and same_addra = '0') then
                buff_next_state <= LOAD_0_S;

            elsif (UBS) then -- shared_flush or no_buffered_action
                buff_next_state <= EMPTY_S;
            end if;

        elsif (buff_state = LOAD_0_S) then

            if (UBS and rd_shared_0 = '1') then
                buff_next_state <= LOAD_0_S;

            elsif (UBS and wr_shared_1 = '1') then
                buff_next_state <= STORE_1_S;
                wr_save_shared <= '1';
                no_mem_access <= '1';

            elsif (UBS and wr_shared_0 = '1') then
                buff_next_state <= STORE_0_S;
                wr_save_shared <= '1';
                no_mem_access <= '1';

            elsif (UBS and rd_shared_1 = '1' and same_addra = '1') then
                buff_next_state <= EMPTY_S;
                no_mem_access <= '1';

            elsif (UBS and rd_shared_1 = '1' and same_addra = '0') then
                buff_next_state <= LOAD_1_S;

            elsif (UBS) then -- shared_flush or no_buffered_action
                buff_next_state <= EMPTY_S;
            end if;
            
        end if;
        
    end process;

    AXI_CONTROL: process (
        axi_state, axi_read_req, axi_write_req,
        request, granted, rready, bready
    )
    begin
        -- Default values
        axi_next_state <= axi_state;

        do_read <= '0';
        do_write <= '0';
        save_axi_ch <= '0';
        from_saved_ch <= '0';
        req_state <= '0';

        bus_frame <= '0';

        arready <= '0';
        awready <= '0';
        wready <= '0';
        rvalid <= '0';
        bvalid <= '0';

        update_buffer_state <= '0';

        if (axi_state = INIT_S) then
            req_state <= '1';

            if (request = '1' and granted = '0') then
                axi_next_state <= INIT_S; -- await
            
            elsif (axi_read_req = '1' and flush_n_read = '1') then
                axi_next_state <= FLUSH_N_READ_S;
                
                arready <= '1';
                do_write <= '1';
                save_axi_ch <= '1';

            elsif (axi_read_req = '1') then
                axi_next_state <= READ_S;
                
                arready <= '1';
                do_read <= '1';
                update_buffer_state <= '1'; 

            elsif (axi_write_req = '1' and flush_n_write = '1') then
                axi_next_state <= FLUSH_N_WRITE_S;
                
                awready <= '1';
                wready <= '1';
                do_write <= '1';
                save_axi_ch <= '1';

            elsif (axi_write_req = '1') then
                axi_next_state <= WRITE_S;
                
                awready <= '1';
                wready <= '1';
                do_write <= '1';
                update_buffer_state <= '1';
            end if;

        elsif (axi_state = READ_S) then
            rvalid <= '1';

            if (rready = '1') then
                axi_next_state <= INIT_S;
            end if;

        elsif (axi_state = WRITE_S) then
            bvalid <= '1';

            if (bready = '1') then
                axi_next_state <= INIT_S;
            end if;

        elsif (axi_state = FLUSH_N_READ_S) then
            from_saved_ch <= '1';
            req_state <= '1';

            if (request = '1' and granted = '0') then
                axi_next_state <= FLUSH_N_READ_S;
            else 
                axi_next_state <= READ_S;
                do_read <= '1';
                update_buffer_state <= '1';
            end if;

        elsif (axi_state = FLUSH_N_WRITE_S) then
            from_saved_ch <= '1';
            req_state <= '1';

            if (request = '1' and granted = '0') then
                axi_next_state <= FLUSH_N_WRITE_S;
            else 
                axi_next_state <= WRITE_S;
                do_write <= '1';
                update_buffer_state <= '1';
            end if;

        end if;

    end process;

end Behavioral;