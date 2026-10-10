# Auditoría geométrica para una silueta atlética

Fecha: 2026-10-04. Se aplicó la skill `create-game-assets`: inspección de la fuente y capturas antes de proponer cambios, conservación del marco técnico y validación en animación. Esta auditoría no modifica mallas, fuentes ni GLBs.

## Base observada

Fuente: `source-assets/footballer/footballer_v3.blend`, después de las pasadas actuales de short y mangas. Modelo de aproximadamente 1,90 m, esqueleto de 53 huesos y ocho clips. Malla `FootballerBody` con materiales por región; objetos aparte `Beard` y `FootballerRig`. La piel cubierta por camiseta, short y medias ya está eliminada en muchas zonas: la silueta muscular del torso debe construirse sobre la camiseta; no existe allí un volumen completo de piel que baste con escalar.

La captura enviada muestra al jugador de espalda y en perspectiva, durante una patada. Se pueden inferir espalda ancha, deltoides y brazos compactos, muslos y pantorrillas robustos y camiseta con caída. No permite recuperar de forma única dimensiones, cara, geometría oculta o iluminación. Las proporciones siguientes son objetivos de adaptación, no mediciones del modelo comercial.

En `despues.png` de sleeves-quality, el brazo expuesto presenta un cono largo casi uniforme. Falta volumen localizado de tríceps/bíceps y masa proximal del antebrazo. La camiseta tiene una buena continuidad de hombro, pero el volumen de la espalda debería distinguirse mejor de la cintura. La referencia conserva muñecas, codos y rodillas más estrechos que los vientres musculares.

## Medidas locales de la fuente

Coordenadas de reposo Blender en metros, +Z arriba. Derecha del archivo tiene +X; frente del cuerpo es -Y.

| Hueso derecho | Cabeza | Cola | Largo |
|---|---|---|---|
| UpperArm.R | (0,2075; -0,0193; 1,5243) | (0,3933; -0,0194; 1,3119) | 0,2822 |
| Forearm.R | (0,3933; -0,0194; 1,3119) | (0,5391; -0,2282; 1,1721) | 0,2905 |
| Thigh.R | (0,1163; 0,0068; 1,0247) | (0,1599; -0,0292; 0,5478) | 0,4802 |
| Shin.R | (0,1599; -0,0292; 0,5478) | (0,2131; -0,0123; 0,0788) | 0,4723 |

Se midieron radios medianos de vértices con influencia del hueso >0,35 en intervalos ±7,5% del largo:

| Región | Fracción longitudinal | Radio mediano |
|---|---:|---:|
| Brazo / Skin | 0,50 / 0,65 / 0,85 | 48,5 / 50,2 / 47,7 mm |
| Manga / Jersey | 0,35 / 0,50 | 58,5 / 57,7 mm |
| Antebrazo / Skin | 0,15 / 0,35 / 0,50 / 0,85 | 46,5 / 40,3 / 35,7 / 26,1 mm |
| Muslo expuesto / Skin | 0,65 / 0,85 | 78,8 / 59,7 mm |
| Pantorrilla / Socks | 0,15 / 0,35 / 0,50 / 0,85 | 57,9 / 58,7 / 48,3 / 41,2 mm |

Anchos de cortes horizontales de camiseta: z1,03=39,6 cm; z1,20=37,8 cm; z1,30=40,6 cm; z1,40=47,7 cm. A z1,40 la superficie frontal está en y=-0,1723 y posterior en y=0,1340. En el corte alto puede entrar parte del brazo: usar máscara de torso, no tomar ese ancho como ancho anatómico de pecho exacto.

## Algoritmo recomendado

Trabajar sobre una copia del estado actual y añadir una postpasada reproducible al generador, después de shorts y sleeves. Mantener cantidad/orden de vértices y polígonos, ambas UV, pesos, jerarquía de huesos y todas las curvas. No transformar objetos ni editar reposo de huesos.

Para cada segmento `head h`, eje unitario `a=(tail-head)/L`, calcular `t=dot(co-h,a)/L` y radial `r=co-h-a*dot(co-h,a)`. Aplicar `delta=r * amplitud * envelope(t)`, limitado al material y al grupo correspondiente. Usar ventanas smoothstep y mezcla por pesos originales para que no aparezcan escalones en codo o rodilla. Conservar eje longitudinal.

- **Brazo**: máximo +18–22% radial entre t0,30–0,65; reducir hacia codo, sin cero brusco. La manga debe acompañar el campo, manteniendo holgura, no una manga más ancha que el bíceps por un factor nuevo arbitrario. Deltoides visible se representa sobre Jersey y clavícula; no hinchar el cuello.
- **Antebrazo**: +12–15% en t0,15–0,45, desvanecer a cero antes de t0,85. El antebrazo está orientado hacia adelante: global X/Y altera la forma; usar su eje propio. Manos y dedos intactos.
- **Espalda/pecho**: como primera prueba, +8–12% transversal centrado en z1,38–1,48, +6–8% profundidad respecto al centro torácico y cintura casi intacta. Si a escala de juego no se lee, subir transversal a 15% después del render. No aplicar 20% uniforme hasta el abdomen: produce un torso ancho sin la silueta en V. Proteger collar y todo z>1,63; ampliar hombro con transición, conservando el suavizado actual.
- **Muslos**: +12–16% hacia lateral y frente/atrás, pero sólo ~5% hacia el interior. Mayor influencia en t0,30–0,65, desvanecer antes de la rodilla. La ropa tiene radios más grandes que la piel expuesta, no ajustar la piel al radio del short.
- **Short**: conservar cintura z>1,015 y puente central abs(x)<0,015. Ampliar lados y profundidad para cubrir muslos, reduciendo la expansión hacia adentro con `smooth(0,015;0,065;abs(x))`. Inflar ambas perneras radialmente 16% sin esa protección puede cerrar o invertir la abertura recién corregida.
- **Pantorrillas/medias**: +12–15% radial proximal en t0,15–0,45, taper fuerte hacia tobillo; desplazamiento cero antes de z0,15 para mantener unión con botín. Aplicar a Socks y al ribete superior Trim por la misma máscara; proteger Trim de suela y materiales Boots.

## Protección y validación

Proteger cara, ojos, cejas, pelo y barba; cabeza/neck superior; manos; botas; plantas; altura total. `Trim` sirve para medias y botas: no seleccionar todo el material indiscriminadamente. Comparar hashes de pesos, topología, UV, huesos, animaciones y paleta antes/después. Preservar fuente del arquero.

Renderizar frente, espalda y perfil en reposo; luego Kick en contacto y máxima apertura, Celebrate e imagen gameplay desde atrás. Verificar codos, axilas, muslos internos, ruedo y unión medias-botines. Aunque los pesos queden idénticos, aumentar radios puede producir intersecciones en poses extremas: la integridad estructural del rig y la calidad visual de su deformación son verificaciones distintas.

El script de medición temporal está en `/tmp/audit-athlete-mass.py`; salida en `/tmp/audit-athlete-mass.log`. No modifica ni guarda el archivo abierto.
