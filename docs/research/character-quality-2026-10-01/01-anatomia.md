# Auditoría de forma, proporción y reconstrucción del personaje

Fecha: 2026-10-01. Alcance: fuentes Blender, generador, GLB y apariencia actual. Restricción del usuario: herramientas y assets gratuitos. No se modificaron modelos ni gameplay durante esta investigación.

## Conclusión

El personaje actual funciona como prototipo riggeado, pero la forma no sostiene un acabado profesional. El principal cuello de botella es la construcción de la superficie: muchos sólidos elípticos superpuestos y volúmenes genéricos sin diseño anatómico consistente. Añadir ruido de tela, aumentar segmentos o pegar más detalles faciales no resuelve la silueta ni la deformación. Recomiendo reconstruir un único personaje base, empezando por diseño y volúmenes, antes de variantes y texturas.

Esto es una valoración artística sustentada en inspección local, no un resultado demostrado por las fuentes externas ni una promesa de que un proceso automático producirá calidad profesional.

## Evidencia local comprobada

- Fuente: `source-assets/footballer/footballer_v2.blend`; generador: `apps/free-kick-3d/tools/build_original_footballer.py`.
- Render neutral de esa fuente mediante `tools/render_footballer.py`: `estado-actual-blender.png` (copia persistida del render `/tmp/footballer-anatomy-preview.png`; 640 × 800, EEVEE, cámara ortográfica, AgX). Es un render de la fuente con materiales Blender; no muestra el shader Godot y no debe confundirse con una captura del juego.
- Captura actual del juego facilitada por el agente principal: `estado-actual-godot.png` (copia persistida de `/tmp/character-research-current.png`; 1280 × 720). Confirma la lectura de mangas tubulares, cabeza ensamblada, manos simplificadas y botines bulbosos en contexto.
- `Imagen de Codex 28 sept 2026, 05_34_41 p.m..png` es una captura anterior de este mismo juego. No se usó como referencia profesional externa.
- Inspección de la fuente con Blender en modo lectura: `FootballerBody` tiene 5.792 vértices, 4.784 polígonos y **73 componentes geométricos desconectados**; `Beard` tiene 288 vértices y 3 componentes. Que piel, ropa, ojos y cabello sean superficies separadas puede ser correcto; el número por sí solo no demuestra un defecto. Lo problemático aquí son las transiciones e intersecciones visibles y cómo se combinan con pesos rígidos.
- Lectura directa del JSON GLB: delantero 10.876 triángulos, 6.080 vértices exportados, 12 materiales, 18 huesos y 0 imágenes; arquero 11.996 triángulos, 6.704 vértices exportados, 13 materiales, 18 huesos y 0 imágenes. Los vértices exportados pueden duplicarse por materiales/atributos; no se comparan uno a uno con la malla Blender.
- Blender se cerró con exit 139 dentro del sandbox. La misma operación en lectura funcionó con la ejecución escalada aprobada. No es evidencia de corrupción del modelo.

## Diagnóstico visual y causa

| Zona | Lo observado | Construcción que lo explica | Qué rehacer |
|---|---|---|---|
| Cabeza | Cráneo alto, mandíbula muy estrecha, plano frontal poco articulado y rasgos que parecen objetos pegados; peinado con borde irregular | Cabeza definida por 7 anillos elípticos, nariz/labios/párpados como elipsoides; escalado posterior de todo el grupo Head (×1,34 en X, ×1,23 en Y, ×1,14 en Z) | Cráneo, mandíbula, pómulos, plano supraorbital y cuencas como volúmenes conectados. Definir perfil nasal, párpados y labios sobre una superficie facial diseñada |
| Hombros | Mangas sobresalen como bloques o tubos grandes, sin transición convincente al torso | Torso y mangas independientes; capuchón de hombro elipsoidal; sin clavículas en rig | Silueta de trapecio/deltoides y axila, unión hombro-brazo; mangas ajustadas al cuerpo y no sustitutivas del hombro |
| Tronco | Camiseta rígida y lisa, pecho/abdomen sin planos claros; cintura con borde abultado | Camiseta principal 100% Spine; collar y algunos detalles Chest; anillos elípticos y bandas superpuestas | Volumen torácico y pelvis primero; prenda con espesor mínimo y caída creíble; distribución de pesos Hips/Spine/Chest |
| Cadera/piernas | Pantalón como dos tubos verticales; entrepierna y transición cintura-piernas artificiosas; rodillas casi sin identidad | Cada pernera es una malla cerrada asignada al muslo, cinturilla rígida aparte; piernas construidas por radios simétricos | Pelvis y entrepierna diseñadas, muslo con taper y rodilla reconocible, pantorrilla y tobillo diferenciados; tela de shorts con paneles y pliegues amplios |
| Brazos/manos | Antebrazo cilíndrico, muñeca abrupta, mano tipo mitón | Brazo de 7 anillos; pesos por altura, mano un elipsoide y pulgar otro; sin dedos separados ni articulaciones | Silueta codo/antebrazo/muñeca; palma con nudillos y dedos simplificados. Un modelo estilizado no necesita dedos hiperrealistas, sí una mano intencional |
| Botines | Volumen inflado parecido a zapatilla blanda, suela blanca ondulada y cordones pegados | Cuerpo y suela elipsoidales; cordones elipsoides; sin estructura de empeine/talón/caja de dedos | Perfil bajo de botín, talón y lengüeta, caja de dedos estrecha y suela controlada; tacos solo donde sobrevivan al tamaño real |

Los comentarios del generador que dicen “more human”, “continuous” o “sporty rather than toy-like” describen intención. El render actual demuestra que no equivalen a una validación visual.

## Riesgos de deformación deducidos del código

No se reprodujeron todas las poses en esta auditoría; los siguientes son riesgos concretos, no fallos certificados de todos los clips:

- La superficie de camiseta sigue solo Spine, mientras collar y detalles siguen Chest; al flexionar pecho puede desalinearse el cuello y detalles.
- Mangas siguen UpperArm y el torso no comparte una superficie deformable de axila; elevar brazos puede abrir huecos o producir solapes.
- Pierna de piel mezcla Thigh/Shin por altura en una franja de 0,13 m, pero la media completa sigue Shin. La apariencia de rodilla requiere comprobar esa transición en flexión extrema.
- No hay clavículas, huesos de dedos ni torsión auxiliar. Los 18 huesos permiten clips básicos, pero limitan hombros expresivos, manos de arquero y rotación suave de antebrazo. No hace falta añadir huesos sin una pose que lo justifique.
- Los elipsoides contienen filas duplicadas en los polos (un vértice por segmento en la misma posición); hace falta limpieza y control de caras degeneradas antes de retopología/exportación.
- “Join” agrupa objetos; el propio generador no ejecuta una operación de unión superficial/retopología. La inspección de conectividad confirma que las piezas siguen desconectadas.

## Qué aportan las fuentes primarias

1. **Diseño antes de malla final.** Blender Studio distingue la etapa de diseño de la entrega de una malla con topología para shading, rigging y animación. También pide pruebas de deformación y contempla UVs y limpieza. Es compatible con detener los retoques del generador y validar un nuevo volumen antes de texturizar. [Modeling, guía oficial Blender Studio](https://studio.blender.org/tools/artist-guide/asset-creation/modeling).
2. **Remesh no sustituye retopología de animación.** El manual explica que el remesh automático normalmente no da un flujo apropiado para deformación. Voxel puede ayudar a unir un blockout para esculpir; no es una entrega final riggeada. [Remeshing, Blender 5.2](https://docs.blender.org/manual/id/5.2/modeling/meshes/retopology.html).
3. **Pesos y volumen importan.** El modificador Armature vincula grupos de vértices con huesos y permite controlar su influencia; su documentación muestra la pérdida de volumen de ciertos giros y la opción Preserve Volume. Esto respalda revisar pesos y poses. No se debe asumir que marcar esa casilla en Blender se reproduce igual en el renderer del juego. [Armature Modifier, Blender 5.2](https://docs.blender.org/manual/en/5.2/modeling/modifiers/deform/armature.html).
4. **El trabajo facial y de ropa necesita etapas propias.** La formación oficial separa flujo de aristas/articulación facial, cuerpo, ropa y calzado. No se afirma aquí haber consumido todo el curso; el índice verificado muestra esas etapas y algunas lecciones gratuitas. [Clean Retopology, Blender Studio](https://studio.blender.org/training/stylized-character-workflow/chapter/5d384edea5b8f5c2c32c8507/).

Las páginas se verificaron con búsqueda web de fuentes primarias; varios intentos de `open` devolvieron 402, pero búsquedas específicas devolvieron texto completo o extractos oficiales. No se usaron como autoridad Reddit, cursos comerciales ni blogs secundarios.

## Ruta viable con herramientas gratuitas

1. **Brief de personaje.** Elegir estilización deportiva moderada con anatomía creíble, materiales simplificados y una sola identidad. No mezclar cuerpo casi realista con cabeza de muñeco ni elegir proporciones improvisando el escalado de piezas.
2. **Blockout nuevo en Blender.** Conservar tamaño en metros y una pose neutral útil; producir frente, perfil, espalda y tres cuartos con material gris. Usar referencias anatómicas observadas y un mismo objetivo de silueta. Hacer dos o tres candidatos de proporción, no variaciones de color.
3. **Gate visual antes de retopo.** Evaluar rostro/cuerpo en gris y en el juego. Si todavía parece ensamblado, volver a forma. El objetivo inmediato es una mejora grande y demostrable de volumen, no completar todos los detalles.
4. **Superficie apta para animación.** Esculpir o modelar los volúmenes finales; retopología manual en zonas articuladas. Piel, ropa, ojos, pelo y botas pueden conservar superficies separadas con transiciones controladas. Evitar un cuerpo compuesto de piezas cerradas que dependan de ocultar uniones.
5. **Rig y pesos.** Reusar nombres/contrato de clips si conviene, pero permitir clavículas y dedos básicos si las poses lo requieren. Repasar axila, pelvis, rodilla y muñeca antes de animaciones pulidas.
6. **UV y textura después.** Cero imágenes en el GLB confirma que actualmente no hay un trabajo de mapas pintados/bakeados en el asset. La tela runtime no reemplaza UVs ni normal/roughness diseñados. La estrategia de mapas corresponde al informe de materiales.
7. **Validación en Godot.** Misma escala, cámara, luz, resolución y pose que el personaje viejo. Confirmar importación, tintes y clips. Solo entonces reemplazar delantero/arquero y construir variantes.

La decisión coordinada del research es probar una base humana gratuita MPFB y adaptar el contrato mediante un adaptador. Esa ruta y su licencia se verifican en el informe de alternativas; esta auditoría no evaluó todavía un modelo MPFB concreto ni garantiza que su salida resuelva por sí sola el arte final. No forzar los 18 huesos actuales si limita la nueva base.

Conservar: integración GLB, parametrización de colores, escala y contratos de rol/animaciones cuando sean útiles. Rehacer: diseño del personaje, superficie principal de cabeza/cuerpo, uniforme, manos y botines. El generador actual puede seguir sirviendo para reproducir el prototipo; no debe condicionar la topología nueva.

## Criterios de aceptación visual evaluables

- Lámina ortográfica gris de frente/perfil/espalda y tres cuartos: cráneo/mandíbula, cuello-hombro, torso-pelvis y pierna-botín mantienen identidad consistente; no basta una única vista favorable.
- Documentar proporciones elegidas (altura en cabezas, ancho hombros/cadera, longitud extremidades) y bloquearlas; no hay un único canon universal para estilización. La línea de ojos, barbilla, clavículas, codo, muñeca y rodillas debe tener una razón de diseño y coincidir entre vistas.
- Silueta a tamaño real de menú y gameplay: atleta adulto reconocible, brazos no parecen mangas infladas, zapatos leen como botines y cabeza no parece un cilindro con accesorios.
- Cabeza en tres cuartos y perfil: nariz/pómulo/cuenca/mandíbula se leen con iluminación lateral suave; labios y cejas no parecen piezas flotantes. Pelo conserva un borde deliberado.
- Poses mínimas: neutral, brazos altos, codo 90°/130°, rodilla 90°/120°, pierna de patada y ambas manos de atajada. Sin huecos visibles, atravesamientos de tela, hombros colapsados ni cambios abruptos de volumen.
- Comparación A/B con la captura actual, a cámara/iluminación idénticas, y revisión del usuario de un solo personaje. Rechazar una mejora que dependa principalmente de luz favorable, color o zoom alejado.
- Validación técnica separada: limpieza geométrica, UVs, pesos normalizados, materiales y profiling en el juego. Un render bonito no certifica ninguna de estas condiciones.

No recomiendo fijar un nuevo presupuesto de polígonos a ciegas: el modelo ya usa cerca de 11–12 mil triángulos y aun así falla visualmente. Primero distribuir geometría donde sostiene forma y deformación, luego medir el costo real en las plataformas objetivo.
