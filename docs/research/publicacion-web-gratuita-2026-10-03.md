# Publicación y distribución web gratuita de Tiros Libres

Fecha de consulta: 3 de octubre de 2026. Investigación basada en documentación oficial. No se modificó código, no se exportó ni se publicó el juego. Los precios y límites pueden cambiar.

## Recomendación

**Empezar con itch.io para la versión 3D**: reúne alojamiento, página del juego y descubrimiento en un mismo lugar. **Cloudflare Pages es la segunda opción para tener una URL independiente**, siempre que los archivos exportados entren en su límite de 25 MiB por archivo. Para compartir el MVP 2D, GitHub Pages tiene la integración más avanzada dentro de este repositorio.

Esta prioridad es una evaluación para nuestro caso, no una garantía de rendimiento ni de audiencia. Conviene comprobar primero la exportación web real del 3D: hoy falta ese artefacto, por lo que todavía no sabemos su peso final ni cómo funciona en móviles.

## Qué juego estamos publicando

El [README principal](../../README.md) identifica dos aplicaciones independientes:

- `apps/free-kick-3d`: desarrollo activo en Godot + GDScript. `project.godot` declara versión 4.7 y renderizador `gl_compatibility`. No se encontró un preset de exportación ni archivos `.wasm`/`.pck` listos para publicar.
- `apps/mvp-phaser`: referencia 2D en Phaser + TypeScript + Vite. Genera archivos estáticos en `dist/`. El workflow `.github/workflows/deploy-pages.yml` compila y publica **esta aplicación**, no la versión Godot.

El README del MVP dice que Vite utiliza `base: "/"`; el archivo actual `vite.config.ts` utiliza `base: "./"`. La documentación está desactualizada en ese punto. No se corrigió porque el pedido es investigar sin tocar código.

Los aproximadamente 26 MB de assets fuente del 3D no equivalen al peso del paquete exportado. No alcanzan para afirmar que Cloudflare lo aceptará o rechazará.

## Comparación

| Opción | Gratuidad y límites relevantes | Distribución y facilidad | Evaluación para este juego |
| --- | --- | --- | --- |
| **itch.io** | Publicar y alojar no tiene cargo. HTML5: hasta 500 MB extraídos, 200 MB por archivo y 1.000 archivos. | Subir ZIP con `index.html`; página propia, catálogo y comunidad. No exige publicar el código fuente. | Primera opción para el 3D y también válida para Phaser. |
| **Cloudflare Pages** | Plan Free: 500 builds/mes, 20.000 archivos y 25 MiB por archivo. Servicio estático con solicitudes y transferencia sin cuota publicada. | Carga manual o Git; URL `pages.dev`; admite headers. El público llega por los enlaces que compartamos. | Buena URL independiente, condicionada por los `.pck` y `.wasm`. |
| **GitHub Pages** | Con GitHub Free requiere repositorio público. Sitio de hasta 1 GB; transferencia con límite blando de 100 GB/mes. | Ya existe workflow para Phaser. Requiere administrar el repositorio y Pages. | Muy conveniente para el MVP; para Godot falta preparar exportación y publicación. |
| **Netlify Free** | 300 créditos/mes compartidos por uso. Al agotarlos se pausan los proyectos; el plan gratuito no genera sobrecostos. | Carga manual o Git, URL `netlify.app`, headers configurables. | Alternativa sencilla, menos generosa para juegos con descargas grandes. |
| **Vercel Hobby** | Gratis para uso personal no comercial. Incluye 100 GB de transferencia; límites propios de despliegue. | El MVP ya contiene `vercel.json`; URL `vercel.app`; configuración de raíz de proyecto. | Adecuada para demo personal, evitar como base si se proyecta monetización. |

Fuentes por fila: [itch.io: costos](https://itch.io/docs/creators/faq) y [HTML5](https://itch.io/docs/creators/html5); [Cloudflare: límites](https://developers.cloudflare.com/pages/platform/limits/) y [producto Pages](https://www.cloudflare.com/products/pages/); [GitHub: límites](https://docs.github.com/en/pages/getting-started-with-github-pages/github-pages-limits); [Netlify: planes actuales](https://docs.netlify.com/manage/accounts-and-billing/billing/billing-for-credit-based-plans/credit-based-pricing-plans/); [Vercel: planes](https://vercel.com/docs/plans) y [uso permitido](https://vercel.com/docs/limits/fair-use-guidelines).

Se puede mantener costo cero utilizando los subdominios del proveedor. Comprar un dominio propio es un gasto separado y no es necesario para empezar.

## Diferencias importantes

### itch.io: alojamiento y comunidad

Una página publicada no garantiza aparecer en el buscador ni recibir visitas: publicación e indexación son procesos separados. Es conveniente acompañar el juego con capturas, descripción, instrucciones y etiquetas apropiadas. [Guía oficial de indexación](https://itch.io/docs/creators/getting-indexed).

Los juegos HTML5 aceptan donaciones; no funcionan como un acceso web de pago obligatorio mediante la configuración normal. La plataforma permite distribuir contenido comercial y elegir qué porcentaje de las ventas darle a itch.io; cobrar puede implicar comisiones de los procesadores de pago. [HTML5 y pagos](https://itch.io/docs/creators/html5), [FAQ de creadores](https://itch.io/docs/creators/faq).

### Cloudflare Pages: revisar cada archivo del 3D

El límite de 25 MiB se aplica a cada archivo alojado, no al total del juego ni al ZIP. Un único `.pck` o `.wasm` grande puede bloquear la carga aunque el resto sea pequeño. La documentación sugiere R2 para archivos mayores, pero eso agrega otro servicio y configuración; no es nuestra ruta inicial más simple. [Límites oficiales](https://developers.cloudflare.com/pages/platform/limits/).

Permite subir una carpeta o ZIP desde el panel; un proyecto creado con Direct Upload no puede convertirse después a integración Git. La decisión inicial importa para las futuras actualizaciones. [Direct Upload](https://developers.cloudflare.com/pages/get-started/direct-upload/).

No encontramos en las páginas consultadas una condición de uso personal no comercial equivalente a Vercel Hobby; esto no sustituye revisar los términos aplicables si luego se monetiza.

### Netlify: el plan nuevo tiene créditos

No conviene usar reseñas antiguas que prometen 100 GB gratuitos para una cuenta nueva. El esquema actual consume 15 créditos por publicación en producción, 20 por GB transferido y 2 por cada 10.000 solicitudes. Las vistas previas y las publicaciones de ramas no consumen créditos de despliegue, pero sí tráfico. [Cómo se calculan los créditos](https://docs.netlify.com/manage/accounts-and-billing/billing/billing-for-credit-based-plans/how-credits-work/).

Ejemplo estimado: con cuatro publicaciones en producción quedan 240 créditos; alcanzarían para **menos de 12 GB** al descontar solicitudes y otros consumos. Es una cuenta orientativa, no capacidad garantizada. Cuando un proyecto supera el límite, se pausan todos los proyectos de la cuenta hasta el siguiente ciclo o una mejora de plan. [Precios actuales](https://www.netlify.com/pricing/).

Netlify declara que Free permite proyectos comerciales. Esa declaración está en el anuncio de 2024; sus cuotas antiguas fueron reemplazadas para planes nuevos por el esquema actual. [Anuncio oficial](https://www.netlify.com/blog/introducing-netlify-free-plan/).

### GitHub y Vercel: condiciones comerciales distintas

GitHub Pages es útil para una demo, pero sus reglas impiden usarlo como alojamiento gratuito para operar un negocio online, comercio electrónico o un sitio principalmente destinado a transacciones comerciales/SaaS. No extrapolarlo a una prohibición de cualquier proyecto comercial. [Reglas de Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/github-pages-limits).

Vercel sí restringe Hobby a uso personal no comercial; define uso comercial como un despliegue realizado para beneficio financiero de alguien involucrado, e incluye anuncios y otras formas de ingresos en sus ejemplos. Que el jugador no pague por entrar no demuestra por sí solo que la actividad sea no comercial. [Fair Use](https://vercel.com/docs/limits/fair-use-guidelines).

## Compatibilidad del 3D con navegador

Godot web requiere WebAssembly y WebGL 2.0; usa Compatibility. Desde Godot 4.3 la exportación de un solo hilo es la opción predeterminada y preferida para compatibilidad. Es el punto de partida razonable para este proyecto. Debe comprobarse rendimiento, audio y guardado; la exportación web móvil rinde menos que la nativa y el guardado en iframe puede depender de restricciones del navegador. [Exportación web de Godot](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).

Si se habilitan hilos, `SharedArrayBuffer` requiere HTTPS y aislamiento mediante `Cross-Origin-Opener-Policy: same-origin` y `Cross-Origin-Embedder-Policy: require-corp`. Cloudflare y Netlify permiten headers; itch.io ofrece una opción de SharedArrayBuffer. Godot también documenta un workaround con service worker al exportar como PWA; por ello no corresponde afirmar que Pages sea absolutamente incompatible con hilos. Para esta primera publicación conviene evitar esa complejidad. [Godot](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html), [Cloudflare headers](https://developers.cloudflare.com/pages/configuration/headers/), [Netlify headers](https://docs.netlify.com/manage/routing/headers/), [itch.io: soporte oficial](https://itch.io/t/2025776/experimental-sharedarraybuffer-support).

## Otros portales

**Newgrounds** acepta un ZIP HTML5 con `index.html` en la raíz, ofrece vista previa y somete las publicaciones a votación de la comunidad. Puede servir para una segunda distribución, una vez probado el juego. No se verificaron límites actuales de archivo ni soporte de aislamiento para hilos; no se promete compatibilidad de Godot sin probarlo. [Formato admitido](https://www.newgrounds.com/wiki/creator-resources/game-dev-resources), [publicación y evaluación](https://www.newgrounds.com/wiki/help-information/content-submission/games-and-movies).

**Game Jolt** se consideró, pero su [ayuda oficial](https://gamejolt.com/help-docs) no devolvió contenido legible durante esta investigación. Quedaron sin verificar sus límites actuales y condiciones concretas de hosting HTML5; no lo priorizamos sobre las alternativas comprobadas.

## Próximo paso posible, fuera de esta investigación

Preparar posteriormente una exportación Godot Web de un solo hilo con `index.html`, medir cada archivo y probarla en Chrome, Firefox y Safari, incluidos audio, controles táctiles y persistencia. Si funciona y entra en los límites de itch.io, publicar allí una página jugable; evaluar Cloudflare como enlace independiente cuando se conozca el peso real. Para una prueba inmediata del MVP, aprovechar su workflow de GitHub Pages existente, previa verificación de la configuración de Pages del repositorio.
