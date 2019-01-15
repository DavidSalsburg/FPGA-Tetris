library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tetris_top is Port (
    clk   : in  STD_LOGIC;
    left  : in  STD_LOGIC;
    right : in  STD_LOGIC;
    down  : in  STD_LOGIC;
    B     : in  STD_LOGIC;
    A     : in  STD_LOGIC;
    addr  : in  STD_LOGIC_VECTOR (8 downto 0);
    pixel : out STD_LOGIC_VECTOR (3 downto 0));
end tetris_top;

architecture Behavioral of tetris_top is
    signal lefti    : STD_LOGIC;
    signal righti   : STD_LOGIC;
    signal downi    : STD_LOGIC;
    signal piecei   : STD_LOGIC_VECTOR (2 downto 0);
    signal locki    : STD_LOGIC;
    signal readyi   : STD_LOGIC;
    signal spawni   : STD_LOGIC;
    signal rpixeli  : STD_LOGIC_VECTOR (3 downto 0);
    signal raddri   : STD_LOGIC_VECTOR (8 downto 0);
    signal weni     : STD_LOGIC;
    signal wpixeli  : STD_LOGIC_VECTOR (3 downto 0);
    signal waddri   : STD_LOGIC_VECTOR (8 downto 0);
    signal starti   : STD_LOGIC;
    signal donei    : STD_LOGIC;
    signal raddri1  : STD_LOGIC_VECTOR (8 downto 0);
    signal weni1    : STD_LOGIC;
    signal wpixeli1 : STD_LOGIC_VECTOR (3 downto 0);
    signal waddri1  : STD_LOGIC_VECTOR (8 downto 0);
    signal raddri2  : STD_LOGIC_VECTOR (8 downto 0);
    signal weni2    : STD_LOGIC;
    signal wpixeli2 : STD_LOGIC_VECTOR (3 downto 0);
    signal waddri2  : STD_LOGIC_VECTOR (8 downto 0);
    
    component das is Port ( 
        clk    : in  STD_LOGIC;
        dasin  : in  STD_LOGIC;
        dasout : out STD_LOGIC);
    end component;
    
    component drop is Port ( 
        clk     : in  STD_LOGIC;
        spawn   : in  STD_LOGIC;
        dropin  : in  STD_LOGIC;
        dropout : out STD_LOGIC);
    end component;
    
    component start is Port (
        clk   : in  STD_LOGIC;
        left  : in  STD_LOGIC;
        right : in  STD_LOGIC;
        down  : in  STD_LOGIC;
        B     : in  STD_LOGIC;
        A     : in  STD_LOGIC;
        start : out STD_LOGIC);
    end component;

    component rng is Port ( 
        clk   : in  STD_LOGIC;
        ready : in  STD_LOGIC;
        piece : out STD_LOGIC_VECTOR (2 downto 0);
        spawn : out STD_LOGIC);
    end component;
    
    component field is Port ( 
        clk     : in  STD_LOGIC;
        raddr1  : in  STD_LOGIC_VECTOR (8 downto 0);
        raddr2  : in  STD_LOGIC_VECTOR (8 downto 0);
        wen     : in  STD_LOGIC;
        waddr   : in  STD_LOGIC_VECTOR (8 downto 0);
        wpixel  : in  STD_LOGIC_VECTOR (3 downto 0);
        rpixel1 : out STD_LOGIC_VECTOR (3 downto 0);
        rpixel2 : out STD_LOGIC_VECTOR (3 downto 0));
    end component;
    
    component piece is Port (
        clk    : in  STD_LOGIC;
        spawn  : in  STD_LOGIC;
        left   : in  STD_LOGIC;
        right  : in  STD_LOGIC;
        down   : in  STD_LOGIC;
        B      : in  STD_LOGIC;
        A      : in  STD_LOGIC;
        piece  : in  STD_LOGIC_VECTOR (2 downto 0);
        rpixel : in  STD_LOGIC_VECTOR (3 downto 0);
        raddr  : out STD_LOGIC_VECTOR (8 downto 0);
        wen    : out STD_LOGIC;
        wpixel : out STD_LOGIC_VECTOR (3 downto 0);
        waddr  : out STD_LOGIC_VECTOR (8 downto 0);
        lock   : out STD_LOGIC);
    end component;
    
    component clear is Port (
        clk    : in  STD_LOGIC;
        lock   : in  STD_LOGIC;
        rpixel : in  STD_LOGIC_VECTOR (3 downto 0);
        raddr  : out STD_LOGIC_VECTOR (8 downto 0);
        wen    : out STD_LOGIC;
        wpixel : out STD_LOGIC_VECTOR (3 downto 0);
        waddr  : out STD_LOGIC_VECTOR (8 downto 0);
        done   : out STD_LOGIC);
    end component;
    
begin
    readyi  <= starti or donei;
    raddri  <= raddri1 or raddri2;
    weni    <= weni1 or weni2;
    wpixeli <= wpixeli1 or wpixeli2;
    waddri  <= waddri1 or waddri2;

    ldas: das port map (
        clk    => clk,
        dasin  => left,
        dasout => lefti);
        
    rdas: das port map (
        clk    => clk,
        dasin  => right,
        dasout => righti);
        
    ddrop: drop port map (
        clk     => clk,
        spawn   => spawni,
        dropin  => down,
        dropout => downi);
        
    ustart: start port map (
        clk   => clk,
        left  => lefti,
        right => righti,
        down  => down,
        B     => B,
        A     => A,
        start => starti);
        
    urng: rng port map (
        clk   => clk,
        piece => piecei,
        ready => readyi,
        spawn => spawni);
        
    ufield: field port map (
        clk     => clk,
        raddr1  => addr,
        raddr2  => raddri,
        wen     => weni,
        waddr   => waddri,
        wpixel  => wpixeli,
        rpixel1 => pixel,
        rpixel2 => rpixeli);
        
    upiece: piece port map (
        clk    => clk,
        spawn  => spawni,
        left   => lefti,
        right  => righti,
        down   => downi,
        B      => B,
        A      => A,
        piece  => piecei,
        rpixel => rpixeli,
        raddr  => raddri1,
        wen    => weni1,
        wpixel => wpixeli1,
        waddr  => waddri1,
        lock   => locki);
        
    uclear: clear port map(
        clk    => clk,
        lock   => locki, 
        rpixel => rpixeli,
        raddr  => raddri2,
        wen    => weni2,
        wpixel => wpixeli2,
        waddr  => waddri2,
        done   => donei);

end Behavioral;