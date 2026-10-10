# Tiros Libres 3D — Fase 1

Vertical slice en Godot 4, aislado del MVP Phaser. Incluye un duelo individual completo: cantidad configurable de turnos de patear y atajar, muerte súbita, tiro con dirección/altura/potencia, atajada dirigida, IA con lectura parcial del tiro y récord local persistido en el dispositivo.

## Ejecutar

1. Instalar Godot 4.x y abrir esta carpeta como proyecto.
2. Ejecutar el proyecto con `F5`: abre la pantalla inicial `Menu.tscn`. `Main.tscn` con `F6` permite probar directamente el duelo.

La pantalla inicial muestra el estadio y el personaje en 3D, la mejor marca y el botón JUGAR. CONFIGURAR reúne dificultad, calidad gráfica, volumen y selección de arquero/delantero; PERSONALIZADO permite editar nombre, dorsal y aspecto de cada personaje. La dificultad modifica la reacción, el alcance y la precisión del arquero rival. `Esc` o el botón PAUSA abre la pausa: CONTINUAR reanuda y SALIR AL INICIO abandona el partido. La pausa congela la física, las animaciones y los temporizadores de turnos.

CONFIGURAR permite ajustar y guardar el volumen. Los efectos incluyen patada, contacto con guantes, palo y red. Cada resultado se indica con una floritura breve de acorde mayor para gol (0,58 s) y un golpe suave descendente para fallo o atajada (0,38 s), tanto propios como del rival. No se reproduce voz ni ambiente de tribuna; todo comparte el control de volumen. Los efectos se regeneran con `python3 apps/free-kick-3d/tools/generate_sfx.py`; usar `--results-only` para regenerar solo las señales de resultado.

CONFIGURAR también guarda la calidad gráfica: BAJO desactiva sombras y MSAA, MEDIO usa sombras y MSAA 2×, y ALTO usa sombras y MSAA 4×. El perfil se aplica tanto al menú como al partido; no altera colisiones ni dificultad. `tools/benchmark_graphics.gd` mide una escena de partido a 1280 × 720 con una estirada del arquero.

Controles de tiro: apuntar al arco con el mouse; mantener clic, toque o `Espacio` para cargar y soltar cerca del centro verde de la barra de precisión. La barra lima indica potencia. Un mal timing desvía físicamente el tiro hacia el lado apuntado.

Controles de atajada: sobre el arco aparece solo una mira, sin cuadrícula. Con mouse, mover el cursor previsualiza el destino y el clic inicia la estirada. En pantalla táctil, tocar y arrastrar mueve la mira; al soltar se estira. Se puede elegir cualquier punto intermedio, incluidos los sectores altos apenas a un lado del centro. También `←`/`→` (estirada lateral) y `Espacio` o `↓` (centro). `W`/`↑` selecciona estirada alta y `S` baja. Al salir el tiro aparece su sector y altura; conviene esperar el disparo para estirarse, porque la estirada tiene impulso, caída y recuperación.

El arquero rival reacciona con demora y una lectura imperfecta del destino del tiro. Las atajadas se resuelven por contacto con la pelota.

La defensa manual mantiene la elección inmediata del sector, sin seguimiento automático de la pelota. El disparo de la IA tarda 1,22 s en llegar al arco; la extensión del arquero dura un poco más para permitir reaccionar al remate. `res://tests/keeper_save_balance_test.gd` comprueba tiros al centro, bajos y altos a ambos lados, además de elecciones equivocadas.
Al atajar, la red propia se vuelve semitransparente para despejar la vista de la pelota y el pateador sin desaparecer. Los postes siguen visibles y la red recupera su intensidad en el impacto de un gol, con su ondulación.
Las estiradas laterales llegan a los cuatro ángulos con contacto físico de cuerpo y brazos. Los tiros bajos usan clips propios, con los guantes más cerca del césped; elegir mal el lado o la altura sigue dejando pasar la pelota. `res://tests/keeper_corner_ai_test.gd` verifica también el alcance del arquero rival.

Al tocar JUGAR aparece PREPARÁ TU RONDA: de 1 a 4 jugadores y de 5 a 15 tiros por persona (7 por defecto). La selección se guarda al tocar EMPEZAR. Con un jugador se alternan tiros y atajadas contra la IA, con muerte súbita si hay empate. Con varios jugadores se alterna un tiro por persona contra el arquero IA, con marcador individual y empate permitido al agotar los tiros.

Al finalizar se muestra el resultado durante tres segundos y se vuelve automáticamente al inicio. `Espacio` permite volver antes. Los récords se guardan por cantidad de tiros.

El estadio conserva geometría generada por código. Todos los delanteros y ambos arqueros usan el personaje completo generado en Meshy con el rig compartido MPFB/MakeHuman CC0. Los GLB v4 anteriores se conservan como fuentes y respaldo. La procedencia está en `ASSET-LICENSES.md` y `source-assets/footballer/`.

## Verificación

```sh
godot --headless --path apps/free-kick-3d --script res://tests/shot_and_keeper_test.gd
godot --headless --path apps/free-kick-3d --script res://tests/menu_flow_test.gd
godot --headless --path apps/free-kick-3d --script res://tests/round_flow_test.gd
```

Ejecutar desde la raíz del repositorio. Comprueba precisión independiente de FPS, desvío, reacción y reinicio del arquero, y un ciclo de ataque/defensa.

### Estadio y materiales

La escena incluye tribunas cubiertas con público instanciado mediante MultiMesh,
reflectores, cielo de atardecer y sombras del sol. El césped usa un shader procedural
con franjas de corte y detalle filtrado por distancia; la pelota tiene paneles
procedurales. Los arcos conservan sus colisiones originales y usan tubos redondos
con redes de malla. MSAA 4× suaviza los bordes en el renderizador Compatibility.
La geometría del estadio vive en `stadium.gd` y los materiales en `shaders/`.
Las gradas usan butacas con asiento y respaldo instanciados, escaleras visibles,
accesos, vigas de cubierta y una franja de palcos. El público tiene torso,
cabeza y cabello con variaciones de color, también mediante MultiMesh para
evitar un nodo por espectador. Las vallas y el césped mantienen una paleta
menos contrastada para dar prioridad visual a la pelota y los jugadores.
La pasada visual de septiembre ajusta el césped a un verde más natural y
reduce la saturación de butacas, público y
vallas. El sol está más alto para acortar las sombras y los postes son más
blancos, sin modificar cámara, colisiones ni trayectoria de tiro.

### Pateador y resultados del tiro

Al soltar el tiro, el jugador hace una aproximación y golpea la pelota a los 0,48 s;
la pelota permanece quieta hasta ese contacto. El rival también tiene animación.
La IA elige el lado incorrecto en el 60 % de los tiros en fácil, el 40 % en medio y el 20 % en difícil. Cuando se equivoca se tira temprano al lado opuesto, por lo que deja pasar un tiro válido; cuando lee bien, la atajada sigue dependiendo del contacto físico con la pelota. `res://tests/keeper_ai_balance_test.gd` mide el porcentaje final de goles y atajadas con 100 tiros válidos por dificultad.
La estirada se sincroniza con la llegada de la pelota para poder atajar tiros débiles.
Apuntar fuera del arco permite rematar ancho o por arriba, aun con precisión perfecta.
Los palos y el travesaño tienen colisiones cilíndricas y restitución: el rebote puede
terminar en gol o afuera, sin decidir el resultado al primer contacto con el palo.
El gol se cuenta cuando la pelota completa cruza la línea.

Verificación de estos resultados físicos:
`godot --headless --path apps/free-kick-3d --script res://tests/kick_outcomes_test.gd`

Los resultados de cada tiro aparecen en grande en el centro. Al terminar, el cartel identifica al jugador ganador (1–4), a la IA o a los jugadores empatados.

La red se deforma en el punto del gol y amortigua su movimiento. Las atajadas suaves y cercanas al cuerpo quedan en las manos; las fuertes o laterales se desvían hacia la cancha. Estos efectos se detienen durante la pausa. Prueba: `res://tests/goal_feedback_test.gd`.

Incluso en tiros que puede retener, el arquero da rebote el 45 % de las veces. Los rebotes permanecen visibles durante 1,9 segundos antes de cambiar de turno.

La cancha mide 105 × 68 unidades (metros). Solo se juegan tiros libres a 24 m del arco. El arco se amplió a 8,4 × 2,9 m para la jugabilidad y los jugadores crecieron un 15 %. Las cámaras muestran al pateador completo y evitan la obstrucción del travesaño.

El inicio muestra un estadio 3D con el personaje y la pelota. JUGAR abre la configuración de ronda; CONFIGURAR reúne la dificultad y el aspecto. El fondo está separado de la partida en `menu_background.gd`.

### Personajes y delantero

CONFIGURAR → ELEGIR DELANTERO permite elegir a Mateo, Bruno o Nicolás y ver
al seleccionado en 3D. NOMBRE Y ASPECTO guarda el nombre y dorsal usados en la
camiseta propia. La elección persiste y se aplica al pateador de la partida.
La IA usa un arquero inspirado en Donnarumma; los atacantes rivales son ficticios.
Las mallas visibles v4 mantienen la base anatómica de MPFB/MakeHuman e incorporan
forma y texturas de uniforme adaptadas de Meshy. No son un escaneo del deportista.

El selector de delantero incluye PERSONALIZADO: nombre, dorsal, piel, cabello, barba, camiseta y short, con vista previa y guardado inmediato. ELEGIR ARQUERO permite seleccionar un personaje ficticio o usar AL AZAR. Las elecciones se mantienen al iniciar la partida.

Arquero y delantero comparten el editor PERSONALIZADO. Sus colores, barba, nombre y número se guardan por separado; editar uno no modifica al otro.

Los personajes comparten anatomía humana, manos con dedos y un rig de 53 huesos.
El delantero usa `footballer_v4.glb`; el arquero usa `goalkeeper_v4.glb` con guantes.
La piel tiene una textura CC0 adaptada; camiseta, short y medias conservan sus
mapas de albedo, normal y rugosidad al cambiar de color. Nombre y dorsal se
imprimen sobre las UV de la espalda y acompañan la deformación de la camiseta.

### Uniforme Meshy v4

El uniforme generado con Meshy 6 Lite se ajusta a la malla limpia v3 y conserva
su topología, pesos y ambas UV. Se hornean los mapas de tela para permitir
recoloración independiente de camiseta y short; cuello, puños y ruedos conservan
contornos continuos. Cuerpo, rostro, pelo, medias, botines, guantes, los 53 huesos
y los ocho clips siguen intactos. Todos los perfiles usan las dos bases v4.

Fuentes: `source-assets/footballer/footballer_v4.blend` y `goalkeeper_v4.blend`.
Reconstrucción: `tools/integrate_meshy_kit.py -- footballer` o `-- goalkeeper`
desde Blender. Las exportaciones candidatas se generan bajo la carpeta de prueba;
`tools/audit_meshy_export.py` valida las copias de runtime y registra hashes en
`source-assets/footballer/athlete_v4_manifest.json`.

La ropa derivada de Meshy usa CC BY 4.0; **Configurar → Créditos** muestra
atribución y enlaces. La base anatómica sigue siendo CC0. La versión v3 se
conserva como respaldo. Informe: `docs/research/meshy-trial-2026-10-06/integracion-aplicada.md`.

### Personaje completo PLAYER

**Configurar → Elegir delantero → PLAYER** identifica el personaje completo
generado desde la referencia, con su rostro, pelo, cuerpo, uniforme y botines.
Es una opción adicional (índice 4); el personalizado sigue en el índice 3.
La elección se guarda y se restaura al volver al ataque. El dorsal usa el
nombre y número configurados, con tinta azul sobre la camiseta blanca.

Se conserva el esqueleto de 53 huesos y los ocho clips del juego. Las dos
bases de delantero se reutilizan al alternar turnos. Reconstrucción:
`blender -b --python tools/rig_meshy_player.py`; auditoría:
`python3 tools/audit_meshy_player.py`. La imagen 2D orienta la generación;
el resultado 3D es una aproximación, no una copia exacta.

Desde el 8 de octubre, PLAYER tiene un gesto de brazos específico de tiro
libre en Idle/Kick: codos flexionados al preparar, contrapeso del brazo opuesto
a la pierna de golpeo y manos orientadas hacia dentro/abajo. La forma de dedos
se curva suavemente en la fuente; no se añadieron huesos ni influencias de
dedos. Se conservan exactamente los canales ajenos a las seis rotaciones de
brazos/manos, la duración de clips y el contacto a 0.48 s. Investigación y
capturas: `docs/research/kick-arms-2026-10-08/aplicado.md`.

Informe: `docs/research/meshy-trial-2026-10-06/personaje-completo.md`.

Desde el 9 de octubre todas las identidades de delantero, incluido el rival,
usan `meshy_striker.glb`: la misma geometría, pesos, UV y animaciones de PLAYER
con la camiseta separada para recolorear. MATEO/BRUNO/NICOLÁS y PERSONALIZADO
seleccionan color y nombre sobre esa base; PLAYER conserva la camiseta blanca.
Los turnos reutilizan una sola instancia y no cargan el modelo anterior.
Rostro, pelo, barba y short mantienen el aspecto de la base Meshy. Los ajustes
antiguos de piel/pelo/barba no alteran este atlas.
Reconstrucción: `blender -b --python tools/build_meshy_striker.py`;
auditoría: `python3 tools/audit_meshy_striker.py`.

Desde el 9 de octubre ambos arqueros reutilizan la geometría de PLAYER con
camiseta recoloreable y guantes. Conservan su tamaño, colisiones y las ocho
animaciones originales de arquero; no usan el Idle de tiro libre. El rostro
y pelo corresponden a la base Meshy, mientras que el color de camiseta,
nombre y dorsal siguen siendo personalizables. Fuente: `meshy_keeper.blend`.
Reconstrucción: `blender -b --python tools/build_meshy_keeper.py`; auditoría:
`python3 tools/audit_meshy_keeper.py`.

### Fuentes y reconstrucción v3

Las fuentes editables están en `source-assets/footballer/footballer_v3.blend`
y `goalkeeper_v3.blend`. El generador es `tools/build_footballer_v3.py`;
versiones, procedencia, instrucciones y límites visuales se documentan en
`source-assets/footballer/footballer_v3.md`. La base y los assets externos usados
son CC0; el proyecto conserva las variantes anteriores como respaldo.

La revisión v3 ajusta el cuello de la remera a la superficie y pesos de la piel,
incorpora mechones de pelo con recorte alfa y degradado lateral, reemplaza la
mancha facial por barba corta geométrica y reconstruye el short con topología
de prenda.

Las animaciones del proyecto se adaptan al nuevo rig, con corrección de brazos
para conservar el contacto de las manos. La sincronización de la patada,
estiradas, pausa y reinicio siguen a cargo de `kicker.gd` y `keeper.gd`.

Pruebas adicionales de la integración:

```sh
godot --headless --path apps/free-kick-3d --script res://tests/athlete_v3_test.gd
godot --headless --path apps/free-kick-3d --script res://tests/custom_players_test.gd
godot --headless --path apps/free-kick-3d --script res://tests/kick_contact_and_dive_test.gd
godot --headless --path apps/free-kick-3d --script res://tests/keeper_hands_test.gd
```


### Sistema visual e Impeccable

La interfaz aplica la dirección 3, Cartel de desafío: Bungee para la marca y
títulos, Archivo para controles y datos, tinta ciruela, crema, azul y naranja.
Los botones principales, el marcador y el medidor usan cortes diagonales originales. Las opciones seleccionadas
incluyen una marca y mantienen el mismo tamaño de letra. El marcador compacto
separa puntuación, récord, turno y dirección; las instrucciones admiten dos líneas.
Esc vuelve del editor al selector y del selector a ajustes. Los selectores y
el editor mantienen el foco de teclado, incluso con un personaje personalizado.

Impeccable está instalada en `.agents/skills/impeccable/`; el sistema aplicado
se documenta en `DESIGN.md` en la raíz. `tools/preview_ui.gd` permite generar
capturas de varias pantallas y resoluciones en una sola ejecución.
