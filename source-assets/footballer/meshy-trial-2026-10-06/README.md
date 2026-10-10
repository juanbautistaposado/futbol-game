# Meshy 6 Lite: prueba y adaptación

Una referencia propia creada con `imagegen`, una generación de malla y un texturizado en Meshy Free: 20 créditos, sin pago. El GLB original es una alternativa **estática**, sin rig, pesos, animaciones ni UV2. No es el asset del juego.

`manifest.json` registra procedencia, licencia, hashes y estado; `image-prompt.txt` contiene el prompt exacto de imagen y la configuración de Meshy. La captura Football Strike sirve únicamente como referencia visual. El GLB descargado se conserva sin editar como `meshy-lite-raw.glb`, bajo CC BY 4.0 con atribución a Meshy AI.

La comparación está en `docs/research/meshy-trial-2026-10-06/resultado.md`, con tres vistas y auditoría del archivo real. Merece una prueba de limpieza/adaptación: corregir primero la entrepierna del short; después materiales, topología y transferencia al rig original en una copia. No usar los scripts de tailoring de producción sobre este GLB.

La ropa ya tiene una adaptación **v4 integrada al juego local**, documentada en
`docs/research/meshy-trial-2026-10-06/integracion-aplicada.md`. Se retopologizó
sobre la ropa v3; conserva el cuerpo, el rig, los pesos, las UV y las animaciones.
`integration/` conserva las exportaciones candidatas; las copias activas están
en los assets del juego. La malla cruda original sigue intacta.

## Reproducir una captura

Desde la raíz del repositorio, reemplazar las rutas absolutas por las de la máquina:

```sh
godot --rendering-method gl_compatibility \
  --path source-assets/footballer/meshy-trial-2026-10-06/preview-project \
  --script compare.gd -- \
  /ABS/apps/free-kick-3d/assets/footballer/footballer_v3.glb \
  /ABS/source-assets/footballer/meshy-trial-2026-10-06/meshy-lite-raw.glb \
  /ABS/docs/research/meshy-trial-2026-10-06/comparacion-front.png front
```

Vistas: `front`, `back`, `profile`, `three_quarter`. Añadir `clay` como último argumento elimina los materiales para revisar forma. El proyecto no importa ni modifica assets del juego; carga los GLB externos en memoria. Uniforma altura y suelo únicamente en la escena de preview. `current_visual.gd` y los dos shaders son copias de producción tomadas el día de la prueba.

## Atribución si se incorpora

Modelo 3D generado con Meshy AI (Meshy 6 Lite), CC BY 4.0; referencia propia y adaptación para este proyecto. Conservar la licencia y documentar modificaciones. Añadir la atribución a los créditos/licencias de producción antes de publicar un derivado.

Fuentes: [Meshy Free](https://help.meshy.ai/en/articles/15696428-what-is-included-on-the-free-plan), [términos](https://www.meshy.ai/terms-of-use), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
