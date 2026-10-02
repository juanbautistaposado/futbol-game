# Rol 1 — Análisis visual de Football Strike

Consulta: **2026-09-23**. Investigación de referencias, sin extracción ni incorporación de assets.

## Conclusión

La referencia oficial es **realismo deportivo simplificado**, con colores vivos y lectura clara en móvil. No corresponde exactamente a personajes de polígonos visibles ni a un cartoon con contorno negro/cel shading fuerte. El usuario aclaró el **24/09/2026** que quiere acercarse al aspecto de Football Strike y no hacerlo más cartoon. La dirección revisada conserva anatomía atlética, superficies suaves, ropa deportiva con detalle y poses expresivas. No confundir Football Strike con Mini Football, otro juego de Miniclip.

## Observaciones verificables visualmente

Estas son interpretaciones de imágenes publicadas por Miniclip, no documentación del motor ni de sus assets.

1. **Proporciones:** anatomía adulta, cabeza relativamente natural, hombros definidos, cintura más estrecha, muslos y pantorrillas con volumen. No hay cabezas gigantes ni extremidades de palitos. Las capturas promocionales recortan cuerpos y usan perspectiva: no permiten medir una proporción exacta en “cabezas”. [Captura oficial de carrera, s/f](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_IPhone_05_EN.jpg).
2. **Cara y cabello:** nariz, mandíbula, labios y cejas legibles; cabello agrupado en formas grandes, barba como masa oscura definida. Hay diferencias de peinado y complexión. [Captura oficial de personalización, s/f](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_IPhone_04_EN.jpg).
3. **Superficies:** piel sombreada suavemente y camisetas con gradaciones, arrugas visibles y detalle de tejido. No se aprecian bandas duras de luz/sombra como requisito del estilo. La captura no permite distinguir cuánto viene de textura, normal map, geometría o iluminación. [Captura de carrera](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_IPhone_05_EN.jpg).
4. **Paleta:** blanco/azul/amarillo y rojo/negro o verde contrastan fuertemente con el césped. El color y los patrones separan equipos y roles. [Captura de personalización](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_IPhone_04_EN.jpg).
5. **Uniformes:** camiseta, pantalón corto, medias, botines y guantes forman bloques reconocibles. Ribetes, franjas y escudos organizan la superficie; las arrugas se concentran alrededor de cintura y pliegues de ropa. [Captura de carrera](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_IPhone_05_EN.jpg).
6. **Personalización:** delantero y arquero personalizables están confirmados por la descripción del desarrollador; eso no confirma que compartan internamente malla, rig o atlas. [Ficha oficial Google Play, actualización mostrada 2026-08-12](https://play.google.com/store/apps/details?hl=en&id=com.miniclip.footballstrike).

## Animación: observación frente a propuesta

El video aportado por el usuario es una referencia secundaria: [DroidCheat — Football Strike: Online Soccer Android Gameplay](https://www.youtube.com/watch?v=iNOT5XGohM0), fecha de publicación **no verificada**. En la sesión previa se inspeccionaron escenas de juego alrededor de 0:33–0:48, incluyendo arquero extendido en el aire y caída. En esta investigación la herramienta web no pudo recuperar el video; no se atribuyen a él medidas de rig, tiempos, técnicas ni licencias.

Para nuestra adaptación recomiendo: espera con rodillas flexionadas; carrera corta con transferencia de peso; pie de apoyo plantado, armado y seguimiento del disparo; atajada con anticipación, extensión, caída y recuperación; celebración de cuerpo completo con brazos y torso. **Es un conjunto de producción propuesto**, no un catálogo verificado de clips originales. Debe ser expresivo por pose y ritmo, sin depender de animación facial compleja.

## Datos que NO se pudieron verificar

- Cantidad real de polígonos/triángulos, huesos, influencias por vértice, LODs, resolución de texturas, draw calls y shader original: no publicados en las fuentes consultadas.
- No se puede inferir un conteo fiable por una captura: normales suavizadas, perspectiva y compresión ocultan la topología.
- Tampoco se confirmó uso de texturas pintadas a mano, PBR, cel shading, normal maps, mocap o un rig específico.

## Especificación propuesta para nuestro proyecto (estimación, no datos de Miniclip)

- Personaje inicial de **8.000–16.000 triángulos**, silueta suave y geometría concentrada en cara, hombros, rodillas y manos. Ajustar después del perfilado en el celular objetivo; no convertir este rango en garantía de rendimiento.
- Proporciones base de **7–7,5 cabezas**, modelar nariz, orejas y manos humanas simplificadas sin exagerarlas.
- Base de color de **1024²**, textura sutil de piel y tela y pliegues grandes; identidad del equipo por regiones recoloreables. Evitar poros y microdetalle que desaparece en pantalla.
- Sombreado suave, ropa mate y colores bien separados. Evitar toon y contorno como tratamiento predeterminado; no son necesarios para parecerse a esta referencia.
- Primer objetivo de aprobación: un jugador original completo visto de frente, espalda y perfil, más pose de tiro y atajada, en la cámara real del juego.

## Registro de fuentes

Todas consultadas **2026-09-23**. “s/f” significa sin fecha editorial visible; fecha de consulta no equivale a publicación.

| Fuente | Fecha | Uso / límite |
|---|---|---|
| [Página de Football Strike, Miniclip](https://www.miniclip.com/games/football-strike) | s/f | Fuente primaria que enlaza las capturas examinadas; no publica especificaciones técnicas. |
| [Captura oficial de carrera](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_IPhone_05_EN.jpg) | s/f | Inspección visual directa en navegador; imagen promocional, no prueba de rendimiento en móvil. |
| [Captura oficial de personalización](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_IPhone_04_EN.jpg) | s/f | Inspección visual directa de caras, pelo y uniformes. |
| [Ficha Google Play del desarrollador](https://play.google.com/store/apps/details?hl=en&id=com.miniclip.footballstrike) | Actualización indicada 2026-08-12 | Personalización de ambos roles; fecha de actualización de app, no de cada captura. |
| [Video aportado](https://www.youtube.com/watch?v=iNOT5XGohM0) | No verificada | Referencia secundaria observada en sesión previa; recuperación web actual fallida. |
