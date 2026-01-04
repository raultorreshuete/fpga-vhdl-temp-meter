library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity tb_control_pulsadores is
end entity;

architecture test of tb_control_pulsadores is

  signal clk         : std_logic := '0';
  signal nRst        : std_logic := '0';
  signal key0        : std_logic := '1';
  signal key1        : std_logic := '1';
  signal key0_pulse  : std_logic;
  signal key1_pulse  : std_logic;

  constant CLK_PERIOD : time := 10 ns;

  -- Instancia del DUT
  component control_pulsadores
    port(
      clk           : in std_logic;
      nRst          : in std_logic;
      key0          : in std_logic;
      key1          : in std_logic;
      key0_pulse    : buffer std_logic;
      key1_pulse    : buffer std_logic
    );
  end component;

begin

  -- Instanciación
  dut: entity work.control_pulsadores(rtl)
    port map (
      clk         => clk,
      nRst        => nRst,
      key0        => key0,
      key1        => key1,
      key0_pulse  => key0_pulse,
      key1_pulse  => key1_pulse
    );

  -- Generación de reloj
  clk_process : process
  begin
    while true loop
      clk <= '0';
      wait for CLK_PERIOD / 2;
      clk <= '1';
      wait for CLK_PERIOD / 2;
    end loop;
  end process;

  -- Estímulos de prueba
  stim_proc : process
  begin
    -- Reset inicial
    wait for 20 ns;
    nRst <= '1';

    -- Espera estable
    wait for 40 ns;

    -- Pulsación limpia en KEY0
    key0 <= '0'; wait for 200 ns;
    key0 <= '1'; wait for 50 ns;

    -- Pulsación con rebote en KEY1
    key1 <= '0'; wait for 10 ns;
    key1 <= '1'; wait for 5 ns;
    key1 <= '0'; wait for 10 ns;
    key1 <= '1'; wait for 5 ns;
    key1 <= '0'; wait for 200 ns;
    key1 <= '1';

    -- Espera final
    wait for 100 ns;
    assert false report "Simulación finalizada" severity failure;
  end process;

end test;
