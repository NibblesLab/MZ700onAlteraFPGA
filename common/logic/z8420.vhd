--
-- z8420.vhd
--
-- Zilog Z80PIO partiality compatible module
-- for MZ-1500 Version Up Adaptor for MZ-700
--
-- mode 3 only
--
-- Nibbles Lab. 2005-2016
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity z8420 is
	Port (
		-- System
		RST	 : in std_logic;								-- Only Power On Reset
		-- Z80 Bus Signals
		CLK	 : in std_logic;
      BASEL	 : in std_logic;
      CDSEL	 : in std_logic;
		CE		 : in std_logic;
		RD_x	 : in std_logic;
		WR_x	 : in std_logic;
		IORQ_x : in std_logic;
		M1_x	 : in std_logic;
		DI     : in std_logic_vector(7 downto 0);
		DO     : out std_logic_vector(7 downto 0);
		IEI	 : in std_logic;
		IEO	 : out std_logic;
		INT_x	 : out std_logic;
		-- Port
		AI		 : in std_logic_vector(7 downto 0);
		AO		 : out std_logic_vector(7 downto 0);
		BI		 : in std_logic_vector(7 downto 0);
		BO		 : out std_logic_vector(7 downto 0);
		-- for Debug
		LDDAT  : out std_logic_vector(7 downto 0)
--		LDDAT2 : out std_logic;
--		LDSNS  : out std_logic;
	);
end z8420;

architecture Behavioral of z8420 is

--
-- Port Selecter
--
signal SELAD : std_logic;
signal SELBD : std_logic;
signal SELAC : std_logic;
signal SELBC : std_logic;
--
-- Port Register
--
signal PORTA : std_logic_vector(7 downto 0);		-- Port Value for ReadOUt (Port A)
signal AREG : std_logic_vector(7 downto 0);		-- Output Register (Port A)
signal DIRA : std_logic_vector(7 downto 0);		-- Data Direction (Port A)
signal DDWA : std_logic;								-- Prepare for Data Direction (Port A)
signal IMWA : std_logic_vector(7 downto 0);		-- Interrupt Mask Word (Port A)
signal MFA : std_logic;									-- Mask Follows (Port A)
signal VECTA : std_logic_vector(7 downto 0);		-- Interrupt Vector (Port A)
signal MODEA : std_logic_vector(1 downto 0);		-- Mode Word (Port A)
signal HLA : std_logic;									-- High/Low (Port A)
signal AOA : std_logic;									-- AND/OR (Port A)
signal PORTB : std_logic_vector(7 downto 0);		-- Port Value for ReadOUt (Port B)
signal BREG : std_logic_vector(7 downto 0);		-- Output Register (Port B)
signal DIRB : std_logic_vector(7 downto 0);		-- Data Direction (Port B)
signal DDWB : std_logic;								-- Prepare for Data Direction (Port B)
signal IMWB : std_logic_vector(7 downto 0);		-- Interrupt Mask Word (Port B)
signal MFB : std_logic;									-- Mask Follows (Port B)
signal VECTB : std_logic_vector(7 downto 0);		-- Interrupt Vector (Port B)
signal MODEB : std_logic_vector(1 downto 0);		-- Mode Word (Port B)
signal HLB : std_logic;									-- High/Low (Port B)
signal AOB : std_logic;									-- AND/OR (Port B)
--
-- Interrupt
--
signal VECTENA : std_logic;							-- Interrupt Vector (Port A)
signal EIA : std_logic;									-- Interrupt Enable (Port A)
signal MINTA : std_logic_vector(7 downto 0);		-- Masked Inerrupt (Port A)
signal INTA : std_logic;								-- Inerrupt Occured (Port A)
signal INTA0 : std_logic;								-- Inerrupt Occured (Port A)
signal INTA_x : std_logic;								-- Inerrupt Request for CPU (Port A)
signal VECTENB : std_logic;							-- Interrupt Vector (Port B)
signal EIB : std_logic;									-- Interrupt Enable (Port B)
signal MINTB : std_logic_vector(7 downto 0);		-- Masked Inerrupt (Port B)
signal INTB : std_logic;								-- Interrupt Occured (Port B)
signal INTB0 : std_logic;								-- Interrupt Occured (Port B)
signal INTB_x : std_logic;								-- Interrupt Request for CPU (Port B)
signal iIE : std_logic;									-- Daisy Chain Signal (Port A&B)

--
-- Components
--
component Interrupt is
	Port (
		-- System Signal
		RESET	 : in std_logic;
		CLK	 : in std_logic;
		-- CPU Signals
		DI		 : in std_logic_vector(7 downto 0);
		IORQ_x : in std_logic;		-- same as Z80
		RD_x	 : in std_logic;		-- same as Z80
		M1_x	 : in std_logic;		-- same as Z80
		IEI	 : in std_logic;		-- same as Z80
		IEO	 : out std_logic;		-- same as Z80
		INTO_x : out std_logic;
		-- Control Signals
		VECTEN : out std_logic;
		INTI	 : in std_logic;
		INTEN	 : in std_logic
	);
end component;

begin

	--
	-- Instantiation
	--
	INT0 : Interrupt port map (
		-- System Signal
		RESET => not RST,
		CLK => CLK,
		-- CPU Signals
		DI => DI,
		IORQ_x => IORQ_x,
		RD_x => RD_x,
		M1_x => M1_x,
		IEI => IEI,
		IEO => iIE,
		INTO_x => INTA_x,
		-- Control Signals
		VECTEN => VECTENA,
		INTI => INTA,
		INTEN => EIA
	);

	INT1 : Interrupt port map (
		-- System Signal
		RESET => not RST,
		CLK => CLK,
		-- CPU Signals
		DI => DI,
		IORQ_x => IORQ_x,
		RD_x => RD_x,
		M1_x => M1_x,
		IEI => iIE,
		IEO => IEO,
		INTO_x => INTB_x,
		-- Control Signals
		VECTEN => VECTENB,
		INTI => INTB,
		INTEN => EIB
	);

	--
	-- Port select for Output
	--
	SELAD<='1' when BASEL='0' and CDSEL='0' else '0';
	SELBD<='1' when BASEL='1' and CDSEL='0' else '0';
	SELAC<='1' when BASEL='0' and CDSEL='1' else '0';
	SELBC<='1' when BASEL='1' and CDSEL='1' else '0';

	--
	-- Control
	--
	process( RST, CLK ) begin
		if RST='0' then
			MODEA<="11";
			DIRA<="00111111";
			DDWA<='0';
			MFA<='0';
			EIA<='0';
			VECTA<=(others=>'0');
			IMWA<=(others=>'1');
			MODEB<="11";
			DIRB<=(others=>'0');
			DDWB<='0';
			MFB<='0';
			EIB<='0';
			VECTB<=(others=>'0');
			IMWB<=(others=>'1');
		elsif CLK'event and CLK='0' then
			if CE='0' and WR_x='0' then
				if SELAC='1' then
					if DDWA='1' then
						DIRA<=DI;
						DDWA<='0';
					elsif MFA='1' then
						IMWA<=DI;
						MFA<='0';
					elsif DI(0)='0' then
						VECTA<=DI;
					elsif DI(3 downto 0)="1111" then
						MODEA<=DI(7 downto 6);
						DDWA<=DI(7) and DI(6);
					elsif DI(3 downto 0)="0111" then
						MFA<=DI(4);
						HLA<=DI(5);
						AOA<=DI(6);
						EIA<=DI(7);
					elsif DI(3 downto 0)="0011" then
						EIA<=DI(7);
					end if;
				end if;
				if SELBC='1' then
					if DDWB='1' then
						DIRB<=DI;
						DDWB<='0';
					elsif MFB='1' then
						IMWB<=DI;
						MFB<='0';
					elsif DI(0)='0' then
						VECTB<=DI;
					elsif DI(3 downto 0)="1111" then
						MODEB<=DI(7 downto 6);
						DDWB<=DI(7) and DI(6);
					elsif DI(3 downto 0)="0111" then
						MFB<=DI(4);
						HLB<=DI(5);
						AOB<=DI(6);
						EIB<=DI(7);
					elsif DI(3 downto 0)="0011" then
						EIB<=DI(7);
					end if;
				end if;
			end if;
		end if;
	end process;

	process( RST, CLK ) begin
		if RST='0' then
			AREG<=(others=>'0');
			BREG<=(others=>'0');
		elsif CLK'event and CLK='0' then
			if CE='0' and WR_x='0' then
				if SELAD='1' then
					AREG<=DI;
				end if;
				if SELBD='1' then
					BREG<=DI;
				end if;
			end if;
		end if;
	end process;

	AO<=AREG and (not DIRA);
	BO<=BREG and (not DIRB);
	INT_x<=INTA_x and INTB_x;

	-- Latch for ReadOut
	process( RD_x ) begin
		if RD_x'event and RD_x='0' then
			PORTA<=(AREG and (not DIRA)) or (AI and DIRA);
			PORTB<=(BREG and (not DIRB)) or (BI and DIRB);
		end if;
	end process;

	--
	-- Port Read and Output Vector
	--
	DO<=PORTA when RD_x='0' and CE='0' and SELAD='1' else
		 PORTB when RD_x='0' and CE='0' and SELBD='1' else
		 VECTA when VECTENA='1' else
		 VECTB when VECTENB='1' else (others=>'0');

	--
	-- Interrupt select
	--
	INTMASK : for I in 0 to 7 generate
		MINTA(I)<=(AI(I) xnor HLA) and (not IMWA(I)) when AOA='0' else
					 (AI(I) xnor HLA) or IMWA(I);
		MINTB(I)<=(BI(I) xnor HLB) and (not IMWB(I)) when AOB='0' else
					 (BI(I) xnor HLB) or IMWB(I);
	end generate INTMASK;
	INTA0<=MINTA(7) or MINTA(6) or MINTA(5) or MINTA(4) or MINTA(3) or MINTA(2) or MINTA(1) or MINTA(0) when AOA='0' else
			 MINTA(7) and MINTA(6) and MINTA(5) and MINTA(4) and MINTA(3) and MINTA(2) and MINTA(1) and MINTA(0);
	INTB0<=MINTB(7) or MINTB(6) or MINTB(5) or MINTB(4) or MINTB(3) or MINTB(2) or MINTB(1) or MINTB(0) when AOB='0' else
			 MINTB(7) and MINTB(6) and MINTB(5) and MINTB(4) and MINTB(3) and MINTB(2) and MINTB(1) and MINTB(0);
	process( CLK ) begin
		if CLK'event and CLK='1' then
			INTA<=INTA0;
			INTB<=INTB0;
		end if;
	end process;

	--
	-- Others
	--

--	LDDAT<=TBLNK&"0000000";

end Behavioral;
