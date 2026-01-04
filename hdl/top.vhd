library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity top is
port(
    clk     : in std_logic;
    nRst    : in std_logic;
    key0    : in std_logic;
    key1    : in std_logic;

    -- bus SPI
    nCS:     		buffer std_logic;		-- chip select
    SCLK:    		buffer std_logic;		-- clock SPI
    SDIO:    		in  std_logic;

    mux_disp      : buffer std_logic_vector(7 downto 0);
    disp          : buffer std_logic_vector(7 downto 0)
    );
end entity;

architecture struct of top is

    signal tic_1ms_t      : std_logic;
    signal tic_1s_t       : std_logic;
    signal tic_2s_t       : std_logic;
    signal tic_4s_t       : std_logic;
    signal tic_6s_t       : std_logic;
    signal tic_8s_t       : std_logic;

    signal tic_elegido_t  : std_logic;
    signal recien_medido_t  : std_logic;

    signal key0_pulse_t   : std_logic;
    signal key1_pulse_t   : std_logic;

    signal dato_rd_t       : std_logic_vector(15 downto 0);

    signal modo_unidad_t   : std_logic_vector(1 downto 0);
    signal modo_refresh_t   : std_logic_vector(1 downto 0);
    signal temp_BCD_t      : std_logic_vector(11 downto 0);
    signal signo_t   	   : std_logic;

    
begin

    TIMER: entity work.timer(rtl)
    port map(
        clk => clk,
        nRst => nRst,
        tic_1ms => tic_1ms_t,
        tic_1s => tic_1s_t,
        tic_2s => tic_2s_t,
        tic_4s => tic_4s_t,
        tic_6s => tic_6s_t,
        tic_8s => tic_8s_t
        );
    
    master_SPI: entity work.master_spi_3_hilos(rtl)                
    port map(
        clk      => clk, 
        nRst     => nRst, 
	start    => tic_elegido_t,
        dato_rd  => dato_rd_t, 
        nCS      => nCS, 
        SCLK     => SCLK,
        SDIO     => SDIO
        );
        
    CNTL_PULSADORES: entity work.control_pulsadores(rtl)
    port map(
        clk => clk,
        nRst => nRst,
        key0 => key0,
        key1 => key1,
        key0_pulse => key0_pulse_t,
        key1_pulse => key1_pulse_t
        );
        
    INTF_PULSADORES: entity work.interfaz_pulsadores(rtl)
    port map(
        clk => clk,
        nRst => nRst,
        key0 => key0_pulse_t,
        key1 => key1_pulse_t,
        dato_rd => dato_rd_t,
        tic_2s => tic_2s_t,
        tic_4s => tic_4s_t,
        tic_6s => tic_6s_t,
        tic_8s => tic_8s_t,
        tic_elegido => tic_elegido_t,
        temp_BCD => temp_BCD_t,
        signo => signo_t,
        modo_unidad => modo_unidad_t,
	modo_refresh => modo_refresh_t,
	recien_medido => recien_medido_t
        );

    DISPLAY: entity work.displays(rtl)
    port map(
        clk => clk,
        nRst => nRst,
        tic_1ms => tic_1ms_t,
        tic_1s => tic_1s_t,
        temp_bcd => temp_BCD_t,
        temp_sig => signo_t,
        unidad_temp => modo_unidad_t,
	sel_refresh => modo_refresh_t,
	recien_medido => recien_medido_t,
        mux_disp => mux_disp,
        disp => disp
        );
        
end architecture struct;
    