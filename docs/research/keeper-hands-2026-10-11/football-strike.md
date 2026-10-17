# Football Strike: manos legibles desde detrás del arquero

Investigación: 11 de octubre de 2026. Objetivo: evitar que guantes y antebrazos se crucen durante la tirada, especialmente desde la cámara de arquero. Conservar la guardia de brazos abiertos aprobada por el usuario.

## Evidencia y límites

La [página oficial de Miniclip](https://www.miniclip.com/games/football-strike) sigue disponible. Su [trailer oficial](https://static-prod-web.miniclip.com/assets/games/FootballStrike/Football%20Strike%20Trailer-SlAHv6D2DOw.mp4) fue observado directamente en navegador el 10 de octubre. El 11 se intentó repetir la observación, pero la herramienta de navegador no tenía navegadores disponibles. No se descargó el video ni se presenta esa revisión anterior como una observación nueva.

**Observación directa del 10 de octubre, reinterpretada para este problema:** hacia 12–13 s, desde detrás del arquero, la mano principal sube a un costado de la cabeza mientras el segundo brazo queda más bajo y afuera. Los codos conservan siluetas distintas; las muñecas no convergen en el centro del torso. Hacia 14–15 s, la cámara del pateador muestra una tirada baja con un brazo adelantado y el otro cercano a la cabeza. Ese intento termina en gol; su trayectoria no es referencia de alcance correcto. No hay una vista trasera equivalente de la misma tirada baja ni una medición de profundidad. [Trailer oficial de Miniclip](https://static-prod-web.miniclip.com/assets/games/FootballStrike/Football%20Strike%20Trailer-SlAHv6D2DOw.mp4).

Miniclip no publica aquí posiciones de muñecas, guías de codo, método de IK ni reglas contra cruces. Lo siguiente es una propuesta propia para nuestro rig.

## Restricciones concretas para la animación

| Situación | Propuesta original |
| --- | --- |
| Tirada alta | Mantener la mano principal arriba y hacia el destino. La secundaria puede quedar más baja y cerca de su hombro; no necesita perseguir el mismo punto que la principal. Conservar su codo afuera del torso durante el traslado. |
| Tirada baja | Elegir dos objetivos distintos: principal detrás de la trayectoria del balón y apoyo encima, con diferencia lateral además de altura. La separación en profundidad sola no garantiza que se distingan desde atrás. |
| Caída | Replegar cada brazo hacia un apoyo propio del mismo lado anatómico. Evitar que ambas manos sean recogidas a una zona pequeña de un solo lado del pecho. Mantener orden y separación mientras el nodo raíz gira. |
| Incorporación | Abrir nuevamente desde esos dos apoyos hacia guardia. No pasar ambas muñecas por el centro del torso durante la interpolación. |

**Carriles distintos** significa definir la ruta hombro→codo→muñeca de cada brazo en espacio del torso y verificarla después en espacio mundial. No basta separar las muñecas al final: una interpolación puede cruzar los antebrazos a mitad de camino. Usar guías de codo estables y escoger claves intermedias que mantengan la ruta exterior.

No girar las palmas para mirar a la cámara trasera: deben orientarse al tiro. Desde atrás se verá naturalmente el dorso. La claridad se obtiene con silueta, separación y profundidad; cambiar la orientación por cámara deformaría la intención física.

## Punto concreto del código que merece inspección

En la lectura de `apps/free-kick-3d/keeper_glove_motion.gd`, el objetivo de aterrizaje usa para la muñeca principal `(d·0.28, 1.20, 0.46)` y para la secundaria `(d·0.12, 1.18, 0.42)`, con `d` como dirección lateral. Su separación nominal es unos **0,166 m**. Ambos objetivos quedan al mismo lado del torso y tienen casi la misma altura y profundidad.

Este cálculo no demuestra por sí solo penetración del mesh: la posición final depende de alcance del brazo, pose del torso y giro global. Sí identifica una concentración de objetivos que debe medirse entre 0,77 y 1,21 s. Como los guantes visibles son rígidos, orientarlos bien puede dejar las puntas ocupando el mismo espacio aunque las muñecas estén separadas.

Propuesta: calibrar la separación mínima a partir del ancho real del guante y la dirección de sus dedos; revisar tanto los segmentos de antebrazo como el volumen aproximado de palma/dedos. No reemplazarlo con un umbral fijo de distancia entre huesos que ignore el tamaño de la geometría.

## Validación desde la cámara opuesta

1. Ejecutar las cuatro tiradas laterales desde la cámara de gameplay de arquero, además de la cámara del pateador. Las vistas de preview cercanas sirven como diagnóstico adicional.
2. Muestrear todo el ciclo a 60 Hz; comprobar distancia entre los segmentos codo→muñeca de brazos opuestos y entre los volúmenes de guantes, especialmente durante aterrizaje e incorporación.
3. Proyectar muñeca, palma y punta de dedos con `Camera3D.unproject_position()` y comparar las siluetas de ambas manos en pantalla. Esta API transforma puntos mundiales a coordenadas del viewport. [Godot 4.7, Camera3D](https://docs.godotengine.org/en/4.7/classes/class_camera3d.html#class-camera3d-method-unproject-position).
4. Distinguir **penetración real** de **superposición de perspectiva**. Para lo primero corregir el rig; para lo segundo revisar altura/lateralidad de la mano secundaria y la vista real. No imponer cero superposición visual en todo fotograma: algunos contactos con el balón la admiten. Exigir claridad en impulso, extensión y apoyo.
5. Medir con la rotación completa del personaje: un objetivo separado en el espacio local puede quedar oculto por cabeza/espalda o por el otro brazo tras el giro global.

La recomendación principal de esta referencia es dar funciones y trayectorias distintas a las dos manos. Repetir el mismo objetivo y moverlo apenas en profundidad produce una silueta cruzada desde la cámara trasera aunque una captura frontal parezca correcta.
