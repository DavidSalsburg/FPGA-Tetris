library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debounce is Port (
    clk  : in  STD_LOGIC;
    btn  : in  STD_LOGIC;
    dbnc : out STD_LOGIC);
end debounce;

architecture Behavioral of debounce is
    signal button  : std_logic_vector( 1 downto 0) := (others => '0');
    signal counter : integer := 0;
    
begin process (clk) begin
    if rising_edge(clk) then
        button <= button(0) & btn;
        
        if (button(1) = '1') then
            if (counter < 65535) then
                counter <= counter + 1;                    
            end if;
            if (counter = 65534) then
                dbnc <= '1';
            else
                dbnc <= '0';
            end if;
        else
            counter <= 0;
            dbnc <= '0';
        end if; 
    end if;
end process;
end Behavioral;