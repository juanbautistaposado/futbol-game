# Dirección de arte para la interfaz de Tiros Libres 3D

**Fecha:** 3 de octubre de 2026  
**Alcance:** investigación y propuesta visual. No se modificó la interfaz ni la jugabilidad.

## Diagnóstico de la interfaz actual

Revisé `DESIGN.md`, `CONTEXT.md`, `apps/free-kick-3d/menu.gd`, `apps/free-kick-3d/ui/visual_theme.gd` y las capturas `impeccable-inicio.png` e `impeccable-ajustes.png`.

La estructura funcional ya tiene una jerarquía clara: el inicio prioriza JUGAR, presenta al futbolista en el estadio y conserva navegación visible; los ajustes separan desafío e imagen/sonido. El tema centraliza fuentes, colores, estados de foco y controles en un módulo reutilizable. Son activos valiosos para conservar.

La sensación de plantilla aparece en la suma de códigos demasiado familiares: base azul noche, lima como único acento, superficies azules repetidas con borde, controles rectangulares uniformes, título condensado enorme, y velo oscuro degradado sobre escena 3D. En ajustes, la grilla simétrica de categorías y opciones se parece a un panel de configuración de producto. En inicio, el personaje y el arco ya prometen un juego concreto, pero la gráfica no continúa esa historia. La captura de ajustes deja además el campo y el jugador perceptibles detrás de la pantalla, lo que resta calma visual a una pantalla de lectura.

La recomendación no es sumar adornos. Conviene elegir un sistema con una idea reconocible, reducir las formas de componentes genéricos, y vincular el menú y el HUD al ritual específico de ejecutar y atajar un tiro libre.

## Referencias de primera mano

Las observaciones de esta sección describen únicamente lo que muestran las capturas, páginas o videos oficiales enlazados. Las inferencias de diseño están marcadas como tales; no se propone reproducir logotipos, uniformes, tipografías propietarias ni arte de estos juegos.

| Referencia | Observación visual documentada | Idea transferible e inferencia |
|---|---|---|
| **EA SPORTS FC 25 — modo Carrera** | La página oficial publica una captura del menú de Carrera con estadio a la derecha y lista de tareas, y otra con la interfaz mostrando próximos partidos y clasificación. EA explica que la lista pone asuntos prioritarios en primer plano. [Análisis oficial de Carrera](https://www.ea.com/es/games/ea-sports-fc/fc-25/news/pitch-notes-fc-25-career-mode) | Un sujeto o entorno 3D puede dar presencia mientras una columna de información concreta organiza la acción. Para Tiros Libres, la columna debería representar la ronda y el próximo paso, no imitar un feed de noticias o licencia de competición. |
| **Football Manager 25 — propuesta de UI publicada** | En su anuncio de desarrollo, Sports Interactive presentó capturas de una propuesta para la nueva UI de FM25: estados de distinto tamaño para un resumen de forma y su expansión a una tarjeta con más detalle; el artículo explica que el diseño pretendía evitar muros de texto. Se cita como dirección mostrada en el anuncio, sin asumir que ese producto se lanzó. [Anuncio y capturas oficiales](https://www.footballmanager.com/news/development-update-football-manager-25) | La jerarquía puede cambiar con la relevancia: compacto durante el juego, detallado al entrar. Inferencia: mostrar datos solo al momento adecuado serviría para la selección, el resumen de ronda y el HUD; copiar el sistema de mosaicos completo sería innecesario para este alcance pequeño. |
| **Rocket League — Play Menu** | Psyonix enseña una propuesta de menú más cuadrada, con submenús simplificados y tarjetas de modos. El artículo advierte que las imágenes eran ilustrativas y no finales. [Primer vistazo oficial al menú](https://www.rocketleague.com/news/first-look-play-menu-changes-coming-to-rocket-league) | Los contornos y módulos pueden ayudar cuando hay varios modos para escoger. Inferencia: el juego actual no necesita muchas tarjetas porque su bucle es directo; una composición de una acción principal más una ruta secundaria expresa mejor la escala. |
| **Mario Strikers: Battle League** | La tienda oficial muestra capturas de personajes y acción, y describe una variante de fútbol deliberadamente exagerada con tackles e Hyper Strikes. [Página oficial de Nintendo](https://www.nintendo.com/us/store/products/mario-strikers-battle-league-switch/) | La identidad arcade gana fuerza cuando los personajes, la acción y las señales gráficas comparten energía. Inferencia: podríamos tomar ritmo, diagonales y celebración en la ruta arcade sin usar personajes, logos o recursos de Mario. |
| **eFootball — control y simulación en cancha** | Konami publica un tráiler in-engine y capturas de juego; su productor describe una intención realista y grounded en la pasión por el fútbol. [Anuncio y tráiler oficial](https://www.konami.com/games/us/en/topics/1756/) | Si el juego quiere enfatizar la ejecución y la lectura del remate, la interfaz puede hablar con precisión deportiva y dejar que la escena aporte realismo. Es una referencia para contención, no una obligación de simular una transmisión licenciada. |

## Tres rutas visuales

### 1. Crónica de potrero — recomendada

Una gráfica editorial deportiva en español rioplatense: programa de cancha, planilla de goleador, carteles impresos y crónica de una jugada. El tono local viene de la voz, el ritmo de la composición y los materiales gráficos originales; no de escudos, camisetas oficiales ni una paleta atribuible a un club.

**Paleta por rol**

| Rol | Color | Uso |
|---|---|---|
| Tinta | `#202321` | Texto principal, marcador y líneas fuertes |
| Papel | `#F2EBDD` | Superficie de lectura y panel principal |
| Verde tribuna | `#456B57` | Fondos secundarios, campo y metadatos de cancha |
| Rojo señal | `#D94E38` | Acción primaria y eventos importantes |
| Amarillo ficha | `#E7BC54` | Turno activo, dato destacado o foco alternativo |
| Papel gastado | `#C9C0AF` | Líneas, separadores y estados deshabilitados |

Mantener rojo y amarillo como señales puntuales, sin emparejarlos siempre. En botones rojos o amarillos, usar tinta oscura `#202321` para texto e iconos; en paneles oscuros, usar papel `#F2EBDD`. Evitar papel claro sobre rojo en texto pequeño. Revisar los pares finales de texto/fondo con una comprobación de contraste antes de integrarlos; reservar `#C9C0AF` para líneas o metadatos secundarios si no alcanza contraste como texto.

**Tipografía con licencia verificada:** Archivo Black no es necesario; usar **Archivo** en peso 700–900 para titulares y **IBM Plex Sans** para lectura, ambas familias en SIL Open Font License 1.1 (OFL) según los metadatos oficiales de Google Fonts. La licencia permite incorporarlas y redistribuirlas junto al juego conservando aviso y licencia. [Archivo: metadatos OFL](https://github.com/google/fonts/blob/main/ofl/archivo/METADATA.pb), [IBM Plex: licencia OFL de IBM](https://github.com/IBM/plex/blob/master/LICENSE.txt). La actual **Barlow** también está bajo OFL; podría mantenerse en cifras o textos si conviene evitar una migración tipográfica completa. [Barlow: licencia del proyecto](https://github.com/jpt/barlow).

**Formas y composición:** márgenes como una página impresa; títulos alineados a una retícula izquierda; filetes, números grandes, columnas de datos y recortes diagonales como acento. Reservar la esquina o el margen para “RONDA 01”, distancia y mejor marca. Evitar textura de papel encima del mundo 3D; la textura vive en el overlay, con grano casi imperceptible. Inicio: gran título editorial, una línea de contexto y dos acciones (“JUGAR” y “CONFIGURAR”), con el personaje visible a la derecha. Ajustes: lista vertical de grupos con valores al lado; no dos grandes tarjetas iguales. HUD: franja compacta tipo planilla con marcador, ejecutante, turno y dirección, usando números alineados y contraste sólido.

**Movimiento:** cambio de pantalla como pase de página corto (desplazamiento lateral 10–16 px y opacidad), selección como subrayado o sello de tinta, sin rebotes en textos largos. Gol/atajada puede ensanchar momentáneamente la etiqueta de resultado y luego asentarse. Reducir o eliminar el movimiento con la preferencia de accesibilidad del sistema, si se añade.

**Por qué encaja:** el juego ya usa voseo (“Elegí”, “Apuntá”) y su unidad dramática es un duelo breve. La ruta convierte esa especificidad cultural y la planilla de una definición deportiva en identidad propia sin apropiarse de marcas reales.

**Composición inicial concreta:** sacar “TU CANCHA. TU MOMENTO.”, que no cuenta qué hace único al juego. Tratar **TIROS LIBRES** como marca tipográfica propia: dos líneas grandes, con una ligadura/corte original que recuerde el arco y la trayectoria, sin balón ni escudo como sustituto automático de identidad. Debajo, usar una ficha de encuentro breve: `DUELO 01 · 24 M · 7 TIROS`; el voseo queda para instrucciones de acción. El menú se compone como afiche/ticket editorial: encabezado a la izquierda, papel claro con borde de corte o muesca vertical, JUGAR como acción principal sin segunda tarjeta gemela, CONFIGURAR como enlace/acción secundaria tipográfica y la mejor marca como dato de planilla. Reubicar al jugador hacia la derecha y dejar que el arco/cancha funcionen como fotografía de fondo recortada, con una pose de espera si la animación ya existe; el contenido de lectura tiene un plano opaco de papel para sostener contraste. El HUD usa la misma gramática de planilla: marcador de goles grande, turno y distancia en columnas cortas, estado “TIRO / ATAJADA” en una etiqueta de color, y una regla fina para separar los datos. Así título, inicio y HUD nacen de la misma metáfora visual.

### 2. Señal de transmisión — premium

Un lenguaje de realización televisiva: información de marcador, tiempo y turno; marcos finos, tipografía de pantalla y un uso calculado del color de señal. El mundo 3D funciona como la toma principal; la UI debe sentirse como una capa de transmisión limpia.

**Paleta por rol**

| Rol | Color | Uso |
|---|---|---|
| Carbón | `#111519` | Base opaca para capas de lectura |
| Pizarra | `#252D33` | Paneles secundarios |
| Blanco técnico | `#F3F3EF` | Texto y lectura principal |
| Gris de dato | `#A8B1B5` | Etiquetas y datos de contexto |
| Ámbar señal | `#F0A43A` | Acción, alerta o turno en curso |
| Cian marcador | `#47B9C8` | Indicadores de dirección y retroalimentación |

**Tipografía con licencia verificada:** **IBM Plex Sans Condensed** para titulares/cifras y **IBM Plex Mono** solo para datos tabulares. Ambas forman parte del proyecto IBM Plex; su licencia oficial es SIL OFL 1.1. [IBM Plex y familias](https://github.com/IBM/plex/), [licencia oficial](https://github.com/IBM/plex/blob/master/LICENSE.txt), [metadatos de IBM Plex Sans Condensed](https://github.com/google/fonts/blob/main/ofl/ibmplexsanscondensed/METADATA.pb).

**Formas y composición:** paneles rectos, radios mínimos, reglas de 1 px, numeración en mono y etiquetas pequeñas con espaciado moderado. Inicio con un “lower third” de título y modo abajo a la izquierda y una selección principal vertical; una placa pequeña identifica al arquero o la marca. Ajustes como menú de broadcast: nombre del grupo, valor y descripción breve, con tabs solo si se necesitan. HUD con marcador compacto centrado en la zona alta, información de turno en una banda inferior y un indicador de remate a la derecha; proteger una ventana amplia de la cancha.

**Movimiento:** barridos horizontales de máscara, entrada escalonada de marcador, transiciones de corte limpio (100–160 ms). En un gol, animar el número con una breve expansión, sin flash de pantalla que distraiga del resultado.

**Costo/riesgo estético:** si se usa en toda la UI, puede parecer genérico de canal deportivo o excesivamente serio frente al modelo simplificado de los jugadores. Necesita microcopy y una paleta muy propia para diferenciarse.

### 3. Cartel de desafío — arcade expresivo

Una gráfica de póster y máquina arcade: formas de alto contraste, diagonales, numeración enorme y energía de cómic deportivo. La celebración ocupa un lugar visual tan claro como el acto de patear.

**Paleta por rol**

| Rol | Color | Uso |
|---|---|---|
| Tinta ciruela | `#211A2B` | Texto, contorno y sombras |
| Crema cancha | `#FFF2D0` | Base de lectura cálida |
| Azul eléctrico | `#3456E8` | Bloques de navegación |
| Naranja pelota | `#F05B3F` | Acción primaria y goles |
| Amarillo energía | `#F5D547` | Potencia y turno activo |
| Verde tablero | `#62C58D` | Confirmación y resultado positivo |

**Tipografía con licencia verificada:** **Bungee** para títulos cortos, etiquetas de modo y cifras expresivas; **Archivo** o **Barlow** para texto de control y descripciones. Google Fonts declara Bungee en su catálogo de fuentes libres, y el proyecto tipográfico enlazado por esa ficha distribuye OFL 1.1. [Bungee: ficha de Google Fonts](https://github.com/google/fonts/blob/main/ofl/bungee/METADATA.pb), [proyecto Bungee y licencia OFL](https://github.com/djrrb/Bungee). La familia display debe limitarse a pocas palabras: no usarla en menús de lectura.

**Formas y composición:** tarjetas inclinadas en una sola zona, recortes tipo rayo, números circulares para vueltas, rayas de velocidad y distintivos originales de “GOL”, “ATAJADA” o “AL TRAVESAÑO”. Inicio con botón principal como sticker grande y selector de personaje por retratos/poses si esos retratos existen; si no, preservar al personaje 3D como foco. Ajustes en lista simple para que la energía no dañe lectura. HUD con una barra de potencia y marcador de alto contraste; animar la reacción después de que la acción se resuelva.

**Movimiento:** overshoot moderado de 4–8 px para el botón, medidor que se llena con un wipe, marcador con punch-in y estela breve en la confirmación del tiro. Mantener el input y los tiempos de gameplay idénticos: son transiciones visuales de interfaz y empiezan tras el cambio de estado ya existente.

**Costo/riesgo estético:** es la ruta con más energía, pero puede sobrepasar la escena 3D sobria y puede sentirse infantil si se usa el alfabeto de cómic en cada pantalla. Debe reservarse a eventos y acciones, con controles secundarios quietos.

## Cinco patrones actuales para abandonar

1. **Azul noche más lima como identidad completa.** Ese emparejamiento aparece en muchas interfaces de rendimiento y tecnología; deja de decir algo sobre fútbol o sobre el carácter local del juego.
2. **Panel y borde en cada elemento.** Si título, selector, botón y tarjeta tienen todos la misma caja azul con borde, no queda una escala visual y cada pantalla parece formulario.
3. **La misma grilla simétrica en todos los menús.** Dos columnas y tarjetas duplicadas comunican un panel genérico, incluso cuando hay una sola tarea principal.
4. **Todo en mayúsculas y display condensada.** Mantener el título como gesto, pero devolver textos de ayuda, estados y ajustes a frase normal; mejora lectura y reduce el aspecto de plantilla deportiva.
5. **Fondo 3D detrás de controles de lectura con velo uniforme.** En inicio el estadio debe lucirse; en ajustes el plano debe bajar a un valor simple y opaco, o el personaje debe apartarse del área del texto. La escena puede seguir viva en las pantallas de selección y juego.

## Implementación visual en Godot

La estructura existente facilita una pasada visual aislada: `visual_theme.gd` concentra constantes, tipografías y `StyleBoxFlat`; `menu.gd` crea páginas de `Control`; `main.gd` reúne el HUD bajo `CanvasLayer`. Se puede crear un conjunto nuevo de colores, fuentes, estilos y recursos SVG originales ahí, manteniendo las mismas señales, callbacks, foco, guardado, InputMap y transiciones de escena.

- Definir tokens con nombres de rol (`INK`, `PAPER`, `ACTION`, `ACTIVE`, `MUTED`) y un tema por ruta o una sola ruta elegida para producción. Cambiar el valor de los tokens no debe alterar lógica ni físicas.
- Construir controles con `StyleBoxFlat` y dibujo vectorial/SVG originales. Para diagonales, filetes y marcas, usar `Control._draw()` o SVG; evitar rasterizar el HUD o incluir insignias de marcas reales.
- Conservar el CanvasLayer existente para el marcador, el turno, instrucciones y respuesta del tiro. Cambiar orden, escala y estilo de nodos de UI con anclas/containers; mantener el espacio interactivo y no desplazar los targets 3D.
- Animar solo propiedades de UI (`modulate`, `position`, `scale`, `custom_minimum_size`) mediante `Tween`/`AnimationPlayer`, conectadas a señales ya disparadas al cambiar de estado. La duración visual no debe retrasar input ni simulación.
- Mantener foco accesible en teclado y mando. Rediseñar el anillo doble visible actual como indicador alineado a la ruta (barra lateral, subrayado o placa), pero seguir distinguiendo foco, hover, seleccionado y deshabilitado sin depender solo del color.
- Usar texto en español rioplatense coherente con `CONTEXT.md`. No atribuir al juego licencias oficiales de selecciones o clubes: crear nombres, marcas y escudos propios si hacen falta.

**Recomendación:** desarrollar la ruta **Crónica de potrero**. Tiene la mejor correspondencia con los términos y la voz local ya definidos, y puede distinguir la UI por composición y tono incluso si el estadio/modelos siguen siendo estilizados. Mantendría una parte de la claridad “de transmisión” para la información de marcador y adoptaría del arcade solo el énfasis de resultado; la base de identidad seguiría siendo editorial, papel/tinta y verde de cancha. La recomendación es una hipótesis de dirección visual, no una conclusión validada por pruebas de usuarios.

## Licencias tipográficas

Las licencias indicadas se comprobaron en los repositorios oficiales de las familias o en los metadatos de Google Fonts con enlace al repositorio fuente. La OFL 1.1 permite incrustar y redistribuir fuentes como parte del software siempre que se incluya la licencia/aviso correspondiente y se respeten los nombres reservados si se modifica la fuente. Antes de añadir una familia al proyecto, copiar el archivo `OFL.txt`/`OFL-1.1.txt` correspondiente a `apps/free-kick-3d/ui/fonts/` junto con los binarios.

Familias sugeridas y fuentes de licencia:

- [Archivo — metadatos de Google Fonts, OFL](https://github.com/google/fonts/blob/main/ofl/archivo/METADATA.pb)
- [Barlow — licencia SIL OFL 1.1 del proyecto](https://github.com/jpt/barlow)
- [IBM Plex Sans Condensed — metadatos de Google Fonts](https://github.com/google/fonts/blob/main/ofl/ibmplexsanscondensed/METADATA.pb)
- [IBM Plex — licencia SIL OFL 1.1 de IBM](https://github.com/IBM/plex/blob/master/LICENSE.txt)
- [Bungee — metadatos de Google Fonts](https://github.com/google/fonts/blob/main/ofl/bungee/METADATA.pb) y [proyecto tipográfico](https://github.com/djrrb/Bungee)

## Material consultado

- EA SPORTS FC 25, “Análisis detallado del modo Carrera”: https://www.ea.com/es/games/ea-sports-fc/fc-25/news/pitch-notes-fc-25-career-mode
- Football Manager, “Development Update: Football Manager 25”: https://www.footballmanager.com/news/development-update-football-manager-25
- Rocket League, “First Look: Play Menu Changes Coming to Rocket League”: https://www.rocketleague.com/news/first-look-play-menu-changes-coming-to-rocket-league
- Nintendo, página oficial de Mario Strikers: Battle League: https://www.nintendo.com/us/store/products/mario-strikers-battle-league-switch/
- Konami, “New eFootball Gameplay Details Revealed by Konami at Gamescom 2021”: https://www.konami.com/games/us/en/topics/1756/
