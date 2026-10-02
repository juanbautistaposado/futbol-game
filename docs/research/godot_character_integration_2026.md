# Integración de futbolistas 3D en Godot 4.7.1

**Consulta:** 28/09/2026. **Fuentes:** documentación oficial de Godot 4.7, sin fecha editorial visible (`s/f`), y archivos del proyecto inspeccionados ese día. **V** = verificable en el repositorio o en la fuente citada; **P** = decisión recomendada para este juego, pendiente de prueba visual o de rendimiento. La última instrucción del usuario pide una interpretación más cartoon, con cabeza más grande y animación expresiva; Football Strike sirve como referencia de uniformes, colores y legibilidad, sin copiar sus assets.

## Estado real del proyecto

**V:** `project.godot` selecciona `gl_compatibility` para escritorio y móvil. Los GLB se cargan como `PackedScene` desde `kicker.gd` y `keeper.gd`; ambos controladores mantienen colisiones, movimiento y reglas del tiro fuera del asset. `footballer_visual.gd` crea materiales independientes para cada avatar y recolorea superficies con nombres `Jersey`, `Shorts`, `Skin`, `Hair` y `Socks`. `kicker.gd` usa `AnimationPlayer` con `Idle`, `Kick`, `Celebrate` y un `Tween` de física que llama al contacto del balón a los **0,48 s**. `keeper.gd` usa `AnimationPlayer` con variantes de estirada y captura; su posición y colisión se animan por separado.

Inspección del JSON glTF dentro de los archivos binarios, sin contar draw calls ni memoria GPU:

| GLB actual | Triángulos indexados | Joints del skin | Imágenes/texturas en el GLB | Clips |
|---|---:|---:|---:|---|
| `footballer_original.glb` | 8.072 | 18 | 0 | Idle, Kick, Celebrate |
| `goalkeeper_original.glb` | 8.624 | 18 | 0 | Idle, Kick, Celebrate, Catch, SaveLeft/Right, SaveLowLeft/Right |

**V:** los `.glb.import` habilitan `meshes/generate_lods=true`, `animation/fps=30` y `animation/remove_immutable_tracks=true`. Por tanto **ya hay** rig, clips, importación y color por avatar. El siguiente salto visual debe venir de la malla, pesos, rostro, ropa, materiales/iluminación y revisión de animaciones desde las cámaras del juego; añadir `AnimationTree` por sí solo no mejora la calidad de un clip. Los triángulos son un conteo del archivo, no un presupuesto máximo de Godot.

## Importar un GLB revisado

**V:** Godot recomienda glTF 2.0 (`.gltf` o `.glb`); admite mallas, esqueleto y animaciones. `.blend` se importa invocando Blender en la máquina del editor; OBJ carece de skinning y animación. Un `.glb` puede incorporar texturas. En el panel de importación se pueden revisar clips, generar LOD, cambiar el muestreo y extraer texturas para controlar su compresión. [Formatos 4.7](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html), [configuración 4.7](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html) (s/f, consulta 28/09/2026).

**P, secuencia segura:**

1. Conservar `.blend` como fuente y exportar una revisión a otro nombre, por ejemplo `footballer_v2.glb`. Dejar `footballer_original.glb` para comparación inmediata. En Blender aplicar transformaciones, exportar en pose de descanso, fijar la orientación frontal del asset a **+Z** y triangular de forma consistente. [Consideraciones de exportación 4.7](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/model_export_considerations.html) (s/f, consulta 28/09/2026).
2. Importar `footballer_v2.glb` y abrir **Advanced Import Settings**. Verificar `Skeleton3D`, nombres de nodos y huesos, materiales, clips, duración y pose extrema. Mantener inicialmente las rutas `FootballerRig/Skeleton3D/FootballerBody`, `Beard` y `AnimationPlayer`, o adaptar la capa visual antes de cambiar el GLB cargado. Si aparece un normal map, asegurar tangentes correctas; si se incrustan imágenes, considerar **Extract Textures** para ajustar mipmaps y compresión VRAM. [Opciones 4.7](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html), [texturas 4.7](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_images.html) (s/f, consulta 28/09/2026).
3. Instanciar la escena importada dentro de una escena propia o del controlador actual. Mantener correcciones editables en materiales/recursos externos o en una escena envolvente; no basar el trabajo en editar subrecursos embebidos de la escena importada, que se regeneran. Godot documenta escenas heredadas y extracción de recursos. [Configuración de importación 4.7](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html) (s/f, consulta 28/09/2026).
4. Probar en menú, tiro, defensa y celebración. Revisar puntas de botines y guantes, ropa sobre piel, sombras, lectura de rostro, nombre/dorsal y pausa. Sólo después cambiar la referencia definitiva del controlador. El diseño actual llama al impulso a 0,48 s; al sustituir el clip se debe volver a sincronizar con el cuadro real de contacto.

## Animación sin romper la física

**V:** `AnimationPlayer` alberga los clips; `AnimationTree` los referencia para transiciones y mezclas, pero no almacena animaciones. Si se añade un árbol, sus estados deben ser la única vía que controle la reproducción mientras esté activo. [AnimationTree 4.7](https://docs.godotengine.org/en/4.7/tutorials/animation/animation_tree.html), [clase AnimationTree 4.7](https://docs.godotengine.org/en/4.7/classes/class_animationtree.html) (s/f, consulta 28/09/2026).

**P:** conservar `AnimationPlayer` directo para el primer reemplazo visual; ya cumple `Idle`, `Kick`, `Catch`, `Save...` y `Celebrate`. Incorporar `AnimationTree` sólo cuando se necesiten transiciones de espera→carrera→patada o mezclas direccionales de atajadas. Usar una escena de visual independiente, dejando a `kicker.gd` y `keeper.gd` como dueños del movimiento físico. Comenzar con clips *in place* para no sumar desplazamiento de root motion al `Tween` actual. En patada, elegir **un único** disparador del balón: mantener el callback actual ajustado al nuevo fotograma, o moverlo a una pista de llamada de animación con protección contra doble emisión al mezclar/reiniciar. Godot admite pistas de llamadas, pero su uso como contacto fiable en este flujo es propuesta que requiere prueba. [Tipos de pistas 4.7](https://docs.godotengine.org/en/4.7/tutorials/animation/animation_track_types.html), [AnimationTree 4.7](https://docs.godotengine.org/en/4.7/tutorials/animation/animation_tree.html) (s/f, consulta 28/09/2026).

GDScript ilustrativo para validar una revisión antes de activar el asset; usa el mismo contrato de nodos que el juego actual:

```gdscript
const CANDIDATE: PackedScene = preload("res://assets/footballer/footballer_v2.glb")

func create_visual(parent: Node3D) -> Node3D:
    var visual := CANDIDATE.instantiate() as Node3D
    assert(visual != null)
    var animation := visual.get_node_or_null("AnimationPlayer") as AnimationPlayer
    var body := visual.get_node_or_null("FootballerRig/Skeleton3D/FootballerBody") as MeshInstance3D
    assert(animation != null and body != null)
    for clip in ["Idle", "Kick", "Celebrate"]:
        assert(animation.has_animation(clip), "Falta clip: " + clip)
    parent.add_child(visual)
    return visual
```

La instancia se añade al árbol después de comprobar las rutas; si el importador cambia nombres, ajustar el asset o el adaptador visual, no la lógica del partido. El ejemplo no sustituye el código actual ni ha sido ejecutado.

## Colores y materiales por avatar

**V:** `MeshInstance3D.set_surface_override_material()` aplica un material a una superficie de una instancia concreta. Éste es el mecanismo que usa el juego. Un `ShaderMaterial` compartido también puede recibir valores distintos en cada `GeometryInstance3D` mediante `instance uniform` + `set_instance_shader_parameter()`. Un `uniform` normal modificado con `ShaderMaterial.set_shader_parameter()` cambia el recurso compartido. [MeshInstance3D 4.7](https://docs.godotengine.org/en/4.7/classes/class_meshinstance3d.html), [GeometryInstance3D 4.7](https://docs.godotengine.org/en/4.7/classes/class_geometryinstance3d.html), [shaders 4.7](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/shading_language.html) (s/f, consulta 28/09/2026).

**P:** conservar las superficies actuales de piel, pelo y uniforme y la personalización independiente mientras se itera visualmente. Para una camiseta texturizada, combinar albedo real de tela con una máscara de color de equipo; no teñir escudo, ribetes, dorsal ni piel. `source_color` corresponde al color y albedo sRGB; la máscara de datos no lo necesita. Si se desea compartir el shader entre avatares sin clonar materiales, usar `instance uniform vec4 team_color : source_color` y escribir el parámetro en **cada** `MeshInstance3D` pertinente. Para dos personajes, las instancias materiales actuales son simples y aceptables; cambiar de técnica sólo por una mejora medida o por escala de variantes. [Shaders 4.7](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/shading_language.html) (s/f, consulta 28/09/2026).

## Rendimiento para un celular real

**V:** Godot puede generar mesh LOD al importar glTF y seleccionarlo por cobertura en pantalla. La documentación advierte defectos ocasionales en mallas skinned; es posible desactivar LOD en la malla afectada y usar rangos de visibilidad para alternativas manuales. El proyecto ya tiene LOD automático habilitado, **pero no hay medición que pruebe que se esté usando en la cámara de juego**. [Mesh LOD 4.7](https://docs.godotengine.org/en/4.7/tutorials/3d/mesh_lod.html), [rangos de visibilidad 4.7](https://docs.godotengine.org/en/4.7/tutorials/3d/visibility_ranges.html) (s/f, consulta 28/09/2026).

**V:** el instancing automático para nodos `MeshInstance3D` idénticos sólo existe en Forward+, no en Compatibility; `MultiMesh` sirve para elementos repetidos del estadio, no para dos esqueletos que se animan de forma independiente. Luces dinámicas, sombras, transparencias y skinning pueden ser costosos en dispositivos móviles. Las texturas 3D detectadas normalmente activan mipmaps y compresión VRAM, pero conviene comprobar la importación final. [Optimización 3D 4.7](https://docs.godotengine.org/en/4.7/tutorials/performance/optimizing_3d_performance.html), [imágenes 4.7](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_images.html) (s/f, consulta 28/09/2026).

**P, presupuesto de partida, no límite oficial ni cifra de Football Strike:** mantener aproximadamente 8–16 mil triángulos para cada protagonista cercano mientras mejora cara/ropa; 18 huesos ya son una base compacta, ampliar sólo si hacen falta deformaciones de codo, rodilla, dedos o cara. Probar textura principal de 1024²; 2048² únicamente si un primer plano demuestra mejora visible. Reducir superficies/materiales sólo tras medir si son un costo relevante. Para un modelo con piel, preferir 4 influencias por vértice en el camino compatible; la opción `4 Influences (Compatible)` documentada por Godot se aplica a la importación de `.blend`, y un GLB de otro origen debe comprobarse por separado. [Configuración 4.7](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html) (s/f, consulta 28/09/2026).

**P, prueba de aceptación:** medir en el celular mínimo objetivo, con estadio y dos protagonistas, durante varios tiros consecutivos. Registrar tiempo de fotograma, CPU/GPU, draw calls, memoria y temperatura; repetir con el GLB actual como línea base y el candidato con idéntica cámara, iluminación y calidad. Revisar patada y atajada con LOD cercano/lejano, skins en poses extremas, nombre y colores independientes, pausa/reanudación y reimportación. Sin ese perfilado no se puede afirmar que una malla de más o menos triángulos mejorará el rendimiento total.

## Licencia

**V:** Godot se distribuye bajo MIT, permite juegos comerciales y no impone esa licencia al contenido creado. Al publicar una copia del motor con el juego corresponde incluir el aviso de copyright y licencia de Godot; los assets que se incorporen tendrán sus propios términos. [Licencia oficial de Godot](https://godotengine.org/license/) (s/f, consulta 28/09/2026). Los dos GLB inspeccionados se describen como originales en el `ASSET-LICENSES.md` del proyecto; esta nota técnica no audita la autoría de su geometría ni sustituye el registro de procedencia.
