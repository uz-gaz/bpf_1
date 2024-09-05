--------------------------------------------------------------------------------
-- Project Name: A basic processor core for running BPF programs
-- Author:       Fernando Lahoz Bernad
--
-- Description:  Declaration of all mem components used by the BPF core:
--                 -> Block_Mem_Inst : 32 KiB -> 4096 words
--                 -> Block_Mem_Unshared : 2560 B -> 320 words
--                 -> Block_Mem_Shared : 28 KiB -> 3584 words
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity Block_Mem_Inst is
    port (
        clka : in std_logic;
        ena : in std_logic;

        addra : in std_logic_vector(11 downto 0);
        dina : in std_logic_vector(63 downto 0);
        douta : out std_logic_vector(63 downto 0);
        wea : in std_logic_vector(7 downto 0)
    );
end Block_Mem_Inst;

architecture Behavioral of Block_Mem_Inst is

    component Block_Mem_base is
        generic ( WIDTH : natural; DEPTH : natural );
        port (
            clka : in std_logic;
            ena : in std_logic;
    
            addra : in std_logic_vector(integer(ceil(log2(real(DEPTH)))) - 1 downto 0);
            dina : in std_logic_vector(WIDTH - 1 downto 0);
            douta : out std_logic_vector(WIDTH - 1 downto 0);
            wea : in std_logic_vector((WIDTH / 8) - 1 downto 0)
        );
    end component;

begin

    BRAM: Block_Mem_base
        generic map ( WIDTH => 64, DEPTH => 4096 )
        port map (
            clka => clka, ena => ena,
            addra => addra, dina => dina, douta => douta, wea => wea
        );

end Behavioral;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity Block_Mem_Unshared is
    port (
        clka : in std_logic;
        ena : in std_logic;

        addra : in std_logic_vector(8 downto 0);
        dina : in std_logic_vector(63 downto 0);
        douta : out std_logic_vector(63 downto 0);
        wea : in std_logic_vector(7 downto 0)
    );
end Block_Mem_Unshared;

architecture Behavioral of Block_Mem_Unshared is

    component Block_Mem_base is
        generic ( WIDTH : natural; DEPTH : natural );
        port (
            clka : in std_logic;
            ena : in std_logic;
    
            addra : in std_logic_vector(integer(ceil(log2(real(DEPTH)))) - 1 downto 0);
            dina : in std_logic_vector(WIDTH - 1 downto 0);
            douta : out std_logic_vector(WIDTH - 1 downto 0);
            wea : in std_logic_vector((WIDTH / 8) - 1 downto 0)
        );
    end component;

begin

    BRAM: Block_Mem_base
        generic map ( WIDTH => 64, DEPTH => 320 )
        port map (
            clka => clka, ena => ena,
            addra => addra, dina => dina, douta => douta, wea => wea
        );

end Behavioral;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity Block_Mem_Shared is
    port (
        clka : in std_logic;
        ena : in std_logic;

        addra : in std_logic_vector(11 downto 0);
        dina : in std_logic_vector(63 downto 0);
        douta : out std_logic_vector(63 downto 0);
        wea : in std_logic_vector(7 downto 0)
    );
end Block_Mem_Shared;

architecture Behavioral of Block_Mem_Shared is

    component Block_Mem_base is
        generic ( WIDTH : natural; DEPTH : natural );
        port (
            clka : in std_logic;
            ena : in std_logic;
    
            addra : in std_logic_vector(integer(ceil(log2(real(DEPTH)))) - 1 downto 0);
            dina : in std_logic_vector(WIDTH - 1 downto 0);
            douta : out std_logic_vector(WIDTH - 1 downto 0);
            wea : in std_logic_vector((WIDTH / 8) - 1 downto 0)
        );
    end component;

begin

    BRAM: Block_Mem_base
        generic map ( WIDTH => 64, DEPTH => 3584 )
        port map (
            clka => clka, ena => ena,
            addra => addra, dina => dina, douta => douta, wea => wea
        );

end Behavioral;