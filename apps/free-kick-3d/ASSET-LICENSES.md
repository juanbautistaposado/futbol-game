# Registro de assets — vertical slice

| Asset | Origen | Licencia / atribución | Estado |
| --- | --- | --- | --- |
| Cancha, arcos, pelota y arqueros | Primitivas de Godot generadas por `main.gd` | Código propio del proyecto | Prototipo |
| Materiales e iluminación | Configuración de `main.gd` | Código propio del proyecto | Prototipo |

No se distribuyen modelos, texturas, animaciones ni audio de terceros en esta primera entrega. Cada asset externo que sustituya a un placeholder debe añadirse a esta tabla antes de incorporarse al build.

## Personajes de fútbol

`footballer_model.gd` y `shaders/kit.gdshader`: mallas anatómicas por contornos,
rostros, cabello, barba, ropa y materiales procedurales originales del proyecto.
Sin modelos ni texturas de terceros. El arquero rotulado DONNARUMMA es una
aproximación estilizada, no un escaneo ni un modelo oficial del deportista.
Mateo, Bruno y Nicolás son personajes ficticios. Estado: prototipo visual;
no equivalen a personajes humanos fotorealistas con texturas y rig de producción.

Referencia visual de proporciones y ropa: [Football Strike: Online Soccer Android Gameplay, DroidCheat](https://www.youtube.com/watch?v=iNOT5XGohM0). Las nuevas superficies suavizadas, uniformes y articulaciones de rodillas y codos son originales; no se extrajeron assets del video ni del juego.

## Modelos originales animados (opción B)

Los archivos `source-assets/footballer/footballer_original.blend` y
`goalkeeper_original.blend`, y sus exportaciones GLB en
`apps/free-kick-3d/assets/footballer/`, fueron generados desde cero por el
script propio `tools/build_original_footballer.py` en Blender. Geometría,
materiales, rig, guantes, barba opcional y clips Idle/Kick/Celebrate/Save/Catch
son originales de este proyecto, incluidas las nuevas estiradas bajas SaveLowLeft
y SaveLowRight. No se importaron modelos, animaciones ni
texturas de Football Strike ni de librerías externas. Las capturas y el video
del juego se usaron solo como referencia de estilo.

`source-assets/footballer/footballer_v2.blend` y `goalkeeper_v2.blend`, junto
con sus GLB en `apps/free-kick-3d/assets/footballer/`, derivan exclusivamente
del generador original del proyecto. Comparten cuerpo, cara y esqueleto; el
delantero se exporta antes de añadir guantes y poses de arquero. Ambos se usan
en la partida normal. Los materiales procedurales del
césped, la paleta de tribunas y la iluminación de `main.gd`,
`menu_background.gd` y `stadium.gd` también son código propio del proyecto.

# Audio original

Los efectos en `audio/kick.wav`, `save.wav`, `post.wav`, `net.wav`, `crowd.wav`
y `cheer.wav` fueron sintetizados para este proyecto mediante
`tools/generate_sfx.py`; no contienen grabaciones ni muestras de terceros.
`audio/goal_voice.wav` es una voz en español generada con la voz de sistema
Eddy (Español de México) de macOS para pronunciar «¡Gooooool!».
