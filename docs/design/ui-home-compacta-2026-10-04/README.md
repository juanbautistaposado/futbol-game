# Home compacta y precarga

Versión del 4 de octubre de 2026 posterior a la aprobación de la home raster.

- Título y botones en un único Control a escala 0,8: 20% menos de ancho y alto, con relaciones y solapes conservados. El récord mantiene tipografía nativa y tamaño legible.
- Configurar usa PNG RGBA de 2122×641, filtrado lineal con mipmaps, mediante el mismo Button de arte raster que JUGAR. Hover, foco, pulsación y callbacks conservados.
- Splash 720×401 derivado de la marca de la home, fondo ciruela y logo a tamaño original en el arranque nativo.
- Precarga web: Archivo local, logo actual, franjas azul/naranja y progreso amarillo. El texto y el progreso siguen vinculados a la carga real, incluyendo mensajes de error.
- Ícono 512² con TL crema/azul, filete amarillo y detalle naranja. Favicon ICO multirresolución y versiones PNG 16/32/48.

Assets: `apps/free-kick-3d/ui/brand/configure-raster.png`, `apps/free-kick-3d/web/{icon.png,splash.png,favicon.ico}`. Procedencia y prompts completos: `source-assets/ui/refinement-prompts.json` y `refinement-manifest.json`. Generación mediante image_gen integrado; normalización determinista conservando originales.

Capturas `1280/home.png`, `home-1920.png`, `home-960.png`: Godot Compatibility real. La prueba existente menu_flow pasa. En navegador se revisaron precarga real, home compacta, favicon enlazado y Configurar → ajustes; consola sin errores. Build web actualizado en `apps/free-kick-3d/build/web/`.
