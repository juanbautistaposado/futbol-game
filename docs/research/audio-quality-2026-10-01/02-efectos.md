# Efectos de fútbol: candidatos y plan de selección

Investigación: 2026-10-01. Fuentes primarias: páginas del autor, fichas del distribuidor y textos de licencia. No se descargaron ni escucharon los archivos; la adecuación perceptual sigue pendiente de audición. Las prioridades y los tratamientos propuestos son criterio de diseño, no afirmaciones de los proveedores.

## Recomendación

Empezar por una patada real CC0 y un impacto de tubo CC0, incorporar reacción de ocasión perdida, y grabar guantes y red si la selección gratuita no convence. Esos sonidos pueden convivir con ambiente y festejos de tribuna reales, sin necesitar un locutor de gol. Evitar introducir pitidos o golpes sintéticos como sustitutos de una pelota física.

## Shortlist concreta

| Prioridad / evento | Candidato | Costo y licencia verificada | Motivo y trabajo pendiente |
| --- | --- | --- | --- |
| Alta / `kick` | [Ball Kicked #1044 — Joseph Sardin / BigSoundBank](https://bigsoundbank.com/ball-kicked-s1044.html) | Gratis; CC0; comercial y redistribución permitidos; sin crédito obligatorio. Sin cuenta. | Cinco patadas a una pelota de fútbol en un archivo de 12 s, mono, 48 kHz/16 bit. Recortar tomas limpias para crear un banco de variantes. Es el candidato más directo. |
| Alta / `post` | [Tube hit 08, high+ringing #435223 — dersinnsspace / Freesound](https://freesound.org/people/dersinnsspace/sounds/435223/) | Gratis; CC0, comercial permitido. Cuenta para descargar. | Grabación propia de un tubo metálico: WAV estéreo, 44,1 kHz/32 bit, 5,863 s. Audicionar si su resonancia resulta adecuada para un poste; recortar y reducir cola. No está grabado como pelota contra arco. |
| Media / fallo o atajada | [crowd oh - disappointed #619007 — mrrap4food / Freesound](https://freesound.org/people/mrrap4food/sounds/619007/) | Gratis; CC0, comercial permitido. Cuenta para descargar. | Reacción colectiva de decepción, 5,003 s, MP3 estéreo 44,1 kHz/135 kbps. La ficha la etiqueta como público/auditorio/teatro: probar integración con estadio; procedencia de grabación no detallada. Usar como candidato de audición, no afirmar que sea fútbol real. |
| Media / `save` | Grabación propia de pelota recibida y rechazada con guantes de arquero | Sin compra de licencia externa; costo de grabación depende de equipo y acceso. | No encontré una muestra gratuita de guantes suficientemente verificada en esta pasada. Grabar 6–10 tomas de recepción y de manotazo; mantener separados agarre y desvío. |
| Media / `net` | Grabación propia de pelota contra red | Sin compra de licencia externa; costo de grabación depende de equipo y acceso. | Buscar golpe suave y vibración de red, con contacto físico reconocible. No sobreacentuar: el festejo debe protagonizar el gol. |
| Baja / UI opcional | [UI Audio — Kenney](https://kenney.nl/assets/ui-audio) | Gratis; CC0; 50 archivos. Uso comercial sin crédito obligatorio confirmado en [soporte oficial](https://kenney.nl/support). | Seleccionar pocos clicks discretos para confirmar/cancelar. No incorporar todo el pack ni priorizar UI sobre la experiencia del remate. |

Para `post`, conservar ataque físico y resonancia breve; si suena a martillo industrial, descartar. Para `save`, un golpe acolchado corto debería contrastar con metal y red. Para el fallo, usar un “uh” breve de tribuna y volver al ambiente, con intensidad menor que la celebración de gol.

## Alternativas útiles con condiciones

**Mixkit: patadas listas para comparar.** [Soccer Sound Effects](https://mixkit.co/free-sound-effects/soccer/) contiene “Hitting soccer ball”, “Soccer ball quick kick” y “Soccer ball kick”, de aproximadamente 1 s. Gratis, sin crédito requerido según la [página oficial de SFX](https://mixkit.co/free-sound-effects/). Su [Sound Effects Free License](https://mixkit.co/license/modal/sfxFree/) permite proyectos comerciales y videojuegos, pero prohíbe redistribuir el material solo, como stock, en herramientas/plantillas o junto a archivos fuente. Por eso no elegirlos para commitear los WAV en un repositorio distribuido con código fuente; sí son candidatos para un producto final bajo esos términos. CC0 encaja mejor con el flujo actual del repo.

**344 SFX — UK Football: candidato pago para resolver el conjunto de foley.** La [ficha del distribuidor autorizado](https://www.asoundeffect.com/sound-library/uk-football/) identifica al licenciante y ofrece grabaciones de fútbol real: capturas del arquero, manotazos, golpes de guantes y una pelota que falla y pega en una jaula metálica, además de reacciones/ambiente. La ficha indica licencia royalty-free por usuarios; revisar el [acuerdo del distribuidor](https://www.asoundeffect.com/license-agreement/) antes de adquisición y distribución. El precio no se pudo verificar: la ficha depende de variantes dinámicas y devolvió un importe cero sin selección, que no es evidencia de gratuidad. No recomiendo presupuesto ni compra basados en ese importe. Es un candidato de audición si se prefiere un pack coherente a grabar por cuenta propia; confirmar qué variante trae el foley necesario.

**Red gratuita localizada, sin prioridad de adquisición.** [Soccer Ball In Net #264 — directory.audio](https://directory.audio/sound-effects/sports/264-soccer-ball-in-net) declara CC0 y ofrece un MP3 estéreo de 8 s a 44,1 kHz/320 kbps, subido por Yoo-toob-FX. El sitio no explica el proceso ni la autoría de grabación más allá del usuario que lo cargó. No lo considero tan confiable como las grabaciones propias documentadas; conservar como pista para seguir buscando al creador original, o reemplazar por grabación propia.

## Cómo pasar de candidatos a una mejora audible

1. Audicionar patadas y metal contra los actuales `kick.wav` y `post.wav` con volumen percibido parecido; elegir por identidad física y ausencia de ruido o cola excesivos.
2. Crear 3–5 variantes por efecto repetido, con selección que evite repetir inmediatamente la misma toma. La variación de pitch debe ser pequeña; no reemplaza un banco de tomas reales.
3. Separar impacto cercano y público: contacto de guantes en el momento de la atajada; reacción de la gente después. No reutilizar el festejo de gol como señal de fallo.
4. Mantener WAV mono para impactos que se espacialicen en 3D; conservar estéreo para público. Son decisiones de producción a verificar con el motor y la escucha.
5. Registrar URL, autor, licencia y fecha de cada muestra finalmente usada. Guardar licencia junto al asset, aunque CC0 no exija crédito.

## Relación con la implementación actual

[`match_audio.gd`](../../../apps/free-kick-3d/match_audio.gd) tiene una sola muestra para cada uno de `kick`, `save`, `post`, `net`; varía pitch entre 0,96 y 1,04. Los efectos salen por `Match SFX` en 3D. El público usa `Stadium`; al gol se superponen `cheer.wav` a −15 dB y `goal_voice.wav` a −1 dB. Ya existe una base para sustituir assets y sumar bancos: el siguiente paso debería ser primero elegir y escuchar grabaciones; luego ajustar mezcla y disparadores. No se modificó el juego en esta investigación.
