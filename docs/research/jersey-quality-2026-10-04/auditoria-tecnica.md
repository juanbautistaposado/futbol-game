# Auditoría técnica de la camiseta actual

Fecha: 4 de octubre de 2026. Auditoría de solo lectura: código del generador,
materiales de Godot, documentación de la fuente y capturas finales de la revisión
anterior. No se modificaron código ni assets.

## Conclusión

La camiseta ya no presenta los errores grandes de interpenetración del pecho,
pero sigue siendo una superficie derivada del cuerpo, redondeada y de color casi
uniforme. Le faltan señales de confección y caída de una prenda deportiva: espacio
entre torso y tela, axila con forma de prenda, cuello visible, borde de manga,
paneles y pliegues grandes que sobrevivan a la cámara del juego. El dorsal funciona;
añadir un logo por sí solo no resolvería el problema de forma.

No hace falta sustituir el personaje completo ni su rig. La intervención puede
concentrarse en `Jersey` y `Collar binding`, manteniendo huesos, clips, escala,
paleta y el resto de las mallas.

## Evidencia local

| Hallazgo | Evidencia | Consecuencia |
|---|---|---|
| La base de camiseta es una copia recortada de piel, expandida 40 mm y suavizada 24 veces | `build_footballer_v3.py`, líneas 189–201 y 263 | La forma general sigue siendo anatómica; suavizar elimina también rasgos de caída y construcción |
| La única holgura adicional del torso es aumentar X hasta 4 % bajo el pecho | Líneas 269–273 | No existe control independiente de holgura frontal, dorsal, costados y barriga; la prenda resulta uniforme |
| Las mangas se vuelven a ajustar a la piel más 12 mm | Líneas 274–283 | Se leen como una cubierta ajustada del brazo; falta espacio inferior que sugiera tejido colgando |
| Hombros y cuello se relajan de nuevo 12 y 24 veces, respectivamente | Líneas 293–300 y 411–422 | Se evita el escalón anterior, pero también se produce un hombro muy redondo y continuo, sin estructura de patronaje |
| Frente regularizado con superficie polinómica | Líneas 435–452 | Buen arreglo del bulto central; no debe eliminarse. Necesita pliegues intencionales pequeños superpuestos, no recuperar los músculos de la piel |
| Cuello y cuerpo usan el mismo material `Jersey` | Líneas 563–598 | En la captura frontal el cuello apenas se distingue; no se percibe una abertura y un ribete de prenda con claridad |
| UV principal = `(x * 2 + 0.5, z * 0.8)` | Líneas 240–251, también collar | Se ignora Y: en superficies laterales y zonas de brazo hay compresión de coordenadas. Sirve como mapa provisional, no para paneles ni costuras orientadas |
| UV secundaria proyectada solo en espalda | Línea 251; `footballer_visual.gd`, `apply_lettering` | La personalización está resuelta y debe conservarse. No reutilizar UV2 para paneles nuevos |
| El albedo solo tiene tejido sinusoidal y un pliegue sinusoidal de contraste muy bajo | Líneas 112–122 | Los pliegues no responden a cuello, axilas o cintura, y el normal solo contiene microtejido; no hay volumen de tela grande |
| Shader carece de detalles exclusivos de camiseta | `athlete_kit.gdshader`, líneas 1–28 | Solo short tiene paneles y costuras; camiseta, cuello y medias comparten la misma respuesta textil |

Inspección visual: `v3-secuencia-final-frente.png` y
`v3-secuencia-final-espalda.png` en `docs/research/character-quality-2026-10-01/`.
Se observa torso casi rectangular, bajo horizontal sin caída perceptible,
hombros redondeados, mangas sin lectura de borde y cuello casi invisible. Son
juicios visuales de esas capturas, no mediciones de una nueva versión.

## Propuesta precisa y acotada

### 1. Silueta de camiseta deportiva

Conservar el largo actual y el solape con short. Mantener el bajo anclado a
pelvis ya corregido. Definir holgura por secciones del torso: pecho, abdomen y
bajo, con curvas suaves entre ellas; evitar seguir cintura/costillas/nipples.
Como punto de partida para probar en vista frontal y perfil, usar 20–30 mm de
separación lateral y 15–25 mm de separación frontal/dorsal respecto al cuerpo
original. Estas cifras son propuestas de autoría, no datos derivados de una
marca real; ajustar por la silueta de referencia.

El borde inferior puede tener una variación de 2–4 mm y dos o tres pliegues de
compresión alrededor de los costados, sin convertirlo en una franja ondulada.
Pliegues amplios de aproximadamente 40–80 mm de ancho y 2–4 mm de profundidad,
con máscara que se apague en pecho central, cuello y límites de impresión.
Eliminar la sinusoidal repetida del albedo como sustituto de esos pliegues.

No aplicar suavizado global después de añadir caída: usar máscaras y fijar los
bordes. Una construcción nueva por paneles frontales/dorsales es la ruta más
controlable; si se mantiene la malla derivada, regularizarla por regiones antes
de introducir pliegues, con transferencia de pesos de la superficie corporal.

### 2. Manga y axila

Conservar como comienzo el largo actual de 15,8 cm hasta medio bíceps. Dar la
sección de manga forma ovalada con parte superior siguiendo el brazo y parte
inferior algo más separada. Probar 12–18 mm arriba y 20–30 mm debajo, sin
agrandar todo el cilindro de forma uniforme ni devolver la manga acampanada.
El borde debe continuar en el mismo tejido, con un dobladillo representado en
normal/roughness o relieve de 0,5–1 mm; nada de una banda vuelta hacia dentro.

Una ligera caída bajo axila y un pliegue diagonal desde axila al lateral del
torso ayudan más que una costura visible en hombro. La transición de hombro debe
seguir siendo geométricamente continua. Si se propone raglán, representarlo
con cambio sutil de tejido/panel y línea suave en normal, no con piezas separadas
ni escalones. La topología debe cerrar y deformarse como una única prenda.

### 3. Cuello reconocible

Mantener la abertura real conectada al cuello y los pesos compartidos del borde
ya arreglado. Hacer visible un ribete de 8–12 mm de ancho y 1–2 mm de grosor,
con textura de canalé y valor ligeramente más oscuro del mismo color. Un cuello
redondo deportivo es suficiente; no añadir cuello tipo polo como atajo.

El objeto `Collar binding` actualmente comparte material y shader con torso.
Puede recibir un material `JerseyCollar` que derive el mismo color del perfil,
o un atributo que seleccione ribete en un shader compartido. Si se cambia el
nombre de material, actualizar el enrutamiento de `footballer_visual.gd` para
que personalización no deje el cuello azul por defecto.

### 4. UV y materiales

UV0: atlas con islas frontal, dorsal, mangas y ribete, escala textil uniforme;
evitar la proyección X/Z actual en costados. UV1/UV2 exportada: conservar la
impresión dorsal exacta y el sentinel `(-2, -2)` fuera de espalda. Comprobar el
flip V del GLB antes de pintar paneles.

Separar microtejido repetible de detalle de confección. Paneles laterales y de
axila con variación tonal de la paleta existente, sin logos de clubes ni marcas.
Normal para costuras y dobladillos muy sutiles; geometría para pliegues que
alteran silueta. Roughness orientativa a probar 0,65–0,80 para poliéster del
torso y diferencia sutil en paneles/puños; la actual 0,84 con variación mínima
produce tela muy mate. No compensar con metalicidad o brillo plástico.

Usar máscara/material exclusivo de camiseta (`jersey_details`) en el shader:
el material compartido de short y medias no debe cambiar al ajustar el tejido
de camiseta. La impresión dorsal conserva render SubViewport independiente por
jugador. Las texturas principales pueden seguir en 512² inicialmente; evaluar
1024² solo si la cámara demuestra necesidad.

## Contrato de conservación

- No cambiar `SHORT_HEM`, generador de shorts, cara, pelo, botines ni grupos
  corporales ajenos a cobertura de camiseta.
- Mantener 53 huesos, sus nombres/transforms, y ocho clips y curvas originales.
- Transferencia de pesos de camiseta nueva desde cuerpo original; normalizar y
  limitar a cuatro influencias. La transferencia conserva rig y clips, pero sí
  puede requerir pesos distintos de la camiseta para deformar correctamente.
- Mantener mezcla gradual hombro/UpperArm y el borde de manga sobre UpperArm.
  Bajo sigue a Hips; no heredar Thigh allí.
- Restringir borrado de piel a regiones realmente ocultas. No tocar cuello
  visible; verificar que los nuevos márgenes no generen agujeros al animar.
- Materiales y color del perfil siguen independientes entre delantero y arquero.

## Orden sugerido y aceptación

1. Cambiar torso, axila y mangas en fuente editable; validar frente, perfil,
   espalda e Idle/Kick/Celebrate sin nuevos materiales que oculten errores.
2. Resolver cuello y dobladillos; revisar close-up y tamaño real en estadio.
3. Rehacer UV0 y mapas textiles, preservando UV2 de impresión; probar nombre y
   dorsal largo y corto y los dos perfiles de color.
4. Revisar transición piel/ropa en Kick, brazos altos y estiradas. Ejecutar
   `athlete_v3_test.gd`, `custom_players_test.gd` y
   `kick_contact_and_dive_test.gd`; comparar invariantes protegidos y manifest.
5. Verificar build web Compatibility además de vista nativa. Medir incremento
   de triángulos/texturas antes de declarar mejora lista para publicar.

El generador actual reconstruye todas las piezas a la vez; aunque los cambios
sean locales, confirmar hashes/geometría protegida después de regenerar para
que una mejora de camiseta no altere incidentalmente short/cara/botines/rig.

## Fuentes auditadas

- `apps/free-kick-3d/tools/build_footballer_v3.py` (fuente primaria del asset).
- `apps/free-kick-3d/footballer_visual.gd` (aplicación runtime de perfiles/dorsal).
- `apps/free-kick-3d/shaders/athlete_kit.gdshader` (respuesta textil runtime).
- `source-assets/footballer/footballer_v3.md` (contrato, procedencia y revisiones).
- Capturas finales citadas arriba (evidencia visual del estado auditado).

Las búsquedas de fotos/modelos y licencias se realizan en los otros informes de
esta investigación. Los tamaños y ajustes aquí son hipótesis concretas para
prototipar, no estándares oficiales ni resultados ya implementados.
