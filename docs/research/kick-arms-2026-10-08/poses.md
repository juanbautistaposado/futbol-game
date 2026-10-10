# Auditoría visual: brazos y manos de PLAYER al patear

Fecha: 2026-10-08. Skills leídos: `godot-animation`, `create-game-assets`.

## Evidencia observada en el proyecto

- `full-player-front.png`: los brazos se abren simétricamente y las palmas miran hacia la cámara, una postura de presentación del modelo.
- `full-player-kick.png`: en la captura próxima al impacto ambos brazos bajan casi rectos. La pierna sí comunica una patada, pero las manos quedan rígidas y los dedos separados.
- `full-player-pose-a.png`: es la pose de reposo técnica, útil para revisar skinning, pero no debe emplearse como postura lista para patear.
- `full-player-gameplay.png`: desde la cámara trasera los brazos cuelgan y las manos sobresalen lateralmente, sin gesto de equilibrio.
- `kicker.gd`: la liberación de pelota se hace a los 0,48 s; el comentario identifica frame 15 (~0,47 s) de Kick. No modificar este evento ni las pistas de piernas para arreglar brazos.
- `build_footballer_v3.py`: los clips originales se retargetearon con IK sobre las posiciones de las manos del rig antiguo, conservando el gesto original simplificado. No constituyen captura de movimiento futbolístico.
- `rig_meshy_player.py`: las influencias de los brazos generados son `UpperArm`, `Forearm` y `Hand`. Los dedos de Meshy reciben `Hand`; no se asignan a las cadenas de dedos. Animar dedos existentes no curvará esos vértices.

## Dirección propuesta: jugador diestro, balance asimétrico

Inferencia artística, pendiente de validación con referencias de biomecánica del otro agente: usar el brazo izquierdo abierto para contrapeso, derecho más flexionado y próximo al cuerpo. Cambiar primero el gesto de hombro/codo/muñeca; la silueta del brazo tiene mucha más lectura desde la cámara de juego que cada dedo. Las palmas deben apuntar aproximadamente hacia el suelo o el torso, nunca ambas frontalmente como en pose A.

### Objetivos concretos de pose

Coordenadas de referencia en metros del modelo normalizado: X positivo hacia la derecha del jugador, Y altura, Z hacia delante. Altura total 1,899 m; hombros aproximados `(±0,207; 1,524; 0,019)`. Son guías de silueta y de plano de codo, **no posiciones finales para trasladar huesos**. Resolver rotaciones usando longitudes originales (~0,282 m UpperArm, ~0,254 m Forearm) y el hombro animado de cada frame. Ajustar el punto de mano dentro del alcance para evitar extensiones de la malla.

| Fase | Tiempo | Codo izquierdo | Muñeca izquierda | Codo derecho | Muñeca derecha | Lectura |
|---|---:|---|---|---|---|---|
| Idle/listo | 0,00 | (-0,283; 1,261; 0,078) | (-0,313; 1,040; 0,190) | (0,285; 1,261; 0,084) | (0,300; 1,040; 0,207) | Brazos cerca del torso, codos suaves, muñecas adelantadas, manos relajadas. |
| Preparación | 0,20 | (-0,443; 1,390; 0,100) | (-0,584; 1,350; 0,300) | (0,320; 1,300; -0,120) | (0,355; 1,100; -0,265) | Izquierdo abre, derecho va atrás con la pierna que carga. |
| Aproximación | 0,33 | Interpolación de preparación a contacto | Interpolación de preparación a contacto | Interpolación de preparación a contacto | Interpolación de preparación a contacto | Asimetría progresiva, sin salto al llegar al balón. |
| Contacto | 0,47–0,48 | (-0,453; 1,405; 0,097) | (-0,582; 1,480; 0,300) | (0,308; 1,290; -0,100) | (0,275; 1,250; 0,150) | Izquierdo afuera y algo elevado; derecho flexionado, mano a cintura y hacia delante. |
| Continuación | 0,65–0,70 | (-0,435; 1,370; -0,015) | (-0,455; 1,120; -0,100) | (0,254; 1,335; 0,225) | (0,035; 1,390; 0,345) | Derecho acompaña al frente/hacia centro; izquierdo baja atrás, evita cruce por la camiseta. |
| Recuperación | 0,90–0,93 | Pose Idle | Pose Idle | Pose Idle | Pose Idle | Vuelta suave al listo. |

Limitar el giro de muñeca a un gesto moderado (~10–25°), sin quiebres. No bloquear codos a 180°. El brazo izquierdo en impacto debe formar una silueta clara contra el césped incluso con PLAYER pequeño en pantalla.

### Manos

La prioridad inmediata es corregir la palma: dejar de mostrar ambas palmas frontalmente. Orientar palma izquierda abajo y ligeramente hacia delante; derecha hacia el torso. Si se conserva la malla actual, las rotaciones Hand harán visible ese cambio, pero los dedos seguirán rígidos abiertos. Curvar los dedos requiere corregir pesos hacia huesos de dedos o deformar de forma controlada la mano en el DCC; no fingir que insertar pistas de dedos basta. Evitar cerrar un puño completo: mano semicurvada, dedos próximos, pulgar separado leve. Preservar volumen y uñas, no escalar la palma.

## Implementación sugerida y guardas

Preferencia: autorar pistas de rotación nuevas para `UpperArm.L/R`, `Forearm.L/R`, `Hand.L/R` dentro de los clips Idle y Kick, conservando todos los demás canales bit a bit. Si se usa un editor de clips en runtime, duplicar la AnimationLibrary y los Animation antes de editar, para no compartir cambios con arqueros u otros avatares. Rotaciones locales por Quaternion, con objetivos resueltos en el espacio del skeleton y convertidos por la transformación del padre; no tratar objetivos globales como eulers locales.

No tocar rest transforms, inverse bind matrices, nombres/jerarquía de 53 huesos, posiciones/escalas de bones, tracks Root/Hips/Chest/legs ni la longitud de los clips. El hombro debe heredar naturalmente la inclinación existente de Chest. Clavícula opcional sólo si aparece una mala unión, evitando nuevas traslaciones.

Usar entrada/salida a Kick con mezcla breve ~0,08–0,10 s y mismo primer/último gesto que Idle; una mezcla larga desplaza visualmente el contacto del pie y no conviene. La documentación oficial expone `custom_blend` en AnimationPlayer.play; conservar el callback de pelota a los 0,48 s. [Godot AnimationPlayer](https://docs.godotengine.org/en/stable/classes/class_animationplayer.html)

Godot dispone de pistas 3D de rotación por Quaternion e inserción de claves, adecuadas para reemplazar únicamente los canales del brazo. [Godot Animation](https://docs.godotengine.org/en/stable/classes/class_animation.html)

La rotación de pose del bone es local respecto al padre, por lo que la conversión desde una pose objetivo debe respetar ese espacio. [Godot Skeleton3D](https://docs.godotengine.org/en/stable/classes/class_skeleton3d.html)

Validar imágenes Idle, preparación, impacto y continuación desde frontal, lateral y cámara del juego. Comprobar ausencia de brazos atravesando camisa, codos sin inversión, muñecas sin torsión extrema y pie–balón dentro del umbral existente (<0,42 m), en ambos sentidos del campo. Si se alteran pesos de manos, comprobar además suma=1, máximo cuatro influencias, sólo 53 bones y UV/texturas sin cambios. La aprobación visual exige ver el movimiento, no únicamente una pose congelada.

## Verificación visual de la implementación

Revisadas las seis capturas `listo-frente`, `preparacion`, `contacto-frente`, `continuacion`, `contacto-espalda` y `contacto-cancha` tras la edición del source Meshy.

Resultado: **el gesto ahora comunica una patada y cumple la mejora solicitada**. La postura lista muestra codos flexionados, manos próximas a cintura y dedos menos rígidos; la preparación introduce asimetría. Al contacto el brazo contrario a la pierna que patea se abre para balance mientras el otro flexiona hacia cintura. La continuación cambia de manera coherente la altura del brazo abierto, evitando una pose única mantenida durante toda la patada. En la cámara trasera del estadio la silueta se entiende claramente a escala real de juego.

No detecté penetraciones materiales de mano en camiseta ni rupturas de hombro/codo/muñeca en las capturas. La mano cercana al torso se superpone visualmente en frontal y queda parcialmente oculta en espalda, compatible con la perspectiva; una comprobación lateral/movimiento permite confirmar el margen, pero no hay evidencia estática que justifique rehacer la pose. Los hombros mantienen continuidad con las mangas. La mano abierta conserva algo de separación entre dedos, aunque la curvatura es más natural y su lectura pequeña es adecuada.

La postura sigue siendo una animación estilizada; las capturas no prueban por sí mismas fidelidad biomecánica exacta ni continuidad en cada frame. Según la auditoría técnica comunicada por el implementador, los demás canales siguen exactos, el rig mantiene 53 huesos y las pruebas de codos/contrapeso y contacto pie–balón pasaron. No solicito corrección adicional porque no observé un problema visual material.
