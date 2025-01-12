library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.math_real.all;
use std.textio.all;

entity Goertzel_top_tb is
end Goertzel_top_tb;

architecture sim of Goertzel_top_tb is

    constant clk_hz : integer := 50e6;
    constant clk_period : time := 1 sec / clk_hz; -- Clock of 10 ns period

    constant sample_clk_hz : integer := 32e3;
    constant sample_clk_period : time := 1 sec / sample_clk_hz; -- Clock of 10 ns period

    constant DATA_WIDTH : integer := 16;
    constant BLOCK_SIZE : integer := 640;
    constant COEFF_697      : real    := 1.98113868088715; -- For frequency 697 Hz
    constant COEFF_770      : real    := 1.97537668119028; -- For frequency 770 Hz
    constant COEFF_852      : real    := 1.96885313617978;
    constant COEFF_941      : real    := 1.96530655866142;
    constant COEFF_1209     : real    := 1.94006250638909;
    constant COEFF_1336     : real    := 1.93014734462309;
    constant COEFF_1477     : real    := 1.91388067146442;

    -- Constant for determining the Q format (obtained from MATLAB Fixed-point tools)
    constant X_INT_BITS  : integer   := 2;
    constant X_FRAC_BITS : integer   := 14;

    -- Clock for generating sample
    signal sample_clk   : std_logic := '1';

    -- Signals for interfacing with the design
    -- Input port
    signal rst	        : std_logic := '1';
    signal clk          : std_logic := '1';
    signal in_ready     : std_logic;
    signal in_valid     : std_logic := '0';
    signal DTMF_sig     : std_logic_vector(DATA_WIDTH - 1 downto 0);
    -- Output port
    signal power_697    : std_logic_vector(DATA_WIDTH  downto 0);
    signal power_770    : std_logic_vector(DATA_WIDTH  downto 0);    
    signal power_852    : std_logic_vector(DATA_WIDTH  downto 0);
    signal power_941    : std_logic_vector(DATA_WIDTH  downto 0);
    signal power_1209    : std_logic_vector(DATA_WIDTH  downto 0);
    signal power_1336    : std_logic_vector(DATA_WIDTH  downto 0);
    signal power_1477    : std_logic_vector(DATA_WIDTH  downto 0);

    signal out_ready    : std_logic := '0';
    signal out_valid    : std_logic;

begin
    -- Component instantiation
    GOERTZEL_DUT : entity work.Goertzel_top(rtl)
    generic map (
        DATA_WIDTH => DATA_WIDTH,
        BLOCK_SIZE => BLOCK_SIZE
    )
    port map (
        clk => clk,
        rst => rst,

        -- Input bus signals
        in_ready => in_ready,
        in_valid => in_valid,
        DTMF_sig => DTMF_sig,

        -- Output bus signals
        out_ready => out_ready,
        out_valid => out_valid,

        power_697 => power_697, 
        power_770 => power_770, 
        power_852 => power_852, 
        power_941 => power_941, 
        power_1209 => power_1209,
        power_1336 => power_1336,
        power_1477 => power_1477
    );
    -- Generate clock process
    clk <= not clk after clk_period / 2;
    sample_clk <= not sample_clk after sample_clk_period/2;

    RST_PROC: process  
    begin 
        rst <= '0' after 3 ns;
        wait;
    end process;

    DATA_READ: process
        file data_file    : text open read_mode is "dtmf_#.txt";
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
            DTMF_sig <= to_std_logic_vector(to_sfixed(x_var, X_INT_BITS-1, -X_FRAC_BITS));
            in_valid <= '1';
            wait for clk_period;
            in_valid <= '0';
            wait for sample_clk_period;
        end loop;
        file_close(data_file);

        if out_ready = '1' and out_valid = '1' then
            out_ready <= '0';
        end if;

        wait;
    end process;

end architecture;