# Mejora visual aplicada — 13 de octubre de 2026

## Resultado

- Cielo procedural con nubes, iluminación ambiental/reflejos desde ese cielo,
  sol cálido, ligera perspectiva atmosférica y cascadas de sombra concentradas.
- Césped con una paleta compartida entre suelo y hojas, bandas que responden
  al ángulo de cámara, desgaste coherente y distribución más uniforme. Se conserva
  el presupuesto de hojas existente y los niveles bajo/medio/alto.
- Camiseta y short con menor contaminación oscura del atlas y detalles de tejido
  filtrados; piel, tela y látex con distinta rugosidad. Dorsal/editor preservados.
- Público con paleta de ropa moderada y sombreado real, en lugar de tarjetas
  luminosas sin iluminación. Se conserva su sistema de instancias y LOD.
- Hormigón y chapa con variación y juntas; asientos menos saturados; banquillos,
  cámaras de televisión y una franja de servicio fuera del campo, sin colisiones.
- Pelota con juntas hundidas, micrograno filtrado y reflejos más mates.
- Calidad alta incorpora oclusión ambiental de pantalla y resplandor sutil;
  medio/bajo los desactivan. Las cámaras de juego y las animaciones no se editaron.

Capturas del motor real: [partido](after-attack.png), [estadio](after-overview.png),
[césped](after-turf.png), [camiseta](after-shirt.png), [jugador](hero.png),
[cielo](venue.png), [pelota](ball.png). `hero/venue/ball` usan cámaras de inspección;
`after-attack` es la cámara normal del partido. No son conceptos generados.

## Investigación

Se usaron las skills router, create-game-assets, research, godot-3d-essentials,
godot-shaders, godot-gdscript, performance-optimization y godot-export.
Se buscaron fuentes primarias en la web y se contrastaron con Godot 4.7.1 local:

- [Renderers Godot](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html):
  mantener Compatibility para web; SSAO/glow sí están disponibles en esta versión,
  a diferencia de versiones antiguas. No activar efectos exclusivos de Forward+.
- [Environment](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html):
  iluminación de cielo, exposición, niebla y posprocesado.
- [Materiales PBR](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html):
  rugosidad, normales, metalicidad y alfa recortado.
- [GPU Gems, césped](https://developer.nvidia.com/gpugems/gpugems/part-i-natural-effects/chapter-7-rendering-countless-blades-waving-grass):
  vegetación instanciada con detalle dependiente de distancia.

Más detalles y fuentes en `lighting.md`, `turf.md` y `character.md`.
Se iniciaron tres agentes nuevos de los cinco solicitados; los tres alcanzaron
el límite de uso. El coordinador completó su integración y las áreas de
estadio/validación. No se afirma haber completado trabajo con cinco agentes.

## Validación

Aprobadas: graphics_quality_test, pitch_grass_test, stadium_geometry_test,
crowd_geometry_test (render nativo), character_editor_test (nativo),
stadium_visual_test y animation_flow_test. La prueba del público falla con el
renderizador dummy porque devuelve transforms identidad; pasó sin cambios con
el renderizador real. Los GLB siguen pasando la auditoría de esqueleto, clips,
geometría/UV/pesos protegidos. `git diff --check` sin errores.

Exportación Web release local completa. Se abrió en el navegador integrado,
entró al partido, se pateó, registró un gol y avanzó al segundo intento. La
consola no mostró errores ni advertencias en esa prueba. No se publicó ni se
hizo commit/push de este trabajo.

## Costo y límites

Prueba nativa de desarrollo a 1280×720, calidad alta, Apple M4. No es benchmark
release web/móvil; hubo otras operaciones locales y hay ruido de medición.

| Métrica | Antes | Después |
|---|---:|---:|
| Media por fotograma | 5,48 ms | 8,82 ms |
| p95 por fotograma | 7,64 ms | 10,09 ms |
| Draw calls | 355 | 397 |
| Triángulos renderizados | 1.172.842 | 1.198.863 |
| Memoria de texturas | 147,1 MiB | 158,8 MiB |

La mejora añade costo, principalmente nuevos efectos y superficies iluminadas;
no se presenta como optimización de FPS ni diagnóstico aislado CPU/GPU. Para
hardware más lento se conservan perfiles medio/bajo. Las texturas procedurales
no agregan descargas de imágenes. El tamaño de exportación incluye todas las
otras tareas presentes en el workspace (145 MiB), no sólo esta mejora.

El modelo y las siluetas del público siguen siendo la base existente. El nivel
de EA FC de las referencias exigiría además personajes/topología/UV específicos,
ropa simulada y pelo detallado, fuera de esta pasada y del trabajo de animación
que el usuario asignó a otro chat. La dirección implementada es más natural y
coherente, sin afirmar equivalencia AAA.
