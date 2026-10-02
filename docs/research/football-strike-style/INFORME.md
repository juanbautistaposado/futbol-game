# Personajes con estética similar a Football Strike: investigación y plan de producción

> **Informe histórico del 23–24/09/2026.** El proyecto ya cambió: los personajes actuales son GLB con rig y animaciones. Para el diagnóstico y plan vigentes, ver [INFORME-2026-09-28.md](INFORME-2026-09-28.md).

**Fuentes consultadas entre el 23 y el 24 de septiembre de 2026.** Seis roles de investigación distribuidos en tandas entre agentes: estilo, creación, animación, implementación, look y revisión crítica. Coordinación y contraste con el proyecto local. No se modificó el juego ni se compraron/descargaron assets durante la investigación.

**Recomendación:** probar una base humana CC0 de Quaternius como punto de partida y **transformarla profundamente en Blender**: anatomía adulta, rostro humano estilizado, uniforme de fútbol con pliegues y materiales suaves. Compartir un rig humanoide entre delantero y arquero, ajustar patada y atajadas, exportar GLB e integrar en Godot. Si la base conserva un aspecto de muñeco aun después de la prueba de silueta, pasar al modelado original del pipeline B. La meta visual es el realismo deportivo simplificado de Football Strike.

**Cómo leer la evidencia:** **V** = documentación, condiciones del proveedor o código local verificados; **O** = interpretación visual de referencias; **P** = propuesta o estimación de producción, no dato del juego original ni rendimiento medido. Las fechas de consulta no son fechas de publicación. Precios en USD sin impuestos.

## 1. Estilo a replicar: siete decisiones

1. **O:** anatomía adulta y atlética, hombros anchos, cintura definida, piernas con volumen. **P:** proporción adulta de unas 7–7,5 cabezas como guía inicial, verificable solo sobre nuestro modelo; mantener manos y botines plausibles.
2. **O:** superficies suaves, sin facetas grandes visibles. **P:** malla optimizada con normales suavizadas, volumen continuo y densidad donde cambian la silueta y las articulaciones.
3. **O:** caras simplificadas pero humanas, mandíbula/nariz/cejas reconocibles. **P:** pelo y barba con volumen modelado, expresión humana legible y textura de piel discreta que resista la cámara cercana.
4. **O:** uniformes contrastantes contra el verde de la cancha. **P:** paleta deportiva saturada pero verosímil, con camisetas, shorts y medias recoloreables.
5. **O:** ropa con ribetes y pliegues legibles. **P:** pliegues en textura y volumen, costuras y ribetes discretos, con nombre y dorsal propios.
6. **O:** el sombreado de las capturas es suave. **P:** iluminación de estadio clara, piel y tela con respuesta suave, sombras de contacto; usar materiales estándar antes de efectos estilizados.
7. **P:** animaciones expresivas mediante transferencia de peso, anticipación y seguimiento: espera, carrera corta, patada, estirada, caída, recuperación y celebración. Asegurar contacto de pie/manos con pelota antes que cantidad de clips.

Las [capturas oficiales de Miniclip](https://www.miniclip.com/games/football-strike) (s/f) muestran **realismo deportivo simplificado**, con anatomía humana y superficies suaves. Esta es la dirección visual elegida por el usuario el 24/09/2026; se descarta el tratamiento más cartoon que aparecía en el primer borrador. No se publicaron datos verificables de polígonos, huesos, tamaño de texturas o shaders originales. No corresponde inventar esos números a partir de un video. Detalle visual y fuentes: [01-estilo.md](01-estilo.md).

## 2. Herramientas, derechos y tres pipelines completos

| Herramienta/asset | Costo verificado al consultar | ¿Se puede publicar un juego? | Dificultad y calidad esperada — P |
|---|---|---|---|
| [Blender](https://www.blender.org/about/license/) | Gratis | Sí. GPL del programa no obliga a licenciar bajo GPL las obras creadas. Respetar los assets importados. | Media con base; alta desde cero. Mayor control artístico. |
| [Quaternius Universal Base Characters](https://quaternius.itch.io/universal-base-characters) | Standard gratis parcial; Source USD19,99 | Sí, CC0. Comprobar qué incluye cada descarga. | Media. Base consistente, requiere ropa y proporciones propias. |
| [Kenney Animated Characters Protagonists](https://kenney.nl/assets/animated-characters-protagonists) | Gratis | Sí, CC0 según autor. | Baja para probar integración; más adaptación para look atlético. Formatos del ZIP no inspeccionados. |
| [Mixamo](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html) | Gratis con Adobe ID | Sí, royalty-free para videojuegos comerciales; no es CC0. Redistribución de archivos crudos no confirmada aquí. | Baja al empezar, media para corregir. Movimiento humano útil; fútbol exacto requiere ajustes. |
| [Quaternius Universal Animation Library](https://quaternius.itch.io/universal-animation-library) | Standard gratis; Pro9,99; Source14,99 | Sí, CC0. No todos los clips están necesariamente en Standard. | Baja con rig compatible, media con retarget. No se confirmó un paquete completo de acciones de fútbol. |
| [Meshy](https://www.meshy.ai/pricing) | Free0; Pro20/mes habitual | Pago: derechos sobre output según términos y ley; Free: CC BY4.0, pero ayuda actual impide nuevas descargas gratuitas. | Generación fácil, limpieza media/alta. Anatomía y topología variables. |
| [Godot](https://godotengine.org/license/) | Gratis, sin regalías | Sí, MIT; incluir aviso de licencia del motor y terceros. | Media. Integración controlable; calidad depende de assets, luz y animaciones. |

Fechas y condiciones completas en [02-creacion.md](02-creacion.md) y [03-animacion.md](03-animacion.md). Las valoraciones no son benchmarks.

| Pipeline completo | Recorrido | Ventaja / riesgo | Tiempo estimado y gasto |
|---|---|---|---|
| **A. Base CC0 muy adaptada — recomendado como prueba** | Quaternius → Blender: proporciones, ropa, UV/pesos → rig compartido y clips adaptados → GLB → BoneMap/AnimationTree → validar patada en Godot | Permite probar pronto rig e integración. Exige rehacer rostro, cuerpo y ropa hasta alcanzar la referencia; si queda demasiado genérica, usar B. | Primer delantero refinado espera+patada:30–60h; USD0 con contenido Standard adecuado. Fuentes editables opcionales:19,99+14,99=34,98. |
| **B. Original desde cero** | Diseño frontal/lateral → modelado y UV Blender → rig/pesos → animación propia o retarget → horneado/GLB → estados en Godot | Máxima identidad visual. Mayor dificultad artística y técnica. | 60–120h para primer personaje refinado con clips esenciales; software0. |
| **C. IA + saneamiento** | Concepto propio → Meshy → selección → retopología/UV/ropa en Blender → rig/pesos/animación → GLB → Godot | Rápido para explorar volumen; tiempo imprevisible para obtener una malla modular que deforme bien. | 30–70h para candidato viable y refinado; Pro20/mes más trabajo. No garantiza ahorrar tiempo. |

Tiempos **P**, con experiencia básica real en Blender/Godot, sin aprendizaje desde cero ni revisiones ilimitadas. No comparar estos rangos con la generación de un preview de pocos minutos. Estos rangos se reajustaron el 24/09/2026 por el objetivo de mayor fidelidad visual. La primera fase A no incluye todas las atajadas y celebraciones.

**Por qué A para este proyecto:** ya tenemos juego, personalización y reglas. Lo que falta es una base visual coherente y animable; una biblioteca CC0 evita dependencia de suscripciones y facilita mantener los assets fuente en el repositorio. La base solo ahorra trabajo de rig/topología si supera una comparación visual temprana; Blender debe convertirla en un futbolista con la referencia buscada. Si ese cambio cuesta tanto como modelar desde cero, elegir B.

**Precauciones concretas verificadas:** Meshy presenta discrepancias entre su página de precios/ayuda y términos sobre privacidad y derechos. No prometer confidencialidad por pagar Pro; comunidad distingue modelos CC0 de imágenes CC BY-NC. Consultar [términos del 19/09/2026](https://www.meshy.ai/terms-of-use) antes de usar ese flujo. Mixamo permite publicación comercial, pero eso no demuestra permiso para distribuir sus FBX sueltos como biblioteca pública.

## 3. Plan para el primer personaje jugable

**Hito A: delantero propio, espera + patada, sin cambiar reglas ni cámara.**

| Paso | Trabajo y criterio de aceptación | Horas P |
|---|---|---:|
| 1 | Elegir base CC0 concreta, guardar licencia y hacer una prueba de silueta frente a capturas de Football Strike desde la cámara del juego; descartarla si no se puede lograr anatomía humana convincente. | 2–4 |
| 2 | Adaptar proporciones adultas, cara, cabello, cuerpo, camiseta, shorts, medias y botines en Blender. Comprobar similitud de estilo en la cámara real. | 10–20 |
| 3 | Preparar UV/atlas y regiones recoloreables; conservar nombre y número. | 4–8 |
| 4 | Revisar rig/pesos en hombros, cadera, rodilla; preparar espera y patada con apoyo/contacto/seguimiento. | 7–14 |
| 5 | Exportar GLB e integrar en una escena envolvente. Conectar estados y evento único de contacto. | 4–8 |
| 6 | Validar reimportación, personalización, pausa, reinicio y rendimiento en dispositivo objetivo. | 3–6 |
| | **Total primer hito** | **30–60** |

**Hito B:** adaptar el mismo cuerpo/rig al arquero, guantes, espera, atajadas a ambos lados, retención, recuperación y celebración: **16–30h adicionales** aprovechando lo anterior. Total orientativo **46–90h**. Son estimaciones consolidadas por alcance; no deben sumarse de nuevo con los tiempos de los informes por rol. Un principiante debe añadir aprendizaje.

**Integración local:** el proyecto usa Godot4.7.1 y Compatibility. Los personajes actuales son Node3D articulados con Tween. Mantener las interfaces `kicker.kick(strike)` y `keeper.dive(...)`, reemplazando su capa visual. El contacto actual está a0,48s: comenzar ajustando el clip a ese contrato, luego usar evento de contacto controlado, ejecutado una sola vez. Evitar que la mezcla entre clips dispare dos impulsos. Conservar resultado, IA, trayectorias y cámaras existentes.

**Criterio de salida:** personaje legible de frente/espalda, camiseta sin atravesar piel en poses extremas, pie que toca pelota, variantes de nombre/color independientes, clip que puede reiniciarse y pausa consistente. Para arquero: manos coinciden con captura; retención y rebote siguen siendo decisiones del juego.

## 4. Especificaciones técnicas propuestas

**Presupuestos nuestros, no números oficiales de Football Strike ni límites de Godot.**

| Elemento | Punto de partida P |
|---|---|
| Triángulos | 8.000–16.000 por protagonista LOD0 para sostener un rostro y pliegues suaves. Una base de13k está dentro de esta meta; medir antes de aumentar o reducir. No confundir polígonos/quads con triángulos exportados. |
| LODs | Probar LOD1 alrededor de4–8k y LOD2 de2–4k; ajustar por tamaño en pantalla. Verificar rodillas, cara y manos en movimiento. |
| Texturas | Atlas base1024²; 512² para variantes lejanas, 2048² solo si el primer plano lo justifica. Máscara uniforme512–1024; normal map opcional. Mipmaps y compresión adecuada al destino. |
| Memoria ilustrativa | RGBA8 sin comprimir1024²≈4MiB; con cadena completa de mipmaps≈5,33MiB. Cada mapa adicional suma; tamaño del PNG no es memoria GPU. Compresión cambia el cálculo. |
| Esqueleto | 24–40 huesos de deformación como objetivo inicial; usar 4 influencias/vértice como opción compatible de exportación en este renderer, no como límite total de huesos. No exportar controles innecesarios. Mantener rig existente algo mayor si simplificarlo rompe compatibilidad. |
| Caras/manos | Cara modelada con volumen humano; animación facial simple inicialmente. Gestos mediante cabeza, torso y brazos, manos suficientes para sostener pelota. |
| Superficies | Objetivo2–4 materiales/superficies por personaje; variaciones por shader/atlas, no una superficie por cada detalle. |
| Formato | glTF2.0 binario `.glb` para entregar; `.blend` como fuente versionada. Animaciones horneadas, escala coherente1unidad≈1metro. |
| Animación | Espera/carrera en loop; patada/atajadas no-loop; muestreo inicial igual a la tasa base en Blender (30 muestras/s solo como ejemplo), sin confundirlo con FPS del juego. |
| Móvil | Probar30fps sostenidos en equipo mínimo;60fps como objetivo si presupuesto lo permite. Medir CPU/GPU, draw calls, sombras, estadio y temperatura, no solo personaje. |

**Medición local V:** MATEO actual tiene38.200 triángulos base y65 superficies/65MeshInstance3D, sin contar texto ni pases de sombras. No significa65drawcalls medidos. [Procedimiento](00-contexto-local.md). Cambiar a una malla skinned con pocas superficies puede mejorar coherencia y costo, pero no hemos medido todavía la alternativa.

**Importación y retarget:** Godot recomienda [glTF2.0](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html). Importación avanzada → `Skeleton3D` → `BoneMap` con `SkeletonProfileHumanoid`, tanto para modelo como para fuente animada. Revisar nombres, jerarquía, T-pose, frente del perfil y rest pose; usar las herramientas de corrección de reposo cuando corresponda. El mapa no crea un rig ni arregla malos pesos. Importar clips compartidos como `AnimationLibrary`; `AnimationPlayer` almacena clips y `AnimationTree` controla estados/mezclas. Comenzar con animaciones in-place y desplazamiento del gameplay para evitar doble movimiento. [Retarget oficial](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/retargeting_3d_skeletons.html), [AnimationTree](https://docs.godotengine.org/en/4.7/tutorials/animation/animation_tree.html) (s/f, consulta23/09/2026).

**Colores:** separar regiones camiseta/shorts/piel/cabello mediante máscara o superficies. Para tintes distintos por jugador, probar `instance uniform` y `set_instance_shader_parameter()` sobre cada MeshInstance3D; si el diseño necesita materiales diferentes por región, duplicar o sobrescribir ese material por personaje. Una textura de nombre/dorsal o placa apropiadamente colocada debe seguir el torso animado. No recolorear piel accidentalmente con un tinte global. Mantener materiales externos al importado para que reimportar no destruya ajustes.

**Look en Godot:** el proyecto usa Compatibility. Empezar con `StandardMaterial3D`, piel de brillo bajo, tela mate, mapas de normal sutiles, una luz principal y ambiente de estadio; comparar en partido y menú. Godot incluye [documentación de materiales e iluminación para 4.7](https://docs.godotengine.org/en/4.7/tutorials/3d/environment_and_post_processing.html). Los shaders toon y de contorno libres de [eldskald (MIT)](https://github.com/eldskald/godot4-cel-shader) y [EMBYRDEV (MIT)](https://github.com/EMBYRDEV/godot-toon-outline) están investigados como ejemplos técnicos en [05-look.md](05-look.md), pero **no forman parte de la dirección visual recomendada**. El segundo requiere adaptación a Godot 4.7/Compatibility; ninguno se probó aquí en el juego.

**LOD:** [Godot genera LODs al importar escenas](https://docs.godotengine.org/en/4.7/tutorials/3d/mesh_lod.html), pero advierte fallos posibles en mallas skinned: revisar deformación y desactivar/reemplazar LOD defectuoso. Reducir geometría no reduce por sí mismo materiales, huesos o costo de animación.

## 5. Errores frecuentes y cómo evitarlos

| Error | Prevención |
|---|---|
| Confundir malla optimizada con apariencia facetada | Usar normales suaves y distribuir triángulos donde cambian silueta o deformación. |
| Confiar en que auto-rig/IA significa listo para jugar | Probar sentadilla, brazo arriba, patada y estirada; corregir topología y pesos antes de producir variantes. |
| Importar OBJ esperando animación | Entregar GLB con skin y clips; OBJ no contiene el esqueleto/animaciones necesarios. |
| Cambiar nombres de huesos y esperar retarget perfecto | Validar también jerarquía, orientación y rest pose, luego corregir contactos. |
| Exportar rig de control sin hornear | Exportar rig de deformación y animaciones resueltas; comprobar el GLB en una escena limpia. |
| Root motion y código desplazan a la vez | Elegir un dueño del desplazamiento; inicialmente in-place con gameplay existente. |
| Patada visual desconectada del impulso | Un evento lógico de contacto por tiro, comprobado también durante mezclas/pausa/reinicio. |
| Editar la escena importada directamente | Crear escena envolvente y recursos externos; reimportar como prueba de aceptación. |
| Cambiar color de todos al personalizar uno | Duplicar el material correspondiente y conservar identidad independiente. |
| Ropa atravesando piel y pelo mal pegado | Ropa skinned al mismo rig; accesorios rígidos con BoneAttachment3D; revisar poses extremas. |
| Shader de otro renderer copiado sin comprobar | Verificar Compatibility, buffers disponibles y convención de profundidad. |
| Optimizar solo triángulos o solo ver FPS en Mac | Medir también superficies, overdraw, sombras, animación y tribuna en un celular real. |

## 6. Preguntas pendientes para afinar la producción

1. ¿Android, iPhone, PC o web? ¿Cuál es el celular más antiguo que queremos soportar?
2. ¿Preferís30fps estables o60fps con gráficos ajustables?
3. ¿Qué captura o momento preciso de Football Strike tomamos como patrón para rostro, proporciones y uniforme?
4. ¿Cuántos jugadores animados estarán visibles a la vez, además del público?
5. ¿Cuánto presupuesto hay para assets: cero, unosUSD35 por fuentes editables, o más?
6. ¿Querés personajes ficticios y uniformes originales en toda la versión publicada?
7. ¿La personalización incluirá altura/complexión y caras, o solo nombre, número, colores y pelo?
8. ¿El código y los assets fuente serán públicos o solo se distribuirá el juego compilado?
9. ¿Qué experiencia tenés con Blender y cuánto trabajo manual querés asumir?
10. ¿Hay primeros planos de cara o solo la cámara de juego y la pantalla inicial?

Ya quedó fijado que la dirección visual buscada es similar a Football Strike: proporciones humanas, superficies suaves y materiales deportivos, sin exageración cartoon. Las otras preguntas no impiden una prueba reversible de base CC0 con comparación visual temprana.
