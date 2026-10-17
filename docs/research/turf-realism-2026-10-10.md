# Césped más realista — 10 de octubre de 2026

Aplicado en futbol-game: dos mapas originales de 1024×1024, detalle de hojas cortadas y normales de relieve, con repetición sin bordes y mipmaps. El material usa verdes menos saturados, bandas de corte más suaves, variación de color y desgaste discreto. Las texturas fueron generadas con tools/generate_turf_surface.py (numpy/Pillow); no son assets de otros juegos.

Cerca de la cámara se agregan hojas curvas en 3D de 20–35 mm, con alturas, direcciones y colores variados, y viento mínimo. Los parches reutilizan cuatro buffers y sólo se dibujan en la zona cercana. La geometría se retira suavemente a distancia y se excluye de la cal y del exterior de la cancha. Bajo usa la textura; medio usa 400 hojas/m² y alto 800 hojas/m². No se agregaron colisiones.

La malla tiene cinco vértices indexados por hoja. Se evitó discard en fragmentos: las hojas sobre la cal se colapsan en vértices para permitir descarte por profundidad antes de sombrear, especialmente al usar antialiasing.

Verificación: capturas de tiro, primer plano, defensa y menú; pruebas de geometría, reciclaje al cambiar cámara, calidad gráfica y posiciones de pelota aprobadas. Godot 4.7.1, GL Compatibility, Apple M4, 1280×720 y VSync desactivado; 90 frames de calentamiento y 300 medidos por calidad.

| Calidad | Tiro FPS promedio | Tiro p95 ms | Atajada FPS promedio | Atajada p95 ms |
| --- | ---: | ---: | ---: | ---: |
| Bajo | 338,0 | 3,88 | 199,3 | 6,42 |
| Medio | 156,3 | 7,22 | 93,8 | 11,47 |
| Alto | 118,3 | 9,30 | 83,7 | 12,79 |

La geometría adicional tiene coste: la versión anterior midió 150 FPS en tiro/alto y 95 FPS en atajada/alto. Las cifras son mediciones locales de estos escenarios. Herramienta de captura: tools/capture_stadium_upgrade.gd, vista turf_detail.
