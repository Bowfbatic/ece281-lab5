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
--|
--| ALU OPCODES:
--|
--|     ADD                    000
--|     SUBTRACT               100
--|     BITWISE AND            101 	
--|     BITWISE OR	           001 	
--|     LEFT LOGICAL SHIFT	   011	        
--|     RIGHT LOGICAL SHIFT    010	        
--|
--|
--|
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity ALU is

    Port (
        i_A :   in std_logic_vector (7 downto 0);
        i_B :   in std_logic_vector (7 downto 0);
        i_op    :   in std_logic_vector (2 downto 0);
        o_results   :   out std_logic_vector (7 downto 0);
        o_flags     :   out std_logic_vector (2 downto 0)
    );
    
end ALU;

architecture behavioral of ALU is 
  
	-- declare components and signals
	signal w_Cout, w_zero  :   std_logic;
	signal w_results   :   std_logic_vector (7 downto 0);
	
  
begin
	-- PORT MAPS ----------------------------------------
	-- CONCURRENT STATEMENTS ----------------------------
	w_results <= std_logic_vector(unsigned(i_A) + unsigned(i_B));
	w_zero <= '1' when (w_results = "00000000") else '0';
	
	w_Cout <= '1' when (w_results < i_A and w_results < i_B) else
	          '0';
	o_results <= w_results;
	
	o_flags(2) <= '0';
	o_flags(1) <= w_zero;
	o_flags(0) <= w_Cout;
	
end behavioral;
