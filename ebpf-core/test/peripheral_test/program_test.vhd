--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Testbench for testing loading of a BPF program and it's
--               execution.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.bpf.all;

entity BPF_Peripheral_Testbench is
end BPF_Peripheral_Testbench;

architecture Behavioral of BPF_Peripheral_Testbench is

    component BPF_AXI_Peripheral is
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
    
            S_AXI_araddr : in std_logic_vector(31 downto 0);
            S_AXI_arprot : in std_logic_vector(2 downto 0);
            S_AXI_arvalid : in std_logic;
            S_AXI_arready : out std_logic;
            
            S_AXI_rdata : out std_logic_vector(31 downto 0);
            S_AXI_rresp : out std_logic_vector(1 downto 0);
            S_AXI_rvalid : out std_logic;
            S_AXI_rready : in std_logic
        );
    end component;

    -- RAM from which instructions are being loaded
    component Inst_RAM is
        port (
            clk : in std_logic;
            addr : in std_logic_vector (11 downto 0);
            input : in std_logic_vector (63 downto 0);
            write_en : in std_logic;
            read_en : in std_logic;
            output : out std_logic_vector (63 downto 0)
        );
    end component;

    function vec32(input_vector: std_logic_vector) return std_logic_vector is
        constant target_length : integer := 32;
        variable output_vector : std_logic_vector(target_length-1 downto 0);
        variable input_length  : integer := input_vector'length;
    begin
        if input_length < target_length then
            -- Zero-extend the input vector to 32 bits
            output_vector := (others => '0');
            output_vector(input_length-1 downto 0) := input_vector;
        else
            -- Truncate or keep the input vector to 32 bits
            output_vector := input_vector(target_length-1 downto 0);
        end if;
        return output_vector;
    end function;

    constant CLK_PERIOD : time := 10 ns;
    constant NUM_CLKS : natural := 10000;

    signal clk, reset : std_logic;
    signal cycles : natural := 0;

    signal instruction : std_logic_vector(63 downto 0);
    signal inst_addr : std_logic_vector(11 downto 0);

    signal S_AXI_awaddr : std_logic_vector(31 downto 0);
    signal S_AXI_awprot : std_logic_vector(2 downto 0);
    signal S_AXI_awvalid : std_logic;
    signal S_AXI_awready : std_logic;

    signal S_AXI_wdata : std_logic_vector(31 downto 0);
    signal S_AXI_wstrb : std_logic_vector(3 downto 0);
    signal S_AXI_wvalid : std_logic;
    signal S_AXI_wready : std_logic;

    signal S_AXI_bresp : std_logic_vector(1 downto 0);
    signal S_AXI_bvalid : std_logic;
    signal S_AXI_bready : std_logic;

    signal S_AXI_araddr: std_logic_vector(31 downto 0);
    signal S_AXI_arprot : std_logic_vector(2 downto 0);
    signal S_AXI_arvalid : std_logic;
    signal S_AXI_arready : std_logic;
    
    signal S_AXI_rdata : std_logic_vector(31 downto 0);
    signal S_AXI_rresp : std_logic_vector(1 downto 0);
    signal S_AXI_rvalid : std_logic;
    signal S_AXI_rready : std_logic;

begin

    tested_unit: BPF_AXI_Peripheral
        port map (
            S_AXI_aclk => clk,
            S_AXI_aresetn => not reset,
    
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
            S_AXI_rready => S_AXI_rready
        );

    program_buffer: Inst_RAM
        port map (
            clk => clk,
            addr => inst_addr,
            input => (63 downto 0 => '0'),
            write_en => '0',
            read_en => '1',
            output => instruction
        );

    CLK_PROC: process
    begin
        if (cycles /= NUM_CLKS) then
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            cycles <= cycles + 1;
            wait for CLK_PERIOD / 2;
        else
            wait;
        end if;
    end process;

    ----------------------------------------------------------------------------

    TEST_PROC: process
    begin
        reset <= '1';

        S_AXI_awaddr <= x"00000000";
        S_AXI_awvalid <= '0';

        S_AXI_wdata <= x"00000000";
        S_AXI_wstrb <= "0000";
        S_AXI_wvalid <= '0';

        S_AXI_araddr <= x"00000000";
        S_AXI_arvalid <= '0';
        
        -- Always ready
        S_AXI_bready <= '1';
        S_AXI_rready <= '1';

        -- Unused
        S_AXI_arprot <= "000";
        S_AXI_awprot <= "000";
        
        wait on clk until clk = '1';
        reset <= '0';

        -- Step 1: load program --
        inst_addr <= x"000";
        wait for CLK_PERIOD / 8;
        while instruction /= (63 downto 0 => '0') loop
            -- lower 32 bit
            S_AXI_awaddr <= BPF_MEM_INST_BASE_U32 + (inst_addr & "000");
            S_AXI_awvalid <= '1';

            S_AXI_wdata <= instruction(31 downto 0);
            S_AXI_wstrb <= "1111";
            S_AXI_wvalid <= '1';

            wait until S_AXI_awready = '1' and S_AXI_wready = '1';
            wait on clk until clk = '1';

            S_AXI_awvalid <= '0';
            S_AXI_wvalid <= '0';

            wait until S_AXI_bvalid = '1';
            wait on clk until clk = '1';

            -- higher 32 bit
            S_AXI_awaddr <= BPF_MEM_INST_BASE_U32 + (inst_addr & "100");
            S_AXI_awvalid <= '1';

            S_AXI_wdata <= instruction(63 downto 32);
            S_AXI_wstrb <= "1111";
            S_AXI_wvalid <= '1';

            wait until S_AXI_awready = '1' and S_AXI_wready = '1';
            wait on clk until clk = '1';

            S_AXI_awvalid <= '0';
            S_AXI_wvalid <= '0';

            wait until S_AXI_bvalid = '1';
            wait on clk until clk = '1';

            inst_addr <= inst_addr + "01";
            wait for CLK_PERIOD / 8;

        end loop;

        -- Step 2: load frame pointer (FP) --

        S_AXI_awaddr <= BPF_CORE_CTRL_U32;
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= vec32("000011" & "1010"); -- reset = 0; sleep = 1; write FP
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait until S_AXI_awready = '1' and S_AXI_wready = '1';
        wait on clk until clk = '1';

        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';

        wait until S_AXI_bvalid = '1';
        wait on clk until clk = '1';

        S_AXI_awaddr <= BPF_CORE_INPUT_U32;
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= vec32(BPF_FRAME_POINTER);
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait until S_AXI_awready = '1' and S_AXI_wready = '1';
        wait on clk until clk = '1';

        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';

        wait until S_AXI_bvalid = '1';
        wait on clk until clk = '1';

        -- Step 3: execute --

        S_AXI_awaddr <= BPF_CORE_CTRL_U32;
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= vec32("000000" & "0000"); -- reset = 0; sleep = 0; don't write
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait until S_AXI_awready = '1' and S_AXI_wready = '1';
        wait on clk until clk = '1';

        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';

        wait until S_AXI_bvalid = '1';
        wait on clk until clk = '1';

        -- -- -- -- --

        wait;

    end process;

end Behavioral;