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
- Selección: la misma gráfica en los márgenes con jugador visible. Los controles mantienen tamaño estable al seleccionarse.
- Personalización: editor de estudio inspirado en FC 26, con categorías arriba,
  catálogo a la izquierda y el nuevo jugador 3D a la derecha. Comparte la
  dirección Cartel de desafío del inicio: Bungee y Archivo, ciruela y crema,
  navegación azul, placas naranjas y foco amarillo; franjas suaves hasta los bordes.
- Ajustes: fondo opaco de tinta, grupos legibles y detalles diagonales en los extremos. La animación de la escena no interfiere con la lectura.
- Preparación: JUGAR abre una fila de tres portadas ilustradas — Individual,
  Duelo local y Ronda local — con títulos nativos sobre placas inclinadas.
  La opción aplicada lleva placa naranja, marco amarillo y check; debajo quedan
  los contadores de tiros y jugadores, el resumen, VOLVER y EMPEZAR. El estadio
  oscurecido queda detrás sin avatar y las diagonales alcanzan el viewport.
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

## Editor de jugador inspirado en FC 26 — 10 de octubre de 2026

La nueva dirección solicitada afecta la personalización del delantero y del
arquero. Se inspeccionó por segmentos el video de modo carrera de
[Vance Studios](https://www.youtube.com/watch?v=qRYtlUU4OQs), especialmente rostro
a 2:45 y equipación a 8:17. Las referencias y capturas están en
`docs/research/editor-fc26-2026-10-10.md`.

`ui/character_editor.gd` separa Identidad, Aspecto e Indumentaria, con
subcategorías y muestras de color. Archivo reemplaza Bungee en esta pantalla;
carbón, blanco y verde distinguen navegación, foco y opción aplicada. Nombre,
dorsal, piel, cabello, barba, camiseta y short son opciones funcionales. El
selector de color libre comparte el tema del editor. L1/R1 y PgUp/PgDn cambian
categoría; Esc y Listo vuelven a la selección.

El nuevo PLAYER Meshy es el modelo de personalización de ambos roles. Las máscaras
UV permiten modificar piel, pelo, short y barba del atlas sin reemplazar el GLB
ni las animaciones. La camiseta conserva su material separado; las áreas
residuales del arquero siguen el mismo color. Nombre y dorsal permanecen en la
espalda. La barba cambia mediante textura, sin modificar la geometría de la cara;
medias y botines conservan su aspecto original. La opción PLAYER conserva el atlas
original. Cada rol guarda su identidad y colores por separado.

`menu_background.gd` oculta el estadio durante la edición y presenta un estudio
con iluminación y fondo continuo. Identidad/Indumentaria muestran el cuerpo
entero; Aspecto acerca la cámara al rostro. El giro se conserva al modificar un
color. Al salir se restauran estadio y cámara del menú. Los fondos de interfaz
alcanzan los bordes del viewport mientras los controles mantienen su escala.

Validación: capturas nativas a 1280×720 y 960×540; exportación web release y prueba
en navegador integrado de configuración, personalización, cambio real de piel,
zoom y giro, sin errores de consola. Pasaron `character_editor_test`,
`custom_players_test`, `meshy_player_test`, `athlete_v3_test` y `menu_flow_test`.
Capturas en `docs/design/editor-fc26-2026-10-10/`. El build local está actualizado;
esta iteración no se publicó en Netlify.

## Piel y vello facial — 11 de octubre de 2026

Aspecto incorpora **Vello facial** con opciones independientes para barba/bigote
y cejas. Las máscaras anteriores excluían parte del bigote junto con los labios
y parte de las cejas junto con los ojos; además, las fibras de vello permanecían
en el mapa de normales. Las regiones nuevas restauran piel sin esas fibras al
desactivar cada opción y protegen ojos y labios. Delantero y arquero guardan
las cejas por separado; los perfiles anteriores mantienen cejas por defecto.

La paleta de piel pasa de seis a nueve tonos, con más pasos intermedios. El
shader reduce la reflectancia de piel bajo las luces reales: la frente del tono
medio antes saturaba el canal rojo en toda el área medida; ahora conserva
detalle. Se mantienen selección de color libre, modelo, rig y animaciones.

Validación: `character_editor_test` y `custom_players_test`; cobertura UV real de
bigote, barba y cejas para ambos GLB, con ojos/labios protegidos; capturas GPU con
nueve tonos distintos y cambios visibles e independientes del vello facial.
Se comprobaron controles a 1280×720 y 960×540 y se regeneró el build web local.
Evidencia en `docs/design/editor-appearance-2026-10-11/`.

```sh
godot --path apps/free-kick-3d --script tools/preview_appearance.gd -- /tmp/appearance
python3 apps/free-kick-3d/tools/check_appearance_renders.py /tmp/appearance
python3 apps/free-kick-3d/tools/check_meshy_facial_masks.py
```

Las verificaciones Python requieren Pillow y NumPy. Esta corrección está
disponible en la vista local; no se publicó en Netlify.

La revisión posterior corrige también los párpados y los bordes de la boca:
la protección del ojo sigue la abertura real, conservando el iris, y el párpado
inferior pasa de 1,3 % a 100 % de cobertura de piel en los puntos de prueba de
ambos modelos. Los labios usan la piel elegida con un matiz rosado moderado;
el borde mezcla ambos pigmentos personalizados y no conserva el atlas claro.
La máscara facial añade el pigmento labial en su canal alpha. Las pruebas
comparan tonos claros y oscuros y comprueban que los labios también respondan.
Capturas actualizadas en la subcarpeta `features/`.

Por pedido del usuario se elimina la opción de ocultar cejas. Aspecto muestra
Piel, Cabello y Barba; las cejas permanecen visibles y siguen el color del
cabello incluso cuando un guardado anterior tenía `eyebrows=false`. Se conservan
los controles de barba/bigote y la corrección de color en párpados y labios.


## Editor integrado a Cartel de desafío — 11 de octubre de 2026

Por pedido del usuario, el editor recupera la identidad de la propuesta aprobada
`docs/design/ui-concepts-2026-10-03/03-arcade.png`. Sustituye la excepción visual
carbón/blanco/verde de la iteración de FC 26. Conserva las categorías, el catálogo
y la vista 3D de esa implementación.

Bungee se aplica a TU DELANTERO/TU ARQUERO, títulos de campos y LISTO. Archivo 400
se usa para lectura y Archivo 600 para controles. Los estilos reutilizan fuentes,
paleta y texturas de placas de `visual_theme.gd`: crema sobre ciruela, pestaña
azul, opción aplicada y acción final naranjas, selección/foco amarillo. Las
placas compactas escalan su textura completa para conservar el corte y el
espacio del texto. La decoración diagonal se dibuja con las mismas máscaras
suavizadas de la home y alcanza los bordes reales en pantallas anchas.

Se mantiene el estudio 3D y su iluminación para conservar los tonos de piel
ya corregidos. Nombre, dorsal, colores por rol, barba, cámara, giro y regreso
permanecen funcionales. Las cejas siguen siempre visibles.

Validación: character_editor y menu_flow pasan sin errores de scripts. Se revisan
Identidad, Aspecto, Barba e Indumentaria a 1280×720 y 960×540, y el marco a
1920×984. La exportación web local se actualiza y se verifica en el navegador.
Capturas: `docs/design/editor-poster-2026-10-11/`.

## Selección ilustrada de modos — 12 de octubre de 2026

Al pulsar JUGAR, la preparación presenta tres portadas siguiendo la composición
de la referencia de Rocket League aportada por el usuario y la identidad vigente
Cartel de desafío. Hereda paleta y tipografía: Bungee para JUGAR, títulos de modo
y EMPEZAR; Archivo para descripciones, ajustes y VOLVER. Los rótulos son texto
nativo, separado del arte. La fila usa HBoxContainer dentro de la composición
centrada de 1024×640; el estadio queda oscurecido, sin delantero ni arquero de
vista previa, y las diagonales se extienden hasta los bordes reales.

- **Individual:** una persona tira y ataja contra la IA.
- **Duelo local:** dos personas tiran por turnos en el mismo dispositivo.
- **Ronda local:** tres o cuatro personas tiran por turnos; la portada propone
  cuatro y el contador permite ajustar a tres.

Las portadas aplican los presets de 1, 2 o 4 participantes. El contador de
jugadores admite 1–4 y sincroniza la portada activa; tiros conserva el rango
5–15. El resumen muestra tiros y atajadas con muerte súbita para Individual,
y tiros por persona y remates totales para partidas locales. EMPEZAR inicia y
guarda la configuración; VOLVER o Esc regresan al inicio. Cada portada es un
Button con selección naranja y check amarillo, hover azul y marco amarillo
para selección o foco; el recorrido de foco enlaza portadas, contadores y
acciones. La implementación está en `menu.gd` (`show_setup`, `select_play_mode`,
`refresh_setup`) y `ui/play_mode_card.gd`.

`ui/play-modes/individual.png`, `duel.png` y `group.png` son ilustraciones
originales generadas con Imagegen integrado a 1536×1024, importadas lossless
con mipmaps y filtrado lineal. El encuadre recorta conservando proporciones.
Prompts finales, edición de Ronda, hashes y procedencia están en
`source-assets/ui/play-modes/`; los tres PNG conservan su prompt incrustado.

Validación nativa: siete capturas a 1280×720, 960×540 y 1920×984 en
`docs/design/play-menu-2026-10-12/`. El reviewer independiente devolvió
`disposition: ship`, sin recortes ni solapes en las capturas inspeccionadas.
`play_modes_test.gd` y `menu_flow_test.gd` pasan sin SCRIPT ERROR; sus logs
conservan avisos de certificados del sandbox y materiales del renderer dummy.
El export web local terminó correctamente. En el navegador integrado a 1280×720
se verificaron JUGAR, los tres presets, los contadores y Tab/Enter; la consola
no registró errores ni advertencias. Evidencia: `docs/design/play-menu-2026-10-12/web-play-menu.jpg`.
Esta iteración no se publicó.

El detector de patrones HTML/CSS no aplica a esta interfaz nativa Godot. El
contrato de esta pantalla y el detalle de validación están en
`docs/design/play-menu-2026-10-12/brief.md`.

## Ajuste: duelo único contra el bot — 12 de octubre de 2026

JUGAR ofrece únicamente UNO CONTRA UNO contra el bot. Conserva la portada
Individual y la estética de Cartel de desafío: Bungee, Archivo, ciruela,
naranja, azul y amarillo. La composición presenta una portada a la izquierda
y las reglas a la derecha. Se eliminan las opciones locales y los contadores.
EMPEZAR tiene el foco inicial; VOLVER y Esc regresan a la home.

La partida tiene cinco remates por lado, alternando ataque y defensa. Sólo si
las cinco parejas terminan empatadas continúa con una pareja extra por vez
hasta desempatar. Menu y Main ignoran los valores antiguos de tiros y jugadores
al cargar un perfil; EMPEZAR guarda cinco tiros y un participante humano.

Validación: play_modes_test, round_flow_test y menu_flow_test pasan. El test de
ronda verifica cinco parejas sin desempate, empate inicial, empate en la primera
pareja extra y final después de que ambos lados rematen en la siguiente pareja.

Verificado en navegador integrado a 1280×720: una sola opción, reglas de cinco
tiros visibles y ningún contador para aumentarlas. Consola sin errores ni
advertencias. Captura: `docs/design/play-menu-2026-10-12/web-bot-five-shots.jpg`.
Export web local actualizado; no se realizó publicación remota.

## Apartado Personaje — 12 de octubre de 2026

La home presenta JUGAR, PERSONAJE y Configurar, en ese orden. PERSONAJE usa una
placa crema con Bungee y bordes suavizados, encima de Configurar. El récord se
reubica debajo de ambas acciones sin cambiar la escala del título ni de JUGAR.

PERSONAJE reúne Elegir delantero y Elegir arquero. Sus listas y editores
conservan la personalización actual. VOLVER y Esc regresan desde cada lista a
PERSONAJE, y desde PERSONAJE a la home con foco en su botón. Configurar contiene
sólo dificultad, gráficos, volumen y créditos. La navegación con teclado
enlaza las tres acciones de inicio. menu_flow_test verifica estas rutas y la
ausencia de selección de personajes dentro de Configurar.

Validado en Godot y navegador integrado a 1280×720. La prueba de navegación
pasó; en web se confirmó Personaje sobre Configurar, acceso al arquero y
regreso con Esc a Personaje y a la home. Consola sin errores ni advertencias.
Capturas: `docs/design/character-section-2026-10-12/web-home.jpg` y
`web-characters.jpg` en el mismo directorio. Export web local actualizado.

El ajuste posterior del usuario pide el estilo previo del botón Configurar
también para Personaje. Su placa ahora es `ui/brand/personaje-raster.png`,
generada con image_gen a partir de Configurar: tipografía atlética inclinada,
mayúscula inicial, placa crema y sombra ciruela. Usa el mismo RasterAction y
las mismas dimensiones que Configurar. Fuente y prompt preservados en
`source-assets/ui/character-button/`; la navegación permanece intacta.

Botón raster verificado en Godot y navegador integrado a 1280×720.
menu_flow_test: PASS. Consola web sin errores ni advertencias. Captura final:
`docs/design/character-section-2026-10-12/web-home-matched-style.jpg`.

Los accesos Elegir delantero y Elegir arquero ahora comparten estilo secundario
ciruela y tamaño 330×54 (antes 390×70), con texto y flecha sin recortes.
Verificado en Godot y web a 1280×720: `docs/design/character-section-2026-10-12/web-compact-buttons.jpg`.

La home compacta Jugar, Personaje y Configurar con 2 unidades de separación
entre sus zonas de clic. Jugar ocupa 514×130; las placas secundarias 378×56.
El récord acompaña el bloque a y=576. Verificado en Godot y web a 1280×720:
`docs/design/character-section-2026-10-12/web-home-tight-actions.jpg`.

El segundo ajuste pega visualmente las placas: Personaje en y=464 y Configurar
en y=506, sin volver a reducir su tamaño. Los rectángulos transparentes se
solapan; RasterAction usa una máscara alpha precalculada para que sólo la
forma visible reciba clics. La navegación y máscara pasan menu_flow_test.

Verificado en navegador a 1280×720: los tres accesos abren sus pantallas y
la consola no registra errores ni advertencias. Captura final:
`docs/design/character-section-2026-10-12/web-home-touching-actions.jpg`.
