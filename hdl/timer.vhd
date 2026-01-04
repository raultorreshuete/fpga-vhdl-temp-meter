-- Temporizador para MEDTH
--
-- Genera las señales de temporizacion para el resto de circuitos. Todas son tics de un periodo
-- de reloj:
-- tic_1ms
-- tic_5ms
-- tic_025s
-- tic_1s
-- Genericos:
---- DIV_125ms (divisor para generar 125 ms a partir del tic de 5 ms)
---- DIV_1ms (divisor para generar tics de 1 ms a partir del reloj de 100 MHz)
---- Los valores por defecto son para sintesis
--
--    Designer: DTE
--    Versión: 1.0
--    Fecha: 24-11-2016

library ieee;
use ieee.std_logic_1164.all;

use ieee.std_logic_unsigned.all;

entity timer is 
generic(
    DIV_1s : natural := 999;	-- 999
    DIV_1ms : natural := 49999   		--99999
   );
port(
    clk           : in std_logic;
    nRst          : in std_logic;
    tic_1ms       : buffer std_logic;
    tic_1s        : buffer std_logic;
    tic_2s        : buffer std_logic;
    tic_4s        : buffer std_logic;
    tic_6s        : buffer std_logic;
    tic_8s        : buffer std_logic

    );  
end entity;

architecture rtl of timer is
  signal cnt_div_1ms : std_logic_vector(20 downto 0);
  signal cnt_div_1s : std_logic_vector(9 downto 0);
  signal cnt_div_2s : std_logic_vector(1 downto 0);
  signal cnt_div_4s : std_logic_vector(1 downto 0);
  signal cnt_div_6s : std_logic_vector(1 downto 0);
  signal cnt_div_8s : std_logic_vector(1 downto 0);

begin
  
 -- generación del tic de 1 ms
 divisor_1ms: process(clk, nRst)
  begin
    if nRst = '0' then
      cnt_div_1ms <= (others => '0');
    elsif clk'event and clk = '1' then
      if tic_1ms = '1' then
        cnt_div_1ms <= (others => '0');
      else
        cnt_div_1ms <= cnt_div_1ms + 1;
      end if;
    end if;
  end process divisor_1ms;
  tic_1ms <= '1' when cnt_div_1ms = DIV_1ms else '0';

    -- generación del tic de 1s
 divisor_1s: process(clk, nRst)
  begin
    if nRst = '0' then
      cnt_div_1s <= (others => '0');
    elsif clk'event and clk = '1' then
      if tic_1s = '1' then
        cnt_div_1s <= (others => '0');
      elsif tic_1ms = '1' then
        cnt_div_1s <= cnt_div_1s + 1;
      end if;
    end if;
  end process divisor_1s; 
  tic_1s <= '1' when cnt_div_1s = DIV_1S and tic_1ms = '1' else '0';

    -- generación del tic de 2s
 divisor_2s: process(clk, nRst)
  begin
    if nRst = '0' then
      cnt_div_2s <= (others => '0');
    elsif clk'event and clk = '1' then
      if tic_2s = '1' then
        cnt_div_2s <= (others => '0');
      elsif tic_1s = '1' then
        cnt_div_2s <= cnt_div_2s + 1;
      end if;
    end if;
  end process divisor_2s; 
  tic_2s <= '1' when cnt_div_2s = 1 and tic_1s = '1' else '0';

    -- generación del tic de 4s
 divisor_4s: process(clk, nRst)
  begin
    if nRst = '0' then
      cnt_div_4s <= (others => '0');
    elsif clk'event and clk = '1' then
      if tic_4s = '1' then 
	cnt_div_4s <= (others => '0');
      elsif tic_2s = '1' then
        cnt_div_4s <= cnt_div_4s + 1;
      end if;
    end if;
  end process divisor_4s; 
  tic_4s <= '1' when cnt_div_4s = 1 and tic_2s = '1' else '0';

    -- generación del tic de 6s
 divisor_6s: process(clk, nRst)
  begin
    if nRst = '0' then
      cnt_div_6s <= (others => '0');
    elsif clk'event and clk = '1' then
      if tic_6s = '1' then
        cnt_div_6s <= (others => '0');
      elsif tic_2s = '1' then
        cnt_div_6s <= cnt_div_6s + 1;
      end if;
    end if;
  end process divisor_6s; 
  tic_6s <= '1' when cnt_div_6s = 2 and tic_2s = '1' else '0';

    -- generación del tic de 8s
 divisor_8s: process(clk, nRst)
  begin
    if nRst = '0' then
      cnt_div_8s <= (others => '0');
    elsif clk'event and clk = '1' then
      if tic_8s = '1' then
        cnt_div_8s <= (others => '0');
      elsif tic_2s = '1' then
        cnt_div_8s <= cnt_div_8s + 1;
      end if;
    end if;
  end process divisor_8s; 
  tic_8s <= '1' when cnt_div_8s = 3 and tic_2s = '1' else '0';


end rtl;