# Camiseta, short y acabados del personaje — 11 de octubre de 2026

Esta pasada modifica assets de delantero y arquero y sus materiales. Conserva
la paleta, identidad, altura y rig. No modifica los controladores de animación,
clips, esqueleto, colisiones, tiempos de contacto ni lógica de juego.

## Camiseta

Se suavizan pequeños relieves de la geometría generada, con un desplazamiento
limitado a 4 mm, y se agrega hasta 1.8 mm de separación del cuerpo. Se conservan
cuello, puños y bordes. La selección del material incluye los pequeños triángulos
claros que quedaban fuera del recoloreado, reduciendo el borde dentado.

La tela conserva el atlas, las UV y el dorsal. El shader agrega tejido fino de
poliéster con filtrado por tamaño de píxel: el detalle desaparece a distancia
para evitar parpadeos. Se atenúa el relieve excesivo del mapa de normales y se
usa un acabado más mate que el de la piel.

## Short

Se suavizan pequeñas irregularidades, manteniendo el largo y volumen de la
base. Los pesos se mezclan un 25% hacia una cintura que sigue Hips y perneras
que siguen el muslo correspondiente. El 75% restante conserva el skinning
original. La corrección se desvanece al llegar a los bordes del tejido.

La revisión de la patada desde atrás mostró que simplificar las caras del short
o sustituir completamente los pesos dañaba sus pliegues. La versión final
conserva la topología del short y usa la corrección gradual, sin esos defectos.

## Materiales y optimización

Piel, tejido y látex tienen respuestas distintas de rugosidad y especularidad.
Los guantes usan un shader independiente de látex con grano fino filtrado.
No se repintan los ojos, rostro, pelo o botines. Las máscaras de personalización
existentes siguen funcionando, y no se cambia el albedo de la paleta.

Se eliminan detalles geométricos redundantes de la camiseta y zonas casi
planas de miembros vinculadas a un solo hueso. Se conservan las costuras UV,
fronteras de materiales y zonas de articulación; quedan excluidos cabeza,
manos, botines y la topología deformable del short. Los informes `striker.json`
y `keeper.json` contienen los conteos finales y hashes.

La reducción es conservadora. Godot ya genera LOD automáticamente, por lo que
menos triángulos en el GLB no garantizan menos triángulos en cada LOD ni un
aumento de FPS. `rendimiento-antes.json` y `rendimiento-despues.json` registran
una escena nativa aislada de nueve avatares; no son un benchmark de release,
web ni móviles. El monitor de tiempo de proceso puede incluir inicialización
y tiene otra frecuencia de actualización que la muestra de render. No se
utiliza para atribuir una mejora de FPS ni para inferir un cuello CPU/GPU.

## Fuentes y validación

Fuentes originales intactas: `meshy_striker.blend`, `meshy_keeper.blend`.
Editables nuevos: `meshy_striker_cloth_v2.blend`, `meshy_keeper_cloth_v2.blend`
en `source-assets/footballer/`. Reconstrucción:

```sh
blender -b --python apps/free-kick-3d/tools/polish_meshy_cloth.py
python3 apps/free-kick-3d/tools/audit_player_cloth.py
```

La auditoría verifica matrices de bind y los ocho clips exactos, posiciones/UV/
pesos de cabeza y botines intactos, pesos normalizados, UV0/UV2 presentes y
geometría finita. Los auditores existentes de delantero/arquero reconocen
esta revisión y ejecutan esa validación.

Licencia derivada Meshy AI (Meshy 6 Lite), CC BY 4.0, con adaptaciones del
proyecto. Sin créditos Meshy adicionales ni generaciones nuevas.
Aplicado localmente, sin commit ni publicación.

## Resultado final

Ambos roles pasan de 101.904 a **91.826 triángulos**: reducción del **9,89%**.
GLB delantero: 9.190.132 bytes; arquero: 9.198.556 bytes. Los 1.272 canales
de animación y el rig se conservan exactamente según la auditoría.

Validación: auditores de delantero/arquero, editor de apariencia, configuración
del arquero y flujo de animación aprobados. Se inspeccionaron capturas nativas
frontales y traseras de `athlete/MatchStrike` y la pose del arquero. El test de
poses de guantes también completa sus comprobaciones; al liberar nodos imprime
advertencias de material nulo del renderizador, ajenas a la exportación de ropa.

Capturas: [frente](despues-frente.png), [espalda](despues-espalda.png) y
[arquero](arquero.png). Los controladores de animación no se editaron en esta tarea.
