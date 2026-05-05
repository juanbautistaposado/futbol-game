# Tiros Libres MVP

Juego web de tiros libres inspirado en Football Strike, construido con Vite, TypeScript y Phaser.

El objetivo del MVP es una experiencia simple y jugable: 7 tiros por ronda, control con mouse, arquero reactivo, delantero con camiseta numero 9, puntaje gol/no gol y mejor marca guardada en el navegador.

## Caracteristicas

- Juego single-player en navegador.
- Rondas de 7 tiros libres.
- Control por arrastrar y soltar desde la pelota.
- Potencia y direccion limitadas para mantener tiros jugables.
- Arquero con movimiento idle, reaccion rapida, estiradas altas y posibilidad de elegir mal el lado.
- Delantero numero 9 con animacion de patada.
- Resultado por tiro: gol, atajada o fuera.
- Mejor puntaje guardado con `localStorage`.
- Graficos 2D simples con falsa profundidad.

## Requisitos

- Node.js 22 o compatible.
- npm.

## Instalacion

```bash
npm install
```

## Desarrollo

```bash
npm run dev
```

Luego abrir:

```txt
http://localhost:5173/
```

## Build

```bash
npm run build
```

El build de produccion se genera en `dist/`.

Para previsualizar el build:

```bash
npm run preview
```

## Deploy En Vercel

El proyecto incluye `vercel.json`, por lo que Vercel usa:

- Build command: `npm run build`
- Output directory: `dist`
- Framework: `vite`

Publicacion con Vercel CLI:

```bash
npx vercel login
npx vercel
npx vercel --prod
```

## Deploy En GitHub Pages

El proyecto incluye un workflow en `.github/workflows/deploy-pages.yml`.

Para publicarlo:

1. Crear un repositorio en GitHub.
2. Subir este proyecto al repositorio.
3. En GitHub, ir a `Settings > Pages`.
4. En `Build and deployment`, elegir `Source: GitHub Actions`.
5. Hacer push a la rama `main`.

GitHub Actions va a ejecutar:

```bash
npm ci
npm run build
```

Luego publica el contenido de `dist/` en GitHub Pages.

La configuracion actual de Vite usa `base: "/"`, por lo que GitHub Pages debe publicarse desde una URL raiz o dominio propio. Si se publica como project page bajo `/nombre-del-repo/`, hay que ajustar `base` antes del build.

La URL final va a tener este formato:

```txt
https://tu-usuario.github.io/nombre-del-repo/
```

## Estructura

```txt
src/
  main.ts
  storage.ts
  types.ts
  scenes/
    BootScene.ts
    MenuScene.ts
    GameScene.ts
    ResultScene.ts
```

## Notas

- No hay backend ni cuentas de usuario.
- No hay multiplayer online en este MVP.
- Phaser genera un bundle relativamente grande; Vite puede mostrar un warning de chunk size, pero no bloquea el build.
