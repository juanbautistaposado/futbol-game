# Posturas antes del tiro y la atajada

10 de octubre de 2026. Godot 4.7.1. Un agente trabajó en cada personaje y la
integración revisó las poses sobre `Main.tscn`, con los materiales del juego.

## Arquero antes de tirarse

La [imagen aportada por el usuario](capturas/referencia-arquero-usuario.png)
define la guardia final: brazos bien abiertos hacia los lados, guantes cerca de
la altura de los hombros y codos ligeramente flexionados. Las palmas se
presentan al tiro y los dedos apuntan mayormente hacia los lados. Las piernas
mantienen su flexión. Esta es la espera visible, incluida la demora de reacción,
antes de iniciar la estirada.

Las variantes laterales, bajas y centrales parten de esta guardia y regresan a
ella. La corrección sólo orienta y coloca los brazos del rig existente. Los
cinco dedos ya extendidos del guante se ven abiertos al girar la palma; el modelo
sigue sin deformación individual de dedos.

Referencia técnica: [FIFA Training Centre, postura atlética de arquero](https://www.fifatrainingcentre.com/en/environment/fifa-goalkeeper-training/sessions/managing-defensive-offensive-defensive-transitions.php).
La fuente describe una postura atlética general. La apertura y altura de
brazos final se ajustaron a la imagen del usuario; esa referencia visual
reemplaza la guardia anterior con manos cerca del torso.

El brazo se resuelve sobre poses clave; la orientación del antebrazo acompaña
su dirección sin heredar giros bruscos del clip fuente. La muñeca distribuye
los cambios rápidos sobre varios fotogramas y conserva los extremos de guardia.
Las palmas permanecen orientadas hacia el tiro y la longitud de los brazos
se conserva durante la animación completa.

## Delantero antes de patear

Base escalonada, ambas rodillas ligeramente flexionadas, torso inclinado hacia
la pelota y brazos relajados. Una respiración discreta mueve el torso y mantiene
las botas fijas en el césped. La pose se reproduce mientras se apunta o carga
potencia y también para el rival IA.

El primer y último fotograma del remate coinciden con la preparación. Los dos
pasos, el apoyo izquierdo y el contacto a los 0,48 s se mantienen.
[Referencias oficiales de FIFA y decisiones de animación](delantero.md).

## Capturas de las poses reales

- [Arquero frontal](capturas/keeper-pre-shot-front.png).
- [Arquero lateral](capturas/keeper-pre-shot-side.png).
- [Guardia, estirada alta y recuperación](capturas/keeper-pre-shot-sequence.png).
- [Guardia, estirada baja y recuperación](capturas/keeper-pre-shot-low-sequence.png).
- [Delantero frontal](capturas/striker-pre-shot-front.png).
- [Delantero lateral](capturas/striker-pre-shot-side.png).
- [Preparación, pasos, golpe y recuperación](capturas/striker-new-ready-sequence.png).

La herramienta `apps/free-kick-3d/tools/preview_pre_shot_pose.gd` muestra Ready
en la escena real. Ejemplo desde la raíz:

```sh
godot --log-file /tmp/pre-shot-preview.log --path apps/free-kick-3d \
  --script res://tools/preview_pre_shot_pose.gd -- /tmp/pose.png keeper side
```


## Verificación final

Pruebas aprobadas: `keeper_glove_pose_test`, `keeper_animation_test`,
`striker_animation_test`, `striker_arms_test`, `kick_contact_and_dive_test`,
`animation_flow_test`, `meshy_player_test`, `menu_flow_test` y
`keeper_save_balance_test`.

La prueba del arquero exige guantes lateralmente separados a altura de hombros,
codos sin bloquear y dedos orientados hacia los lados,
coincidencia entre guardia e inicio/final de todas las atajadas, orientación,
alineación, longitudes, continuidad a 60 Hz y simetría. La del delantero
comprueba botas fijas al respirar, ambos extremos del remate iguales a Ready,
apoyo y contacto, a 30/60/120 Hz y en ambas direcciones.

Las capturas muestran ambos actores de frente y de perfil y las secuencias de
acción completas. Las reglas físicas de alcance, dificultad, sector y altura
conservan los nueve casos de atajada correcta y los cuatro de elección errónea.


La adaptación a la imagen pasó `keeper_glove_pose_test`,
`keeper_animation_test` y `kick_contact_and_dive_test`. Las capturas del arquero
se actualizaron para mostrar la referencia final; las anteriores se conservan
con el sufijo `-guardia-anterior`.
