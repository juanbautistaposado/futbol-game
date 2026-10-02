# Delantero v2

`footballer_v2.blend` y `apps/free-kick-3d/assets/footballer/footballer_v2.glb`
son originales del proyecto. Se generan con
`blender -b --factory-startup --python apps/free-kick-3d/tools/build_original_footballer.py -- --goalkeeper-v2`.

El generador exporta primero el futbolista v2 y luego añade guantes y clips de
atajada para `goalkeeper_v2.glb`. Así ambos roles comparten rostro, cuerpo,
uniforme personalizable y un esqueleto de 18 huesos. El delantero conserva
manos normales y los clips Idle, Kick y Celebrate. Godot lo usa en el jugador,
los rivales y la vista previa de selección.

No contiene modelos, texturas ni animaciones de terceros. El GLB anterior
`footballer_original.glb` se conserva como respaldo.
