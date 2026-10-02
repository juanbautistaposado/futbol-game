# Agente 2 — Creación de personajes

Consulta: **2026-09-23**. Alcance: investigación, sin descargar ni modificar assets del juego. **V** = verificado en fuente primaria; **R** = recomendación/estimación propia, no benchmark probado.

## Herramientas y licencias

| Herramienta/base | Costo comprobado | Uso en juego publicado | Dificultad / calidad esperada (R) |
|---|---|---|---|
| Blender | USD 0 | Software GPL; las obras creadas no quedan obligadas a GPL. El autor puede comercializarlas. [B1] | Alta desde cero; mayor control y coherencia final. |
| Quaternius Universal Base Characters | Standard: precio libre, admite gratis. Source: USD 19.99 o más. [Q2] | CC0, admite comercial. El paquete anuncia 6 cuerpos y 20 peinados; Standard es parcial, no prometer todos gratis. [Q1][Q2] | Media: adaptar proporciones/ropa/pesos. Muy buen punto de partida para humanos estilizados. |
| Kenney Animated Characters Protagonists | Gratis, donación opcional. [K1] | CC0, comercial y sin atribución obligatoria; logo Kenney no incluido en ese permiso. [K2] | Baja para prototipo; adaptar al look futbolístico lleva trabajo. Menor parecido inicial que una base atlética. |
| Meshy | Free USD 0, Pro USD 20/mes; la ayuda actual indica que Free no descarga modelos generados (salvo creados previamente en plan pago). [M2] | Free: CC BY 4.0 con atribución; pago: propiedad del output en lo permitido por ley. Rigs/animaciones del servicio se permiten incorporados al output; materiales de entrada deben tener permisos. [M3] | Fácil generar, media/alta preparar para producción. Calidad y topología variables; no asumir listo para deformar. |

Blender y Godot forman un flujo sin suscripción; el gasto principal es trabajo artístico. Las cifras en USD no incluyen impuestos ni conversión local. Los costos de animación específicos corresponden al informe del agente 3.

## Tres pipelines completos

### A. Base CC0 + edición en Blender + animaciones reutilizables + Godot — recomendado

1. Elegir una base Quaternius disponible en Standard; comprobar el contenido antes de escoger Regular/Superhero. Source agrega fuentes .blend y el conjunto completo.
2. En Blender, modificar cabeza/hombros y crear camiseta, shorts, medias, guantes y botines originales. Mantener un mismo rig y topología compatible entre variantes.
3. UV simple o atlas, máscara de colores de uniforme; peinados modulares. Evitar piel duplicada oculta debajo de ropa.
4. Reutilizar rig humanoide y animaciones compatibles, corregir patada/atajadas y contacto en Blender. Validar poses extremas de hombro, cadera y rodilla.
5. Exportar GLB con malla, skin y animaciones horneadas; importar a Godot, configurar mapa humanoide y estados de animación; probar primero idle→patada→idle.

**V:** El pack anuncia rig humanoide, export glTF/FBX y promedio de **13.000 triángulos**. Ese dato es del pack, no de Football Strike. [Q1] **R:** conservar inicialmente el rig y medir antes de reducir; un personaje de ese tamaño puede ser razonable con solo dos protagonistas, pero no garantiza rendimiento móvil. Dificultad media, calidad previsible, costo mínimo USD 0 o USD 19.99 por Source. Primera versión jugable: **16–32 horas de trabajo**, incluyendo adaptación, animación e integración, con conocimiento básico de Blender/Godot; más aprendizaje si se empieza de cero.

### B. Blender original + rig/animación manual o retarget + GLB + Godot

Diseño propio frontal/lateral → modelado por volúmenes y loops de deformación → UV/atlas → rig humanoide y pesos → clips propios o retarget corregido → horneado → GLB → AnimationPlayer/AnimationTree → prueba de contacto/personalización.

**R:** mejor opción para identidad visual propia a largo plazo; permite decidir dónde gastar triángulos. Mayor riesgo inicial de topología y pesos. Software USD 0, dificultad alta, **40–80 horas** de trabajo para primer personaje básico con clips esenciales, excluyendo aprendizaje desde cero. Mantener un cuerpo compartido y cambiar cabeza/peinado/colores para producir siguientes personajes mucho más rápido. Exportador glTF de Blender soporta animación de huesos y shape keys; constraints/controladores deben resolverse en animación exportable. [B2]

### C. Concepto original + Meshy + limpieza Blender + rig/retarget + Godot

Concepto propio sin logos/licencias ajenas → generar candidato y seleccionar silueta → exportar GLB → Blender: revisar anatomía, retopología, UV y materiales → rig/pesos y animaciones → segundo GLB limpio → Godot y validación.

**V:** Meshy ofrece descarga GLB, FBX y Blend, entre otros. [M1] **R:** usarlo para concepto/base, no sustituir control de malla y deformación. Costo práctico de exportación desde **USD 20/mes** según plan vigente. Dificultad media/alta en limpieza; calidad variable, **20–50 horas** para convertir una salida adecuada en personaje jugable, con riesgo de descartar candidatos. Es el menos previsible para una plantilla modular con nombres, camisetas y peinados intercambiables. No recomendar como primera inversión del proyecto.

Kenney sirve como alternativa del pipeline A para probar rápidamente importación y estados; su estilo no es automáticamente el buscado y no se verificó el formato dentro del ZIP de Protagonists. No asumir GLB directo sin inspeccionarlo.

## Qué sigue sin verificar / contradicciones

- No se descargaron los packs ni se midieron deformación, huesos, materiales o FPS. “Game-ready” y compatibilidad anunciada por autor no sustituyen una prueba real.
- Meshy: la página de precios dice que no usa datos para entrenamiento sin consentimiento, pero términos del 19-09-2026 §2.9 permiten usar contenido de clientes no Enterprise. Para confidencialidad manda revisar contrato; no prometer privacidad por pagar Pro. [M1][M3]
- Meshy Help Center presenta “Private & CC BY 4.0” para pago, mientras términos §3.2 distinguen ownership pago y CC BY gratuito. No tratar todas las salidas pagas como CC BY por esa tabla. [M2][M3]
- Publicar contenido en la comunidad Meshy cambia alcance: modelos bajo CC0 e imágenes bajo CC BY-NC; no confundir la licencia de una imagen de referencia con la del modelo. [M3]
- Fuentes antiguas que permiten descargas Free Meshy-4 no reflejan la ayuda actual. [M2]
- El low-poly no equivale a flat shading: podemos tener geometría económica y normales suaves. Esto es una decisión artística recomendada.

## Fuentes primarias (fechas)

- **B1** [Blender — License](https://www.blender.org/about/license/). Sin fecha publicada; consulta 2026-09-23.
- **B2** [Blender 5.0 Manual — glTF 2.0, Animations](https://docs.blender.org/manual/id/5.0/addons/import_export/scene_gltf2.html). Manual de versión 5.0, sin fecha de edición visible; consulta 2026-09-23. Página localizada con sección técnica de animaciones en inglés. El manual /en/latest no respondió en esta consulta.
- **Q1** [Quaternius — Universal Base Characters](https://quaternius.com/packs/universalbasecharacters.html). Lanzamiento indicado: agosto 2025; consulta 2026-09-23.
- **Q2** [Quaternius — descarga oficial itch.io](https://quaternius.itch.io/universal-base-characters). Actualizado 2026-09-16, consulta 2026-09-23. Confirma Standard y Source USD 19.99.
- **K1** [Kenney — Animated Characters Protagonists](https://kenney.nl/assets/animated-characters-protagonists). Versión 1.0, 2020; consulta 2026-09-23. Fuente antigua mantenida por su autor, no tutorial actual.
- **K2** [Kenney — Support/licencias](https://kenney.nl/support). Sin fecha publicada; consulta 2026-09-23.
- **M1** [Meshy — Pricing](https://www.meshy.ai/pricing). Sin fecha publicada; consulta 2026-09-23.
- **M2** [Meshy — Which plan is right for you](https://help.meshy.ai/en/articles/12062933-which-meshy-plan-is-right-for-you-free-vs-pro-vs-premium-vs-ultra). Indica actualizado hace más de dos semanas, sin fecha exacta visible; consulta 2026-09-23.
- **M3** [Meshy — Terms of Service](https://www.meshy.ai/terms-of-use). Actualizado 2026-09-19; consulta 2026-09-23, en especial §§2.2, 2.9, 3.1–3.3. Resumen operativo de condiciones, no garantía de titularidad intelectual.
