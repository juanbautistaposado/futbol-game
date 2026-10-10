# Prueba Meshy: integración con el personaje y rig existentes

Fecha: 2026-10-06. Auditoría de solo lectura sobre los archivos actuales; este informe no modifica el personaje publicado, sus fuentes ni la lógica del juego. Se aplicaron las guías `create-game-assets` (pipeline 3D y procedencia) y `godot-animation`.

## Recomendación

La primera prueba debe comparar **una alternativa estática en pose A** con el jugador actual, a la misma altura, cámara e iluminación. Si mejora claramente la silueta, la camiseta y el short, el camino de menor riesgo es adaptar la malla nueva al **armature y a los ocho clips actuales**, conservando cara, pelo, botines y guantes existentes durante la prueba. Generar otro esqueleto con Meshy para sustituir el actual añade trabajo que no resuelve la apariencia.

El render de Meshy sirve para decidir si vale la pena descargar y limpiar la alternativa. No demuestra que sea una malla apta para animar: brazos cruzados, manos pegadas al torso, ropa fundida con piel o un arco incorrecto del short pueden aparecer en el resultado aunque la imagen de entrada sea buena. Estos son riesgos técnicos de la propuesta, aún no observaciones de un resultado generado.

## Lo que ya funciona y debe conservarse

Se leyeron directamente las estructuras JSON y buffers de los GLB actuales, además del manifest y los scripts de Godot.

| Dato medido | Jugador | Arquero |
|---|---:|---:|
| Archivo | `footballer_v3.glb` | `goalkeeper_v3.glb` |
| Tamaño | 7.37 MB | 7.64 MB |
| Triángulos | 89,843 | 96,571 |
| Vértices exportados, incluidos cortes UV/materiales | 60,239 | 63,641 |
| Huesos del skin | 53 | 53 |
| Materiales/superficies | 11 | 12 |
| Imágenes incorporadas | 10 | 10 |
| Altura por límites de POSITION | 1.898873 m | 1.898873 m |

Los dos modelos tienen el mismo orden de huesos, las mismas matrices inversas de bind y los mismos datos de canales de animación —nombres de hueso, tiempos, transformaciones e interpolación—. La comparación de clips normalizó los índices de accessor del contenedor GLB; comparar solamente el JSON de los archivos produciría diferencias irrelevantes por empaquetado.

SHA-256 de las matrices de bind decodificadas y serializadas como JSON: `be1458de66ef540a3fd22b3da9ce4e74ec2a3d4143e4994123ed3b76833811f6`.

| Clip | Duración exportada |
|---|---:|
| Catch | 0.600 s |
| Celebrate | 0.800 s |
| Idle | 1.033 s |
| Kick | 0.967 s |
| SaveLeft / SaveRight / SaveLowLeft / SaveLowRight | 0.767 s cada uno |

Las texturas de piel, ojos y pelo son de 1024²; cejas y mapas del uniforme son de 512². Ambos GLB no declaran extensiones glTF adicionales. La importación actual genera LOD y shadow meshes, usa skins por nombre e importa animación a 30 fps.

El runtime usa `kicker.scale = 1.15` y la misma escala en el nodo visual del arquero. Esa escala, el origen y la altura del esqueleto deben conservarse: el contacto de la patada y las manos del arquero dependen de posiciones concretas. La escala no es una medida oficial de Football Strike.

### Contrato de escenas y materiales

`kicker.gd` y `keeper.gd` acceden a rutas concretas:

- `AnimationPlayer` con los ocho nombres de clip anteriores.
- `FootballerRig/Skeleton3D/FootballerBody`.
- `FootballerRig/Skeleton3D/Beard`, que se activa por perfil.
- Huesos `Foot.R`, `Hand.L` y `Hand.R`, entre otros.

`footballer_visual.gd` personaliza por **nombre de material**: `Jersey`, `Shorts`, `Socks`, `Skin`, `Hair`, `HairScalp`, `HairStrands` y `Beard`. Los botines, ojos, vivos y guantes tienen materiales separados. Un modelo Meshy con un único atlas y un único material perdería la personalización independiente de camiseta, short, piel y pelo al usar este código sin adaptación.

La camiseta usa UV0 para albedo/normal/roughness y UV2 para un dorsal dinámico de un SubViewport 512². La región de espalda queda dentro de [0,1]; frente y mangas quedan fuera. Por tanto **no conviene hornear “PLAYER 10” en el albedo Meshy**: se duplicaría al activar nombres/números personalizados. El short también reserva UV2 para sus detalles. No generar lightmap UV2 sobre esos canales.

## Carpeta de prueba y etapas

Ruta sugerida para trabajo posterior, fuera de los assets de producción:

```text
source-assets/footballer/meshy-trial-2026-10-06/
  input/                 # referencia preparada y prompt exacto
  raw/                   # GLB descargado sin editar
  edited/                # .blend de limpieza y adaptación
  exports/               # GLB candidato, nunca footballer_v3.glb
  manifest.json          # herramienta/modelo, licencia, prompt, hashes y estado
  preview-project/       # proyecto Godot mínimo e independiente
docs/research/meshy-trial-2026-10-06/
  comparacion/            # capturas equivalentes, métricas y decisión
```

Una escena de estudio independiente puede reutilizar la iluminación y encuadre de `preview_athlete_neutral.gd`, pero necesita aceptar una ruta de candidato y funcionar también con un modelo sin rig. El script actual tiene rutas del personaje y animación fijadas; **no acepta directamente cualquier GLB Meshy**. Copiar y adaptar el harness en la carpeta trial, sin tocar las rutas de `kicker.gd` ni `keeper.gd`.

### A. Comparación estática

1. Conservar el GLB original descargado y su procedencia.
2. Importar en un `.blend` nuevo; verificar unidades, frente +Z al exportar a Godot, pies en el suelo y altura de aproximadamente 1.899 m.
3. Ajustar solamente la malla candidata antes de vincularla al armature: escala, orientación y pose A con manos/brazos y piernas separados. No aplicar transforms ni editar rest pose del rig de producción.
4. Inspeccionar frente, espalda, perfil y tres cuartos con luz neutral; comparar también a la escala visible en el juego. La camiseta debe tener caída libre, manga integrada sin escalón y pecho moderado; short con cintura continua, entrepierna baja y largo a medio muslo; muslos/pantorrillas atléticos.
5. Comprobar triángulos, componentes conectados, normales, agujeros, caras interiores y UV. Si el resultado requiere reconstruir gran parte del cuerpo o la ropa, usarlo como referencia visual y conservar la malla actual como base.

### B. Adaptación al armature existente, si la alternativa gana

1. Trabajar en una copia de `footballer_v3.blend`; importar la alternativa en una colección separada.
2. Mantener el armature, jerarquía, nombres, rest matrices, NLA y acciones originales. Ajustar la malla nueva para alinear hombros, codos, muñecas, cadera, rodillas y tobillos con esos huesos.
3. Separar regiones de camiseta, short, medias y piel por caras/materiales. Conservar cabeza, pelo, barba y botines originales; resolver la unión del cuello y tobillos en el candidato. Si la malla generada no permite esa separación limpiamente, detener esta ruta.
4. Transferir **vertex groups de deformación por región**, desde la región original equivalente, mediante Data Transfer con *Nearest Face Interpolated*, correspondencia por nombre y grupos generados en destino. No usar transferencia por topología entre mallas distintas. La documentación Blender describe que este mapping interpola datos desde la superficie fuente más cercana. [Blender, Data Transfer](https://docs.blender.org/manual/id/5.0/modeling/modifiers/modify/data_transfer.html)
5. Usar una distancia máxima calibrada a la escala y separar izquierda/derecha, brazo/torso y piernas antes de transferir: evita que la superficie más cercana sea otra extremidad o el torso. Corregir manualmente axilas, cuello, entrepierna, codos y rodillas. Esa segmentación es una recomendación para este modelo, no una garantía automática del modificador.
6. Limitar a cuatro influencias de hueso por vértice y normalizar después; revisar que no haya pesos negativos, grupos extra ni vértices sin peso. *Limit Total* elimina los pesos menores hasta alcanzar el límite. [Blender, edición de Weight Paint](https://docs.blender.org/manual/nb/5.0/sculpt_paint/weight_paint/editing.html)
7. Agregar Armature modifier apuntando al rig conservado y reconstruir las UV2 de la espalda con exclusión de pecho y mangas. Asignar los nombres de material que espera el runtime y una base de tejido neutral que admita tintes.
8. Exportar el candidato a un nombre nuevo con el patrón existente: GLB, selección de rig/mallas, skins, Y-up, cuatro influencias, animaciones por NLA. Conservar un `.blend` editable. La exportación glTF soporta skinning y animaciones; separar las pistas NLA mantiene múltiples clips. [Blender, glTF](https://docs.blender.org/manual/en/3.2/addons/import_export/scene_gltf2.html)

No aplicar el Armature modifier para “limpiar” la malla: eso hornearía una pose y eliminaría la deformación del objeto. Tampoco parentar con Automatic Weights sobre el rig ya validado como reemplazo indiscriminado de sus pesos. Son acciones que pueden romper la animación si se realizan en los archivos originales.

### C. Rig Meshy independiente: ruta secundaria

Si por topología o proporciones fuese imprescindible usar otro esqueleto, requiere una prueba separada de retargeting. Godot aclara que igualar nombres no alcanza: también influyen rest poses, jerarquía y ejes. BoneMap/SkeletonProfileHumanoid permite mapear, pero corregir la pose A, ejes y silueta puede alterar pies/manos. Eso obliga a validar nuevamente patada y atajadas; no conserva por sí solo el contrato de 53 huesos. [Godot 4.7, retargeting](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/retargeting_3d_skeletons.html)

La opción preferida para este ensayo es **malla nueva + esqueleto actual**. El resultado puede representar una silueta nueva sin cambiar los huesos. Si la figura necesita articulaciones mucho más alejadas, el coste de cambiar rig y gameplay debe evaluarse aparte.

## Presupuesto propuesto y aceptación

Estos son límites de prueba del proyecto, no cifras publicadas por Football Strike ni promesas del generador.

| Recurso | Objetivo del candidato |
|---|---|
| Triángulos LOD0 | 20–35 mil si la calidad visual lo permite; no superar 89,843 jugador / 96,571 arquero para aprobar como reemplazo sin justificación y medición |
| Materiales | Hasta las 11/12 superficies actuales; preferir menos compartiendo mapas donde corresponda, sin perder tintes separados |
| Texturas | 1024² piel/pelo; 512² uniforme para primera comparación; subir solo con ventaja visible a escala real |
| GLB del jugador | No superar aproximadamente 7.4 MB sin una mejora visible y una comparación de carga |
| Skin | Armature original de 53 huesos, máximo cuatro influencias, suma de pesos normalizada |
| Animación | Ocho clips originales, mismos datos y duraciones; misma altura/origen/runtime scale |
| Rendimiento | Medición nueva en navegador, equipo/calidad/resolución iguales; sin regresión sostenida >5% de p95 como gate inicial |

La importación de Godot puede generar LOD y tangentes y usar skins por nombre; UV2 puede generarse al activar lightmaps estáticos, por lo que esa opción debe evitarse en esta camiseta. El bind mantiene matrices y referencia a huesos, no se resuelve únicamente con el nombre del objeto. [Godot 4.7, configuración de importación](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html)

**Go** solo si se cumplen las tres condiciones: mejora visible en comparación equivalentes, limpieza/articulaciones razonables y personalización/animación correctas. **No-go** para ropa/miembros fusionados que necesiten reconstrucción general, silueta que funcione solo desde la imagen original, dedos/botines defectuosos difíciles de conservar o material único que impida los colores actuales.

Antes de aprobar animación: capturas en Idle, Kick cerca de contacto (~0.47 s), Catch y las cuatro atajadas, además de Celebrate. Revisar piel atravesando mangas/pecho/short, continuidad cuello/cintura, pliegues deformados y aparición del número en el frente. Repetir perfiles y ambos roles tras aprobar el jugador.

## Herramientas existentes reutilizables

- `source-assets/footballer/footballer_v3.blend` y `goalkeeper_v3.blend`: rig y clips a conservar.
- `source-assets/footballer/athlete_v3_manifest.json`: escala, mapas, métricas y procedencia actuales.
- `apps/free-kick-3d/tools/preview_athlete_neutral.gd`: luz y cámaras; adaptar copia para candidato estático.
- `preview_athlete_family.gd`: comparación de todos los perfiles una vez que se respeta el contrato.
- `preview_athlete_v3.gd` / `capture_match_visual.gd`: contexto real del estadio y cámara de juego.
- `footballer_visual.gd` y `shaders/athlete_kit.gdshader`: colores y dorsal existentes que deben pasar la prueba.
- `tests/athlete_v3_test.gd`, `custom_players_test.gd`, `keeper_hands_test.gd`, `kick_contact_and_dive_test.gd`, `keeper_save_balance_test.gd`: comportamiento/personalización existentes. Los tests actuales cargan producción; para candidato hace falta harness aislado o proyecto de copia con sustitución únicamente en esa copia.
- `tools/benchmark_graphics.gd`: benchmark nativo reutilizable en copia. Las métricas históricas del manifest son previas a esta revisión; no demuestran FPS web del candidato.
- `tailor_footballer_jersey.py`, `tailor_footballer_shorts.py`, `tailor_footballer_sleeves.py`, `athletic_footballer.py`: útiles como referencia del diseño y auditorías, **no ejecutarlos sobre Meshy sin adaptar**: usan índices/materiales/estructura de la malla actual y rutas de exportación a producción.
- `build_footballer_v3.py`: referencia de exportación y pesos, no herramienta de conversión Meshy; un rebuild completo recrea geometría de MPFB y no conservaría una alternativa importada.

## Esfuerzo de la alternativa

Estimación técnica, condicionada al GLB recibido: preparar referencia y comparar un candidato estático puede resolverse en unas horas de trabajo; una malla razonablemente limpia que admita separar ropa y conservar cabeza/botines necesita aproximadamente 1–2 jornadas para materiales, pesos y pruebas. Un resultado con anatomía/ropa fusionada o topología incapaz de doblar requiere retopología y varios días: en ese caso conviene tomar la silueta como guía y mejorar el modelo actual. Estas duraciones no son una promesa de calidad ni un motivo para integrar una alternativa defectuosa.

La primera decisión útil es visual y barata: comparar una única generación descargable. La integración se justifica solo después de esa evidencia.

## Resultado del candidato real descargado

Se auditó `source-assets/footballer/meshy-trial-2026-10-06/meshy-lite-raw.glb`, SHA-256 `0a2f7b66a9fc3edaf7175766d54647f667f38e33379b0dcb666fd21245febec3`. Métricas completas: [candidato-auditoria.json](candidato-auditoria.json).

Tiene **101,904 triángulos**, 59,055 vértices exportados, un nodo sin nombre, una malla/primitive y un material sin nombre. Pesa **7,765,716 bytes**. Es 13.42% más complejo en triángulos que el jugador actual y 5.52% más que el arquero. Lleva tres mapas JPEG de **2048²** —albedo, metallic/roughness y normal— en un único atlas; los colores de ropa, piel y pelo no están separados por materiales.

**No contiene esqueleto, skin, JOINTS/WEIGHTS, animaciones ni UV2**. Su altura es 1.899616 m, prácticamente igual a la actual (+0.039%), pero está centrado alrededor del origen: hay que subirlo 0.953246 m para apoyar los pies en el suelo. No requiere un cambio de altura del rig como consecuencia de esa normalización.

Al soldar posiciones coincidentes exactamente —y repetir con una cuadrícula de 1e-6 m— quedan 50,944 posiciones únicas y **un componente cerrado**, con cero bordes abiertos, cero aristas no-manifold, cero caras duplicadas y cero triángulos colapsados. Los 8,111 vértices adicionales son cortes de atributos/UV, no prueba de agujeros. El componente tiene Euler -8/genus 5; esa observación topológica no se considera por sí sola un fallo de animación. Hay 73 caras (~0.072%) cuyo promedio de normales apunta contra su winding: revisar el sombreado local al limpiar. No se evaluaron auto-intersecciones ni deformación.

También se inspeccionaron las comparaciones de Godot preparadas por el coordinador: `comparacion-front.png`, `comparacion-back.png` y `comparacion-profile.png`. **Sí sirve como base estética**: camiseta con manga más continua, cuello fino, pliegues y caída de tela; short con cintura y piernas más reconocibles; cuerpo atlético con pecho moderado. Es una valoración visual de esas vistas estáticas, no aprobación de rig. La cara, el pelo y los botines del candidato son distintos a los originales y deberán conservarse/reintegrarse según los límites de la mejora.

La siguiente prueba útil es **segmentar las prendas y evaluar pesos sobre una copia del rig original**. Bloquean la integración directa la ausencia total de skin/animaciones, el atlas único sin regiones personalizables, la falta de UV2 del dorsal y de los nombres/rutas esperados. Además, supera el presupuesto de triángulos del reemplazo propuesto: conviene retopología/simplificación y rehorneado de mapas antes de presentarlo como opción de producción. Que sea cerrado y se vea mejor no evita esas tareas.

## Alcance de la verificación

Este agente inspeccionó los archivos GLB, scripts y capturas indicados de forma read-only. No ejecutó Blender, no transfirió pesos, no generó el candidato Meshy y no alteró el juego; únicamente escribió este informe y el JSON de auditoría. Fuentes oficiales Blender/Godot consultadas el 2026-10-06; las páginas inglesas actuales de Blender no se pudieron abrir con el navegador de investigación, pero su índice devolvió manuales oficiales 5.0 en otros idiomas y la documentación glTF 3.2. Los controles concretos de Blender 5.2.2 se deben verificar en la herramienta al implementar, junto con el patrón de exportación ya probado del proyecto.
