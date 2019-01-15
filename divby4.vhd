library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity divby4 is
    Port ( clk : in  STD_LOGIC;
           div : out STD_LOGIC := '0');
end divby4;

architecture Behavioral of divby4 is
    signal count : std_logic_vector(1 downto 0) := (others => '0');

begin process(clk) begin
    if rising_edge(clk) then
        if (unsigned(count) = 0) then
            count <= std_logic_vector(To_unsigned(3, 2));
            div <= '1';
        else
            count <= std_logic_vector(unsigned(count) - 1);
            div <= '0';
        end if;
    end if;
end process;
end Behavioral;