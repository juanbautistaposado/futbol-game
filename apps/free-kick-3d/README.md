# Tiros Libres 3D — Fase 1

Vertical slice en Godot 4, aislado del MVP Phaser. Incluye un duelo individual completo: cantidad configurable de turnos de patear y atajar, muerte súbita, tiro con dirección/altura/potencia, atajada dirigida, IA con lectura parcial del tiro y récord local persistido en el dispositivo.

## Ejecutar

1. Instalar Godot 4.x y abrir esta carpeta como proyecto.
2. Ejecutar el proyecto con `F5`: abre la pantalla inicial `Menu.tscn`. `Main.tscn` con `F6` permite probar directamente el duelo.

La pantalla inicial conserva el diseño del MVP 2D: mejor marca, dificultad fácil/media/difícil y botón JUGAR. ASPECTO permite guardar nombre, número y cabello del arquero propio. La dificultad modifica la reacción, el alcance y la precisión del arquero rival. `Esc` o el botón PAUSA abre la pausa: CONTINUAR reanuda y SALIR AL INICIO abandona el partido. La pausa congela la física, las animaciones y los temporizadores de turnos.

CONFIGURAR permite ajustar y guardar el volumen. Los efectos incluyen patada, contacto con guantes, palo, red y ambiente de tribuna. Al entrar la pelota se oye una voz que grita «¡Gol!» sobre una celebración breve; todo comparte el control de volumen. Los efectos de tribuna se regeneran con `python3 apps/free-kick-3d/tools/generate_sfx.py`.

CONFIGURAR también guarda la calidad gráfica: BAJO desactiva sombras y MSAA, MEDIO usa sombras y MSAA 2×, y ALTO usa sombras y MSAA 4×. El perfil se aplica tanto al menú como al partido; no altera colisiones ni dificultad. `tools/benchmark_graphics.gd` mide una escena de partido a 1280 × 720 con una estirada del arquero.

Controles de tiro: apuntar al arco con el mouse; mantener clic, toque o `Espacio` para cargar y soltar cerca del centro verde de la barra de precisión. La barra azul indica potencia. Un mal timing desvía físicamente el tiro hacia el lado apuntado.

Controles de atajada: sobre el arco aparece solo una mira, sin cuadrícula. Con mouse, mover el cursor previsualiza el destino y el clic inicia la estirada. En pantalla táctil, tocar y arrastrar mueve la mira; al soltar se estira. Se puede elegir cualquier punto intermedio, incluidos los sectores altos apenas a un lado del centro. También `←`/`→` (estirada lateral) y `Espacio` o `↓` (centro). `W`/`↑` selecciona estirada alta y `S` baja. Al salir el tiro aparece su sector y altura; conviene esperar el disparo para estirarse, porque la estirada tiene impulso, caída y recuperación.

El arquero rival reacciona con demora y una lectura imperfecta del destino del tiro. Las atajadas se resuelven por contacto con la pelota.

La defensa manual mantiene la elección inmediata del sector, sin seguimiento automático de la pelota. El disparo de la IA tarda 1,22 s en llegar al arco; la extensión del arquero dura un poco más para permitir reaccionar al remate. `res://tests/keeper_save_balance_test.gd` comprueba tiros al centro, bajos y altos a ambos lados, además de elecciones equivocadas.
Al atajar, la red propia se vuelve semitransparente para despejar la vista de la pelota y el pateador sin desaparecer. Los postes siguen visibles y la red recupera su intensidad en el impacto de un gol, con su ondulación.
Las estiradas laterales llegan a los cuatro ángulos con contacto físico de cuerpo y brazos. Los tiros bajos usan clips propios, con los guantes más cerca del césped; elegir mal el lado o la altura sigue dejando pasar la pelota. `res://tests/keeper_corner_ai_test.gd` verifica también el alcance del arquero rival.

Al tocar JUGAR aparece CONFIGURAR RONDA: de 1 a 4 jugadores y de 5 a 15 tiros por persona (7 por defecto). La selección se guarda al tocar EMPEZAR. Con un jugador se alternan tiros y atajadas contra la IA, con muerte súbita si hay empate. Con varios jugadores se alterna un tiro por persona contra el arquero IA, con marcador individual y empate permitido al agotar los tiros.

Al finalizar se muestra el resultado durante tres segundos y se vuelve automáticamente al inicio. `Espacio` permite volver antes. Los récords se guardan por cantidad de tiros.

El estadio conserva geometría generada por código. Los futbolistas actuales usan GLB originales del proyecto; su procedencia está en `ASSET-LICENSES.md` y `source-assets/footballer/`.

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
Las mallas visibles originales se generan en Blender desde
`tools/build_original_footballer.py`; siguen siendo estilizadas y no son
modelos fotorealistas ni un escaneo del deportista.

El selector de delantero incluye PERSONALIZADO: nombre, dorsal, piel, cabello, barba, camiseta y short, con vista previa y guardado inmediato. ELEGIR ARQUERO permite seleccionar un personaje ficticio o usar AL AZAR. Las elecciones se mantienen al iniciar la partida.

Arquero y delantero comparten el editor PERSONALIZADO. Sus colores, barba, nombre y número se guardan por separado; editar uno no modifica al otro.

Los personajes usan contornos suavizados, hombros y piernas con mayor volumen, uniformes con pliegues, ribetes y medias a franjas. Rodillas y codos articulan la preparación del tiro y la postura del arquero; los shorts acompañan al muslo. Se conservan las personalizaciones independientes de delantero y arquero.

El cuerpo y rostro v2 se usan ahora en todos los personajes. El delantero usa
`footballer_v2.glb` con manos libres y clips de patada; los arqueros usan
`goalkeeper_v2.glb` con guantes y clips de atajada. Ambos conservan párpados,
nariz y boca más definidos y un emblema con franjas propias en la camiseta.
El tono de esos detalles se deriva del color de piel y camiseta elegidos; el
nombre y dorsal siguen siendo editables.

### Personajes 3D originales

Los personajes visibles del delantero y del arquero se exportan desde los
archivos editables `.blend` de `source-assets/footballer/` como GLB con un
esqueleto compartido. El generador reproducible es
`tools/build_original_footballer.py` (ejecutar desde la raíz del repositorio
con `blender -b --factory-startup --python apps/free-kick-3d/tools/build_original_footballer.py -- --goalkeeper-v2`
para las dos variantes v2).
Las animaciones importadas cubren espera, patada, atajadas laterales, captura
y celebración, con variantes altas y bajas para las estiradas. `kicker.gd` y `keeper.gd` mantienen el momento de contacto y
la lógica de juego; `footballer_visual.gd` aplica colores independientes para
cada personaje. La meta visual es el realismo deportivo simplificado de
Football Strike, usando modelos originales.
