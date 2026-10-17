# Delantero: preparación antes de patear

10 de octubre de 2026. Godot 4.7.1.

## Referencias primarias

- [FIFA Training Centre: tiros libres a corta distancia](https://www.fifatrainingcentre.com/en/game/game-analysis/set-plays/set-play-routines/direct-free-kicks-fine-margins-at-short-distance.php), 6 de mayo de 2026. El análisis de Quintero describe una aproximación angulada y una forma corporal que anticipa el gesto de tiro. El de Suárez explica cómo el primer paso construye el ángulo de aproximación. El artículo destaca orientación corporal y posición del pie de apoyo como variables de ejecución.
- [FIFA Training Centre: tiros libres de media distancia](https://www.fifatrainingcentre.com/en/game/game-analysis/set-plays/set-play-routines/direct-free-kicks-why-mid-range-means-maximum-threat.php), 28 de abril de 2026. La rutina de Kolarov se describe como una aproximación ligeramente angulada, practicada y repetible; la de Cristiano Ronaldo acelera de forma progresiva.

Estas fuentes orientan la intención de la preparación. No prescriben la posición
exacta de rodillas, manos o torso de nuestra pose. Los valores siguientes son
una decisión de animación propia para que la espera tenga aspecto de preparación
futbolística y conecte con la carrera corta existente.

## Pose aplicada

`athlete/Ready` reemplaza el Idle heredado únicamente en la biblioteca privada de
cada delantero. Se reproduce mientras el jugador apunta o carga y también para
el rival IA, en ambas direcciones del campo.

- Pie izquierdo adelantado 14 cm y derecho retrasado 16 cm respecto del origen
  del modelo; separación lateral de 41 cm.
- Pelvis 5,2 cm más baja. Ambas piernas se resuelven contra objetivos de botas
  fijos, flexionando las rodillas y manteniendo los pies sobre el césped.
- Inclinación leve del torso hacia delante y compensación de la cabeza para
  mantener la atención en pelota y arco.
- Brazos relajados junto a las caderas, manos bajas, codos ligeramente flexionados.
  Los brazos dejan de adoptar la guardia del Idle anterior.
- Respiración de 2,8 s: desplazamiento de pelvis de ±1,5 mm y flexión de torso
  inferior a 0,3°. Los objetivos de las botas permanecen fijos.

## Continuidad con el remate

El primer fotograma de `MatchStrike` coincide con Ready; durante los primeros
0,10 s se transfiere suavemente a los dos pasos existentes. Desde 0,94 s hasta
1,16 s, la recuperación vuelve a la misma pose de espera. El contacto del pie
derecho sigue calibrado exactamente a 0,48 s y el pie izquierdo mantiene su apoyo
entre 0,36 y 0,64 s. La cancelación, pausa y callback de liberación no cambiaron.

La cantidad de muestras se redondea, en vez de truncarse: `1.16 * 100` podía
terminar en el fotograma 115 por precisión decimal y dejar una diferencia pequeña
al pasar a Ready. Ahora se incluye la pose final del fotograma 116.

## Verificación

`striker_animation_test.gd` comprueba escalonamiento, brazos bajos, botas inmóviles
con respiración, coincidencia de ambos extremos del remate, continuidad entre
fotogramas, dos pasos alternados, apoyo, contacto y retorno a Ready. Ejecuta el
flujo a 30, 60 y 120 ticks por segundo en ambas direcciones, además de cancelar
un remate pendiente. También se ejecutaron las pruebas de flujo de animación,
modelo Meshy y conservación de brazos originales.

La integración revisó capturas frontales y laterales de la pose dentro del juego.
Los clips importados, malla, atlas, pesos y celebración permanecen intactos.
