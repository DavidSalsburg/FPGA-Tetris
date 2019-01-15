library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pixel_pusher is Port (
    clk, en, vs, vid : in  STD_LOGIC;
    pixel  : in  STD_LOGIC_VECTOR (3 downto 0);
    hcount : in  STD_LOGIC_VECTOR (9 downto 0);
    R, B   : out STD_LOGIC_VECTOR (4 downto 0) := (others => '0');
    G      : out STD_LOGIC_VECTOR (5 downto 0) := (others => '0');
    addr   : out STD_LOGIC_VECTOR (8 downto 0));
end pixel_pusher;

architecture Behavioral of pixel_pusher is
    signal addri : integer := 12; -- start reading from second row (first is all white)
    signal count, countx, county : integer := 0; -- three-level nested counter setup

begin
    addr <= std_logic_vector(to_unsigned(addri, 9));
    
    process (clk) begin
        if rising_edge(clk) then
            if (vs = '0') then
                addri <= 12; -- reset to second row
            end if;
            
            if (en = '1') then -- only write to screen center, range [176,463]
                if (vid = '1' and unsigned(hcount) > 175 and unsigned(hcount) < 464) then
                    R <= (4 downto 0 => pixel(3)); -- red is all or nothing (RRRRR)
                    G <= pixel(2) & (4 downto 0 => pixel(1)); -- green supports half-value (G GGGGG)
                    B <= (4 downto 0 => pixel(0)); -- blue same as red (BBBBB)
                        -- Green 01 = 011111, 10 = 100000 (both closest values to half-maximum)
                    
                    if count < 23 then
                        count <= count + 1; -- repeat each pixel 24 times
                    else
                        count <= 0;
                        if countx < 11 then -- each row contains 12 pixels
                            countx <= countx + 1;
                            addri  <= addri + 1;
                        else
                            countx <= 0;
                            if county < 23 then -- repeat each row 24 times
                                county <= county + 1;
                                addri  <= addri - 11;
                            else
                                county <= 0;
                                addri  <= addri + 1; -- thus each pixel becomes 24x24
                            end if; -- which enlarges 12x20 to 288x480, filling the screen height
                        end if;
                    end if;
                else
                    R <= (others => '0');
                    G <= (others => '0');
                    B <= (others => '0');  
                end if;
            end if;
        end if;
    end process;
end Behavioral;