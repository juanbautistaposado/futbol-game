# Contexto y medición del proyecto

Consulta e inspección: 2026-09-23. Evidencia local, no especificaciones de Football Strike.

- `godot --version`: 4.7.1.stable.official.a13da4feb.
- `apps/free-kick-3d/project.godot`: `gl_compatibility` en desktop y móvil; MSAA configurado en 2.
- `footballer_model.gd`: superficies procedurales y numerosos MeshInstance3D independientes. `kicker.gd` / `keeper.gd`: articulaciones Node3D y Tween, sin Skeleton3D/AnimationTree.
- Medición instanciando `kicker.gd`, esperando _ready, sumando índices/3 en cada superficie: MATEO predeterminado = **38.200 triángulos base, 65 superficies y 65 nodos MeshInstance3D**. Excluye Label3D, pases de sombras y posibles otros pases. No equivale a draw calls medidos ni a FPS. Script temporal: `/tmp/count-football-character.gd`.
- `kicker.gd::kick`: contacto mediante Callable luego de 0,38 + 0,10 segundos. Sustituir modelo debe preservar el evento lógico de contacto; el nuevo clip puede ajustar el momento según su movimiento.
- Preservar selección independiente de arquero/delantero, nombres y números, colores, dificultad, resultados y cámaras ya aceptadas.

Conclusión de ingeniería: una malla skinned coherente con pocas superficies ofrece un camino más controlable que seguir subdividiendo piezas. El beneficio de rendimiento debe medirse en dispositivo; la propuesta no implica FPS garantizados.
