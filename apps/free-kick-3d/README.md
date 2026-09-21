# Tiros Libres 3D — Fase 1

Vertical slice en Godot 4, aislado del MVP Phaser. Incluye un duelo individual completo: cantidad configurable de turnos de patear y atajar, muerte súbita, tiro con dirección/altura/potencia, atajada dirigida, IA con lectura parcial del tiro y récord local persistido en el dispositivo.

## Ejecutar

1. Instalar Godot 4.x y abrir esta carpeta como proyecto.
2. Ejecutar el proyecto con `F5`: abre la pantalla inicial `Menu.tscn`. `Main.tscn` con `F6` permite probar directamente el duelo.

La pantalla inicial conserva el diseño del MVP 2D: mejor marca, dificultad fácil/media/difícil y botón JUGAR. ASPECTO permite guardar nombre, número y cabello del arquero propio. La dificultad modifica la reacción, el alcance y la precisión del arquero rival. `Esc` vuelve al menú desde el duelo.

Controles de tiro: apuntar al arco con el mouse; mantener clic, toque o `Espacio` para cargar y soltar cerca del centro verde de la barra de precisión. La barra azul indica potencia. Un mal timing desvía físicamente el tiro hacia el lado apuntado.

Controles de atajada: clic o toque en el tercio izquierdo, central o derecho de la ventana. También `←`/`→` (estirada lateral) y `Espacio` o `↓` (centro). `W`/`↑` selecciona estirada alta y `S` baja. Conviene esperar el disparo: la estirada tiene impulso, caída y recuperación.

El arquero rival reacciona con demora y una lectura imperfecta del destino del tiro. Las atajadas se resuelven por contacto con la pelota.

Al tocar JUGAR aparece CONFIGURAR RONDA: de 1 a 4 jugadores y de 5 a 15 tiros por persona (7 por defecto). La selección se guarda al tocar EMPEZAR. Con un jugador se alternan tiros y atajadas contra la IA, con muerte súbita si hay empate. Con varios jugadores se alterna un tiro por persona contra el arquero IA, con marcador individual y empate permitido al agotar los tiros.

Al finalizar se muestra el resultado durante tres segundos y se vuelve automáticamente al inicio. `Espacio` permite volver antes. Los récords se guardan por cantidad de tiros.

Todos los modelos del prototipo son primitivas generadas por el código. Antes de sustituirlos por assets se debe registrar su licencia o atribución en el proyecto.

## Verificación

```sh
godot --headless --path apps/free-kick-3d --script res://tests/shot_and_keeper_test.gd
godot --headless --path apps/free-kick-3d --script res://tests/menu_flow_test.gd
godot --headless --path apps/free-kick-3d --script res://tests/round_flow_test.gd
```

Ejecutar desde la raíz del repositorio. Comprueba precisión independiente de FPS, desvío, reacción y reinicio del arquero, y un ciclo de ataque/defensa.
