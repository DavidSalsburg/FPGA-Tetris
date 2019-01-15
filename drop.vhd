library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity drop is Port (
    clk     : in  STD_LOGIC;
    spawn   : in  STD_LOGIC;
    dropin  : in  STD_LOGIC;
    dropout : out STD_LOGIC);
end drop;

architecture Behavioral of drop is
    signal count : integer := 0;
    signal limit : integer := 80222222;
    signal crtlbit: STD_LOGIC := '0';

begin
	process(clk) begin
		if rising_edge(clk) then
		    if count >= limit then
		        count <= 0;
		        dropout <= '1';
		    else
		        dropout <= '0';
		        count <= count + 1;
		    end if;

		    if dropin = '1' then
		        crtlbit <= '1';
		        count <= 0;
		        if count >= 3333333 and crtlbit = '1' then
		            count <= 0;
		            dropout <= '1';
		        else
		            dropout <= '0';
		            count <= count + 1;
		        end if;
		    end if;  
		            
		    if spawn = '1'then
		    	count <= 0;
		    	if limit > 13555555 then
		    		limit <= limit - 222222; -- decrease delay each time piece is placed
				else
					limit <= 13333333; -- down to the minimum limit
				end if;
		    end if;
		end if;
	end process;
end Behavioral;

--When receiving no inputs, a drop (due to gravity) is output every (initially) 0.8 sec
--Gravity delay decreases with each piece placed, down to a minimum 0.13 sec
--While holding down, a drop is instead output every 0.033 sec