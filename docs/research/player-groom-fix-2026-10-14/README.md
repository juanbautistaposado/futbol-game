# Corrección del pelo y la barba

El pelo retenido de la cabeza anterior penetraba la nueva superficie en la
nuca. Se ajustaron la malla del peinado y sus fibras por encima del cráneo,
conservando el volumen superior. Se suavizó el borde dentado de la nuca.

La barba anterior se reemplazó por 12 000 fibras cortas y finas distribuidas
sobre la cara actual, orientadas hacia abajo y hacia los lados en el bigote.
La cobertura del material comparte la distribución de las raíces y se guarda
en los vértices para acompañar la animación. Se redujo el pigmento oscuro bajo
las fibras para dejar piel visible entre los pelos, evitando el aspecto de
una mancha pintada. El bigote respeta labios, nariz, orejas y cuello.

Aplicado al delantero y al arquero. El selector de barba y los colores de pelo
y piel siguen funcionando.

## Capturas del juego

Mismo personaje, cámara, pose y luces. Capturas directas de Godot, sin retoque.

| Vista | Antes | Después |
| --- | --- | --- |
| Nuca | [Antes](before/nape.png) | [Después](after/nape.png) |
| Rostro | [Antes](before/face.png) | [Después](after/face.png) |
| Perfil | [Antes](before/profile.png) | [Después](after/profile.png) |
| Perfil izquierdo | [Antes](before/left_profile.png) | [Después](after/left_profile.png) |
| Tres cuartos trasero | [Antes](before/rear_quarter.png) | [Después](after/rear_quarter.png) |

[Barba en el editor](editor/beard.png) · [Sin barba](editor/clean.png).

## Verificación

- 525 rayos sobre la nuca por modelo: cobertura completa, separación mínima
  entre piel y pelo de 1,26 mm.
- Las 12 000 raíces de barba por modelo quedan a unos 0,12 mm de la piel.
- Cabeza, ojos y cejas conservan exactamente posiciones, normales, UV y pesos.
  Cuerpo y prendas conservan posiciones, UV y pesos; 53 huesos y ocho clips
  permanecen idénticos a los originales.
- Seis pruebas aprobadas: personalización, delantero, arquero, sus animaciones
  y editor. Se verificaron nueve tonos de piel y activación de barba mediante
  capturas nativas. Véanse [tests.json](tests.json),
  [geometry-checks.json](geometry-checks.json) y
  [appearance-checks.txt](appearance-checks.txt).
- 305 413 / 305 417 triángulos antes de LOD, 10 / 11 superficies. La barba usa
  72 000 triángulos en lugar de los 41 400 anteriores. La medición nativa de
  nueve avatares está en [performance.json](performance.json); no mide móvil
  ni Web. En Apple M4, Godot Compatibility a 1280 × 720: 24,70 ms promedio,
  25,57 ms p95 y 25,84 ms máximo en 240 cuadros, con 90 llamadas de dibujo.

## Reconstrucción

`tools/rebuild_player_head.py` invoca `tools/fit_player_groom.py` y parte siempre
de los archivos `_realism.blend`; no acumula deformaciones sobre el resultado.
Los editables finales son `source-assets/footballer/meshy_*_head.blend`.
No se reemplazó el atlas facial ni se incorporaron recursos externos.

```sh
blender -b --factory-startup --python apps/free-kick-3d/tools/rebuild_player_head.py -- striker keeper
godot --headless --editor --path apps/free-kick-3d --quit
python3 apps/free-kick-3d/tools/audit_player_head.py /ruta/a/baseline
blender -b --factory-startup --python apps/free-kick-3d/tools/audit_player_groom.py -- /ruta/a/baseline
```

El baseline de la última auditoría fue una copia de los GLB inmediatamente
anteriores a esta corrección. `audit_player_groom.py` necesita ese estado de la
cabeza reconstruida para comprobar que su anatomía permanece intacta.
