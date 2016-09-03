-----------------------------------------------------------------------------
--	Filename:	gh_edge_det_XCD_t.vhd
--
--	Description:
--		an edge detector, for crossing clock domains - 
--		   includes muxs, one to bypass if using same clock for both in and out,
--		   the other to bypass a register if two clocks are synchronous
--		   for use with the gh_timer_8254.vhd module
--
--	Copyright (c) 2008 by Howard LeFevre
--		an OpenCores.org Project
--		free to use, but see documentation for conditions  
--
--	Revision 	History:
--	Revision 	Date       	Author    	Comment
--	-------- 	----------	--------	-----------
--	1.0        	07/30/08  	hlefevre 	Initial revision   
--
-----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity gh_edge_det_XCD_t is
	GENERIC(same_clk: boolean := false;	-- true, if same clock is used for i/o clocks
	        sync_clk: boolean := false); -- true, if i/o clocks are synchronous
	port(
		iclk : in STD_LOGIC;  -- clock for input data signal
		oclk : in STD_LOGIC;  -- clock for output data pulse
		rst  : in STD_LOGIC;
		D    : in STD_LOGIC;
		re   : out STD_LOGIC  -- rising edge 
		);
end entity;

architecture a of gh_edge_det_XCD_t is

COMPONENT gh_jkff is
	PORT(	
		clk  : IN STD_logic;
		rst  : IN STD_logic;
		J,K  : IN STD_logic;
		Q    : OUT STD_LOGIC
		);
END COMPONENT;

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

	signal iQ, niQ, diq, idiq  : std_logic;
	signal iiQ, aiiQ, hQ, iD : std_logic;

begin

	re <= aiiQ when (same_clk = true) else
	      aiiQ when (sync_clk = true) else
	      iiQ;

U0 : gh_edge_det 
	PORT MAP (
		clk => iclk,
		rst => rst,
		d => D,
		re => iD);
		  
U1 : gh_jkff 
	PORT MAP (
		clk => iclk,
		rst => rst,
		j => iD,
		k => hQ,
		Q => iQ);

U2 : gh_jkff 
	PORT MAP (
		clk => oclk,
		rst => rst,
		j => iQ,
		k => niQ,
		Q => diq);
		
	idiq <= D when (same_clk = true) else
	        iQ when (sync_clk = true) else
	        diq;
		
U3 : gh_edge_det 
	PORT MAP (
		clk => oclk,
		rst => rst,
		d => idiQ,
		re => aiiQ,
		sre => iiQ);

U4 : gh_jkff 
	PORT MAP (
		clk => oclk,
		rst => rst,
		j => iiQ,
		k => niQ,
		Q => hQ);
		
	niQ <= (not iQ);


end a;
