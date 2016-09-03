-----------------------------------------------------------------------------
--	Filename:	gh_counter_down_16b_bb.vhd
--
--	Description:
--		Binary/BCD 16 bit down counter
--
--	Copyright (c) 2008 by H LeFevre 
--		an OpenCores.org Project
--		free to use, but see documentation for conditions 
--
--	Revision 	History:
--	Revision 	Date       	Author   	Comment
--	-------- 	---------- 	---------	-----------
--	1.0      	08/02/08  	H LeFevre	Initial revision
--
-----------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;


entity gh_counter_down_16b_bb is
	port(
		clk     : in STD_LOGIC;
		rst     : in STD_LOGIC;
		BCD_EN  : in STD_LOGIC;
		CE      : in STD_LOGIC;
		LD      : in STD_LOGIC;
		M_CMD   : in STD_LOGIC;
		MODE    : in STD_LOGIC_VECTOR(2 downto 0);
		DI      : in STD_LOGIC_VECTOR(15 downto 0);
		Cout    : out std_logic;
		NULL_C  : out std_logic;
		DO      : out STD_LOGIC_VECTOR(15 downto 0)
		);
end entity;

architecture a of gh_counter_down_16b_bb is


component gh_counter_down_4b_bb
	port (
		clk    : in STD_LOGIC;
		rst    : in STD_LOGIC;
		BCD_EN : in STD_LOGIC;
		CE     : in STD_LOGIC;
		D      : in STD_LOGIC_VECTOR(3 downto 0);
		LOAD   : in STD_LOGIC;
		Q      : out STD_LOGIC_VECTOR(3 downto 0);
		TC     : out STD_LOGIC
		);
end component;

COMPONENT gh_edge_det is
	PORT(	
		clk : in STD_LOGIC;
		rst : in STD_LOGIC;
		D   : in STD_LOGIC;
		re  : out STD_LOGIC; -- rising edge (need sync source at D)
		fe  : out STD_LOGIC; -- falling edge (need sync source at D)
		sre : out STD_LOGIC; -- sync'd rising edge
		sfe : out STD_LOGIC  -- sync'd falling edge
		);
END COMPONENT;

COMPONENT gh_jkff is
	PORT(	
		clk  : IN STD_logic;
		rst  : IN STD_logic;
		J,K  : IN STD_logic;
		Q    : OUT STD_LOGIC
		);
END COMPONENT;


COMPONENT gh_div2_bcd_4digits is
	port(
		BCD_IN  : in STD_LOGIC_VECTOR(15 downto 0);
		BCD_OUT : out STD_LOGIC_VECTOR(15 downto 0)
		);
END COMPONENT;

	signal LOAD    : STD_LOGIC;
	signal iLOAD   : STD_LOGIC;
	signal dLOAD   : STD_LOGIC;
	signal dC1     : STD_LOGIC;
	signal edge    : STD_LOGIC;
	signal iCE     : STD_LOGIC_VECTOR (3 downto 0);
	signal pTC     : STD_LOGIC_VECTOR (2 downto 0);
	signal iDI     : STD_LOGIC_VECTOR (15 downto 0);
	signal iDO     : STD_LOGIC_VECTOR (15 downto 0);
	signal hDI     : STD_LOGIC_VECTOR (15 downto 0);
	signal BCD_d2  : STD_LOGIC_VECTOR (15 downto 0);
	signal nNULL   : STD_LOGIC;
	signal cNULL   : STD_LOGIC;
	signal MODE1o  : STD_LOGIC;
	signal MODE1ce : STD_LOGIC;
	signal sMD1o   : STD_LOGIC;

begin
	
	DO <= iDO;

	hDI <= ('0' & DI(15 downto 1)) when (BCD_EN = '0') else
	       BCD_d2;

	iDI <= x"0000" when (M_CMD = '1') else
	       DI;

U0 : gh_div2_bcd_4digits 
	PORT MAP (
		BCD_IN => DI,
		BCD_OUT => BCD_d2);
		   
process(MODE,hDI,iDO,LD,CE,dC1,edge,MODE1o,MODE1ce)
begin
case MODE is
	when "000" => -- mode zero
		iLOAD <= LD;
		if (iDO = x"0001") then
			Cout <= '1';
		else
	        Cout <= '0';
		end if;
		iCE(0) <= CE; 
	when "001" =>
		iLOAD <= edge;
		Cout <= MODE1o;
		iCE(0) <= MODE1ce;
	when "010" =>
		iCE(0) <= CE;
		if (iDO = x"0001") then
			iLOAD <= '1'; 			
			Cout <= '0';			
		elsif (iDO = x"0000") then
			iLOAD <= LD;
			Cout <= '1';
		else
			iLOAD <= edge;
	        Cout <= '1';
		end if;
	when "011" =>
		iCE(0) <= CE;
		if (iDO > hDI) then
			Cout <= '1';
		else
	        Cout <= '0';
		end if;
		if (iDO = x"0001") then
			iLOAD <= '1'; 
		elsif (iDO = x"0000") then
			iLOAD <= LD;
		else
			iLOAD <= edge;
		end if;
	when "100" =>
		iCE(0) <= CE;
		if (dC1 = '1') then
			iLOAD <= '0';
			Cout <= '0';
		else
			iLOAD <= LD;
	        Cout <= '1';
		end if;	
	when "101" => 
		iLOAD <= edge;
		iCE(0) <= '1';
		if (dC1 = '1') then
			Cout <= '0';
		else
	        Cout <= '1';
		end if;	
	when others =>
		iLOAD <= '0';
		Cout <= '0';
		iCE(0) <= '0';
end case;
end process;

PROCESS (CLK,rst)
BEGIN
	if (rst = '1') then 
		dC1 <= '0';
	elsif (rising_edge(CLK)) then
		if (iDO = x"0001") then 
			dC1 <= '1';
		else
			dC1 <= '0';
		end if;			
	end if;
END PROCESS;

U1 : gh_edge_det 
	PORT MAP (
		clk => clk,
		rst => rst,
		d => CE,
		re => edge);

U2 : gh_jkff 
	PORT MAP (
		clk => clk,
		rst => rst,
		j => edge,
		k => M_CMD,
		Q => MODE1ce);
		
	LOAD <= iLOAD or M_CMD or dLOAD;

PROCESS (CLK,rst)
BEGIN
	if (rst = '1') then 
		dLOAD <= '0';
	elsif (rising_edge(CLK)) then
		dLOAD <= iLOAD and M_CMD;		
	end if;
END PROCESS;
	
	iCE(3) <= pTC(2) and iCE(2) and iCE(1) and iCE(0);

	sMD1o <= dC1 or M_CMD;
	
U3 : gh_jkff 
	PORT MAP (
		clk => clk,
		rst => rst,
		j => sMD1o,
		k => iLOAD,
		Q => MODE1o);
	
U4 : gh_counter_down_4b_bb
	port map(
		clk => clk,
		rst => rst,
		BCD_EN => BCD_EN,
		CE => iCE(3),
		LOAD => LOAD,
		D => iDI(15 downto 12),
		TC => open,
		Q => iDO(15 downto 12)
		);
	
	iCE(2) <= pTC(1) and iCE(1) and iCE(0);
		
U5 : gh_counter_down_4b_bb
	port map(
		clk => clk,
		rst => rst,
		BCD_EN => BCD_EN,
		CE => iCE(2),
		LOAD => LOAD,
		D => iDI(11 downto 8),
		TC => pTC(2),
		Q => iDO(11 downto 8)
		);
 
	iCE(1) <= pTC(0) and iCE(0); 
		
U6 : gh_counter_down_4b_bb
	port map(
		clk => clk,
		rst => rst,
		BCD_EN => BCD_EN,
		CE => iCE(1),
		LOAD => LOAD,
		D => iDI(7 downto 4),
		TC => pTC(1),
		Q => iDO(7 downto 4)
		);

U7 : gh_counter_down_4b_bb
	port map(
		clk => clk,
		rst => rst,
		BCD_EN => BCD_EN,
		CE => iCE(0),
		LOAD => LOAD,
		D => iDI(3 downto 0),
		TC => pTC(0),
		Q => iDO(3 downto 0)
		);

	cNULL <= (iLOAD and (not M_CMD)) or dLOAD;
		
U8 : gh_jkff 
	PORT MAP (
		clk => clk,
		rst => rst,
		j => cNULL,
		k => M_CMD,
		Q => nNULL);
		
	NULL_C <= not nNULL;
		
end architecture;
