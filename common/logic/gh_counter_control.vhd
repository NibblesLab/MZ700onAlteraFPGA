-----------------------------------------------------------------------------
--	Filename:	gh_counter_control.vhd
--
--	Description:
--		counter control for the 8254 Timer
--
--	Copyright (c) 2008 by H LeFevre 
--		A VHDL 8254 Timer core
--		an OpenCores.org Project
--		free to use, but see documentation for conditions 
--
--	Revision 	History:
--	Revision 	Date       	Author    	Comment
--	-------- 	---------- 	---------	-----------
--	1.0      	08/02/08  	H LeFevre	Initial revision
--
-----------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;

entity gh_counter_control is
	GENERIC(same_clk: boolean := false;	-- true, if same clock is used for bus and counter
	        sync_clk: boolean := false); -- true, if bus and counter clocks are synchronous
	port(	  
	-------- data bus/control signals ------------
		clk_i  : in std_logic;
		rst    : in std_logic;
		ics    : in std_logic;
		dwr    : in std_logic;
		iA     : in std_logic_vector(1 downto 0);
		iD     : in std_logic_vector(7 downto 0);
		dat_o  : out std_logic_vector(7 downto 0);
	----------------------------------------------------
	------ counter output/control signals --------------	
		clk     : in std_logic;
		rd_busy : out std_logic;
		gate    : in std_logic;
		Cout    : out std_logic
		);
end entity;

architecture a of gh_counter_control is

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

COMPONENT gh_register_ce is
	GENERIC (size: INTEGER := 8);
	PORT(	
		clk : IN		STD_LOGIC;
		rst : IN		STD_LOGIC; 
		CE  : IN		STD_LOGIC; -- clock enable
		D   : IN		STD_LOGIC_VECTOR(size-1 DOWNTO 0);
		Q   : OUT		STD_LOGIC_VECTOR(size-1 DOWNTO 0)
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

COMPONENT gh_edge_det_XCD_t is
	GENERIC(same_clk: boolean := false;	-- true, if same clock is used for i/o clocks
	        sync_clk: boolean := false); -- true, if i/o clocks are synchronous
	port(
		iclk : in STD_LOGIC;  -- clock for input data signal
		oclk : in STD_LOGIC;  -- clock for output data pulse
		rst  : in STD_LOGIC;
		D    : in STD_LOGIC;
		re   : out STD_LOGIC  -- rising edge 
		);
END COMPONENT;

COMPONENT gh_counter_down_16b_bb is
	port(
		clk    : in STD_LOGIC;
		rst    : in STD_LOGIC;
		BCD_EN : in STD_LOGIC;
		CE     : in STD_LOGIC;
		LD     : in STD_LOGIC;
		M_CMD  : in STD_LOGIC;
		MODE   : in STD_LOGIC_VECTOR(2 downto 0);
		DI     : in STD_LOGIC_VECTOR(15 downto 0);
		Cout   : out std_logic;
		NULL_C : out std_logic;
		DO     : out STD_LOGIC_VECTOR(15 downto 0)
		);
END COMPONENT;

	signal control   : std_logic_vector(5 downto 0);
	signal cRW       : std_logic_vector(1 downto 0);
	signal DC_lsb    : std_logic_vector(7 downto 0);
	signal DC_msb    : std_logic_vector(7 downto 0);
	signal DCI       : std_logic_vector(15 downto 0);
	signal MODE      : std_logic_vector(2 downto 0);
	signal sMODE     : std_logic_vector(2 downto 0);
	signal iD_lsb    : std_logic_vector(7 downto 0);
	signal iD_msb    : std_logic_vector(7 downto 0);
	signal iload     : std_logic;
	signal load      : std_logic;
	signal ld_cmd    : std_logic;
	signal ld_lsb    : std_logic;
	signal ld_msb    : std_logic;
	signal rd_lsb    : std_logic;
	signal rd_msb    : std_logic;
	signal srd_lsb   : std_logic;
	signal srd_msb   : std_logic;
	signal dwb       : std_logic;
	signal rdwb      : std_logic;
	signal drb       : std_logic;
	signal rdrb      : std_logic;
	signal iout      : std_logic;
							 	 
	signal iclcw     : std_logic;
	signal clcw      : std_logic;
	signal clcw_l    : std_logic;
	signal clcw_m    : std_logic;
	signal slcw_l    : std_logic;
	signal slcw_m    : std_logic;
	signal iclsw     : std_logic;
	signal hclsw     : std_logic;
	signal clsw      : std_logic;
	signal clsw_n    : std_logic;
	signal rdst      : std_logic;
	signal DO        : std_logic_vector(15 downto 0);
	signal rDO       : std_logic_vector(15 downto 0);
	signal Ds        : std_logic_vector(7 downto 0);
	signal rDs       : std_logic_vector(7 downto 0);
	signal NULL_C    : std_logic;
	signal M_CMD     : std_logic;
	signal CE        : std_logic;
	signal m0_outh   : std_logic;
	signal set_busy  : std_logic;
	signal clr_busy  : std_logic;
	signal s_hdcl    : std_logic;
	signal h_hdcl    : std_logic;
	signal c_hdcl    : std_logic;
	signal fe_hdcl   : std_logic;
	signal ird_busy  : std_logic;
	signal clr_hclsw : std_logic;
	
begin
 
----------------------------------------------------

	
	rd_busy <= ird_busy;

	dat_o <= rDs when (hclsw = '1') else
	         rDO(7 downto 0) when ((control(5 downto 4) = "11") and (drb = '0')) else
	         rDO(15 downto 8) when (control(5 downto 4) = "11") else
	         rDO(7 downto 0) when (control(5 downto 4) = "01") else
	         rDO(15 downto 8);-- when ((iA = "00") and (control0(5 downto 4) = "10")) else;
			 
	Ds <= iout & NULL_C & control;
			 
u0 : gh_register_ce 
	generic map (8)
	port map(
		clk => clk,
		rst => rst,
		ce => clsw,
		D => Ds,
		Q => rDs);

	
----------------------------------------------------

	ld_cmd <= '1' when ((dwr = '1') and (iA = "11") and (iD(7 downto 6) = "00") and (iCS = '1')) else
	          '0';

U1 : gh_edge_det_XCD_t
	GENERIC MAP(same_clk => same_clk,
	            sync_clk => sync_clk)
	PORT MAP (
		iclk => clk_i,
		oclk => clk,
		rst => rst,
		d => ld_cmd,
		re => M_CMD);
			  
u2 : gh_register_ce 
	generic map (6)
	port map(
		clk => clk_i,
		rst => rst,
		ce => ld_cmd,
		D => iD(5 downto 0),
		Q => control
		);
			   
	ld_lsb <= '1' when ((dwr = '1') and (iA = "00") and (control(5 downto 4) = "01") and (iCS = '1')) else
	          '1' when ((dwr = '1') and (iA = "00") and (control(5 downto 4) = "11") and (dwb = '0') and (iCS = '1')) else
	          '0';
			   
	ld_msb <= '1' when ((dwr = '1') and (iA = "00") and (control(5 downto 4) = "10") and (iCS = '1')) else
	          '1' when ((dwr = '1') and (iA = "00") and (control(5 downto 4) = "11") and (dwb = '1') and (iCS = '1')) else
	          '0';
			   
	rd_lsb <= '0' when (hclsw = '1') else
	          '1' when ((dwr = '0') and (iA = "00") and (control(5 downto 4) = "01") and (iCS = '1')) else
	          '1' when ((dwr = '0') and (iA = "00") and (control(5 downto 4) = "11") and (drb = '0') and (iCS = '1')) else
	          '0';
			   
	rd_msb <= '1' when ((dwr = '0') and (iA = "00") and (control(5 downto 4) = "10") and (iCS = '1')) else
	          '1' when ((dwr = '0') and (iA = "00") and (control(5 downto 4) = "11") and (drb = '1') and (iCS = '1')) else
	          '0';

	rdst <=  '1' when ((dwr = '0') and (iA = "00") and (iCS = '1')) else
	         '0';
			   
	sMODE <= control(3 downto 1);

	cRW <= control(5 downto 4);
	
process (sMODE,iload,iout,gate,ld_lsb,ld_msb,ld_cmd,cRW,dwb,m0_outh)
begin
	case sMODE is
		when "000" => -- mode zero
			MODE <= "000"; 			
			if (cRW = "11") then
				iload <= ld_msb;
			elsif ((ld_lsb or ld_msb or ld_cmd) = '1') then
				iload <= '1'; 
			else
				iload <= '0';
			end if;
			if (cRW = "11") then
				CE <= gate and (not dwb);
			else 
				CE <= gate;
			end if;
			if (iout = '1') then
				Cout <= '1';
			elsif (iload = '1') then
				Cout <= '0';
			else
				Cout <= m0_outh;
			end if;
		when "001" => 
			MODE <= "001";
			iload <= gate;
			CE <= gate;
			Cout <= iout;
		when "010" => 
			MODE <= "010";
			CE <= gate;
			if (cRW = "11") then
				iload <= ld_msb;
			elsif ((ld_lsb or ld_msb) = '1') then
				iload <= '1'; 
			else
				iload <= '0';
			end if;
			Cout <= iout or (not gate);
		when "110" =>
			MODE <= "010";
			CE <= gate;
			if (cRW = "11") then
				iload <= ld_msb;
			elsif ((ld_lsb or ld_msb) = '1') then
				iload <= '1'; 
			else
				iload <= '0';
			end if;
			Cout <= iout or (not gate); 
		when "011" =>
			MODE <= "011";
			CE <= gate;
			if (cRW = "11") then
				iload <= ld_msb;
			elsif ((ld_lsb or ld_msb) = '1') then
				iload <= '1'; 
			else
				iload <= '0';
			end if;
			Cout <= iout;
		when "111" =>
			MODE <= "011";
			CE <= gate;
			if (cRW = "11") then
				iload <= ld_msb;
			elsif ((ld_lsb or ld_msb) = '1') then
				iload <= '1'; 
			else
				iload <= '0';
			end if;
			Cout <= iout;
		when "100" =>
			MODE <= "100";
			CE <= gate;
			if (cRW = "11") then
				iload <= ld_msb;
			elsif ((ld_lsb or ld_msb) = '1') then
				iload <= '1'; 
			else
				iload <= '0';
			end if;
			Cout <= iout;
		when "101" =>
			MODE <= "101";
			iload <= '0';
			CE <= gate;
			Cout <= iout;
		when others =>
			MODE <= "111";
			iload <= '0';
			CE <= gate;
			Cout <= iout;
	end case;
end process;

U3 : gh_jkff 
	PORT MAP (
--		clk => clk,
		clk => clk_i,
		rst => rst,
		j => iout,
		k => iload,
		Q => m0_outh);

	rdwb <= ld_msb or ld_cmd;
	rdrb <= '1' when ((rd_msb = '1') or (ld_cmd = '1')) else
	        '1' when ((dwr = '1') and (iA = "11") and (iD(7 downto 5) = "110") and (iD(1) = '1') and (iCS = '1')) else
	        '0';
	
U4 : gh_jkff 
	PORT MAP (
		clk => clk_i,
		rst => rst,
		j => ld_lsb,
		k => rdwb,
		Q => dwb);

U5 : gh_jkff 
	PORT MAP (
		clk => clk_i,
		rst => rst,
		j => rd_lsb,
		k => rdrb,
		Q => drb);

	iD_lsb <= x"00" when (control(5 downto 4) = "10") else
	          iD;

	iD_msb <= x"00" when (control(5 downto 4) = "01") else
	          iD;
				
u6 : gh_register_ce 
	generic map (8)
	port map(
		clk => clk_i,
		rst => rst,
		ce => ld_lsb,
		D => iD_lsb,
		Q => DC_lsb
		);
		
u7 : gh_register_ce 
	generic map (8)
	port map(
		clk => clk_i,
		rst => rst,
		ce => ld_msb,
		D => iD_msb,
		Q => DC_msb
		);
		
	DCI <= (DC_msb & DC_lsb);

U8 : gh_edge_det_XCD_t
	GENERIC MAP(same_clk => same_clk,
	            sync_clk => sync_clk)
	PORT MAP (
		iclk => clk_i,
		oclk => clk,
		rst => rst,
		d => iLOAD,
		re => load);
		
U9 : gh_counter_down_16b_bb
	PORT MAP (
		clk    => clk,
		rst    => rst,
		BCD_EN => control(0),
		CE     => CE,
		LD     => load,
		M_CMD  => M_CMD,
		MODE   => MODE,
		DI	   => DCI,
		NULL_C => NULL_C,
		Cout   => iout,
		DO     => DO
		);

----------------------------------------------------

	iclcw <= '1' when ((dwr = '1') and (iA = "11") and (iD(7 downto 4) = x"0") and (iCS = '1')) else
	         '1' when ((dwr = '1') and (iA = "11") and (iD(7 downto 5) = "110") and (iD(1) = '1') and (iCS = '1')) else
	         '0';
			 
U10 : gh_edge_det_XCD_t 
	GENERIC MAP(same_clk => same_clk,
	            sync_clk => sync_clk)
	PORT MAP (
		iclk => clk_i,
		oclk => clk,
		rst => rst,
		d => iclcw,
		re => clcw);

	slcw_l <= M_CMD or srd_lsb;  
		
U11 : gh_jkff 
	PORT MAP (
		clk => clk,
		rst => rst,
		j => slcw_l,
		k => clcw,
		Q => clcw_l);
		
u12 : gh_register_ce 
	generic map (8)
	port map(
		clk => clk,
		rst => rst,
		ce => clcw_l,
		D => DO(7 downto 0),
		Q => rDO(7 downto 0));

	slcw_m <= M_CMD or srd_msb;
		
U13 : gh_jkff 
	PORT MAP (
		clk => clk,
		rst => rst,
		j => slcw_m,
		k => clcw,
		Q => clcw_m);
		
u14 : gh_register_ce 
	generic map (8)
	port map(
		clk => clk,
		rst => rst,
		ce => clcw_m,
		D => DO(15 downto 8),
		Q => rDO(15 downto 8));
		
	iclsw <= '1' when ((dwr = '1') and (iA = "11") and (iD(7 downto 6) = "11") and (iD(4) = '0') and (iD(1) = '1') and (iCS = '1')) else
	         '0';
			 
U15 : gh_edge_det_XCD_t
	GENERIC MAP(same_clk => same_clk,
	            sync_clk => sync_clk)
	PORT MAP (
		iclk => clk_i,
		oclk => clk,
		rst => rst,
		d => iclsw,
		re => clsw);
		
	clr_hclsw <= (rdst and not ird_busy) or fe_hdcl;
		
U16 : gh_jkff 
	PORT MAP (
		clk => clk_i,
		rst => rst,
		j => iclsw,
		k => clr_hclsw,
		Q => hclsw);

	s_hdcl <= iCS and (not dwr) and ird_busy;
		
U17 : gh_jkff 
	PORT MAP (
		clk => clk_i,
		rst => rst,
		j => s_hdcl,
		k => clr_hclsw,
		Q => h_hdcl);
		
	c_hdcl <= h_hdcl and ird_busy; 
		
U18 : gh_edge_det 
	PORT MAP (
		clk => clk_i,
		rst => rst,
		d => c_hdcl,
		fe => fe_hdcl);
		
----------------------------------------------------

	clsw_n <= not clsw;

U19 : gh_edge_det_XCD_t
	GENERIC MAP(same_clk => same_clk,
	            sync_clk => sync_clk)
	PORT MAP (
		iclk => clk,
		oclk => clk_i,
		rst => rst,
		d => clsw_n,
		re => clr_busy);
	
	set_busy <= iclcw;
	
U20 : gh_jkff 
	PORT MAP (
		clk => clk_i,
		rst => rst,
		j => set_busy,
		k => clr_busy,
		Q => ird_busy);

U21 : gh_edge_det_XCD_t
	GENERIC MAP(same_clk => same_clk,
	            sync_clk => sync_clk)
	PORT MAP (
		iclk => clk_i,
		oclk => clk,
		rst => rst,
		d => rd_lsb,
		re => srd_lsb);

U22 : gh_edge_det_XCD_t
	GENERIC MAP(same_clk => same_clk,
	            sync_clk => sync_clk)
	PORT MAP (
		iclk => clk_i,
		oclk => clk,
		rst => rst,
		d => rd_msb,
		re => srd_msb);
		
end a;
