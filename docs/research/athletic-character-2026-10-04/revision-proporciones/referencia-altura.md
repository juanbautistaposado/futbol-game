# Revisión de altura y equilibrio corporal: Football Strike

Fecha: 2026-10-04. Investigación delegada mediante la skill `research`. Este informe no modifica mallas, fuentes ni animaciones.

## Evidencia primaria consultada

- [Página oficial de Football Strike, Miniclip](https://www.miniclip.com/games/football-strike): origen de las capturas de la galería.
- [Captura oficial 04, personalización](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_IPhone_04_EN.jpg): inspeccionada visualmente en navegador. Delantero frontal en tres cuartos, camiseta roja/negra, brazos y short visibles.
- [Captura oficial 05, carrera](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_IPhone_05_EN.jpg): inspeccionada visualmente. Delantero en tres cuartos con camiseta blanca; buena lectura de profundidad del tórax y caída hasta la cadera.
- [Captura oficial 01, patada](https://static-prod-web.miniclip.com/assets/games/FootballStrike/05_StoreScreenshots/FBS_SCR_iPhone_01_B_EN.jpg): inspeccionada visualmente. Relación entre espalda, cadera, muslo y pantorrilla durante apoyo y patada.
- [Trailer oficial de Miniclip](https://www.youtube.com/watch?v=SlAHv6D2DOw), publicado el 14 de septiembre de 2017. Autor Miniclip verificado. La descripción no contiene dimensiones del personaje. El video se encontró como fuente oficial adicional; las conclusiones visuales siguientes proceden de las capturas inspeccionadas, no de fotogramas no vistos.
- [Ficha publicada por Miniclip en Google Play](https://play.google.com/store/apps/details?id=com.miniclip.footballstrike): descripción del juego, personalización y equipo. No especifica estatura ni anatomía del avatar.

## Qué se puede afirmar sobre altura

No se encontró una altura en metros publicada en las fuentes oficiales consultadas. No corresponde presentar 1,80 m, 1,85 m o cualquier otro número como la medida original de Football Strike. Tampoco puede deducirse comparando el jugador con el arco: están a distancias diferentes de una cámara en perspectiva, y las proporciones promocionales pueden estar compuestas.

La captura enviada por el usuario tiene los pies parcialmente recortados, una pierna flexionada y vista posterior oblicua. Por eso no permite una medición fiable cabeza/altura total, longitud de pierna o volumen frontal del pecho. Es una referencia de silueta en gameplay, no una vista ortográfica del modelo.

## Lectura visual y corrección de la interpretación anterior

Las capturas 04 y 05 muestran un atleta con hombros definidos y brazos firmes, pero **la camiseta conserva un frente relativamente plano**. No hay un tórax abombado ni pectorales de culturista. El ancho de hombros se mantiene, mientras el panel del pecho cae hacia una cintura más estrecha. En 05 el perfil del pecho sobresale moderadamente, no como una esfera sobre el abdomen. Estas son inferencias visuales, no medidas del asset comercial.

La captura 01 muestra fuerza en todo el tren inferior: short con volumen alrededor del muslo, pierna de apoyo llena y pantorrilla que afina hacia el tobillo. Aumentar mucho el torso sin acompañar esa masa produce el desequilibrio que el usuario rechazó. La dirección adecuada de esta pasada es recuperar un tórax más contenido y poner mayor énfasis en las piernas.

La captura frontal actual del repositorio (`../frente.png`) confirma la descompensación: el tórax domina la silueta y el short/piernas quedan comparativamente pequeños. Además, la camiseta es una superficie exterior; inflar sus coordenadas no equivale a reconstruir músculo bajo tela y puede dar apariencia de pecho acolchado.

## Medidas de la base y escala de escena

La [auditoría local anterior](../auditoria-base.md) registró una fuente de aproximadamente **1,90 m** y estos huesos de reposo:

| Medida local | Valor | Implicación |
|---|---:|---|
| Altura de cadera (`Thigh.R` head Z) | 1,0247 m | Cerca del 54% de la altura total |
| Largo de muslo | 0,4802 m | Longitud ya considerable |
| Largo de tibia | 0,4723 m | Casi igual al muslo |
| Rodilla (`Thigh.R` tail Z) | 0,5478 m | Cerca del 29% de la altura total |

Estas medidas no son datos de Football Strike. Sí muestran que nuestra base no tiene piernas longitudinalmente diminutas. Conviene aumentar su volumen antes de alargarlas: cambiar la longitud implica modificar reposo de huesos, alcance y contacto de la patada.

`apps/free-kick-3d/main.gd:84` y `menu_background.gd:50` aplican `Vector3.ONE * 1.15` al jugador. La altura aparente en unidades de escena es aproximadamente 2,185, aunque la fuente mida 1,90. Es una decisión local de presentación; no prueba que el jugador de Football Strike tenga esa altura. Alterar ahora esa escala exige revisar cámara, contacto con pelota y alcance, por lo que se recomienda conservarla en esta revisión corporal.

## Recomendación concreta para la revisión

Los porcentajes siguientes son parámetros de autoría propuestos para nuestro asset, no porcentajes medidos del personaje comercial. La comparación final debe hacerse con la misma cámara e iluminación.

1. **Pecho:** rehacer la pasada desde la base previa a la constitución atlética. Sustituir el ensanchamiento transversal anterior de hasta 18% por 0–4% en el panel torácico; eliminar el aumento de profundidad anterior de 8% y, si persiste volumen acolchado, contraer suavemente 3–5% la profundidad del frente/espalda respecto al centro torácico. Mantener hombros y axilas con transición suave y proteger cuello.
2. **Muslos:** pasar del incremento radial nominal anterior de 13% a 22–26% respecto a la base previa, concentrado en el tramo superior/medio. Favorecer frente y lateral; limitar expansión interior para conservar la abertura del short. La tela debe acompañar el campo sin mover cintura ni puente central.
3. **Pantorrillas:** pasar del incremento nominal anterior de 12% a 18–22%, con vientre localizado y reducción gradual hacia rodilla y tobillo. Aplicar el mismo campo a medias y ribete correspondiente; proteger botines.
4. **Longitud/altura:** conservar altura total, cabeza y huesos. No alargar piernas ni reducir torso longitudinalmente en esta pasada. Si el usuario luego pide otro canon de altura, será una tarea de rig y recalibración separada.
5. **Validación:** frente y perfil deben mostrar un tórax más plano; gameplay posterior debe dar mayor peso a piernas sin un cuerpo ancho uniforme. Comprobar patada/celebración, intersecciones, cintura única y unión de medias/botines. La comparación de hashes verifica conservación estructural, pero no sustituye la inspección de la deformación.

No se propone descargar el modelo comercial, copiar texturas oficiales o afirmar identidad geométrica. Se aprovechan referencias públicas para corregir la silueta de la base CC0 existente.
