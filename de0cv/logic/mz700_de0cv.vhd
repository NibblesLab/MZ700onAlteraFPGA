--
-- mz700.vhd
--
-- SHARP MZ-700/1500 compatible logic, main module
-- for MZ-700 on FPGA (DE0-CV version)
--
-- Nibbles Lab. 2007-2016
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity mz700 is
	port(
		------------ CLOCK ----------
		CLOCK_50   : in std_logic;
		CLOCK2_50  : in std_logic;
		CLOCK3_50  : in std_logic;
		CLOCK4_50  : in std_logic;

		------------ SDRAM ------------
		DRAM_ADDR  : out std_logic_vector(12 downto 0);
		DRAM_BA    : out std_logic_vector(1 downto 0);
		DRAM_CAS_N : out std_logic;
		DRAM_CKE   : out std_logic;
		DRAM_CLK   : out std_logic;
		DRAM_CS_N  : out std_logic;
		DRAM_DQ    : inout std_logic_vector(15 downto 0);
		DRAM_LDQM  : out std_logic;
		DRAM_RAS_N : out std_logic;
		DRAM_UDQM  : out std_logic;
		DRAM_WE_N  : out std_logic;

		------------ SEG7 ------------
		HEX0       : out std_logic_vector(6 downto 0);
		HEX1       : out std_logic_vector(6 downto 0);
		HEX2       : out std_logic_vector(6 downto 0);
		HEX3       : out std_logic_vector(6 downto 0);
		HEX4       : out std_logic_vector(6 downto 0);
		HEX5       : out std_logic_vector(6 downto 0);

		------------ KEY ------------
		KEY        : in std_logic_vector(3 downto 0);
		RESET_N    : in std_logic;

		------------ LED ------------
		LEDR       : out std_logic_vector(9 downto 0);

		------------ PS2 ------------
		PS2_CLK    : inout std_logic;
		PS2_CLK2   : inout std_logic;
		PS2_DAT    : inout std_logic;
		PS2_DAT2   : inout std_logic;

		------------ microSD Card ------------
		SD_CLK     : out std_logic;
		SD_CMD     : inout std_logic;
		SD_DATA    : inout std_logic_vector(3 downto 0);

		------------ SW ------------
		SW         : in std_logic_vector(9 downto 0);

		------------ VGA ------------
		VGA_B      : out std_logic_vector(3 downto 0);
		VGA_G      : out std_logic_vector(3 downto 0);
		VGA_HS     : out std_logic;
		VGA_R      : out std_logic_vector(3 downto 0);
		VGA_VS     : out std_logic;

		------------ GPIO_0, GPIO_0 connect to GPIO Default ------------
		GPIO_0     : inout std_logic_vector(35 downto 0);

		------------ GPIO_1, GPIO_1 connect to GPIO Default ------------
		GPIO_1     : inout std_logic_vector(35 downto 0)
	);
end mz700;

architecture rtl of mz700 is

--
-- Reset
--
signal RCOUNT : std_logic_vector(10 downto 0);
signal URST : std_logic;
--
-- Clock
--
signal CLK100  : std_logic;
signal CLK40   : std_logic;
signal PCLK   : std_logic;
--
-- SD/MMC card
--
signal MC_CLK : std_logic;
signal MC_DATi : std_logic_vector(3 downto 0);
signal MC_DATo : std_logic_vector(3 downto 0);
signal MC_DDIR : std_logic;
signal MC_CMD  : std_logic;
signal MC_CDIR : std_logic;
--signal MC_INUSE : std_logic;
--
-- Debug
--
signal TCLK : std_logic;

--
-- Components
--
component pll40
	port (
		refclk   : in  std_logic := 'X'; -- clk
		rst      : in  std_logic := 'X'; -- reset
		outclk_0 : out std_logic;        -- clk
		outclk_1 : out std_logic;        -- clk
		outclk_2 : out std_logic         -- clk
	);
end component;

component mz700_sopc
	port (
		pclk_clk        : in  std_logic                    := 'X';             -- clk
		pio_0_export    : out std_logic_vector(7 downto 0);                    -- export
		reset_reset_n   : in  std_logic                    := 'X';             -- reset_n
		sdif_0_sd_cdir  : out std_logic;                                       -- sd_cdir
		sdif_0_ck40m    : in  std_logic                    := 'X';             -- ck40m
		sdif_0_sd_clk   : out std_logic;                                       -- sd_clk
		sdif_0_sd_cmd   : out std_logic;                                       -- sd_cmd
		sdif_0_sd_dati  : in  std_logic_vector(3 downto 0) := (others => 'X'); -- sd_dati
		sdif_0_sd_dato  : out std_logic_vector(3 downto 0);                    -- sd_dato
		sdif_0_sd_ddir  : out std_logic;                                       -- sd_ddir
		sdif_0_sd_inuse : out std_logic;                                       -- sd_inuse
		sdif_0_sd_resp  : in  std_logic                    := 'X'              -- sd_resp
	);
end component;


begin

	--
	-- Instantiation
	--
	PLL0 : pll40 port map (
		refclk   => CLOCK_50,	-- clk
		rst      => not URST,	-- reset
		outclk_0 => CLK40,		-- 40MHz
		outclk_1 => PCLK,			-- 20MHz
		outclk_2 => TCLK			-- 20MHz
	);
--	PLL0 : pll100 port map (
--		refclk   => CLOCK_50, -- clk
--		rst      => URST, -- reset
--		outclk_0 : out std_logic;        -- 100MHz
--		outclk_1 : out std_logic;        -- 100MHz(-60deg)
--		outclk_2 => PCLK,        -- 20MHz
--		outclk_3 : out std_logic         -- 1MHz
--	);

	SOPC0 : mz700_sopc port map (
		pclk_clk        => PCLK,					--    clk.clk
		pio_0_export    => LEDR(7 downto 0),	--  pio_0.export
		reset_reset_n   => URST,					--  reset.reset_n
		sdif_0_sd_cdir  => MC_CDIR,				-- sdif_0.sd_cdir
		sdif_0_ck40m    => CLK40,					--       .ck40m
		sdif_0_sd_clk   => MC_CLK,					--       .sd_clk
		sdif_0_sd_cmd   => MC_CMD,					--       .sd_cmd
		sdif_0_sd_dati  => SD_DATA,				--       .sd_dati
		sdif_0_sd_dato  => MC_DATo,				--       .sd_dato
		sdif_0_sd_ddir  => MC_DDIR,				--       .sd_ddir
		sdif_0_sd_inuse => LEDR(9),				--       .sd_inuse
		sdif_0_sd_resp  => SD_CMD					--       .sd_resp
	);

	--
	-- Reset
	--
--	process( pSltRst_n, CPUCLK ) begin
--		if( pSltRst_n='0' ) then
--			RCOUNT<=(others=>'0');
--		elsif( CPUCLK'event and CPUCLK='1' ) then
--			if( RCOUNT(10)='0' ) then
--				RCOUNT<=RCOUNT+'1';
--			end if;
--		end if;
--	end process;
	URST<=RESET_N;	--RCOUNT(10);

	--
	-- Port
	--
	SD_CLK<=MC_CLK;
	SD_CMD<=MC_CMD when MC_CDIR='0' else 'Z';
	SD_DATA<=MC_DATo when MC_DDIR='0' else "ZZZZ";
	LEDR(8)<='0';
	HEX0<=(others=>'1');
	HEX1<=(others=>'1');
	HEX2<=(others=>'1');
	HEX3<=(others=>'1');
	HEX4<=(others=>'1');
	HEX5<=(others=>'1');


end rtl;
