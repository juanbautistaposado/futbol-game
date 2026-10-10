# Brazos y manos para un tiro libre diestro

Investigación: 8 de octubre de 2026. Alcance: postura y animación del delantero; no modificar cara, botines, escala, colores, rig ni contacto de la pelota. Las recomendaciones siguientes son una adaptación visual al juego, no mediciones clínicas ni captura de movimiento.

## Evidencia y referencias primarias

**Shan y Westerhoff, 2005 — Full-body kinematic characteristics of the maximal instep soccer kick.** El estudio usa un modelo tridimensional de cuerpo completo y compara jugadores entrenados con principiantes. Identifica la contribución del movimiento superior a la cadena del golpeo y propone la distancia entre cadera del lado que patea y hombro contrario como indicador. Esto justifica animar hombros y brazos de manera coordinada con el tiro. El resumen no proporciona ángulos de dedos ni una postura universal de mano. [Publicación original, DOI 10.1080/14763140508522852](https://pubmed.ncbi.nlm.nih.gov/15807377/).

**FIFA — Beckham contra Ecuador, Mundial 2006.** Video oficial verificado mediante reproducción pausada y avance por cuadros. La repetición cercana alrededor de 0:27–0:29 permite ver una secuencia diestro: antes del contacto el brazo izquierdo se abre ampliamente, aproximadamente a la altura del hombro; el derecho queda más bajo, junto al costado. Durante el seguimiento ambos cambian con el giro del cuerpo; no permanecen en una A simétrica. En estas imágenes las manos no muestran una palma frontal de presentación. La resolución y el movimiento impiden medir articulaciones de los dedos. Usar la secuencia como referencia de silueta, no copiar exactamente el estilo exagerado de Beckham. [Video oficial de FIFA](https://www.youtube.com/watch?v=PM79nfZr30I&t=27s).

**FIFA Training Centre — tiros libres de media distancia.** Reúne ejemplos de Beckham, Trippier, Ronaldo y Zico, y también zurdos. Destaca la variación entre ejecuciones, carrera y tipo de golpeo. Para el jugador diestro del proyecto conviene usar Beckham o Trippier como guía y evitar copiar la lateralidad de Kolarov o Messi. [Análisis oficial y ejemplos](https://www.fifatrainingcentre.com/en/game/game-analysis/set-plays/set-play-routines/direct-free-kicks-why-mid-range-means-maximum-threat.php).

**Chen, Chang y Lin — The kinematics chain of instep kicking of soccer with upper-body constrained: a pilot study.** Compara golpeos con y sin movimiento de brazos mediante captura VICON. La condición con brazos obtuvo mayor velocidad de pelota y segmentos inferiores. Es un piloto de un solo participante: evidencia de apoyo, insuficiente para imponer ángulos universales. [Trabajo original del congreso ISBS](https://ojs.ub.uni-konstanz.de/cpa/article/view/6009/5490).

## Objetivo de animación para el juego

Esta tabla es una propuesta artística derivada de las referencias anteriores. Sus rangos son puntos iniciales de ajuste visual; no valores medidos en los estudios.

| Fase | Brazo izquierdo, lado de apoyo | Brazo derecho, lado del golpeo | Manos |
| --- | --- | --- | --- |
| Preparación / Idle | Bajo, ligeramente separado del torso; codo flexionado | Un poco más atrás o cerca de cintura; diferente al izquierdo | Dedos juntos con curvatura suave; pulgar junto al índice; palma hacia el muslo o adentro |
| Armado | Se abre lateralmente y algo hacia atrás, con alcance visible | Más bajo y recogido, acompaña la carrera | Mantener curvatura suave, sin abanico de dedos ni puño rígido |
| Contacto | Aún separado como contrapeso, empieza a acompañar la rotación | Se desplaza hacia adelante, sin atravesar el torso | Muñeca neutra o levemente flexionada; evitar mostrar ambas palmas a cámara |
| Seguimiento | Baja progresivamente y vuelve hacia el cuerpo | Avanza con el giro y luego recupera posición | Recuperación continua, sin cambio instantáneo de apertura |

Como primera aproximación: codos en preparación con 25–45° de flexión; brazo izquierdo en armado/contacto con 45–75° de separación respecto al torso; derecho más recogido, con 35–70° de flexión de codo. Ajustar estos valores a la silueta del personaje y sus ejes óseos. No levantar ambos brazos por igual ni fijar todas las fases en esos valores.

## Aplicación segura al proyecto

- `kicker.gd` lanza `Kick` y libera la pelota a los 0,48 s; el comentario sitúa contacto del botín derecho en aproximadamente 0,47 s. Mantener ese momento y las pistas de piernas/pelvis existentes.
- Corregir únicamente hombro/brazo/antebrazo/mano y dedos si los grupos de vértices realmente existen. Revisar pesos de dedos del PLAYER generado: si todos están unidos rígidamente a `Hand`, rotar huesos de dedos no cambiará su silueta.
- Preparación deportiva es parte del resultado: el usuario ve `Idle` antes de patear; mejorar sólo el cuadro de contacto dejaría las palmas abiertas visibles durante todo el apuntado.
- Los huesos deben conservar nombres, jerarquía y bind pose. Editar las pistas de rotación de animación o aplicar una capa de pose; no aplicar modificador Armature ni cambiar rest pose.
- Revisar frente, espalda y tres cuartos en Idle, armado, contacto y seguimiento. Comprobar que muñecas no colapsen, dedos no se crucen y manos/mangas no atraviesen torso. Validar después celebración, cambio de turno y sincronización del botín con pelota.

## Criterio de aceptación visual

El jugador espera con brazos bajos y codos suaves. Al patear aparece una silueta asimétrica de contrapeso: izquierdo amplio, derecho más recogido, seguida por recuperación. Las manos parecen relajadas y activas; no parecen una presentación del modelo en pose A ni un gesto de portero. No afirmar que esta animación reproduce exactamente Football Strike ni a un futbolista real.
