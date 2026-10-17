# Barba y expresión facial

La segunda revisión reemplaza el aspecto de sombra y puntos por **8 500 fibras
curvas, más largas y visibles**, distribuidas por mejillas, mentón y bigote. Las
puntas se afinan gradualmente, la orientación acompaña cada zona de la cara y
el color oscuro ya no está pintado como una mancha bajo la barba. El selector
de barba sigue mostrando y ocultando las fibras.

También se levantaron un poco los párpados superiores para que la mirada no
quede somnolienta, se abrió levemente el ancho de la mandíbula y se suavizaron
los extremos de la boca. Un nuevo movimiento de párpados cierra los ojos con
un parpadeo breve y asíncrono por jugador; no altera las animaciones de fútbol.

| Vista | Resultado |
| --- | --- |
| Barba de cerca | [Captura](final/beard_detail.png) |
| Frente | [Captura](final/face.png) |
| Perfil | [Captura](final/left_profile.png) |
| Parpadeo | [Captura](final/blink.png) |
| Editor de personaje | [Barba activada](editor/beard.png) · [Sin barba](editor/clean.png) |

Las capturas son del modelo final dentro de Godot, sin retoque. `geometry-checks.json`
registra separación entre barba y piel, cobertura de la nuca y apertura de los
párpados; `appearance-checks.txt` registra la revisión visual del editor. Se
conservan los ojos y sus globos oculares. La reconstrucción reproducible parte
de los archivos `_realism.blend`:

```sh
blender -b --factory-startup --python apps/free-kick-3d/tools/rebuild_player_head.py -- striker keeper
godot --headless --editor --path apps/free-kick-3d --quit
```

Los seis chequeos funcionales registrados están en [tests.json](tests.json).
La reconstrucción queda aplicada al delantero y al arquero.
