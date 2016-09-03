-----------------------------------------------------------------------------
--	Filename:	gh_counter_down_4b_bb.vhd
--
--	Description:
--		Binary/BCD 4 bit down counter
--
--	Copyright (c) 2008 by H LeFevre 
--		an OpenCores.org Project
--		free to use, but see documentation for conditions 
--
--	Revision 	History:
--	Revision 	Date       	Author   	Comment
--	-------- 	---------- 	---------	-----------
--	1.0      	07/07/08  	H LeFevre	Initial revision
--
-----------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.all;

ENTITY gh_counter_down_4b_bb IS
	PORT(
		clk    : IN STD_LOGIC;
		rst    : IN STD_LOGIC;
		LOAD   : IN STD_LOGIC;
		BCD_EN : IN STD_LOGIC;
		CE     : IN STD_LOGIC;
		D      : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		TC     : OUT STD_LOGIC;
		Q      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
		);
END entity;

ARCHITECTURE a OF gh_counter_down_4b_bb IS 

	signal iTC : STD_LOGIC;
	signal iQ  : STD_LOGIC_VECTOR (3 DOWNTO 0);
	signal iD  : STD_LOGIC_VECTOR (3 DOWNTO 0);
	
BEGIN

	TC <= iTC;
	      
	Q <= iQ;

----------------------------------
----------------------------------

PROCESS (CLK,rst)
BEGIN
	if (rst = '1') then 
		iTC <= '0';
	elsif (rising_edge(CLK)) then
		if (LOAD = '1') then
			if (D = x"0") then
				iTC <= '1';
			else
				iTC <= '0';
			end if;
		elsif (CE = '0') then  -- LOAD = '0'
				if (iQ = x"0") then
					iTC <= '1';
				else
					iTC <= '0';
				end if;
		else -- (CE = '1')	
			if (iQ = x"1") then
				iTC <= '1';
			else
				iTC <= '0';
			end if;
		end if;			
	end if;
END PROCESS;

	iD <= D when (BCD_EN = '0') else
	      D when (D < x"A") else
	      x"A";

PROCESS (CLK,rst)
BEGIN
	if (rst = '1') then 
		iQ <= (others => '0');
	elsif (rising_edge(CLK)) then
		if (LOAD = '1') then 
			iQ <= iD;
		elsif (CE = '0') then
			iQ <= iQ;
		elsif ((CE = '1') and (BCD_EN = '1') and (iQ = x"0"))then
			iQ <= x"9";
		else
			iQ <= (iQ - "01");
		end if;			
	end if;
END PROCESS;

END a;
