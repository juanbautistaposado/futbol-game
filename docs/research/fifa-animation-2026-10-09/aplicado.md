# Animaciones de arquero y delantero aplicadas

Fecha: 9 de octubre de 2026. Motor verificado: Godot 4.7.1.

Tres agentes trabajaron en referencias oficiales, animación de arquero y
animación de delantero. La integración y revisión visual se hicieron sobre
`Main.tscn`, con los materiales e identidades reales del juego.

## Referencias y alcance

[Investigación y enlaces oficiales](referencias.md). Las publicaciones de EA
orientan la preparación del remate, la continuidad entre acciones y el movimiento
durante estirada y caída. Las curvas, poses y tiempos aplicados son propios de
este proyecto; no son clips de FIFA/FC ni una implementación de HyperMotion.

## Delantero

`apps/free-kick-3d/striker_animation.gd` construye una biblioteca privada al
instanciar el personaje. `kicker.gd` reproduce `athlete/MatchStrike` en física.

- Dos pasos alternados durante la aproximación, con balance de brazos.
- Preparación de pelvis y torso antes del golpe y rotación durante la continuación.
- Pie izquierdo estable entre 0,36 y 0,64 s mediante resolución de la pierna.
- Pose y orientación del pie derecho originales conservadas a los 0,48 s.
- Un único contacto libera la pelota; la recuperación termina a los 1,16 s.
- Ready y Celebrate privados restauran los canales adicionales de la animación.

La prueba dedicada verifica ambas direcciones a 30, 60 y 120 ticks de física por
segundo, apoyo, contacto, continuidad de rotaciones y cancelación del remate.

## Arquero

`apps/free-kick-3d/keeper_animation.gd` proporciona guardia, cuatro variantes
laterales y dos paradas centrales. `keeper.gd` conserva la trayectoria física,
colisiones, retardo de reacción y selección de destino.

- Guardia con rodillas flexionadas, pelvis más baja y manos delante del cuerpo.
- Impulso inicial, alcance de ambos guantes y extensión sostenida hasta la caída.
- Repliegue de brazos y piernas durante la recepción y recuperación de la guardia.
- Secuencia de 1,59 s sincronizada con el desplazamiento existente.
- Clips privados con canales completos de los 53 huesos: Catch y Celebrate no
  dejan poses residuales al reiniciar.
- Reset cancela impulso, arco y reacción pendiente; retener sigue colocando la
  pelota entre las manos del esqueleto.

## Corrección posterior de las manos

La revisión del arquero incorpora IK en las poses de brazo y antebrazo,
orientación calibrada del guante visible y separación en las paradas bajas.
Las rotaciones se interpolan entre poses clave para evitar giros de codo.
[Diagnóstico, medidas y capturas](manos-diagnostico.md) y
[referencias técnicas investigadas](manos-tecnica.md).

## Verificación

Pruebas funcionales aprobadas:

| Prueba | Qué comprueba |
|---|---|
| `striker_animation_test.gd` | Pasos, apoyo, impacto, recuperación, 30/60/120 Hz y ambas direcciones. |
| `keeper_glove_pose_test.gd` | Palmas, muñecas, longitudes, continuidad a 60 Hz, simetría y separación baja. |
| `keeper_animation_test.gd` | Guardia, reacción, alcance, pausa, caída, recuperación, central, baja y reset completo. |
| `animation_flow_test.gd` | Pausa del remate y estirada, contacto único y cancelación al cambiar de turno. |
| `kick_contact_and_dive_test.gd` | Contacto real pie/pelota y alcance de ambos guantes. |
| `keeper_save_balance_test.gd` | Nueve destinos correctos y cuatro elecciones incorrectas. |
| `keeper_corner_ai_test.gd` | Cobertura de los cuatro ángulos por el arquero rival. |
| `keeper_manual_save_test.gd` | Estirada dirigida y resolución por contacto físico. |
| `keeper_hands_test.gd` | Pelota entre guantes y celebración. |
| `shot_and_keeper_test.gd` | Tiro, reacción y reinicio del arquero. |
| `striker_arms_test.gd` | Conservación de clips fuente y continuidad del gesto de brazos. |
| `meshy_player_test.gd` | Identidad, materiales, contacto y reutilización del delantero. |
| `meshy_keeper_test.gd` | Ambos arqueros, guantes, identidad y captura. |
| `custom_players_test.gd` | Aspecto personalizado. |
| `menu_flow_test.gd` | Menú, selección, pausa, continuar y salir. |
| `round_flow_test.gd` | Turnos, puntuación, desempate y regreso al menú. |

Godot con renderizador dummy emite avisos de materiales nulos en algunas pruebas
de personajes aislados; las aserciones pasan. La ejecución gráfica de las capturas
no presentó errores de script. El sandbox impide guardar preferencias globales
del editor, pero el escaneo del proyecto generó los UID de los scripts nuevos.

## Capturas del movimiento real

La herramienta `apps/free-kick-3d/tools/capture_animation_sequence.gd` dispara
`kick()` o `dive()` y captura ticks completos de física con cámara fija.

- [Delantero frontal](capturas/delantero.png).
- [Delantero lateral](capturas/delantero-lateral.png).
- [Arquero alto](capturas/arquero.png).
- [Arquero bajo](capturas/arquero-bajo.png).

Ejemplo desde la raíz del repositorio:

```sh
godot --log-file /tmp/futbol-animation-capture.log --path apps/free-kick-3d \
  --resolution 1280x720 --fixed-fps 60 \
  --script res://tools/capture_animation_sequence.gd -- /tmp/remate.png striker side
```

La revisión mantiene una aproximación corta y el vuelo del arquero ajustado a la
jugabilidad del duelo. Las poses siguen siendo keyframes sobre el rig existente;
no se añade captura de movimiento ni adaptación a superficies arbitrarias.
