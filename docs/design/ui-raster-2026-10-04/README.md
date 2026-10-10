# Home raster y contornos suaves

Implementación de la dirección 03, revisada el 4 de octubre de 2026.

- `home.png`: captura real final de Godot Compatibility a 1280×720.
- `home-960.png` / `home-1920.png`: lectura y contornos a 960×540 y Full HD.
- `wide/home.png`: viewport panorámico completo a 1600×720 con aspecto expand.
- `4x3/home.png`: 1280×960; la franja derecha reduce su ancho para dejar visible la pelota.
- `match.png`: HUD con placas, ayuda, pausa y medidor suavizados.
- `states/`: hover y pulsación de JUGAR, preparación, medidor activo y bloqueado.
- `alpha-preview.png`: assets transparentes sobre damero; el damero no forma parte de los PNG del juego.

La marca y la placa JUGAR incorporan lettering raster de alta resolución, generado desde el concepto aprobado. Sus originales, prompts de generación/corrección y manifiesto están en `source-assets/ui/`. El título integra su respaldo ciruela y filete amarillo; JUGAR integra placa, letras, flecha y sombra. Los estados se dibujan sobre un Button que conserva su texto semántico y callback.

Se evaluaron SVG con más resolución, MSAA y PNG. Compatibility no tiene MSAA 2D: se usan PNG para la gráfica de marca y máscaras de polígonos supersampleadas para franjas/placas. El filtro y los mipmaps evitan dientes al reducir. Configurar, ayuda y pausa conservan texto nativo sobre SVG a 4×, sin nine-slicing que deforme las diagonales.

La home ancla el cartel a la izquierda. `window/stretch/aspect="expand"` elimina las barras que el motor añadía fuera del viewport capturado; las franjas llegan a los límites de la ventana. Se verifican también los anclajes del HUD a 1600×720 y 1280×960.

Pruebas existentes: menu_flow y shot_and_keeper pasan. Navegación de pausa por teclado comprobada. La exportación Web local se regeneró y se probó en navegador a 1280×720: home, JUGAR, preparación y partido, sin errores de scripts en consola. El build actualizado está en `apps/free-kick-3d/build/web/`; no se publicó externamente.

La escena 3D sigue siendo la del juego. La reconstrucción del cartel mejora lettering y contornos, pero no se declara una copia idéntica píxel por píxel de la propuesta.
