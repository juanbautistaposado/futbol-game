# Tiros Libres 3D — Fase 1

Vertical slice en Godot 4, aislado del MVP Phaser. Incluye un duelo individual completo: cantidad configurable de turnos de patear y atajar, muerte súbita, tiro con dirección/altura/potencia, atajada dirigida, IA con lectura parcial del tiro y récord local persistido en el dispositivo.

## Ejecutar

1. Instalar Godot 4.x y abrir esta carpeta como proyecto.
2. Ejecutar el proyecto con `F5`: abre la pantalla inicial `Menu.tscn`. `Main.tscn` con `F6` permite probar directamente el duelo.

La pantalla inicial muestra el estadio y el personaje en 3D, la mejor marca y el botón JUGAR. CONFIGURAR reúne dificultad, calidad gráfica, volumen y selección de arquero/delantero; PERSONALIZADO permite editar nombre, dorsal y aspecto de cada personaje. La dificultad modifica el margen de error, el tiempo de reacción y el alcance del arquero rival. `Esc` o el botón PAUSA abre la pausa: CONTINUAR reanuda y SALIR AL INICIO abandona el partido. La pausa congela la física, las animaciones y los temporizadores de turnos.

CONFIGURAR permite ajustar y guardar el volumen. Los efectos incluyen patada, contacto con guantes, palo y red. Cada resultado se indica con una floritura breve de acorde mayor para gol (0,58 s) y un golpe suave descendente para fallo o atajada (0,38 s), tanto propios como del rival. No se reproduce voz ni ambiente de tribuna; todo comparte el control de volumen. Los efectos se regeneran con `python3 apps/free-kick-3d/tools/generate_sfx.py`; usar `--results-only` para regenerar solo las señales de resultado.

CONFIGURAR también guarda la calidad gráfica: BAJO desactiva sombras y MSAA, MEDIO usa sombras y MSAA 2×, y ALTO usa sombras y MSAA 4×. El perfil se aplica tanto al menú como al partido; no altera colisiones ni dificultad. `tools/benchmark_graphics.gd` mide una escena de partido a 1280 × 720 con una estirada del arquero.

Controles de tiro: apuntar al arco con el mouse; mantener clic, toque o `Espacio` para cargar y soltar cerca del centro verde de la barra de precisión. La barra lima indica potencia. Un mal timing desvía físicamente el tiro hacia el lado apuntado.

Controles de atajada: sobre el arco aparece solo una mira, sin cuadrícula. Con mouse, mover el cursor previsualiza el destino y el clic inicia la estirada. En pantalla táctil, tocar y arrastrar mueve la mira; al soltar se estira. Se puede elegir cualquier punto intermedio, incluidos los sectores altos apenas a un lado del centro. También `←`/`→` (estirada lateral) y `Espacio` o `↓` (centro). `W`/`↑` selecciona estirada alta y `S` baja. El HUD no anuncia el lado ni la altura: hay que leer la salida de la pelota. La estirada tiene impulso, caída y recuperación.

El arquero rival observa la posición y velocidad de la pelota después de una demora según la dificultad; no recibe el destino elegido por el jugador. Las atajadas se resuelven por contacto con la pelota.

La defensa manual mantiene la elección inmediata del sector, sin seguimiento automático de la pelota. El disparo de la IA tarda 1,22 s en llegar al arco; la extensión del arquero dura un poco más para permitir reaccionar al remate. `res://tests/keeper_save_balance_test.gd` comprueba tiros al centro, bajos y altos a ambos lados, además de elecciones equivocadas.
Al atajar, la red propia se vuelve semitransparente para despejar la vista de la pelota y el pateador sin desaparecer. Los postes siguen visibles y la red recupera su intensidad en el impacto de un gol, con su ondulación.
Las estiradas laterales llegan a los cuatro ángulos con contacto físico de cuerpo y brazos. Los tiros bajos usan clips propios y una estirada rasante, sin el pequeño salto que dejaba pasar los remates pegados al césped; elegir mal el lado o la altura sigue dejando pasar la pelota. `res://tests/keeper_corner_ai_test.gd` verifica que el bot llegue desde el centro cuando elige el lado correcto, ante tiros de potencia máxima a los cuatro ángulos en dificultad media. `res://tests/keeper_ground_corner_test.gd` cubre además ambos ángulos casi al ras del césped (centro de la pelota a 24 cm), con el bot y la defensa manual por mouse y teclado.

PERSONAJE, encima de Configurar, reúne la elección y personalización del delantero y del arquero. Configurar conserva dificultad, gráficos, sonido y créditos.

Al tocar JUGAR aparece UNO CONTRA UNO: vos contra el bot, con 5 tiros por lado. Se alternan tiros y atajadas. La cantidad de tiros es fija; sólo se añaden rondas de un remate por lado si persiste el empate. EMPEZAR guarda esta configuración, incluso si una partida anterior tenía más tiros o participantes.

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
El arquero rival vuelve al margen de error anterior, sin recordar tiros: elige el lado equivocado el 60 % de las veces en fácil, 40 % en medio y 20 % en difícil. Cuando lee bien, conserva las mejoras de alcance a los ángulos y una pequeña imprecisión lateral. Siempre parte del centro del arco, con la guardia recta; solo se mueve al estirarse. El gol o la atajada siguen dependiendo del contacto físico. `res://tests/keeper_ai_balance_test.gd` compara los mismos 24 tiros colocados entre dificultades.
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
Desde el 10 de octubre, piel, cabello, camiseta, short y barba se personalizan
sobre esa misma base mediante máscaras UV; nombre y dorsal siguen la espalda
animada. PLAYER conserva su atlas original. Las medias y botines conservan
su aspecto original. La barba está pintada: el interruptor cambia su pigmento,
sin modificar la forma facial, el peinado ni el rig.
Las máscaras se regeneran con Python, Pillow y NumPy:
`python3 tools/build_meshy_appearance_mask.py`. No requiere Blender ni exportar
los GLB. Prueba de guardado/recarga: `tests/custom_players_test.gd`.
Reconstrucción: `blender -b --python tools/build_meshy_striker.py`;
auditoría: `python3 tools/audit_meshy_striker.py`.

Desde el 9 de octubre ambos arqueros reutilizan la geometría de PLAYER con
camiseta recoloreable y guantes. Conservan su tamaño, colisiones y las ocho
animaciones originales de arquero; no usan el Idle de tiro libre. Comparten
las máscaras de personalización de piel, cabello, short y barba, y mantienen
guantes independientes. Camiseta, nombre y dorsal también se personalizan.
Fuente: `meshy_keeper.blend`.
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

### Detalle del personaje — 14 de octubre de 2026

Los GLB de delantero y arquero incorporan subdivisión localizada, normales
recalculadas, fibras 3D de pelo/barba/cejas, ojos y detalle de piel, además de
prendas con holgura y espesor en los bordes. Las ocho animaciones y los 53 huesos
se conservan. La ropa se deforma con el rig, sin simulación de tela.

La etapa de ropa y pelo se conserva en `tools/build_player_realism.py` y en
`source-assets/footballer/meshy_*_realism.blend`. Si se reconstruye esa etapa,
debe ejecutarse después la reconstrucción de cabeza indicada a continuación.
Sus capturas históricas están en `docs/research/player-realism-2026-10-14/`.

### Cabeza anatómica y textura facial dedicada — 14 de octubre de 2026

La cabeza actual reemplaza la cara escaneada por anatomía derivada de la base
CC0 del proyecto, ajustada al jugador: párpados, labios, nariz, orejas y cuello.
Los ojos tienen volumen propio y material independiente para esclera, iris,
pupila y brillo corneal. La piel usa `assets/footballer/face_albedo.png`, con UV
exclusivas y mayor resolución frontal. Se conservan los colores de piel/pelo,
la barba opcional, el rig y los clips de delantero y arquero.

Reconstrucción desde la raíz:
`blender -b --factory-startup --python apps/free-kick-3d/tools/rebuild_player_head.py -- striker keeper`.
Auditoría vigente: `python3 apps/free-kick-3d/tools/audit_player_head.py`.
Fuentes editables actuales: `source-assets/footballer/meshy_*_head.blend`.
Textura, prompt y procedencia: `source-assets/footballer/head-2026-10-14/`.
Comparación, pruebas y costo de renderizado: `docs/research/player-head-2026-10-14/`.
Corrección posterior de nuca y barba, con capturas y auditoría de raíces:
`docs/research/player-groom-fix-2026-10-14/`.
Revisión de fibras de barba, expresión facial y parpadeo:
`docs/research/player-face-polish-2026-10-14/`.

### Movimiento de tiro y atajada

La revisión del 9 de octubre incorpora animaciones originales inspiradas en
principios publicados por EA para FIFA/FC. El delantero alterna dos pasos,
carga pelvis y torso, planta el pie izquierdo y continúa el remate antes de
recuperar su postura. El contacto sigue a los **0,48 s**; la recuperación termina
a los **1,16 s**. `striker_animation.gd` prepara los clips privados sobre el rig
existente, sin reemplazar el GLB.

Antes de patear, el delantero espera con pies escalonados, rodillas flexionadas,
torso ligeramente inclinado y brazos relajados. Una respiración discreta mantiene
ambas botas apoyadas. La espera, el primer fotograma del remate y su recuperación
usan la misma pose privada `athlete/Ready`.

El arquero espera con los brazos bien abiertos a los lados, guantes a la altura
de los hombros y codos ligeramente flexionados, según la imagen de referencia.
La guardia se mantiene también durante el
retardo de reacción, antes de iniciar la estirada. Prepara el impulso y mantiene la extensión
durante el vuelo, amortigua la caída y recupera la guardia al terminar la
secuencia de **1,59 s**. Tiene variantes laterales altas/bajas y paradas centrales.
`keeper_animation.gd` acompaña la trayectoria física existente; dirección,
reacción, alcance y resultado de atajada conservan sus reglas.

Ambos actores reproducen las poses junto con los ticks de física. Pausar o
cambiar de turno congela o cancela también el contacto pendiente y la reacción.
Referencias de las acciones: `docs/research/fifa-animation-2026-10-09/`.
[Posturas previas y capturas](../../docs/research/pre-shot-poses-2026-10-10/aplicado.md).

La revisión del 10 de octubre mantiene la guardia abierta y reemplaza la pausa
en el aire por continuación de vuelo con piernas asimétricas. La baja carga
el peso hacia el costado; después del alcance el arquero recoge los guantes,
cae sobre el costado y se incorpora desde un apoyo de brazo y pierna.
La secuencia conserva los 1,59 s y la ventana de intercepción física.
[Investigación de FC/Football Strike, diagnóstico y resultados](../../docs/research/keeper-dive-2026-10-10/aplicado.md).

La corrección del 11 de octubre separa los recorridos de brazos y guantes durante
todo el ciclo. En medias/altas, la mano principal se extiende y el apoyo queda
bajo, junto a su propio hombro; durante la caída cada mano usa su propio carril.
La revisión incluye la cámara real detrás del arquero y una regresión de cruces
de antebrazos, dedos y siluetas, además de conservar la guardia abierta.
[Diagnóstico, referencias y capturas de manos](../../docs/research/keeper-hands-2026-10-11/aplicado.md).

```sh
godot --headless --path apps/free-kick-3d --script res://tests/striker_animation_test.gd
godot --headless --path apps/free-kick-3d --script res://tests/keeper_animation_test.gd
godot --headless --path apps/free-kick-3d --script res://tests/animation_flow_test.gd
```

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


La corrección de manos usa `keeper_glove_motion.gd`: IK de brazo/antebrazo sobre
poses clave, orientación de la palma y guantes separados en atajadas bajas.
`tests/keeper_glove_pose_test.gd` comprueba orientación, alineación de muñeca,
longitudes, continuidad y simetría. El diagnóstico y las capturas están en
[`manos-diagnostico.md`](../../docs/research/fifa-animation-2026-10-09/manos-diagnostico.md).
Los guantes actuales no tienen pesos en los dedos, así que su forma sigue siendo
rígida; mover falanges no deforma esta malla.

### Decisiones, pistas y aprendizaje

Durante los últimos 0,35 segundos de preparación del rival, el cuerpo hace
un ajuste pequeño: giro de unos seis grados y una inclinación leve según
la altura. La carrera conserva el mismo recorrido, sin desplazarse al lado
del remate. El HUD solo muestra «¡Remate!», sin revelar dirección ni altura. El destino
real se elige una vez antes de preparar y se conserva hasta el contacto. Se puede mover la mira y estirarse durante la
carrera, también con teclado y táctil. Anticiparse demasiado puede dejar al
arquero en recuperación cuando llega la pelota.

En el 30 % de los remates laterales, el rival prepara el cuerpo hacia un lado
y tira cruzado al contrario. El amague también se decide antes de la estirada
del jugador; no cambia el destino en respuesta a su elección. Esperar la
salida de la pelota permite confirmar el lado real y atajar. Si el jugador
sigue la pista falsa y recibe un gol, el mensaje posterior explica el remate
cruzado. `tests/crossed_shot_test.gd` verifica remates normales y cruzados a
ambos lados, y que el remate cruzado siga siendo atajable.

Después de cada tiro aparece una explicación en el panel inferior durante
2,3 segundos: margen de la mira, desvío por timing, colocación del tiro,
elección de lado o altura al defender y estirada temprana o
tardía. Las pistas y las estiradas se congelan durante la pausa; al cambiar de
turno se cancelan las acciones pendientes.

Prueba del duelo y sus decisiones:
`godot --headless --path apps/free-kick-3d --script res://tests/skill_play_test.gd`.
Esta primera mejora mantiene los controles de tiro actuales; los tipos de
remate, efecto controlable, barreras y entrenamiento quedan para una siguiente
iteración.

El final de la atajada lateral conserva una postura baja de costado hasta el
siguiente tiro. Al retener, el cuerpo completa la caída y los guantes sujetan
la pelota por sus palmas; la guardia abierta vuelve solamente con el reinicio.
La técnica y las capturas se documentan en
[`keeper-recovery-2026-10-13.md`](../../docs/research/keeper-recovery-2026-10-13.md).
`tests/keeper_ground_finish_test.gd` cubre caída, retención, final y reinicio en
ambos arqueros y a tres alturas.
