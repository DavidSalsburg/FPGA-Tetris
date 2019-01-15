library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity start is Port (
    clk   : in  STD_LOGIC;
    left  : in  STD_LOGIC;
    right : in  STD_LOGIC;
    down  : in  STD_LOGIC;
    B     : in  STD_LOGIC;
    A     : in  STD_LOGIC;
    start : out STD_LOGIC := '0');
end start;

architecture Behavioral of start is
    signal starti : STD_LOGIC := '0';
    signal trig   : STD_LOGIC := '0';  

begin
    start <= starti;

process (clk) begin
    if rising_edge(clk) then
        if starti = '1' then
            starti <= '0';
        elsif starti = '0' and trig ='0' and (
            left  = '1' or
            right = '1' or
            down  = '1' or
            B     = '1' or
            A     = '1')
        then
            starti <= '1';
            trig   <= '1';
        end if;
    end if;
end process;
end Behavioral;

--Start waits for a button press and pulses the RNG
--Then outputs only 0 from then on