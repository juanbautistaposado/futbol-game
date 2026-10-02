# Agente 5 — Look visual en Godot

Consulta y revisión: **2026-09-23–24**. Contexto leído: `00-contexto-local.md`, Godot 4.7.1, renderer Compatibility. **V**: verificado en documentación/código; **R**: recomendación artística o ingeniería, sin prueba GPU en este trabajo.

## Dirección recomendada (R)

Adoptar **realismo deportivo simplificado** conforme a la corrección del usuario del 24/09/2026: anatomía humana, normales suaves, variación sutil de piel/tela, pliegues visibles e iluminación de estadio. Mantener contraste de uniforme contra césped. Evitar bandas duras de dos tonos, contornos negros y brillos de plástico; alejarían el resultado de la referencia.

Orden práctico: primero malla y pesos; luego paleta/materiales; iluminación; finalmente comparar ajustes de materiales y luz contra las capturas oficiales. Un shader no corrige rodillas, hombros o camisetas que atraviesan el cuerpo.

## Materiales, luces y post

- **R:** comenzar con StandardMaterial3D opaco, metallic 0, roughness 0.65–0.9 para piel/tela, normal map sutil o ausente. Ojos/botines pueden variar sin agregar numerosos materiales. Colores principales y secundarios mediante máscara, sin hornear sombras direccionales en albedo.
- **V:** Godot permite `diffuse_toon` y `specular_toon`; no es necesario instalar un plugin para experimentar. Un `light()` personalizado no corre con `vertex_lighting` o Force Vertex Shading habilitado. Verificar ese ajuste al exportar a celular. [G1]
- **R:** no implementar una rampa toon para este objetivo. Si se prueba como experimento, evaluar si preserva volumen de cara y ropa frente a la referencia antes de integrarla.
- **R:** una luz direccional principal, ambiente moderado y cielo simple; sombras legibles bajo pies. Reducir luces con sombra antes de agregar efectos. Mantener exposición estable y comprobar rojo/azul/verde en cámara de partido y en menú.
- **V:** el sol/ambiente de vista previa del editor no aparece automáticamente al ejecutar; crear DirectionalLight3D y WorldEnvironment. El cielo también afecta iluminación ambiental/reflejos. [G2]
- **V:** en la documentación 4.7, Compatibility tiene glow con implementación y opciones reducidas. Desde Godot 4.6 tiene **SSAO simplificado**, diferente del de Forward+, con solo radio e intensidad configurables; Mobile no dispone de SSAO. SSR y SDFGI son Forward+. No repetir listas de limitaciones de 4.0 como si fueran actuales. [G2]
- **R:** mantener glow muy leve o apagado durante tiros, sin profundidad de campo que dificulte leer arquero/pelota. No depender de SSAO para el estilo: AO horneado leve o vértices bien coloreados son alternativas. Medir cualquier post en el teléfono objetivo; esta investigación no demuestra FPS.

## Dos ejemplos libres, con código y licencia del autor

| Ejemplo | Costo y permiso | Integración / calidad esperada (R) |
|---|---|---|
| [eldskald — Godot 4 Complete Cel Shader](https://github.com/eldskald/godot4-cel-shader) | Gratis; [LICENSE MIT](https://github.com/eldskald/godot4-cel-shader/blob/main/LICENSE), copyright Rafael de Lima Bordoni. Uso comercial del **código** permitido conservando aviso/licencia. Changelog: 2025-10-08. | Dificultad media. Rampa de difusión, opciones de material y [outline por geometría](https://github.com/eldskald/godot4-cel-shader/blob/main/src/outline.gdshader). Copiar `src` completo e includes, definir globals y recurso de rampa. Ejemplo técnico de sombreado alternativo; no recomendado para el look pedido. No se probó aquí en Compatibility 4.7. |
| [EMBYRDEV — godot-toon-outline](https://github.com/EMBYRDEV/godot-toon-outline) | Gratis; [LICENSE MIT](https://github.com/EMBYRDEV/godot-toon-outline/blob/main/LICENSE), copyright 2023 Hannah Crawford. Comercial permitido conservando avisos. Autor declara probado en 4.0.3; sin fecha exacta de último cambio visible. | Dificultad alta por port. [Código](https://github.com/EMBYRDEV/godot-toon-outline/blob/main/post_process_outline.gdshader) útil para estudiar contornos por profundidad/normales; **no pegar tal cual** en este proyecto. Más costo por pantalla y artefactos potenciales; no recomendado para primera versión móvil. |

**V, eldskald:** el contorno usa `cull_front`, expansión de posición proyectada y `next_pass`; no necesita normal-roughness del screen buffer. La licencia cubre código; no extender automáticamente el permiso a cualquier asset/imagen de demostración. **R:** contorno estrecho o ninguno; otra pasada agrega trabajo por cada superficie. Con las 65 superficies actuales del personaje sería particularmente conveniente simplificar primero la malla. Coste final depende de renderizado real.

**V, EMBYRDEV:** código aún contiene `POSITION = vec4(VERTEX, 1.0)`, opción `SUPPORT_MOBILE` y dos rutas de normales: una usa `hint_normal_roughness_texture`, ausente en Compatibility; la otra reconstruye normales desde profundidad, pero no se ha validado en este renderer. La reconstrucción de NDC también requiere revisión. README indica prueba en Godot 4.0.3 y advierte problemas con TAA. **R:** tratarlo como referencia de algoritmo, no solución validada para Godot 4.7 Compatibility.

## Trampas de renderer y versión

1. **V:** `hint_normal_roughness_texture` solamente está disponible en Forward+; no en Mobile ni Compatibility. Outlines dependientes de ese buffer no funcionan allí sin otra técnica. [G3]
2. **V:** desde Godot 4.3, el ejemplo oficial de pantalla completa usa `POSITION = vec4(VERTEX.xy, 1.0, 1.0)` por reverse-Z. Tutorials antiguos pueden ubicar el quad incorrectamente. [G4]
3. **V:** reconstruir profundidad con `INV_PROJECTION_MATRIX`; Compatibility usa NDC z entre -1 y 1, mientras Forward+/Mobile usa 0 a 1. Usar rama `CURRENT_RENDERER == RENDERER_COMPATIBILITY`, no asumir que el mismo cálculo sirve en ambos. [G4]
4. **V:** la textura de pantalla 3D se copia antes de transparentes; éstos no aparecen en ella. Esto afecta outlines/post con pelo transparente/redes. [G3]
5. **R:** si en el futuro se solicita contorno, probar inverted hull/next pass opaco sobre malla simplificada; revisar normales partidas, articulaciones, grosor y sombras. No incorporarlo al estilo actual.
6. **R:** comparar en 720p/1080p y teléfono real: lectura del nombre, balón blanco, rostro, color del equipo, estabilidad al mover cámara, frame time GPU. Elegir calidad mediante resultados medidos; “toon” no garantiza que sea más rápido que PBR sencillo.

## Fuentes primarias y fechas

- **G1** [Godot 4.7 — Spatial shaders](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/spatial_shader.html). Manual de versión 4.7, sin fecha editorial; consulta 2026-09-23.
- **G2** [Godot 4.7 — Environment and post-processing](https://docs.godotengine.org/en/4.7/tutorials/3d/environment_and_post_processing.html). Sin fecha editorial; consulta y revisión 2026-09-23–24.
- **G3** [Godot 4.7 — Screen-reading shaders](https://docs.godotengine.org/en/4.7/tutorials/shaders/screen-reading_shaders.html). Sin fecha editorial; consulta 2026-09-23.
- **G4** [Godot 4.7 — Advanced post-processing](https://docs.godotengine.org/en/4.7/tutorials/shaders/advanced_postprocessing.html). Sin fecha editorial; consulta 2026-09-23.
- [Godot 4.7 — Overview of renderers](https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html). Sin fecha editorial; consulta 2026-09-23.
- Repositorios, código y archivos LICENSE enlazados en tabla: consultados 2026-09-23. Ejemplos inspeccionados como código, **no ejecutados ni integrados**.
