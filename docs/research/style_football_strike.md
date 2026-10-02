# Análisis de estilo: Football Strike y estado actual del proyecto

**Fecha de investigación: 28/09/2026. Rol 1.** Objetivo: reproducir principios visuales con personajes originales, sin extraer modelos, texturas ni animaciones de Miniclip.

## 1. Estilo observable

La mejor descripción de las referencias oficiales es **realismo deportivo simplificado**, con anatomía adulta y colores fuertes. “Low-poly” puede describir nuestro presupuesto, pero no demuestra el número de polígonos original ni implica que deban verse caras planas. Es un juicio visual, no una especificación interna de Miniclip. **La instrucción vigente del usuario pide una reinterpretación más cartoon y de cabeza grande:** esa preferencia manda para nuestro personaje, aunque no describa literalmente todas las proporciones de la referencia.

- **Proporciones:** hombros atléticos, cintura más estrecha, extremidades con volumen y cabeza cercana a proporciones humanas. La perspectiva impide medir una razón exacta de cabeza/cuerpo. [Captura oficial de carrera, s/f](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_IPhone_05_EN.jpg).
- **Cara:** mandíbula, nariz, labios y cejas legibles; ojos proporcionados. Peinados y barba funcionan como masas reconocibles, no hebras individuales. [Captura oficial de personalización, s/f](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_IPhone_04_EN.jpg).
- **Sombreado:** gradientes suaves sobre piel y ropa. No se observa cel-shading fuerte como rasgo necesario. Eso no permite identificar el shader utilizado. [Carrera](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_IPhone_05_EN.jpg).
- **Ropa:** camiseta y shorts con pliegues grandes, ribetes, medias y botines; guantes distinguen al arquero. Detalle de tejido visible en las imágenes cercanas. [Carrera](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_IPhone_05_EN.jpg).
- **Paleta:** uniformes blancos/azules/amarillos, rojo/negro y verde; bloques contrastantes ayudan a identificar roles y equipo contra la cancha. No hace falta copiar escudos ni diseños exactos. [Personalización](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_IPhone_04_EN.jpg).
- **Personalización de ambos roles:** confirmada por la ficha publicada por Miniclip. Esto no demuestra que compartan malla, atlas o esqueleto. [Google Play](https://play.google.com/store/apps/details?hl=en&id=com.miniclip.footballstrike).

Las capturas promocionales fueron inspeccionadas visualmente en esta tarea de investigación; la página oficial que las enlaza fue revalidada el 28/09. No demuestran idéntica calidad en todas las plataformas.

## 2. Qué no está verificado

No hay especificaciones públicas verificadas en estas fuentes sobre triángulos originales, número de huesos, resolución de texturas, normal maps, iluminación horneada, uso de PBR o mocap. No se debe deducir un conteo de polígonos de una captura.

El [video aportado por el usuario](https://www.youtube.com/watch?v=iNOT5XGohM0) es una referencia secundaria de gameplay; su fecha editorial no fue verificada. En la sesión previa se observaron atajadas y caídas; no se ha vuelto a inspeccionar cuadro a cuadro el 28/09. No atribuyo duraciones de clips, técnicas ni un catálogo exhaustivo al juego.

**Propuesta de animación propia:** anticipación, apoyo del pie, armado y seguimiento del disparo; estirada con extensión y caída; recuperación; celebración de torso y brazos. Expresividad por pose y ritmo, conservando contacto físico creíble. No es un inventario oficial de Football Strike.

## 3. Estado real del repositorio

Verificación de archivos locales el 28/09/2026. El proyecto **ya tiene personajes originales GLB generados en Blender**, con malla skinned, Skeleton3D y AnimationPlayer. No corresponde seguir describiéndolo como personajes formados únicamente por piezas Node3D y Tween.

| Archivo | Triángulos almacenados | Meshes / primitivas | Materiales | Huesos de la skin | Texturas en GLB |
|---|---:|---:|---:|---:|---:|
| `assets/footballer/footballer_original.glb` | 8.072 | 2 / 10 | 9 | 18 | 0 |
| `assets/footballer/goalkeeper_original.glb` | 8.624 | 2 / 11 | 10 | 18 | 0 |

**Método:** leer chunk JSON de cada GLB; sumar `accessor.count / 3` de índices de primitivas con modo TRIANGLES. Incluye la barba opcional y todas las primitivas almacenadas. No equivale a geometría visible de cada configuración, a draw calls, a FPS ni a coste de sombras. No se midió rendimiento en celular en este análisis.

El delantero incluye `Idle`, `Kick`, `Celebrate`. El arquero incluye además `Catch`, `SaveLeft`, `SaveRight`, `SaveLowLeft`, `SaveLowRight`. Confirmado en JSON de GLB y uso de AnimationPlayer en `kicker.gd`/`keeper.gd`.

`footballer_visual.gd` ya duplica/asigna materiales por avatar y personaliza Jersey, Shorts, Skin, Hair y Socks; `footballer_fabric.gdshader` aporta tela procedural. Los GLB no contienen texturas: no confundir eso con que no existe detalle de material en Godot.

El generador `tools/build_original_footballer.py` construye geometría, rig y clips; `ASSET-LICENSES.md` registra su autoría original. Las fuentes editables `.blend` están documentadas en `source-assets/footballer/`. El dato previo de **38.200 triángulos/65 piezas** describe una versión anterior y no es la referencia actual.

## 4. Recomendación accionable

**Continuar los GLB originales existentes y llevarlos a la reinterpretación cartoon solicitada**, sin reiniciar la creación del personaje. El presupuesto actual ya es compatible con una dirección de geometría moderada; el mayor salto visual debe venir de proporciones, cara, ropa y animación, no de aumentar subdivisiones indiscriminadamente. Conservar de Football Strike los colores, la ropa y la legibilidad, mientras se exagera deliberadamente cabeza y expresividad.

1. Renderizar frente, perfil y espalda con luz neutra, luego con la cámara real. Comparar dos variantes propias de cabeza más grande y anatomía simplificada; elegir por silueta, sin presentarlas como proporciones oficiales de Football Strike.
2. Pulir transición hombro/brazo y rodilla, y verificar deformación en golpe y estirada extrema. Las imágenes estáticas no garantizan buen skinning.
3. Crear un atlas original con pliegues amplios y detalles de uniforme: **1024² como punto de partida propuesto**, no dato de Miniclip. Conservar máscaras para colores independientes y región para nombre/dorsal.
4. Evaluar consolidar las **10–11 primitivas** actuales a unas **2–4 superficies**, manteniendo personalización y barba opcional. Es objetivo de optimización, sujeto a coste y medición.
5. Mejorar poses clave y contacto pie–pelota antes de agregar más clips. Comparar los movimientos en contexto, no solo en Blender.
6. Mantener materiales mate y probar sombreado suave frente a toon suave. Un contorno puede apoyar nuestra reinterpretación cartoon, pero no es un rasgo verificado que debamos copiar de la referencia.

**Criterio de aprobación:** silueta humana legible desde cámara de juego, rostro convincente en menú, camiseta sin atravesamientos y contacto correcto al patear/atajar. Falta inspección visual nueva del render actual para señalar defectos concretos; el código y los conteos no bastan para afirmar calidad estética final.

## 5. Fuentes y fechas

| Fuente | Publicación / actualización | Consulta | Alcance |
|---|---|---|---|
| [Football Strike — Miniclip](https://www.miniclip.com/games/football-strike) | s/f | 28/09/2026 | Página primaria y enlace de capturas. |
| [Captura oficial de carrera](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_IPhone_05_EN.jpg) | s/f | Inspección visual previa; enlace revalidado28/09 | Proporciones, cara, tejido. |
| [Captura oficial de personalización](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_IPhone_04_EN.jpg) | s/f | Inspección visual previa; enlace revalidado28/09 | Peinados, uniforme y roles. |
| [Google Play, Miniclip](https://play.google.com/store/apps/details?hl=en&id=com.miniclip.footballstrike) | App actualizada12/08/2026 según ficha | 28/09/2026 | Personalización confirmada; no fechar capturas con la fecha de app. |
| [Video del usuario](https://www.youtube.com/watch?v=iNOT5XGohM0) | No verificada | Observación en sesión previa | Gameplay secundario; no evidencia técnica interna. |
| Archivos del repositorio enumerados arriba | Estado del checkout | 28/09/2026 | Datos propios medidos, no datos de Miniclip. |

No se descargaron ni incorporaron assets de Miniclip. Investigación de estilo, sin cambios al código del juego.
