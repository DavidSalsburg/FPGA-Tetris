library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rng is Port (
    clk   : in  STD_LOGIC;
    ready : in  STD_LOGIC;
    piece : out STD_LOGIC_VECTOR (2 downto 0);
    spawn : out STD_LOGIC := '0');
end rng;

architecture Behavioral of rng is
    signal count : STD_LOGIC_VECTOR (2 downto 0) := (others => '0');
begin
process(clk) begin
if rising_edge(clk) then
 if ready = '1' then
        piece <= count;
        spawn <= '1'; 
 else 
        spawn <= '0';       
 end if;
    if count = "110" then
        count <= (others => '0');
        else 
        count <= std_logic_vector(unsigned(count)+1);  
    end if;
end if;

end process;
end Behavioral;

--RNG refers to a Random Number Generator.
--A counter which increments on every clock tick is essentially random on a human timescale.
--The counter cycles continuously within the range 0 to 6, where each value represents a piece type.
--When receiving the ready signal, it updates the current piece value and pulses the spawn signal.