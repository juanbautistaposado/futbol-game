# Migración de personajes: tres caminos para un principiante

Investigación e inspección local: **28 de septiembre de 2026**. Fuentes primarias; precios en USD antes de impuestos. Separación: **verificado** significa leído en código/documentación del proveedor; **estimado** significa juicio de producción sin benchmark ni prueba del asset.

## Punto de partida real

El proyecto **ya usa GLB originales con Skeleton3D y AnimationPlayer**: `assets/footballer/footballer_original.glb` y `goalkeeper_original.glb`. Sus fuentes Blender y generador se registran en `ASSET-LICENSES.md`; hay clips Idle/Kick/Celebrate/Save/Catch y variantes de atajada baja. No estamos migrando desde muñecos exclusivamente procedurales.

`kicker.gd` y `keeper.gd` esperan rutas `FootballerRig/Skeleton3D/FootballerBody`, una malla `Beard`, un `AnimationPlayer` y nombres de clips concretos. `footballer_visual.gd` personaliza materiales llamados `Jersey`, `Shorts`, `Skin`, `Hair`, `Socks`. **Cambiar el GLB por cualquier descarga rompería estos contratos si no se adapta.** Esto se verificó leyendo esos archivos, sin modificar código.

**Recomendación:** mejorar primero un delantero existente en Blender y mantener su rig, nombres y materiales. Usar una base CC0 como comparación o alternativa solo si la anatomía/topología actual impide lograr el resultado. Una suscripción IA no es necesaria para avanzar.

## Comparativa

| Pipeline completo | Costo y permiso verificado | Dificultad y resultado estimados | Trabajo activo estimado |
|---|---|---|---|
| **1. Blender incremental, recomendado:** fuente actual → mejorar silueta/topología/UV → conservar rig y clips → corregir pesos y patada → GLB → misma escena de Godot → comparar en partido | Blender gratis; GPL del programa no obliga a publicar el arte bajo GPL. Obras propias utilizables comercialmente. [B] | Media, control alto y menos riesgo de romper personalización. No garantiza perfección: depende de la calidad del rig y del trabajo artístico. | **12–24 h** para primer pase visual validado; sumar **8–16 h** de aprendizaje básico si nunca usó Blender. |
| **2. Base CC0:** Quaternius → ropa/cabeza propias en Blender → retarget o rehacer clips esenciales → normalizar nombres/materiales → GLB → adaptador de personaje en Godot → QA | Standard admite USD 0; Source USD **19.99** o más, CC0 comercial. Standard es parcial; no todos los cuerpos/peinados se prometen gratis. [Q] | Media; anatomía más previsible que generación IA, pero hay trabajo de integración. El rig anunciado como humanoide no significa compatible automáticamente con nuestros nombres/eventos. | **20–40 h**, más aprendizaje. |
| **3. IA + edición:** concepto propio → Meshy → descargar candidato → retopología/UV/rig en Blender → clips y contacto → GLB limpio → integrar y validar | Meshy Pro **USD 20/mes**. La ayuda actual dice Free sin descarga de modelos nuevos; salidas free CC BY 4.0, pago ownership sujeto a ley y condiciones. [M][T] | Fácil obtener una forma, media/alta llevarla a producción. Calidad variable; dedos/ropa/pesos y piezas modulares requieren inspección. | **24–56 h** tras candidato útil, más aprendizaje; puede requerir descartar generaciones. |

Estas horas son **estimaciones de una persona**, no plazos prometidos ni cifras del proveedor. Incluyen un personaje con movimientos esenciales y validación, no un catálogo de avatares. Modelar desde cero en Blender sería una variante más lenta del pipeline 1: aproximadamente 40–80 h con experiencia básica, más aprendizaje, sin beneficio claro antes de evaluar las fuentes existentes.

## Pasos del camino recomendado

1. **2–3 h:** abrir copia de `source-assets/footballer/footballer_original.blend`; revisar silueta frontal/lateral y poses extremas. Mantener una versión base para comparación.
2. **3–6 h:** mejorar cabeza, cuello, hombros, manos, caderas y rodillas; corregir zonas de ropa que atraviesen piel. No aumentar subdivisión global para ocultar anatomía deficiente.
3. **2–4 h:** simplificar materiales y ajustar UV/paleta. Preservar nombres de materiales usados por la personalización, incluido número/nombre de camiseta en el flujo del juego.
4. **2–5 h:** revisar pesos en sentadilla, brazo elevado y patada; ajustar clips conservando el evento lógico de contacto con pelota. No confundir retarget automático con contacto correcto.
5. **1–2 h:** exportar GLB de prueba a una ruta nueva, comprobar Skeleton3D, AnimationPlayer, nombres, escala y orientación en escena aislada.
6. **2–4 h:** validar menú y partido: nombre/número, colores independientes, barba, patada, celebración y encuadre. Tras aprobación visual, repetir mejoras comunes para arquero y sus guantes/atajadas.

**Criterio para abandonar la base actual:** después de un ensayo acotado de 3–4 h, si arreglar hombros/caderas exige reconstruir toda la malla y los pesos, comparar con Quaternius antes de invertir más. Es una recomendación de gestión, no una deficiencia demostrada del GLB actual.

## Formato y entrega

Godot recomienda **glTF 2.0**, incluido GLB. La importación directa `.blend` llama Blender para convertir a glTF; entregar GLB evita exigir Blender a cada entorno de ejecución/importación. OBJ no conserva esqueleto ni animación. [G] Mantener `.blend` como fuente editable fuera de los recursos importados, como ya hace el proyecto; entregar GLB, texturas y registro de licencia/procedencia.

Para cualquier base externa: conservar licencia exacta en el repositorio, registrar URL/fecha y mantener un archivo original sin tocar. Luego hacer un pase de poses y clips antes de reemplazar el personaje activo. El nombre comercial de una licencia no prueba que una imagen de referencia o logo incluido tenga los mismos derechos.

## Condiciones y dudas verificadas

- **Quaternius:** el autor anuncia promedio **13.000 triángulos** para Universal Base Characters, rig humanoide y glTF/FBX. No es la cifra de Football Strike, ni prueba de FPS en celular. Source incluye fuentes; Standard no equivale al pack completo. [Q]
- **Kenney:** assets de sus páginas son CC0, comercial y sin atribución obligatoria; su logo no está incluido. Es alternativa para prototipo, no una sustitución visual garantizada. No se inspeccionó un ZIP de personaje concreto en esta investigación. [K]
- **Meshy:** términos §3.2 separan outputs gratuitos CC BY de propiedad pagada; la tabla de planes simplifica la columna como “Private & CC BY 4.0”. Priorizar condiciones completas, no interpretar todos los outputs pagos como CC BY. §3.3 distingue modelos comunitarios CC0 de imágenes comunitarias CC BY-NC; estas últimas no habilitan uso comercial indiscriminado. Los inputs deben tener permisos. [T]
- **No probado:** no se compraron servicios, descargaron packs ni validaron sus rigs en este proyecto. Dificultad, horas y calidad son estimaciones explícitas.

## Fuentes y fecha

- **[B]** [Blender — License](https://www.blender.org/about/license/). Sin fecha de actualización visible; consulta 2026-09-28. Permiso del software y obras. La apertura directa falló; contenido verificado por índice de búsqueda del sitio oficial y [FAQ oficial](https://www.blender.org/support/faq/).
- **[Q]** [Quaternius — Universal Base Characters](https://quaternius.itch.io/universal-base-characters), actualizado **2026-09-16**; [ficha del autor](https://quaternius.com/packs/universalbasecharacters.html), lanzamiento agosto 2025. Ambas consultadas 2026-09-28; precio Standard/Source, licencia y formatos.
- **[M]** [Meshy — comparación oficial de planes](https://help.meshy.ai/en/articles/12062933-which-meshy-plan-is-right-for-you-free-vs-pro-vs-premium-vs-ultra). Dice actualizado hace más de un mes, sin fecha exacta; consulta 2026-09-28. Pro USD 20/mes, Free sin nuevas descargas.
- **[T]** [Meshy — Terms of Service](https://www.meshy.ai/terms-of-use). Actualizado **2026-09-19**; consulta 2026-09-28. §§2.2, 3.1–3.3.
- **[G]** [Godot — Available 3D formats](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html). Documentación estable, sin fecha editorial; consulta 2026-09-28.
- **[K]** [Kenney — Support](https://kenney.nl/support). Sin fecha editorial; consulta 2026-09-28.
