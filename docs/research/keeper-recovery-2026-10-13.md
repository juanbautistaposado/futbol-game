# Atajada: contacto, caída y final de la acción

Investigación realizada el 13 de octubre de 2026. Objetivo: que el arquero termine la atajada en una postura coherente con la acción, sin volver automáticamente a la guardia de comienzo.

## Evidencia verificada en fuentes primarias

Se consultó el texto de estas páginas y el manual de The FA. No se midieron secuencias de vídeo, tiempos de caída ni ángulos articulares de profesionales. Las cifras y poses propuestas más abajo son decisiones para este juego.

| Fuente | Enseñanza documentada | Implicación para la animación |
| --- | --- | --- |
| [The FA — Level 1 and 2 in Coaching Goalkeepers, Technical Manual](https://www.thefa.com/-/media/cfa/sheffieldfa/files/l1-and-l2-coaching-gk-technical-manual.ashx?la=en), páginas impresas 7–8, PDF índices 6–7 | En la estirada baja, el impacto se absorbe con el costado y los hombros; el codo se recoge y la cabeza sigue detrás de las manos. En la alta, la pelota debe asegurarse al tocar el suelo. Distingue recuperar una pelota suelta de recuperar la línea para defender el arco. | La fase final necesita una caída lateral con articulaciones flexionadas y una respuesta que dependa del resultado; no basta con enderezar el cuerpo. |
| [FIFA Training Centre — Learning to dive low](https://www.fifatrainingcentre.com/en/environment/fifa-goalkeeper-training/goalkeeping-fundamentals/learning-to-dive-low.php), Thierry Barnerat, 18/11/2025 | Para retener, la mano baja sostiene desde atrás y la otra asegura por arriba; el suelo ayuda a sujetar la pelota. Si el alcance no permite retenerla, puede rechazarse con una mano. | Mantener separadas las acciones de captura y rechazo. No usar la misma pose de dos manos para todas las estiradas. |
| [FIFA Training Centre — Defending the goal](https://www.fifatrainingcentre.com/en/environment/fifa-goalkeeper-training/sessions/goalkeeping-fundamentals-defending-the-goal.php), Dean Santangelo, 17/03/2026 | Se asegura la pelota antes de levantarse o cambiar de posición. Durante el seguimiento, los hombros orientan hacia la pelota. Los rechazos se dirigen hacia zonas laterales seguras. La distribución posterior pertenece a otra acción. | Capturar debe conservar control durante la caída; rechazar debe conservar atención a la pelota, incluso sin posesión. |
| [FIFA Training Centre — Learning to dive at mid-height](https://www.fifatrainingcentre.com/en/environment/fifa-goalkeeper-training/goalkeeping-fundamentals/learning-to-dive-at-mid-height.php), Thierry Barnerat, 09/12/2025 | Recomienda agarrar con ambas manos cuando es posible y rechazar fuera del arco con una mano si no lo es. El despegue y la recepción siguen la trayectoria del balón. | La mano de apoyo no debe atravesar la cara para imitar una captura imposible. |

Ninguna de estas fuentes exige terminar todas las atajadas en una rodilla, ni permanecer tumbado un número fijo de segundos. Tampoco sostienen una vuelta idéntica a la guardia inicial después de cada tiro. El final depende de si hubo captura, rechazo, rebote o continuidad de juego.

## Causa encontrada en el proyecto

En la versión consultada, `keeper.gd::dive()` lleva al arquero desde caída lateral a apoyo y después lo endereza durante 0,38 s: altura de reposo, inclinación cero y reproducción de `keeper_motion/Ready`. `keeper_animation.gd` también termina sus clips de 1,59 s con los huesos de Ready. Por eso el final vuelve visualmente al comienzo aunque la acción haya terminado. `catch_pose()` detiene la caída y reproduce el Catch importado, de modo que una captura lateral también debe revisarse por separado.

## Recomendaciones aplicables al juego

Estas son decisiones de implementación inspiradas en las fuentes, no datos biomecánicos medidos:

1. Conservar las trayectorias de intercepción y el alcance físico ya corregidos; sustituir primero el tramo posterior al contacto/caída.
2. Para una estirada lateral sin pelota retenida, absorber de lado y terminar bajo, con piernas asimétricas recogidas, cabeza elevada y mirada hacia el campo. Puede haber un asentamiento corto tras el impacto. Un semiapoyo con antebrazo o rodilla es una opción artística que requiere comprobar el contacto del modelo con el suelo.
3. Para captura lateral, permitir que el cuerpo complete la caída y mantenga las dos manos sujetando la pelota. El balón debe seguir las manos reales del rig. Conservar una postura de protección baja durante el resultado, evitando el salto a un Catch erguido.
4. Para una parada central baja, terminar recogido cerca del suelo, sin forzar la misma caída lateral de un tiro al palo. Para una captura central de pie, la postura de posesión puede seguir erguida: es una acción distinta de Ready, con las manos ocupadas por la pelota.
5. Mantener el final de la acción hasta el reinicio del siguiente tiro. En este juego de duelos, ese reinicio es el momento apropiado para volver a la guardia abierta de la referencia del usuario. Si en el futuro hay rebotes jugables, será necesaria una recuperación específica hacia la nueva trayectoria.
6. Verificar ambos lados, alturas bajas/medias/altas y los dos arqueros; mirar capturas con y sin retención desde las cámaras reales de atacante y arquero. Comprobar continuidad del muñeco, pelota entre guantes, separación de brazos y ausencia de penetración de pies/hombros/manos.

## Alcance de esta investigación

No se propone modificar la guardia abierta, volver a cruzar las manos, ampliar colisiones para dar atajadas artificiales ni copiar animaciones propietarias de otros juegos. La prioridad es distinguir el final de una estirada de la preparación de otro tiro.
