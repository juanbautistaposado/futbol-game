# Hueco bajo del arquero rival — 12 de octubre de 2026

## Reproducción

En dificultad media, un pateo completo con potencia máxima y precisión perfecta
hacia `x=±3.85`, `y=0.235` o `0.24` terminaba en gol. El control cercano a
`y=0.30` sí se atajaba. La prueba que llamaba a `launch_ball` directamente no
reproducía el hueco: importa el orden real de lanzamiento desde el callback de
contacto de la animación del delantero y su relación con los ticks físicos.

La regresión permanente usa `fire_player_shot`, la carrera, el lanzamiento real,
la observación del rival y el contacto físico de la pelota. Conserva el paso de
simulación de 1/60 s al acelerar las pruebas.

## Causa y corrección

El alcance de los brazos se contrarrotaba con el ángulo **final** de la estirada,
70° en una atajada baja. Cuando llegaba la pelota, el cuerpo todavía estaba en
60.55°: el volumen de los brazos quedaba inclinado unos 9.45°, elevando su borde
exterior y dejando pasar la pelota rasa por debajo.

La contrarrotación ahora acompaña el ángulo **actual** del cuerpo mediante el
mismo tween físico. El volumen conserva su orientación horizontal durante la
estirada. No se agrandó el collider ni se cambiaron los guantes, la pose, la
trayectoria, los tiempos o la reacción del arquero.

## Verificación

- Antes: 4 goles incorrectos en 6 pateos completos, repetidos al instrumentar.
- Después: los 6 pateos son atajables a ambos lados; se verifica también que el
  alcance permanece horizontal mientras está activo.
- Pasan las 13 pruebas de sectores y alturas, incluidos los goles al seleccionar
  mal el lado o la altura.
- Pasan las pruebas de equilibrio de IA, separación de brazos y continuidad de
  la estirada.
- Pasan los cuatro ángulos del rival y las pruebas de tiros débiles, anticipación
  al lado equivocado, palos y tiros afuera.
- Se regeneró el build Web release y los seis pateos de regresión pasan también
  ejecutando su PCK exportado con Godot headless. Esto comprueba el código incluido
  en el paquete; no constituye una prueba del renderizado en navegador.

SHA-256 del PCK local: `c36ce7182ab4f55ed81719c326cd04a14ba5b700a1dd5825e5d0ddb37115567a`.
La corrección no se publicó en Netlify en esta tarea.

Prueba principal:

```sh
godot --headless --log-file /tmp/keeper-rival-ground.log \
  --path apps/free-kick-3d \
  --script res://tests/keeper_rival_ground_reach_test.gd
```

El defecto estaba en la orientación del volumen físico durante el movimiento,
no en una falta de alcance horizontal ni en las manos abiertas de la guardia.
La prueba de regresión incluye la secuencia completa de pateo para evitar la
falsa confianza que daba el lanzamiento directo.
