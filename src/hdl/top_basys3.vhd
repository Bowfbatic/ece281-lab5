--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
-- TODO
    port (
    -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(15 downto 0);
        btnU    :   in std_logic; -- master_reset
        btnC    :   in std_logic; -- cycle advancer
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
        );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
    component ALU is
    Port (
        i_A :   in std_logic_vector (7 downto 0);
        i_B :   in std_logic_vector (7 downto 0);
        i_op    :   in std_logic_vector (2 downto 0);
        o_results   :   out std_logic_vector (7 downto 0);
        o_flags     :   out std_logic_vector (2 downto 0)
    ); 
    end component ALU;
    
    component controller_fsm is
    Port (
        i_adv   :   in std_logic;
        i_clk   :   in std_logic;
        i_reset :   in std_logic;
        o_cycle :   out std_logic_vector (3 downto 0)       
    );
    end component controller_fsm;
    
    component clock_divider is 
    generic ( constant k_DIV : natural := 2	);
	port ( 	i_clk    : in std_logic;		   -- basys3 clk
			i_reset  : in std_logic;		   -- asynchronous
			o_clk    : out std_logic		   -- divided (slow) clock
	); 
	end component clock_divider;
    
    component TDM4 is
    generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
    Port (
        i_clk		: in  STD_LOGIC;
        i_reset		: in  STD_LOGIC; -- asynchronous
        i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	);
	end component TDM4;
	
	component twoscomp_decimal is
	Port (
	   i_binary: in std_logic_vector(7 downto 0);
--        o_negative: out std_logic_vector ( 3 downto 0);
        o_negative: out std_logic;
        o_hundreds: out std_logic_vector(3 downto 0);
        o_tens: out std_logic_vector(3 downto 0);
        o_ones: out std_logic_vector(3 downto 0)
    );
    end component twoscomp_decimal;
    
    component sevenSegDecoder is
    Port (
        i_D : in STD_LOGIC_VECTOR (3 downto 0);
        o_S : out STD_LOGIC_VECTOR (6 downto 0)
    );
    end component sevenSegDecoder;
    
    
    signal w_regA, w_regB, w_results, w_val, w_neg_display    :   std_logic_vector (7 downto 0);
    signal w_op, w_flags :   std_logic_vector (2 downto 0);
    signal w_tdm, w_an    :   std_logic_vector (3 downto 0);
    
    signal w_cycle  :   std_logic_vector (3 downto 0) := "0001";
    signal f_Q, f_Q_next    :   std_logic_vector (3 downto 0);
    
    signal w_neg   :   std_logic;
    signal w_hund, w_tens, w_ones, w_sevSegSign   :   std_logic_vector (3 downto 0);

    signal w_clk_tdm    :   std_logic;
  
begin
	-- PORT MAPS ----------------------------------------
    ALU_inst    :   ALU
    port map (
        i_A => w_regA,
        i_B => w_regB,
        i_op => w_op,
        o_results => w_results,
        o_flags => w_flags
    );
	
	controller_inst    :   controller_fsm
	port map (
	   i_adv => btnC,
	   i_clk => clk, -- need a clock divider clk
	   i_reset => btnU,
	   o_cycle => w_cycle
    );
    
    clk_TDM_inst    :   clock_divider
    generic map ( k_DIV => 100000 ) -- 2 Hz
    port map (
        i_clk => clk,
        i_reset => btnU,
        o_clk => w_clk_tdm
    );
    
    tdm_inst    :   TDM4
    port map (
        i_clk => w_clk_tdm,
        i_reset => btnU,
        i_D3 => w_sevSegSign,
        i_D2 => w_hund,
        i_D1 => w_tens,
        i_D0 => w_ones,
        o_data => w_tdm,
        o_sel => w_an
    );
    
    twoscomp_inst   :   twoscomp_decimal
    port map (
        i_binary => w_val,
        o_negative => w_neg,
        o_hundreds => w_hund,
        o_tens => w_tens,
        o_ones => w_ones
    );
    
    sevenSegDec_inst    :   sevenSegDecoder
    port map (
        i_D => w_tdm,
        o_S => seg
	);
	
	
	-- CONCURRENT STATEMENTS ----------------------------
	an <= "1111" when (w_cycle = "0001") else -- clear display on reset
	       w_an;
	       
	w_val <= w_regA when (w_cycle = "1000") else
	         w_regB when (w_cycle = "0100") else
	         w_results when (w_cycle = "0010") else
	         "00000000";
	         
	w_sevSegSign <= x"F" when (w_neg = '1') else --  negative
	                x"E"; -- positive
	                
	w_op <= sw(2 downto 0);
	
	
	led(15 downto 13) <= w_flags when w_cycle = "0010" else "000";
	led(3 downto 0) <= w_cycle;
	led(12 downto 4) <= (others => '0');
	
	reg_process    :   process(clk)
	begin
	
	   if (rising_edge(clk)) then 
            if (w_cycle = "0001") then
            w_regA <= sw (7 downto 0);
            elsif (w_cycle = "1000") then
            w_regB <= sw (7 downto 0);
            else
            w_regA <= w_regA;
            w_regB <= w_regB;
            end if;
        end if;
        
	end process reg_process;

end top_basys3_arch;
