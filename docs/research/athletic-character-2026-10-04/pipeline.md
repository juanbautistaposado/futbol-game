# Pipeline para una silueta atlética sin sustituir el rig

Investigación del 4 de octubre de 2026. Skill aplicada: `research`. Se revisaron fuentes primarias MPFB, Blender y Khronos, y los generadores actuales. Este informe propone una implementación; no modifica modelos ni acredita resultados de una transformación todavía no ejecutada.

## Decisión recomendada

Añadir una pasada reproducible **sobre el `.blend` actual después de jersey, short y mangas**, desplazando únicamente coordenadas de vértices. Mantener topología, pesos, nombres de grupos, matrices de reposo del esqueleto, UV, materiales y acciones. La robustez debe venir de la sección del torso y las extremidades, sin agrandar el personaje entero ni alargar huesos. Esta es una conclusión de ingeniería para este proyecto, no una garantía general del exportador.

Blender vincula cada hueso con el grupo de vértices del mismo nombre y utiliza los pesos para regular su influencia. En glTF la deformación depende de las matrices de articulaciones, inverse bind matrices y atributos JOINTS/WEIGHTS. Conservar ese conjunto mantiene la estructura de animación, aunque una sección más gruesa puede aumentar colisiones y exigir revisar poses. [Blender Armature](https://docs.blender.org/manual/en/latest/modeling/modifiers/deform/armature.html), [Khronos: skins](https://github.com/KhronosGroup/glTF-Tutorials/blob/main/gltfTutorial/gltfTutorial_020_Skins.md).

## Estado verificado en el repositorio

- `build_footballer_v3.py:31` ya crea la anatomía MPFB con `muscle=.8`, `weight=.4`, `height=.6`, `proportions=.65`. Después hornea targets y normaliza anatomía y huesos a 1,90 m. Subir solo el slider muscle no garantiza una diferencia visual suficiente a distancia.
- La misma reconstrucción añade ojos, cejas y pelo, subdivide cabeza, genera prendas por superficies anatómicas y retargetea animaciones. Cambiar macros desde ese punto vuelve a construir más que el torso.
- Al final se encadenan `tailor_footballer_jersey.py`, `tailor_footballer_shorts.py` y `tailor_footballer_sleeves.py`. Hay protección de revisiones para evitar acumulación accidental.
- `FootballerBody` reúne partes por materiales. El manifiesto vigente declara 53 huesos, 89.843 triángulos, 11 superficies y 8 clips: Catch, Celebrate, Idle, Kick, SaveLeft, SaveLowLeft, SaveLowRight y SaveRight. Son valores locales, no limitaciones de glTF.
- La nueva pasada puede reutilizar `locked_state` de shorts para comprobar pesos, matrices, curvas, topología, paleta y UV. Debe añadir protección explícita de cara, pelo, barba y botas.

## Transformación local propuesta

Los porcentajes siguientes son **rangos iniciales artísticos para probar**, no proporciones medidas de Football Strike. La captura posterior no permite reconstruir con certeza el pecho, perfil ni anatomía oculta.

| Región | Cambio inicial | Límites que se deben fijar |
| --- | --- | --- |
| Pecho y espalda bajo camiseta | Aumentar ancho 8–12 % y profundidad 5–9 % con transiciones suaves | Desvanecer antes de cintura y cuello; no reproducir pectorales puntiagudos en tela |
| Hombro y parte superior de brazo | Sección radial 10–16 %, deltoide redondeado | Mantener centros de articulación; no trasladar todo el brazo lateralmente |
| Antebrazo | Sección radial 8–12 %, volumen máximo en mitad proximal | Desvanecer a cero antes de muñeca; manos y dedos intactos |
| Muslo y short | Sección radial 8–12 % | Conservar puente de entrepierna, cintura continua y ruedo existente; evitar estrechar abertura central |
| Pantorrilla y medias | Sección radial 6–10 % | Desvanecer a cero en rodilla y tobillo; botas intactas |

Para un vértice `p`, usar el hueso de reposo de su región, con origen `h` y eje unitario `a`: `t=dot(p-h,a)` y `r=p-h-a*t`. La modificación debe ser `p'=h+a*t+r*(1+k*m(t))`, con máscara suave `m` que se apaga en límites. Así se conserva la longitud longitudinal y el centro articular. La fórmula es una propuesta propia basada en coordenadas locales; no una función incorporada MPFB.

Aplicar la misma deformación espacial a piel y prenda adyacente. No expandir piel y luego pegar la tela con nearest-neighbor indiscriminado: la camiseta debe conservar holgura y puentear músculos. Las caras de piel ocultas bajo ropa ya se han eliminado; un BVH sobre la piel visible no contiene un torso completo y puede proyectar hacia bordes cortados. Usar protección de distancia solo en hombro/cuello expuestos o una copia anatómica completa auxiliar.

Máscaras por material y pesos deben dominar sobre cortes absolutos por `z`: los brazos de la pose A son oblicuos, por lo que una franja horizontal puede alcanzar mano o formar escalones. El cuello y collar deben quedar fijos en esta pasada; la conexión con un torso ampliado puede suavizarse solo desde abajo. Los extremos de la camiseta deben mantener su carácter suelto.

## Por qué no regenerar macros ahora

MPFB representa targets como offsets de índices de vértices y shape keys. El sistema macro interpola múltiples atributos y `bake_targets` convierte el resultado en geometría sin shape keys. El cuerpo entregado ya pasó por ese horneado y por operaciones posteriores de topología; sus vértices no equivalen de forma trivial al basemesh original. [MPFB TargetService](https://github.com/makehumancommunity/mpfb2/blob/master/docs/services/targetservice.md).

Los rigs MPFB se describen usando referencias a vértices del basemesh para colocar cabezas y colas de huesos. Una reconstrucción con anatomía distinta puede modificar sus matrices de reposo aun cuando los nombres y el conteo sean los mismos. Por eso conservar 53 nombres no demuestra compatibilidad exacta. [Formato de rigs MPFB](https://github.com/makehumancommunity/mpfb2/blob/master/docs/fileformats/rig.md).

Regenerar con mayor peso/musculatura sigue siendo una opción futura si se necesita cambiar longitudes, hombros óseos o proporciones de cabeza. En ese caso habría que comparar nuevo rig, retargetear, volver a ajustar prendas y revisar cara. La función Export Copy de MPFB facilita crear una copia autocontenida y conservar la fuente, pero no garantiza mantener nuestra anatomía/rig personalizados. [MPFB Export Copy](https://static.makehumancommunity.org/mpfb/docs/exporting/export_copy.html).

## Exportación y verificación necesarias

Conservar los parámetros actuales: GLB, selección FootballerRig/FootballerBody/Beard, `export_skins=True`, `export_apply=False`, `export_animation_mode='NLA_TRACKS'`, `export_yup=True`, cuatro influencias. Blender documenta que NLA Tracks produce una animación independiente por pista; no sustituir por Active Actions merged porque cambiaría la biblioteca de clips. [Blender 5.0 glTF: animaciones](https://docs.blender.org/manual/en/5.0/addons/import_export/scene_gltf2.html).

Antes/después, comparar en el `.blend`: número y orden de vértices, polígonos/materiales, coordenadas de regiones protegidas, todos los pesos, nombres/parents/matrices de 53 huesos, curvas y handles de acciones, UV0/UV2 y paleta. `mesh.validate(clean_customdata=False)` debe no necesitar reparaciones. Los UV pueden quedar idénticos aunque la textura se estire más: revisar dorsal PLAYER/10 visualmente. El exportador puede separar vértices en discontinuidades UV o normales; comparar posiciones de exportación sin asumir índice Blender = índice GLB. [Blender glTF](https://docs.blender.org/manual/en/4.4/addons/import_export/scene_gltf2.html).

Después verificar GLB: 53 joints, mismas inverseBindMatrices, JOINTS/WEIGHTS equivalentes y 8 clips con nombres/duración. Reimportar en Godot y ejecutar pruebas existentes athlete_v3, custom_players y kick_contact_and_dive, esta última aislada de renders concurrentes. Guardar imágenes antes/después frontal, posterior, perfil y cámara real; inspeccionar patada y celebración en más de un instante, especialmente axila, muñeca, entrepierna, rodilla y tobillo.

Cambiar coordenadas sin agregar polígonos mantiene el presupuesto geométrico; eso no equivale a un nuevo benchmark de FPS. No activar Preserve Volume solo para ocultar pinzamientos: Blender puede mostrar una deformación por cuaterniones distinta del skinning lineal glTF descrito por Khronos. El resultado que manda es la importación final Godot, no únicamente el viewport Blender. [Blender Armature](https://docs.blender.org/manual/en/latest/modeling/modifiers/deform/armature.html), [Khronos: ecuación de skinning](https://github.com/KhronosGroup/glTF-Tutorials/blob/main/gltfTutorial/gltfTutorial_020_Skins.md).

## Límite de la referencia

La captura sirve para silueta y lectura de espalda, jersey suelto y masa de brazos/piernas. No prueba dimensiones métricas, UV, topología ni distribución de pesos del personaje original. La fidelidad debe evaluarse con una cámara similar y comparaciones visuales; no se puede afirmar identidad geométrica a partir de una sola imagen.
