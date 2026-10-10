# Referencia visual: atleta Football Strike

Fecha: 2026-10-04. Skills aplicadas: `research` y `create-game-assets`, con sus criterios de silueta, escala real de juego y validación de malla/animación. Trabajo delegado; este informe no modifica el personaje.

## Fuentes primarias inspeccionadas

- [Página oficial de Football Strike, Miniclip](https://www.miniclip.com/games/football-strike): origen comprobado de las capturas oficiales siguientes.
- [Gameplay: delantero durante patada](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_iPhone_01_B_EN.jpg): vista posterior, brazos expuestos, caída de camiseta, short y medias. Inspeccionada visualmente en navegador.
- [Gameplay: arquero en estirada](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_iPhone_02_B_EN.jpg): continuidad de volumen y ropa en deformación. Inspeccionada visualmente.
- [Promoción de personalización](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_IPhone_04_EN.jpg): delantero frontal en tres cuartos; permite comparar hombro, brazo y transición a manga. Inspeccionada visualmente.
- [Promoción de carrera](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_IPhone_05_EN.jpg): delantero frontal con camiseta blanca, torso y short. Inspeccionada visualmente.
- Referencia entregada por el usuario: `codex-clipboard-65f6e6ae-70fd-4cee-b429-c487af39c2fc.png`, vista posterior en tres cuartos del delantero con camiseta blanca, laterales oscuros, `PLAYER 10` y short oscuro. Inspeccionada directamente.

Una búsqueda adicional de imágenes encontró material de terceros, pero no se usa para fundamentar proporciones ni descargar assets. Las imágenes oficiales se utilizan como referencia visual; no se incorporan sus texturas ni modelos al juego. No hace falta comprar ni descargar otro personaje para esta pasada.

## Lo observado y sus límites

En la imagen del usuario, el personaje ocupa aproximadamente 260 píxeles de altura visible; los pies están parcialmente recortados. Su espalda se lee ancha en la parte superior y se estrecha hacia la cintura. Hay volumen visible de brazo y antebrazo; las piernas mantienen masa incluso junto al short. La camiseta conserva holgura y pliegues, con mangas cortas que acompañan el brazo en vez de abrirse como un cilindro rígido. El `10` y `PLAYER` se leen desde la cámara de juego. Estas observaciones corresponden a esa captura, no a mediciones anatómicas ortográficas.

La [captura oficial del delantero pateando](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_iPhone_01_B_EN.jpg) confirma deltoides y brazos de volumen marcado, torso superior amplio y short suelto con ruedo cercano al medio muslo. Su cintura sigue siendo deportiva, sin un abdomen inflado. Los pliegues son grandes y direccionales: axila y cintura, con zonas lisas para el dorsal.

La [promoción frontal](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_IPhone_04_EN.jpg) muestra hombros redondeados, brazo superior firme y antebrazo lleno que se afina hacia la muñeca. La [camiseta blanca frontal](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_IPhone_05_EN.jpg) muestra pecho ancho pero sin separación exagerada entre pectorales, y ropa que no reproduce cada músculo del abdomen. La [estirada del arquero](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_iPhone_02_B_EN.jpg) sirve como comprobación de volumen en movimiento, aunque su uniforme y pose son distintos.

La perspectiva, el escorzo, la luz y la ropa impiden extraer las medidas 3D originales. No se puede verificar una reproducción geométricamente idéntica ni inferir la cara a partir de la imagen posterior. El objetivo verificable es una silueta comparable desde la misma cámara y una anatomía coherente en otras vistas.

## Propuesta de proporciones para la base existente

Los siguientes valores son **rangos iniciales de autoría inferidos**, no especificaciones publicadas de Football Strike. Aplicarlos en coordenadas locales por región, con transiciones suaves y simétricas. Conservar altura, articulaciones y longitudes de huesos.

| Región | Cambio inicial respecto a la base | Criterio visual |
|---|---:|---|
| Torso superior / dorsales | Ancho +6–10%; profundidad +5–8% | Espalda superior más sólida, caída gradual hacia cintura |
| Hombros / deltoides | Volumen radial +10–16% alrededor del eje del brazo | Hombro redondo integrado, sin meseta ni escalón |
| Bíceps / tríceps | Radio +15–22% en mitad proximal del brazo | Brazo firme, mantener axila y codo suaves |
| Antebrazo | Radio +10–16% proximal; reducir a 0% en muñeca | Masa deportiva que se afina hacia la mano |
| Muslo | Radio +10–14% en tercio superior/medio | Cuádriceps presentes sin ensanchar rodilla |
| Pantorrilla | Radio +8–12% en vientre; 0% junto a rodilla/tobillo | Pierna fuerte con tendón y articulaciones legibles |
| Cintura | 0–3% | Mantener contraste torso/cintura; evitar cuerpo ancho uniforme |
| Cabeza, cara, pelo, manos, botines | 0% | Preservar identidad y partes fuera del cambio |

Estos cambios deben ocurrir en la malla de piel y en la prenda correspondiente. Engrosar solamente la camiseta mantiene brazos delgados; engrosar solamente la piel causa intersecciones. La ropa debe conservar holgura moderada, mangas integradas y la entrepierna corregida. No acortar ni abrir de nuevo el short para acomodar el muslo.

## Materiales y lectura desde gameplay

- Conservar paleta existente. La referencia blanca/negra/dorado puede orientar el contraste, sin reemplazar colores actuales.
- Mantener `PLAYER 10` sobre un panel posterior suficientemente liso. La identificación se juzga al tamaño real de juego, no ampliada en Blender.
- Piel: iluminación amplia del deltoides y antebrazo; evitar líneas oscuras pintadas que simulen músculos y desaparezcan o parezcan manchas a distancia.
- Tela: normales y pliegues de escala media, limitados a axila, costado y bajo. Evitar una V central profunda o ruido uniforme; el dorsal necesita descanso visual.
- Evaluar de espalda, frente y perfil, en reposo y en patada. Comparar también con cámara posterior de gameplay y tamaño similar al de la captura, porque el escorzo influye mucho en la sensación de fuerza.

## Criterios de aceptación

1. Misma altura y contacto de pies, espalda superior más ancha y brazos/piernas más sólidos.
2. Rig, acciones, pesos y número de vértices conservados si la solución utiliza deformación de coordenadas; no asumir conservación solo por ver un render.
3. Cara, pelo y botines sin cambios; colores conservados.
4. Ninguna piel atravesando cuello, axila, pecho o short durante patada y celebración.
5. Mangas continúan suaves; short mantiene cintura única, ruedo de medio muslo y entrepierna baja.
6. Captura comparativa bajo misma cámara y luz, más una captura de gameplay que confirme lectura real.
