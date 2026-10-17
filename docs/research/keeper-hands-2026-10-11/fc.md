# Manos durante la estirada: FC y fundamentos FIFA

11 de octubre de 2026. Revisión específica del cruce de brazos/manos, sobre todo visto desde detrás del arquero. Continúa [la investigación del 10 de octubre](../keeper-dive-2026-10-10/ea-fc.md); conserva la guardia abierta que aprobó el usuario. No se modificaron runtime ni tests.

## Evidencia publicada por FC

EA describe animaciones volumétricas de arquero y control de rechazos. No publica en estas fuentes curvas óseas, polos de codo ni reglas para evitar cruces. El aprendizaje por refuerzo sigue siendo un sistema de posicionamiento; no explica cómo deberían moverse los brazos al atajar. [EA FC 26, Gameplay Deep Dive, Goalkeeper](https://www.ea.com/games/ea-sports-fc/fc-26/news/pitch-notes-fc26-gameplay-deep-dive#goalkeeper).

Para el sistema general de animación, EA explica que distancia a la pelota, ángulo de movimiento y velocidad influyen en la selección de movimientos. Eso respalda buscar variantes según contexto, pero no prueba una implementación concreta para manos de arquero. [EA, Gameplay Responsiveness Update](https://forums.ea.com/blog/ea-sports-fc-game-info-hub-en/ea-sports-fc%E2%84%A2-26--pitch-notes---gameplay-responsiveness-update/12353372).

El [video oficial de FC 26](https://www.youtube.com/watch?v=0GE8YCIQF2M) ya fue localizado en la investigación anterior. Esta revisión intentó abrirlo para observación visual, pero no hay navegador disponible en la herramienta de computadora. **No se observaron ni midieron nuevos fotogramas de FC**. Las recomendaciones siguientes no se presentan como poses extraídas del videojuego.

## Descrito por FIFA: la mano principal depende de la acción

FIFA Training Centre enseña técnica real, no documenta el motor de FC. Sus referencias distinguen:

- **Media altura con recepción:** manos abiertas, firmes y próximas, delante del pecho o debajo del mentón. Si la pelota queda fuera del alcance de ambas, puede rechazar con la mano superior. No requiere que ambos brazos recorran idéntica trayectoria. [Learning to dive at mid-height, ejercicios 1 y 4](https://www.fifatrainingcentre.com/en/environment/fifa-goalkeeper-training/goalkeeping-fundamentals/learning-to-dive-at-mid-height.php).
- **Alta con rechazo:** palma abierta y firme, hombro fuerte y brazo extendido. El ejercicio distingue la mano para pelotas lejanas de la usada para las más altas; al reflejar la acción cambian los lados. Por tanto, una regla absoluta de usar siempre la mano del lado de la estirada sería incorrecta. [Learning to dive high](https://www.fifatrainingcentre.com/en/environment/fifa-goalkeeper-training/goalkeeping-fundamentals/learning-to-dive-high.php).
- **Baja con recepción:** mano inferior detrás de la pelota y superior encima. Para una pelota demasiado lejana se admite rechazo con una sola mano. Las dos palmas no cumplen siempre el mismo papel. [Learning to dive low, ejercicio 4](https://www.fifatrainingcentre.com/en/environment/fifa-goalkeeper-training/goalkeeping-fundamentals/learning-to-dive-low.php).

Estas fuentes no prescriben distancia universal entre muñecas, límite angular de codos ni retraso temporal del brazo secundario.

## Observado en nuestro material y leído en el código

Se revisó [alta-despues.png del 10 de octubre](../keeper-dive-2026-10-10/capturas/alta-despues.png). La cámara frontal muestra principal y secundaria próximas durante el alcance, y la secundaria se recoge ante el torso durante el descenso. Esa captura no permite descartar cruces al verla desde detrás; no es evidencia suficiente para aprobar la trayectoria nueva.

En el `keeper_glove_motion.gd` leído al iniciar esta revisión, ambas muñecas se reúnen al mismo lado del torso durante aterrizaje: `x=direction*.28/.12`, `y=1.20/1.18`, `z=.46/.42`. Los destinos nominales distan aproximadamente **0.166 m**. Es una medida de las coordenadas objetivo, no de las posiciones alcanzadas por IK ni de los vértices del guante. En un rig de guantes rígidos, la orientación y longitud visible de dedos pueden reducir el espacio libre aunque esos centros estén separados.

También se resuelve cada brazo y luego se interpolan sus rotaciones. Poses finales correctas no garantizan trayectorias correctas entre claves: el brazo que llega desde el hombro opuesto puede cruzar otro antebrazo o acercarse a cara/pecho antes de alcanzar su destino. Esta es una hipótesis geométrica para comprobar con la vista trasera y mediciones, no una causa ya probada por esta investigación.

## Propuesta propia para evitar el cruce

1. **Separar papeles por acción.** Para la variante actual de rechazo lejano, definir una mano principal con mayor alcance y una secundaria que acompaña más cerca del cuerpo y algo por debajo. No reunir ambas en el mismo objetivo. Para recepciones media/baja, autorizar convergencia alrededor de la pelota sin interpenetración.
2. **Separar recorridos, no únicamente muñecas.** Usar carriles definidos por la dirección de alcance y el plano del pecho. La principal avanza por el carril exterior/superior elegido; la secundaria llega por un carril inferior o ligeramente retrasado. Conservar el orden de esos carriles durante extensión y recogida. El ancho lo determina la geometría del rig y la acción, no un número supuestamente extraído de FC.
3. **Guiar ambos codos.** El polo de cada brazo debe mantener un lado de flexión estable durante la transición. Comprobar que el codo no pasa por delante de su propia muñeca en la dirección de alcance ni invade el otro antebrazo. No aplicar una restricción absoluta de mantener toda la mano en el hemisferio de su hombro: impediría recepciones de dos manos y rechazos legítimos con mano opuesta.
4. **Usar espacio corporal coherente.** Convertir objetivos y referencias al mismo espacio antes de resolver IK. La rotación del nodo y la diferencia entre los dos arcos del campo no deben invertir papeles. Verificar la relación entre nombres L/R del rig y anatomía real; los nombres importados por sí solos no son una prueba.
5. **Palmas hacia el balón.** Desde detrás deberían verse normalmente los dorsos. Orientar las palmas a la cámara trasera produciría una pose equivocada aunque esa captura pareciera más abierta. Controlar orientación de muñeca respecto al antebrazo y al tiro, además del suavizado de roll.
6. **Recoger por rutas separadas.** Después del contacto, la principal baja por delante del hombro del lado de caída y la secundaria se recoge por su carril antes de convertirse en apoyo. Evitar que ambas atraviesen el pecho para llegar juntas a la pose de aterrizaje. Conservar la guardia inicial/final exactamente aprobada.

## Qué debe verificar la implementación

- Capturas y reproducción desde detrás, frente y lateral, en ambos lados del arco y con estiradas alta/media/baja.
- Separación de superficies de guantes, distancia entre segmentos de antebrazo y proximidad al pecho/cara durante **toda** la transición, no solo en alcance máximo.
- Orden de los codos y de los carriles principal/secundario sin inversiones bruscas; continuidad de muñeca al cambiar la orientación del brazo.
- Ventana de contacto y alcance mantenidos; distinguir rechazo de recepción antes de exigir que las manos se junten.

La cifra 0.166 m y la hipótesis de cruce corresponden a nuestro código. Las reglas de carriles y validación son propuestas originales. Ninguna fuente consultada permite afirmar que sean las reglas internas de FC.
