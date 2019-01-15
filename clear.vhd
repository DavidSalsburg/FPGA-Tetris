library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; -- cuts down on type conversions

entity clear is Port (
    clk    : in  STD_LOGIC;
    lock   : in  STD_LOGIC;
    rpixel : in  STD_LOGIC_VECTOR (3 downto 0);
    raddr  : out STD_LOGIC_VECTOR (8 downto 0) := (others => '0');
    wen    : out STD_LOGIC := '0';
    wpixel : out STD_LOGIC_VECTOR (3 downto 0) := (others => '0');
    waddr  : out STD_LOGIC_VECTOR (8 downto 0) := (others => '0');
    done   : out STD_LOGIC := '0');
end clear;

architecture Behavioral of clear is
    signal row, count, write : STD_LOGIC_VECTOR (8 downto 0) := (others => '0');
    type statetype is (zero, one);
    signal state : statetype := zero;

begin
    process (clk) begin
        if rising_edge(clk) then
            case (state) is
                when zero =>
                    done   <= '0';
                    if lock = '1' then
                        state <= one;
                    end if;
                when one =>
                    if row < 240 then
                        if count = 0 then -- test if row contains any empty space
                            count  <= count + 1;
                            raddr  <= row + count + 13;
                        elsif count <= 10 then 
                            count  <= count + 1;
                            raddr  <= row + count + 13;
                            if rpixel = "0000" then -- skip to next row if so
                                count <= (others => '0');
                                row   <= row + 12;
                            end if;
                        elsif count = 11 then
                            count <= count + 1;
                            raddr <= row + 10;
                        else
                            if (row - write + 10) > 0 then -- otherwise clear row by overwriting
                                write <= write + 1; -- each block becomes the block at loc - 12
                                raddr <= row - write + 9;
                                wen   <= '1';
                                waddr <= row - write + 22;
                                if (row - write + 10) > 10 then
                                    wpixel <= rpixel;
                                else
                                    wpixel <= "0000"; -- fill top row in with black
                                end if;
                            else
                                count <= (others => '0');
                                write <= (others => '0');
                                row   <= row + 12; -- then continue checking rows
                                wen   <= '0'; -- (because multi-clears are possible)
                            end if;
                        end if;
                    else
                        state <= zero; -- output only 0 while inactive
                        done  <= '1'; -- because read/write line shared with piece
                        row    <= (others => '0');
                        count  <= (others => '0');
                        raddr  <= (others => '0');
                        wpixel <= (others => '0');
                        waddr  <= (others => '0');
                        wen    <= '0';
                    end if;
            end case;
        end if;
    end process;
end Behavioral;

--When a lock pulse is received, check each row of the field (or just the rows where the piece was placed).
--If every cell of a checked row is non-empty, write the above row into the checked row.
--Repeat upward, writing each row into the row below it. Fill the topmost row with all empty cells.
--When finished checking all relevant rows, send a done pulse.