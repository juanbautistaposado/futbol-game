# Atleta v3: reconstrucción anatómica gratuita

## Dirección y alcance

Atleta adulto masculino de 1,90 m en el asset, proporciones deportivas moderadas,
rostro integrado, uniforme sencillo y superficies de tela, piel y goma distinguibles.
El juego conserva su escala visual adicional. La prioridad es silueta y deformación;
la personalización mantiene identidad independiente de delantero y arquero.

Fuentes editables: `footballer_v3.blend` y `goalkeeper_v3.blend`. Exportaciones:
`apps/free-kick-3d/assets/footballer/footballer_v3.glb` y `goalkeeper_v3.glb`.
Los anteriores v1/v2 permanecen disponibles como respaldo.

## Procedencia y licencia

- Herramienta: Blender y MPFB 2.0.17, repositorio
  https://github.com/makehumancommunity/mpfb2, revisión
  `afb9f530a7c2741dedb8df0ebae2e0b183caec21`.
- Base humana, targets y rig GameEngine: datos CC0 de MPFB/MakeHuman.
- Paquete oficial gratuito:
  https://files.makehumancommunity.org/asset_packs/makehuman_system_assets/makehuman_system_assets_cc0.zip
- Entradas utilizadas: `skins/young_caucasian_male/`, `eyes/low-poly/`,
  `eyes/materials/brown.mhmat`, `eyes/materials/brown_eye.png`,
  `eyebrows/eyebrow001/` y `hair/short04/`. Autor del paquete: `makehuman_system`, CC0.
- Piel: textura original adaptada a detalle neutral para permitir tintes y reducida a 1024².
- Uniforme, cabello corto, barba opcional, botines y guantes: geometría derivada de
  la base y trabajo propio del generador. La tela tiene mapas propios de 512². La barba corta usa briznas geométricas y el cabello combina un atlas CC0 adaptado a 1024² con raíz degradada.
- Los clips v2 originales del proyecto se adaptan al nuevo rig; no se descargaron animaciones.

Licencia completa de datos: [MPFB-CC0.txt](MPFB-CC0.txt). MPFB es una herramienta
GPL; su código no se distribuye en el juego. Referencias oficiales:
[licencia](https://static.makehumancommunity.org/about/license.html),
[paquete](https://static.makehumancommunity.org/assets/assetpacks/makehuman_system_assets.html),
[exportación](https://static.makehumancommunity.org/mpfb/docs/exporting/index.html).
Hashes de entradas y salidas: [athlete_v3_manifest.json](athlete_v3_manifest.json).

## Reconstrucción

Desde la raíz del repositorio, con Blender disponible:

```sh
git clone https://github.com/makehumancommunity/mpfb2.git /tmp/futbol-mpfb2
git -C /tmp/futbol-mpfb2 checkout afb9f530a7c2741dedb8df0ebae2e0b183caec21
# Descargar y extraer el paquete oficial CC0 en /tmp/futbol-system-assets.
blender -b --factory-startup --python apps/free-kick-3d/tools/build_footballer_v3.py -- /tmp/futbol-mpfb2 /tmp/futbol-system-assets
godot --headless --editor --path apps/free-kick-3d --quit
```

El generador carga MPFB para ese proceso, con estado temporal en `/tmp/futbol-mpfb-state`;
no instala la extensión ni cambia preferencias persistentes de Blender. También
puede editarse directamente el `.blend`; las imágenes están guardadas en las fuentes.

## Contrato técnico y verificación

Rig compartido de 53 huesos con nombres principales compatibles con el gameplay y
huesos de dedos. Clips: Idle, Kick, Celebrate, Catch, SaveLeft, SaveRight,
SaveLowLeft, SaveLowRight. Brazos adaptados con IK y horneados para mantener contacto.
La piel, los ojos y las briznas de barba son opacos; cejas y mechones de cabello usan recorte alfa.

El uniforme usa albedo, normal y roughness reales y UV secundarias reservadas
para nombre/dorsal. Cada avatar reutiliza sus materiales y su impresión en un
SubViewport al editar la identidad; los materiales no se comparten entre jugadores.
Texturas de ropa 512², piel y cabello 1024². La barba ya no usa una capa facial oscura. Objetivo medido: 60 FPS en PC;
la medición de un Mac concreto no garantiza rendimiento en otros equipos.

Pruebas aprobadas: anatomía/mapas/UV, personalización independiente, contacto de
patada y estirada, contacto de manos, balance de atajadas, rondas y ciclo tiro/arquero.
Los scripts de revisión visual son `preview_athlete_v3.gd` (estadio) y
`preview_athlete_neutral.gd` (frente, perfil y espalda sin estadio).

## Límites visuales

Esta v3 reemplaza la anatomía construida por primitivas. Es una base de producción
editable; no se declara acabado artístico final. Botines, detalle de costuras y expresividad facial siguen simplificados. Las variantes
actuales comparten la misma anatomía; no representan semejanzas faciales del deportista.
El aumento de geometría se registra en el manifiesto y se mide con el estadio completo.

## Correcciones tras la revisión del usuario

- Cuello de camiseta ajustado por rayos a la superficie anatómica real y sus pesos de rig;
  se conserva el cuello humano. La revisión del 3 de octubre restaura la piel visible,
  estrecha la abertura a un cuello redondo y conecta el ribete al borde real de la
  camiseta con posiciones y pesos compartidos. Se relaja la topología de hombros y
  se recalculan las normales del ribete. Capturas y medición actual:
  [v3-correcciones.md](../../docs/research/character-quality-2026-10-01/v3-correcciones.md).
- Pelo `short04` CC0 con mechones, atlas neutral para recolorear y recorte alfa en Godot;
  capa inferior con degradado lateral y canal de color activo comprobado por prueba.
- Barba corta construida con briznas de vello y labios despejados; no hay una malla
  transparente que oscurezca toda la mandíbula.
- Short reconstruido con cintura, unión de entrepierna y dos piernas; subdivisión
  y pesos propios para evitar el recorte irregular del cuerpo anterior.

### Revisión posterior del uniforme

El short se amplió y alargó, con entrepierna reforzada, dobladillos parejos,
pliegues suaves y UV secundarias para costuras/paneles tonales. Mangas y piel
comparten plano y pesos de unión; el bajo de la remera se ancla a la pelvis y
solapa con la cintura en la patada. Se limpiaron grupos auxiliares y pesos
inválidos de la fuente corporal. Evidencia y mediciones actuales:
[v3-pantalones-y-mangas.md](../../docs/research/character-quality-2026-10-01/v3-pantalones-y-mangas.md).

### Corte ajustado a la referencia del usuario

Short alargado 10,5 cm hasta cerca de la rodilla; mangas de 20,5 cm desde el
hombro del rig, más holgadas y de abertura recta. Borde de camiseta de 1 mm
hacia afuera, sin vuelta interior. Piel oculta y costuras ajustadas al nuevo
largo. Referencia, capturas y verificación:
[v3-corte-referencia.md](../../docs/research/character-quality-2026-10-01/v3-corte-referencia.md).

### Corrección secuencial según referencias Football Strike

Reemplaza el corte anterior: dobladillo a 0,715 m, entrepierna baja compartida
a 0,758 m, mangas de 15,8 cm con 12 mm de holgura sobre el brazo y transición
suave del hombro. Se regulariza el frente de camiseta y se retira piel interna
bajo el pecho. Cara, pelo, botines, paleta, escala, huesos y clips conservados.
Pasos, capturas y auditoría:
[v3-secuencia-short-mangas-pecho.md](../../docs/research/character-quality-2026-10-01/v3-secuencia-short-mangas-pecho.md).

### Camiseta deportiva del jugador — 4 de octubre

La etapa `tools/tailor_footballer_jersey.py` ajusta únicamente la camiseta del
jugador después de generar ambas bases. Conserva toda la geometría ajena a
`Jersey`, pesos, UV secundarias del dorsal, rig y clips. El arquero conserva su
exportación anterior. La etapa se ejecuta automáticamente al final del generador;
para iterar aisladamente se debe pasar una fuente base sin este ajuste, ya que
el script rechaza acumular modificaciones sobre una camiseta ya refinada.

Se añade caída en abdomen/bajo, puente suave sobre pectorales, mangas de sección
oval más uniforme, frente del cuello 17 mm más bajo, pliegues asimétricos y atlas
propio 512² con paneles tonales, ribete y detalle de tejido. El material sigue
siendo `Jersey` y conserva el color personalizable. Godot respeta la intensidad
de normales de la fuente en lugar de imponer un valor fijo a todos los mapas.

Fotos oficiales y modelos gratuitos se consultaron como referencia; no se
importaron meshes, texturas ni marcas externas. Investigación, capturas y
verificación: [camiseta-2026-10-04](../../docs/research/jersey-quality-2026-10-04/mejora-aplicada.md).

### Segunda pasada de camiseta: hombros y caída

Se reduce el volumen del hombro con transición gradual, se suaviza la axila y
se uniforma la sección de manga. Los pliegues largos en V se sustituyen por
pliegues cortos laterales y verticales junto al bajo, definidos una sola vez para
geometría y atlas. Se comprueba separación de tela sobre la piel superviviente
sin modificarla. Capturas, auditoría y pruebas:
[segunda-pasada/resultado.md](../../docs/research/jersey-quality-2026-10-04/segunda-pasada/resultado.md).

### Constitución atlética y correcciones localizadas

El generador incorpora las pasadas de short, suavizado de mangas y constitución
atlética, en ese orden, después de la camiseta. La última amplía torso superior,
brazos, muslos y pantorrillas alrededor de los ejes del rig existente, conserva
cara/botines/altura y adapta la ropa. Las UV, los pesos, los 53 huesos y ocho clips
se verifican tanto en fuente como en GLB. Investigación con tres agentes, medidas
y capturas: [constitución atlética](../../docs/research/athletic-character-2026-10-04/resultado.md).

La revisión posterior contiene el pecho y refuerza muslos/pantorrillas, adaptando
la holgura del short sin cambiar altura ni rig. Resultado y mediciones actuales:
[revisión de proporciones](../../docs/research/athletic-character-2026-10-04/revision-proporciones/resultado.md).

Las mismas pasadas se aplican también al arquero, con guantes protegidos, y a
todas las variantes/personalizados mediante sus dos modelos compartidos.
[Cobertura y verificación de toda la familia](../../docs/research/athletic-character-2026-10-04/todos-los-jugadores/resultado.md).
