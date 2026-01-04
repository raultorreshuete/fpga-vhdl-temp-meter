-- Control de pulsadores Key0 y Key1 de la placa
--
--
--
--    Designer: DTE
--    Versión: 1.0
--    Fecha: 24-11-2016

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity control_pulsadores is 
port(
    clk           : in std_logic;
    nRst          : in std_logic;
    key0          : in std_logic;      --pulsador de tiempo de refresco
    key1          : in std_logic;      --pulsador de tipo de temperatura
    key0_pulse     : buffer std_logic; --pulso limpio y sincronizado
    key1_pulse     : buffer std_logic  --pulso limpio y sincronizado

    );  
end entity;

architecture rtl of control_pulsadores is

--Señales de sincornización del reloj:
	signal key0_sync_0, key0_sync_1 : std_logic := '1';
	signal key1_sync_0, key1_sync_1 : std_logic := '1';

--Señales de estado anterior
	signal key0_last : std_logic := '1';
	signal key1_last : std_logic := '1';

--Señales de debounced
	signal key0_debounced : std_logic := '1';
	signal key1_debounced : std_logic := '1';

-- Historial de señales para antirrebote (3 bits por pulsador)
	signal key0_hist : std_logic_vector(2 downto 0) := (others => '1');
	signal key1_hist : std_logic_vector(2 downto 0) := (others => '1');

begin

  -- Sincronización con el reloj:
  process(clk)
  begin
    if nRst = '0' then
      key0_sync_0 <= '1';
      key0_sync_1 <= '1';
      key1_sync_0 <= '1';
      key1_sync_1 <= '1';
    elsif clk'event and clk = '1' then
	key0_sync_0 <= key0;         --2 flipflops para key 0
	key0_sync_1 <= key0_sync_0;                            --Se puede usar uno pero se implementan 2 por razones de metaestabilidad

	key1_sync_0 <= key1;	     --2 flipflops para key 1
	key1_sync_1 <= key1_sync_0;
    end if;
  end process;

  -- Filtro de rebotes
  process(clk)
  begin
    if nRst = '0' then
      key0_debounced <= '1';
      key1_debounced <= '1';
    elsif clk'event and clk = '1' then
	key0_hist <= key0_hist(1 downto 0) & key0_sync_1;
	key1_hist <= key1_hist(1 downto 0) & key1_sync_1;

	--Filtra rebotes del botón esperando que la señal esté igual 3 ciclos consecutivos antes de considerarla válida.
        --Lo malo de este método es que no nos asegura al 100% que la pulsacion dure 3 ciclos pero no suele ser problema
	--Una pulsacion rapida por nuestra parte dura entre 5ms y 10ms q son 1000 veces mas qu 3 ciclos de reloj asi q no deberia ser problema
	
	if key0_hist = "000" then
	  key0_debounced <= '0';
        elsif key0_hist = "111" then
	  key0_debounced <= '1';
	end if;

	if key1_hist = "000" then
	  key1_debounced <= '0';
        elsif key1_hist = "111" then
	  key1_debounced <= '1';
	end if;          
    end if;
  end process;

  --Detección de flanco de bajada (pulsación)
  process(clk)
  begin
    if nRst = '0' then
      key0_pulse <= '1';
      key1_pulse <= '1';
      key0_last <= '1';
      key1_last <= '1';
    elsif clk'event and clk = '1' then
	if key0_last = '1' and key0_debounced = '0' then
	  key0_pulse <= '0';
	else
	  key0_pulse <= '1';
	end if;

	if key1_last = '1' and key1_debounced = '0' then
	  key1_pulse <= '0';
	else
	  key1_pulse <= '1';
	end if;

    key0_last <= key0_debounced;
    key1_last <= key1_debounced;

  end if;
  end process;

end rtl;
