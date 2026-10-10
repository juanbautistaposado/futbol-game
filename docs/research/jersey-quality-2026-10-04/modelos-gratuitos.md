# Camiseta de fútbol: modelos gratuitos y vías de adaptación

Investigación: 4 de octubre de 2026. Restricción: herramientas y assets gratuitos. No se descargó ningún modelo ni se incorporó contenido externo al juego.

## Recomendación

Conservar el esqueleto y las animaciones actuales. La búsqueda encontró referencias útiles, pero ningún asset verificado que pueda sustituir directamente la camiseta con nuestro rig. La vía con menor riesgo es reconstruir la silueta y los pliegues sobre la camiseta propia, usando modelos de ropa como referencia de volumen. Como alternativa, adaptar una camiseta CC0 del ecosistema MakeHuman/MPFB y transferir pesos al esqueleto actual.

## Candidatos y verificación

| Modelo / autor | Gratuidad y licencia publicadas | Formato / rig comprobables | Utilidad y limitación |
| --- | --- | --- | --- |
| [Soccer jersey — Guitomic](https://sketchfab.com/3d-models/soccer-jersey-505135b60524470493ebe08f7a8718b7) | La ficha indexada del autor muestra Download Free y CC Attribution. | 25.3k triángulos, 12.8k vértices; escaneo Polycam con retopología automática y proyección de color en Blender. No declara rig ni formato original en el texto accesible. | La referencia más específica de prenda de fútbol: examinar caída, volumen de hombros, axilas, mangas y dobladillo. Un escaneo no equivale a una prenda preparada para animar. Apertura directa devolvió 403; datos verificados mediante resultado indexado de la ficha original, sin inspeccionar archivos. |
| [elvs_crude_t-shirt_male — Elvaerwyn, Shirts01](https://static.makehumancommunity.org/assets/assetpacks/shirts01.html) | Pack descargable; esta camiseta figura CC0. | Asset de ropa MakeHuman. No se abrió el archivo ni se verificó la topología individual. | Mejor opción gratuita para partir de una malla de ropa en nuestro ecosistema MPFB. Es una camiseta genérica: todavía hay que trabajar ajuste deportivo, mangas, cuello, UV y pesos. |
| [toigo_basic_tucked_t-shirt — MargaretToigo, Shirts01](https://static.makehumancommunity.org/assets/assetpacks/shirts01.html) | CC0 publicado en el mismo pack. | Asset de ropa MakeHuman; archivo individual no inspeccionado. | Alternativa para aprender organización de prenda; su diseño metido en el pantalón no encaja con la camiseta suelta solicitada. |
| [Low Poly Soccer Player (rigged) — erik90mx](https://blendswap.com/blend/3058) | BlendSwap publica CC-BY y descarga. El índice histórico indica necesidad de iniciar sesión. | Archivo Blender 2.5x, Blender Internal, 2 MB; autor describe armature propio. No ofrece texturas según su descripción. | Referencia secundaria de silueta y deformación estilizada. Muy antiguo y sin materiales terminados; usar su rig obligaría a retargeting y no resuelve la calidad actual de tela. |
| [LAMINE YAMAL Model — Shockwave7](https://sketchfab.com/3d-models/lamine-yamal-model-69084075f1d8454a90570013b00e02cd) | Ficha original indexada: Download Free, CC Attribution. | Autor declara fully rigged; 49.1k triángulos y 29.1k vértices. Formatos y estructura de huesos no comprobados. | Referencia del conjunto de jugador vestido. No adoptar personaje/rig ni marcas o identidad del deportista para este cambio. Apertura directa 403; evidencia limitada a la ficha original indexada. |
| [Low Poly Soccer Player — PropShop, Fab](https://www.fab.com/listings/49664d36-acb5-4187-b14c-19db96ec4859) | Ficha abierta muestra Free. El campo License terms aparece «-»: licencia concreta **no verificable** en la vista accesible. | FBX publicado. Autor anuncia PBR y ready for animation, pero no demuestra huesos, clips ni su compatibilidad. | Candidato visual para comparar tela y topología; no incorporar sin verificar licencia y archivo. «Ready for animation» no prueba que esté riggeado. |

CC BY permite adaptación y uso comercial con atribución; CC0 es la opción más sencilla para contenido propio derivado. Esto no verifica por sí solo los derechos sobre marcas o identidad representadas en un personaje. La fuente de tipos de licencia es [Creative Commons](https://certificates.creativecommons.org/cccertedu/chapter/3-3-license-types/). Las fichas que sólo dicen CC-BY no permiten afirmar una versión concreta de licencia.

## Vías técnicas que conservan el rig

### A. Mejorar la camiseta propia — preferida

La malla actual se extrae del cuerpo y se ensancha; eso facilita preservar pesos, pero también conserva parte de la silueta anatómica y da una lectura de piel coloreada. Esta observación procede del generador local `apps/free-kick-3d/tools/build_footballer_v3.py`, no de los assets externos.

Propuesta de implementación artística: crear una envolvente de tela continua con pecho que atraviese suavemente la forma muscular, abdomen con mayor holgura, caída vertical hacia la cintura y pequeñas compresiones alrededor de axila y dobladillo. Mantener mangas integradas y abertura libre; la ropa deportiva necesita volumen vacío alrededor del brazo, no una copia exacta del bíceps. Resolver estos rasgos en geometría antes de añadir detalle fino de tejido. El escaneo Soccer jersey sirve como referencia de construcción y caída, sin copiar sus texturas.

### B. Adaptar camiseta CC0 MakeHuman — alternativa

MPFB permite añadir ropa desde Apply assets → Clothes. MakeClothes dispone de ajuste sobre la base hm08 y usa correspondencias con la base/helper para colocar la ropa. Las prendas siguen los huesos mediante pesos; esta arquitectura encaja con nuestra base MPFB. Fuentes oficiales: [Adding clothes](https://static.makehumancommunity.org/mpfb/docs/characters/clothes.html), [Introduction to MakeClothes](https://static.makehumancommunity.org/assets/creatingassets/makeclothes/introduction.html).

No asumir que los pesos del asset encajan sin trabajo: cargar y adaptar en pose base, conservar nuestro Armature, transferir sólo grupos de huesos existentes, normalizar y limitar influencias a cuatro. Blender documenta la transferencia de grupos de vértices y la interpolación entre superficies: [Data Transfer modifier, manual oficial](https://docs.blender.org/manual/en/3.0/modeling/modifiers/modify/data_transfer.html). Esta página es una referencia de mecanismo, no una verificación de todas las opciones de Blender 5.2.

Para ambas vías: probar Idle, Kick y Celebrate; comprobar hombro/axila/pecho/cintura, huesos y matrices de reposo idénticos, acciones sin modificaciones, materiales/paleta conservados, GLB importado en Godot y vista real a distancia de juego. No hace falta sustituir cuerpo, cabeza, pelo ni botines.

## Modelos descartados

[American Football Uniform — ds89](https://blendswap.com/blend/20659) es gratuito CC0 y Blender 2.7x, pero corresponde a fútbol americano: no usar su patrón ni volumen como camiseta de fútbol asociación. Modelos de tiendas con precio o una prueba de suscripción no satisfacen la restricción de assets gratuitos. Los agregadores que anuncian descargas sin licencia original verificable tampoco son una ruta de incorporación.

## Alcance de la evidencia

Se verificaron fichas públicas de autores y documentación oficial. No se descargaron binarios, por lo que formato original, UV, pesos, compatibilidad real y calidad de deformación permanecen sin confirmar salvo los datos explícitos de cada ficha. La recomendación de mantener y mejorar la malla propia es una decisión técnica inferida de esos límites y del generador existente.
