# Medidor de Temperatura Digital - FPGA DECA (MAX 10)
Diseño y desarrollo de un sistema de instrumentación digital en hardware para la medición de temperatura en tiempo real. El proyecto se basa en la implementación de una arquitectura digital personalizada en una FPGA para gestionar la adquisición y visualización de datos sin necesidad de un microprocesador.

### 🔧 Hardware e Interfaces
- ***Protocolo SPI:*** Implementación de un controlador maestro SPI en VHDL para la comunicación serie con el sensor.
- ***Sensor:*** Interfaz directa con el sensor de temperatura digital LM71.
- ***Visualización:*** Control de displays de 7 segmentos mediante técnicas de multiplexación temporal para la representación de los grados Celsius.
- ***Plataforma:*** Implementación física sobre la tarjeta de desarrollo DECA con la FPGA Intel MAX 10.

### 🏗️ Arquitectura de Software
- ***Modularidad VHDL:*** Diseño basado en módulos independientes para la adquisición de datos (SPI), conversión de formato y gestión del display.
- ***Máquinas de Estados (FSM):*** Uso de lógica secuencial para coordinar los ciclos de lectura del sensor y el refresco dinámico de los displays.
- ***Validación RTL:*** Proceso de verificación que incluye la creación de testbenches para asegurar el correcto funcionamiento del protocolo antes de la síntesis.

### 🚀 Funcionalidades Clave
- Adquisición precisa de datos térmicos mediante comunicación digital serie.
- Visualización dinámica en tiempo real sobre hardware físico.
- Síntesis hardware optimizada para dispositivos lógicos programables.

### 🛠️ Herramientas y Tecnología
- ***Lenguaje:*** VHDL.
- ***Síntesis:*** Intel Quartus.
- ***Simulación:*** ModelSim.
- ***Hardware:*** FPGA DECA MAX10.

### 👥 Colaboradores
Proyecto académico desarrollado por Raúl Torres, Diego Domínguez y Yuanze Li.

