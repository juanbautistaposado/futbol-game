# Revisión del pecho y compatibilidad del rig

Fecha: 2026-10-04. Investigación delegada con `research` y `create-game-assets`; no se modifica el modelo en este informe.

## Evidencia y diagnóstico

La [página oficial de Football Strike](https://www.miniclip.com/games/football-strike) publica capturas de personalización y gameplay, pero no una ficha de altura, medidas anatómicas ni un modelo de referencia descargable. Se comprobaron los enlaces oficiales de la [vista frontal](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_IPhone_04_EN.jpg) y la [patada posterior](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_iPhone_01_B_EN.jpg). La estatura exacta del personaje no queda documentada por estas fuentes; los valores recomendados abajo son decisiones de autoría, no medidas de Miniclip.

Se inspeccionaron los renders locales `frente.png` y `perfil.png` y el código `apps/free-kick-3d/tools/athletic_footballer.py`. El torso actual tiene aspecto de bloque alto: la anchura domina sobre las piernas y el hombro presenta un volumen redondeado muy fuerte. El perfil no muestra una punta aislada como problema dominante; el exceso corresponde al volumen general superior, especialmente pecho, espalda y hombro. No conviene corregir únicamente la cara frontal del pecho porque la espalda y los deltoides mantendrían la desproporción.

La auditoría de la primera pasada mide pecho de 0,4993 a 0,5411 m (+8,37%) y cintura de 0,3925 a 0,3990 m (+1,67%). La relación pecho/cintura pasa de 1,272 a 1,356. El script utiliza un factor X de 18% dentro de una máscara progresiva, por lo que el incremento real de sección no es 18%. Añade además 8% de profundidad relativa al eje y = -0,020 m y hasta 26% de radio de brazo superior. Esta combinación explica por qué el conjunto pesa visualmente arriba aunque cada operación individual parezca moderada.

## Cambio recomendado

Regenerar desde la base previa a la pasada atlética, conservando los últimos arreglos de short y manga; no acumular otra expansión encima del cuerpo actual.

| Parámetro de autoría | Actual | Primera propuesta revisada |
|---|---:|---:|
| Factor de ancho de torso dentro de la máscara | 0,18 | 0,04–0,06 |
| Factor de profundidad torso | 0,08 | 0,00–0,02 |
| Máximo aumento radial brazo superior | 0,26 | 0,15–0,18 |
| Máximo aumento radial muslo | 0,13 | 0,22–0,26 |
| Máximo aumento radial pantorrilla | 0,12 | 0,18–0,22 |

El objetivo inicial para la sección de pecho es aproximadamente 0,508–0,514 m; debe confirmarse midiendo la geometría resultante, no deducirse como un porcentaje aplicado a toda la sección. Mantener cintura alrededor de 0,395–0,399 m y no inflar el abdomen. Estos rangos son una hipótesis de ajuste visual para la base propia, no especificaciones oficiales de Football Strike.

Aplicar el mismo campo de deformación a piel y camiseta, tanto por delante como por detrás. No reducir sólo la camiseta: produciría atravesamientos del cuerpo. La máscara superior debe caer suavemente antes del cuello y hacia la axila. Preservar el cuello central protegido; no cambiar cara, pelo, manos ni botines. Mantener rodilla y tobillo con radio original y aumentar el vientre del músculo, no toda la extremidad como cilindro.

## Altura y esqueleto

Recomiendo conservar los 1,90 m del asset fuente, las longitudes y posiciones de las articulaciones y la escala de runtime existente. El error reportado se resuelve redistribuyendo volumen y no requiere alterar altura. No hay datos primarios para afirmar que Football Strike mida exactamente 1,80, 1,85 o 1,90 m.

La documentación de [Godot sobre importación](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html) explica que el skin conserva las matrices de enlace con el esqueleto y que `Apply Root Scale` puede aplicar la escala a mallas y animaciones conjuntamente. Por tanto, una escala uniforme del conjunto puede cambiar estatura sin cambiar sus proporciones, pero también cambia contacto, alcance y encuadre de juego; no reduce un pecho grande respecto de las piernas.

La documentación de [retargeting de Godot](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html) requiere compatibilidad de Bone Rest además de nombres y advierte sobre desplazamiento de pies al compartir movimiento entre alturas distintas. Alterar pelvis, rodillas o longitudes en Edit Mode introduciría un trabajo de adaptación de clips que no hace falta para este pedido. Mantener las articulaciones actuales evita ese riesgo.

El exportador de [Blender glTF 2.0](https://docs.blender.org/manual/en/5.0/addons/import_export/scene_gltf2.html) admite transformaciones de objetos, poses de huesos y valores de shape keys; el modo NLA Tracks conserva cada pista como animación independiente. Conservar el export actual con skins y NLA, sin aplicar Armature, cambiar nombres de pistas ni añadir otro esqueleto.

## Verificación propuesta

1. Comparación frontal, posterior y lateral bajo idéntica cámara y luz, más gameplay durante patada. El objetivo es piernas con mayor presencia y torso más contenido, sin evaluar exclusivamente una imagen ampliada.
2. Auditoría exacta de huesos, rest transforms, pesos, UV, acciones, curvas y geometría de partes protegidas. Deben permanecer 53 huesos y los ocho clips existentes.
3. Comprobar cuello, axila, camiseta, entrepierna y short en `Idle`, `Kick` y `Celebrate`: mantener las mejoras de prendas y evitar intersección con piel ampliada.
4. Medir ancho/profundidad de pecho y secciones de muslo/pantorrilla antes y después. Conservar coordenadas Z máximas, pivote y contacto de botines.

Ninguna medida inferida de screenshots en perspectiva debe presentarse como anatomía exacta de Football Strike. El resultado verificable es una silueta comparable desde la cámara de juego y una deformación estable con el rig propio.
