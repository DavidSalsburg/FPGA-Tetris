library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; -- cuts down on type conversions

entity piece is Port (
    clk    : in  STD_LOGIC;
    spawn  : in  STD_LOGIC;
    left   : in  STD_LOGIC;
    right  : in  STD_LOGIC;
    down   : in  STD_LOGIC;
    B      : in  STD_LOGIC;
    A      : in  STD_LOGIC;
    piece  : in  STD_LOGIC_VECTOR (2 downto 0); -- O=0 I=1 T=2 J=3 L=4 S=5 Z=6
    rpixel : in  STD_LOGIC_VECTOR (3 downto 0);
    raddr  : out STD_LOGIC_VECTOR (8 downto 0);
    wen    : out STD_LOGIC;
    wpixel : out STD_LOGIC_VECTOR (3 downto 0) := "1111";
    waddr  : out STD_LOGIC_VECTOR (8 downto 0) := "000000000";
    lock   : out STD_LOGIC);
end piece;

architecture Behavioral of piece is
    signal loc    : STD_LOGIC_VECTOR (8 downto 0) := "000010001"; -- 17 = spawn location
    signal rot    : integer := 0;
    signal piecei : integer := 0;
    signal count  : integer := 2;
    signal lefti, righti, downi, Bi, Ai, inval : STD_LOGIC := '0';
    type statetype is (spawns, lefts, rights, downs, Bs, As, idles, locks);
    signal state : statetype := locks;
    type coltype is array (0 to 7) of STD_LOGIC_VECTOR (3 downto 0);
    constant color : coltype := (
        "1110", "0111", "1001", "0001", "1100", "0110", "1000", "0000");
    type piecerot is array (0 to 3) of STD_LOGIC_VECTOR (8 downto 0);
    type subrot   is array (0 to 3) of piecerot;
    type rottype  is array (0 to 6) of subrot;
    constant rota : rottype := ( -- three-dimensional piece rotation reference array
        0 => (others =>                                                 -- O does not rotate
                 ("000000000", "000000001", "000001100", "000001101")), -- O0: 0,  1,  12,  13
        1 => (
            0 => ("000000000", "000000001", "000000010", "111111111"),  -- I0: 0,  1,   2,  -1
            1 => ("000000000", "000001100", "000011000", "111110100"),  -- I1: 0, 12,  24, -12
        	2 => ("000000000", "111111111", "111111110", "000000001"),  -- I2: negative I0
        	3 => ("000000000", "111110100", "111101000", "000001100")), -- I3: negative I1
        2 => (
            0 => ("000000000", "000000001", "000001100", "111111111"),  -- T0: 0,  1,  12,  -1
            1 => ("000000000", "000001100", "111111111", "111110100"),  -- T1: 0, 12,  -1, -12
        	2 => ("000000000", "111111111", "111110100", "000000001"),
        	3 => ("000000000", "111110100", "000000001", "000001100")),
        3 => (
            0 => ("000000000", "000000001", "000001101", "111111111"),  -- J0: 0,  1,  13,  -1
            1 => ("000000000", "000001011", "000001100", "111110100"),  -- J1: 0, 11,  12, -12
        	2 => ("000000000", "111111111", "111110011", "000000001"),
        	3 => ("000000000", "111110101", "111110100", "000001100")),
        4 => (
            0 => ("000000000", "000000001", "000001011", "111111111"),  -- L0: 0,  1,  11,  -1
            1 => ("000000000", "000001100", "111110100", "111110011"),  -- L1: 0, 12, -12, -13
        	2 => ("000000000", "111111111", "111110101", "000000001"),
        	3 => ("000000000", "111110100", "000001100", "000001101")),
        5 => (
            0 => ("000000000", "000000001", "000001011", "000001100"),  -- S0: 0,  1,  11,  12
            1 => ("000000000", "000001100", "111111111", "111110011"),  -- S1: 0, 12,  -1, -13
        	2 => ("000000000", "111111111", "111110101", "111110100"),
        	3 => ("000000000", "111110100", "000000001", "000001101")),
        6 => (
            0 => ("000000000", "000001100", "000001101", "111111111"),  -- Z0: 0, 12,  13,  -1
            1 => ("000000000", "000001011", "111111111", "111110100"),  -- Z1: 0, 11,  -1, -12
            2 => ("000000000", "111110100", "111110011", "000000001"),
            3 => ("000000000", "111110101", "000000001", "000001100")));

begin
    piecei <= to_integer(unsigned(piece));

process (clk) begin
if rising_edge(clk) then
    if down = '1' then -- down inputs cannot be overwritten
        downi <= '1';
    end if;
    
    if left = '1' or right = '1' or B = '1' or A = '1' then
        lefti  <= '0'; -- save inputs for later,
        righti <= '0'; -- in case component is busy
        Bi     <= '0'; -- (only newest left/right/B/A matters)
        Ai     <= '0';
        if left = '1' then
            lefti <= '1';
        elsif right = '1' then
            righti <= '1';
        elsif A = '1' then
            Ai <= '1';
        elsif B = '1' then
            Bi <= '1';
        end if;
    end if;
        
    case (state) is
        when spawns => -- spawn in a piece, end game if the spawn is invalid
            if count < 5 then
		        count <= count + 1;

	        	if count < 4 then -- check spawn location for validity
                	raddr <= loc + rota(piecei)(rot)(count);
            	end if;
                
                if count > 0 then
                    if rpixel /= "0000" then inval <= '1';
                    end if;
                    
                    wen    <= '1'; -- spawn in four blocks sequentially
                    waddr  <= loc + rota(piecei)(rot)(count-1);
                    wpixel <= color(piecei);
                end if;
            else
                count <= 0;
                wen   <= '0';
                if inval = '1' then
                    state <= locks;
                else
                    state <= idles;
                end if;
            end if;
        when lefts => -- attempt to move piece to location - 1
        	if inval = '1' then
        		inval <= '0';
        		count <= 0;
        		state <= idles;
    		else
    			count <= count + 1;

	        	if count < 5 then
	        		if count < 4 then -- validity check
						raddr <= loc - 1 + rota(piecei)(rot)(count);
					end if;

	            	if count > 0 then
	            		if rpixel = "1111" or (rpixel /= "0000" and
	            			loc - 1 + rota(piecei)(rot)(count-1) /= loc + rota(piecei)(rot)(0) and
	            			loc - 1 + rota(piecei)(rot)(count-1) /= loc + rota(piecei)(rot)(1) and
	            			loc - 1 + rota(piecei)(rot)(count-1) /= loc + rota(piecei)(rot)(2) and
	            			loc - 1 + rota(piecei)(rot)(count-1) /= loc + rota(piecei)(rot)(3))
	            		then inval <= '1';
            			end if;
	    			end if;
	    		elsif count > 4 and count < 9 then -- erase piece
	    			wen <= '1';
	    			waddr <= loc + rota(piecei)(rot)(count-5);
                    wpixel <= "0000";
                elsif count > 8 and count < 13 then -- generate piece in new spot
                    wen <= '1';
                	waddr <= loc - 1 + rota(piecei)(rot)(count-9);
                    wpixel <= color(piecei);
                else
                	count <= 0;
                	wen   <= '0';
                	loc   <= loc - 1;
                	state <= idles;
            	end if;
            end if;
        when rights => -- attempt to move to location + 1
        	if inval = '1' then
        		inval <= '0';
        		count <= 0;
        		state <= idles;
    		else
    			count <= count + 1;

	        	if count < 5 then
	        		if count < 4 then
						raddr <= loc + 1 + rota(piecei)(rot)(count);
					end if;

	            	if count > 0 then
	            		if rpixel = "1111" or (rpixel /= "0000" and
	            			loc + 1 + rota(piecei)(rot)(count-1) /= loc + rota(piecei)(rot)(0) and
	            			loc + 1 + rota(piecei)(rot)(count-1) /= loc + rota(piecei)(rot)(1) and
	            			loc + 1 + rota(piecei)(rot)(count-1) /= loc + rota(piecei)(rot)(2) and
	            			loc + 1 + rota(piecei)(rot)(count-1) /= loc + rota(piecei)(rot)(3))
	            		then inval <= '1';
            			end if;
	    			end if;
	    		elsif count > 4 and count < 9 then
                    wen    <= '1';
	    			waddr  <= loc + rota(piecei)(rot)(count-5);
                    wpixel <= "0000";
                elsif count > 8 and count < 13 then
                    wen    <= '1';
                	waddr  <= loc + 1 + rota(piecei)(rot)(count-9);
                    wpixel <= color(piecei);
                else
                	count <= 0;
                	wen   <= '0';
                	loc   <= loc + 1;
                	state <= idles;
            	end if;
            end if;
        when downs => -- attempt to move to location + 12
        	if inval = '1' then -- (row including borders contains 12 blocks)
        		inval <= '0';
        		count <= 0;
        		state <= locks; -- if unable to go down, lock
    		else
    			count <= count + 1;

	        	if count < 5 then
        			if count < 4 then
						raddr <= loc + 12 + rota(piecei)(rot)(count);
					end if;

	            	if count > 0 then
	            		if rpixel = "1111" or (rpixel /= "0000" and
	            			loc + 12 + rota(piecei)(rot)(count-1) /= loc + rota(piecei)(rot)(0) and
	            			loc + 12 + rota(piecei)(rot)(count-1) /= loc + rota(piecei)(rot)(1) and
	            			loc + 12 + rota(piecei)(rot)(count-1) /= loc + rota(piecei)(rot)(2) and
	            			loc + 12 + rota(piecei)(rot)(count-1) /= loc + rota(piecei)(rot)(3))
	            		then inval <= '1';
            			end if;
	    			end if;
	    		elsif count > 4 and count < 9 then
	    		    wen    <= '1';
	    			waddr  <= loc + rota(piecei)(rot)(count-5);
                    wpixel <= "0000";
                elsif count > 8 and count < 13 then
                    wen    <= '1';
                	waddr <= loc + 12 + rota(piecei)(rot)(count-9);
                    wpixel <= color(piecei);
                else
                	count <= 0;
                	wen   <= '0';
                	loc   <= loc + 12;
                	state <= idles;
            	end if;
            end if;
        when Bs => -- attempt to change piece to rotation - 1
        	if inval = '1' then
        		inval <= '0';
        		count <= 0;
        		state <= idles;
    		else
    			count <= count + 1;

	        	if count < 5 then
	        		if count < 4 then
						raddr <= loc + rota(piecei)(to_integer(to_unsigned(rot,2)-1))(count);
					end if;

	            	if count > 0 then
	            		if rpixel = "1111" or (rpixel /= "0000" and
	            			loc + rota(piecei)(to_integer(to_unsigned(rot,2)-1))(count-1)
	            				/= loc + rota(piecei)(rot)(0) and
	            			loc + rota(piecei)(to_integer(to_unsigned(rot,2)-1))(count-1)
	            				/= loc + rota(piecei)(rot)(1) and
	            			loc + rota(piecei)(to_integer(to_unsigned(rot,2)-1))(count-1)
	            				/= loc + rota(piecei)(rot)(2) and
	            			loc + rota(piecei)(to_integer(to_unsigned(rot,2)-1))(count-1)
	            				/= loc + rota(piecei)(rot)(3))
	            		then inval <= '1';
            			end if;
	    			end if;
	    		elsif count > 4 and count < 9 then
	    			wen    <= '1';
	    			waddr  <= loc + rota(piecei)(rot)(count-5);
                    wpixel <= "0000";
                elsif count > 8 and count < 13 then
                	wen    <= '1';
                	waddr  <= loc + rota(piecei)(to_integer(to_unsigned(rot,2)-1))(count-9);
                    wpixel <= color(piecei);
                else
                	count <= 0;
                	wen   <= '0';
                	rot   <= to_integer(to_unsigned(rot,2) - 1);
                	state <= idles;
            	end if;
            end if;
        when As => -- attempt to change to rotation + 1
        	if inval = '1' then
        		inval <= '0';
        		count <= 0;
        		state <= idles;
    		else
    			count <= count + 1;

	        	if count < 5 then
	        		if count < 4 then
						raddr <= loc + rota(piecei)(to_integer(to_unsigned(rot,2)+1))(count);
					end if;

	            	if count > 0 then
	            		if rpixel = "1111" or (rpixel /= "0000" and
	            			loc + rota(piecei)(to_integer(to_unsigned(rot,2)+1))(count-1)
	            				/= loc + rota(piecei)(rot)(0) and
	            			loc + rota(piecei)(to_integer(to_unsigned(rot,2)+1))(count-1)
	            				/= loc + rota(piecei)(rot)(1) and
	            			loc + rota(piecei)(to_integer(to_unsigned(rot,2)+1))(count-1)
	            				/= loc + rota(piecei)(rot)(2) and
	            			loc + rota(piecei)(to_integer(to_unsigned(rot,2)+1))(count-1)
	            				/= loc + rota(piecei)(rot)(3))
	            		then inval <= '1';
            			end if;
	    			end if;
	    		elsif count > 4 and count < 9 then
	    			wen    <= '1';
	    			waddr  <= loc + rota(piecei)(rot)(count-5);
                    wpixel <= "0000";
                elsif count > 8 and count < 13 then
                	wen    <= '1';
                	waddr  <= loc + rota(piecei)(to_integer(to_unsigned(rot,2)+1))(count-9);
                    wpixel <= color(piecei);
                else
                	count <= 0;
                	wen   <= '0';
                	rot   <= to_integer(to_unsigned(rot,2) + 1);
                	state <= idles;
            	end if;
            end if;
        when idles =>
            if downi = '1' then -- down must be first
            	state <= downs; -- otherwise ignoring gravity is possible
            	downi <= '0';
            elsif lefti = '1' then
            	state <= lefts;
            	lefti <= '0';
            elsif righti = '1' then
            	state  <=  rights;
            	righti <= '0';
        	elsif Ai = '1' then
        		state <= As;
        		Ai    <= '0';
    		elsif Bi = '1' then
    			state <= Bs;
    			Bi    <= '0';
    		end if;
        when locks =>
            raddr  <= (others => '0');
        	waddr  <= (others => '0');
        	wpixel <= (others => '0');
        	wen    <= '0';
        	
            if inval = '0' and count = 0 then
                lock <= '1'; -- game will halt here if inval = 1
                count <= 1;  -- inval = 1 when exiting spawns indicates game over
            else
                lock <= '0';
            end if;
            if spawn = '1' then -- leave lock when told to spawn
                state <= spawns;
                loc <= "000010001"; -- 17 = spawn location
                rot <= 0;
            	count <= 0;
                if count = 2 then -- special initial condition
                	lefti  <= '0';
                	righti <= '0';
                	downi  <= '0';
                	Bi     <= '0';
                	Ai     <= '0';
                end if;
            end if;
    end case;
end if;
end process;
end Behavioral;

--A piece knows what cells it occupies by checking its piece ID and rotation ID against the rotation table.
--Each entry in the table contains three constants which are each individually added to the piece's coordinate
--    to indicate the location of the other three blocks which make up the piece. 
--When a piece receives any input (left/right/down/A/B), it runs through the following.
--Delete itself from the field.
--Attempt the requested movement/rotation.
--If all cells of the piece's new location are empty, write the piece into the new location.
--Otherwise, undo the requested movement/rotation and write the piece back into its original location.
--If the requested movement was a downward movement which failed, send a lock pulse and go idle.
--When a spawn pulse is received, exit idle state and write a new piece to the top of the field.