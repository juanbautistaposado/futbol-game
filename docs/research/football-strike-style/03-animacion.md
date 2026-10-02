# Rol 3 — Rigging y animación de fútbol

Consulta: 23 de septiembre de 2026. Fuentes oficiales; fechas de publicación indicadas cuando existen. Las recomendaciones y tiempos son estimaciones de producción, no características confirmadas de Football Strike. Documentación Godot `stable` consultada en esa fecha; su alias es mutable y no demuestra la versión instalada del proyecto.

## Comparativa verificada y valoración

| Opción | Costo y uso publicado | Dificultad / calidad esperada (valoración) | Aplicación |
|---|---|---|---|
| Blender + rig humano propio/Rigify | Blender gratis, GPL; las obras creadas no se vuelven GPL y pueden publicarse comercialmente. Licencias de assets importados siguen aplicando. | Media-alta; máximo control, resultado depende del animador. | Patear y atajar con contacto preciso; controlar silueta humana y movimiento deportivo. |
| Mixamo | Gratis con Adobe ID personal; FAQ autoriza personajes y animaciones royalty-free en videojuegos comerciales. No es CC0. | Baja al arrancar, media al corregir pesos/retarget; buena base de movimiento humano, necesita exageración estilizada. | Auto-rig y clips como punto de partida. No se verificó un inventario actual de patadas/atajadas específicas. |
| Quaternius Universal Animation Library | Standard gratis; Pro USD 9,99; Source USD 14,99 al consultar. CC0 y uso comercial declarado. Source incluye `.blend`. | Baja con su rig; media en otros esqueletos. Estilo de juego consistente; acciones futbolísticas propias requieren autoría adicional. | Locomoción y emotes; versiones con/sin root motion. No asumir que los 120+ clips están incluidos en Standard. |

Fuentes: [Blender License](https://www.blender.org/about/license/) (s/f); [Adobe FAQ](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html) (14-09-2021, aún accesible); [Quaternius, página del autor](https://quaternius.itch.io/universal-animation-library) (actualizada 16-09-2026, changelog de root motion 16-06-2026). Precios sin impuestos ni conversiones.

Rigify genera controles a partir de un metarig que se ajusta al personaje; hay que conservar ese metarig para futuras modificaciones. Pesos automáticos son un comienzo, no una validación de hombros/ingle. [Manual oficial Rigify Basic Usage](https://docs.blender.org/manual/en/latest/addons/rigging/rigify/basics.html?highlight=pose+mode) (s/f; resultado consultado identificado como manual 4.4, no prueba de versión Blender actual).

Mixamo acepta FBX/OBJ/ZIP para modelos propios y FBX para personajes ya riggeados. Conviene subir una malla limpia y centrada, en pose neutral y sin objetos auxiliares. Sus requisitos de auto-rig limitan proporciones extremas. Descargar y guardar los resultados localmente. [Adobe Upload and rig](https://helpx.adobe.com/creative-cloud/help/mixamo-rigging-animation.html) (14-09-2021) y FAQ anterior.

La licencia comercial de Mixamo está verificada; **no se verificó aquí permiso para redistribuir sus archivos crudos en un repositorio público**. Mantener esa cuestión abierta antes de publicar fuentes con esos assets. Sus [Additional Terms](https://wwwimages2.adobe.com/content/dam/cc/en/legal/servicetou/Mixamo-Addl-Terms-en_US-20210623.pdf) (23-06-2021) incorporan condiciones generales y prohíben usar contenido derivado para crear/entrenar/mejorar sistemas IA/ML; no interpretar el auto-rigger como permiso de entrenamiento.

## Retarget en Godot: procedimiento verificado

1. Abrir importación avanzada del modelo y seleccionar `Skeleton3D`.
2. Crear `BoneMap` y asignar `SkeletonProfileHumanoid`; revisar manualmente errores de mapeo, jerarquía y nombres.
3. Hacer lo mismo sobre la fuente animada; importarla como `AnimationLibrary` cuando se quiera compartir clips.
4. Unificar nombres/rutas usando Bone Renamer/Unique Node. Igualar nombres solamente no alcanza: también importan las poses de reposo.
5. Revisar Rest Fixer. El perfil usa T-pose y frente +Z. `Fix Silhouette` puede ayudar con A-pose, pero no resuelve cualquier deformación.
6. Para bibliotecas compartidas, revisar Remove Tracks; quitar posiciones no esenciales evita alterar proporciones. No eliminar indiscriminadamente pistas de accesorios.
7. Normalizar posiciones según altura si se comparte entre cuerpos distintos; verificar pies y talones visualmente.

Fuente: [Retargeting 3D Skeletons, Godot stable](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html) (s/f). No se realizó una importación real durante esta investigación.

`Skeleton3D` representa el esqueleto del modelo; `BoneMap` vincula sus huesos al perfil. El perfil humano contiene 56 posiciones de referencia; **esto no significa que el personaje necesite obligatoriamente 56 huesos**. [SkeletonProfileHumanoid, Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_skeletonprofilehumanoid.html) (s/f).

## Plan recomendado para este juego (propuesta)

- Crear un único rig de deformación compartido por delantero y arquero. Aproximadamente 24–40 huesos iniciales; manos simples y sin rig facial complejo. Ropa y cuerpo usan los mismos pesos. Conservar controles de autoría en Blender; exportar movimiento horneado al rig de deformación.
- Validar primero un ciclo de espera y **una patada**. Separar anticipación, apoyo del pie, giro de cadera, contacto y recuperación. La pelota recibe su impulso en el contacto, una sola vez. No depender de que el clip y un temporizador separado casualmente coincidan.
- Mantener las interfaces actuales `kicker.kick(strike)` y `keeper.dive(...)`; introducir el modelo como capa visual. Conservar inicialmente la sincronía existente de contacto (~0,48 s), ajustando el clip al contrato. No mezclar esta migración con cambios de IA ni de trayectoria.
- Luego sumar `run`, `celebrate`, `keeper_ready`, `save_left/right`, `catch_low`, `recover`. Son clips **a producir/validar**, no un catálogo prometido de Mixamo o Quaternius. Para atajar, diseñar primero poses extremas y llegada de las manos al balón; para retener, anclar visualmente la pelota a un punto entre las manos después del evento de captura.
- Usar `AnimationPlayer` como contenedor de clips y `AnimationTree` como controlador de estados y mezclas. Hacer transiciones cortas hacia atajadas para no retrasar el contacto; no activar locomoción simultáneamente desde otro script sobre los mismos huesos.
- Para esta primera migración, preferir clips in-place y conservar desplazamientos existentes. Root motion es una alternativa posterior, no una corrección automática: Godot extrae del hueso elegido el desplazamiento que el código debe aplicar. Aplicar a la vez root motion y movimiento de gameplay duplica el avance.

Las capacidades de mezclas, estados y extracción mediante `get_root_motion_position()` están documentadas en [Using AnimationTree](https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html) (s/f). La elección in-place es nuestra recomendación para reducir riesgo en este juego, no una limitación de Godot.

## Tiempo y criterio de aceptación (estimaciones)

- Rig compartido y ajuste de pesos sobre una base sana: 3–6 h con experiencia; principiante, 1–3 días.
- Importar espera/carrera y verificar retarget: 2–4 h.
- Patada propia, evento de contacto y prueba dentro del juego: 4–8 h.
- Atajadas izquierda/derecha, captura/recuperación y celebración: 8–16 h adicionales.
- Total animación de una primera versión, excluyendo modelado: 17–34 h con experiencia; reservar más aprendizaje para principiantes.

Aceptar cuando no haya patinaje evidente, cortes de ropa, brazos torcidos, doble impulso ni salto de escala entre estados; el pie y las manos deben coincidir con la pelota desde las cámaras reales. Probar ambos personajes personalizados y repetir tras reimportar. El retarget reutiliza movimiento, pero no garantiza contactos exactos para cuerpos de proporciones distintas.
