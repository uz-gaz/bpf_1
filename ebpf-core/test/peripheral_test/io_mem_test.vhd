--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Testbench for testing writing into unshared memory and reading
--               from shared memory. Also tests concurrent
--
-- Usage:        launch-peripheral-testbench.sh --imem test_io_mem --tb io_mem_test
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

            wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
            S_AXI_awvalid <= '0';
            S_AXI_wvalid <= '0';
            wait on clk until S_AXI_bvalid = '1' and clk = '1';

            -- higher 32 bit
            S_AXI_awaddr <= BPF_MEM_INST_BASE_U32 + (inst_addr & "100");
            S_AXI_awvalid <= '1';

            S_AXI_wdata <= instruction(63 downto 32);
            S_AXI_wstrb <= "1111";
            S_AXI_wvalid <= '1';

            wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
            S_AXI_awvalid <= '0';
            S_AXI_wvalid <= '0';
            wait on clk until S_AXI_bvalid = '1' and clk = '1';

            inst_addr <= inst_addr + "01";
            wait for CLK_PERIOD / 8;

        end loop;

        -- Step 2: write in unshared memory --

        for offset in 0 to 319 loop 
            -- lower 32 bit
            S_AXI_awaddr <= BPF_MEM_PACKET_BASE_U32 + std_logic_vector(to_unsigned(8*offset, 32));
            S_AXI_awvalid <= '1';

            S_AXI_wdata <= std_logic_vector(to_unsigned(2*offset, 32));
            S_AXI_wstrb <= "1111";
            S_AXI_wvalid <= '1';

            wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
            S_AXI_awvalid <= '0';
            S_AXI_wvalid <= '0';
            wait on clk until S_AXI_bvalid = '1' and clk = '1';

            -- higher 32 bit
            S_AXI_awaddr <= BPF_MEM_PACKET_BASE_U32 + std_logic_vector(to_unsigned(8*offset + 4, 32));
            S_AXI_awvalid <= '1';

            S_AXI_wdata <= std_logic_vector(to_unsigned(2*offset + 1, 32));
            S_AXI_wstrb <= "1111";
            S_AXI_wvalid <= '1';

            wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
            S_AXI_awvalid <= '0';
            S_AXI_wvalid <= '0';
            wait on clk until S_AXI_bvalid = '1' and clk = '1';

            inst_addr <= inst_addr + "01";
            wait for CLK_PERIOD / 8;
        end loop;

        -- Step 3: load frame pointer (FP) --

        S_AXI_awaddr <= BPF_CORE_CTRL_U32;
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= vec32("000011" & "1010"); -- reset = 0; sleep = 1; write FP
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

        S_AXI_awaddr <= BPF_CORE_INPUT_U32;
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= vec32(BPF_FRAME_POINTER);
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

        -- Step 4: execute --

        S_AXI_awaddr <= BPF_CORE_CTRL_U32;
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= vec32("000000" & "0000"); -- reset = 0; sleep = 0; don't write
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

        -- -- -- -- --

        /*
            Control test:
             - Write control signals [x] (steps 3 and 4)
             - Read control signals, input and output [x]

            Concurrency test:
             - Concurrent 1 step write [x]
             - Concurrent 1 step read [x]

             - Concurrent flush and write [x]
             - Concurrent flush and read [x]

            Buffered read test:
             - Read lower 32b + higher 32b of same addr [x]
             - Read higher 32b + lower 32b of same addr [x]
             - Read lower 32b + lower 32b of same addr [x]
             - Read higher 32b + higher 32b of same addr [x]

             - Read lower 32b + higher 32b of different addr [x]
             - Read higher 32b + lower 32b of different addr [x]
             - Read lower 32b + lower 32b of different addr [x]
             - Read higher 32b + higher 32b of different addr [x]

            Buffered write test:
             - Write lower 32b + higher 32b of same addr [x]
             - Write higher 32b + lower 32b of same addr [x]
             - Write lower 32b + lower 32b of same addr [x]
             - Write higher 32b + higher 32b of same addr [x]

             - Write lower 32b + higher 32b of different addr [x]
             - Write higher 32b + lower 32b of different addr [x]
             - Write lower 32b + lower 32b of different addr [x]
             - Write higher 32b + higher 32b of different addr [x]

            Forced flushed test:
             - Write 32b + FLUSH [x]
             - Write <32b + FLUSH [x] 
             - Read lower 32b + FLUSH + Read higher 32b (same addr) [x]
             
         */

        ------------------------------------------------------------------------
        wait until cycles = 4003; -- Concurrent flush and write ----------------

        S_AXI_awaddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_unsigned(0, 32));
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= x"FFFFFFFF";
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

        S_AXI_awaddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_unsigned(8, 32));
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= x"FFFFFFFF";
        S_AXI_wstrb <= "1001";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

        ------------------------------------------------------------------------
        wait until cycles = 4016; -- Concurrent flush and read -----------------

        S_AXI_awaddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_unsigned(0, 32));
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= x"0000000A";
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

        S_AXI_araddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_unsigned(0, 32));
        S_AXI_arvalid <= '1';

        wait on clk until S_AXI_arready = '1' and clk = '1';
        S_AXI_arvalid <= '0';
        wait on clk until S_AXI_rvalid = '1' and clk = '1';

        ------------------------------------------------------------------------
        wait until cycles = 4025; -- Concurrent 1 step write -------------------

        S_AXI_awaddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_unsigned(0, 32));
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= x"0D0C0BFF";
        S_AXI_wstrb <= "1110";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

        ------------------------------------------------------------------------
        wait until cycles = 4031; -- Concurrent 1 step read --------------------

        S_AXI_araddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_unsigned(0, 32));
        S_AXI_arvalid <= '1';

        wait on clk until S_AXI_arready = '1' and clk = '1';
        S_AXI_arvalid <= '0';
        wait on clk until S_AXI_rvalid = '1' and clk = '1';

        ------------------------------------------------------------------------
        wait until cycles = 4036; -- Control reg test --------------------------

        S_AXI_araddr <= BPF_CORE_CTRL_U32;
        S_AXI_arvalid <= '1';

        wait on clk until S_AXI_arready = '1' and clk = '1';
        S_AXI_arvalid <= '0';
        wait on clk until S_AXI_rvalid = '1' and clk = '1';

        S_AXI_araddr <= BPF_CORE_INPUT_U32;
        S_AXI_arvalid <= '1';

        wait on clk until S_AXI_arready = '1' and clk = '1';
        S_AXI_arvalid <= '0';
        wait on clk until S_AXI_rvalid = '1' and clk = '1';

        S_AXI_araddr <= BPF_CORE_OUTPUT_U32;
        S_AXI_arvalid <= '1';

        wait on clk until S_AXI_arready = '1' and clk = '1';
        S_AXI_arvalid <= '0';
        wait on clk until S_AXI_rvalid = '1' and clk = '1';

        ------------------------------------------------------------------------
        wait until cycles = 4045; -- Write lower 32b + higher 32b of same addr

        S_AXI_awaddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_unsigned(0, 32));
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= x"77777777";
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

        S_AXI_awaddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_unsigned(4, 32));
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= x"88888888";
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

        ------------------------------------------------------------------------
        wait until cycles = 4050; -- Write higher 32b + lower 32b of same addr

        S_AXI_awaddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_unsigned(4, 32));
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= x"AAAAAAAA";
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

        S_AXI_awaddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_unsigned(0, 32));
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= x"BBBBBBBB";
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

        ------------------------------------------------------------------------
        wait until cycles = 4055; -- Write lower 32b + lower 32b of same addr

        S_AXI_awaddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_unsigned(8, 32));
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= x"CCCCCCCC";
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

        S_AXI_awaddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_unsigned(8, 32));
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= x"33333333";
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

        ------------------------------------------------------------------------
        wait until cycles = 4062; -- Write higher 32b + higher 32b of same addr -

        S_AXI_awaddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_unsigned(12, 32));
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= x"45454545";
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

        S_AXI_awaddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_unsigned(12, 32));
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= x"12121212";
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

        ------------------------------------------------------------------------
        wait until cycles = 4070; -- Write lower 32b + higher 32b of different addr

        S_AXI_awaddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_unsigned(8, 32));
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= x"FFFFFFFF";
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

        S_AXI_awaddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_unsigned(4, 32));
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= x"EEEEEEEE";
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

        ------------------------------------------------------------------------
        wait until cycles = 4080; -- Write higher 32b + lower 32b of different addr

        S_AXI_awaddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_unsigned(12, 32));
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= x"DDDDDDDD";
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

        S_AXI_awaddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_unsigned(16, 32));
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= x"CCCCCCCC";
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

        ------------------------------------------------------------------------
        wait until cycles = 4090; -- Write lower 32b + lower 32b of different addr

        S_AXI_awaddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_unsigned(8, 32));
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= x"BBBBBBBB";
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

        S_AXI_awaddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_unsigned(0, 32));
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= x"AAAAAAAA";
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

        ------------------------------------------------------------------------
        wait until cycles = 4100; -- Write higher 32b + higher 32b of different addr

        S_AXI_awaddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_unsigned(4, 32));
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= x"11111111";
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

        S_AXI_awaddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_unsigned(20, 32));
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= x"22222222";
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

        ------------------------------------------------------------------------
        wait until cycles = 4108; -- Read lower 32b + higher 32b of same addr

        S_AXI_araddr <= x"000092C0";
        S_AXI_arvalid <= '1';

        wait on clk until S_AXI_arready = '1' and clk = '1';
        S_AXI_arvalid <= '0';
        wait on clk until S_AXI_rvalid = '1' and clk = '1';

        S_AXI_araddr <= x"000092C4";
        S_AXI_arvalid <= '1';

        wait on clk until S_AXI_arready = '1' and clk = '1';
        S_AXI_arvalid <= '0';
        wait on clk until S_AXI_rvalid = '1' and clk = '1';

        ------------------------------------------------------------------------
        wait until cycles = 4114; -- Read higher 32b + lower 32b of same addr

        S_AXI_araddr <= x"000092CC";
        S_AXI_arvalid <= '1';

        wait on clk until S_AXI_arready = '1' and clk = '1';
        S_AXI_arvalid <= '0';
        wait on clk until S_AXI_rvalid = '1' and clk = '1';

        S_AXI_araddr <= x"000092C8";
        S_AXI_arvalid <= '1';

        wait on clk until S_AXI_arready = '1' and clk = '1';
        S_AXI_arvalid <= '0';
        wait on clk until S_AXI_rvalid = '1' and clk = '1';

        ------------------------------------------------------------------------
        wait until cycles = 4120; -- Read lower 32b + lower 32b of same addr

        S_AXI_araddr <= x"000092D0";
        S_AXI_arvalid <= '1';

        wait on clk until S_AXI_arready = '1' and clk = '1';
        S_AXI_arvalid <= '0';
        wait on clk until S_AXI_rvalid = '1' and clk = '1';

        S_AXI_araddr <= x"000092D0";
        S_AXI_arvalid <= '1';

        wait on clk until S_AXI_arready = '1' and clk = '1';
        S_AXI_arvalid <= '0';
        wait on clk until S_AXI_rvalid = '1' and clk = '1';

        ------------------------------------------------------------------------
        wait until cycles = 4126; -- Read higher 32b + higher 32b of same addr

        S_AXI_araddr <= x"000092DC";
        S_AXI_arvalid <= '1';

        wait on clk until S_AXI_arready = '1' and clk = '1';
        S_AXI_arvalid <= '0';
        wait on clk until S_AXI_rvalid = '1' and clk = '1';

        S_AXI_araddr <= x"000092DC";
        S_AXI_arvalid <= '1';

        wait on clk until S_AXI_arready = '1' and clk = '1';
        S_AXI_arvalid <= '0';
        wait on clk until S_AXI_rvalid = '1' and clk = '1';

        ------------------------------------------------------------------------
        wait until cycles = 4132; -- Read lower 32b + higher 32b of different addr

        S_AXI_araddr <= x"00009000";
        S_AXI_arvalid <= '1';

        wait on clk until S_AXI_arready = '1' and clk = '1';
        S_AXI_arvalid <= '0';
        wait on clk until S_AXI_rvalid = '1' and clk = '1';

        S_AXI_araddr <= x"000092E4";
        S_AXI_arvalid <= '1';

        wait on clk until S_AXI_arready = '1' and clk = '1';
        S_AXI_arvalid <= '0';
        wait on clk until S_AXI_rvalid = '1' and clk = '1';

        ------------------------------------------------------------------------
        wait until cycles = 4138; -- Read higher 32b + lower 32b of different addr

        S_AXI_araddr <= x"00009004";
        S_AXI_arvalid <= '1';

        wait on clk until S_AXI_arready = '1' and clk = '1';
        S_AXI_arvalid <= '0';
        wait on clk until S_AXI_rvalid = '1' and clk = '1';

        S_AXI_araddr <= x"000092E8";
        S_AXI_arvalid <= '1';

        wait on clk until S_AXI_arready = '1' and clk = '1';
        S_AXI_arvalid <= '0';
        wait on clk until S_AXI_rvalid = '1' and clk = '1';

        ------------------------------------------------------------------------
        wait until cycles = 4144; -- Read lower 32b + lower 32b of different addr

        S_AXI_araddr <= x"00009000";
        S_AXI_arvalid <= '1';

        wait on clk until S_AXI_arready = '1' and clk = '1';
        S_AXI_arvalid <= '0';
        wait on clk until S_AXI_rvalid = '1' and clk = '1';

        S_AXI_araddr <= x"000092F0";
        S_AXI_arvalid <= '1';

        wait on clk until S_AXI_arready = '1' and clk = '1';
        S_AXI_arvalid <= '0';
        wait on clk until S_AXI_rvalid = '1' and clk = '1';

        ------------------------------------------------------------------------
        wait until cycles = 4150; -- Read higher 32b + higher 32b of different addr

        S_AXI_araddr <= x"00009004";
        S_AXI_arvalid <= '1';

        wait on clk until S_AXI_arready = '1' and clk = '1';
        S_AXI_arvalid <= '0';
        wait on clk until S_AXI_rvalid = '1' and clk = '1';

        S_AXI_araddr <= x"000092FC";
        S_AXI_arvalid <= '1';

        wait on clk until S_AXI_arready = '1' and clk = '1';
        S_AXI_arvalid <= '0';
        wait on clk until S_AXI_rvalid = '1' and clk = '1';

        ------------------------------------------------------------------------
        wait until cycles = 4160; -- Write 32b + FLUSH -------------------------

        S_AXI_awaddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_unsigned(4, 32));
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= x"01234567";
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

          -- Write on Shared Base - 1 == FLUSH
        S_AXI_awaddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_signed(-1, 32));
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= x"22222222";
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

        ------------------------------------------------------------------------
        wait until cycles = 4170; -- Write <32b + FLUSH ------------------------

        S_AXI_awaddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_unsigned(4, 32));
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= x"FFFFFFFF";
        S_AXI_wstrb <= "0011";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

          -- Write on Shared Base - 1 == FLUSH
          -- (shouldn't request nor set shared mem enable)
        S_AXI_awaddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_signed(-1, 32));
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= x"22222222";
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';

        ------------------------------------------------------------------------
        wait until cycles = 4180; -- Read lower 32b + FLUSH + Read higher 32b (same addr)

        S_AXI_araddr <= x"00009320";
        S_AXI_arvalid <= '1';

        wait on clk until S_AXI_arready = '1' and clk = '1';
        S_AXI_arvalid <= '0';
        wait on clk until S_AXI_rvalid = '1' and clk = '1';


          -- You can also try to comment this FLUSH action and check 2nd read is different
        -- -- -- 
        S_AXI_awaddr <= BPF_MEM_SHARED_BASE_U32 + std_logic_vector(to_signed(-1, 32));
        S_AXI_awvalid <= '1';

        S_AXI_wdata <= x"22222222";
        S_AXI_wstrb <= "1111";
        S_AXI_wvalid <= '1';

        wait on clk until S_AXI_awready = '1' and S_AXI_wready = '1' and clk = '1';
        S_AXI_awvalid <= '0';
        S_AXI_wvalid <= '0';
        wait on clk until S_AXI_bvalid = '1' and clk = '1';
        -- -- --

        S_AXI_araddr <= x"00009324";
        S_AXI_arvalid <= '1';

        wait on clk until S_AXI_arready = '1' and clk = '1';
        S_AXI_arvalid <= '0';
        wait on clk until S_AXI_rvalid = '1' and clk = '1';

        wait;

    end process;

end Behavioral;