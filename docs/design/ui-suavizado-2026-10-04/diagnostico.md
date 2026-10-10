# Suavizado de las diagonales de la home

La captura `ui-propuesta-fiel-2026-10-04/home.png` muestra escalones en los
polígonos diagonales del marco y del cartel. La referencia `03-arcade.png` tiene
transiciones suaves de cobertura en esos contornos. Aumentar el MSAA 3D no corrige
el dibujo 2D: son pasos de render independientes.

El proyecto usa Godot 4.7.1 y `gl_compatibility`. En ese renderizador no hay MSAA 2D.
`draw_colored_polygon()` tampoco tiene parámetro `antialiased`. Las líneas,
polilíneas y círculos sí ofrecen suavizado propio, pero no los rellenos poligonales.

El SVG importado como `Texture2D` tampoco permanece vectorial durante el juego.
`wordmark.svg.import` y `play.svg.import` usan `svg/scale=1.0`, sin mipmaps. En la
captura 1280×720, el diseño lógico 1024×640 se escala por 1.125: también se amplían
esas texturas rasterizadas. La calidad del logo necesita resolverse por separado
con rasterización de mayor resolución o `DPITexture`.

## Solución implementada

`apps/free-kick-3d/ui/smooth_polygon.gd` mantiene la geometría y los colores que
recibe el `_draw()`. Rasteriza una máscara SVG blanca con cuatro muestras lineales
por unidad lógica; la reduce a una textura de dos píxeles por unidad y genera
mipmaps. La máscara se conserva en el helper y se tiñe al dibujar, así los estados
de color no regeneran texturas. La caché sólo se genera en el primer dibujo de cada
geometría. Debe conservarse como miembro del Control que dibuja.

```gdscript
const SmoothPolygon = preload("res://ui/smooth_polygon.gd")
var smooth_polygons := SmoothPolygon.new()

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func _draw() -> void:
    smooth_polygons.draw(self, points, color)
```

El helper sirve para las pocas formas estáticas del marco y el cartel. No está
destinado a vértices animados: cada geometría nueva conservaría otra textura.
`clear()` libera las máscaras cuando cambia la geometría; se llama fuera de
`_draw()`, antes de solicitar el siguiente dibujo. Los controles `poster_panel.gd`
y `shot_meter.gd` lo conectan a `resized`, conservando sólo la geometría actual.
El consumo aproximado por máscara es `ancho × alto × 16 × 4/3` bytes, incluyendo
mipmaps. Por ejemplo, una diagonal en un rectángulo lógico de 325×640 ocupa cerca
de 4.5 MB. No añade una pasada de pantalla completa ni cambia el renderizador.

## Verificación

- Parseo con `godot --headless --check-only --script ui/smooth_polygon.gd`: correcto.
- Render real con Godot 4.7.1, OpenGL Compatibility, Apple M4, ventana 1280×720.
- `diagonales-comparacion.png`: izquierda, `draw_colored_polygon()`; derecha,
  helper, con las mismas coordenadas, colores y escala 1.07. Las pendientes
  superficiales, pronunciadas y el recorte cóncavo quedan suavizados.
- Se verificó sólo la ruta nativa. La API SVG existe en las compilaciones estándar
  de Godot; el export web requiere conservar su módulo SVG, habilitado por defecto.
- Capturas reales del HUD en `hud/match.png`, `hud/charge.png` y `hud/locked.png`:
  paneles y medidor suavizados en reposo, carga y tiro bloqueado; cursor, potencia,
  texto y dimensiones conservados.

## Fuentes primarias

- [Godot: 2D antialiasing](https://docs.godotengine.org/en/latest/tutorials/2d/2d_antialiasing.html)
- [Godot: CanvasItem](https://docs.godotengine.org/en/4.6/classes/class_canvasitem.html)
- [Godot: importing images](https://docs.godotengine.org/en/latest/tutorials/assets_pipeline/importing_images.html)
- [Godot: Image](https://docs.godotengine.org/en/stable/classes/class_image.html)
