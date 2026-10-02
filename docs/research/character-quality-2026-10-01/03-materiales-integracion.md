# Materiales, rig e integración del nuevo personaje

Fecha: 2026-10-01. Investigación de código y documentación primaria; sin modificar gameplay ni assets. **V** indica hecho verificado; **P** propuesta sin implementar ni medir. Herramientas y assets deben ser gratuitos: Blender y Godot cubren la ruta recomendada, sin Substance ni plugins pagos.

## Decisión recomendada

**P:** producir una malla y rig nuevos en Blender, con proporciones y deformaciones aprobadas primero, y después UVs y texturas propias. Mantener GLB como entrega y una capa adaptadora en Godot. El problema actual no es falta de un shader más vistoso: texturas y normales no reparan silueta, proporciones, hombros ni articulaciones deficientes. Godot documenta que el normal mapping modifica la iluminación, no la geometría. [Materiales 3D](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html#normal-map).

No recomiendo otra ronda de sinusoidales de tela, contornos o cambios de luz como solución principal. Son acabados posteriores. La puerta de aprobación inicial debe ser el cuerpo en material gris mate, frente/perfil/espalda y poses exigentes; si allí se ve mal, el asset no pasa a texturizado.

## Diagnóstico del repositorio

**V: lectura directa de los chunks JSON de los GLB v2 actuales.** Sumé índices/3 por primitiva de triángulos; no es medida de draw calls ni de geometría visible ni de rendimiento.

| Archivo | Triángulos almacenados | Meshes / superficies | Materiales | Huesos del skin | Imágenes |
|---|---:|---:|---:|---:|---:|
| `footballer_v2.glb` | 10.876 | 2 / 13 | 12 | 18 | **0** |
| `goalkeeper_v2.glb` | 11.996 | 2 / 14 | 13 | 18 | **0** |

Las cifras de informes de septiembre describen versiones anteriores. Ambos conservan clips Idle, Kick y Celebrate; el arquero añade Catch y cuatro Save. No se ejecutó una sesión visual ni benchmark en esta investigación.

Carencias concretas:

- `tools/build_original_footballer.py:28–48`: materiales con color constante y roughness escalar; no mapas de albedo, normal ni roughness pintados.
- `:67–109`: UVs calculadas por índices de filas/anillos en cada pieza. No atlas de personaje con islas distribuidas y densidad controlada; las piezas ocupan rangos repetidos. En la vuelta del anillo se conectan índices extremos sin una UV de costura duplicada explícita: hay que inspeccionar y rehacer las costuras antes de hornear.
- `:52–62`: asignación inicial de toda una pieza a un único hueso; `:170–178` y `:193–201` mezclan dos pesos por altura en piernas y brazos. Existe una mejora de continuidad local, pero no constituye weight painting anatómico con corrección de hombros/caderas. El torso creado en `:145` está inicialmente asociado a Spine; la aprobación debe incluir flexión/torsión del tronco.
- `:245–258`: unir objetos conserva grupos y materiales; **join no convierte superficies superpuestas en una topología continua**. El archivo final puede ser una sola malla y conservar muchos componentes desconectados.
- `footballer_visual.gd:9–20`: personalización por nombre de material. La ropa es reemplazada por un `ShaderMaterial` nuevo que recibe solo tint. **Agregar mapas al GLB no basta: ese código descartaría los materiales texturizados de Jersey, JerseyAccent, Shorts y Socks.**
- `shaders/footballer_fabric.gdshader:5–11`: color varía mediante senos de UV, roughness fija 0,87. No textura de tejido, mapa normal, máscara ni diferenciación de zonas. Las frecuencias muy altas deben revisarse a distancia porque pueden generar grano temporal; eso es una hipótesis visual, no fallo medido.
- `footballer_model.gd:143–152`, `kicker.gd:21–24,37–38`, `keeper.gd:50,67–68`: nombre/dorsal son Label3D con desplazamiento fijo sobre un nodo externo. No se deforman con la tela y no están anclados a UVs de espalda.
- `graphics_quality.gd:10–11`: los perfiles cambian MSAA y sombras; hoy no definen resolución de textura ni calidad de material. `project.godot` configura 1280×720 y Compatibility.

Los archivos anteriores están bajo `apps/free-kick-3d/`. `footballer_model.gd` también contiene funciones procedurales antiguas; la geometría activa viene de los GLB cargados por kicker/keeper, no de asumir que todos esos métodos están en uso.

## Ruta gratuita de materiales

**P, trabajo de autoría en Blender:**

1. Retopología con bucles en hombro, axila, codo, rodilla, cadera y base del cuello; esculpir/editar volumen antes de añadir detalle superficial. Ropa con espesor visual y holgura razonables; cabello sólido estilizado como primera versión, evitando una dependencia de tarjetas transparentes.
2. UV1 sin solapamiento no intencional, costuras escondidas, checker de distorsión, rostro con más densidad y espalda reservada para nombre/dorsal. Los elementos espejados solo comparten UVs cuando no necesitan asimetría ni texto.
3. Texturas propias mediante Texture Paint y bake: albedo con variación suave de piel; tela con paneles, costuras y pliegues medianos; botas con zonas de distinto brillo. No pintar luces direccionales del estadio en el albedo.
4. Normal tangente +Y para pliegues y detalles, AO moderada en cavidades y roughness por zona. Pliegues que alteran el borde de la ropa deben estar en geometría. Evitar poros fotográficos sobre un cuerpo estilizado sin dirección coherente.
5. Exportar Principled BSDF con texturas conectadas explícitamente, UVs/normales/tangentes y animaciones. Mantener `.blend` y PNG maestros fuera de la malla runtime; verificar compresión y mipmaps en Godot.

**V:** el exportador oficial glTF reconoce normal maps tangentes conectados por Normal Map, imágenes Non-Color, y empaquetado R=occlusion/G=roughness/B=metallic. Permite hornear normales de nodos a una imagen; no es una traducción general de cualquier shader de Blender. [Documentación del exportador Khronos](https://github.com/KhronosGroup/glTF-Blender-IO/blob/main/docs/blender_docs/scene_gltf2.rst). **V:** Cycles documenta bake entre objetos Selected to Active y margen alrededor de las islas. El margen evita contaminación de bordes; el valor adecuado depende del atlas/mip usado. [Manual de bake Blender](https://docs.blender.org/manual/sr/4.0/render/cycles/baking.html) — contenido oficial 4.0 verificado mediante el extracto indexado del buscador; la apertura directa y el endpoint latest devolvieron error, por eso no se presenta como lectura completa ni verificación de una versión actual concreta.

**P: personalización.** Un material de uniforme con albedo neutro, normal/roughness y máscara RGB: camiseta, pantalón, detalles; medias pueden compartir canal con camiseta o usar otra región/selector. Combinar tint solo dentro de las regiones de máscara, conservando logos originales, costuras y contraste. Piel y cabello tienen tint propio y textura de variación neutra. Compartir imágenes entre avatares; duplicar recursos de material y uniformes por avatar, como ya intenta hacer `apply_profile`.

El shader de máscara es una herramienta para conservar personalización y pocas superficies, no una reparación de anatomía. Alternativa inicial más simple: superficies Skin/Hair/Jersey/Shorts/Socks texturizadas con `StandardMaterial3D` duplicado y color multiplicador; integrar primero y consolidar atlas después de medir. Una máscara personalizada necesita material de Godot: no esperar que el core glTF la reconstruya automáticamente. glTF describe material PBR metallic-roughness, texturas y factores, no este contrato de recolor del juego. [Especificación glTF](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#materials).

**P: dorsales.** Generar al cambiar la identidad una pequeña imagen transparente de nombre+número, cachearla por combinación y mezclarla en un rectángulo UV reservado de espalda. En runtime usarla dentro del material opaco del uniforme, sin una malla transparente extra. Así sigue el skinning y no flota. La composición se realiza al cambiar el perfil, no cada frame. Se debe probar nombre largo, acentos y números de dos/tres dígitos. Si el dorsal usa UV2, reservar ese uso conscientemente; no sobrescribirlo con lightmap automático.

## Rig e intercambio sin perder gameplay

**V:** Godot aclara que mismos nombres de hueso no bastan para compartir clips: hay que compatibilizar Bone Rest, jerarquía y tracks. Ofrece BoneMap/SkeletonProfileHumanoid, normalización de tracks de posición y correcciones de rest. Su perfil humanoide referencia T-pose y +Z; modificar rest sin validar puede empeorar el resultado. [Retargeting oficial](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html).

**P:** un rig deformador compartido para delantero/arquero, con clavículas, tronco flexible y dedos mínimos si las tomas lo necesitan. Controles IK permanecen en Blender; hornear su resultado en huesos deformadores al exportar. Retargetear puede ahorrar la base de clips, pero Kick/Save/Catch precisan corrección manual de contacto, manos y apoyos. Un rig nuevo no debe quedar limitado a los 18 huesos actuales por miedo a cambiar rutas.

**V:** el importador documenta 4 Influences (Compatible) para compatibilidad entre renderers y hasta 8 en otra modalidad no universal. Tangentes son necesarias para normal maps; LOD, named skins, importación de animaciones y extracción de imágenes son opciones existentes. [Configuración de importación](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html).

**P: contrato de adaptación:**

- Resolver malla, Skeleton3D, AnimationPlayer, barba y regiones materiales en un adaptador central. Hoy rutas rígidas en `kicker.gd:28–33` y `keeper.gd:55–63` hacen frágil cambiar jerarquía.
- Mantener métodos públicos, movimiento, IA y proxies de colisión del controlador. No generar colisión física detallada desde la malla renderizada.
- Conservar inicialmente contacto de Kick a **0,48 s**, `kicker.gd:49–54`: nueva animación ajustada al contrato. Si cambia el contacto, sincronizar callback y clip juntos; nunca aplicar dos impulsos por mezclar eventos y Tween.
- Mapear Hand.L/Hand.R o sockets equivalentes: `keeper.gd:156–162` calcula pelota retenida como promedio de huesos de mano. El pivote de muñeca nuevo puede quedar lejos de la palma; definir offsets/socket de captura y comprobar la pelota entre guantes en Catch y después de Save.
- Validar apariencia independiente de delantero/arquero, barba, reinicio, pausa, patada, captura y todas las alturas/lados de estirada. No introducir root motion además del desplazamiento del controlador, porque duplicaría movimiento.

## Compatibility, web y presupuesto experimental

**V:** Compatibility permite desktop y web, normal/PBR básico y MSAA. No ofrece SSS, SSR, SDFGI, compute shaders, CompositorEffects ni buffer normal/roughness de pantalla; la tabla actual sí indica SSAO y glow, por lo que no repetir que están totalmente ausentes. [Comparativa de renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html). **V:** exportación web Godot 4 usa WebGL 2 con Compatibility, no Forward+/Mobile ni WebGPU en la documentación consultada. [Exportación web](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html#webgl-version).

**P:** no necesitamos cambiar renderer para lograr un personaje mucho mejor. Mantener una luz/sombra legible y PBR texturizado como mínimo común. Probar mismo GLB en export desktop y navegador, no deducir rendimiento web desde editor Mac. La compresión/mipmaps debe verificarse en los imports, pues Godot documenta varios modos y conversiones para imágenes. [Importar imágenes](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html).

| Recurso | Hipótesis inicial, no límite del motor |
|---|---|
| Geometría LOD0 | 15–30 mil triángulos por personaje si mejoran silueta/deformación; comparar también 10–15 mil |
| LOD1 / LOD2 | Aproximadamente 50% / 25% de LOD0; verificar manos/rostro/patadas, no aprobar por porcentaje |
| Rig | 30–60 huesos deformadores según dedos/twist; 4 influencias normalizadas por vértice |
| Superficies | 4–6 iniciales; barba/cabello opcionales pueden añadir una; son superficies, no draw calls medidos |
| Texturas PC | Atlas piel/rostro 2048 y uniforme 2048 como candidato de menú cercano; compartir mapas entre roles |
| Variante reducida | 1024 para comparar en partido y export web; máscara 512–1024, lettering 512 provisional |
| Rendimiento | Objetivo del juego 60 FPS, 16,7 ms por frame; medir escena completa y percentiles, no solo promedio |

Estos números son hipótesis de producción. 2048 RGBA8 sin compresión ocupa 16 MiB base y unos 21,3 MiB con cadena completa de mipmaps; **tres mapas así son aproximadamente 64 MiB**, antes de máscara, lettering y otras texturas. PNG pequeño en disco no implica poca memoria GPU. Verificar formatos reales en Godot antes de fijar presupuesto.

La aceptación requiere comparativa v2/nuevo en las mismas cámaras a 1280×720 y en primeros planos, poses grises primero, luego mapas, personalización y partido. Medir memoria de texturas, tiempo GPU/CPU, superficies/pases y estabilidad de frame en calidades baja/media/alta. **La conclusión verificada es la carencia de mapas y la fragilidad de integración; la mejora visual y los 60 FPS con la nueva malla quedan pendientes de prototipo y medición.**
