# Rol 4 — Implementación en Godot

Consulta y contraste: **2026-09-24**. Fuentes oficiales de **Godot 4.7**, sin fecha editorial visible (**s/f**). La instalación local verificada por el coordinador es **Godot 4.7.1**, con renderer **Compatibility** tanto en escritorio como en móvil. La documentación 4.7 describe la versión menor, no garantiza cada detalle del parche 4.7.1: validar el flujo con esa instalación antes de integrar.

## Recomendación específica

Crear un `FootballerVisual.tscn` con malla skinned y clips, y conectarlo a los controladores existentes de pateador/arquero. La física del balón y la decisión de atajada deben seguir siendo responsabilidad del juego. Preservar cámaras, selección, nombres, números y personalización.

La medición local del coordinador es **38.200 triángulos base, 65 MeshInstance3D y 65 superficies** para MATEO listo. No son draw calls medidos ni un benchmark. Una malla coherente de pocas superficies constituye una hipótesis razonable de mejora, pero requiere perfilado real. Véase [contexto local](00-contexto-local.md).

## Flujo de importación verificado

1. Exportar **glTF 2.0 / GLB**. Godot lo recomienda y soporta rig y animaciones. OBJ no sirve para este personaje animado. `.blend` directo depende de Blender instalado en la máquina importadora; GLB explícito reduce esa dependencia. [Formatos oficiales 4.7](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html).
2. Aplicar transformaciones antes de finalizar el rig, exportar en pose de descanso y triangulación consistente. Godot usa Y arriba; el frente de un asset orientado es **+Z**, distinto del frente de cámara **−Z**. Fijar una convención única, no compensar con giros distintos en cada clip. [Convenciones oficiales 4.7](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/model_export_considerations.html).
3. Copiar GLB al proyecto; revisar Advanced Import Settings. Importar animaciones y probar cada clip; configurar el muestreo inicialmente a **la tasa base de Blender**, que puede ser 30 muestras/s, y subirla solo si el contacto rápido pierde precisión. Para **Compatibility**, seleccionar **4 Influences (Compatible)** en la exportación/importación de Blender y comprobar el GLB final. No confundir influencias con huesos totales: Godot admite hasta ocho influencias en otra opción, pero su documentación advierte que puede no funcionar con todos los renderers. [Opciones de importación 4.7](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html).
4. Mantener el GLB como fuente importada e instanciarlo dentro de una escena propia. Extraer materiales/animaciones que deban editarse para que una reimportación no borre cambios. Clips independientes pueden importarse como `AnimationLibrary`. Un GLB puede traer texturas incrustadas; si necesitamos ajustar mipmaps o compresión VRAM para celular, usar **Extract Textures** en la importación y comprobar cada imagen. [Configuración 4.7](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html), [opciones avanzadas 4.7](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/advanced_import_settings.html) e [importación de imágenes 4.7](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_images.html).

## Animación y conexión con el partido

`Skeleton3D` representa huesos; `Skin` guarda los enlaces y matrices de pose de descanso para asociar la malla con el esqueleto; **los pesos por vértice están en la malla**. `AnimationPlayer` contiene los clips. **AnimationTree no almacena clips:** referencia ese player para controlar estados y mezclas. [Importación 4.7](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html), [AnimationTree 4.7](https://docs.godotengine.org/en/4.7/tutorials/animation/animation_tree.html).

Propuesta de estados: `idle → approach → kick → recover → idle`; arquero: `ready → dive_left/right/center → land → get_up → ready`; `celebrate` como salida de fin de partido. Usar transiciones cortas y no poner `kick` ni `dive` en loop. Una vez que AnimationTree controla reproducción, conducir estados desde él y evitar un segundo controlador que escriba poses simultáneamente.

La API visual propuesta expone `play_kick()`, `play_save(direction)` y una señal `ball_contact`. El contacto actual ocurre a **0,48 s**, según el código local: al cambiar clip se debe alinear la señal al fotograma real del pie, no conservar ciegamente ese tiempo. Puede usarse una pista de llamada a método en animación extraída, protegida por un identificador de tiro para emitir una única vez. Las pistas de llamada son una capacidad oficial de `AnimationPlayer`; **la lógica de contacto y su compatibilidad con mezclas/pausa es una propuesta que debe probarse**, no algo que el importador resuelva automáticamente. [Tipos de pistas 4.7](https://docs.godotengine.org/en/4.7/tutorials/animation/animation_track_types.html). Primer prototipo con animaciones **in-place** y desplazamiento del controlador; root motion se incorpora solo si sustituye ese desplazamiento, nunca sumándose a él.

## Uniformes y personalización

Propuesta inicial: cuerpo/pelo y uniforme en **2–4 superficies**. Reutilizar texturas; colorear la camiseta con una máscara por regiones para evitar teñir piel, escudo y dorsal. Hay dos mecanismos válidos: (a) duplicar el material de uniforme por personaje y asignarlo con `set_surface_override_material()`; (b) usar un `ShaderMaterial` compartido con `instance uniform vec4 team_color : source_color` y llamar `set_instance_shader_parameter()` en cada `MeshInstance3D`. La segunda vía evita duplicar materiales y es la primera prueba recomendada si una malla/superficie necesita un color por jugador; si las regiones requieren materiales distintos, el override sigue siendo simple para dos protagonistas. Editar un uniform común del material compartido cambiaría a todas sus instancias. [MeshInstance3D 4.7](https://docs.godotengine.org/en/4.7/classes/class_meshinstance3d.html), [parámetros por instancia 4.7](https://docs.godotengine.org/en/4.7/classes/class_geometryinstance3d.html) y [lenguaje de shaders 4.7](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/shading_language.html).

En un shader propio: `instance uniform vec4 team_color : source_color` para la opción por instancia, o `uniform vec4 team_color : source_color` si se duplica el material. La máscara de regiones es dato lineal (sin `source_color`); el albedo sRGB sí requiere `source_color`. Mezclar el tinte solo dentro de la máscara. Usar `set_instance_shader_parameter()` para el primero y `ShaderMaterial.set_shader_parameter()` para el segundo. Un parámetro de instancia pertenece al `GeometryInstance3D`, no a un submaterial en particular; comprobarlo si la malla tiene varias superficies. [Lenguaje de shaders 4.7](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/shading_language.html).

Nombre y dorsal: región UV dedicada en la espalda, generada una vez al editar al jugador y reutilizada durante el partido. Evitar generar texturas o renderizar un SubViewport continuamente. Eso sustituiría progresivamente los Label3D actuales por letras que deforman con la camiseta; es propuesta de implementación, no funcionalidad automática del importador.

## Presupuesto propuesto para celular

**Estimaciones de diseño propias, no límites oficiales ni especificaciones de Football Strike.** Supuesto: dos jugadores protagonistas visibles; estadio se presupuesta por separado.

| Área | Punto de partida | Validación |
|---|---|---|
| Geometría | 8–16 mil triángulos por protagonista como objetivo visual revisado el 24/09/2026 | Revisar silueta cerca y deformación en hombro/rodilla. |
| LOD | Cercano completo; medio ≈50%; lejano ≈25% | Auto-LOD puede romper mallas skinned: revisar atajadas y patadas en cada nivel. |
| Materiales | 2–4 superficies/personaje | Medir draw calls y pases reales, incluidas sombras. |
| Texturas | 1024² base; 512² para máscaras/detalle; 2048² solo si mejora el menú cercano | Mipmaps y compresión VRAM apropiada al dispositivo; revisar letras. |
| Rig | 24–40 huesos deformadores como objetivo; aceptar más si el rig elegido lo necesita. Máximo 4 pesos/vértice como decisión compatible | Más dedos/cara solo si visibles y útiles. Los huesos de control de Blender no deben exportarse innecesariamente. |
| Animación | Muestreo inicial igual a Blender, por ejemplo 30 muestras/s | Reducir pistas constantes; subir calidad solo al detectar artefactos. |
| Fotogramas | Objetivo60 FPS =16,7 ms; alternativa30 FPS =33,3 ms | Medir exportación en celular mínimo durante varios minutos, no solo editor Mac. |

Godot selecciona LOD por tamaño en pantalla y permite generarlo al importar; **advierte explícitamente problemas ocasionales en mallas skinned**. Si aparece una deformación, desactivar ese auto-LOD para la malla afectada. Los niveles manuales se montan con rangos de visibilidad, que exigen configuración adicional; no son una opción de reemplazo automático en el importador. [LOD oficial 4.7](https://docs.godotengine.org/en/4.7/tutorials/3d/mesh_lod.html).

Las texturas deben seguir el tamaño del objeto en pantalla; mipmaps reducen grano a distancia. En 3D, Godot suele activar mipmaps y compresión VRAM cuando detecta la textura, pero hay que verificar la importación de las texturas extraídas. [Importar imágenes 4.7](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_images.html). Reducir transparencias, cantidad de luces con sombras y pases antes de asumir que todos los problemas vienen de los triángulos. **Automatic instancing es Forward+ solamente**, no una optimización disponible en este proyecto Compatibility. MultiMesh sigue siendo útil para elementos repetidos del estadio, no resuelve automáticamente dos esqueletos con animaciones independientes. [Rendimiento 3D 4.7](https://docs.godotengine.org/en/4.7/tutorials/performance/optimizing_3d_performance.html).

## Prueba de aceptación propuesta

- Importar, reexportar y reimportar sin perder material, clips ni eventos propios.
- Pateador y arquero simultáneos con uniformes distintos; cambiar uno no altera al otro.
- Primer tiro: balón sale cuando toca el botín; pausa/reanudación no duplica contacto.
- Atajar ambos lados, caída y recuperación sin hundir pies ni ropa atravesada.
- Perfil en dispositivo: CPU/GPU, memoria, draw calls y fotogramas sostenidos; comparar contra personaje actual con la misma escena y cámaras.

## Costo y licencia

**Godot: gratuito, licencia MIT**, permite publicar juegos comerciales, con los avisos de licencia aplicables del motor y dependencias. No impone MIT a los assets propios. Importación GLB, AnimationPlayer/Tree y herramientas de perfilado están incluidos: dificultad media y calidad final dependiente del modelo/rig y del hardware. [Licencia oficial, s/f, consulta2026-09-23](https://godotengine.org/license/).

Todas las fuentes Godot de arriba: documentación oficial **4.7, s/f, consultada 2026-09-24**. El shader de máscara y las escenas descritas son diseños propuestos: no fueron implementados ni ejecutados en esta tarea de investigación. Los presupuestos de triángulos, huesos, materiales, resolución y FPS son hipótesis de producción; ninguna página citada los presenta como límites específicos de Godot o cifras de Football Strike.
