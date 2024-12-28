library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;

entity goertzel_calc_registered_v4 is

	generic
	(
        COEFF_INT_BITS : integer := 2;
        COEFF_FRAC_BITS : integer := 14;
    
        Q_INT_BITS : integer    := 11;
        Q_FRAC_BITS : integer   := 5;
    
        X_INT_BITS  : integer   := 2;
        X_FRAC_BITS : integer   := 14;
		  
		  BLOCK_SIZE  : natural   := 321
	);

	port
	(
		clk, start, rst	: in std_logic;
		-- Fixed-point format specifier: (sign).(integer).(fraction)
		x_in					: in sfixed((X_INT_BITS-1) downto -X_FRAC_BITS); -- Format: 1.1.14
		coeff					: in sfixed((COEFF_INT_BITS-1) downto -COEFF_FRAC_BITS); -- Format: 1.1.14
		ready					: out std_logic;
		Q0, Q1, Q2			: out sfixed(Q_INT_BITS-1 downto -Q_FRAC_BITS) -- Format: 1.10.5
	);

end entity;

architecture rtl of goertzel_calc_registered_v4 is

	type state_type is (idle, get_x, update);
	signal state_reg, state_next : state_type;
	
	-- Three register chain 
	signal Q0_reg, Q1_reg, Q2_reg	  : sfixed(Q_INT_BITS-1 downto -Q_FRAC_BITS);
	signal Q0_next, Q1_next, Q2_next: sfixed(Q_INT_BITS-1 downto -Q_FRAC_BITS);
	
	-- input register
	signal x_reg : sfixed((X_INT_BITS-1) downto -X_FRAC_BITS);

begin
	
	-- Inferr register process
	process (clk, rst)
	begin
		if rst = '1' then
			x_reg  <= (others => '0');
			Q0_reg <= (others => '0');
			Q1_reg <= (others => '0');
			Q2_reg <= (others => '0');
			state_reg <= idle;
		elsif (rising_edge(clk)) then
			if (start = '1') then
				x_reg <= x_in;
				Q0_reg <= Q0_next;
				Q1_reg <= Q1_next;
				Q2_reg <= Q2_next;
				state_reg <= state_next;
			end if;
		end if;
	end process;
	
	-- Next state logic Combinational logic process
	process(Q0_reg, Q1_reg, Q2_reg, x_reg, state_reg, start, coeff)
		variable coeff_q1 : sfixed (Q_INT_BITS downto -Q_FRAC_BITS+1);
		variable x_min_q2 : sfixed (Q_INT_BITS-1 downto -Q_FRAC_BITS);
		variable Q0_next_calc : sfixed(Q_INT_BITS-1 downto -Q_FRAC_BITS);
		variable count : natural := BLOCK_SIZE;
	begin
		Q0_next <= Q0_reg;
		Q1_next <= Q1_reg;
		Q2_next <= Q2_reg;
		ready   <= '0';
		case state_reg is
			when idle => 
				if start = '1' then 
					state_next <= get_x;
				else 
					state_next <= idle;
				end if;
				ready <= '1';
			when get_x =>
				state_next <= update;
				Q1_next <= Q0_reg;
				coeff_q1 := resize(coeff * Q1_reg, coeff_q1);
				x_min_q2 := resize(x_reg - Q2_reg, x_min_q2);
				Q0_next_calc := resize(coeff_q1 + x_min_q2, Q0_next_calc);
				count := count - 1;
				Q0_next <= Q0_next_calc;
			when update => 
				Q2_next  <= Q1_reg;
				if count /= 0 then 
					state_next <= get_x;
				else 
					state_next <= idle;
				end if;
		end case;
	end process;
	
	-- Output assignment
	Q0 <= Q0_reg;
	Q1 <= Q1_reg;
	Q2	<=	Q2_reg;
	
end rtl;
