# Arquero v2 — primera cara base

Estado: **arquero activo del juego**, 28/09/2026. El GLB original se conserva como respaldo.

- Dirección: personaje original de fútbol estilizado; cabeza más ancha, cuello menos visible, ojos y cejas legibles. Una cara base primero; después dos variantes faciales sobre el mismo cuerpo y rig.
- Segunda pasada: hombros con continuidad hacia la camiseta, rodillas con malla y pesos entre muslo y tibia, guantes más legibles con pulgar y puño, y costuras laterales del uniforme.
- Tercera pasada: párpados, iris, oreja y rasgos de nariz/boca; emblema y franjas originales. `JerseyAccent` toma una variante clara de la camiseta personalizada y `SkinShade` una sombra de la piel elegida. Nombre y dorsal siguen siendo `Label3D` editables.
- Atajadas: anticipación con la pierna de apoyo, salto del cuerpo con arco vertical y extensión de ambos brazos hacia el lado y altura del tiro. Las variantes bajas orientan las manos hacia abajo.
- Plataforma y cámara: PC, objetivo 60 FPS con opciones gráficas; comparar en el menú y el arco real del partido.
- Fuente editable: `goalkeeper_v2.blend`. Entrega a Godot: `apps/free-kick-3d/assets/footballer/goalkeeper_v2.glb`.
- Procedencia: generado y editado en el proyecto a partir de `tools/build_original_footballer.py -- --goalkeeper-v2`. Sin modelos, texturas ni animaciones de terceros.
- Contrato conservado: `FootballerRig/Skeleton3D/FootballerBody`, `Beard`, 18 huesos, materiales de uniforme y clips Idle/Kick/Celebrate/Catch/SaveLeft/SaveRight/SaveLowLeft/SaveLowRight.
- El v2 tiene 5.304 polígonos Blender, 13 superficies y 18 huesos. Este dato no equivale a FPS ni draw calls.
- Regeneración: `blender -b --factory-startup --python apps/free-kick-3d/tools/build_original_footballer.py -- --goalkeeper-v2` desde la raíz. Sin el flag, el script regenera los archivos `*_original`; no usar esa ruta para cambios manuales de v2.
- Inspección: `blender -b --factory-startup --python apps/free-kick-3d/tools/render_footballer.py -- source-assets/footballer/goalkeeper_v2.blend /tmp/goalkeeper-v2-preview.png`; captura en Godot con `godot --rendering-method gl_compatibility --path apps/free-kick-3d --script res://tools/preview_goalkeeper_v2.gd -- /tmp/goalkeeper-v2-in-game.png`. Agregar `dive` como segundo argumento para capturar la estirada.

La importación, personalización (incluidos tonos de detalle, nombre y dorsal), captura con manos, contacto/estirada y atajadas por sector pasan. Se inspeccionaron capturas del modelo y del partido.

Medición local en Apple M4, Godot 4.7.1 Compatibility, ventana de 1280 × 720, VSync y límite de FPS desactivados, 300 cuadros por perfil tras 90 de calentamiento. La escena incluye estadio, personajes y una estirada del arquero. Tiempos medidos entre cuadros renderizados; no representan todas las PC ni todos los momentos del juego:

| Perfil | Promedio | p95 | FPS promedio | Draw calls promedio |
|---|---:|---:|---:|---:|
| Bajo | 8,72 ms | 13,14 ms | 114,7 | 234 |
| Medio | 11,81 ms | 14,79 ms | 84,7 | 1096 |
| Alto | 12,17 ms | 13,72 ms | 82,1 | 1096 |

En esta máquina, los tres perfiles quedaron por debajo del presupuesto de 16,67 ms para 60 FPS en p95. **Pendiente para calidad final:** texturas UV/atlas de rostro y uniforme, dedos más definidos, comparación cuadro a cuadro con trayectorias reales de pelota y una medición en la PC Windows objetivo si difiere de este equipo.
