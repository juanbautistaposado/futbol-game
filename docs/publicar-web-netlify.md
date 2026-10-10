# Publicar Tiros Libres 3D en Netlify

## Flujo preparado

La versión web se exporta **localmente con Godot** y después se sube como sitio
estático. Netlify no necesita ejecutar Godot para este flujo. No se configuró
publicación automática desde Git: el entorno de build de Netlify no trae nuestro
motor ni sus plantillas configurados, y el directorio generado está ignorado en Git.

El preset `Web` usa un solo hilo, sin GDExtensions ni PWA. No requiere headers
COOP/COEP. Las texturas se preparan para escritorio y móvil; el rendimiento y audio
en celulares todavía deben comprobarse en dispositivos reales.

La configuración está en `netlify.toml`, el preset en
`apps/free-kick-3d/export_presets.cfg` y los headers en
`apps/free-kick-3d/web/_headers`. El preset parte del
[preset oficial de las demos de Godot](https://github.com/godotengine/godot-demo-projects/blob/master/.github/dist/export_presets.cfg).

## 1. Exportar

Requiere Godot y las plantillas de exportación de su **misma versión exacta**.
En esta máquina se verificó Godot 4.7.1 y se instalaron sus plantillas web oficiales.
En otra máquina: Editor → Administrar plantillas de exportación → instalar la
versión correspondiente. La plantilla no se guarda en este repositorio.

Desde la raíz del repositorio:

```sh
bash scripts/export-web.sh
```

Si Godot no está en PATH:

```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot bash scripts/export-web.sh
```

El resultado está en `apps/free-kick-3d/build/web/`. El script importa recursos,
exporta en release, verifica HTML/JS/WASM/PCK y copia `_headers`.
No incluir las fuentes del juego, los archivos de Blender ni credenciales al subir.

## 2. Probar localmente

```sh
python3 -m http.server 8765 --bind 127.0.0.1 --directory apps/free-kick-3d/build/web
```

Abrir [la vista local](http://127.0.0.1:8765). No abrir `index.html` mediante `file://`.

El 3 de octubre de 2026 se verificaron exportación release, carga del menú,
configuración de ronda e inicio de la escena de partido en el navegador integrado,
sin errores ni advertencias de consola. Esto es una prueba básica de carga, no una
validación completa de jugabilidad, audio, guardado, Safari ni móviles.

Build medido: aproximadamente **53 MiB** en disco, `index.pck` **14,48 MiB** y
`index.wasm` **37,68 MiB**. El tamaño transferido puede ser menor con compresión HTTP.
El WASM supera los 25 MiB por archivo de Cloudflare Pages; no subir este build allí
sin adaptar su distribución. Para Netlify se recomienda CLI por el tamaño de los
archivos, en vez de arrastrar la carpeta al panel.

## 3. Vincular la cuenta y el proyecto

La CLI se puede ejecutar sin instalación global:

```sh
npx --yes netlify-cli login
npx --yes netlify-cli status
```

Completar el acceso en el navegador con la cuenta de Netlify. No pegar tokens en
el chat ni guardarlos en el repositorio.

Para un proyecto ya existente:

```sh
npx --yes netlify-cli link
```

Para crear uno desde la CLI:

```sh
npx --yes netlify-cli sites:create
```

Elegir la cuenta/equipo y el nombre del sitio. Comprobar luego `status` y, si el
proyecto aún no quedó vinculado, ejecutar `link`. Usar el plan Free. El estado local
de vinculación vive en `.netlify/`, que está ignorado en Git.

## 4. Subir una versión de prueba

Después de exportar, desde la raíz del repositorio:

```sh
npx --yes netlify-cli deploy --no-build --dir apps/free-kick-3d/build/web
```

La CLI devuelve una URL de borrador. Probar allí carga, tiros/atajadas, sonido,
pausa, guardado y móviles antes de publicar en la URL principal.

Los proyectos nuevos pueden quedar **privados por defecto**: Netlify pide acceso
con una cuenta del equipo para abrir el borrador. Subir archivos no habilita por
sí solo el acceso público.

## 5. Publicar en la URL principal

```sh
npx --yes netlify-cli deploy --prod --no-build --dir apps/free-kick-3d/build/web
```

Si el proyecto sigue marcado como Private, abrir su panel y completar **Make
public** para habilitar el acceso público. Verificar después desde un navegador
sin sesión de Netlify. No confundir un deploy en producción con la visibilidad
pública del proyecto.

Para actualizar: repetir exportación, borrador y publicación en producción. El
subdominio `netlify.app` permite empezar sin comprar un dominio.

Netlify Free ofrece 300 créditos mensuales: actualmente cada publicación de
producción consume 15, la transferencia 20 por GB y las solicitudes 2 por cada
10.000. Los borradores no consumen créditos de publicación, pero su tráfico sí.
Al agotar el límite se pausan los proyectos de la cuenta; Free no genera cargos
por exceso. Revisar consumo en el panel.

## Skill opcional

Existe `netlify-deploy` en el repositorio de skills de OpenAI. Ayuda con login,
vinculación y despliegue usando la CLI; no reemplaza la exportación Godot ni la
cuenta de Netlify. No hace falta instalarla para ejecutar estos comandos.

```sh
npx skills add https://github.com/openai/skills --skill netlify-deploy
```

La búsqueda en el catálogo de plugins disponible no devolvió un plugin Netlify;
ese resultado no demuestra que no exista en otros catálogos.

## Referencias

- [Godot: exportar para web](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).
- [Netlify: deploy y sus flags](https://cli.netlify.com/commands/deploy/).
- [Netlify: configuración por archivo](https://docs.netlify.com/build/configure-builds/file-based-configuration/).
- [Netlify: agregar proyectos y límites de carga manual](https://docs.netlify.com/manage/projects/add-new-project/).
- [Netlify: precios actuales](https://www.netlify.com/pricing/).
- [OpenAI: skill netlify-deploy](https://github.com/openai/skills/tree/main/skills/.curated/netlify-deploy).

## Primera carga verificada — 3 de octubre de 2026

- Proyecto creado y vinculado: `futbol-tiros-libres-3d`, en el equipo Free.
- [Vista previa privada](https://6ac190eabba1b66a8cb19460--futbol-tiros-libres-3d.netlify.app).
- [Panel del proyecto](https://app.netlify.com/projects/futbol-tiros-libres-3d).
- Se regeneró el build con los cambios actuales y se subió como borrador.
- En Chrome con la sesión del equipo: menú, configuración de ronda e inicio del
  partido cargaron sin errores ni advertencias de consola.
- No se habilitó acceso público ni se hizo deploy de producción.

## Publicación pública — 3 de octubre de 2026

- [Jugar en la URL pública](https://futbol-tiros-libres-3d.netlify.app/).
- Deploy de producción: `6ac194ce7f1d78996346e1fd`.
- Se habilitó **Make public** para el sitio de producción; los previews siguen
  privados para el equipo.
- Se comprobó que el menú carga en el navegador integrado sin sesión de Netlify.

## Identidad de la carga web

La exportación usa `web/loading.html`, basado en el shell oficial de Godot 4.7.1,
con mensajes de carga en español y porcentaje de descarga. Al completar la
descarga muestra “Preparando la cancha…” hasta que el motor inicia.
`web/splash.png` reemplaza el splash predeterminado y `web/icon.png` reemplaza el
favicon. La precarga usa el logo raster aprobado, la tipografía Archivo y la
paleta ciruela, azul, crema, naranja y amarillo del menú. El ícono usa el monograma
TL de la misma identidad. El script de exportación copia Archivo y `favicon.ico`
al directorio publicado.
Estos archivos se conservan fuera del build para que sobrevivan nuevas
exportaciones. Se verificó la carga completa con una descarga local ralentizada.

## Actualización del personaje — 3 de octubre de 2026

- Se exportó y publicó el estado actual del juego con las correcciones del short,
  las mangas y el pecho del personaje.
- Deploy de producción: `6ac1a1b0420f2b847a129fc2`.
- Se verificaron menú e inicio del partido en el build web local, sin errores ni
  advertencias de consola, y la carga del menú en la URL pública sin sesión.
- El `index.pck` público coincide con el build local: SHA-256
  `1d7962d10d77ba4f5dacf2746b4a5e0a02d5ed9d8ba49260b1710beddcf18537`.

## Actualización de interfaz — 4 de octubre de 2026

- Publicación de producción: `6ac2ab7f4f0d6a3c911416e3`.
- [Jugar en la URL pública](https://futbol-tiros-libres-3d.netlify.app/).
- Incluye la home compacta con logo y botones Jugar/Configurar rasterizados,
  bordes suavizados, precarga renovada e ícono TL.
- Se verificaron en la URL pública, sin sesión de Netlify, la carga de la home,
  configuración de ronda e inicio del partido. Evidencia visual en
  `docs/design/publicacion-2026-10-04/home-publica.jpg` y `partido-publico.jpg`.
- HTML, PCK, splash, ícono, fuente Archivo y favicon respondieron HTTP 200 y sus
  SHA-256 coinciden con el build local probado. SHA-256 del PCK:
  `b0f33406406e61e8b4b0b77aa538f87726c12f33ad1eb9107d35abf37f839b53`.
- La consola registró un TypeError de `MutationObserver.observe` sin URL de
  origen. La home y el partido cargaron; no se determinó el origen del error.
  La página también incluye el badge público que Netlify agrega al sitio.
- Esta comprobación cubre carga y navegación; no es una prueba completa de
  jugabilidad ni de dispositivos móviles.

## Corrección de bordes en configuración — 4 de octubre de 2026

- Deploy de producción: `6ac2b760ce110e1732a50a15`.
- Los paneles y franjas de selección, personalización, ajustes y preparación
  llegan hasta los bordes reales del viewport, incluso en formatos anchos o 4:3.
- Capturas nativas de las seis pantallas a 1920×984 y 1280×960; `menu_flow` pasa.
  Exportación release completada sin errores de scripts.
- Se verificó Configurar → ajustes → selección de delantero en la URL pública.
  Evidencia: `docs/design/ui-config-bordes-2026-10-04/striker-publico.jpg`.
- El PCK público responde HTTP 200 y coincide con el exportado: SHA-256
  `e19286b436e4a70e477fcae85845c46317a3674462fbf2b443a1ab77b419ba21`.

## Camiseta, segunda pasada publicada — 4 de octubre de 2026

- Producción: `6ac2d8108f9d43b21a1bf318`.
- [URL pública](https://futbol-tiros-libres-3d.netlify.app/).
- Build release regenerado con el estado actual del workspace y las mejoras de
  hombros, axilas, mangas y pliegues de la camiseta del jugador.
- Menú verificado en navegador sin sesión de Netlify. La consola del navegador
  registró un error JavaScript de `MutationObserver.observe` sin URL de origen;
  el menú y el personaje cargaron. No se atribuye ese error al juego sin diagnóstico.
- El paquete público coincide con el local: SHA-256 de `index.pck`
  `12f248943a2d4e22c831573aea22664ef0e19ab45e67c30100a5c5cdaca5eee5`.

## Proporciones y uniforme de todos los jugadores — 4 de octubre de 2026

- Producción: `6ac2e9528e8115336c77b8e3`.
- [URL pública](https://futbol-tiros-libres-3d.netlify.app/).
- Incluye pecho reducido, piernas reforzadas y las mejoras de camiseta, short
  y mangas en jugadores de campo y arqueros, incluidos los personalizados.
- Exportación release completada sin errores de scripts. El menú público y su
  personaje cargaron en el navegador.
- El paquete público descargado coincide con el build local: SHA-256 de
  `index.pck`:
  `e507ad87a154e6c13916a7a1adf3724f2259fecced4d85b312e64625b8bbd019`.
