# Realismo del partido — 13 de octubre de 2026

## Dirección elegida

Estadio de fútbol a última hora de la tarde: cielo azul grisáceo con nubes,
luz solar cálida, relleno ambiental frío suave y separación de las gradas por
distancia. Las referencias aportadas guían el volumen de luz, la respuesta de
superficies y el detalle del estadio. No se incorporan elementos del juego bélico.

Motor existente Godot 4.7.1, 3D, Compatibility/OpenGL; salida web y desktop.
Referencia de validación 1280×720. Escala cancha 105×68 m, cámaras y jugabilidad
existentes. Se preservan rig, clips y controladores de animación de jugadores.
Recursos gratuitos; no se compra ni genera contenido Meshy adicional.

## Prioridades visuales

1. Iluminación ambiental direccional, sombras legibles, cielo con profundidad.
2. Césped con variación de hoja, color y desgaste; franjas de corte suaves.
3. Tela limpia sin triángulos oscuros de atlas; piel y látex diferenciados.
4. Gradas con paleta de indumentaria natural, hormigón/metal de distinta rugosidad.
5. Pelota con juntas hundidas y micrograno; oclusión de contacto en calidad alta.

Los detalles pequeños se filtran al alejarse. Se mantienen tres perfiles gráficos:
bajo conserva la legibilidad, medio usa sombras y alta incorpora SSAO/glow sutil.
Se comparan capturas reales y conteos de render; no se equipara un modelo Meshy
con personajes escaneados, pelo por hebras o ropa simulada de una producción AAA.

## Validación y presupuesto

Estado inicial nativo: 355 draw calls, aproximadamente 1,17 M de triángulos,
147 MiB de texturas, media 5,48 ms y p95 7,64 ms en esta máquina (no medición web).
Se medirá con la misma escena/resolución. La captura overview inicial se ejecutó
en paralelo unos instantes: los tiempos tienen ruido y sirven sólo como referencia.
No se aumentará la densidad de hierba ni la resolución del personaje por defecto.
Se exportará una versión web local para comprobar recursos y shaders; publicar
queda como una acción posterior si el usuario la solicita.
