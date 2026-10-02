# Rutas de producción del personaje: presupuesto USD 0

Investigación: 1 de octubre de 2026. Restricción del usuario: **sólo herramientas y assets gratuitos**. Se consultaron documentación y páginas de autores; no se compraron, descargaron ni importaron modelos. Las capacidades anunciadas están verificadas documentalmente; la calidad final, la compatibilidad concreta y los tiempos requieren una prueba de producción. Las recomendaciones son juicio de producción, no benchmarks.

## Decisión recomendada

**Construir un candidato en Blender usando MPFB como base anatómica, con uniforme, guantes y botines propios.** Mantener Quaternius Standard como alternativa gratuita si su contenido disponible encaja mejor con la dirección estilizada. Modelar todo desde cero sólo tiene sentido si las dos bases fallan visualmente: es la ruta que más depende de dominio artístico y repite trabajo anatómico resuelto por las otras.

El problema señalado por el usuario abarca forma y proporción; cambiar mapas o aumentar segmentos del generador actual no basta. El primer entregable debe demostrar una silueta y rostro convincentes en gris, antes de invertir en texturas y animación. MPFB reduce la necesidad de inventar anatomía con cilindros y elipsoides, pero **no genera automáticamente un futbolista con acabado profesional**: sigue haciendo falta dirección artística, ropa bien modelada, pesos corregidos y materiales preparados para Godot.

## Qué condiciona la compatibilidad actual

Lectura local: `apps/free-kick-3d/tools/build_original_footballer.py`, `kicker.gd`, `keeper.gd` y `footballer_visual.gd`.

- El generador crea piezas con anillos/elipsoides, las asigna inicialmente a un hueso y mezcla pesos en algunos miembros. El rig original tiene Root/Hips/Spine/Chest/Neck/Head y tres huesos por brazo/pierna; no hay huesos independientes de dedos.
- El juego carga `footballer_v2.glb` y `goalkeeper_v2.glb`. Depende de `FootballerRig/Skeleton3D/FootballerBody`, `Beard`, `AnimationPlayer` y huesos `Hand.L`/`Hand.R` para ubicar la pelota retenida.
- La personalización reemplaza materiales por nombres `Jersey`, `Shorts`, `Skin`, `Hair`, `Socks`, etc. Para ropa sustituye el material completo por el shader de tela actual. Importar un uniforme con buenas texturas y ejecutar ese reemplazo perdería ese material, salvo que adaptemos el shader y sus parámetros.
- Los clips esperados incluyen `Idle`, `Kick`, `Celebrate`, `Catch` y las atajadas. Un esqueleto “humanoide” externo no equivale a esos nombres, jerarquía, poses de reposo ni clips.

**Consecuencia:** ninguna ruta es un reemplazo directo de un GLB. Hay que crear un adaptador de presentación o normalizar nombres y exportación, conservar las interfaces `kick()`/`dive()` y validar contactos. Godot permite BoneMap/SkeletonProfileHumanoid y corrección de rest pose para retarget; aun así la documentación exige atender las diferencias de reposo y escala. [Retargeting oficial de Godot](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html).

## Tres rutas realizables

| Ruta | Coste obligatorio | Punto fuerte | Trabajo propio imprescindible | Riesgo principal |
|---|---:|---|---|---|
| MPFB + Blender + GLB | USD 0 | Proporciones y caras parametrizadas sobre una base humana | Estilización, uniforme, guantes/botines, materiales, integración | Acabar con un humano genérico/realista que no encaja con el juego |
| Quaternius Standard + Blender + GLB | USD 0 | Base diseñada para animación de juegos y estilo coherente | Ropa deportiva y accesorios; revisar rig/pesos y adaptar materiales | El ZIP gratuito puede no contener el cuerpo elegido; no hay fuente `.blend` garantizada |
| Blender original desde cero | USD 0 | Control de identidad, topología y licencias | Anatomía, cara, UV, ropa, rig, pesos y texturas completos | Tiempo y calidad dependen del oficio de modelado; riesgo de repetir el resultado actual |

### A. MPFB: base humana gratuita y controlable

MPFB es una extensión para Blender, requiere al menos Blender 4.2 y no necesita instalar MakeHuman. Su guía permite modificar dimensiones y rasgos con sliders, cargar piel/ojos/cabello/ropa y guardar presets; recomienda agregar el rig antes de vestir para que los assets se riggeen. [Guía oficial](https://static.makehumancommunity.org/mpfb/docs/getting_started.html).

**Licencia:** el código MPFB es GPL y MakeHuman AGPL; los assets del núcleo son CC0. Son capas distintas: usar una malla del núcleo en el juego no vuelve GPL el juego. El proyecto declara ausencia de cuotas y de funciones premium. Esto no convierte automáticamente cada asset comunitario de terceros en CC0: registrar licencia por archivo. [Licencia oficial](https://static.makehumancommunity.org/about/license.html), [FAQ de gratuidad](https://static.makehumancommunity.org/mpfb/faq/is_it_really_free.html).

**Exportación:** la documentación recomienda material `GameEngine`, basado en texturas PBR, y rig `GameEngine` como la opción más probable de funcionar fuera de Blender; no garantiza Godot. Advierte sobre geometría auxiliar y propone proxies para reducir resolución. Documenta export FBX. Podemos exportar la copia limpia a GLB usando Blender, cuyo exportador soporta skinning y shape keys. [Export MPFB](https://static.makehumancommunity.org/mpfb/docs/exporting/index.html), [glTF Blender 5.0](https://docs.blender.org/manual/id/5.0/addons/import_export/scene_gltf2.html).

`Export Copy` conserva el original editable y prepara una copia: hornea formas, aplica máscaras de piel oculta, quita helpers y gestiona subdivisión. Puede añadir shape keys faciales mediante packs adicionales. No se necesita un sistema facial completo para el primer candidato. [Export Copy](https://static.makehumancommunity.org/mpfb/docs/exporting/export_copy.html).

**Plan concreto recomendado:** adulto atlético sin exagerar musculatura; evaluar cabeza, hombros, pelvis, manos y longitud de miembros en vistas frontal/lateral/¾. Modelar camiseta y shorts sobre esa base, con cuello y bordes físicos; ocultar la piel cubierta al exportar. Crear un único par de manos y guantes de arquero adaptados sobre él, además de botines; compartir el rig entre ambos roles. Mantener un preset maestro y dos caras derivadas sin cambiar proporciones del cuerpo hasta validar animación.

MPFB incluye herramientas de creación de ropa y materiales. Su tutorial muestra extracción de una plantilla, UV/texture paint y registro en biblioteca; esto facilita reutilización pero no sustituye diseñar ropa deportiva de calidad. [Creación oficial de ropa](https://static.makehumancommunity.org/mpfb/docs/assets/creating_clothes.html).

**Límites:** no se verificó un conjunto gratuito de uniforme/botines/guantes deportivos con el acabado buscado. No asumir que una textura de piel compleja o un material procedural de Blender se verá igual en Godot. No hornear subdivisión alta por defecto: medir el GLB final vestido y usar proxy/LOD sólo con inspección de deformación.

### B. Quaternius Standard: alternativa de estilo de juego

El autor anuncia seis bases de proporciones Superhero/Regular/Teen, peinados intercambiables, rig humanoide, topología para animación, formatos FBX/glTF y promedio de 13.000 triángulos. Declara CC0 para uso personal/comercial. Son prestaciones del conjunto publicado, no prueba de cada archivo gratuito ni de rendimiento en este juego. [Página del autor](https://quaternius.com/packs/universalbasecharacters.html).

La descarga oficial lista **Standard, 122 MB, precio libre**, y **Source, 600 MB, desde USD 19,99**. La web del autor describe Standard como aproximadamente 60–70 % del pack y reserva fuentes `.blend`/integraciones completas a Source. No identifica públicamente en el listado qué bases exactas incluye Standard; por tanto, no prometer los seis cuerpos ni un Regular masculino gratuito sin inspeccionar el ZIP. Source queda descartado por presupuesto. [Distribución oficial](https://quaternius.itch.io/universal-base-characters).

**Plan:** inspeccionar Standard; si hay una base apropiada, importarla desde FBX/glTF a Blender, conservar su topología/rig y adaptar forma atlética, cara y peinado. Crear nuestro kit deportivo y probar una patada/atajada sobre la base antes de producir variantes. La importación de un formato de intercambio permite editar, pero no reconstruye todos los controles de autoría del `.blend` original.

**Límites:** una base con estética distinta puede requerir tanta intervención facial como MPFB. No trae uniforme de fútbol profesional confirmado. “Humanoid rig” no significa compatibilidad inmediata con el rig original ni animaciones deportivas disponibles. El promedio de triángulos es una referencia de contenido, no un límite artístico que debamos copiar.

### C. Blender original: control máximo, mayor riesgo

Blender permite comercializar las obras y archivos producidos; su GPL afecta al software y no impone esa licencia sobre los modelos propios. Los assets importados conservan sus licencias. [Licencia de Blender](https://www.blender.org/about/license/?wvideo=akzb57a5z3).

La ruta viable sería modelado orgánico continuo con referencias frontal/lateral, loops de cara/hombro/rodilla, UV intencional, rig de deformación y controles de autoría separados. El generador Python podría automatizar exportación, variantes o validaciones, pero no debería ser la única herramienta para diseñar anatomía. Necesitamos evaluación visual frecuente, no sólo verificar que el script termina.

**Cuándo elegirla:** si ninguna base gratuita supera el control de silueta/rostro o impide la dirección artística. El precio de software permanece cero; el trabajo manual es mayor. No dar una estimación optimista de horas sin probar primero una cabeza y una articulación: los informes anteriores estimaban tiempos generales que no demostraron el acabado exigido ahora.

## Opciones descartadas para esta fase

- **Meshy gratis:** su ayuda del 27-08-2026 indica que Free no permite descargar modelos; Pro cuesta USD 20/mes. Sus términos asignan outputs Free bajo CC BY 4.0; tener permiso comercial no habilita técnicamente una descarga inexistente. No es una ruta USD 0 verificable para integrar el personaje. No afirmar que toda IA 3D es inviable: lo que queda descartado aquí es esta oferta comprobada. [Planes oficiales](https://help.meshy.ai/en/articles/12062933-which-meshy-plan-is-right-for-you-free-vs-pro-vs-premium-vs-ultra), [términos §3.2](https://www.meshy.ai/terms-of-use).
- **Assets pagos / Character Creator:** se excluyen por la condición USD 0. CC5 anuncia Standard USD 299; además tiene requisitos Windows 10/11, mientras este proyecto se desarrolla en macOS. Comprar un software tampoco equivale a una licencia sin restricciones para todos sus componentes y personalización en juego. No propone cambiar de equipo ni adquirir licencias. [Producto oficial](https://www.reallusion.com/character-creator/), [requisitos oficiales](https://kb.reallusion.com/Product/53240/System-Requirements), [licencias de contenido](https://www.reallusion.com/license/content.html).

## Siguiente paso y criterio de elección

Hacer un candidato MPFB y, si Standard ofrece una base adecuada, uno Quaternius, con el mismo uniforme simple y la misma iluminación/cámara. Comparar en gris y luego texturizados: silueta, cara cercana, articulaciones, patada y manos juntas en atajada. Elegir **por resultado dentro de Godot**, no por render promocional.

Entregables del ganador: fuente editable, GLB limpio, texturas y máscaras originales/CC0 documentadas, rig mapeado, una patada con contacto correcto y una atajada sin pliegues rotos. Luego completar los clips/variantes y adaptar personalización para conservar detalles de textura al cambiar colores. Ningún candidato fue producido ni benchmarkeado en esta investigación; esas pruebas son el trabajo siguiente.
