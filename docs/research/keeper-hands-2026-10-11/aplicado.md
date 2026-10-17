# Cruce de manos y vista de atajada — 11 octubre 2026

Se corrigieron los recorridos de los brazos durante impulso, alcance, caída y recuperación. La principal alcanza el tiro; la secundaria tiene un recorrido propio. En las estiradas medias/altas se usa un rechazo con una mano, con el apoyo bajo y junto a su hombro. La guardia abierta de la imagen del usuario se conserva.

## Investigación

Participaron cuatro agentes: referencias FC/FIFA, referencias Football Strike, diagnóstico y aplicación. La revisión visual de integración utilizó tanto el frente como la cámara real de atajada del producto.

- [FC y técnica FIFA](fc.md): EA documenta captura volumétrica, pero no publica curvas ni guías de codo. FIFA distingue recepción y rechazo con una mano fuera del alcance de ambas. [FIFA, media altura](https://www.fifatrainingcentre.com/en/environment/fifa-goalkeeper-training/goalkeeping-fundamentals/learning-to-dive-at-mid-height.php), [FIFA, estirada alta](https://www.fifatrainingcentre.com/en/environment/fifa-goalkeeper-training/goalkeeping-fundamentals/learning-to-dive-high.php).
- [Football Strike](football-strike.md): la observación del trailer oficial realizada el 10 de octubre muestra principal adelantada y apoyo más bajo, con siluetas diferentes. El navegador no estuvo disponible para repetir la reproducción el día 11. [Página oficial y trailer](https://www.miniclip.com/games/football-strike).
- [Diagnóstico reproducible](diagnostico.md): midió cruces de antebrazo contra brazo contrario y de palmas/dedos, aunque las muñecas estuvieran separadas.

Las posiciones y tiempos son originales para este rig. No se observaron nuevos fotogramas de FC en esta revisión ni se presentan las curvas como animaciones extraídas de los juegos.

## Causa y corrección

La trayectoria importada del apoyo atravesaba el recorrido del brazo principal. Después, ambos objetivos de aterrizaje se reunían al mismo lado del pecho, a unos 16,6 cm entre sí. Orientar los guantes y separar sus muñecas no evitaba que sus dedos y antebrazos ocuparan el mismo espacio durante las transiciones.

`keeper_glove_motion.gd` ahora resuelve recorridos continuos de brazos con guías estables de codo y destinos distintos para cada mano. En medias/altas, la principal gana extensión real y el apoyo queda junto a su propio hombro, debajo del principal. En la baja las manos siguen destinos escalonados; al caer, cada brazo se recoge hacia un apoyo propio.

La principal media/alta pasa de una extensión hombro–muñeca equivalente al 82,6 % de la cadena a aproximadamente 94–96 %. Su flexión de codo baja de unos 69° a 31–40°. El ajuste mueve la muñeca unos 12 cm lateralmente y menos de un centímetro en altura mundial durante el alcance. La caja de colisión, la reacción y el ciclo de 1,59 s conservan sus valores.

La revisión visual también detectó que una primera solución sin interpenetración todavía llevaba el apoyo por debajo de la mandíbula. Esa pose se descartó. La variante final deja la cara despejada desde el frente y las siluetas separadas desde atrás.

## Regresión y resultados

Se ejecutó el mismo `Keeper.dive()` real, con sus Tween y animación avanzados a 60 Hz. La prueba incluye ambos arqueros, ambos lados y alturas baja/media/alta.

| Métrica mínima | Antes | Final |
|---|---:|---:|
| Antebrazo contra brazo opuesto, medias/altas | 0,008 m | 0,505 m |
| Núcleos de palma/dedos, todo el ciclo | 0,025–0,034 m | 0,408 m |
| Separación de núcleos proyectados en vista de atajada a 1280 px de ancho | 0 px | 45 px |

Son distancias entre proxies conservadores dentro de los brazos/guantes, no distancias exactas entre todas las superficies de la malla. La proyección se normaliza por ancho del viewport y usa `look_from_keeper()` del producto. Las capturas complementan estas medidas.

La reproducción original terminó en **FAIL 26**: veinte fallos geométricos y seis de proyección. La variante intermedia pasó esos checks, pero falló ocho nuevas comprobaciones del rol del apoyo tras detectar el barrido bajo la mandíbula. La variante final pasa los doce escenarios completos.

```sh
godot --headless --path apps/free-kick-3d --script res://tests/keeper_arm_separation_test.gd
godot --headless --path apps/free-kick-3d --script res://tests/keeper_glove_pose_test.gd
godot --headless --path apps/free-kick-3d --script res://tests/keeper_dive_direction_test.gd
```

También pasan guardia/reacción/pausa/reset, contacto de patada, movimiento/suelo, respuesta manual, cuatro ángulos del rival y balance de trece tiros. Se revisaron las capturas alta/media/baja, alta al lado opuesto y vistas frontal/trasera.

Tres expectativas anteriores exigían que el apoyo también se extendiera hacia el tiro por delante de la cabeza. Se sustituyeron por el rol de rechazo con una mano: apoyo bajo y junto a su propio hombro. Los umbrales de alcance principal, alturas, reacción, pausa, suelo y cruces se mantienen. Los checks de apoyo de la variante baja conservan su alcance anterior.

## Capturas

- Vista real de atajada: [alta antes](capturas/defensa-alta-antes.png), [alta después](capturas/defensa-alta-despues.png), [alta izquierda](capturas/defensa-alta-izquierda.png), [media](capturas/defensa-media-despues.png), [baja antes](capturas/defensa-baja-antes.png), [baja después](capturas/defensa-baja-despues.png).
- Recortes ampliados de esa misma cámara: [manos antes](capturas/manos-defensa-antes.png), [manos después](capturas/manos-defensa-despues.png), [baja](capturas/manos-defensa-baja.png).
- Vista frontal de inspección: [alta](capturas/frente-alta-despues.png), [baja](capturas/frente-baja-despues.png).

`tools/capture_animation_sequence.gd` acepta `defense` para llamar a `start_defense()` y conservar la cámara de gameplay. `hands` amplía un recorte de brazos ya renderizado, sin cambiar el ángulo ni la pose; sus píxeles ampliados no representan una mayor resolución de la malla.

## Límite del asset

Los guantes siguen siendo rígidos, sin pesos de dedos. La corrección modifica brazos y orientación de muñecas; no añade articulación individual de falanges. Las irregularidades de mangas pertenecen al skinning original. La mejora se verificó en las poses y vistas indicadas; no equivale a utilizar mocap de FC.
