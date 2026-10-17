# Jugar · Selección ilustrada

Solicitud: reemplazar la preparación que aparece al pulsar JUGAR por una selección
con portadas visuales, tomando como referencia la imagen de Rocket League enviada
por el usuario y manteniendo la estética del juego.

Modo: Operate. La tarea es elegir una configuración de duelo de tiros libres y
comenzar con los participantes y tiros correctos, con ratón, teclado o mando.

Dirección: Cartel de desafío existente. Bungee para JUGAR, nombres de modos y
EMPEZAR; Archivo para instrucciones y ajustes. Ciruela #211A2B, crema #FFF2D0,
azul #3456E8, naranja #F05B3F, foco/selección amarillo #F5D547. El escenario 3D
queda oscurecido y sin avatar detrás de la selección. Las diagonales llegan a
los bordes del viewport. No se copian marcas, recursos ni modos de Rocket League.

Primer viewport: título JUGAR, una fila de tres portadas ilustradas grandes,
placas de título inclinadas y una descripción breve por opción. La opción activa
tiene placa naranja, marco amarillo y check. Hover azul y foco amarillo son
visibles sin borrar la opción aplicada. Debajo: tiros (5–15), jugadores (1–4),
resumen, VOLVER y EMPEZAR. La composición lógica 1024×640 se escala y centra con
el menú existente, y la fila se distribuye con HBoxContainer.

Contenido real:

- Individual: una persona alterna tiros y atajadas contra IA.
- Duelo local: dos personas tiran por turnos en el mismo dispositivo.
- Ronda local: tres o cuatro personas tiran por turnos en el mismo dispositivo.

Son accesos a las reglas ya disponibles, sin modo online, entrenamiento,
clasificación ni torneo inventados. Elegir portada cambia participantes a 1, 2 o
4; el contador puede ajustar todos los valores y sincroniza la portada activa.
El total de remates aparece para multijugador. Solo EMPEZAR guarda la ronda.

Las portadas se generan con Imagegen integrado a 1536×1024, sin texto incrustado,
y se importan lossless con mipmaps. El encuadre recorta proporciones sin estirar
los atletas. Son arte de menú; los modelos y la simulación no cambian. Prompts,
hashes y procedencia se guardan en source-assets/ui/play-modes/.

Validación prevista: selección de los tres modos; sincronía del contador;
límites de tiros/personas; Esc → home; inicio y guardado de ronda local; capturas
1280×720, 960×540, 1920×984 y navegador local 1280×720.

## Resultado de implementación y validación — 12 de octubre de 2026

Implementado en `apps/free-kick-3d/menu.gd` (`show_setup`, `select_play_mode`,
`refresh_setup`), `ui/play_mode_card.gd` y `ui/play-modes/*.png`. Cada portada es
un Button con texto nativo, recorrido de foco entre portadas, contadores y
acciones, selección naranja/check amarillo, hover azul y marco amarillo de
foco o selección. VOLVER y Esc regresan al inicio; EMPEZAR inicia y guarda la
ronda seleccionada. La opción Ronda aplica cuatro participantes, permite ajustar
a tres y permanece activa para ambos valores. El resumen de Individual indica
tiros y atajadas con desempate por muerte súbita; el multijugador indica tiros
por persona y remates totales.

La revisión nativa cubrió siete capturas: los tres presets en `desktop/`
(1280×720), Individual y Ronda en `compact/` (960×540), e Individual y Ronda en
`wide/` (1920×984). El reviewer independiente inspeccionó estas capturas y
devolvió **`disposition: ship`**, sin recortes ni solapes. Se conserva la fila
HBoxContainer, las proporciones del arte, el estadio oscurecido sin avatar y
las diagonales hasta los bordes.

`play_modes_test.gd` pasó selección, sincronía de presets/contadores, límites,
Esc e inicio y persistencia de ronda local. `menu_flow_test.gd` pasó la regresión
de foco, navegación por niveles, personalización, juego, resultado y pausa.
Logs: `/tmp/play-modes-test.log` y `/tmp/play-menu-flow-test.log`; ambos muestran
PASS y ningún SCRIPT ERROR. Registran el aviso conocido de certificados del
sandbox; menu_flow también registra avisos de material nulo del renderer dummy.

El export web local terminó correctamente. En el navegador integrado a 1280×720
se verificó el paso de la home a JUGAR, la selección de los tres presets,
el aumento de tiros, Tab/Enter para cambiar participantes y Ronda con tres
jugadores. La consola no registró errores ni advertencias. Evidencia:
`web-play-menu.jpg`.
Esta iteración no se publicó. El detector de patrones HTML/CSS no aplica a los
Control nativos de Godot; la evidencia visual corresponde a capturas del juego.

El manifest registra los tres PNG finales a 1536×1024, hashes SHA-256,
procedencia Imagegen integrado, importación lossless con mipmaps y filtrado
lineal. Los prompts completos y la edición de Ronda se conservan en
`source-assets/ui/play-modes/`; el scan de prompts incrustados encontró
0 faltantes. La paleta y las fuentes de Cartel de desafío se heredan sin
redefinir el sistema visual.

## Revisión posterior: sólo uno contra uno y cinco tiros

El pedido posterior del usuario reemplaza los tres presets por una sola opción
contra el bot, sin controles de cantidad de tiros o participantes. Son cinco
remates por lado; sólo un empate permite parejas de remates adicionales.
La portada individual se mantiene, acompañada por las reglas del duelo.
Pruebas actualizadas: /tmp/bot-play-modes-test.log, /tmp/bot-round-flow-test.log
y /tmp/bot-menu-flow-test.log: PASS. La revisión `ship` anterior corresponde
a la selección original de tres modos, no a este ajuste posterior.

Verificado en navegador integrado a 1280×720: una sola opción, reglas de cinco
tiros visibles y ningún contador para aumentarlas. Consola sin errores ni
advertencias. Captura: `docs/design/play-menu-2026-10-12/web-bot-five-shots.jpg`.
Export web local actualizado; no se realizó publicación remota.
