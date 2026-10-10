# Camiseta: referencias fotográficas y lectura visual

Fecha: 2026-10-04. Investigación de fuentes primarias. Las dimensiones sugeridas son objetivos de modelado propios, no medidas publicadas por fabricantes.

## Material revisado

- Render actual: `docs/research/character-quality-2026-10-01/v3-secuencia-final-frente.png` y `v3-secuencia-3-pecho.png`, inspeccionados visualmente.
- [Nike: National Federation Kits 2024](https://about.nike.com/en-GB/newsroom/collections/nikes-national-federation-kits-bring-dri-fit-adv-to-the-pitch). Fotos oficiales de Brasil (pecho, manga, jugador en movimiento) y Canadá (cuello, pecho, movimiento), vistas en navegador. Nike describe telas deportivas con ventilación por zonas, diseñadas para movilidad.
- [adidas: Real Madrid 2024/25](https://news.adidas.com/sports/adidas-and-real-madrid-reveal-white-home-kit-rooted-in-tradition-for-2024-25-season/S/6c62faf7-a3a5-4b7b-a66f-bb7858d5d548). Fotos oficiales del grupo masculino y Jude Bellingham, frente y espalda. Se revisó la foto grande del grupo. Fuente confirma cuello V, tela ligera, textura tejida y diferencia entre versión de cancha y de fan.
- [Real Madrid: presentación del kit 2024/25](https://www.realmadrid.com/en-US/news/football/first-team/latest-news/asi-es-la-nueva-camiseta-para-la-temporada-2024-25-05-06-2024). Galería complementaria y descripción oficial del cuello V y textura.
- [PUMA: kits nacionales 2024](https://www.about.puma.com/en/newsroom/product-and-brand-news/2024/28-03-2024-puma-launches-2024-national-team-home-away-kits). Fuente textual primaria: distingue tela ULTRAWEAVE ligera en auténticas y RE:FIBRE en réplica. El servidor devolvió 502 al abrir; no se usó como prueba visual.
- [Football Strike, Miniclip](https://www.miniclip.com/games/football-strike), con [captura oficial de personaje](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_IPhone_05_EN.jpg). Captura inspeccionada visualmente en navegador. La camisa blanca tiene cuello definido, paneles laterales, manga fina y pliegues grandes en abdomen/bajo que siguen siendo legibles en pantalla pequeña.

Se ejecutaron búsquedas de imágenes para Nike y adidas; el índice devolvió resultados vacíos. Se resolvió mediante las galerías fotográficas oficiales anteriores, sin descargar imágenes remotas ni incorporarlas al juego.

## Diagnóstico comparativo

Observaciones e inferencias visuales propias:

| Zona | Personaje actual | Referencia y objetivo |
| --- | --- | --- |
| Cuello | Azul continuo hasta la piel; abertura y ribete casi invisibles. Se lee como ropa pegada al cuello. | Abertura oval o V deportiva definida, con ribete estrecho visible. Nike Brasil muestra V suave; Canadá cuello redondo; adidas Madrid V. No hace falta agregar cuello de polo. |
| Hombro | Volumen redondo continuo que conserva lectura del deltoides; parece espuma/neopreno. | Prenda apoyada arriba del hombro, sección menos abultada y caída hacia manga. La construcción puede ser set-in o raglán; evitar escalón de piezas pero mantener plano textil legible. |
| Manga | Extremo con pequeña expansión hacia afuera; material se percibe grueso y sólido. | Tubo fino, ligeramente holgado, abertura oval perpendicular al brazo y borde discretísimo. Largo alrededor de medio bíceps. No campana, no borde doblado hacia adentro ni aro gordo. |
| Torso | Pecho suavizado, pero contorno todavía anatómico; cintura recta de cilindro y sin tela sobrante. | Tela puentea pectorales y cae desde pecho/hombros, conserva espacio en abdomen y flancos. El ajuste deportivo puede ser slim sin parecer piel pintada. |
| Bajo | Línea horizontal dura sobre cintura del short, totalmente regular. | Bajo algo separado, con 2–3 caídas suaves y pequeñas variaciones verticales. No cintura elástica de sudadera. |
| Pliegues | Muy pocos; ruido fino casi uniforme domina toda superficie. | Pliegues localizados por gravedad/tensión: axila diagonal, flanco oblicuo, abdomen bajo vertical/diagonal. Football Strike exagera esos pliegues para lectura móvil. |
| Material | Color azul liso con textura demasiado fina para comunicar construcción. | Tejido deportivo mate con reflejo suave; contraste tonal discreto en zonas/paneles. La estructura de tela depende de normales, roughness y pliegues, no solamente logos. |

## Cambios concretos recomendados

1. **Rehacer la silueta del torso como prenda**: usar curvas de sección propias con pecho limpio, laterales de caída más vertical y abdomen libre. Mantener volumen del cuerpo, añadir holgura inicial de 12–20 mm en pecho, 20–35 mm en abdomen/flanco; revisar de perfil. Son parámetros iniciales a ajustar visualmente, no medidas reales universales.
2. **Cuello visible y anatómico**: abertura oval con frente 20–30 mm más bajo que espalda, ribete fino 8–12 mm. Conservar piel del cuello visible y continuidad sin hueco. Mantener paleta usando un azul un poco más oscuro ya presente en el uniforme.
3. **Manga tubular**: soporte superior en hombro, axila más blanda, clearance 10–15 mm sobre brazo; abertura uniforme sin flare. Retener largo a medio bíceps y pesos graduales del hombro. Borde geométrico de 1–2 mm máximo, detalle textil por normal/roughness.
4. **Pliegues con causa**: 1–2 diagonales suaves por axila, 2 por lateral bajo, 2–3 verticales cortos en abdomen/bajo. Amplitud inicial 3–7 mm, longitud 5–14 cm; evitar patrón senoidal repetido o simetría perfecta. Centro del pecho permanece limpio. Referencia estilística: pliegues anchos de Football Strike, moderados respecto a su captura promocional.
5. **Material original**: microtejido en normal/roughness de baja intensidad, panel lateral tonal y ribete del cuello/cuff. Conservar azul actual. No copiar patrocinadores, logos de fabricantes, escudos o texturas fotográficas.
6. **Validación**: frente y perfil en A, espalda, pose de patada y brazos alzados. Confirmar continuidad axila/collar, ausencia de clip sobre pectorales, cuff sin colapso y apariencia de tela a distancia de juego. Comparar siempre en misma iluminación/cámara.

## Uso y licencias

Todas las fotos/capturas son **referencias visuales externas**, no assets licenciados para runtime. La presencia de botones de descarga no implica permiso para redistribuir fotografías o extraer texturas. Esta ruta produce geometría y mapas propios gratuitos, conserva el rig existente y no necesita reemplazar el cuerpo, cara, pelo, short o botines.
