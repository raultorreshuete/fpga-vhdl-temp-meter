-- Interfaz de pulsadores Key0 y Key1 de la placa
--
--
--
--    Designer: DTE
--    Versión: 1.0
--    Fecha: 24-11-2016

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity interfaz_pulsadores is
    port(
        clk          : in std_logic;
        nRst         : in std_logic;
        key0         : in std_logic;
        key1         : in std_logic;
        dato_rd      : in std_logic_vector(15 downto 0);

    	tic_2s        : in std_logic;
    	tic_4s        : in std_logic;
    	tic_6s        : in std_logic;
   	tic_8s        : in std_logic;

   	tic_elegido  : buffer std_logic;

        temp_BCD     : buffer std_logic_vector(11 downto 0); -- Para los displays
        signo        : buffer std_logic;
        modo_unidad  : buffer std_logic_vector(1 downto 0);
	modo_refresh : buffer std_logic_vector(1 downto 0);
	recien_medido: buffer std_logic

    );
end entity;

architecture rtl of interfaz_pulsadores is

    -- FSM
    type estado_key0 is (REFRESH_2S, REFRESH_4S, REFRESH_6S, REFRESH_8S);
    type estado_key1 is (CELSIUS, KELVIN, FARENHEIT);

    signal refresh         : estado_key0;
    signal unidad          : estado_key1;

    -- Intermedios y resultados
    signal temp_celsius    : std_logic_vector(7 downto 0);
    signal signo_celsius   : std_logic;

    signal farenheit29     : std_logic_vector(12 downto 0);
    signal farenheit29_16  : std_logic_vector(8 downto 0);
    signal temp_farenheit  : std_logic_vector(8 downto 0);
    signal signo_farenheit : std_logic;

    signal temp_kelvin     : std_logic_vector(8 downto 0);
    signal temp_salida     : std_logic_vector(8 downto 0);

    -- Para convertir el valor seleccionado a BCD
    signal t_DU		   : std_logic_vector(8 downto 0);
    signal t_sum_salida      : std_logic_vector(4 downto 0);
    signal t_carry_BCD	   : std_logic_vector(1 downto 0);

    signal t_centenas_BCD    : std_logic_vector(2 downto 0);
    signal t_decenas_BCD     : std_logic_vector(3 downto 0);
    signal t_unidades_BCD    : std_logic_vector(3 downto 0);

begin

    -- FSM DE LOS REFRESCOS --
    process(clk, nRst)
    begin
        if nRst = '0' then
            refresh <= REFRESH_4S;
        elsif clk'event and clk = '1' then
            if key0 = '0' then
                case refresh is
                    when REFRESH_2S => refresh <= REFRESH_4S;
                    when REFRESH_4S => refresh <= REFRESH_6S;
                    when REFRESH_6S => refresh <= REFRESH_8S;
                    when REFRESH_8S => refresh <= REFRESH_2S;
                end case;
            end if;
        end if;
    end process;

    -- FSM DE LAS UNIDADES --
    process(clk, nRst)
    begin
        if nRst = '0' then
            unidad <= CELSIUS;
        elsif clk'event and clk = '1' then
            if key1 = '0' then
                case unidad is
                    when CELSIUS   => unidad <= KELVIN;
                    when KELVIN    => unidad <= FARENHEIT;
                    when FARENHEIT => unidad <= CELSIUS;
                end case;
            end if;
        end if;
    end process;

    -- Conversiones desde Celsius a Kelvin y Farenheit
    temp_celsius <= dato_rd(14 downto 7) when dato_rd(15) = '0' else
                    (not dato_rd(14 downto 7)) + 1;

    signo_celsius <= dato_rd(15);

    farenheit29 <= ("00000" & temp_celsius) +         -- *1
                   ("00" & temp_celsius & "000") +     -- *8
                   ("000" & temp_celsius & "00") +     -- *4
                   ('0' & temp_celsius & "0000");      -- *16

    farenheit29_16 <= farenheit29(12 downto 4);

    process(clk, nRst)
    begin
        if nRst = '0' then
            temp_farenheit <= (others => '0');
        elsif clk'event and clk = '1' then
          if signo_celsius = '0' then
              temp_farenheit <= farenheit29_16 + 32;
          else
              if farenheit29_16 < 32 then
                  temp_farenheit <= 32 - farenheit29_16;
              else
                  temp_farenheit <= farenheit29_16 - 32;
              end if;
          end if;
	end if;
    end process;

    signo_farenheit <= '1' when temp_celsius > 18 and signo_celsius = '1' else
                       '0';

    temp_kelvin <= ('0' & temp_celsius) + 273 when signo_celsius = '0' else
                   273 - ('0' & temp_celsius);


    -- Selección de salida según unidad
    process(clk, nRst)
    begin
        if nRst = '0' then
            temp_salida <= (others => '0');
	    signo <= '0';
        elsif clk'event and clk = '1' then
          case unidad is
              when CELSIUS =>
                  temp_salida <= "0" & temp_celsius;
                  signo       <= signo_celsius;

              when KELVIN =>
                  temp_salida <= temp_kelvin;
                  signo       <= '0';

              when FARENHEIT =>
                  temp_salida <= temp_farenheit;
                  signo       <= signo_farenheit;

              when others =>
                  temp_salida <= "0" & temp_celsius;
                  signo       <= signo_celsius;
          end case;
	end if;
    end process;


    -- Conversiones de temperaturas a BCD

    -- Centena: Los dos bits de mayor peso deben sumar 96 y alguno de los 
    -- de peso >= 4 restantes deben valer 1

    t_centenas_BCD <= "100" when temp_salida >= 400 else  -- 500
                      "011" when temp_salida >= 300 else  -- 300
                      "010" when temp_salida >= 200 else  -- 200
                      "001" when temp_salida >= 100 else  -- 100
                      "000";

    -- Decenas + Unidades en BN
    t_DU <= temp_salida - 400 when t_centenas_BCD = "100" else
            temp_salida - 300 when t_centenas_BCD = "011" else
            temp_salida - 200 when t_centenas_BCD = "010" else
            temp_salida - 100 when t_centenas_BCD = "001" else
            temp_salida;


    -- bit 6 -> d64 (4), bit 5 -> d32 (2), bit 4 -> d16 (6), bit 3 -> d8, bit 2, 1, 0 -> d4, d2, d1
    -- Sumo las unidades en binario:
    --          ((3) -> 8 + (6) -> 4 + (1:0) -> 3) +       ((4) -> 6)       +  ((2) -> 4 + (5) -> 2)
    t_sum_salida <= ('0'&t_DU(3)&t_DU(6)&t_DU(1 downto 0))  + ("00"&t_DU(4)&t_DU(4)&'0') + ("00"&t_DU(2)&t_DU(5)&'0');

    -- Calculo el acarreo para las decenas:
    t_carry_BCD <= "00" when t_sum_salida < 10 else
                 "01" when t_sum_salida < 20 else
                 "10";

    -- Calculo las unidades en decimal
    t_unidades_BCD <= t_sum_salida(3 downto 0) when t_carry_BCD = 0 else
                      t_sum_salida(3 downto 0) + 6  when t_carry_BCD = 1 else
                      t_sum_salida(3 downto 0) + 12;

    -- Calculo las decenas (son <= 9)
    -- bit 6 -> d64 (6), bit 5 -> d32 (3), bit 4 -> d16 (1), resto 0
    --              ((6) -> 6 + (4) -> 1)  +     ((5) -> 3)     + acarreo unidades
    t_decenas_BCD <= ('0'&t_DU(6)&t_DU(6)&t_DU(4)) + ("00"&t_DU(5)&t_DU(5)) + t_carry_BCD;

    temp_BCD <= '0'&t_centenas_BCD & t_decenas_BCD & t_unidades_BCD;


    -- Conversión de tipo enumerado a std_logic_vector para el puerto
    process(clk, nRst)
    begin
      if nRst = '0' then
          modo_unidad <= "00";
      elsif clk'event and clk = '1' then
        case unidad is
            when CELSIUS   => modo_unidad <= "00";  --Esto tiene la misma utilidad que el modo_refresh
            when KELVIN    => modo_unidad <= "01";  --Será una señal que se manda al display a modo de enable
            when FARENHEIT => modo_unidad <= "10";  --para poner en el display las letras F, K o º.
            when others    => modo_unidad <= "00";
        end case;
      end if;
    end process;

    --Selector de refresco de datos en display
    process(clk, nRst)
    begin
        if nRst = '0' then
            modo_refresh <= "01";
            tic_elegido <= tic_4s;
        elsif clk'event and clk = '1' then
          case refresh is
              when REFRESH_2S =>
                  modo_refresh <= "00";  --Se trata de un enable que se conectara al codigo de displays 
		  tic_elegido <= tic_2s;
              when REFRESH_4S =>        --que dependiendo del valor dará salida al tic que le corresponda
                  modo_refresh <= "01";
		  tic_elegido <= tic_4s;
              when REFRESH_6S =>
                  modo_refresh <= "10";
		  tic_elegido <= tic_6s;
              when REFRESH_8S =>
                  modo_refresh <= "11";
		  tic_elegido <= tic_8s;
              when others =>
                  modo_refresh <= "00"; -- Valor por defecto de seguridad
		  tic_elegido <= tic_2s;
          end case;
	end if;
    end process;

    recien_medido <= tic_elegido;

end rtl;