# Rigging y animación: investigación actualizada

**Consulta e inspección: 2026-09-28.** V = verificado documentalmente o en archivos; R = propuesta de ingeniería, no prueba ejecutada. Esta inspección reemplaza el diagnóstico del 23-09 sobre ausencia de esqueletos: el repositorio avanzó.

## Estado real del proyecto (V local)

- `assets/footballer/footballer_original.glb` y `goalkeeper_original.glb` existen y son instanciados por `kicker.gd`/`keeper.gd`.
- Lectura de sus chunks JSON glTF: ambos tienen skin de **18 huesos**, nombres Root/Hips/Spine/Chest/Neck/Head, UpperArm/Forearm/Hand y Thigh/Shin/Foot a izquierda/derecha. Exportador declarado: Khronos glTF Blender I/O v5.2.40.
- Delantero contiene `Idle`, `Kick`, `Celebrate`. Arquero contiene esos tres más `Catch`, `SaveLeft`, `SaveRight`, `SaveLowLeft`, `SaveLowRight`. **No hay clip Run en estos GLB.**
- Ambos scripts usan `AnimationPlayer` y ruta `FootballerRig/Skeleton3D`. No encontré `AnimationTree` ni configuración BoneMap en las fuentes/imports examinados. Importación animada está habilitada a 30 fps.
- El disparo conserva callback separado a los 0,38+0,10 = **0,48 s**. La aproximación se desplaza por Tween. La atajada combina clip de extremidades con desplazamiento/inclinación del cuerpo físico; la pelota retenida sigue el promedio de los huesos `Hand.L`/`Hand.R`.
- Son hechos de archivo; no se reprodujeron clips ni se ejecutaron tests durante esta investigación. Existen pruebas `kick_contact_and_dive_test.gd`, `keeper_hands_test.gd` y `custom_players_test.gd` para validar cambios futuros.
- El generador `tools/build_original_footballer.py::mesh()` asigna inicialmente cada pieza a un hueso con peso 1,0; después mezcla pesos entre brazo y antebrazo en `Continuous arm` y une las piezas antes de exportar. La mayor parte sigue rígida por pieza, aunque hay una excepción explícita. **Tener skin no garantiza deformación suave en todas las articulaciones**: hay que revisar poses y, si hace falta, crear topología continua y pesos mezclados. No se ha medido visualmente cada deformación.

## Herramientas y biblioteca

| Opción | Costo/licencia verificados | Dificultad/calidad esperada (R) | Aplicación |
|---|---|---|---|
| Blender y rig propio/Rigify | Gratis; software GPL, obras propias comercializables sin quedar automáticamente bajo GPL. Assets ajenos conservan sus condiciones. | Media-alta; control máximo del estilo y contactos. | Mejorar el rig original y animar fútbol a medida. |
| Mixamo | Gratis con Adobe ID; personajes y animaciones royalty-free permitidos en videojuegos comerciales. No es CC0. | Auto-rig sencillo, corrección media; movimiento humano útil como base, no acabado cartoon garantizado. | Rig/locomoción alternativa. No confirmé catálogo actual de patadas/atajadas concretas. |
| Quaternius Universal Animation Library | Standard gratis/parcial; Pro USD9,99; Source USD14,99; CC0, comercial permitido. Source incluye `.blend`. | Baja con rig compatible; media con el rig actual. | Locomoción/emotes, con y sin root motion. No asumir fútbol específico incluido. |

Fuentes: [Blender licencia](https://www.blender.org/about/license/) (s/f; recuperada mediante búsqueda oficial al fallar apertura directa); [Mixamo FAQ](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html) (14-09-2021, consultada 28-09-2026); [Quaternius UAL](https://quaternius.itch.io/universal-animation-library) (actualización mostrada 16-09-2026; consulta 28-09-2026). Costos en USD, sin impuestos. No se descargaron bibliotecas.

Rigify organiza un rig de controles y huesos de deformación; conservar el metarig y hornear el movimiento al esqueleto de exportación. Su guía oficial aconseja ajustar escala y posiciones antes de generar. [Rigify Basic Usage](https://docs.blender.org/manual/en/latest/addons/rigging/rigify/basics.html?highlight=pose+mode) (s/f; búsqueda devuelve manual 4.4, por lo tanto no evidencia de versión Blender actual). Para los 18 huesos ya existentes, añadir controles de autoría puede ser menos riesgoso que sustituir todo el esqueleto (R).

Mixamo requiere humanoide limpio en pose neutral, sin piezas flotantes ni proporciones excesivamente deformadas. La FAQ confirma uso comercial, **no se verificó permiso para redistribuir los archivos crudos públicamente**; resolverlo antes de incluirlos en un repositorio abierto. No hace falta Mixamo para continuar con los assets propios.

## Retargeting en Godot 4.7 (V documental)

1. En importación avanzada, seleccionar `Skeleton3D`; crear `BoneMap` y asignar `SkeletonProfileHumanoid`.
2. Revisar el mapeo automático y corregir errores de jerarquía/nombres. Preparar tanto personaje destino como fuente de animación.
3. Importar la fuente como `AnimationLibrary` si se compartirán clips. Unificar nombres/rutas; coincidencia de nombres sola no basta porque importan los reposos.
4. El perfil de referencia espera T-pose y frente +Z. Revisar Rest Fixer; `Fix Silhouette` ayuda a A-pose, no arregla cualquier proporción o bone roll.
5. Evaluar eliminación de pistas no esenciales y normalización por altura. No borrar a ciegas animación de accesorios.

[Godot 4.7: Retargeting 3D Skeletons](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/retargeting_3d_skeletons.html) (s/f; consulta28-09-2026). En este proyecto, mapear manualmente `Thigh.L→LeftUpperLeg`, `Shin.L→LeftLowerLeg`, `Forearm.L→LeftLowerArm`, etc. es una propuesta a validar en importación, no configuración ya aplicada. Los clips propios sobre el mismo rig no requieren retarget por el mero hecho de existir.

## Plan concreto (R)

1. **Auditar poses actuales, 1–2 h:** frente/perfil/espalda, cadera/hombros/rodillas, pie de apoyo y contacto. Conservar clips existentes como referencia reproducible.
2. **Refinar rig/pesos, 2–6 h sobre malla preparada:** reemplazar articulaciones de piezas rígidas por topología y pesos mezclados en hombros, codos, cadera y rodillas. Mantener 18 huesos si dan deformación suficiente; agregar clavículas o dedos del pie sólo con evidencia visual de necesidad. No aumentar huesos por cumplir un número arbitrario. Si hay que reconstruir esas zonas, reservar trabajo de modelado adicional fuera de esta estimación.
3. **Mejorar Kick y añadir Run, 4–8 h:** carrera corta, anticipación, apoyo, cadera, impacto, seguimiento; usar in-place para conservar trayectoria existente. Alinear impacto con callback0,48s o reemplazar su contrato por evento único explícito del clip, con prueba de pausa/reinicio. No mantener dos emisores de impulso activos.
4. **Refinar arquero y celebración, 6–12 h:** conservar variantes altas/bajas, capturar/soltar sólo en evento, añadir recuperación expresiva; comparar manos y collider durante toda la estirada. Celebración con silueta legible antes de facial.
5. **Estados y validación, 3–6 h:** wrapper propio con `AnimationTree` cuando las mezclas lo justifiquen; estados Idle→Approach/Kick→Recover y KeeperReady→Save/Catch→Recover, más Celebrate. Probar tiros, pausa, personalización y ambos lados.

Total orientativo de mejora sobre assets existentes: **16–34 h con experiencia**, excluyendo remodelado integral y aprendizaje. No son tiempos de crear personaje desde cero.

**Dirección cartoon expresiva pedida:** acentuar anticipación de la patada, contragiro de torso/brazos, extensión rápida y recuperación con asentamiento; celebrar con poses amplias y pausas legibles. Para arquero, comprimir la pose antes de impulsarse y estirar claramente brazos/piernas. Favorecer siluetas y ritmo; no aumentar realismo/mocap por defecto. Exageración de pose primero; escalado de huesos/squash complejo sólo si ropa y colisión lo toleran. Esta es propuesta artística propia, no descripción técnica verificada de Football Strike.

`AnimationTree` reproduce animaciones almacenadas en `AnimationPlayer` y permite mezclas/estados. Root motion extrae desplazamiento para aplicarlo desde código: no usarlo además del Tween que ya desplaza al cuerpo. Si se introduce Tree, unificar ahí el control de reproducción para que no compita con llamadas `AnimationPlayer.play`. [Godot4.7 Using AnimationTree](https://docs.godotengine.org/en/4.7/tutorials/animation/animation_tree.html) (s/f; consulta28-09-2026).

## Riesgos concretos y aceptación

- Renombrar huesos puede romper `Hand.L`/`Hand.R`, pistas y tests; introducir mapeo explícito o adaptar referencias juntos.
- Cambiar velocidad/crossfade del clip puede desincronizar el callback fijo; comprobar contacto real, no sólo duración.
- Compartir movimiento entre cuerpos de distinta altura no garantiza pie/manos sobre la pelota. Ajustar poses y puntos de contacto después del retarget.
- El nombre/dorsal actual está en nodos separados del skin: revisar que acompañe torso al refinar animaciones; no confundir personalización conservada con ausencia de deslizamiento visual.
- Prueba de aprobación: tiros sin doble impulso, balón retenido entre guantes, ropa sin cortes, pies sin patinaje evidente, resultado consistente al pausar/reiniciar y en personajes personalizados.
