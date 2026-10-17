# Manos del arquero: técnica, orientación y corrección del rig

Consulta: 9 de octubre de 2026. Fuentes primarias: FIFA Training Centre, EA,
documentación versionada de Godot 4.7 y una tesis de investigación original.
Las recomendaciones de implementación son propias; no son curvas extraídas de FIFA.

## Diagnóstico que motiva la corrección

La versión previa de `keeper_animation.gd` animaba brazo y antebrazo tomando
poses de atajada a los 0,30 s, pero su lista `POSE_BONES` excluía `Hand.L`,
`Hand.R` y dedos. `_complete_pose` rellenaba esos canales con la rotación fuente
a los 0,0 s durante todo el clip. La guardia también flexionaba antebrazos y
mezclaba brazos de Catch con manos de Idle. Son combinaciones incoherentes,
verificables en el código anterior a esta reparación.

La [captura previa](capturas/arquero-antes.png) muestra los dos guantes dirigidos
de forma distinta durante el alcance; el guante inferior parece caer desde la
muñeca. La imagen confirma el problema visual, aunque por sí sola no distingue
si todo el defecto proviene de la animación o también del skinning.

## Referencia técnica real

| Acción | Evidencia de FIFA | Consecuencia para el gesto propio |
|---|---|---|
| Retención frontal | Ambas manos llegan juntas, a igual nivel, con antebrazos algo flexionados; contacto delante del rostro. | Evitar codos bloqueados y muñecas caídas; definir palma y dedos como parte de la pose de recepción. |
| Baja | Palma inferior detrás del balón y superior encima; el suelo ayuda a asegurar la retención. | Las manos necesitan orientaciones diferentes y contacto próximo al suelo. |
| Media | Palmas abiertas y firmes, cercanas; retención bilateral cuando hay alcance y desvío unilateral cuando no lo hay. | No imponer dos brazos paralelos para todos los destinos. |
| Alta/lejana | Palma abierta y firme; en los ejercicios hacia un lado cambia la mano usada según altura o distancia. | Diferenciar brazo que alcanza y brazo que acompaña, sin copiar literalmente derecha/izquierda del ejercicio a ambos lados. |

Fuentes: [FIFA, Learning to catch](https://www.fifatrainingcentre.com/en/environment/fifa-goalkeeper-training/goalkeeping-fundamentals/learning-to-catch.php),
[Learning to dive low](https://www.fifatrainingcentre.com/en/environment/fifa-goalkeeper-training/goalkeeping-fundamentals/learning-to-dive-low.php),
[Learning to dive at mid-height](https://www.fifatrainingcentre.com/en/environment/fifa-goalkeeper-training/goalkeeping-fundamentals/learning-to-dive-at-mid-height.php) y
[Learning to dive high](https://www.fifatrainingcentre.com/en/environment/fifa-goalkeeper-training/goalkeeping-fundamentals/learning-to-dive-high.php).

La guardia depende del contexto. El análisis de FIFA de tiros desde más de seis
metros describe manos bajas y pies apoyados antes del impacto; el X-block cercano
usa brazos abiertos y dedos extendidos. Para el tiro libre de este juego conviene
una guardia baja disponible para ambos lados, sin anticipar un bloqueo cercano.
Fuente: [FIFA, Making close-range saves](https://www.fifatrainingcentre.com/en/game/tournaments/fcwc/2025/team-analyses/goalkeeping-making-close-range-saves.php).

## Qué aporta la búsqueda de FIFA/EA FC

EA confirma para FC 26 animaciones de arqueros basadas en captura volumétrica,
lectura de trayectorias y mejoras de manejo y desvíos. Su posicionamiento por
aprendizaje reforzado se limita a posicionar al arquero y no actúa en atajada o
retención. No publica allí curvas de muñeca ni parámetros articulares que se
puedan trasladar a este rig. La referencia útil es la respuesta contextual y la
calidad de continuidad. Fuente: [EA, FC 26 Gameplay Deep Dive](https://www.ea.com/games/ea-sports-fc/fc-26/news/pitch-notes-fc26-gameplay-deep-dive#goalkeeper).

## Mejor arquitectura si hace falta adaptación al balón

El trabajo original de Cormac Doyle separa dos problemas: colocar la mano y
orientar su palma. Usa IK de dos huesos para brazo/antebrazo y guía de codo
externa y posterior; otro constraint dirige la palma. Mezcla la corrección sólo
cerca del balón y la retira cuando se completa o falla el contacto, porque un IK
siempre activo hace que el personaje persiga continuamente la pelota.
Fuente: [Doyle, Real-Time Physics-Based Goalkeeper Animations, pp. 29–31](https://publications.scss.tcd.ie/theses/diss/2022/TCD-SCSS-DISSERTATION-2022-033.pdf#page=30).

Para este proyecto la primera intervención debe ser corregir los canales
completos de manos en las poses y validar el skinning. Si la pelota real todavía
queda fuera de las palmas, la extensión recomendada es una corrección breve de
IK sobre esas poses, conservando la trayectoria y reglas existentes. Esta
prioridad es una decisión de diseño propia, no una conclusión cuantitativa de
la tesis.

### API de Godot 4.7 verificada

- `SkeletonModifier3D` se procesa después de `AnimationMixer` y recibe su
  esqueleto del padre. Para una corrección propia usar
  `_process_modification_with_delta(delta)`; el engine aplica `influence`, por
  lo que no debe aplicarse esa influencia una segunda vez dentro del solver.
  Fuente: [Godot 4.7, SkeletonModifier3D](https://docs.godotengine.org/en/4.7/classes/class_skeletonmodifier3d.html).
- `TwoBoneIK3D` requiere pole target y resuelve mediante rotaciones. Su dirección
  de pole y vector de avance no deben ser colineales para evitar giros
  involuntarios. Cadena sugerida: UpperArm, Forearm, Hand, con pole de cada codo
  derivado de su lado anatómico. Fuente: [Godot 4.7, TwoBoneIK3D](https://docs.godotengine.org/en/4.7/classes/class_twoboneik3d.html).
- La pose global de un hueso es relativa a `Skeleton3D`, no al mundo; transformar
  explícitamente objetivos y bases entre esos espacios. `skeleton_updated`
  informa que terminó el procesamiento de modificadores; leer allí la pose
  final para contacto y captura. Los antiguos global pose overrides están
  deprecados. Fuente: [Godot 4.7, Skeleton3D](https://docs.godotengine.org/en/4.7/classes/class_skeleton3d.html).
- `LookAtModifier3D` permite configurar `forward_axis`, rotación relativa y
  límites. El modificador del padre debe preceder al del hijo; su documentación
  también advierte cambios de eje al cruzar límites. Fuente:
  [Godot 4.7, LookAtModifier3D](https://docs.godotengine.org/en/4.7/classes/class_lookatmodifier3d.html).

### Criterios concretos de integración y verificación

Estas condiciones son propuestas de este proyecto:

1. Calibrar cada mano desde su rest pose y geometría: eje muñeca→dedos,
   normal de palma y lado del pulgar. No asumir que L/R comparten signo ni que
   el eje forward estándar equivale a la palma.
2. Resolver primero clavícula/brazo/antebrazo y después muñeca y dedos. Conservar
   la traslación y escala del hueso al corregir orientación.
3. Durante el alcance presentar la palma al origen del tiro; en retención
   ajustar ambas hacia la superficie del balón. En baja usar una detrás y otra
   encima. Evitar perseguir la pelota después de que pase el punto de contacto.
4. Distribuir el giro entre antebrazo y mano; si cambiar la muñeca produce un
   estrechamiento severo del guante, revisar pesos y proporción del guante en
   vez de seguir agregando rotación.
5. Comprobar en frontal y lateral guardia, impulso, alcance, caída y reinicio,
   y las variantes izquierda/derecha, alta/baja y central. Medir orientación de
   palma además de posición de muñeca: el test anterior de manos sólo validaba
   posición y no detectaba una palma dada vuelta.

