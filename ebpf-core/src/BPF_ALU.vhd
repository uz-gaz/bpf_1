--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  ALU for a BPF processor
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.bpf.all;

entity BPF_ALU is
    port (
        clk : in std_logic;
        reset : in std_logic;
        alu_en : in std_logic;
        operand_A : in std_logic_vector (63 downto 0);
        operand_B : in std_logic_vector (63 downto 0);
        op_alu : in std_logic_vector (3 downto 0);
        op_64b : in std_logic;
        signed_alu : in std_logic; -- Only for SDIV and SMOD
        sx_size : in std_logic_vector (1 downto 0); -- Only for MOVSX

        alu_ready : out std_logic;
        output : out std_logic_vector (63 downto 0)
    );
end BPF_ALU;

architecture Behavioral of BPF_ALU is

    component BPF_Byte_Mask is
        port (
            input : in std_logic_vector (63 downto 0);
            size : in std_logic_vector (1 downto 0);
            sign_extend : in std_logic;
            output : out std_logic_vector (63 downto 0)
        );
    end component;

    component Divider_U64 is
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
    end component;

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

    -- Output multiplexed buses
    signal add_bus, sub_bus, mul_bus, div_bus, mod_bus : std_logic_vector (63 downto 0);
    signal or_bus, and_bus, lsh_bus, rsh_bus, neg_bus : std_logic_vector (63 downto 0);
    signal xor_bus, arsh_bus, mov_bus, end_bus : std_logic_vector (63 downto 0);
    signal raw_output_bus : std_logic_vector (63 downto 0);

    -- Byte swap signals
    signal byte_swap_16b, byte_swap_32b, byte_swap_64b : std_logic_vector (63 downto 0);

    -- Multiplication signals
    signal mult_aux : std_logic_vector (127 downto 0);

    -- Division signals --------------------------------------------------------
    signal div_result : std_logic_vector (127 downto 0);
    signal ok_A, ok_B, ok_div : std_logic;
    signal div_by_0, neg_A, neg_B, neg_result, neg_result_pre, update_neg_result : std_logic;
    signal dividend, divisor : std_logic_vector (63 downto 0);

    signal use_divider, divider_ready, A_ready, B_ready, aresetn, await_div : std_logic;
    signal save_operands, use_saved_operands : std_logic;
    signal saved_operand_A, saved_operand_B : std_logic_vector (63 downto 0);
    signal sync_operand_A, sync_operand_B : std_logic_vector (63 downto 0);

    type DivState_t is (INIT_S, RESET_S, DIVIDING_S, READY_TO_DIVIDE_S);
    signal div_state, div_next_state : DivState_t;
    ----------------------------------------------------------------------------

    constant ZERO32 : std_logic_vector := (31 downto 0 => '0');
    constant ZERO64 : std_logic_vector := (63 downto 0 => '0');
begin

    saved_operand_A_reg: Register_N
        generic map ( SIZE => 64 )
        port map (
            clk => clk,
            reset => reset,
            load => save_operands,    
            input => operand_A,
            output => saved_operand_A
        );

    saved_operand_B_reg: Register_N
        generic map ( SIZE => 64 )
        port map (
            clk => clk,
            reset => reset,
            load => save_operands,    
            input => operand_B,
            output => saved_operand_B
        );

    sync_operand_A <= operand_A when use_saved_operands = '0' else saved_operand_A;
    sync_operand_B <= operand_B when use_saved_operands = '0' else saved_operand_B;
    
    ----------------------------------------------------------------------------

    add_bus <= std_logic_vector(unsigned(operand_A) + unsigned(operand_B));
    sub_bus <= operand_A - operand_B;

    mult_aux <= std_logic_vector(unsigned(operand_A) * unsigned(operand_B)); -- Could be segmented if necessary
    mul_bus <= mult_aux(63 downto 0);
    
    or_bus <= operand_A or operand_B;
    and_bus <= operand_A and operand_B;
    lsh_bus <= std_logic_vector(shift_left(unsigned(operand_A), conv_integer(operand_B(5 downto 0))));
    rsh_bus <= std_logic_vector(shift_right(unsigned(operand_A), conv_integer(operand_B(5 downto 0))));
    neg_bus <= not operand_A;
    xor_bus <= operand_A xor operand_B;

    arsh_bus <= std_logic_vector(shift_right(signed(operand_A), conv_integer(operand_B(5 downto 0)))) when op_64b = '1' else
                ZERO32 & std_logic_vector(shift_right(signed(operand_A(31 downto 0)), conv_integer(operand_B(5 downto 0))));

    movsx_byte_mask: BPF_Byte_Mask
        port map (
            input => operand_B,
            size => sx_size,
            sign_extend => '1',
            output => mov_bus
        );
    
    -- Byte swap ---------------------------------------------------------------
    
    byte_swap_16b <= (47 downto 0 => '0') &
                     operand_A(7 downto 0) &
                     operand_A(15 downto 8);
    
    byte_swap_32b <= (31 downto 0 => '0') &
                     operand_A(7 downto 0) &
                     operand_A(15 downto 8) &
                     operand_A(23 downto 16) &
                     operand_A(31 downto 24);

    byte_swap_64b <= operand_A(7 downto 0) &
                     operand_A(15 downto 8) &
                     operand_A(23 downto 16) &
                     operand_A(31 downto 24) &
                     operand_A(39 downto 32) &
                     operand_A(47 downto 40) &
                     operand_A(55 downto 48) &
                     operand_A(63 downto 56);

    end_bus <= byte_swap_16b when operand_B(4) = '1' else
               byte_swap_32b when operand_B(5) = '1' else
               byte_swap_64b when operand_B(6) = '1' else operand_A;

    ----------------------------------------------------------------------------

    -- Division ----------------------------------------------------------------

    div_by_0 <= '1' when operand_B = ZERO64 and div_state = INIT_S else '0';

    use_divider <= '1' when (op_alu = BPF_DIV or op_alu = BPF_MOD) and div_by_0 = '0' and alu_en = '1' else '0';
    
    divider_ready <= A_ready and B_ready;

    neg_A <= '1' when (op_64b = '1' and signed_alu = '1' and sync_operand_A(63) = '1')
                   or (op_64b = '0' and signed_alu = '1' and sync_operand_A(31) = '1') else '0';
    neg_B <= '1' when (op_64b = '1' and signed_alu = '1' and sync_operand_B(63) = '1')
                   or (op_64b = '0' and signed_alu = '1' and sync_operand_B(31) = '1') else '0';

    neg_result_pre <= neg_A xor neg_B; -- Negate result if both operands are negative

    dividend <= ZERO64 - sync_operand_A when op_64b = '1' and neg_A = '1' else
                ZERO32 & (ZERO32 - sync_operand_A(31 downto 0)) when op_64b = '0' and neg_A = '1' else
                sync_operand_A;

    divisor  <= ZERO64 - sync_operand_B when op_64b = '1' and neg_B = '1' else
                ZERO32 & (ZERO32 - sync_operand_B(31 downto 0)) when op_64b = '0' and neg_B = '1' else
                sync_operand_B;

    divider: Divider_U64
        port map (
            aclk => clk,
            aresetn => aresetn,
            s_axis_divisor_tvalid => ok_B,
            s_axis_divisor_tdata => divisor,
            s_axis_divisor_tready => A_ready,
            s_axis_dividend_tvalid => ok_A,
            s_axis_dividend_tdata => dividend,
            s_axis_dividend_tready => B_ready,
            m_axis_dout_tvalid => ok_div,
            m_axis_dout_tdata => div_result
        );
    
    div_bus <= ZERO64 when div_by_0 = '1' else
               ZERO64 - div_result(127 downto 64) when neg_result = '1' else
               div_result(127 downto 64);

    mod_bus <= operand_A when div_by_0 = '1' else
               ZERO64 - div_result(63 downto 0) when neg_result = '1' else
               div_result(63 downto 0);

    
    saved_neg_result_block: process (clk)
    begin
        if (clk'event and clk = '1') then
            if (reset = '1') then
                neg_result <= '0';
            elsif (update_neg_result = '1') then 
                neg_result <= neg_result_pre;
            end if;        
        end if;
    end process;

    -- control with state machine --

    SYNC_PROC: process (clk)
    begin
        if (clk'event and clk = '1') then
            div_state <= div_next_state;
        end if;
    end process;

    DIV_CONTROL: process (div_state, reset, use_divider, divider_ready, ok_div)
    begin
        -- Default values
        div_next_state <= div_state;

        aresetn <= '1';
        use_saved_operands <= '0';
        save_operands <= '0';
        await_div <= '0';
        ok_A <= '0';
        ok_B <= '0';
        update_neg_result <= '0';

        if (div_state = INIT_S) then

            if (reset = '1') then
                div_next_state <= RESET_S;
                aresetn <= '0';

            elsif (use_divider = '1' and divider_ready = '0') then
                div_next_state <= READY_TO_DIVIDE_S;
                save_operands <= '1';
                await_div <= '1';
                update_neg_result <= '1';

            elsif (use_divider = '1' and divider_ready = '1') then
                div_next_state <= DIVIDING_S;
                use_saved_operands <= '0';
                ok_A <= '1';
                ok_B <= '1';
                await_div <= '1';
                update_neg_result <= '1';
            end if;
            
        elsif (div_state = READY_TO_DIVIDE_S) then
            await_div <= '1';

            if (reset = '1') then
                div_next_state <= RESET_S;
                aresetn <= '0';

            elsif (divider_ready = '1') then
                div_next_state <= DIVIDING_S;
                use_saved_operands <= '1';
                ok_A <= '1';
                ok_B <= '1';
                await_div <= '1';
            end if;

        elsif (div_state = DIVIDING_S) then
            await_div <= '1';

            if (reset = '1') then
                div_next_state <= RESET_S;
                aresetn <= '0';

            elsif (ok_div = '1') then
                div_next_state <= INIT_S;
                await_div <= '0';
            end if;

        elsif (div_state = RESET_S) then

            div_next_state <= INIT_S;
            aresetn <= '0';

        end if;
    end process;   

    ----------------------------------------------------------------------------

    -- Multiplex output depending on the selected operation 
    raw_output_bus <= add_bus when op_alu = BPF_ADD else
                      sub_bus when op_alu = BPF_SUB else
                      mul_bus when op_alu = BPF_MUL else
                      div_bus when op_alu = BPF_DIV else
                      or_bus  when op_alu = BPF_OR else
                      and_bus when op_alu = BPF_AND else
                      lsh_bus when op_alu = BPF_LSH else
                      rsh_bus when op_alu = BPF_RSH else
                      neg_bus when op_alu = BPF_NEG else
                      mod_bus when op_alu = BPF_MOD else
                      xor_bus when op_alu = BPF_XOR else
                      mov_bus when op_alu = BPF_MOV else
                      arsh_bus when op_alu = BPF_ARSH else
                      end_bus when op_alu = BPF_END else ZERO64;

    output <= raw_output_bus when op_64b = '1' else ZERO32 & raw_output_bus(31 downto 0);

    alu_ready <= (not await_div) when (op_alu = BPF_DIV or op_alu = BPF_MOD) and div_by_0 = '0' and alu_en = '1' else '1';

end architecture;