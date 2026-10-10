# Auditoría de piernas y balance corporal

Fecha: 2026-10-04. Skill aplicada: `create-game-assets`, con su referencia `three-d-pipeline.md`. Auditoría de sólo lectura sobre `footballer_v3.blend`, `athletic_footballer.py` y las capturas frente/perfil/comparación de la pasada atlética. No se modificaron fuentes, scripts de producción ni GLB.

## Lectura visual

La comparación frontal muestra un cambio del torso más dominante que el de las piernas. La camiseta ensancha el pecho hasta una silueta prácticamente rectangular; el muslo expuesto sigue siendo estrecho respecto de las perneras del short. El perfil presenta pantorrillas relativamente rectas: falta una masa proximal visible seguida por una reducción clara hacia el tobillo. El objetivo de la siguiente pasada debe ser redistribuir el volumen, no escalar el personaje completo.

Las medidas siguientes describen la fuente propia; no son medidas del personaje comercial de Football Strike. No puede deducirse una altura física exacta del personaje comercial a partir de la captura posterior en perspectiva.

## Medición de la fuente actual

Blender 5.2.2 LTS, pose de reposo, metros, +Z arriba. Script de lectura `/tmp/audit-athlete-mass.py`; salida de esta ejecución `/tmp/leg-shape-audit.log`. Se tomó la mediana del radio perpendicular al eje del hueso en ventanas ±0,075 de su longitud, material indicado, lado derecho y peso del grupo >0,35. Mediana no equivale a semiancho frontal, especialmente en ropa que no es circular.

| Región | Fracción del hueso | Antes de la pasada atlética | Fuente atlética actual |
|---|---:|---:|---:|
| Muslo, Skin | 0,65 | 78,8 mm | 89,0 mm |
| Muslo próximo a rodilla, Skin | 0,85 | 59,7 mm | 62,7 mm |
| Pernera, Shorts | 0,35 | — | 114,9 mm |
| Pernera, Shorts | 0,50 | — | 129,3 mm |
| Pernera, Shorts | 0,65 | — | 133,5 mm |
| Media alta, Socks | 0,15 | 57,9 mm | 61,1 mm |
| Pantorrilla, Socks | 0,35 | 58,7 mm | 64,8 mm |
| Pantorrilla, Socks | 0,50 | 48,3 mm | 53,4 mm |
| Media baja, Socks | 0,85 | 41,2 mm | 41,2 mm |

Las cifras anteriores proceden de `auditoria-base.md`, calculadas con el mismo método antes de la pasada atlética. El hueso `Thigh.R` tiene longitud 0,4802 m, desde (0,1163; 0,0068; 1,0247) hasta (0,1599; -0,0292; 0,5478). `Shin.R` mide 0,4723 m y termina en (0,2131; -0,0123; 0,0788). Ninguna necesidad estética de esta revisión exige modificar esas longitudes ni sus matrices.

El short termina en z0,695 y mantiene cintura z1,075. La media va de z0,1011 a z0,5458; la piel expuesta de rodilla comienza alrededor de z0,536. El material `Trim` también alcanza z0,5458: contiene ribete de media además de piezas de botines y cordones. Por eso excluir todo `Trim`, como hace la pasada atlética vigente, conserva el ribete mientras aumenta la media y puede dejar un escalón.

## Campo recomendado

Partir de la copia anterior a la pasada atlética, no acumular otro escalado sobre la fuente actual. Mantener posiciones de huesos, pesos, índices, UV, paleta, altura y geometría de cabeza/botines. Aplicar un campo radial respecto al eje local de cada segmento; no escalar en los ejes globales.

- **Muslo:** probar pico total +28–32% sobre la base anterior, con campana centrada en t0,55–0,67 y anchura ~0,32. La ventana proximal debe subir suavemente entre t0,05 y t0,25; el taper distal debe empezar cerca de t0,75 y llegar a cero en t0,98. Conservar masa en el muslo visible bajo el ruedo y limitar expansión hacia el interior a aproximadamente 30–40% de la expansión lateral para evitar colisión entre piernas.
- **Short:** no usar el mismo porcentaje muscular para todas las caras de Shorts. Su radio actual ya excede notablemente el de la piel. Probar sólo +6–9% radial sobre la base anterior, con cintura y puente central protegidos, `delta.z=0`, y mantener holgura real sobre el muslo. La propuesta muscular no obliga a modificar el largo de las perneras.
- **Pantorrilla:** probar pico +22–26% sobre la base anterior, en t0,35–0,43. Bell suave, retorno gradual a cero antes de t0,82–0,90, con máscara adicional que conserve intacto z<0,15. El aumento debe leerse como vientre muscular; una expansión uniforme hasta el tobillo crea una media cilíndrica.
- **Rodilla/ribete:** usar un mismo campo geométrico de transición en la banda z0,50–0,57 para Skin, Socks y sólo el `Trim` alto, con pesos Shin/Thigh compatibles. No depender exclusivamente de dos máscaras por grupo: la piel posee pesos mezclados y el cuff de Socks tiene Shin=1.0. Evitar que el campo de Shin sea cero en su cabeza mientras el de Thigh sigue ampliando la piel vecina. Alternativamente conservar ambos volúmenes prácticamente iguales a la base en esa banda, con transición continua desde el vientre muscular.

Los porcentajes son un punto de partida de autoría que requiere render y ajuste. El campo por vértice es `r = co-head-axis*dot(co-head,axis)` y `delta = r*amplitud*bell(t)*ventana(t)`, mezclado con los pesos existentes; cualquier componente que acerque las superficies interiores de los muslos debe limitarse. Para el puente del short mantener la protección por `abs(x)` ya implementada.

## Verificación necesaria

Comparar reposo frente, espalda y perfil con misma cámara y encuadre. Medir cortes de pierna expuesta, pernera y pantorrilla; no reportar sólo la amplitud teórica del campo. Revisar la abertura del short, rodilla/ribete y media/botín en Kick al contacto y máxima flexión, Celebrate y cámara real de juego. Un hash de rig/pesos idéntico prueba conservación estructural, pero no descarta intersecciones visuales después de ampliar la malla.

No modificar altura corporal o esqueleto para aproximar una captura sin escala verificable. Mantener 1,90 m en la fuente permite conservar alcance y contacto actuales; si más adelante se cambia escala de presentación, debe verificarse separadamente el contacto pie-pelota.
