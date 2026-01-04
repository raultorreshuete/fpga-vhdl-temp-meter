-- Controlador de displays para el medidor de temperatura y humedad
--
-- Controla 8 displays de 7 segmentos multiplexandolos en el tiempo
-- Tiene 4 modos de funcionamiento, que se seleccionan mediante comandos del teclado
--
-- Recibe comandos del controlador de teclado:
-- E: incrementa modo_disp (0->1->2->3->1...)
--
-- Muestra los datos en el display en funcion del modo de operacion (modo_disp):
-- modo 0: muestra solo el reloj
-- modo 1: muestra solo la temperatura
-- modo 2: muestra solo la humedad relativa
-- modo 3: muestra los 3 datos. Cada dato se visualiza durante 16 segundos. La
-- temperatura y la humedad relativa entran por la parte izquierda de los displays
-- durante 8 seg. y permanecen fijos durante otros 8. La temperatura se visualiza como
-- en el modo 0.
--
-- Los displays se multiplexan en el tiempo. 
-- Los digitos no significativos de la temperatura y humedad relativa, asi como las
-- decenas de hora del reloj (cuando es 0) no se visualizan.
-- En el modo de programacion del reloj los digitos activos parpadean 4 veces por segundo.
--
--    Designer: DTE
--    Versi√≥n: 2.0
--    Fecha: 08-01-2018 


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity displays is port(
    clk           : in std_logic;
    nRst          : in std_logic;
    tic_1ms       : in std_logic;
    tic_1s        : in std_logic;
    temp_bcd      : in std_logic_vector(11 downto 0);
    temp_sig      : in std_logic;
    unidad_temp   : in std_logic_vector(1 downto 0);
    sel_refresh   : in std_logic_vector(1 downto 0);
    recien_medido : in std_logic;

    mux_disp      : buffer std_logic_vector(7 downto 0);
    disp          : buffer std_logic_vector(7 downto 0)
    );  
end entity;

architecture rtl of displays is

  signal dig_activo 		: std_logic_vector(3 downto 0);
  signal temp_bcd_c 	 	: std_logic_vector(11 downto 0);
  signal temp 		 	: std_logic_vector(31 downto 0);
  signal temp_refresh    	: std_logic_vector(31 downto 0);

  signal unidad			: std_logic_vector(3 downto 0);
  signal refresh		: std_logic_vector(3 downto 0);
  signal periodo		: std_logic_vector(3 downto 0);

  signal contador_refresh : std_logic_vector(9 downto 0);

  signal temp_recien_leida : std_logic;

begin

 -- Preparacion de los datos para el display
 -- Eliminacion de ceros no significativos

 temp_bcd_c <= X"E"&"111" & temp_sig & temp_bcd(3 downto 0) when temp_bcd(11 downto 4) = 0 else -- elim. ceros centenas y decenas
               "111" & temp_sig & temp_bcd(7 downto 0) when temp_bcd(11 downto 8) = 0 else -- elim. ceros centenas
	           temp_bcd;


 -- Indicador de que se ha recibido buena medida
  process(clk, nRst)
  begin
    if nRst = '0' then
      refresh <= X"E"; -- Inicia blanco 
      contador_refresh <= (others => '0');
    elsif clk'event and clk = '1' then
      if recien_medido = '1' then
	refresh <= X"0";  -- Cuando medida nueva -> '0'
	contador_refresh <= contador_refresh + 1;
      end if;
      if tic_1ms = '1' then
        if (contador_refresh /= 0)  and (contador_refresh < 999) then
          contador_refresh <= contador_refresh + 1; 
        else
	  refresh <= X"E";
          contador_refresh <= (others => '0');
        end if;
      end if;
    end if;
  end process;


 unidad <= X"C" when unidad_temp = "00" else
	   X"D" when unidad_temp = "01" else
	   X"B" when unidad_temp = "10" else
	   X"C";
	
 periodo <= X"2" when sel_refresh = "00" else
	    X"4" when sel_refresh = "01" else
	    X"6" when sel_refresh = "10" else
	    X"8";

-- Presentacion
 temp <= refresh&periodo&X"E"&temp_bcd_c&X"E"&unidad; -- A: blanco;
 
 -- Activacion de los catodos
 catodos: process(clk, nRst)
  begin
    if nRst = '0' then
      mux_disp <= (0=> '0',others => '1');
    elsif clk'event and clk = '1' then
      if tic_1ms = '1' then
        mux_disp <= mux_disp(6 downto 0) & mux_disp(7);
      end if;
    end if;
  end process catodos;
 
  -- Multiplexion de los digitos
 dig_activo <= temp(3 downto 0)   when mux_disp(0) = '0' else
               temp(7 downto 4)   when mux_disp(1) = '0' else
               temp(11 downto 8)  when mux_disp(2) = '0' else
               temp(15 downto 12) when mux_disp(3) = '0' else
               temp(19 downto 16) when mux_disp(4) = '0' else
               temp(23 downto 20) when mux_disp(5) = '0' else
               temp(27 downto 24) when mux_disp(6) = '0' else
               temp(31 downto 28);
  
  -- BCD a 7 segmentos
  process(dig_activo) --punto_abcdefg
  begin
    case(dig_activo) is
      when X"0" => disp <= "01111110";
      when X"1" => disp <= "00110000";
      when X"2" => disp <= "01101101";
      when X"3" => disp <= "01111001";
      when X"4" => disp <= "00110011";
      when X"5" => disp <= "01011011";
      when X"6" => disp <= "01011111";
      when X"7" => disp <= "01110000";
      when X"8" => disp <= "01111111";
      when X"9" => disp <= "01110011";
     -- when X"A" => disp <= "00000000"; -- en blanco (+)
     -- when X"B" => disp <= "00000001"; -- signo -
      --when X"C" => disp <= "01001110"; -- C
      --when X"D" => disp <= "01100011"; -- ∫(para kelvin)
     -- when X"E" => disp <= "11111111"; -- 
      --when X"F" => disp <= "01000111"; -- F

      when X"A" => disp <= "01110111"; -- A
      when X"B" => disp <= "01000111"; -- F
      when X"C" => disp <= "01001110"; -- C
      when X"D" => disp <= "01100011"; -- ∫(para kelvin)
      when X"E" => disp <= "00000000"; -- en blanco (+)
      when X"F" => disp <= "00000001"; -- signo -

      when others => null;

    end case;
  end process;

end rtl;