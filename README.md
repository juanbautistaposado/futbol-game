# Fútbol — juegos de tiros libres

Este repositorio contiene dos aplicaciones independientes que comparten el mismo dominio de juego. La versión 3D es el desarrollo activo; el MVP Phaser se conserva como referencia jugable.

## Aplicaciones

| Aplicación | Ubicación | Tecnología | Estado |
| --- | --- | --- | --- |
| Tiros Libres 3D | [`apps/free-kick-3d`](./apps/free-kick-3d) | Godot 4 + GDScript | Desarrollo activo — Fase 1 |
| Tiros Libres MVP | [`apps/mvp-phaser`](./apps/mvp-phaser) | Phaser + TypeScript + Vite | Referencia 2D |

## Abrir el juego 3D

Abrí [`apps/free-kick-3d/project.godot`](./apps/free-kick-3d/project.godot) en Godot 4 y ejecutá el proyecto. Sus controles y alcance están en su [README](./apps/free-kick-3d/README.md).

## Ejecutar el MVP Phaser

```bash
cd apps/mvp-phaser
npm install
npm run dev
```

## Deploy del MVP

GitHub Pages ya compila `apps/mvp-phaser` desde el workflow del repositorio. Para Vercel, configurá `apps/mvp-phaser` como **Root Directory** del proyecto; allí están `package.json` y `vercel.json`.

## Publicar el 3D en web

Exportá la versión Godot con `bash scripts/export-web.sh`. Genera el sitio estático
en `apps/free-kick-3d/build/web/`, listo para una carga manual a Netlify.
La [guía de publicación](./docs/publicar-web-netlify.md) explica cómo probarlo,
vincular la cuenta y subir primero un borrador. Requiere Godot y sus plantillas de
exportación de la misma versión. El build se genera localmente; Netlify no tiene
builds automáticos por Git configurados para el 3D.

## Documentación compartida

- [Glosario del dominio](./CONTEXT.md)
- [Decisiones de arquitectura](./docs/adr/)
- [Hoja de ruta 3D](./docs/roadmap-3d.md)
