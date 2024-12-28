library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use std.textio.all;

entity goertzel_calc_registered_v4_tb is
end goertzel_calc_registered_v4_tb;

architecture sim of goertzel_calc_registered_v4_tb is

    constant clk_hz : integer := 50e6;
    constant clk_period : time := 1 sec / clk_hz; -- Clock of 10 ns period

    constant sample_clk_hz : integer := 32e3;
    constant sample_clk_period : time := 1 sec / sample_clk_hz; -- Clock of 10 ns period

    -- Constants
    constant COEFF_INT_BITS : integer := 2;
    constant COEFF_FRAC_BITS : integer := 14;
    constant Q_INT_BITS : integer := 11;
    constant Q_FRAC_BITS : integer := 5;
    constant X_INT_BITS : integer := 2;
    constant X_FRAC_BITS : integer := 14;

    -- Signals for generating sample
    signal sample_clk   : std_logic := '0';

    -- Signals for interfacing with the design
    signal start, rst	: std_logic := '1';
    signal clk          : std_logic := '0';
    signal ready        : std_logic;
    -- Fixed-point format specifier: (sign).(integer).(fraction)
    signal x_in			:  sfixed((X_INT_BITS-1) downto -X_FRAC_BITS); -- Format: 1.1.14
    signal coeff		:  sfixed((COEFF_INT_BITS-1) downto -COEFF_FRAC_BITS); -- Format: 1.1.14
    signal Q0, Q1, Q2	:  sfixed(Q_INT_BITS-1 downto -Q_FRAC_BITS); -- Format: 1.10.5

begin
    -- Component instantiation
    DUT : entity work.goertzel_calc_registered_v4(rtl)
    generic map (
        COEFF_INT_BITS => COEFF_INT_BITS,
        COEFF_FRAC_BITS => COEFF_FRAC_BITS,
        Q_INT_BITS => Q_INT_BITS,
        Q_FRAC_BITS => Q_FRAC_BITS,
        X_INT_BITS => X_INT_BITS,
        X_FRAC_BITS => X_FRAC_BITS
    )
    port map (
        clk => clk,
        start => start,
        rst => rst,
        ready => ready,
        x_in => x_in,
        coeff => coeff,
        Q0   => Q0,
        Q1   => Q1,
        Q2   => Q2
    );
    
    -- Generate clock process
    clk <= not clk after clk_period / 2;
    sample_clk <= not sample_clk after sample_clk_period/2;

    process is 
    begin 
        rst <= '0' after 3 ns;
        wait;
    end process;

    DATA_READ: process
        file data_file    : text open read_mode is "dtmf_signal.txt";
        variable x_var    : real := 0.0;
        variable line_in  : line;
    begin
--        x_in <= to_sfixed(0.000000000000000, x_in);
--        wait for 60 ns;
--        x_in <= to_sfixed(0.727443130630800, x_in);
--        wait;
        while not endfile(data_file) loop
            readline(data_file, line_in);
            read(line_in, x_var);
            x_in <= to_sfixed(x_var, x_in);
            wait for clk_period;
        end loop;
    end process;

    STIMULUS : process
        variable coeff_var : real := 1.924910472907295;
    begin
        coeff <= to_sfixed(coeff_var, coeff);
        wait;
    end process;


end architecture;