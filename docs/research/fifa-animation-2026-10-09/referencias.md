# Animaciones de arquero y delantero: referencias FIFA / EA SPORTS FC

Consulta: **9 de octubre de 2026**. Alcance: principios de movimiento y secuencias para las animaciones originales de nuestro juego. Se consultaron publicaciones y videos oficiales de EA; no se descargaron ni extrajeron animaciones de FIFA/FC.

## Hechos publicados por EA

### FIFA 23: continuidad del remate y variedad del arquero

EA describe HyperMotion2 como captura de partidos completos combinada con aprendizaje automático. Su interés para esta mejora es la continuidad entre acciones, no una receta de keyframes.

- **Composed Ball Striking:** mejora la transición entre controlar la pelota y rematar en situaciones que requieren un control previo.
- **Power Shots:** tienen una preparación importante antes del remate; EA explicita que requieren espacio y tiempo.
- **Tiros libres:** el punto de golpeo seleccionado determina efecto, elevación y estilo; la dirección del remate y su contacto deben resultar legibles.
- **Arqueros:** incorporan paradas reflejas y de rodilla, gestos y reacciones después de atajar o recibir un gol. Una visión bloqueada puede retrasar la reacción.

Fuente primaria: [EA, FIFA 23 Gameplay Deep Dive](https://careers.ea.com/ea-play/news/pitch-notes-fifa-23-gameplay-deep-dive), secciones HyperMotion2, Power Shots, Redesigned Set Pieces, Composed Ball Striking y Goalkeepers.

### FIFA 22: familias de paradas y movimiento contextual

EA identifica tres objetivos del nuevo arquero: paradas fiables, variedad visual y personalidad. Su sistema utiliza más de 600 animaciones e incluye estiradas, desvíos por encima del arco y movimiento general. También renueva las animaciones de tiros libres y penales.

Fuente primaria: [EA, FIFA 22 Gameplay Deep Dive](https://careers.ea.com/ea-play/news/pitch-notes-fifa-22-gameplay-deep-dive), secciones Goalkeeper Rewrite y Set Pieces.

### EA SPORTS FC 24: conservar la inercia y adaptar la respuesta

- **Movement Preservation Everywhere:** EA afirma que los arqueros conservan su movimiento durante la estirada y la caída para mejorar la autenticidad.
- Se renuevan animaciones de paradas con los pies, estiradas, desvíos y reflejos.
- Los arqueros pueden orientar un desvío hacia zonas seguras y detectar mejor tiros bombeados para desviarlos sobre el travesaño.
- **AI Hands** añade detalle al movimiento de manos y muñecas.
- **Quick Release Shots:** se busca seleccionar un remate rápido cuando el contexto lo requiere. **AI Mimic** aporta estilos corporales y de carrera individuales.

Fuente primaria: [EA, FC 24 Gameplay Deep Dive](https://www.ea.com/news/fc-24-gameplay-deepdive), secciones AI Mimic, AI Hands, Shooting Improvements, Goalkeeper y Player Movement. El cuerpo completo del artículo se obtuvo en esta URL; otras rutas regionales mostraban sólo la introducción.

## Referencias audiovisuales oficiales

[EA SPORTS, FIFA 23 Official Gameplay Deep Dive](https://www.youtube.com/watch?v=xu0jf2LwafY) ofrece capítulos específicos: [ataque, 05:54](https://www.youtube.com/watch?v=xu0jf2LwafY&t=354s), [Power Shots, 06:06](https://www.youtube.com/watch?v=xu0jf2LwafY&t=366s), [Composed Ball Striking, 06:34](https://www.youtube.com/watch?v=xu0jf2LwafY&t=394s), [pelota parada, 07:01](https://www.youtube.com/watch?v=xu0jf2LwafY&t=421s) y [arqueros, 08:58](https://www.youtube.com/watch?v=xu0jf2LwafY&t=538s). Los tiempos provienen del índice publicado por el canal oficial; no se realizó una medición fotograma a fotograma.

## Traducción a nuestro juego: decisiones de diseño propias

Las siguientes fases son propuestas de animación original. **EA no publica en estas fuentes curvas de huesos, ángulos articulares ni duración precisa de apoyos, impactos o recuperaciones.** No deben presentarse como una reproducción exacta de FIFA ni como implementación de HyperMotion.

| Función | Secuencia propuesta | Qué debe percibirse |
|---|---|---|
| Delantero en espera | Respiración leve, rodillas desbloqueadas, desplazamiento mínimo de peso. | Atleta preparado y estable. |
| Carrera al balón | Pasos alternados, brazos contralaterales, inclinación progresiva del torso. | Movimiento con cadencia y aceleración; pies que acompañan el desplazamiento. |
| Último apoyo | Desaceleración, pie de apoyo junto al balón y carga de la pierna de remate. | El cuerpo tiene una base clara antes del golpe. |
| Remate | Pelvis y torso acompañan la extensión de pierna, brazos equilibran la silueta. | Preparación seguida por aceleración breve; contacto reconocible. |
| Continuación | Pierna atraviesa la dirección del golpe, torso termina de girar, paso de recuperación y asentamiento. | La energía no desaparece inmediatamente después de golpear. |
| Arquero preparado | Base amplia, rodillas flexionadas, manos delante del cuerpo y pequeños ajustes laterales. | Puede reaccionar hacia ambos lados. |
| Impulso de atajada | Compresión breve y transferencia de peso hacia el lado elegido. | La estirada empieza desde el suelo. |
| Alcance | Cabeza y manos siguen el objetivo; brazos con extensión y flexión diferenciadas, piernas rezagadas. | Silueta dirigida hacia la pelota, con variantes altas y bajas. |
| Caída | Continuidad del desplazamiento y rotación; recepción lateral con absorción de cadera, torso y brazos. | Peso e inercia durante el aterrizaje. |
| Recuperación | Repliegue, apoyo de manos/rodillas y retorno gradual a la postura preparada. | Termina la atajada antes de volver a estar listo. |

### Contratos que deben conservarse

- El lanzamiento de la pelota debe tener un único instante de contacto sincronizado con el remate. El cambio visual no debe emitir dos impulsos.
- La trayectoria física del arquero y la resolución de la atajada continúan determinando el resultado. Las curvas de pose acompañan esos eventos.
- Los guantes deben llegar a la región de contacto y, al retener la pelota, mantenerla entre las manos durante el movimiento posterior.
- Las variantes izquierda/derecha y alta/baja necesitan revisión individual; reflejar una pose no garantiza por sí solo un contacto correcto.
- Comparar espera, carrera, contacto, alcance máximo, caída y recuperación desde la cámara real del juego, además de vistas frontal y lateral.

Estos contratos son criterios de integración propios, no especificaciones atribuidas a EA. Las fuentes respaldan continuidad, variedad y lectura contextual; las poses y su temporización se diseñan para el rig y la física de este repositorio.
