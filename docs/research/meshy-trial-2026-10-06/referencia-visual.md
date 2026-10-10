# Objetivo visual para la prueba de Meshy

Fecha: 2026-10-06. Prueba de una base alternativa; este documento no sustituye assets de producción.

## Referencia elegida

La captura entregada por el usuario muestra dos personajes en la pantalla de personalización de Football Strike. Elegimos como referencia visual al jugador de campo a la izquierda, con camiseta blanca. El arquero amarillo sirve solamente para comprobar que la misma familia corporal admite otra indumentaria.

Archivo recibido: `/var/folders/ww/smzm844x7n1f39wjqhbg0nyc0000gq/T/codex-clipboard-d308a8a4-ed90-4ba8-9856-2695a80b35d6.png`.

La captura completa no conviene como entrada directa a Image-to-3D: contiene dos cuerpos, interfaz, brazos cruzados que ocultan pecho y axilas, iluminación verde, perspectiva y solapamientos. Recortar el jugador ayuda a quitar interfaz y arquero, pero no recupera la anatomía oculta. La ruta preferida para una primera prueba es un único personaje en pose A generado a partir de un brief explícito. Si usamos Image-to-3D, primero necesitamos una imagen aislada en esa pose, con fondo neutro y figura completa. Esa imagen sería un concepto nuevo, no una reconstrucción exacta del personaje del juego.

La [página oficial de Football Strike de Miniclip](https://www.miniclip.com/games/football-strike) aporta capturas de presentación y juego. Sus enlaces incluyen [captura de tienda 05](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_IPhone_05_EN.jpg) y [captura de tienda 01](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_iPhone_01_B_EN.jpg). No publica una altura física ni proporciones medidas del personaje; cualquier proporción del brief es una decisión artística para nuestro juego.

## Lo que se observa y lo que conviene trasladar

- **Cuerpo:** aspecto adulto atlético, hombros redondeados, pecho moderado y abdomen sin volumen de culturista. La fuerza se lee en brazos, muslos y gemelos; la camiseta no reproduce cada músculo.
- **Camiseta:** tela ligera relativamente suelta. Tiene anchura en cintura y pequeños pliegues blandos. La transición hombro–manga es continua; el borde de manga termina aproximadamente a mitad del bíceps y supera ligeramente el ancho del brazo. El cuello fino abraza la base del cuello.
- **Short:** cintura única, cadera cubierta y dos perneras que caen casi rectas hasta mitad del muslo. La entrepierna baja reduce la curva vacía en la vista frontal, sin convertir las perneras en una falda ni unir los muslos.
- **Materiales:** algodón/poliéster mate para camiseta y short, piel con brillo suave, medias claras y botines de material distinto. Los pliegues principales tienen que existir en la forma o normales; las sombras verdes del menú no deben quedar pintadas en el albedo.
- **Lectura móvil:** pocos cambios de valor grandes y una silueta limpia. Evitar ruido fino, pliegues negros profundos, contornos inflados, costuras voluminosas y detalles que solamente se ven con zoom.

No se propone copiar cara, pelo, insignias, logos o texturas del título de referencia. Tampoco se promete un resultado idéntico: se busca su claridad corporal y de indumentaria.

## Bloqueos del proyecto

Fuentes inspeccionadas: `source-assets/footballer/athlete_v3_manifest.json`, `apps/free-kick-3d/footballer_model.gd`, `footballer_visual.gd` y `tools/build_footballer_v3.py`.

| Aspecto | Decisión para la prueba |
|---|---|
| Motor/render | Godot 4.7.1, Compatibility, navegador y escritorio |
| Altura | Normalizar a 1.90 m de fuente para comparar; conservar después la escala visual actual del juego |
| Anatomía | Pecho moderado, muslos y gemelos fuertes; articulaciones y manos reconocibles |
| Pose | A simétrica, brazos unos 35° alejados del tronco hacia abajo, codos casi extendidos, dedos separados, pies paralelos a anchura de cadera |
| Cámara de concepto | Frontal casi ortográfica, sin escorzo, figura entera y ambos botines visibles |
| Fondo/luz | Gris claro uniforme, luz de estudio blanda y equilibrada, sin pedestal ni sombra dura |
| Paleta de comparación | Camiseta blanco cálido, short muy oscuro, medias claras y botines oscuros |
| Producción | Conservar paletas, rostros, pelo y botines actuales; una cara generada nueva no autoriza reemplazarlos |
| Materiales | Tela mate, piel suave; no iluminación verde incorporada a la textura |
| Rig | La generación no garantiza nuestro esqueleto de 53 huesos, sus pesos ni sus ocho clips; adaptación y verificación aparte |

La paleta de prueba aproxima el contraste blanco/oscuro de la referencia. Los colores reales de los presets continúan siendo MATEO (`#245baa`/`#172f58`), BRUNO (`#c53938`/`#252a35`) y NICOLÁS (`#ebebdf`/`#213d6e`). `footballer_visual.gd` tiñe medias y camiseta con el mismo color. Los botines actuales son oscuros; no trasladar los rojos de la captura. Una base útil tiene que permitir conservar ese sistema de colores.

## Prompt recomendado para la primera generación

Versión inglesa, descriptiva y concreta, sin depender del nombre comercial del estilo:

```text
One adult male association-football player, full body, symmetrical A-pose for character rigging. Athletic football physique: moderate chest, natural rounded shoulders, strong thighs and calves, balanced adult proportions, no bodybuilder bulk. Arms angled 35 degrees away from the torso, nearly straight elbows, open hands with separate fingers; parallel feet hip-width apart. Entire figure and both boots visible.

Warm off-white loose short-sleeve football jersey with a thin dark crew-neck trim. Smooth continuous shoulder-to-sleeve transition, no separate shoulder caps, sleeves only slightly wider than the upper arms and ending at mid-biceps. Soft shallow fabric folds, flat smooth chest, fabric draping freely around the waist. Dark charcoal football shorts with one continuous waistband, a low natural crotch and two slightly loose straight legs ending at mid-thigh. Light knee-high socks and dark football boots. Plain original kit, no club logos, no sponsors, no text.

Stylized realistic mobile-game character with clean readable forms and matte sports fabric, restrained detail, neutral skin lighting. Single isolated character facing forward, nearly orthographic view, uniform light-gray background, soft even studio light. No other people, ball, equipment, scenery, pedestal or interface. No crossed arms, action pose, exaggerated chest, giant shoulder pads, flared sleeves, high arched shorts crotch, inward-folded sleeve cuffs, clipping clothing, baked shadows or green lighting.
```

El nombre y número no conviene pedirlos a Meshy en esta primera pasada: complican el diagnóstico del albedo y la generación puede deformar texto. `PLAYER`/`10` se aplican después mediante nuestro sistema de impresión, al validar las UV. El prompt no garantiza materiales separados ni topología apta para deformar: son controles de aceptación de la malla descargada.

## Variante corta si la interfaz limita texto

```text
Single full-body adult male footballer in symmetric A-pose, balanced athletic build, moderate chest and strong thighs/calves. Loose warm-white football jersey: thin dark crew neck, smooth shoulder-to-sleeve transition, sleeves to mid-biceps, soft shallow folds and flat chest. Dark straight football shorts to mid-thigh, one continuous waistband and low natural crotch. Light knee socks, dark boots. Stylized realistic mobile-game model, matte fabric, clear silhouette. Front nearly orthographic view, isolated on light-gray background, soft neutral studio light. No logos, text, ball, other people, scenery, bodybuilder chest, flared sleeves, high crotch or clothing clipping.
```

## Orden de evaluación

1. **Antes de texturizar:** revisar frontal, espalda, perfil y tres cuartos. Rechazar torso inflado, axilas pegadas, short con arco alto, piernas fusionadas, piel atravesando ropa o manos deformadas. No gastar una descarga para una variante claramente peor.
2. **En Blender:** igualar altura, orientación y origen con la base actual; comprobar separación de perneras, normales, interior del cuello/mangas, UV y número de materiales. Un render bonito no demuestra geometría válida.
3. **En la cámara real del juego:** comparar con el personaje actual al mismo encuadre, iluminación y escala. Deben mejorar silueta de piernas, caída de camiseta y short tanto desde atrás en el pateo como desde frente en el menú. No acercar la cámara para aparentar mejora.
4. **Con movimiento:** validar Idle, Kick, Celebrate, Catch y las cuatro atajadas después de la adaptación al rig. Comprobar entrepierna y hombros durante flexión, piel a través de camiseta y short, contacto del pie y deformación de los puños de manga. No reemplazar la base de todos los jugadores hasta superar esos puntos.
5. **En presupuesto real:** comparar tamaño de GLB/texturas, superficies y rendimiento con la versión actual; los valores de referencia del manifiesto son históricos, no una medición de la generación nueva. Cualquier LOD o reducción debe conservar articulaciones, silueta y UV útiles.

Para una prueba controlada basta un único jugador. La familia de arqueros, todos los presets, caras, cabello y botines siguen usando los assets actuales hasta que una alternativa pase la comparación y la revisión técnica.

## Uso de skills

Se aplicó `.agents/skills/create-game-assets/SKILL.md`, con las referencias de dirección artística y pipeline 3D: inspeccionar el proyecto, definir un solo objetivo representativo y validar la malla en Godot antes de considerar producción. No se generaron imágenes ni se modificaron modelos en esta investigación.

## Inspección del concepto y de la primera malla

El agente principal ejecutó después una prueba. Se inspeccionaron con `view_image` estos resultados, sin modificar sus archivos:

- Concepto propio en pose A: `source-assets/footballer/meshy-trial-2026-10-06/referencia-pose-a.png`.
- Captura del preview de Meshy 6 Lite: `docs/research/meshy-trial-2026-10-06/meshy-malla.jpg`.

### Concepto

La imagen cumple la figura única, cuerpo entero, brazos separados y fondo neutro. La anatomía ofrece una base de comparación pertinente: pecho moderado, brazos atléticos, muslos presentes y gemelos fuertes. La camiseta tiene uniones suaves en el hombro y caída relativamente libre, sin marcas musculares exageradas. El short presenta cintura continua, perneras rectas y espacio frontal entre piernas bastante menor que el arco rechazado por el usuario.

Hay diferencias con la captura de Football Strike: el concepto tiene tratamiento casi fotográfico, con piel, manos, pelo y tejido mucho más detallados que el acabado del juego. El pecho permanece moderado, pero camiseta y puños se ven algo más estructurados que la tela blanda de la referencia. El borde de manga tiene una banda visible y relativamente gruesa; esto es un dobladillo externo, aunque convendría reducir su volumen para que no se lea como un aro rígido. También hay un ruedo horizontal nítido en la camiseta. Las medias muestran el volumen de canilleras, compatible con la referencia, pero habrá que comprobar que no recargue la silueta en cámara.

La cara y el pelo son nuevos y más realistas. Son parte del concepto de prueba, no una propuesta autorizada de reemplazo de la identidad de los personajes actuales.

### Malla de Meshy 6 Lite, antes de evaluar textura

En el preview gris se ve una silueta atlética contenida: el pecho no parece exagerado y la transición hombro–manga no muestra el escalón grande criticado antes. El short, las rodillas y las medias se distinguen y los brazos quedan separados del torso. Esto justifica completar la comparación, sin declarar todavía que supera al asset actual.

Los puntos que requieren atención son:

1. La generación convierte varios pliegues del concepto en relieves pronunciados, especialmente en el bajo de la camiseta y delante del short. La referencia necesita una caída más sencilla y pliegues anchos, blandos; no picos ni surcos que parezcan tela pesada.
2. El borde de manga sigue siendo visible y parece grueso. Revisar su perfil y continuidad al mover el brazo; la captura no confirma si es solamente forma externa o un anillo separado.
3. La camiseta forma una banda marcada alrededor de la cintura. Comprobar frontal, espalda y perfil para descartar un borde rígido que elimine la caída libre.
4. La imagen pequeña y de tres cuartos no demuestra que la entrepierna frontal sea suficientemente baja, que las dos perneras compartan topología adecuada, ni que las axilas sean limpias. Es obligatorio revisar esas zonas en la malla descargada.
5. Las manos se ven delgadas y sus dedos separados, pero el preview no permite comprobar uniones, grosor o topología. Tampoco prueba el estado de cara o pelo desde atrás.

La interfaz informa **101 904 caras en modo Tris y 50 944 vértices**. Esto es un dato de la captura de Meshy, pendiente de confirmar al inspeccionar la exportación. No es una base de menor coste por sí misma: el manifiesto del jugador actual registra 89 843 triángulos. UV, materiales, piel interior, esqueleto, pesos, clips y rendimiento siguen sin validarse a partir de estas dos imágenes.

Conclusión visual provisional: el experimento consigue una dirección de anatomía y ropa útil. Para aproximarse más al aspecto de Football Strike, conviene simplificar el acabado fotográfico, suavizar relieves de cintura/short y adelgazar dobladillos. La decisión de integración debe salir de una comparación en la cámara real y de la revisión de deformaciones; el render aislado todavía no basta.

## Comparación de los dos personajes dentro de Godot

Se inspeccionaron `comparacion-front.png`, `comparacion-back.png` y `comparacion-profile.png`, en esta carpeta. El personaje actual y la prueba Meshy están normalizados a la misma altura, con la misma cámara y luz. El actual utiliza los shaders del juego; el candidato utiliza su textura nueva. No son la misma textura ni una copia exacta de Football Strike.

Los ángulos de los brazos de sus poses A difieren. El actual tiene los brazos más abiertos; el candidato los deja más próximos al tronco. Esto cambia la anchura aparente de hombros, axilas y mangas, así que no permite atribuir toda diferencia de volumen a la anatomía. El candidato todavía es estático y carece del rig del proyecto.

| Zona | Observación concreta en Godot | Decisión |
|---|---|---|
| Camiseta frontal | La prueba tiene caída de tejido más creíble, manga que continúa el hombro y menos lectura de torso cilíndrico. El pecho es moderado, sin una punta central evidente. | Conservar esta dirección; suavizar pliegues fuertes del bajo y revisar holgura al mover brazos. |
| Camiseta de espalda | El tejido y el fruncido inferior aportan forma, pero el blanco muy intenso aplana parte del torso. La espalda está vacía de nombre y dorsal. | Ajustar albedo/material al blanco cálido actual y aplicar impresión mediante UV, una vez validada la malla. |
| Perfil | La camiseta del candidato sigue una línea corporal más natural y muestra pliegues en abdomen, en lugar de una pared casi recta. Su bajo está más recogido. | Mantener holgura, evitando que el bajo forme un aro apretado o una banda rígida. |
| Short frontal | La entrepierna del candidato sube visiblemente más que la del modelo actual: su hueco entre perneras llega bastante por encima de los bajos. Esto reintroduce precisamente la abertura alta que se quería corregir. | Bajar el centro de la entrepierna, mantener cintura continua y perneras rectas. No considerar este short aprobado. |
| Short de espalda/perfil | Se lee tejido y volumen de cadera con más naturalidad; los vivos laterales son claros. Eso no corrige la abertura frontal alta. | Retener silueta exterior y vivos mientras se corrige el centro; revisar cavidad interior y flexión. |
| Piernas | Rodillas y piel resultan más anatómicas en la prueba. Los gemelos son más contenidos que en el modelo actual; no se ve un aumento claro de fuerza o grosor. | No aumentar pecho. Si se busca más fuerza, ajustar muslos/gemelos de manera moderada y comprobar espacio de short/medias. |
| Cara, pelo y botines | Son distintos de los actuales y contribuyen mucho a la impresión más realista del candidato. | Excluirlos de una afirmación de mejora del cuerpo o de ropa; conservar la identidad y partes protegidas de producción durante adaptación. |

### Lectura a menor escala

La mejora que puede sobrevivir mejor en una pantalla pequeña es la silueta de camiseta/mangas, la relación torso–piernas y el contraste uniforme claro/short oscuro. Los poros, vello, detalle fino del tejido y buena parte del acabado facial se perderán al reducir el jugador; no justifican por sí mismos una malla más pesada.

Los pliegues de cintura y los vivos del short seguirán siendo visibles, pero pueden producir manchas duras si el contraste de textura es excesivo. Conviene simplificar esos relieves y evitar el blanco puro, que en esta iluminación elimina matices del pecho y la espalda. Esta evaluación de escala pequeña es una inferencia visual de las capturas de comparación; falta una captura en el encuadre móvil real para aprobar legibilidad y rendimiento.

### Conclusión y siguiente intervención

**La candidata merece una limpieza localizada y una prueba de adaptación; no merece reemplazo directo.** La camiseta presenta una mejora útil de caída y continuidad que acerca el conjunto al lenguaje del juego de referencia. El short frontal incumple todavía el requisito de entrepierna baja, y las piernas no son claramente más fuertes que las actuales.

Orden recomendado para el siguiente trabajo:

1. Corregir entrepierna y caída frontal del short; conservar altura total, cintura y silueta exterior.
2. Suavizar los pliegues fuertes de cintura, adelgazar dobladillos y revisar interior de cuello/mangas/short.
3. Reducir la intensidad del blanco y revisar si hay sombras pintadas demasiado fuertes; devolver la paleta del proyecto y dejar nombre/número para el sistema de impresión.
4. Adaptar una única versión al rig existente, con identidad y partes protegidas del personaje actual. Revisar después pateo y atajadas; el candidato estático no aporta evidencia de animación.
5. Comparar en cámara de pateo y pantalla móvil. Recién entonces decidir si conviene extender la base a los demás jugadores.

No se modificaron modelos durante esta evaluación.
