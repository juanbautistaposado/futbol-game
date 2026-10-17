# Football Strike: referencia para mejorar la tirada

Investigación: 10 de octubre de 2026. Alcance: impulso, vuelo, manos, caída y recuperación. La guardia previa debe conservar la pose de brazos abiertos que pidió el usuario en su fotografía.

## Fuentes primarias y hechos comprobados

Miniclip presenta Football Strike como un juego de duelos de tiros libres. Su ficha publicada por Miniclip describe controles de tiro y atajada mediante un gesto de dedo, y una experiencia rápida. Esto respalda priorizar una acción legible y breve; no publica valores de su rig, curvas ni duración de atajadas. [Página de Miniclip](https://www.miniclip.com/games/football-strike), [ficha de Google Play](https://play.google.com/store/apps/details?id=com.miniclip.footballstrike&hl=en).

Se observó el trailer integrado en la página oficial mediante reproducción y pausas en navegador, sin descargar ni reutilizar el material. El video dura aproximadamente 30 segundos. [Trailer alojado por Miniclip](https://static-prod-web.miniclip.com/assets/games/FootballStrike/Football%20Strike%20Trailer-SlAHv6D2DOw.mp4).

### Observación visual del trailer

Estas observaciones describen fotogramas del trailer; no revelan la implementación interna. Los tiempos son aproximados dentro del montaje.

| Momento | Observación |
| --- | --- |
| ~12–13 s, vista desde atrás del arquero | La mano principal sube antes que la otra; el segundo brazo queda bajo. El torso se inclina y las piernas dejan de ser simétricas. La palma principal se presenta abierta al balón. |
| ~14 s, vista desde el pateador | El arquero baja y carga lateralmente antes de quedar horizontal. Un brazo se adelanta y la otra mano acompaña cerca de la cabeza. Una rodilla queda más flexionada. |
| ~14–15 s | El cuerpo llega al césped; las piernas aún están levantadas mientras el tronco ya descansa. Luego los codos aparecen flexionados cerca del piso. |

El último ejemplo termina en gol: el arquero se tira bajo mientras el balón va arriba. Sirve como referencia de movimiento, no de precisión de alcance. El montaje no muestra una incorporación completa; no se puede atribuir una secuencia exacta de recuperación a Football Strike. [Video oficial](https://static-prod-web.miniclip.com/assets/games/FootballStrike/Football%20Strike%20Trailer-SlAHv6D2DOw.mp4).

## Diferencia útil con EA SPORTS FC

EA confirma para FC 26 nuevas animaciones de arquero basadas en captura volumétrica, lectura refinada de trayectorias y acciones diferenciadas de atajada. También aclara que el posicionamiento por aprendizaje por refuerzo no interviene en atajar ni atrapar. [Pitch Notes, sección Goalkeeper](https://www.ea.com/games/ea-sports-fc/fc-26/news/pitch-notes-fc26-gameplay-deep-dive#goalkeeper).

**Interpretación de diseño:** Football Strike aporta claridad desde una cámara cercana y ritmo breve para el duelo; FC aporta el criterio de variar la acción por situación y altura. Nuestro juego puede combinar ambos sin replicar sus clips: un movimiento corto cuya silueta y contacto sean coherentes con el destino elegido. El trailer no justifica afirmar que Football Strike usa IK, mocap o una técnica concreta.

## Propuestas originales para este proyecto

Estos valores son candidatos de autoría propia para el ciclo actual de 1,59 s. No son mediciones de Football Strike ni de FC.

| Fase del juego | Propuesta y motivo |
| --- | --- |
| 0–0,09 s: carga | Conservar el primer fotograma de guardia. Cargar el muslo del lado de salida y bajar la pelvis; el brazo principal comienza a buscar el destino. Evita que el cuerpo parezca una tabla rotada. |
| 0,09–0,25 s: impulso | Estirar progresivamente la pierna de apoyo y flexionar la otra. El alcance empieza antes de que el torso llegue a su inclinación máxima. |
| 0,25–0,45 s: alcance | Priorizar una palma principal abierta. La segunda sigue con un retraso moderado y permanece más cerca del torso en tiros altos; acompaña encima de la principal en tiros bajos. Evitar copiar simétricamente los dos brazos. |
| 0,45–0,77 s: final de vuelo | No congelar todo el esqueleto: permitir una pequeña continuación de pelvis, rodillas y brazo secundario. Mantener el alcance útil y la ventana de colisión existente. |
| 0,77–1,01 s: caída | Reducir altura de pelvis y flexionar progresivamente codos y rodillas. El contacto con el césped debe mostrar absorción, con cuello y manos fuera del suelo. |
| 1,01–1,21 s: apoyo | Mantener una breve postura de apoyo estable antes de elevarse. Separar la posición lateral del tronco de la recuperación de brazos. |
| 1,21–1,59 s: recuperación | Subir el torso desde apoyo de brazo/rodilla hacia guardia. No levantar un cuerpo entero rígido mediante la rotación del nodo raíz. Esta incorporación es una propuesta propia, no algo comprobado en el trailer. |

La corrección debe comenzar en el esqueleto y su relación con la rotación de `keeper.gd`; el alcance físico no debe ampliarse para disimular una palma que no llega. El giro global y las rotaciones locales se suman: revisar su composición en espacio mundial, tanto para atajadas altas como bajas.

En Godot 4.7 se pueden conservar pistas de posición y rotación 3D en los clips de `keeper_animation.gd`. Godot recomienda esas pistas dedicadas para transformaciones 3D y permite interpolar sus claves. [Animation](https://docs.godotengine.org/en/4.7/classes/class_animation.html).

Para la cadena de brazo, usar un objetivo de muñeca y una guía de codo estable; orientar después la palma. TwoBoneIK3D exige una guía y advierte evitar que su dirección sea colineal con el eje de avance. El helper actual de guantes puede aplicar el mismo criterio al generar claves, sin cambiar obligatoriamente a un modificador por fotograma. [TwoBoneIK3D](https://docs.godotengine.org/en/4.7/classes/class_twoboneik3d.html).

## Verificación propuesta

- Capturar ambas direcciones y dos alturas desde la cámara real; además revisar frontal y lateral cerca de manos/codos.
- Muestrear a 60 Hz la continuidad de brazo y muñeca, y comprobar que el codo no cambia de lado al pasar por una extensión casi recta.
- Comprobar separación de guantes y composición del giro en espacio mundial durante vuelo y caída.
- Ejecutar las pruebas existentes de guardia, contacto, animación y balance de atajadas para mantener la pose aprobada y la dificultad del juego.
- Comparar una secuencia completa, no solo el fotograma de máximo alcance: el problema puede estar en aterrizar y levantarse aunque la palma esté bien orientada.

No se extrajeron clips, código ni assets de Football Strike o FC.
