-----------------------------------------------------------------------------
--	Filename:	gh_div2_bcd_4digits.vhd
--
--	Description:
--		4 digit BCD div by 2 for gh_timer_8254
--
--	Copyright (c) 2008 by H LeFevre 
--		an OpenCores.org Project
--		free to use, but see documentation for conditions 
--
--	Revision 	History:
--	Revision 	Date       	Author   	Comment
--	-------- 	---------- 	---------	-----------
--	1.0      	07/21/08  	H LeFevre	Initial revision
--
-----------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;


entity gh_div2_bcd_4digits is
	port(
		BCD_IN  : in STD_LOGIC_VECTOR(15 downto 0);
		BCD_OUT : out STD_LOGIC_VECTOR(15 downto 0)
		);
end entity;

architecture a of gh_div2_bcd_4digits is


component gh_div_bcd2 IS
	PORT(
		CDi    : IN STD_LOGIC; -- cary down input
		iBCD   : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		oBCD   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		CDo    : OUT STD_LOGIC -- cary down out
		);
end component;

	signal CD  : STD_LOGIC_VECTOR (2 downto 0);


begin

U0 : gh_div_bcd2 
	PORT MAP (
		CDi => '0',
		iBCD => BCD_IN(15 downto 12),
		oBCD => BCD_OUT(15 downto 12),
		CDo => CD(2));

U1 : gh_div_bcd2 
	PORT MAP (
		CDi => CD(2),
		iBCD => BCD_IN(11 downto 8),
		oBCD => BCD_OUT(11 downto 8),
		CDo => CD(1));

U2 : gh_div_bcd2 
	PORT MAP (
		CDi => CD(1),
		iBCD => BCD_IN(7 downto 4),
		oBCD => BCD_OUT(7 downto 4),
		CDo => CD(0));

U3 : gh_div_bcd2 
	PORT MAP (
		CDi => CD(0),
		iBCD => BCD_IN(3 downto 0),
		oBCD => BCD_OUT(3 downto 0),
		CDo => open);
		
end architecture;
