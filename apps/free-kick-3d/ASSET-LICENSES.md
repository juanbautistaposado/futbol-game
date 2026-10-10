# Registro de assets — vertical slice

| Asset | Origen | Licencia / atribución | Estado |
| --- | --- | --- | --- |
| Cancha, arcos, pelota y arqueros | Primitivas de Godot generadas por `main.gd` | Código propio del proyecto | Prototipo |
| Materiales e iluminación | Configuración de `main.gd` | Código propio del proyecto | Prototipo |

La primera entrega no distribuía modelos, texturas, animaciones ni audio de terceros. La integración v3 incorpora la base CC0 detallada abajo. Cada asset externo que sustituya a un placeholder debe añadirse a esta tabla antes de incorporarse al build.

## Personajes de fútbol

`footballer_model.gd` y `shaders/kit.gdshader`: mallas anatómicas por contornos,
rostros, cabello, barba, ropa y materiales procedurales originales del proyecto.
Sin modelos ni texturas de terceros. El arquero rotulado DONNARUMMA es una
aproximación estilizada, no un escaneo ni un modelo oficial del deportista.
Mateo, Bruno y Nicolás son personajes ficticios. Estado: prototipo visual;
no equivalen a personajes humanos fotorealistas con texturas y rig de producción.

Referencia visual de proporciones y ropa: [Football Strike: Online Soccer Android Gameplay, DroidCheat](https://www.youtube.com/watch?v=iNOT5XGohM0). Las nuevas superficies suavizadas, uniformes y articulaciones de rodillas y codos son originales; no se extrajeron assets del video ni del juego.

## Modelos originales animados (opción B)

Los archivos `source-assets/footballer/footballer_original.blend` y
`goalkeeper_original.blend`, y sus exportaciones GLB en
`apps/free-kick-3d/assets/footballer/`, fueron generados desde cero por el
script propio `tools/build_original_footballer.py` en Blender. Geometría,
materiales, rig, guantes, barba opcional y clips Idle/Kick/Celebrate/Save/Catch
son originales de este proyecto, incluidas las nuevas estiradas bajas SaveLowLeft
y SaveLowRight. No se importaron modelos, animaciones ni
texturas de Football Strike ni de librerías externas. Las capturas y el video
del juego se usaron solo como referencia de estilo.

`source-assets/footballer/footballer_v2.blend` y `goalkeeper_v2.blend`, junto
con sus GLB en `apps/free-kick-3d/assets/footballer/`, derivan exclusivamente
del generador original del proyecto. Comparten cuerpo, cara y esqueleto; el
delantero se exporta antes de añadir guantes y poses de arquero. Ambos se conservan
como respaldo; la partida normal usa v4. Los materiales procedurales del
césped, la paleta de tribunas y la iluminación de `main.gd`,
`menu_background.gd` y `stadium.gd` también son código propio del proyecto.

# Audio original

Los efectos en `audio/kick.wav`, `save.wav`, `post.wav`, `net.wav`, `crowd.wav`
y `cheer.wav` fueron sintetizados para este proyecto mediante
`tools/generate_sfx.py`; no contienen grabaciones ni muestras de terceros.
`audio/goal_voice.wav` es una voz en español generada con la voz de sistema
Eddy (Español de México) de macOS para pronunciar «¡Gooooool!».

## Señales breves de resultado

`audio/goal.wav` (0,58 s) y `audio/miss.wav` (0,38 s) son tonos originales
sintetizados por `tools/generate_sfx.py`, sin muestras ni voces externas.
Se usan para indicar gol y tiro sin gol. El juego conserva los efectos de
contacto propios y ya no reproduce `crowd.wav`, `cheer.wav` ni `goal_voice.wav`;
estos archivos anteriores permanecen como material de prototipo sin uso.

Las señales de resultado usan parciales con decaimientos separados, ataque y
salida suaves y reflexiones breves: una floritura en sol mayor para gol y un
golpe amortiguado con caída de tono para fallo. No contienen audio externo.

## Reconstrucción anatómica v3 — assets gratuitos

| Parte | Procedencia | Licencia |
| --- | --- | --- |
| Cuerpo, cabeza, topología y rig GameEngine | MPFB 2.0.17 / MakeHuman, commit `afb9f530a7c2741dedb8df0ebae2e0b183caec21` | CC0 para los datos de assets; MPFB es herramienta GPL |
| Piel, ojos low-poly y textura marrón, cejas eyebrow001 y cabello short04 | Paquete oficial `makehuman_system_assets_cc0.zip`, autor `makehuman_system` | CC0 |
| Uniforme, botines, guantes, cabello corto y barba conformados a la base | Generador propio `build_footballer_v3.py`, derivados de la geometría CC0 | Base CC0; modificaciones propias |
| Mapas de tela, briznas de barba, degradado de raíz y nombre/dorsal en UV | Generación propia y shaders del proyecto | Trabajo propio |
| Textura `hair_detail` | Adaptación neutral y reducción a 1024² de `short04_diffuse.png` | CC0 |
| Textura `skin_detail` | Adaptación neutral y reducción a 1024² de `young_lightskinned_male_diffuse.png` | CC0 |
| Clips de animación | Clips v2 originales del proyecto, adaptados al rig anatómico con IK | Trabajo propio |

La licencia de los assets se conserva en `source-assets/footballer/MPFB-CC0.txt`.
El código GPL de MPFB se usa para autoría y no se incluye en el juego.
Fuentes: [licencia oficial](https://static.makehumancommunity.org/about/license.html),
[paquete oficial](https://static.makehumancommunity.org/assets/assetpacks/makehuman_system_assets.html),
[MPFB](https://github.com/makehumancommunity/mpfb2).
Versiones, hashes y reconstrucción: `source-assets/footballer/footballer_v3.md`
y `athlete_v3_manifest.json`. No se usaron assets comerciales ni modelos extraídos de otros juegos.


## Tipografía de interfaz

`ui/fonts/Barlow-Regular.ttf`, `ui/fonts/Barlow-SemiBold.ttf` y `ui/fonts/BarlowCondensed-Bold.ttf` pertenecen a
la familia Barlow, de Jeremy Tribby. Se distribuyen bajo SIL Open Font License 1.1;
la licencia está incluida en `ui/fonts/OFL.txt`.
Procedencia: repositorio oficial Google Fonts, directorios `ofl/barlow` y
`ofl/barlowcondensed`. Se incluyen localmente para que el juego funcione sin red.

Los iconos de flecha, selección y pausa de `ui/icons/` son vectores originales del proyecto.


## Interfaz arcade — Cartel de desafío

- `ui/fonts/Bungee-Regular.ttf`: Bungee de David Jonathan Ross, distribuida bajo SIL OFL 1.1. Licencia local: `ui/fonts/bungee-OFL.txt`. Fuente: https://github.com/google/fonts/tree/main/ofl/bungee.
- `ui/fonts/Archivo-Variable.ttf`: Archivo de Omnibus-Type, SIL OFL 1.1. Licencia local: `ui/fonts/archivo-OFL.txt`. Fuente: https://github.com/google/fonts/tree/main/ofl/archivo. Los recursos `Archivo-Body.tres` y `Archivo-Emphasis.tres` seleccionan los pesos 400 y 600 sin modificar la fuente.
- La silueta de la marca, franjas diagonales, placas del HUD y SVG de botones en `ui/plates/` son gráficos originales del proyecto, construidos con vectores y código. La versión inicial era vectorial; la home actual incorpora dos PNG generados a partir del concepto propio aprobado, documentados debajo.
- Barlow permanece como recurso anterior; el tema activo usa Bungee y Archivo.


## Lettering de la propuesta — 4 de octubre de 2026

`ui/brand/wordmark.svg` y `ui/brand/play.svg` son letras originales construidas con polígonos biselados, no contornos extraídos de otra tipografía. Se conservan como SVG editables y se reconstruyen con `tools/generate_ui_wordmark.py`. La textura de impresión también es vectorial y determinista. Los nuevos SVG de ayuda, configuración, foco, pausa y flecha gruesa son gráficos originales del proyecto. Archivo-Poster y Archivo-Action usan la misma fuente OFL para textos auxiliares; las variaciones están configuradas con etiquetas OpenType numéricas.


## Arte raster de la home — 4 de octubre de 2026

`ui/brand/title-raster.png` y `ui/brand/play-raster.png` fueron generados con la herramienta integrada `image_gen`, usando como referencia el concepto original propio `docs/design/ui-concepts-2026-10-03/03-arcade.png`. No se incorporó arte extraído de otros juegos. La marca, sus textos y la placa son derivados de ese concepto; no son una tipografía distribuida.

Originales RGBA y metadatos conservados: `source-assets/ui/title-generated.png` y `play-generated.png`. Prompts completos, edición para eliminar halo/regularizar contornos y controles de importación: `source-assets/ui/prompts.json` y `manifest.json`. Normalización determinista mediante `tools/normalize_ui_raster.py`; conserva color/lettering, elimina alpha desconectado y recorta con gutter. El proceso normalizado no conserva los metadatos incrustados; los originales sí. Generación realizada con la herramienta de OpenAI; no se presenta como asset CC0 ni de terceros licenciado.

Los SVG `wordmark.svg` y `play.svg` se conservan como iteración anterior y ya no se muestran en la home. Bungee y Archivo mantienen las licencias SIL OFL indicadas arriba.


## Configurar, splash e ícono arcade — 4 de octubre de 2026

`ui/brand/configure-raster.png` y `web/icon.png` provienen de generación integrada image_gen referenciada a la marca propia aprobada. Fuentes originales: `source-assets/ui/configure-generated.png` e `icon-generated.png`; prompts y dimensiones/hashes en `refinement-prompts.json` y `refinement-manifest.json`. La normalización conserva fuentes originales y sus metadatos, recorta alpha del botón y genera tamaños de ícono con Lanczos. El splash `web/splash.png` reduce el logo ya documentado a 720×401; no agrega nueva ilustración ni texto. Archivo se copia al build web bajo la misma SIL OFL 1.1 indicada arriba.

#### Atlas de camiseta del jugador (4 de octubre de 2026)

`textures/jersey_albedo.png`, `jersey_normal.png`, `jersey_roughness.png` y las
copias extraídas del GLB son mapas originales del proyecto (512×512), creados por
`tools/tailor_footballer_jersey.py`. Fotos oficiales Nike/adidas, capturas de
Football Strike y modelos públicos fueron referencias visuales; no se incorporó
contenido de esos modelos o imágenes al runtime. Fuentes y límites de licencia
de los candidatos consultados: `docs/research/jersey-quality-2026-10-04/`.

## Uniforme Meshy v4 — 6 de octubre de 2026

La atribución de este uniforme se conserva junto a la del personaje PLAYER completo, agregado como opción adicional en la misma fecha.

`footballer_v4.glb` y `goalkeeper_v4.glb` incorporan forma y texturas de ropa
generadas con **Meshy AI (Meshy 6 Lite)**, bajo **CC BY 4.0**. Fuentes:
[Meshy AI](https://www.meshy.ai/),
[licencia CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
Referencia original, GLB descargado y procedencia:
`source-assets/footballer/meshy-trial-2026-10-06/manifest.json`.

Modificaciones del proyecto: ajuste de la ropa a la anatomía existente,
retopología sobre el uniforme v3, reducción de pliegues, conservación de cuello,
mangas y entrepierna continua, horneado y neutralización de mapas de tela para
recoloración. Los atlas derivados están en `assets/footballer/textures/meshy/`.
Se conservan el cuerpo, rostro, cabello, medias, botines, guantes y rig de la
base CC0 v3, junto a los ocho clips originales; su procedencia anterior sigue
vigente. No se importaron assets de Football Strike.

Atribución visible: **Configurar → Créditos** dentro del juego. No se compraron
créditos ni modelos; la generación consumió 20 créditos gratuitos.

## PLAYER completo — 6 de octubre de 2026

`assets/footballer/meshy_player.glb` incorpora el personaje completo generado
con **Meshy AI (Meshy 6 Lite), CC BY 4.0**: rostro, pelo, barba, cuerpo,
uniforme, medias y botines con sus atlas originales. Usa el mismo GLB fuente
y la misma procedencia del ensayo anterior; esta integración no consumió
créditos adicionales. La imagen del usuario es una referencia 2D, no un modelo
3D ni un asset extraído de Football Strike.

Adaptaciones del proyecto: altura de 1.898873 m, alineación de miembros a la
pose de reposo, soldadura de posiciones coincidentes, normales, transferencia
y ajuste de pesos, UV2 de dorsal y material de runtime. El rig compartido es
MPFB/MakeHuman CC0; las ocho animaciones originales del proyecto se conservan.
Desde el 8 de octubre, Idle/Kick modifican únicamente las rotaciones de
UpperArm, Forearm y Hand para un gesto de tiro libre. También se curva
suavemente la forma de dedos; UV, texturas y skinning conservan su procedencia.
Fuente editable: `source-assets/footballer/meshy_player.blend`.

Atribución visible: **Configurar → Créditos**. Informe y hashes:
`docs/research/meshy-trial-2026-10-06/personaje-completo.md` y
`full-player-rig.json` en el mismo directorio.

## Arquero con la base PLAYER — 9 de octubre de 2026

`assets/footballer/meshy_keeper.glb` deriva del mismo personaje PLAYER, bajo
**Meshy AI (Meshy 6 Lite), CC BY 4.0**. Mantiene rostro, pelo, cuerpo, UV0 y
atlas. Adaptaciones: separación de la camiseta para recolorear, material de
guantes y un engrosamiento de 3.5 mm en las manos. Usa el rig compartido CC0 y
las ocho animaciones exactas de `goalkeeper_v4.glb`, incluyendo su Idle propio.
No hubo generaciones ni créditos adicionales. La atribución visible sigue
en **Configurar → Créditos**. Fuente: `source-assets/footballer/meshy_keeper.blend`;
auditoría: `docs/research/meshy-keeper-2026-10-09/integration.json`.

## Base compartida para todos los delanteros — 9 de octubre de 2026

`assets/footballer/meshy_striker.glb` deriva de PLAYER completo (Meshy AI,
Meshy 6 Lite, CC BY 4.0). Mantiene exactamente geometría, normales, UV, pesos,
rig y las ocho animaciones de PLAYER; la camiseta pasa a un material separado
para conservar los colores de cada identidad. No hubo créditos adicionales.
Fuente: `source-assets/footballer/meshy_striker.blend`; informe:
`docs/research/shared-player-2026-10-09/integration.json`.
