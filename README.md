# Proyecto Final: Semáforo Inteligente Interactivo

**Asignatura:** Electrónica Digital II - Universidad Nacional de Córdoba  
**Profesor:** Ing. Blasco  

---

## 🚀 1. Descripción General del Proyecto

Este proyecto consiste en el diseño e implementación de un sistema de tránsito automatizado basado en el microcontrolador PIC16F887 y programado en lenguaje Assembler. El sistema simula un semáforo de dos vías: una vía vehicular regulada por una secuencia de luces (Verde, Amarillo, Rojo) acoplada a una barrera física, y una vía de cruce peatonal que asiste a personas mediante alertas sonoras y temporizadores visuales.

El dispositivo resuelve la necesidad de adaptabilidad vial y seguridad en cruces urbanos complejos. Integra automatización por hardware para conmutar dinámicamente entre el régimen diurno convencional y un modo nocturno intermitente de precaución mediante la medición de luz ambiental con un sensor LDR acoplado al conversor analógico-digital (ADC). Está dirigido a entornos urbanos de alto trafico y concurrencia peatonal.



### 🎯 Alcances del Proyecto

### El sistema SÍ es capaz de:
* **Gestionar una máquina de 4 estados:** Controla de manera sincronizada las luces vehiculares para los estados Verde, Amarillo, Rojo y Noche.
* **Interrumpir la secuencia vehicular:** Mediante un botón peatonal conectado por hardware al pin RB0, el sistema detecta la pulsación por interrupción externa y fuerza de manera inmediata la transición para permitir el cruce seguro.
* **Controlar una barrera automatizada:** Utiliza un servomotor mapeado en una salida digital gestionada por software, el cual posiciona la barrera alta durante los estados Rojo y Noche, y la mantiene baja en Verde y Amarillo.
* **Cuenta regresiva visual:** Implementa dos displays de 7 segmentos compartidos en PORTD y multiplexados para mostrar el tiempo restante en el estado Rojo o guiones de espera (`--`) en Verde y Amarillo.
* **Emitir asistencia sonora:** Activa un buzzer acoplado a una salida digital sincronizado intermitentemente cada vez que el semáforo se encuentra en el estado Rojo diurno.
* **Monitorear la luz ambiente automáticamente:** Realiza lecturas constantes a través del ADC conectado al LDR, aplicando lógica de comparación con un umbral digital de 8 bits para pasar a modo Noche o retornar al modo Día.
* **Transmitir telemetría serial e interactuar vía comandos:** Configura la UART a 9600 baudios para enviar de forma automática reportes textuales del estado actual de las luces, la barrera y el sensor hacia una PC, además de permitir la detección de la pulsación del botón peatonal.

### El sistema NO incluye (Fuera de alcance):
* Almacenamiento local de logs o registro histórico de eventos en memorias EEPROM externas.
* Conectividad inalámbrica para el monitoreo a distancia a través de redes de internet.
* Regulación adaptativa de la velocidad o movimeinto de la barrera.
* Deteccion y monitoreo de fallas o conflictos: El sistema no cuenta con mecanismos de diagnóstico en tiempo real para detectar errores de software o hardware en las transiciones.
* Control adaptativo o dinámico de tráfico: La máquina de estados opera con una base de tiempos rígida y predeterminada en el código
### ⏩ Posibles Etapas Siguientes (Líneas Futuras)

* **Optimización por Hardware de Periféricos:** Reemplazar el control del servomotor (actualmente basado en retardos bloqueantes de software como `DELAY_1MS` y `DELAY_2MS`) por los módulos CCP/PWM integrados por hardware del PIC16F887.
* **Señalización Peatonal Simbólica:** Evolucionar los displays numéricos de 7 segmentos actuales hacia matrices de LED o indicadores gráficos que muestren símbolos normativos dinámicos de tránsito pedestre, tales como una silueta humana en movimiento.
* **Control Bidireccional Avanzado por UART:** Expandir la lógica de recepción serial para que el operador no solo pueda consultar el estado del PIC o simular el botón, sino también reconfigurar dinámicamente en tiempo real los tiempos base de la secuencia vehicular (Verde, Amarillo, Rojo) o forzar estados de emergencia de forma remota.
* **Modo Nocturno de Bajo Consumo Inteligente:** Adaptar una rutina de ahorro energético basada en la instrucción `SLEEP` del microcontrolador que se active durante el estado nocturno; el sistema despertaría de forma cíclica mediante desbordes del Watchdog Timer (WDT) o interrupciones del Timer para generar el titilado amarillo intermitente, reduciendo drásticamente el consumo promedio de potencia.
* **Cumplimiento de Normativa Vial y de Seguridad:** Investigar y adecuar el diseño para cumplir con normativas de seguridad vial y señalización urbana, asegurando tiempos de despeje mínimos obligatorios, redundancias de hardware ante fallas de lámparas y protección contra tensiones peligrosas para los usuarios.
* **Fiscalización Electrónica Integrada:** Incorporar sensores de velocidad de efecto Doppler junto a módulos de captura de imágenes para detectar y registrar automáticamente vehículos que excedan los límites de velocidad o crucen con la señal de luz roja encendida.
