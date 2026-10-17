# Estirada del arquero: EA SPORTS FC y técnica FIFA

Investigación: 10 de octubre de 2026. Alcance: mejorar la estirada del rig actual en Godot 4.7; conservar la guardia abierta solicitada por el usuario. No se descargaron ni extrajeron animaciones propietarias.

## Qué confirma EA

FC 26 incorpora animaciones de arquero basadas en captura volumétrica real, y mejoras para leer trayectorias y orientar rechazos. **El posicionamiento mediante aprendizaje por refuerzo no actúa al ejecutar una atajada ni una recepción**. Por eso no hay fundamento para atribuir la solución visual de una estirada a ese sistema. EA no publica aquí poses óseas, curvas, duraciones ni algoritmo de IK. [EA FC 26, Gameplay Deep Dive, apartado Goalkeeper](https://www.ea.com/games/ea-sports-fc/fc-26/news/pitch-notes-fc26-gameplay-deep-dive#goalkeeper).

FC 25 distingue animaciones para atajadas con pierna, pie, estirada y puño. También describe uno o dos pasos de movimiento manual, pero ese límite tiene una excepción explícita en tiros libres y córners. No debe trasladarse como regla de locomoción para nuestro tiro libre. [EA FC 25, Gameplay Deep Dive, apartado Goalkeeper](https://www.ea.com/games/ea-sports-fc/fc-25/news/pitch-notes-fc-25-gameplay-deep-dive).

El artículo técnico divulgado por los propios investigadores de EA estudia el **posicionamiento** en FC 25. Sus acciones son destino relativo y velocidad de desplazamiento. Es una referencia de decisión espacial, no un método publicado para animar manos, aterrizajes o cuerpos en vuelo. [Sestini y colaboradores, Human-Like Goalkeeping in a Realistic Football Simulation](https://arxiv.org/html/2510.23216v1).

El [Gameplay Deep Dive oficial de FC 26](https://www.youtube.com/watch?v=0GE8YCIQF2M), publicado por EA SPORTS FC el 22 de julio de 2025, tiene un capítulo de fundamentos desde 3:03. Se localizó el video y su descripción oficial, pero el acceso web usado no proporcionó reproducción fotograma a fotograma. **No se midieron tiempos de estiradas en ese video**, ni se dedujeron poses de su descripción. El tiempo 3:03 es un capítulo, no el comienzo verificado de una atajada.

## Técnica real para orientar la animación

Estas fuentes FIFA describen entrenamiento de arqueros reales, no el videojuego FIFA/FC. Dan fundamentos verificables para suplir el detalle que EA no publica.

En la estirada alta, FIFA describe pasos cortos para generar impulso, empuje secuencial de los pies, cuerpo extendido pero firme, piernas altas y palma abierta y firme al contactar. Sus ejemplos de manos derecha/izquierda corresponden al lado del ejercicio: al reflejar una pose se deben reflejar también esos papeles. Para un tiro muy lejano puede liderar una mano; para uno más alto la otra puede tener más alcance. [FIFA Training Centre, Learning to dive high](https://www.fifatrainingcentre.com/en/environment/fifa-goalkeeper-training/goalkeeping-fundamentals/learning-to-dive-high.php).

En la baja, el peso se transfiere al pie que inicia la salida, y el impulso va hacia abajo y al costado. Para sujetar, una mano respalda la pelota y la superior la controla por encima; para rechazar un balón fuera de alcance puede usarse una sola mano. [FIFA Training Centre, Learning to dive low](https://www.fifatrainingcentre.com/en/environment/fifa-goalkeeper-training/goalkeeping-fundamentals/learning-to-dive-low.php).

Para llegar rápido a una pelota cercana y baja, la pierna interior se retira hacia atrás para despejar la caída. Las piernas liberan el cuerpo y las manos avanzan abiertas hacia el balón. Esta mecánica no equivale a inclinar un salto alto hasta volverlo horizontal. [FIFA Training Centre, Learning to dive](https://www.fifatrainingcentre.com/en/environment/fifa-goalkeeper-training/goalkeeping-fundamentals/learning-to-dive.php).

## Problemas observados en nuestro juego

Revisión visual de [la secuencia vigente antes de esta mejora](../pre-shot-poses-2026-10-10/capturas/keeper-pre-shot-sequence.png):

- La guardia de 0.00 s tiene brazos abiertos, acorde a la referencia del usuario, y debe conservarse.
- Entre 0.40, 0.48 y 0.68 s la silueta y ubicación apenas cambian. A 0.90 s todavía parece suspendido.
- Las piernas acompañan el vuelo casi juntas y estiradas; no se lee claramente cuál empuja, cuál sigue ni cuál se recoge antes de tocar el suelo.
- La recuperación pasa por una figura inclinada a 1.30 s hacia la guardia a 1.65 s. La captura no muestra una pose clara de costado con apoyo antes de incorporarse.

Esas son observaciones de nuestra captura, **no mediciones de FC**. El código previo respalda una causa concreta: `_dive_clip` usa la misma rotación `extended` a 0.25, 0.45 y 0.77 s. Eso sostiene la pose esquelética durante 520 ms. Cambiar únicamente muñecas no corrige esa meseta.

## Propuesta para Godot 4.7

La siguiente es una propuesta propia, informada por las fuentes anteriores:

1. Mantener la guardia intacta hasta que comienza la reacción. Después, cargar la pierna del lado de salida y mover primero el peso del torso; evitar que el desplazamiento parezca preceder al empuje.
2. Autorizar poses distintas de carga, despegue, alcance máximo, descenso, contacto lateral, apoyo y recuperación. No reutilizar `extended` durante todo el vuelo. Una pierna puede extender el impulso mientras la otra queda algo retrasada y luego se recoge.
3. Mantener una ventana breve de alcance cerca del contacto previsto; fuera de esa ventana evolucionar pecho, cadera y piernas. No perder el alcance que requieren los tests de colisión por embellecer el vuelo.
4. Separar la mano principal de la de apoyo según altura y distancia. La palma sigue abierta al tiro, pero el brazo de apoyo no tiene que copiar siempre el brazo principal. En una baja con recepción, la disposición detrás/encima debe sustituir la pareja de palmas idénticas.
5. Tras el alcance, descender con continuidad y quedar de costado; recoger rodillas y llevar el brazo de apoyo al suelo antes de incorporarse. Es una decisión de animación propuesta, no una curva de aterrizaje publicada por EA.
6. Evaluar ambas direcciones y alturas con la cámara del juego, y luego en vista lateral. Verificar continuidad de brazos y muñecas, separación de guantes, suelo, tiempo de contacto y alcance, además de revisar la captura.

El proyecto ya crea pistas de rotación y posición con `Animation`. Se pueden introducir estas fases en los clips existentes, manteniendo una sola fuente de tiempo para movimiento raíz y pose. La documentación confirma las pistas 3D y su interpolación; no es necesario migrar toda la animación a otro sistema para corregir la meseta. [Godot 4.7, Animation](https://docs.godotengine.org/en/4.7/classes/class_animation.html).

## Límite práctico

La mejora debe juzgarse viendo el movimiento completo. Más poses, IK y tests de continuidad pueden detectar fallos, pero no garantizan por sí solos una estirada convincente. La referencia FC justifica buscar movimiento capturado y variedad contextual; el rig actual y la autoría procedural permiten aproximar sus principios, sin afirmar que reproducimos sus clips ni sus timings.
