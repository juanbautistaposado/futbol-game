# Brazos y manos de PLAYER al patear — aplicado localmente

## Resultado

PLAYER dejó la postura de presentación con brazos caídos y palmas abiertas
al frente. En preparación mantiene codos flexionados y manos orientadas hacia
dentro. En la patada con Foot.R, el brazo opuesto se abre como contrapeso y
el del mismo lado se recoge; durante la continuación vuelven hacia el torso.
Las fases se interpolan suavemente y terminan en el gesto de listo.
La interpolación usa Quaternion slerp entre orientaciones locales de las
poses clave, con entrada/salida suavizada, para evitar el giro rápido que
puede causar normalizar una dirección interpolada al invertir el antebrazo.

Tres agentes revisaron referencias primarias, la lectura de poses y el rig:

- [Referencias futbolísticas y biomecánica](referencias.md).
- [Objetivos de pose y verificación visual](poses.md).
- [Auditoría de rig, pesos y manos](rig.md).

La referencia visual principal fue la [repetición oficial de FIFA de Beckham
contra Ecuador, 0:27–0:29](https://www.youtube.com/watch?v=PM79nfZr30I&t=27s).
Los rangos y puntos usados son decisiones de animación, no una reconstrucción
de captura de movimiento ni mediciones de ese jugador.

## Autoría y alcance

`tools/pose_striker_arms.py` genera nuevos canales de rotación de
`UpperArm.R/L`, `Forearm.R/L` y `Hand.R/L` en Idle y Kick. Trabaja en el espacio
del torso animado y convierte las orientaciones al espacio local respetando
las longitudes, los padres y el reposo de los huesos. Solo escribe rotaciones.
No deja constraints ni un solver IK activo en runtime.

El exportador calcula matrices locales a partir de poses globales y puede
introducir redondeos en canales no editados. La entrega restaura sus samplers
originales desde v3, de forma que el GLB sólo cambia esas doce pistas de
rotación (seis por clip), manteniendo **todo lo demás exactamente igual**.
La fuente Blender conserva sus curvas originales fuera de esas rotaciones.

Meshy no tenía pesos en sus huesos de dedos, pese a que el rig los incluye.
Se eligió una curvatura estática continua en la geometría distal de la mano:
15% menos separación lateral, hasta 24 mm de curvatura hacia la palma y hasta
8 mm de recogimiento longitudinal, con transición suave y una máscara para
respetar el pulgar. No es un puño cerrado ni un sistema de dedos animados
individualmente. Se conservan UV, mapas, pesos y todos los huesos.

El cambio afecta únicamente al personaje completo PLAYER. Los assets v4 de
los otros delanteros y los arqueros conservan sus hashes anteriores. Se
mantienen colores, rostro, cabello, ropa y botines. No hay nuevas generaciones
ni créditos de Meshy, y no se publicó una nueva versión web.

## Validación

- `tools/audit_meshy_player.py`: rig/bind matrices exactos, los ocho clips
  presentes, canales ajenos a las rotaciones de brazos exactos. 53 huesos,
  101904 triángulos, UV0/UV2 y pesos normalizados. Métricas y hashes en
  `../meshy-trial-2026-10-06/full-player-rig.json`.
- `tests/striker_arms_test.gd`: flexión de codos al preparar, mano opuesta más
  alta/abierta al impacto, duración original y posiciones/orientaciones de
  Root, torso, cabeza y piernas conservadas en seis muestras. PASS.
  También recorre treinta muestras del clip para detectar saltos de rotación
  mayores a 0.45 rad por cuadro en brazos y manos; la versión final pasa.
- `tests/meshy_player_test.gd` con renderer nativo: selección persistente,
  dorsal editable, contacto con la pelota y restauración después de defensa.
  PASS.
- `tests/kick_contact_and_dive_test.gd`: sincronización de golpeo y arquero.
  PASS.
- Revisión nativa de preparación, contacto, continuación, perfil, espalda y
  cámara de cancha. Capturas en este directorio; comparación antes/después
  en `comparacion-contacto.png`.

La liberación de pelota sigue en 0.48 s. No se añadieron nuevas transiciones
que puedan desplazar el contacto. Las posiciones de codos y muñecas se usan
como guías de dirección; no se trasladan huesos ni se estiran extremidades.
