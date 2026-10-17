# Diagnóstico medido de la estirada — 10 octubre 2026

La estirada actual tiene dos defectos reproducibles: el cuerpo completo se detiene en el aire después de alcanzar la zona del tiro y los tobillos atraviesan el suelo durante la caída. No son solamente un problema de orientación de guantes.

## Reproducción rápida

```sh
godot --headless --log-file /tmp/keeper-dive-motion.log --path apps/free-kick-3d --script res://tests/keeper_dive_motion_test.gd
```

Se ejecutó tres veces; mismo resultado rojo en aproximadamente 0.31–0.35 segundos: seis estiradas congeladas y seis penetraciones profundas. El escenario instancia `Keeper`, ejecuta su `dive()` real y avanza los Tween reales con `custom_step(1/60)`. El `AnimationPlayer` usa avance manual a la misma cadencia. La segunda trayectoria vertical empieza un tick después de crearse, como la cola de Tween de `SceneTree`. No se reproduce una fórmula alternativa de trayectoria ni se espera tiempo de reloj.

Los errores de certificados del sistema y de materiales del renderer dummy son ajenos al veredicto; la salida del test termina con `FAIL: 12 fallos de vuelo/caída` y código de salida 1.

## Qué se midió

Marcadores mundiales: Hips, Chest, Head, Hand.L/R y Foot.L/R. Hips sirve como referencia de pelvis, **no** como centro de masa físico calculado (el rig no define masas por segmento). Los orígenes Foot son tobillos, no vértices de las suelas.

| Destino Y | Lado | Inmovilidad .48–.73 s | Recorrido pelvis en esa ventana | Marcador más bajo en vuelo | Tobillo mínimo .75–1.45 s |
|---|---|---:|---:|---:|---:|
| .70 m | izquierda/derecha | .250 s | .0000 m | .164 m | −.241 m |
| 1.25 m | izquierda/derecha | .250 s | .0000 m | .465 m | −.421 m |
| 1.60 m | izquierda/derecha | .250 s | .0000 m | .815 m | −.421 m |

El test exige movimiento real de al menos un marcador mientras todo el cuerpo sigue separado del suelo: no puede haber seis frames consecutivos (0.10 s) con desplazamiento máximo menor a .5 mm. Es deliberadamente conservador: no prescribe una velocidad cinematográfica ni cambia el alcance de intercepción. La segunda comprobación tolera hasta seis centímetros bajo Y=0; aun así detecta la penetración grande de los tobillos.

Para obtener los checkpoints completos:

```sh
godot --headless --log-file /tmp/keeper-dive-motion-details.log --path apps/free-kick-3d --script res://tests/keeper_dive_motion_test.gd -- --diagnostics
```

En una estirada derecha media, a .450 s la raíz está en (2.8, 1.262, −51.8), pelvis Y=1.402 y pecho Y=1.589. A .767 s la raíz está en (2.8, 1.250, −51.8), pelvis Y=1.390 y pecho Y=1.577. La diferencia sólo corresponde al final del arco; en el interior .48–.73 todos permanecen inmóviles. A 1.017 s la raíz baja a .430 m, pero el marcador más bajo ya está a −.395 m. A 1.217 s sigue a −.413 m.

## Hipótesis antes de instrumentar y resultado

1. **Meseta de raíz después del alcance.** Si el `tween_interval(.32)` de `keeper.gd` causa el defecto, la pelvis no avanzará después de .45 s aunque esté en el aire; una caída continua elimina esa meseta. Confirmado por las medidas mundiales y por el Tween: X termina a .45 s, arco Y aproximadamente a .45–.47 s, y la siguiente caída empieza a .77 s.
2. **Pose de estirada repetida.** Si las claves iguales de `keeper_animation.gd` congelan articulaciones, la raíz por sí sola no resolverá la rigidez de piernas y torso. Confirmado: para todos los huesos principales se repite `extended` en .25, .45 y .77 s. Conviene introducir un final de vuelo diferenciado de la pose de alcance, con una pierna flexionándose y torso acompañando la caída.
3. **Aterrizaje sin apoyos.** Si bajar la raíz a .43 m con roll fijo de 45°/70° es insuficiente, algunos marcadores cruzarán Y=0 antes de recuperar la postura. Confirmado hasta −.421 m. Conviene diseñar la pose de contacto lateral y después su recuperación; no sólo subir el nodo y deshacer su giro.
4. **Límites del modelo fuente.** Si persisten guantes rígidos y bordes dentados en mangas aun con una trayectoria mejor, pertenecen al skinning/modelo y no a la curva de raíz. El [diagnóstico de manos anterior](../fifa-animation-2026-10-09/manos-diagnostico.md) ya midió influencia nula de los huesos de dedos en los guantes. Este test no interpreta esos límites como errores de trayectoria ni pretende resolverlos cambiando animaciones.

## Orden de mejora sugerido

- Preservar la guardia de manos abiertas solicitada por el usuario y el alcance/tiempo de la intercepción. Guardar un checkpoint de posiciones de guantes y colisión en la fase de alcance antes de cambiar curvas.
- Continuar el vuelo y la caída después del alcance, con transición continua de torso y piernas. Evitar mantener un cuadro .32 s en el aire.
- Introducir contacto lateral y flexión de piernas antes de que la raíz baje; la posición de apoyo debe determinar cuánto puede bajar el personaje visual.
- Recuperarse mediante un apoyo visible de brazo/rodilla, terminando de nuevo en la guardia existente. Corregir el suelo visualmente sin ampliar la capacidad de atajada del collider.
- Validar derecha/izquierda y alturas baja/media/alta con este test; ejecutar además `keeper_save_balance_test`, `keeper_animation_test` y `keeper_glove_pose_test` para alcance, retardo, pausa, guardia y muñecas. Las capturas de secuencia completan la comprobación del movimiento: estas métricas por sí solas no garantizan una animación convincente.

No se modificó runtime en esta auditoría. El nuevo test queda rojo a propósito para que la implementación posterior demuestre que elimina ambos síntomas medidos.
