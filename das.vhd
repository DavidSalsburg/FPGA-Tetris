library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity das is Port (
    clk    : in  STD_LOGIC;
    dasin  : in  STD_LOGIC;
    dasout : out STD_LOGIC);
end das;

architecture Behavioral of das is
    signal count : integer := 0;
    signal crtlbit: STD_LOGIC :='0';
begin
process (clk) begin
if rising_edge(clk) then
    if dasin = '1' then
        if count >= 25000000 then
            dasout <= '1';
            count <= 0;
            crtlbit <= '1';
        elsif count = 0  and crtlbit ='0' then
            dasout <= '1';
            count <= count + 1; 
        else 
            dasout <= '0';
            count <= count + 1;
            if count >= 10000000 and crtlbit ='1' then
                dasout <= '1';
                count <= 0;
            else 
                dasout <= '0';
            end if; 
        end if;
    else 
        dasout  <= '0';
        count   <= 0;
        crtlbit <= '0';
    end if;
end if;
end process;
end Behavioral;

--DAS refers to Delayed Auto Shift.
--It begins when the same direction has been held for 0.25 sec
--It responds by pulsing the same direction every 0.1 sec
--The hold counter resets as soon as the direction is released.