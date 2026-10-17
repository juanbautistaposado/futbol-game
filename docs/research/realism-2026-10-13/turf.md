# Césped natural de estadio — 13 de octubre de 2026

## Marco

Godot 4.7.1, renderer Compatibility, cámara de partido y primeros planos. Se conserva el campo de 105 × 68 m, la cal, las texturas originales de 1 m con mipmaps y filtro anisotrópico, los cuatro patrones MultiMesh y los presupuestos existentes. Recursos gratuitos; no se descargan ni generan nuevas imágenes en esta revisión.

## Investigación y decisiones

- La [guía oficial DFL de mantenimiento de césped](https://media.dfl.de/sites/3/2022/06/EN_DFL_Broschuere_Greenkeeping_Stadionrasen_Ansichts_PDF.pdf) describe corte uniforme y bandas transversales a las líneas de gol. La dirección visual será un césped corto y cuidado, con desgaste localizado; no hierba silvestre ni barro extendido.
- [GPU Gems: césped instanciado](https://developer.nvidia.com/gpugems/gpugems/part-i-natural-effects/chapter-7-rendering-countless-blades-waving-grass) combina planos/geometría de hierba y movimiento agrupado para cubrir terreno sin monopolizar la GPU. Se conserva geometría opaca curva y movimiento milimétrico; no se aumenta la cantidad de hojas.
- [GPU Gems: vegetación de Crysis](https://developer.nvidia.com/gpugems/gpugems3/part-iii-rendering/chapter-16-vegetation-procedural-animation-and-shading-crysis) distingue el movimiento general del detalle de hojas y usa variación por instancia. Aquí interesa su coherencia espacial de sombreado y movimiento, con amplitud adecuada a césped de fútbol.
- [Godot: rendimiento 3D](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html) recomienda MultiMesh para hierba y evitar grandes superficies transparentes. Se mantienen parches pequeños reciclados, culling, opacidad y reducción de geometría mediante escala a distancia.
- [Godot: antialiasing 3D](https://docs.godotengine.org/en/stable/tutorials/3d/3d_antialiasing.html) distingue aliasing geométrico, de texturas y especular. El detalle fino se filtra por derivadas de pantalla y se conserva una rugosidad alta; no se pretende resolver brillo o ruido subpíxel aumentando polígonos.
- [Godot: renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html) documenta diferencias entre Compatibility y Forward+. Esta mejora se implementa con shaders espaciales, derivadas y MultiMesh disponibles en el renderer existente, sin buffers de normales ni efectos exclusivos de Forward+.

## Implementación aplicada

Compartir paleta, variación, bandas y desgaste entre el plano y las hojas. Dar a las bandas una respuesta suave al ángulo de observación (interpretación visual de las hojas inclinadas por el corte). Repartir las coronas de hojas con una secuencia progresiva más uniforme, conservando las densidades de cada preset. Rebajar las hojas sobre las áreas de mayor tránsito para que el césped tridimensional siga el desgaste del suelo.

## Validación

Capturas `after-attack.png`, `after-overview.png` y `after-turf.png`. Pruebas de geometría de césped, presets y reciclaje aprobadas; exportación web y tiro completo en navegador comprobados. El coordinador completó la integración tras agotarse el límite de los agentes.
