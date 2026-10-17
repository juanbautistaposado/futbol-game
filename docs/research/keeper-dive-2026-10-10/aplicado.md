# Mejora de la estirada del arquero — 10 octubre 2026

La revisión conserva las manos abiertas de la referencia del usuario y cambia el movimiento posterior: carga con rodillas flexionadas, alcance, continuación de vuelo con piernas asimétricas, caída de costado y recuperación desde apoyo.

## Investigación y agentes

Trabajaron cuatro agentes: referencias de EA SPORTS FC, observación de Football Strike, diagnóstico reproducible y aplicación de la animación. La integración y la revisión visual se hicieron en el juego.

- [Investigación EA FC y técnica FIFA](ea-fc.md): EA confirma captura volumétrica en FC 26, pero no publica curvas ni poses para reconstruir una estirada. Los fundamentos de FIFA Training Centre orientan la diferencia entre salida alta y baja. [EA, Gameplay Deep Dive](https://www.ea.com/games/ea-sports-fc/fc-26/news/pitch-notes-fc26-gameplay-deep-dive#goalkeeper).
- [Observación de Football Strike](football-strike.md): el trailer oficial muestra mano principal adelantada, brazo secundario retrasado, piernas asimétricas y flexión durante la caída. No muestra una incorporación completa ni documenta su rig. [Miniclip, Football Strike](https://www.miniclip.com/games/football-strike).
- [Diagnóstico medido](diagnostico.md): el movimiento anterior congelaba todo el cuerpo durante 0,25 s en el aire; los tobillos penetraban hasta 0,421 m durante caída y recuperación.

Las poses y curvas aplicadas son originales para nuestro rig y su ventana de contacto. Los tiempos no se extrajeron de FC ni Football Strike.

## Cambios aplicados

`keeper.gd` sustituye la espera después de alcanzar el destino por una pequeña continuación lateral y vertical. Esa fase permite que el balón llegue al alcance previsto mientras evolucionan las piernas. Después, el cuerpo gira hacia una caída lateral, pasa por apoyo y vuelve a la altura de guardia. La baja sale hacia el costado sin tomar el ápice de un salto alto.

`keeper_animation.gd` incorpora carga real de rodillas y poses diferentes para final de vuelo, contacto y apoyo. Las cadenas de piernas se resuelven con IK sin cambiar longitudes ni escala; una se recoge más que la otra. Pecho, rodillas y brazos acompañan la incorporación. La guardia inicial/final permanece y el ciclo sigue durando 1,59 s más el retardo de reacción.

La selección del clip convierte la dirección del tiro al eje local del rig. Esto corrige el espejo del arquero controlado, que mira hacia el otro extremo del campo, conservando la trayectoria y el giro en coordenadas mundiales.

`keeper_glove_motion.gd` recoge los guantes hacia el pecho después de la intercepción, flexionando brazos para el apoyo. La orientación de palma y muñeca conserva las comprobaciones anteriores. Se revisaron tanto huesos como vértices deformados: un tobillo sobre el piso no garantiza que la suela también quede fuera del césped.

No se amplió la caja de alcance para disimular la animación. Las atajadas continúan resolviéndose por contacto físico, con elecciones erróneas de lado/altura que dejan pasar el tiro.

## Verificación

La reproducción determinista usa `Keeper.dive()` y sus Tween reales, avanzados a 60 Hz junto con el AnimationPlayer. En seis casos de dirección/altura, la pausa completa en el aire pasa de 0,250 s a 0,000 s. Las comprobaciones mantienen sus tolerancias originales.

Pruebas de regresión ejecutadas:

| Prueba | Qué comprueba |
|---|---|
| `keeper_dive_motion_test.gd` | Continuidad del vuelo y suelo durante caída/recuperación |
| `keeper_dive_direction_test.gd` | Alcance mundial en ambos arqueros y suelas deformadas durante el apoyo |
| `keeper_glove_pose_test.gd` | Palmas, muñecas, longitudes, continuidad y guardia aprobada |
| `keeper_animation_test.gd` | Guardia, reacción, pausa, alcance, recuperación y reset |
| `kick_contact_and_dive_test.gd` | Contacto de remate y alcance de guantes |
| `keeper_save_balance_test.gd` | Nueve destinos correctos y cuatro elecciones erróneas |
| `keeper_corner_ai_test.gd` | Atajada rival en los cuatro ángulos |
| `keeper_manual_save_test.gd` | Respuesta manual y atajada por contacto |
| `animation_flow_test.gd` | Pausa, cancelación, contacto único y reacción diferida |
| `meshy_keeper_test.gd` | Identidades, personalización y pelota entre guantes |

Las diez pruebas pasan. El test nuevo cubre ocho combinaciones de arquero/lado/altura y muestrea los vértices de botas durante 1,10–1,40 s. Detectó la inversión del clip y una suela a −0,077 m que no aparecía midiendo solo el tobillo; tras corregir la pose, en 1,21 s las suelas quedan aproximadamente a +0,004/+0,008 m.

Ejecutar desde la raíz del repositorio:

```sh
godot --headless --path apps/free-kick-3d --script res://tests/keeper_dive_motion_test.gd
godot --headless --path apps/free-kick-3d --script res://tests/keeper_glove_pose_test.gd
godot --headless --path apps/free-kick-3d --script res://tests/keeper_save_balance_test.gd
```

## Capturas

- Antes: [alta](capturas/alta-antes.png), [baja](capturas/baja-antes.png).
- Después: [alta derecha](capturas/alta-despues.png), [baja derecha](capturas/baja-despues.png), [alta izquierda](capturas/alta-izquierda.png), [baja izquierda](capturas/baja-izquierda.png), [vista lateral](capturas/alta-lateral.png).
- Contacto y apoyo: [secuencia alta](capturas/alta-apoyo.png), [arquero controlado alta](capturas/manual-alta.png), [arquero controlado baja](capturas/manual-baja.png).

Se revisaron las capturas finales de ambos arqueros: guardia abierta, salida baja diferenciada, continuación de piernas, contacto con brazo/pierna y recuperación. El tool muestra la escena real con una cámara fija de inspección; no es una captura de los juegos de referencia.

El tool `tools/capture_animation_sequence.gd` usa el actor real en Main.tscn. Acepta `keeper`, `keeper_low` o `keeper_mid`; los argumentos opcionales `left`, `side`, `home` y `landing` permiten revisar dirección, cámara lateral, arquero controlado y fotogramas de contacto/apoyo.

## Límites del modelo

Los guantes actuales siguen siendo rígidos: no tienen influencia de los huesos de dedos. La mejora orienta las palmas y articula los brazos, pero no abre individualmente las falanges. Se conserva la malla y el rig existentes. Las irregularidades de las mangas pertenecen al skinning fuente y no se corrigen cambiando las curvas de esta estirada.
