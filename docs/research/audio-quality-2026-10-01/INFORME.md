# Propuesta de mejora de audio

Investigación del 1 de octubre de 2026, realizada con tres agentes: fuentes de tribuna, fuentes de efectos y auditoría del sistema actual. Esta etapa reúne opciones y un plan; no incorpora assets ni cambia el juego. No se realizó escucha comparativa de los candidatos externos.

## Recomendación

Reemplazar la voz sintética del gol por una reacción real de tribuna, sobre una cama continua de estadio. Después renovar los impactos y sumar variantes. La prioridad es reconocer el contacto de la pelota y sentir la reacción colectiva sin que cada tiro repita exactamente el mismo sonido.

| Uso | Primera opción para probar | Evidencia y trabajo pendiente |
| --- | --- | --- |
| Gol | [Goal.wav, Sandermotions](https://freesound.org/people/Sandermotions/sounds/494352/) | Grabación de Cambuur; CC0; 14,781 s, estéreo. Escuchar y recortar ataque y cola. |
| Ambiente | [Soccer Stadium 10.wav, Sandermotions](https://freesound.org/people/Sandermotions/sounds/494360/) | Mismo autor/estadio; CC0; 156,305 s, estéreo. Elegir tramo y preparar unión sin salto. |
| Patada | [Ball Kicked #1044, Joseph Sardin](https://bigsoundbank.com/ball-kicked-s1044.html) | CC0; cinco patadas reales en 12 s, mono. Separar tomas y comparar a igual nivel. |

Las fichas verifican procedencia, formato y licencia, pero no garantizan que la grabación suene bien dentro del juego. Los dos sonidos de tribuna requieren cuenta en Freesound para descargar el original; BigSoundBank indica descarga sin cuenta. La procedencia compartida de los dos primeros sugiere coherencia acústica, todavía pendiente de escucha. Detalles y alternativas: [tribuna](01-tribuna.md), [efectos](02-efectos.md).

## Orden de trabajo propuesto

1. **Ambiente y gol:** probar las dos grabaciones CC0; retirar `GoalCall` de la reproducción habitual. Mantener el fondo discreto y dejar que el festejo suba de inmediato y caiga suavemente. Comprobar voces próximas, megafonía y música antes de elegir recortes.
2. **Continuidad del ambiente:** corregir y comprobar los límites del loop WAV actual o preparar un Ogg con loop explícito. El sistema debe sostener el ambiente durante el duelo y respetar volumen y pausa.
3. **Impactos:** extraer variantes de patada; evaluar un golpe de tubo para el poste; grabar pelota contra guantes y red si las bibliotecas no dan tomas adecuadas. Disparar cada sonido al contacto correspondiente, conservando la sincronización existente.
4. **Reacciones:** añadir una reacción corta de tribuna para palo/fuera y otra para atajada. El festejo largo debe caer antes de tapar el próximo tiro; contemplar que el cambio de turno actual llega a los 1,25 s.
5. **Mezcla:** conservar control global y ajustar por grupos, con margen para la suma de ambiente, festejo e impactos. Rotar muestras sin repetir inmediatamente; usar variación de pitch pequeña para impactos y evitar deformar la tribuna.
6. **Verificación:** escuchar varios turnos consecutivos con auriculares y parlantes, incluyendo gol rival, palo seguido de gol, atajada con rebote, pausa y silencio. Actualizar el test que exige `GoalCall` y la duración de 1,85 s del festejo: verificar el comportamiento nuevo, no conservar el placeholder por el test.

Los rangos de duración y mezcla son decisiones iniciales de diseño; deben ajustarse jugando. No hacen falta compras para probar la primera selección.

## Estado actual y límites

`ASSET-LICENSES.md` confirma que `goal_voice.wav` se generó con la voz Eddy de macOS y los seis efectos restantes con síntesis propia. `match_audio.gd` reproduce voz y festejo simultáneamente, con la voz a −1 dB y festejo a −15 dB; no son niveles de sonoridad medidos. El ambiente sintetizado dura seis segundos. La auditoría documenta además un problema de límites de loop y su reproducción en Godot: [auditoría técnica](03-auditoria.md).

Antes de integrar, registrar autor, URL, licencia y edición en `ASSET-LICENSES.md`. Para assets incluidos como archivos en el repositorio, CC0 resulta una primera ruta sencilla. Otras bibliotecas pueden permitir su inclusión en el juego terminado y restringir distribuir los WAV junto al código: no tratar ambos permisos como equivalentes. Por ejemplo, [la licencia vigente de Sonniss GDC](https://sonniss.com/gdc-bundle-license/) permite proyectos comerciales sin crédito pero restringe suministrar los efectos como tales; es una alternativa de producción, no la primera elección de assets redistribuibles.

## Informes de los agentes

- [Grabaciones de tribuna y ambiente](01-tribuna.md).
- [Patada, guantes, poste, red y otros efectos](02-efectos.md).
- [Auditoría de assets, mezcla, loop y eventos](03-auditoria.md).
