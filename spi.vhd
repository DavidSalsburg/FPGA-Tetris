library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi is Port (
    clk   : in  STD_LOGIC;
    en    : in  STD_LOGIC;
    MISO  : in  STD_LOGIC;
    CS    : out STD_LOGIC := '1';
    SCK   : out STD_LOGIC;
    left  : out STD_LOGIC := '0';
    right : out STD_LOGIC := '0';
    down  : out STD_LOGIC := '0');
end spi;

architecture Behavioral of spi is
    signal count : integer := 0;
    signal shift : STD_LOGIC_VECTOR (39 downto 0) := (25 => '1', 9 => '1', others => '0');
    signal xpos, ypos: integer := 512;
    signal SCKi : STD_LOGIC := '0';

begin
    SCK <= SCKi;
    
    process (clk) begin
        if rising_edge(clk) and en = '1' then
            if count >= 239 then
                count <= 0;
            else
                count <= count + 1;
            end if;
            
            if count = 0 then -- bit order: x[76543210 ......98] y[76543210 ......98] ........
                CS <= '1';
                xpos <= to_integer(unsigned(shift(25 downto 24) & shift(39 downto 32)));
                ypos <= to_integer(unsigned(shift( 9 downto  8) & shift(23 downto 16)));
            elsif count = 1 then
                if xpos > 383 and xpos < 640 and ypos > 383 then -- 25% deadzone
                    left  <= '0';
                    right <= '0';
                    down  <= '0';
                elsif xpos < 512 then -- left bias or right bias?
                    if xpos < ypos then -- which is more extreme, left or down?
                        left  <= '1';
                        right <= '0';
                        down  <= '0';
                    else
                        left  <= '0';
                        right <= '0';
                        down  <= '1';
                    end if;
                else
                    if (1023 - xpos) < ypos then -- more extreme, right or down?
                        left  <= '0';
                        right <= '1';
                        down  <= '0';
                    else
                        left  <= '0';
                        right <= '0';
                        down  <= '1';
                    end if;
                end if;
            elsif count >= 50 and count < 80 then -- wait 25us then chip select low
                CS <= '0';
            elsif count >= 80 and count < 96 then -- wait 15us then read first byte
                if SCKi = '0' then
                    SCKi <= '1';
                    shift <= shift(38 downto 0) & MISO;
                else
                    SCKi <= '0';
                end if;
            elsif count >= 116 and count < 132 then -- wait 10us then read second byte
                if SCKi = '0' then
                    SCKi <= '1';
                    shift <= shift(38 downto 0) & MISO;
                else
                    SCKi <= '0';
                end if;
            elsif count >= 152 and count < 168 then -- wait 10us
                if SCKi = '0' then
                    SCKi <= '1';
                    shift <= shift(38 downto 0) & MISO;
                else
                    SCKi <= '0';
                end if;
            elsif count >= 188 and count < 204 then -- wait 10us
                if SCKi = '0' then
                    SCKi <= '1';
                    shift <= shift(38 downto 0) & MISO;
                else
                    SCKi <= '0';
                end if;
            elsif count >= 224 and count < 240 then -- wait 10us then read fifth/last byte
                if SCKi = '0' then
                    SCKi <= '1';
                    shift <= shift(38 downto 0) & MISO;
                else
                    SCKi <= '0';
                end if;
            end if;
        end if;
    end process;
end Behavioral;

--SPI refers to a Serial Peripheral Interface.
--Starting from when CS goes low, the joystick must be given 15(30) full cycles to prepare.
--Following that, a new bit is placed onto MISO on every falling edge of SCK.
--Once all data (40 bits) have been transferred, CS must remain high for at least 25(50) full cycles.
--All signals are sent MSB first, in the following order.
--10-bit X coordinate, 6 empty bits, 10-bit Y coordinate, 11 empty bits, 3 bits button statuses (discarded).
--X coordinate ranges from 0 (left) to 1023 (right), and likewise for the Y coordinate (down to up).
--After receiving all coordinate values, evaluate which direction output to set to 1, if any.
--If both coordinates fall in the range [384, 639] (25% deadzone), all direction outputs are 0.
--Otherwise put a 1 on the most extreme output (closest to 0 or 1023).
--(If port faces up:) Left: X~=0, right: X~=1023, down: Y~=0.
--(Y~=1023, rather than output up, results in all 0 outputs.)