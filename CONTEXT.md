# Tiros Libres

Este contexto define una experiencia de fútbol centrada en ejecutar y resolver tiros libres. La próxima evolución busca conservar ese núcleo mientras incorpora una presentación y simulación 3D.

## Lenguaje

**Duelo de tiro libre**:
Una secuencia autónoma en la que el jugador ejecuta tiros contra un arquero; no representa un partido de fútbol completo.
_Evitar_: partido, simulador de fútbol completo

**Simulación de tiro**:
La representación espacial de la trayectoria de la pelota, sus impactos y la intervención del arquero en un duelo de tiro libre.
_Evitar_: animación de gol, resultado aleatorio

**Versión 3D**:
La evolución del juego que usa escena, actores y cámara tridimensionales para el duelo de tiro libre, destinada tanto a navegador como a escritorio.
_Evitar_: cambio de gráficos, port 3D

**Modo individual**:
Un duelo de tiro libre jugado por una persona contra un arquero controlado por el juego.
_Evitar_: multijugador, partido local

**Multijugador local**:
Un modo de duelo compartido por varias personas en el mismo dispositivo, por turnos.
_Evitar_: online, cooperativo

**Multijugador online**:
Un modo en el que participantes conectados desde dispositivos diferentes comparten una sesión de juego.
_Evitar_: local, por turnos

**Turno de ida y vuelta**:
La unidad de un duelo en la que un participante ejecuta un tiro y después asume la defensa de su arco ante el tiro rival.
_Evitar_: tiro aislado, ronda ofensiva

**Copa de tiros libres**:
Una competición futura formada por fase de grupos y eliminatorias, cuyo resultado se decide exclusivamente mediante duelos de tiro libre.
_Evitar_: partido de Copa del Mundo, liga

**Atajada dirigida**:
La defensa en la que quien juega anticipa una zona y sincroniza una estirada para interceptar un tiro rival.
_Evitar_: atajada automática, movimiento libre del arquero

**Duelo reglamentario**:
Un enfrentamiento decidido por cinco turnos de ida y vuelta por participante y, si persiste el empate, muerte súbita.
_Evitar_: partido, tiro único

**Rival IA**:
Un participante controlado por el juego, definido por un estilo de tiro y una dificultad.
_Evitar_: jugador real, rival genérico

**Copa de 32**:
Una Copa de tiros libres con ocho grupos de cuatro participantes, de la que avanzan dos por grupo a octavos de final.
_Evitar_: liga de 32, formato de 48

**Copa elegible**:
Una Copa de tiros libres alternativa seleccionada antes de competir; inicialmente existen las copas América, Europa y Mundial.
_Evitar_: liga regional, fase de la Copa Mundial

**Selección elegida**:
El país real que la persona selecciona para representar durante una Copa de tiros libres, presentado con identidad artística original no oficial.
_Evitar_: equipo creado, club oficial

**Vista de pateo**:
La cámara situada detrás o junto al ejecutor para controlar dirección, potencia y efecto del tiro.
_Evitar_: cámara lateral fija, cámara libre

**Vista de atajada**:
La cámara situada detrás del arquero para anticipar y ejecutar una Atajada dirigida ante el tiro rival.
_Evitar_: vista de pateo, cámara lateral fija

**Señal de tiro**:
Un gesto visible de la carrera o postura de un Rival IA que anticipa, sin revelar de forma explícita, la intención de su tiro.
_Evitar_: indicador de zona, resultado aleatorio

**Partido de copa**:
Un Duelo reglamentario jugado por la Selección elegida contra un Rival IA durante una Copa de tiros libres.
_Evitar_: partido de fútbol, encuentro simulado

**Tabla de grupo**:
La clasificación de un grupo de una Copa de 32, ordenada por puntos de partido, diferencia de goles y goles a favor.
_Evitar_: tabla de goles, ranking global

**Progreso de copa**:
El estado persistido localmente de la selección, resultados, calendario y clasificación de una Copa de tiros libres en curso.
_Evitar_: cuenta online, partida reiniciable
