library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity master_spi_3_hilos is
port(nRst:     in     std_logic;
     clk:      in     std_logic;		-- 50 MHz
     -- Ctrl_SPI
     start:    in     std_logic;			-- Orden de ejecución (si ready = 1 ) => ready  <= 0 hasta fin, cuando ready <= 1
     dato_rd:  buffer std_logic_vector(15 downto 0);	-- valor del byte leido

     -- bus SPI
     nCS:      buffer std_logic;		-- chip select
     SCLK:     buffer std_logic;		-- clock SPI
     SDIO:     in  std_logic);			-- Linea de datos bidireccional
     
end entity;

architecture rtl of master_spi_3_hilos is
 --Reloj del bus
 signal cnt_SCLK:     std_logic_vector(2 downto 0);
 signal fdc_cnt_SCLK: std_logic;
 signal SCLK_posedge: std_logic;

 constant SCLK_LH: natural := 5; 
 
 -- Contador de bits y bytes transmitidos
 signal cnt_bits_SCLK: std_logic_vector(4 downto 0);

 -- Registro de recepcion
 signal reg_SPI: std_logic_vector(15 downto 0);

 -- Para el control
 signal fin: std_logic;


begin
  -- Generacion de nCS:
  process(nRst, clk)
  begin
    if nRst = '0' then
      nCS <= '1';

    elsif clk'event and clk = '1' then
      if start = '1' and nCS = '1' then  	--Si nCs ya está a nivel bajo significa que hay una transferencia en marcha
        nCS <= '0';

      elsif fin = '1' then
        nCS <= '1';

      end if;
    end if;
  end process;


  -- Generacion de SCLK:
  process(nRst, clk)
  begin
    if nRst = '0' then
      cnt_SCLK <= (1 => '1', others => '0');
      SCLK <= '1';

    elsif clk'event and clk = '1' then
      if nCS = '1' then 
        cnt_SCLK <= (1 => '1', others => '0');
        SCLK <= '1';

      elsif fdc_cnt_SCLK = '1' then                --No se tiene en cuenta el CS setup time ya que el periodo del reloj es mucho mayor
        SCLK <= not SCLK;                           --y por lo tanto cuando nCs se pone a nivel bajo SCLK está medio periodo en nivel alto
        cnt_SCLK <= (0 => '1', others => '0');

      else
        cnt_SCLK <= cnt_SCLK + 1;

      end if;
    end if;
  end process;

  fdc_cnt_SCLK <= '1' when cnt_SCLK = SCLK_LH else
                  '0';

  SCLK_posedge <= SCLK when cnt_SCLK = 1 else
                  '0'; 

  -- Cuenta bits y bytes (empieza a contar los bits desde el momento en el que se activa nCS):
  process(nRst, clk)
  begin
    if nRst = '0' then
      cnt_bits_SCLK <= (others => '0');
      
    elsif clk'event and clk = '1' then  
      if SCLK_posedge = '1' then            --Cuenta el número de bits intercambiado en la transferencia en los niveles altos de SCLK
        cnt_bits_SCLK <= cnt_bits_SCLK + 1;

      elsif nCS = '1' then
        cnt_bits_SCLK <= (others => '0');

      end if;
    end if;
  end process;

  -- Registro de datos
  process(clk, nRst)
  begin
    if nRst = '0' then
      reg_SPI <= (others => '0');

    elsif clk'event and clk = '1' then
      if SCLK_posedge = '1' and nCS = '0' then
        reg_SPI(15 downto 1) <= reg_SPI(14 downto 0);
	  if SDIO = '0' or SDIO = '1' then
            reg_SPI(0) <= SDIO;
	  else
            reg_SPI(0) <= '0';
	  end if;
      end if;
    end if;
  end process;

   -- Salidas
  dato_rd <= reg_SPI when nCS = '1';

  fin <= '1' when cnt_bits_SCLK = "10000" else 
	 '0';
 
end rtl;
