# Auditoría técnica del audio actual

Fecha: 2026-10-01. Alcance: `apps/free-kick-3d`. Investigación, sin reemplazar audios ni editar código de juego.

## Método y límites

Se inspeccionaron `match_audio.gd`, `main.gd`, `tools/generate_sfx.py`, `tests/match_audio_test.gd`, `audio/*.wav.import`, README y ASSET-LICENSES. Se midieron los siete WAV con Python (`wave`, muestras PCM de 16 bits). Se consultaron documentación y código fuente oficiales de Godot. **No se escucharon los clips**: las conclusiones perceptuales son hipótesis apoyadas por síntesis, niveles y comportamiento del código, no una evaluación auditiva. El origen de la voz está documentado por el proyecto, no validado contra un proceso reproducible de generación.

## Hallazgos prioritarios

1. **El grito protagonista es texto a voz.** `ASSET-LICENSES.md` identifica `goal_voice.wav` como Eddy, español de México de macOS, diciendo «¡Gooooool!». `play_goal_cheer()` superpone esa voz a un festejo sintetizado. Ambos son mono y se reproducen iguales en cada gol. El archivo vocal se reproduce a -1 dB y el festejo a -15 dB: con los RMS medidos, la voz queda aproximadamente **18,2 dB por encima** de la celebración. Esto explica técnicamente por qué domina el componente que el usuario considera robótico. Recomendación: sustituir esa combinación por una reacción real de tribuna; un relato humano puede ser una capa opcional posterior.
2. **Hay un defecto de bucle verificable, independiente de la calidad de los assets.** El import de `crowd.wav` deja el bucle desactivado. El stream importado observado tiene `loop_begin=0`, `loop_end=0`; `_ready()` solamente cambia `loop_mode=LOOP_FORWARD`. En Godot 4.7.1, una reproducción temporal con ese estado estaba detenida tras 0,3 s, en posición 0. La misma prueba con `loop_end=264599` permanecía activa en posición ≈0,28 s. Por tanto, el ambiente no funciona como bucle continuo en este entorno. El test actual comprueba `playing` inmediatamente y no detecta que se detenga después de comenzar. Los límites de bucle se expresan en muestras, no en segundos. [AudioStreamWAV oficial](https://docs.godotengine.org/en/stable/classes/class_audiostreamwav.html), [implementación oficial 4.7](https://github.com/godotengine/godot/blob/4.7/scene/resources/audio_stream_wav.cpp).
3. **La tribuna no es una grabación.** El generador crea `crowd.wav` con cuatro senoidales de 87, 113, 159 y 197 Hz más ruido. `cheer.wav` mezcla 18 voces sintéticas de uno o dos armónicos, ruido filtrado y palmadas sintéticas. Una pista de ambiente grabada aporta complejidad vocal, espacio y eventos que estas fórmulas no contienen. Es una inferencia sobre naturalidad, pendiente de escucha A/B.
4. **Mezcla de festejo y ritmo de ronda desalineados.** La celebración dura 1,85 s y la voz 1,617 s; la ronda avanza normalmente a los 1,25 s. Pueden seguir sonando ya en el siguiente estado. Un festejo real más largo necesita una envolvente y política de transición deliberadas. El gol dispara la reacción al resolver el resultado, mientras el sonido de red llega 0,14 s más tarde con su animación. No hay que retrasar red/impactos arbitrariamente; sí separar reacción de público y caída al ambiente.

## Mediciones

Todos los archivos fuente son mono, 44.100 Hz, PCM de 16 bits. Pico y RMS calculados sobre las muestras originales; **RMS no equivale a LUFS**, y los valores no describen la mezcla final ni la atenuación 3D.

| Archivo | Duración | Pico dBFS | RMS dBFS | Ganancia del reproductor | RMS estimado antes de bus/3D |
|---|---:|---:|---:|---:|---:|
| kick.wav | 0,240 s | -2,70 | -16,41 | -3 dB | -19,41 |
| save.wav | 0,320 s | -4,84 | -18,65 | -3 dB | -21,65 |
| post.wav | 0,750 s | -3,38 | -19,47 | -3 dB | -22,47 |
| net.wav | 0,580 s | -11,16 | -26,54 | -3 dB | -29,54 |
| crowd.wav | 6,000 s | -16,76 | -27,92 | -15 dB | -42,92 |
| cheer.wav | 1,850 s | -8,96 | -21,76 | -15 dB | -36,76 |
| goal_voice.wav | 1,617 s | -5,00 | -17,59 | -1 dB | -18,59 |

El ajuste global predeterminado de 0,8 añade aproximadamente -1,94 dB a ambos buses. Al usar el mismo control no cambia el desequilibrio entre voz y tribuna. La suma de tamaño de los WAV es ≈982 KiB; el tamaño de fuente no mide memoria real de los imports comprimidos.

El generador aplica `tanh(x*1.3)*0.82` a todos los clips. Es una saturación uniforme y no garantiza loudness consistente entre sonidos. En `kick.wav` la primera muestra es ≈0,142 de amplitud, una discontinuidad potencial al arrancar desde silencio. Esto puede formar parte del golpe o producir un clic: requiere escucha antes de aplicar fades que debiliten el ataque.

## Qué ya funciona y qué falta

- Hay buses separados `Match SFX` y `Stadium`, un volumen persistente, variación de pitch 0,96–1,04 para efectos, sonidos 3D para contactos y limpieza de one-shots mediante `finished`. Son una base reutilizable.
- Cada impacto sólo tiene una toma. Cambiar pitch evita identidad exacta, pero conserva textura/envolvente. Gol y ambiente no tienen variación de toma.
- Captura y rechazo del arquero usan el mismo `save`; goles propios y del rival usan la misma celebración; no hay reacción específica a un remate fuera, expectativa o mala suerte en el palo. Decidir qué tiene sentido para una tribuna neutral antes de sumar capas.
- La posición de cada one-shot se fija al dispararlo; no sigue al balón. Es adecuado para un punto de contacto. Los cambios de cámara requieren comprobar la mezcla desde ataque y defensa.
- No hay ducking, limitación de voces simultáneas ni efectos de bus configurados en este módulo. **No se detectó clipping** por esta auditoría: habría que medir la mezcla final para afirmarlo. La limpieza al terminar ya evita acumular nodos sin fin.

## Plan de mejora concreto

### P0: corregir el ambiente y sacar la voz sintética dominante

- Preparar una escena A/B con la combinación actual y una reacción real de estadio sin relato.
- Configurar explícitamente el import y los límites del loop, o usar un stream de ambiente con loop configurado; validar actividad y posición durante más de dos ciclos.
- Seleccionar un ambiente de estadio estéreo de 30–90 s como rango de búsqueda y 3–5 festejos de 2–5 s. Son objetivos de diseño, no requisitos del motor.
- Hacer una unión de bucle con crossfade que mantenga energía. El generador actual cae a cero 0,3 s a cada lado, creando un valle periódico incluso si se corrige el bucle.
- Ajustar ganancias por oído y medición con espacio para impactos. No reutilizar automáticamente -15 dB con un asset distinto.

### P1: mejorar los contactos y la repetición

- Conseguir 3–5 tomas de patada/guantes y 2–3 de palo/red; grabar foley propio es una alternativa viable para contactos. Elegir toma evitando repetir inmediatamente, con variación moderada de pitch y ganancia.
- Distinguir guantes que sujetan de rechazo, y escalar intensidad del impacto con velocidad cuando la información ya esté disponible.
- Mantener mono los contactos espaciales y estéreo el ambiente/festejo global. Godot diferencia reproductores posicionales y globales. [AudioStreamPlayer oficial](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html).
- Implementar una envolvente de festejo: ataque rápido, cuerpo de reacción y caída suave al ambiente, compatible con transición de ronda. Limitar superposiciones de reacción para que varias acciones no acumulen ruido.
- Considerar buses `Ambience` y `Crowd Reaction`, conservando un único volumen global si ésa sigue siendo la UI deseada. Ducking pequeño del ambiente puede aclarar patada, palo y guantes; no procesar fuerte sin necesidad. Los buses permiten procesar y controlar categorías; el master debe quedar bajo 0 dBFS. [Buses oficiales](https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html).

### P2: validar experiencia y contrato

- Escuchar en auriculares y parlantes: 10 goles consecutivos, ataque y defensa, atajadas, palo, remate fuera, cambio de ronda, salida a menú y volumen 0/50/100%.
- Medir pico del master con todas las capas activas. Verificar que los contactos sigan legibles y que el ambiente no tenga silencios/cortes en la unión.
- Sustituir assertions que obligan a conservar `GoalCall` y duración exacta de 1,85 s por comportamiento: reacción presente, voz sintética eliminada si se decide así, limpieza de reproductores, loop continuo y volumen/mute persistentes. Esto es una actualización futura de contrato, no una modificación realizada.
- Si se incorpora Web, probar allí también. La documentación actual advierte que efectos de bus dependen del modo de reproducción Stream en Web y pueden aumentar latencia sin threads. [Limitación oficial de buses en Web](https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html).

## Verificación y procedencia

Se usó Godot `4.7.1.stable.official.a13da4feb` con scripts temporales en `/tmp`. La primera invocación falló al abrir su log de usuario; reintentar con `--log-file /tmp/...` permitió inspección y comparación. Apareció un error de certificados del sistema y en la comparación un aviso de dos objetos al salir: no invalidan los valores impresos, pero no se presenta esa ejecución como una validación auditiva ni como una suite completa aprobada.

No se regeneraron los WAV: el generador no produce `goal_voice.wav`, y ejecutarlo reemplaza todos los otros seis assets. Antes de incorporar sonidos externos habrá que actualizar `ASSET-LICENSES.md` con URL, autor, licencia y condiciones de uso. La ficha de fuentes/candidatos se investiga por separado.
