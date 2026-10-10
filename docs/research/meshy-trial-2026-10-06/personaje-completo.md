# PLAYER completo integrado localmente — 2026-10-06

**Actualización 2026-10-08:** la revisión actual de PLAYER añade un gesto de
brazos de tiro libre y una curvatura leve de dedos. Sólo cambian seis pistas
de rotación en Idle/Kick; el rig y los otros canales permanecen exactos.
Ver `../kick-arms-2026-10-08/aplicado.md`. Este informe describe la integración
inicial; `full-player-rig.json` registra la última revisión del asset.

El usuario pidió agregar el personaje completo de la referencia generada,
después de una integración anterior limitada al uniforme v4. PLAYER es ahora
una opción adicional en **Configurar → Elegir delantero**. Los delanteros
anteriores, el personalizado y los arqueros conservan sus modelos v4.

## Fuente y alcance

- Referencia recibida: `source-assets/footballer/references/meshy-player-user-reference.png`.
- GLB original: `source-assets/footballer/meshy-trial-2026-10-06/meshy-lite-raw.glb`.
- Modelo completo de Meshy 6 Lite, incluyendo cara, cabello, barba, piel,
  camiseta, short, medias y botines; no se sustituyeron por el cuerpo v3.
- Licencia CC BY 4.0, autor Meshy AI, atribución visible en Configurar → Créditos.
- Se reutilizó el ensayo de 20 créditos gratuitos: **costo adicional 0,
  nuevas generaciones 0, sin publicación en Meshy Community**.

La referencia es una imagen 2D. El modelo generado aproxima su diseño y no
reproduce cada detalle de esa imagen. No se importó el modelo de Football Strike.

## Adaptación y runtime

`tools/rig_meshy_player.py` normaliza la altura a 1.898873 m y alinea los
miembros del candidato con el rig existente. No cambia huesos, matrices de
reposo ni canales de animación. Transfiere pesos por superficie, ajusta brazos
y manos a sus cadenas y conserva como máximo cuatro influencias normalizadas.
La transición entre las regiones del antebrazo y la manga se superpone para
evitar estiramientos de triángulos; los límites excluyen torso y short.

Las posiciones coincidentes se sueldan sin perder las UV por esquina. Se
recalculan normales y se conserva el atlas original. Una segunda UV marca
únicamente la espalda para el nombre y número configurables. El material
reduce el brillo plástico sin recolorear el atlas. Se guardan el `.blend`
editable y el GLB con las tres texturas incluidas.

PLAYER usa el índice 4, separado de los tres presets y el personalizado (3).
`kicker.gd` reutiliza dos instancias para alternar con el rival durante la
defensa; solo una permanece visible y procesando animación. La opción elegida
se conserva al regresar al ataque.

## Validación

- `tools/audit_meshy_player.py`: 53 huesos, ocho clips y matrices de bind
  exactamente iguales a v3; 101904 triángulos, UV0 y UV2, pesos normalizados.
  Hash y métricas: `full-player-rig.json`.
- `tests/meshy_player_test.gd` con renderer nativo: selección persistente,
  modelo completo, mapas, dorsal editable, contacto de patada, restauración
  de PLAYER después de defensa y reutilización de avatares. PASS.
- Regresión: `athlete_v3_test`, `custom_players_test`, `menu_flow_test` y
  `kick_contact_and_dive_test`. PASS. El renderer dummy del menú headless
  emite advertencias de material nulo ya observadas en v4; se repitió el menú
  con renderer nativo y pasó sin esos errores. La prueba nativa del personaje
  también pasa sin esos errores.
- Capturas nativas del selector, frente, espalda, patada, celebración,
  pose A, perfil y estadio en este directorio.
- Rendimiento en Apple M4, Godot Compatibility, 1280×720 y sin vsync:
  bajo 126.2 FPS / p95 11.37 ms, medio 101.9 FPS / p95 12.08 ms, alto
  100.0 FPS / p95 12.63 ms. Se midieron 300 frames por perfil en el partido
  con PLAYER seleccionado y estiradas del arquero. Datos en
  `rendimiento-player-completo.json`; no confirma rendimiento web o móvil.

Esta integración queda local. No se realizó despliegue web ni publicación.
