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
	signal w_Cout, w_zero, w_neg  :   std_logic;
	signal w_results   :   std_logic_vector (7 downto 0);
	signal w_adder   :   std_logic_vector (7 downto 0);
	
	signal w_and_bitwise, w_or_bitwise, w_bitwise :   std_logic_vector (7 downto 0);
	signal w_check_adder : std_logic_vector (8 downto 0);
	
	signal w_A : std_logic_vector (7 downto 0);
	signal w_shift_right, w_shift_left : std_logic_vector (7 downto 0);
  
begin
	-- CONCURRENT STATEMENTS ----------------------------\
	-- adding and subtracting
	w_adder <= std_logic_vector(signed(i_A) + signed(i_B)) when i_op = "000" else
	           std_logic_vector(signed(i_A) - signed(i_B));	            
	w_check_adder <= std_logic_vector(resize(signed(i_A),9) + resize(signed(i_B), 9)) when i_op = "000" else
	                 std_logic_vector(resize(signed(i_A),9) - resize(signed(i_B), 9));
	
	-- bitwise operations
	w_and_bitwise <= i_A and i_B;
	w_or_bitwise <= i_A or i_B;
	w_bitwise <= w_and_bitwise when (i_op = "101") else w_or_bitwise;
	
	-- logical shifts
	w_shift_right <= std_logic_vector(shift_right(unsigned(i_A), to_integer(unsigned(i_B(2 downto 0)))));
	w_shift_left <= std_logic_vector(shift_left(unsigned(i_A), to_integer(unsigned(i_B(2 downto 0)))));
	
	
	-- select output
	w_results <= w_adder when (i_op(1 downto 0) = "00") else
	             w_bitwise when (i_op(1 downto 0) = "01") else
	             w_shift_right when (i_op(1 downto 0) = "10") else
	             w_shift_left when (i_op(1 downto 0) = "11") else
	             w_results;

	-- flags
	w_zero <= '1' when (w_results = "00000000") else '0'; -- zero flag
	
	w_Cout <= w_check_adder(8) when (i_op = "000" or i_op = "100") else '0'; 
	
	w_neg <= w_results(7);
	
	o_results <= w_results;
		
	o_flags(2) <= w_neg;
	o_flags(1) <= w_zero;
	o_flags(0) <= w_Cout;
	
	
	
	
	
end behavioral;
