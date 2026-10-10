# Auditoría de brazos y manos del delantero PLAYER

Fecha: 2026-10-08. Inspección de código, GLB y fuente Blender existentes; no se modificaron assets durante esta auditoría.

## Hallazgo

La postura rígida tiene dos causas independientes:

1. `Idle` deja las muñecas a ~0,98 m y `Kick` casi nunca las levanta más de 1,04 m. Los antebrazos siguen prácticamente alineados con los brazos, sin flexión de codo significativa. Las manos tienen la misma rotación casi constante en ambos clips.
2. Meshy tiene huesos de dedos pero ningún vértice está pesado en ellos. Los dedos de PLAYER se mueven como una pieza rígida de `Hand.R` o `Hand.L`. Rotar `index`, `middle`, `ring`, `pinky` o `thumb` no cierra visualmente la mano. Los personajes normales sí tienen pesos individuales.

Rig: 53 huesos. Hay 30 huesos de dedos, 3 por dedo y lado. Atención al nombre: `Hand.R` corresponde a hijos `index_*_l`, `middle_*_l`, `ring_*_l`, `pinky_*_l`, `thumb_*_l`; `Hand.L` a sufijo `_r`. Es una convención heredada del origen MakeHuman. No inferir el lado por el sufijo de los dedos.

GLB PLAYER conserva las mismas matrices inversas y clips que v3. `Idle` dura 1,0333 s, `Kick` 0,9667 s, con claves a 30 Hz. El callback de contacto en `kicker.gd` se ejecuta a 0,48 s; comentario técnico del pie indica ~0,47 s. Ese tiempo, la trayectoria del kicker y los canales de piernas, pelvis, torso y cabeza deben permanecer exactos.

## Medidas en espacio Godot, antes de cambiar clips

| Clip / tiempo | Muñeca derecha x,y,z | Muñeca izquierda x,y,z |
| --- | --- | --- |
| Idle / 0,033 s | 0,374 / 0,979 / -0,035 | -0,374 / 0,979 / -0,035 |
| Kick / 0,233 s | 0,182 / 0,961 / 0,071 | -0,295 / 0,973 / -0,120 |
| Kick / 0,500 s | 0,247 / 0,977 / -0,201 | -0,433 / 1,039 / -0,056 |
| Kick / 0,700 s | 0,328 / 0,911 / -0,047 | -0,277 / 0,997 / -0,047 |

Coordenadas del modelo antes de la rotación PI del avatar; transformarlas al evaluar el sentido de avance en cancha. El origen de `Foot.R` no es el punto exacto de contacto de la superficie del botín.

## Rest pose y ejes Blender

Blender usa Z arriba y frente -Y. Godot/glTF usa Y arriba y frente +Z.

| Hueso | Inicio Blender | Final Blender |
| --- | --- | --- |
| UpperArm.R | 0,2075 / -0,0193 / 1,5243 | 0,3933 / -0,0194 / 1,3119 |
| Forearm.R | 0,3933 / -0,0194 / 1,3119 | 0,5391 / -0,2282 / 1,1721 |
| Hand.R | 0,5391 / -0,2282 / 1,1721 | 0,5513 / -0,2602 / 1,1539 |

El eje local Y sigue el hueso. El roll difiere entre brazos y antebrazos; no aplicar rotaciones Euler del eje global directamente a `rotation_quaternion`. Usar quaternion en espacio local, o resolver objetivos de mano y hornear solamente los canales de brazos/manos. Las animaciones fuente procedurales viejas fueron retargeteadas con corrección de basis e IK de brazo; copiar sus Euler globales omitiría esa corrección.

## Mano Meshy y opciones

Mano derecha Meshy en espacio local de Hand:

- x: -0,117 a 0,043 m
- y: -0,066 a 0,252 m
- z: -0,031 a 0,046 m

Mano derecha v3, incluyendo pesos de dedos:

- x: -0,034 a 0,083 m
- y: -0,035 a 0,217 m
- z: -0,047 a 0,098 m

Las palmas y dedos no coinciden en orientación. La transferencia nearest de pesos desde v3 a Meshy sin remap previo puede asignar un dedo al vecino y crear pellizcos o estiramientos. Existe un atributo fuente `MeshyRestPosition` que conserva las posiciones normalizadas originales antes del alineamiento de miembros. En mano derecha original: x 0,350..0,477, y -0,099..0,047, z 0,796..1,042 m. Muñeca/palma predominan z 0,93..1,00; dedos distales z 0,80..0,92. Esta distribución permite una curvatura leve sin volver a transferir pesos.

### Ruta recomendada para esta corrección

1. Crear un derivado editable de la fuente actual, conservando el candidato Meshy crudo.
2. Modificar únicamente rotaciones de UpperArm/Forearm/Hand de PLAYER en Idle y Kick. Añadir codo flexionado ~20–40 grados y balanceo asimétrico durante preparación, impacto y recuperación. Idle puede tener muñecas ~1,09..1,17 m y brazos levemente separados. La otra mano durante impacto puede subir ~1,25..1,35 m. Estos son objetivos artísticos iniciales, requieren inspección en cámara de juego.
3. Relajar la mano Meshy con deformación geométrica suave y pequeña de dedos distales: caída suave entre z original 0,95 y 0,82, reducción del spread 10–15%, curvatura máxima ~0,02..0,025 m y acortamiento ~0,008 m. Máscara lateral |x|>0,35 evita piernas. Proteger la muñeca y reducir influencia en el pulgar interno, aproximadamente |x|<0,405. Conservar conectividad y UV0/UV2. Esto relaja la silueta pero no produce animación independiente de dedos.
4. Si se necesita cierre dinámico real más adelante, identificar cada dedo por conectividad distal, alinear la palma Meshy al marco de huesos y rehacer pesos por segmentos. Requiere una validación más amplia que la postura actual; no es necesario para una mano relajada en la escala de cancha.

### Validación mínima

- Huesos, parents y matrices inversas exactas.
- Todos los canales exactos salvo rotaciones permitidas de brazos/manos de Idle/Kick.
- Coordenadas/UV/pesos exactos fuera de la máscara de mano si se retoca geometría.
- Eventos y duración del clip intactos; contacto de pie en test existente, posición actor y callback sin cambios.
- Fuente y PBR existentes, cara/cabello/botines intactos.
- Render de Idle y Kick en preparación, impacto y seguimiento, vistos de frente/perfil/espalda y cámara de cancha.
- Las mangas no colapsan al flexionar el brazo. Muñecas no se separan del antebrazo. Mano relajada sin puño rígido ni dedos atravesando palma.
- Celebrate, arqueros y personajes normales sin cambios. El audit previo que exige igualdad de todos los clips debe extenderse con allowlist estricta de la modificación legítima, no desactivar la verificación global.

## Fuentes locales inspeccionadas

- `apps/free-kick-3d/kicker.gd`
- `apps/free-kick-3d/tools/rig_meshy_player.py`
- `apps/free-kick-3d/tools/build_footballer_v3.py`, retarget y bake ~líneas 660–710
- `apps/free-kick-3d/tools/build_original_footballer.py`, clips de brazos ~líneas 295–303
- `apps/free-kick-3d/assets/footballer/meshy_player.glb`
- `apps/free-kick-3d/assets/footballer/footballer_v4.glb`
- `source-assets/footballer/meshy_player.blend`
- `source-assets/footballer/footballer_v3.blend`
