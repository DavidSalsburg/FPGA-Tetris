library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity field is Port (
    clk     : in  STD_LOGIC;
    raddr1  : in  STD_LOGIC_VECTOR (8 downto 0);
    raddr2  : in  STD_LOGIC_VECTOR (8 downto 0);
    wen     : in  STD_LOGIC;
    waddr   : in  STD_LOGIC_VECTOR (8 downto 0);
    wpixel  : in  STD_LOGIC_VECTOR (3 downto 0);
    rpixel1 : out STD_LOGIC_VECTOR (3 downto 0);
    rpixel2 : out STD_LOGIC_VECTOR (3 downto 0));
end field;

architecture Behavioral of field is
    type fieldtype is array (0 to 263) of STD_LOGIC_VECTOR (3 downto 0);
    signal data : fieldtype := ( -- field initial state (white border, black interior)
         13 to  22 => "0000",  25 to  34 => "0000",  37 to  46 => "0000",  49 to  58 => "0000",
         61 to  70 => "0000",  73 to  82 => "0000",  85 to  94 => "0000",  97 to 106 => "0000",
        109 to 118 => "0000", 121 to 130 => "0000", 133 to 142 => "0000", 145 to 154 => "0000",
        157 to 166 => "0000", 169 to 178 => "0000", 181 to 190 => "0000", 193 to 202 => "0000",
        205 to 214 => "0000", 217 to 226 => "0000", 229 to 238 => "0000", 241 to 250 => "0000", others => "1111");
begin

rpixel1 <= data(to_integer((unsigned(raddr1))));
rpixel2 <= data(to_integer((unsigned(raddr2))));
process (clk) begin
if rising_edge(clk) then
    if wen = '1' then
        data(to_integer((unsigned(waddr)))) <= wpixel;
    end if;
end if;
end process;
end Behavioral;

--The field size is 12 wide, 22 high.
--The outer border is all white, leaving an inner area of 10 wide, 20 high.
--Each pixel is represented by 4 bits: 1 red, 2 green, 1 blue.
--There are two pairs of read ports and one pair of write ports.