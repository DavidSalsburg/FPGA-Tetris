library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity game_top is Port (
    clk125 : in  STD_LOGIC;
--    sw     : in  STD_LOGIC_VECTOR(2 downto 0);
    B      : in  STD_LOGIC;
    A      : in  STD_LOGIC;
    MISO   : in  STD_LOGIC;
    CS     : out STD_LOGIC;
    MOSI   : out STD_LOGIC;
    SCK    : out STD_LOGIC;
    vga_hs, vga_vs : out STD_LOGIC;
    vga_r, vga_b   : out STD_LOGIC_VECTOR (4 downto 0);
    vga_g : out STD_LOGIC_VECTOR (5 downto 0));
end game_top;

architecture Behavioral of game_top is
    signal div, div25, div2, vs, vid, SCKi : STD_LOGIC;
    signal lefti, righti, downi, Ai, Bi : STD_LOGIC;
    signal pixel  : STD_LOGIC_VECTOR (3 downto 0);
    signal hcount : STD_LOGIC_VECTOR (9 downto 0);
    signal addr   : STD_LOGIC_VECTOR (8 downto 0);
    
    component clk_wiz_0 is port (
        clk_in1  : in  std_logic;
        clk_out1 : out std_logic);
    end component;
    
    component divby4 is Port (
        clk : in  STD_LOGIC;
        div : out STD_LOGIC);
    end component;
    
    component divby50 is Port (
        clk : in  STD_LOGIC;
        div : out STD_LOGIC);
    end component;
    
    component debounce is Port (
        clk  : in  STD_LOGIC;
        btn  : in  STD_LOGIC;
        dbnc : out STD_LOGIC);
    end component;
    
    component spi is Port (
        clk   : in  STD_LOGIC;
        en    : in  STD_LOGIC;
        MISO  : in  STD_LOGIC;
        CS    : out STD_LOGIC;
        SCK   : out STD_LOGIC;
        left  : out STD_LOGIC;
        right : out STD_LOGIC;
        down  : out STD_LOGIC);
    end component;
    
    component tetris_top is Port (
        clk   : in  STD_LOGIC;
        left  : in  STD_LOGIC;
        right : in  STD_LOGIC;
        down  : in  STD_LOGIC;
        B     : in  STD_LOGIC;
        A     : in  STD_LOGIC;
        addr  : in  STD_LOGIC_VECTOR (8 downto 0);
        pixel : out STD_LOGIC_VECTOR (3 downto 0));
    end component;

    component pixel_pusher is Port (
        clk, en, vs, vid : in  STD_LOGIC;
        pixel  : in  STD_LOGIC_VECTOR (3 downto 0);
        hcount : in  STD_LOGIC_VECTOR (9 downto 0);
        R, B   : out STD_LOGIC_VECTOR (4 downto 0);
        G      : out STD_LOGIC_VECTOR (5 downto 0);
        addr   : out STD_LOGIC_VECTOR (8 downto 0));
    end component;
    
    component vga_ctrl is Port (
        clk, en : in STD_LOGIC;
        hcount : buffer STD_LOGIC_VECTOR (9 downto 0) := (others => '0');
        vid, hs, vs : out    STD_LOGIC);
    end component;

begin
    vga_vs <= vs;
    MOSI   <= '0';
    
    uclkwiz : clk_wiz_0 port map ( 
        clk_in1  => clk125,   
        clk_out1 => div);
       
    udiv4: divby4 port map (
        clk => div,
        div => div25);
        
    udiv50: divby50 port map (
        clk => div,
        div => div2);
        
    adbnc: debounce port map (
        clk => div,
        btn => A,
        dbnc => Ai);
        
    bdbnc: debounce port map (
        clk => div,
        btn => B,
        dbnc => Bi);
        
    uspi: spi port map (
        clk   => div,
        en    => div2,
        MISO  => MISO,
        CS    => CS,
        SCK   => SCK,
        left  => lefti,
        right => righti,
        down  => downi
    );
            
    utetris : tetris_top port map (
        clk   => div,
        left  => lefti,
        right => righti,
        down  => downi,
        B     => Bi,
        A     => Ai,
        addr  => addr,
        pixel => pixel);

    upusher: pixel_pusher port map (
        clk    => div,
        en     => div25,
        vs     => vs,
        vid    => vid,
        pixel  => pixel,
        hcount => hcount,
        R      => vga_r,
        G      => vga_g,
        B      => vga_b,
        addr   => addr);
            
    uctrl: vga_ctrl port map (
        clk    => div,
        en     => div25,
        hcount => hcount,
        vid    => vid,
        hs     => vga_hs,
        vs     => vs);

end Behavioral;