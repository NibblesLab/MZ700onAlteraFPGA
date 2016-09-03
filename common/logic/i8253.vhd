--
-- i8253.vhd
--
-- Intel 8253 (PIT:Programmable Interval Timer) partiality compatible module
-- for MZ-700 on FPGA
--
-- PIT main module 
--
-- Nibbles Lab. 2005
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity i8253 is
    Port (
		-- System
		RST : in std_logic;
		-- Z80 Bus Signals
		CLK : in std_logic;
		A : in std_logic_vector(1 downto 0);
		DI : in std_logic_vector(7 downto 0);
		DO : out std_logic_vector(7 downto 0);
		CS : in std_logic;
		WR : in std_logic;
		RD : in std_logic;
		-- Counters
		CLK0 : in std_logic;
		GATE0 : in std_logic;
		OUT0 : out std_logic;
		CLK1 : in std_logic;
		GATE1 : in std_logic;
		OUT1 : out std_logic;
		CLK2 : in std_logic;
		GATE2 : in std_logic;
		OUT2 : out std_logic
	);
end i8253;

architecture Behavioral of i8253 is

signal STB_i : std_logic;
signal REG : std_logic_vector(1 downto 0);

component gh_timer_8254_wb
	GENERIC(mux0_same_clk: boolean := false; -- true, if same clock is used for bus and counter
	        mux1_same_clk: boolean := false; 
	        mux2_same_clk: boolean := false;
	        mux0_sync_clk: boolean := false; -- true, if bus and counter clocks are synchronous
	        mux1_sync_clk: boolean := false;
	        mux2_sync_clk: boolean := false);
	port(	  
	-------- wishbone signals ------------
		wb_clk_i  : in std_logic;
		wb_rst_i  : in std_logic;
		wb_stb_i  : in std_logic;
		wb_cyc_i  : in std_logic;
		wb_we_i   : in std_logic;
		wb_adr_i  : in std_logic_vector(1 downto 0);
		wb_dat_i  : in std_logic_vector(7 downto 0);
		
		wb_ack_o  : out std_logic;
		wb_dat_o  : out std_logic_vector(7 downto 0);
	----------------------------------------------------
	------ other I/O -----------------------------------	
		
		clk0    : in std_logic;
		gate0   : in std_logic;
		out0    : out std_logic;
		
		clk1    : in std_logic;
		gate1   : in std_logic;
		out1    : out std_logic;
		
		clk2    : in std_logic;
		gate2   : in std_logic;
		out2    : out std_logic
		);
end component;

begin

	process( RST, CLK ) begin
		if RST='0' then
			STB_i<='0';
			REG<="11";
		elsif CLK'event and CLK='0' then
			REG<=REG(0)&cS;
			if REG="11" and CS='0' then
				STB_i<='1';
			else
				STB_i<='0';
			end if;
		end if;
	end process;

	PIT8254 : gh_timer_8254_wb GENERIC map (
		mux0_same_clk => false, -- true, if same clock is used for bus and counter
	   mux1_same_clk => false,
		mux2_same_clk => false,
		mux0_sync_clk => false, -- true, if bus and counter clocks are synchronous
		mux1_sync_clk => false,
		mux2_sync_clk => false
	)
	port map (	  
	-------- wishbone signals ------------
		wb_clk_i => CLK,
		wb_rst_i => not RST,
		wb_stb_i => STB_i,
		wb_cyc_i => not CS,
		wb_we_i => not WR,
		wb_adr_i => A,
		wb_dat_i => DI,
		
		wb_ack_o => open,
		wb_dat_o => DO,
	----------------------------------------------------
	------ other I/O -----------------------------------	
		
		clk0 => CLK0,
		gate0 => GATE0,
		out0 => OUT0,
		
		clk1 => CLK1,
		gate1 => GATE1,
		out1 => OUT1,
		
		clk2 => CLK2,
		gate2 => GATE2,
		out2 => OUT2
	);

end Behavioral;
