-----------------------------------------------------------------------------
--	Filename:	gh_div_bcd2.vhd
--
--	Description:
--		BCD divide by 2 for gh_timer_8254
--
--	Copyright (c) 2008 by H LeFevre 
--		an OpenCores.org Project
--		free to use, but see documentation for conditions 
--
--	Revision 	History:
--	Revision 	Date       	Author   	Comment
--	-------- 	---------- 	---------	-----------
--	1.0      	07/21/08  	H LeFevre	Initial revision
--	1.1      	08/09/08  	H LeFevre	correct typo in notes
--
-----------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.all;

ENTITY gh_div_bcd2 IS
	PORT(
		CDi    : IN STD_LOGIC; -- carry down input
		iBCD   : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		oBCD   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		CDo    : OUT STD_LOGIC -- carry down out
		);
END entity;

ARCHITECTURE a OF gh_div_bcd2 IS 

	signal cBCD     : STD_LOGIC_VECTOR (4 downto 0);

BEGIN
 
	cBCD <= CDi & iBCD;
	
process(CDi,cBCD)
begin
case cBCD is
	when "00000" => -- 
		oBCD <= x"0";
		CDo <= '0';
	when "00001" => 
		oBCD <= x"0";
		CDo <= '1';
	when "00010" => 
		oBCD <= x"1";
		CDo <= '0';
	when "00011" => 
		oBCD <= x"1";
		CDo <= '1';
	when "00100" => 
		oBCD <= x"2";
		CDo <= '0';
	when "00101" => 
		oBCD <= x"2";
		CDo <= '1';
	when "00110" => 
		oBCD <= x"3";
		CDo <= '0';
	when "00111" => 
		oBCD <= x"3";
		CDo <= '1';
	when "01000" => 
		oBCD <= x"4";
		CDo <= '0';
	when "01001" => 
		oBCD <= x"4";
		CDo <= '1';
 --
	when "10000" => -- 
		oBCD <= x"5";
		CDo <= '0';
	when "10001" => 
		oBCD <= x"5";
		CDo <= '1';
	when "10010" => 
		oBCD <= x"6";
		CDo <= '0';
	when "10011" => 
		oBCD <= x"6";
		CDo <= '1';
	when "10100" => 
		oBCD <= x"7";
		CDo <= '0';
	when "10101" => 
		oBCD <= x"7";
		CDo <= '1';
	when "10110" => 
		oBCD <= x"8";
		CDo <= '0';
	when "10111" => 
		oBCD <= x"8";
		CDo <= '1';
	when "11000" => 
		oBCD <= x"9";
		CDo <= '0';
	when "11001" => 
		oBCD <= x"9";
		CDo <= '1';
	when others => -- non BCD inputs
		oBCD <= x"0";
		CDo <= '0';
end case;
end process;

END a;
