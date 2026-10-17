# Cruce de brazos y guantes — 11 octubre 2026

El defecto existe en geometría mundial: no es sólo una perspectiva de la cámara. Durante las estiradas medias/altas, el antebrazo pasa por el brazo contrario; durante recuperación, las tiras centrales de los guantes se cruzan aunque las muñecas permanezcan separadas.

## Loop rojo específico

```sh
godot --headless --log-file /tmp/keeper-arm-separation.log --path apps/free-kick-3d --script res://tests/keeper_arm_separation_test.gd
```

Se ejecutó dos veces antes de modificar runtime. Resultado geométrico determinista: `FAIL: 20 cruces de brazos/guantes`, salida 1, unos 0.78 segundos. Ocho fallos corresponden a brazos (media/alta, ambos lados y arqueros), doce a guantes (todas las alturas/lados/arqueros). Se añadió después la regresión de silueta desde defensa y se verificó nuevamente en rojo: `FAIL: 26 cruces de brazos/guantes`, incorporando seis fallos de proyección del arquero local. La ejecución completa siguió por debajo de dos segundos.

El test instancia `Main.tscn`, ejecuta `keeper.dive()` y avanza sus Tween reales con `custom_step(1/60)` y el AnimationPlayer manual a la misma cadencia. La trayectoria secundaria comienza al tick siguiente de crearse, como en SceneTree. Muestrea 95 frames de cada una de las doce estiradas, incluyendo caída y recuperación. No tiene una copia de los objetivos de IK ni del algoritmo del solver.

Se llaman los métodos reales del producto para la cámara: `look_from_keeper()` para el arquero local, `look_from_kicker()` para el rival con la pelota en su posición reglamentaria. No se utiliza una cámara frontal de preview. `look_from_keeper()` mantiene FOV 55°, posición (0, 4.4, 60.5), objetivo (0, 1.2, 52.5 − distancia_de_tiro/2) y opacidad de red .18.

## Medidas antes de la corrección

Las distancias físicas son iguales para izquierda/derecha y ambos arqueros. La inversión de orientación entre arcos ya está compensada por `rig_direction` en el runtime actual; no se reprodujo aquí el antiguo defecto de elegir el lado incorrecto del clip.

| Altura | Distancia mínima entre ejes de brazos opuestos | Fase | Distancia mínima entre núcleos longitudinales de guantes | Fase | Distancia mínima de muñecas |
|---|---:|---:|---:|---:|---:|
| .70 m | .1939 m | 1.017 s | .0249 m | 1.183 s | .1941 m |
| 1.25 m | .0080 m | .633 s | .0338 m | 1.200 s | .1915 m |
| 1.60 m | .0080 m | .633 s | .0338 m | 1.200 s | .1915 m |

Los segmentos de brazos conectan hombro–codo y codo–muñeca. Se comparan los antebrazos entre sí y cada antebrazo con el brazo superior contrario. Un umbral conservador de .06 m detecta que volúmenes de unos tres centímetros de radio se atraviesan; no exige una separación artificial de hombros.

Para el guante rígido Meshy, la tira central va de Y local .06 a .23 m y se desplaza X local +.035 m en Hand.L / −.035 m en Hand.R. Sigue la palma y los dedos visibles en +Y. Se excluye la gran caja vacía del pulgar para no usar todo el AABB como volumen sólido. El umbral de .06 m representa dos núcleos conservadores de aproximadamente tres centímetros de radio; la escala visual 1.15 aumenta, en lugar de reducir, el margen real del guante. El [diagnóstico anterior de la malla](../fifa-animation-2026-10-09/manos-diagnostico.md) registra los límites y pesos que fundamentan esta aproximación.

Esto es una prueba de separación conservadora, no una simulación exacta de triángulos skinned. Puede detectar cruces grandes y no garantiza contacto fino de cada dedo.

## Lectura desde las cámaras reales

La distancia proyectada entre esas tiras de guante llega a **0 píxeles** durante recuperación, en ambas vistas: los ejes de las siluetas se cruzan. En defensa ocurre aproximadamente entre 1.07 y 1.18 s; esa fase coincide con las manos apelmazadas de la [captura anterior de gameplay](capturas/defensa-alta-antes.png).

Durante alcance (.25–.77 s), los guantes no son la pareja que cruza: en defensa sus tiras conservan una distancia proyectada mínima de 22.90 px baja, 43.10 px media y 42.19 px alta. En ese intervalo el fallo prioritario es **antebrazo contra brazo superior contrario**, observado a .633 s. En ataque los guantes tienen menor tamaño proyectado, con mínimos de 7.72 / 9.73 / 9.89 px durante alcance.

Los píxeles dependen del viewport. Por eso la condición de legibilidad desde **defensa** exige dos píxeles de separación entre tiras centrales a 1280 px de ancho, normalizados mediante `distancia_proyectada / ancho_viewport >= 2 / 1280`. Se verificó con viewport real de 1280 × 720. Este margen pequeño rechaza el cruce de los ejes de ambos guantes, aunque una implementación los separe físicamente sólo en profundidad y aún los muestre enmarañados desde atrás. Se conservan los métodos, FOV y posición de la cámara del juego.

La cámara lejana de ataque sólo registra métricas de proyección: no comparte el umbral visual del defensor. Las condiciones de separación geométrica en metros permanecen iguales para ambos arqueros. La comprobación de silueta no promete que todos los bordes de las mallas estén separados en pantalla; compara las tiras centrales conservadoras durante la estirada y su recuperación.

## Por qué pasó la prueba anterior

`keeper_glove_pose_test.gd` comprueba palmas al tiro, dedos alineados con cada antebrazo, longitudes, continuidad y simetría. Esas propiedades pueden cumplirse mientras **dos brazos distintos se atraviesan**. Una pose simétrica puede reflejar el mismo cruce hacia ambos lados.

Su condición de separación de guantes sólo evalúa centros de palma en .45 s y sólo en clips bajos. No comprueba la recuperación a 1.18–1.20 s, el volumen de los dedos ni segmentos de brazos opuestos. Incluso en la recuperación defectuosa, las muñecas permanecen a .19 m, mientras los dedos convergen hasta .025–.034 m: medir únicamente muñecas omite la parte que se cruza.

## Hipótesis para discriminar en la implementación

1. **IK independiente de cada brazo.** Si la guía del codo del apoyo permite cruzar el brazo principal, ajustar la guía y el recorrido de ese brazo debe aumentar su distancia al brazo opuesto sin mover el guante de intercepción. Predicción: desaparece el mínimo .008 m alrededor de .633 s y se mantiene el alcance.
2. **Objetivos de aterrizaje demasiado próximos.** Si los objetivos de muñeca convergen a una región similar, abrir el espacio y diferenciar su apoyo debe aumentar la separación de las tiras de guantes en 1.18–1.20 s. Las muñecas por sí solas no bastan: debe verificarse orientación +Y de los guantes.
3. **Interpolación con un cruce intermedio.** Si las claves finales parecen separadas pero sus trayectorias se cruzan, añadir un tránsito anatómico o cambiar el recorrido del codo resuelve el test a 60 Hz; comprobar sólo .45 y 1.01 s lo deja pasar.
4. **Perspectiva posterior amplifica un defecto existente.** Si el arreglo físico basta, la captura con `look_from_keeper()` mejora sin mover la cámara. Cambiar cámara, FOV u opacidad de red no resolvería los mínimos mundiales registrados.

La guardia solicitada por el usuario, orientación de palmas y timing/alcance de intercepción deben conservarse. El criterio nuevo complementa las pruebas anteriores, no las sustituye. No se modificó runtime durante esta auditoría; el test queda rojo para la implementación posterior.

## Segunda revisión: apoyo delante de la mandíbula pese a separación verde

Después de resolver los cruces geométricos, las capturas frontal y posterior todavía mostraron la mano secundaria pasando por delante de la mandíbula durante el alcance medio/alto, con aspecto de gesto «dab». La separación física por sí sola no representa el nuevo rol deseado: rechazo con una mano principal y apoyo junto a su propio hombro. Las [fuentes FIFA reunidas en FC](fc.md) distinguen rechazo y recepción; no obligan a juntar ambas manos en todas las intervenciones. La elección de una mano para este movimiento concreto es una decisión de implementación apoyada por esa distinción y por la revisión visual del usuario, no una regla universal de técnica de arquero.

Se añadió una comprobación conservadora de rol, sólo para alturas medias/altas (.85 m o más), durante .25–.767 s. En cada frame:

- El rol principal se deriva de la dirección real del movimiento transformada al espacio del rig antes de la estirada, por lo que funciona al invertir el arco y el giro del cuerpo.
- La mano de apoyo permanece en el hemisferio de su propio hombro: se tolera que su muñeca avance diez centímetros locales hacia la línea central desde el hombro, sin exigir coordenadas exactas de destino.
- El centro visible del guante principal queda por lo menos cinco centímetros mundiales por encima del centro de apoyo. Se usan centros de la geometría del guante, no solamente muñecas.

Antes de cambiar esa postura, el test dio **FAIL: 8** en .80 segundos: media/alta de ambos lados y ambos arqueros. Todas las condiciones de separación anteriores ya pasaban. La muñeca de apoyo invadía el lado opuesto **.4475 m locales** respecto a su hombro (límite .10 m); la diferencia vertical ya era correcta, con principal .1352 m por encima. Los mínimos geométricos entonces eran .0846 m entre brazos y .1936 m entre guantes; en defensa también había más de 17.26 px entre núcleos. Esto discrimina una postura inapropiada de un cruce físico.

La prueba de rol no aplica a recepción `Catch`, parada central ni atajada baja: esos movimientos pueden utilizar las dos manos con otro propósito. Los antiguos asserts que exigían que el guante secundario alcanzara hacia el destino por delante de la cara deben revisarse para el rechazo medio/alto con una mano, conservando las condiciones del guante principal, guardia, pausa y alcance de colisión. Mantener aquel requisito de apoyo y el rol nuevo simultáneamente obligaría al movimiento que la revisión visual acaba de descartar.
