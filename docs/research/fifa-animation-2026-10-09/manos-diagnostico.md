# Diagnóstico de los guantes del arquero

Fecha local: 2026-10-09. Asset observado: `apps/free-kick-3d/assets/footballer/meshy_keeper.glb`.

## Reproducción determinista

```sh
godot --headless --log-file /tmp/keeper-rig-audit.log --path apps/free-kick-3d --script res://tests/keeper_glove_pose_test.gd
```

Antes del arreglo: salida 1, `FAIL: 32 orientaciones de guantes`. El test muestrea los clips reales que instala `KeeperAnimation`, en guardia y a 0.25, 0.45 y 0.70 s de las seis atajadas. También compara la simetría de izquierda y derecha. No simula otro rig ni reemplaza la animación por un fixture.

La normal de la palma visible apunta casi perpendicular al tiro en guardia y en la estirada alta. En la estirada baja, la mano principal apunta hacia atrás. La continuación del cuerpo no corrige esa orientación: su giro es alrededor de Z, así que conserva la componente frontal de la palma.

| Pose | Palma principal · dirección del tiro | Ángulo al tiro |
| --- | ---: | ---: |
| Guardia | 0.0034 | 89.8° |
| Estirada lateral alta | 0.0105 | 89.4° |
| Estirada lateral baja | -0.8054 | 143.6° |
| Atajada central | 0.2239 | 77.1° |

Para esta malla, la dirección del tiro en el espacio del esqueleto es +Z. La mano tiene su palma en el plano local XY y los dedos en +Y. El umbral frontal del test es 0.60 en guardia y al atajar: deja margen para manos abiertas en diagonal, pero rechaza guantes de canto o con el dorso hacia la pelota. También exige que el eje longitudinal de la mano tenga producto escalar de al menos 0.65 con el vector codo–muñeca, evitando resolver la palma con una flexión de muñeca excesiva. La comprobación usa espacio del esqueleto y funciona independientemente del arco defendido.

## Datos de la malla y el rig

La superficie `GoalkeeperGloves` contiene 4531 vértices exportados. Vértices dominados por `Hand.L`: 2276; por `Hand.R`: 2255. La suma de influencias es:

| Hueso | Suma de pesos de la superficie |
| --- | ---: |
| Hand.L | 2275.1110 |
| Hand.R | 2254.2835 |
| Forearm.L | 0.8890 |
| Forearm.R | 0.7165 |
| Todos los dedos | 0.0000 |

Los guantes son prácticamente rígidos en cada mano. Animar los dedos actualmente no deforma ningún vértice del guante. La primera corrección visible debe controlar las muñecas y la alineación del antebrazo. Para abrir, cerrar o curvar dedos de verdad hace falta un nuevo reparto de pesos en el asset, verificado visualmente.

Límites de la geometría en el espacio local de cada mano, obtenidos aplicando el inverso del rest global a los vértices exportados:

| Mano | X | Y | Z |
| --- | --- | --- | --- |
| L | -0.0395 … 0.1237 | -0.0080 … 0.2536 | -0.0368 … 0.0413 |
| R | -0.1230 … 0.0422 | -0.0092 … 0.2535 | -0.0330 … 0.0451 |

Esto calibra la normal visible como `Hand.basis.z`. La normal estimada únicamente con los huesos de los nudillos está desviada respecto del plano real de esta malla; sería una prueba indirecta de la anatomía del rig anterior.

El signo +Z se comprobó con la curvatura real de los dedos: la mediana Z de los vértices en Y=0.10–0.15 m es 0.0023 m en L y 0.0043 m en R; en las puntas, Y=0.20–0.25 m, asciende a 0.0156 y 0.0169 m. Las puntas se curvan 12–13 mm hacia +Z. Esto distingue palma y dorso; el espesor solo permitiría identificar el plano.

Una palma perfectamente frontal no siempre es compatible con conservar la pose del antebrazo: en la estirada alta principal, el vector codo–muñeca tiene Z=0.9753. Exigir a la vez normal de palma frontal >0.93 y dedos alineados al antebrazo >0.65 es geométricamente imposible sin ajustar el brazo. Una orientación de los dedos con Z≈0.50 permite alineación ≈0.68 y palma frontal ≈0.87. La solución debe repartir el ajuste entre brazo y muñeca o conservar una palma diagonal razonable.

Además, los sufijos de los dedos están cruzados con los nombres de las manos:

- `Hand.R` (hueso 8) parenta `index_01_l`, `middle_01_l`, `ring_01_l`, `pinky_01_l`, `thumb_01_l`.
- `Hand.L` (hueso 27) parenta los correspondientes nombres terminados en `_r`.

No se debe escoger una falange únicamente por el sufijo. Se debe seguir la jerarquía de la mano correspondiente.

## Causa observada y límites

La rotación de `Hand.L` y `Hand.R` permanece exactamente en rest mientras cambian los brazos. Los clips anteriores ajustaban pecho, brazos y piernas, y completaban las muñecas con canales neutrales. Al cambiar el antebrazo sin compensar la muñeca, se deja al guante de canto o mirando hacia atrás.

El test cubre la orientación de la superficie rígida visible y la simetría. No garantiza contacto fino de todos los dedos, torsión anatómica de piel ni calidad visual completa. Las capturas del juego son necesarias para revisar el pliegue de muñeca y que la solución no fuerce una articulación imposible. `Catch` requiere una palma orientada al centro de la pelota retenida, distinta de presentar una palma frontal para desviar, y no está incluido en la condición frontal de las atajadas.

## Revisión independiente después de la corrección

La corrección de `keeper_glove_motion.gd` resuelve primero los brazos y luego orienta los guantes. El test final pasa con salida 0: `PASS: palmas frontales, muñecas alineadas, longitudes, continuidad, espacio y simetría a 60 Hz`. Comprueba las orientaciones y longitudes en cada muestra, además de los picos: así puede detectar una muñeca incorrecta entre claves interpoladas. La separación de las palmas bajas y la continuidad de las rotaciones también están verificadas.

Una sonda independiente de 97 muestras por clip encontró:

| Clip | Mínima componente frontal de palma | Mínima alineación dedos–antebrazo |
| --- | ---: | ---: |
| Guardia | 0.8930 | 0.9584 |
| Atajada lateral alta | 0.8183 | 0.8512 |
| Atajada lateral baja | 0.6290 | 0.6567 |
| Atajada central | 0.8742 | 0.9584 |

El máximo error de longitud de brazo y antebrazo es 0.00000012 m, correspondiente a redondeo numérico. Los casos más ajustados están en la recuperación baja, no en el pico de la atajada.

Las capturas detalladas de guardia, alta y baja muestran palmas abiertas y guantes separados. La malla de la camiseta todavía presenta bordes dentados y pliegues excesivos en los hombros con brazos elevados. Comparar `/tmp/keeper-hands-reach-before.png` con `/tmp/keeper-hands-high-final.png` confirma que ese defecto ya estaba presente antes de esta corrección. Es una limitación del skinning del asset de ropa y no se reconstruyó la camiseta como parte del arreglo de las manos.


## Corrección aplicada y revisión independiente

`keeper_glove_motion.gd` resuelve brazo y antebrazo mediante IK de dos huesos
sobre las poses clave. Conserva las longitudes y utiliza una guía de codo.
Después orienta la superficie rígida del guante: palma hacia el tiro y dedos
siguiendo el antebrazo, con flexión limitada. Las atajadas bajas separan los
objetivos de muñeca de la mano principal y la acompañante.

La primera implementación recalculaba el codo en cada frame. Produjo giros al
pasar cerca del eje de la guía. La versión final resuelve las poses clave y
utiliza interpolación de cuaterniones entre ellas. La prueba detecta saltos de
más de 0,30 radianes entre muestras de 60 Hz. No se añade seguimiento continuo
del balón ni se altera la trayectoria física del arquero.

La prueba final pasa con orientación y alineación comprobadas durante toda la
estirada y recuperación, longitudes constantes, continuidad, simetría y una
separación de centros de palma superior a 18 cm en el alcance bajo. Una auditoría
independiente muestreó los clips a 60 Hz: error máximo de longitud de brazo
0,00000012 m; mínima componente frontal de la palma 0,629; mínima alineación
mano–antebrazo 0,657. También pasan pruebas de contacto, pausa, reinicio,
identidad de ambos arqueros y los 13 casos de selección de sector/altura.

Capturas revisadas del rig real:

- [Guardia y muñecas](capturas/manos-guardia.png).
- [Palma principal en alta](capturas/manos-alta.png).
- [Separación de guantes en baja](capturas/manos-baja.png).
- [Secuencia alta](capturas/arquero.png), [baja](capturas/arquero-bajo.png) y
  [baja lateral](capturas/arquero-bajo-lateral.png).

Limitación del asset: los guantes siguen siendo rígidos porque los dedos no
tienen influencia. Abrir/cerrar dedos individualmente requiere repintar los
pesos del modelo. Las mangas presentan bordes dentados al levantar los brazos;
la comparación con la captura anterior confirma que ya estaban presentes.
La recepción `Catch` conserva sus manos en forma de cuenco y la posición del
balón retenido; no recibe la orientación frontal de una parada con desvío.
