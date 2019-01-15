library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_ctrl is Port (
    clk, en : in STD_LOGIC;
    hcount : buffer STD_LOGIC_VECTOR (9 downto 0) := (others => '0');
    vid : out STD_LOGIC := '1';
    hs  : out STD_LOGIC := '1';
    vs  : out STD_LOGIC := '1');
end vga_ctrl;

architecture Behavioral of vga_ctrl is
    signal vcount : STD_LOGIC_VECTOR (9 downto 0) := (others => '0');

begin
    process (clk, hcount, vcount) begin  
        if (rising_edge(clk) and en = '1') then
            if (unsigned(hcount) >= 799) then
                hcount <= (others => '0');
                
                if (unsigned(vcount) >= 524) then
                    vcount <= (others => '0');
                else
                    vcount <= std_logic_vector(unsigned(vcount) + 1);
                end if;
            else
                hcount <= std_logic_vector(unsigned(hcount) + 1);
            end if;
        end if;
        
        if (unsigned(hcount) <= 639 and unsigned(vcount) <= 479) then
            vid <= '1';
        else
            vid <= '0';
        end if;
        
        if (unsigned(hcount) >= 656 and unsigned(hcount) <= 751) then
            hs <= '0';
        else
            hs <= '1';
        end if;
        
        if (unsigned(vcount) >= 490 and unsigned(vcount) <= 491) then
            vs <= '0';
        else
            vs <= '1';
        end if;         
    end process;
end Behavioral;