# Interfaz de Tiros Libres 3D

Dirección activa elegida por el usuario: **03 — Cartel de desafío**, aplicada el 3 de octubre de 2026. La selección sustituye la propuesta inicial de Crónica de potrero.

## Identidad

Marca TIROS LIBRES y placa JUGAR con PNG transparentes de alta resolución derivados de la propuesta aprobada; Bungee para encabezados, turnos y cifras; Archivo 400 para lectura y Archivo 600 para controles y marcador. Las fuentes están incluidas localmente con SIL OFL 1.1. La marca TIROS LIBRES combina dos líneas, tinta ciruela, letras crema/azul y un corte de cartel con filete amarillo. El estadio y los personajes 3D siguen siendo la imagen principal.

| Rol | Color |
| --- | --- |
| Tinta / fondo | `#211A2B` |
| Texto crema | `#FFF2D0` |
| Navegación y turno | `#3456E8` |
| Acción principal | `#F05B3F` |
| Energía / foco / puntuación | `#F5D547` |
| Precisión correcta / gol | `#62C58D` |
| Superficie secundaria | `#30253C` |
| Texto secundario | `#CBBFD3` |

Acción naranja con tinta oscura: contraste 5,03:1. Crema sobre azul: 5,18:1. Texto secundario sobre superficie: 8,20:1. El estado pulsado usa naranja `#EA543C` para conservar contraste. La selección combina color y check; el foco usa un contorno amarillo, incluido en botones recortados.

## Composición

- Inicio: marca original en cartel, franjas diagonales azul/naranja, JUGAR rasterizado con letras y flecha de la propuesta y Configurar como acción tipográfica secundaria. El récord es un dato separado. Se eliminó el eslogan genérico.
- Selección y personalización: la misma gráfica en los márgenes con jugador visible. Los controles mantienen tamaño estable al seleccionarse.
- Ajustes: fondo opaco de tinta, grupos legibles y detalles diagonales en los extremos. La animación de la escena no interfiere con la lectura.
- Preparación: cifras grandes y placas recortadas; acciones y rangos conservan su funcionamiento.
- HUD: placa de marcador recortada, puntuación amarilla, turno en banda azul, medidor con marco diagonal, barra rojo/amarillo/verde e instrucciones crema sobre tinta oscura. La cámara y los blancos 3D se mantienen.
- Pausa y resultados: tipografía y paleta arcade, foco visible; los resultados largos envuelven el texto y mantienen sus márgenes.

## Implementación

`apps/free-kick-3d/ui/visual_theme.gd` centraliza fuentes, colores, estados y estilos. `ui/poster_mark.gd` muestra la marca rasterizada y `ui/poster_panel.gd` las placas. `ui/plates/` contiene los SVG originales de acción, hover y pulsación. La marca y JUGAR son arte raster; los números, nombres y demás controles conservan texto nativo. `ui/raster_action.gd` conserva Button, nombre JUGAR, foco, hover, pulsación y callback. `ui/smooth_polygon.gd` rasteriza las franjas y placas estáticas con cobertura suave y mipmaps, sin cambiar el renderer.

El menú escala desde una composición de 1024×640. El proyecto usa canvas_items con referencia 1280×720. Se revisaron capturas reales de inicio, ajustes, preparación, selección, editor, partido, pausa, gol, resultado largo, muerte súbita y cuatro jugadores; se verificó además una ventana de 960×540.

Esc conserva el regreso del editor al selector, del selector a ajustes y de ajustes al inicio. Durante el partido abre/cierra pausa. El rediseño no cambia reglas, físicas, input, guardado ni timing del remate.

Pasaron las pruebas existentes: menu_flow, round_flow, graphics_quality, custom_players y shot_and_keeper. Los tests headless emiten avisos conocidos del renderer dummy y certificados del sandbox; las capturas OpenGL no presentaron errores de scripts.

Capturas actuales: `docs/design/ui-raster-2026-10-04/`. Las carpetas anteriores documentan iteraciones reemplazadas.

```sh
godot --path apps/free-kick-3d --script res://tools/preview_ui.gd -- home,settings,setup,keeper,custom,match,pause,long,result,winner,multi /tmp/tiros-ui 1280 720
```

Impeccable y Brandkit están instaladas como herramientas de diseño del proyecto. La dirección surgió de las propuestas en `docs/design/ui-concepts-2026-10-03/` y la investigación en `docs/research/direccion-arte-ui-2026-10-03.md`.


## Iteración vectorial reemplazada — 4 de octubre de 2026

La home y el HUD se revisaron por separado contra `docs/design/ui-concepts-2026-10-03/03-arcade.png`. La primera implementación solo trasladaba la paleta: la segunda pasada trasladó su composición, pero el usuario señaló diferencias en lettering, serruchado y margen izquierdo. La iteración raster siguiente sustituye la marca y JUGAR de esa pasada.

- Home: lettering angular vectorial original en `ui/brand/wordmark.svg`, dos líneas crema/azul sin contorno crema, corte escalonado, textura de impresión y filete amarillo. JUGAR usa el mismo lenguaje en `ui/brand/play.svg`; conserva su nombre semántico y callbacks como Button. Configurar aparece en placa crema, el récord destaca la cifra en amarillo, y el encuadre del jugador se ajusta solo en la home. Los selectores recuperan su cámara previa.
- HUD: nombres crema, cifras amarillas, marcador compacto y turno separado en azul. Las instrucciones del remate quedan en una placa corta a la izquierda y el medidor a la derecha, con blanco circular y borde naranja. Durante la defensa la ayuda se expande para conservar las instrucciones de control. Los datos de récord siguen en la home; el marcador de cuatro personas y nombres largos ajusta su texto al espacio disponible.
- Las variaciones de Archivo usan las etiquetas OpenType numéricas para seleccionar sus pesos de forma efectiva en Godot. Referencia: [FontVariation](https://docs.godotengine.org/en/stable/classes/class_fontvariation.html). Las imágenes de la propuesta no se incorporaron como interfaz rasterizada.
- La marca y el rótulo se pueden reconstruir con `python3 apps/free-kick-3d/tools/generate_ui_wordmark.py` desde cualquier directorio.

Validación: capturas reales a 1280×720 y 960×540; revisión de medidor inactivo, carga y tiro bloqueado, nombres largos, muerte súbita, cuatro jugadores, selección y pausa. Pasaron menu_flow, round_flow y shot_and_keeper. Capturas de esta pasada en `docs/design/ui-propuesta-fiel-2026-10-04/`.


## Corrección raster y bordes — 4 de octubre de 2026

- `ui/brand/title-raster.png`: 1512×842 RGBA; letras TIROS/LIBRES, respaldo ciruela y filete amarillo en una textura transparente. `ui/brand/play-raster.png`: 2132×573 RGBA; placa naranja, JUGAR, flecha y sombra. Se generan desde la dirección 03, con una edición posterior para quitar halo y corregir el perímetro.
- Importación lossless, alpha-border fix, mipmaps y filtrado lineal. Originales conservados en `source-assets/ui/`, junto a prompts, hashes, dimensiones y procedencia. El recorte normalizado elimina puntos exteriores desconectados, preserva antialias y añade cuatro píxeles de gutter.
- La home ancla el bloque a x=0. Las franjas usan coordenadas del viewport completo. El aspecto `expand` elimina las barras automáticas del motor al cambiar proporciones. Ajustes y preparación mantienen su composición centrada.
- Los polígonos de home, placas HUD y medidor usan máscaras rasterizadas a 4×, reducidas a 2× y con mipmaps. Se limpian al redimensionar, sin crecimiento continuo de caché.
- Configurar conserva Archivo nativa sobre placa SVG importada a 4×, estirada completa para evitar deformación por nine-slicing.
- Se inspeccionan capturas reales en 960×540, 1280×720, 1920×1080, 1600×720 y 1280×960; además estados hover, pulsación, partida, carga y tiro bloqueado. menu_flow y shot_and_keeper pasan. No se cambian reglas ni física.

Se mantiene la escena 3D real. Los PNG reproducen el cartel de la propuesta; no se afirma identidad píxel por píxel con la imagen generada.


## Home compacta, precarga e ícono — 4 de octubre de 2026

El usuario aprobó la versión raster y pidió reducir el peso del título y JUGAR en pantalla completa. `HomePoster` agrupa título y los dos botones con escala 0,8 y desplazamiento vertical de 80 unidades; mantiene proporciones y solapes. El récord queda fuera del grupo para conservar tamaño de letra. La placa de respaldo inferior se adapta a la posición nueva.

Configurar usa `ui/brand/configure-raster.png` (2122×641 RGBA), generado desde la marca aprobada; `raster_action.gd` admite arte y caption, manteniendo Button, callback, hover, pulsación y foco visible para ambos controles.

La precarga usa la misma marca de la home en `web/splash.png` (720×401); el shell usa Archivo local, fondo ciruela, franjas azul/naranja y progreso amarillo. El ícono `web/icon.png` (512²) usa un monograma TL crema/azul, con filete amarillo y esquina naranja; también se producen favicon.ico y variantes 16/32/48. Las fuentes y prompts se conservan en `source-assets/ui/refinement-*`.

El splash nativo usa el tamaño original en vez de ampliarse a toda la ventana; configuración documentada en [ProjectSettings de Godot](https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html#class-projectsettings-property-application-boot-splash-stretch-mode).

El exportador termina la importación con `--quit` y copia Archivo y favicon al build. La exportación local fue regenerada. Validación nativa a 960×540, 1280×720 y 1920×1080; validación web de precarga real, logo, enlaces de iconos, home y Configurar → ajustes sin errores de consola. menu_flow pasa. Capturas actuales: `docs/design/ui-home-compacta-2026-10-04/`.

## Configuración sin márgenes exteriores — 4 de octubre de 2026

Las formas de selección y personalización se extienden hasta los límites reales
del viewport, conservando la inclinación del panel y las franjas izquierdas. La
decoración derecha sigue el margen derecho y el inferior; en ajustes y preparación
las esquinas también siguen el viewport. Los controles mantienen su composición
centrada, con la misma escala y navegación.

Se verificaron las seis pantallas en 1920×984 y 1280×960. `menu_flow` pasa y la
exportación web release termina correctamente. Capturas en
`docs/design/ui-config-bordes-2026-10-04/`.
