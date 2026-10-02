# Rol 6 — Revisión crítica e integración

Revisión: 2026-09-23. Revisados inicialmente 00–03; revisión de 04–05 pendiente al crear este archivo. El revisor produjo previamente el informe 03: esta parte es autoauditoría, mientras que 00–02 provienen de otros investigadores. No se presenta como seis revisores independientes simultáneos.

## Correcciones necesarias para el informe unificado

1. **Alinear los alcances de los tiempos.** 02 propone 16–32 h para primera versión con base; 03 propone 17–34 h de animación incluyendo ambos roles, además del modelado. No compararlos como si fueran el mismo entregable. Resolución revisada el 24/09/2026: las 16–32 h iniciales suponían estilización ligera. Al pedir mayor similitud visual, estimar 30–60 h para delantero con rostro/ropa refinados, espera y patada; 16–30 h adicionales para arquero/atajadas/captura/recuperación/celebración. Total orientativo 46–90 h con experiencia, sin sumar etapas ya solapadas. Principiante requerirá aprendizaje adicional; no son plazos prometidos.
2. **Alinear estilo con la corrección del usuario.** Las fuentes muestran realismo deportivo simplificado con superficies suaves. El 24/09/2026 el usuario descartó hacerlo más cartoon; el objetivo final debe usar anatomía humana, detalles de uniforme y sombreado suave, sin cel shading fuerte ni proporciones exageradas.
3. **No inventar especificaciones originales.** 8–16 mil triángulos es una meta nuestra revisada para mayor fidelidad. El promedio 13 mil corresponde a Quaternius y puede tolerarse en el primer prototipo sujeto a medición. No hay conteo verificado de Football Strike.
4. **No vender un importador como migración completa.** El juego actual articula nodos con Tweens; no tiene ya un rig `Skeleton3D` al que simplemente asignar animaciones. Hacen falta escena visual nueva y adaptador que preserve `kick`, `dive`, personalización y evento de pelota.
5. **No convertir geometría en FPS.** 38.200 triángulos/65 superficies es medición local de un modelo, no contador GPU, draw calls ni prueba en celular. Reducir superficies/triángulos es una oportunidad, no garantía de velocidad.
6. **Separar paquetes y precios.** Quaternius Base Source USD 19,99 y Animation Library Source USD 14,99 son compras distintas: ambas fuentes suman USD 34,98, antes de impuestos. Versiones gratuitas parciales pueden bastar. No prometer los 6 cuerpos/20 peinados/todos los clips gratis.

## Revisión independiente de condiciones publicadas

- [Quaternius Base Characters, itch oficial](https://quaternius.itch.io/universal-base-characters), actualizado 16-09-2026: confirma CC0, media de 13k triángulos, Source USD 19,99. Compatibilidad anunciada por autor no es nuestra prueba del paquete descargado.
- [Meshy Help Center](https://help.meshy.ai/en/articles/12062933-which-meshy-plan-is-right-for-you-free-vs-pro-vs-premium-vs-ultra), s/f exacta: confirma USD 20/mes Pro y ausencia de nuevas descargas Free, salvo modelos anteriores de pago. La fecha relativa devolvió «más de un mes» al revisor, frente a «más de dos semanas» al autor de 02: usar s/f y fecha de consulta. Promoción inicial no equivale a precio recurrente.
- [Meshy Terms](https://www.meshy.ai/terms-of-use), 19-09-2026: las distinciones Free CC BY/pago, servicio incorporado y contenido comunitario están sustentadas. Hay discrepancia con tabla de ayuda y mensajes de privacidad; conservar esa incertidumbre y no prometer privacidad ni propiedad intelectual exclusiva por contratar Pro.
- [Mixamo FAQ](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html), 14-09-2021: comercial gratuito verificado. Es una página antigua aún oficial; no usar su disponibilidad como fecha de actualización reciente. El permiso para distribuir archivos crudos no fue confirmado en las fuentes investigadas. No hace falta resolverlo para recomendar Blender+CC0.

## Evidencia que falta antes de producción

- Inventario real de los ZIP gratuitos y comprobación de licencias incluidas; no se descargaron durante la investigación.
- Importación y retarget de un asset real en el Godot 4.7.1 local; docs `stable` son un alias mutable, no una versión instalada.
- Inventario actual de animaciones específicamente futbolísticas en Mixamo/Quaternius. Carrera y emotes no implican patada/estirada/captura correctas.
- Calidad de pesos y contactos en las proporciones elegidas. Retarget no adapta mágicamente manos al balón ni pie de apoyo al piso.
- Rendimiento y temperatura en teléfono objetivo, aún no identificado.
- Validación visual con las cámaras aceptadas y ambos personajes personalizados; no se modificó el juego para este informe.

## Criterio de decisión

La recomendación de una base CC0 editada en Blender se sostiene por licencia simple, control artístico y compatibilidad anunciada. La incertidumbre restante se resuelve con un hito pequeño —un delantero, una espera, una patada— antes de comprar un catálogo completo, producir variantes o reescribir la lógica del partido.

## Revisión final de los informes 04 y 05 (24/09/2026)

- 04 documenta correctamente que el proyecto usa Compatibility y que el cambio exige un adaptador, no solo importar GLB. Sus 30–60 huesos son una propuesta distinta de 03 (24–40): el objetivo consolidado es 24–40 huesos deformadores inicialmente, aceptar más si el rig escogido lo exige y medir.
- Las primeras versiones de 04 y 05 proponían 6–12k triángulos y un look cartoon suave. Tras la corrección del usuario, ambos informes se actualizaron: 8–16k tris es el nuevo presupuesto inicial para superficies humanas suaves, no dato original ni requisito absoluto; 05 ahora recomienda materiales estándar y luz deportiva.
- Los ejemplos MIT de toon/contorno se documentan porque se pidieron en el rol 5, con links de licencia. **No se recomienda aplicarlos** al objetivo visual final ni se verificó su funcionamiento en nuestro Compatibility 4.7.
- 04 y 05 se basan en documentación Godot estable/versionada y fuentes de código de autores. Sus resultados son investigación; no hay prueba de importación ni de rendimiento móvil en este trabajo.

## Auditoría independiente final del informe unificado (24/09/2026)

Leídos 00–05 e INFORME.md. Contrasté de nuevo afirmaciones puntuales con fuentes primarias; los hallazgos siguientes son correcciones de precisión y límites de evidencia, no una validación del paquete en ejecución.

1. **Referencia de los 56 huesos:** 03 afirma correctamente que `SkeletonProfileHumanoid` contiene 56 huesos, pero enlaza la clase genérica `SkeletonProfile`. Citar la [clase concreta `SkeletonProfileHumanoid`](https://docs.godotengine.org/en/stable/classes/class_skeletonprofilehumanoid.html), que documenta `bone_size = 56`; esto describe el perfil de referencia, **no** un mínimo requerido para nuestra malla. INFORME.md ya distingue perfil y presupuesto propio de 24–40 huesos deformadores.
2. **Cuatro pesos por vértice:** 04 e INFORME.md los presentan como decisión conservadora; la fuente `import_configuration.html` enlazada no establece por sí sola que cuatro sea un límite del renderer Compatibility. Mantenerlo etiquetado **P** (presupuesto de exportación del proyecto), sin decir que Godot exige exactamente cuatro. Verificar el GLB real antes de fijarlo como límite técnico.
3. **SSAO y glow en Compatibility:** la [documentación de Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/3d/environment_and_post_processing.html) confirma SSAO simplificado desde 4.6 y glow con controles reducidos. 05 lo indica bien. No trasladar una tabla de Godot 4.0 a esta instalación 4.7.1.
4. **Precio/licencia de Quaternius:** las [páginas oficiales de Base Characters](https://quaternius.itch.io/universal-base-characters) y [Animation Library](https://quaternius.itch.io/universal-animation-library), consultadas el 24/09/2026, confirman CC0, Standard descargable a precio libre, Source a USD 19,99 y USD 14,99 respectivamente. También confirman 13k tris promedio para el **pack Base**. No se verificó qué cuerpos/peinados/clips concretos contiene cada ZIP gratuito; por eso el pipeline A depende de inspección real antes de iniciar modelado y no garantiza disponer de una base atlética apropiada a costo cero.
5. **Mixamo:** la [FAQ oficial de Adobe](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html), fechada 14/09/2021 y accesible el 24/09/2026, confirma gratuidad con Adobe ID y uso en juegos comerciales. No establece en esa misma sección un inventario de clips futbolísticos ni permiso inequívoco para republicar archivos fuente sin procesar. Los informes separan correctamente esas dudas.
6. **Meshy:** su [tabla actual](https://help.meshy.ai/en/articles/12062933-which-meshy-plan-is-right-for-you-free-vs-pro-vs-premium-vs-ultra) muestra Pro USD 20/mes y ninguna descarga nueva en Free; la fecha editorial solo aparece relativa ("hace más de un mes" al consultar el 24/09/2026). Su fila `Private & CC BY 4.0` para pago es ambigua frente a los [términos fechados 19/09/2026](https://www.meshy.ai/terms-of-use). Los informes hacen bien en no prometer exclusividad, privacidad ni exportación gratuita. Revalidar las condiciones antes de contratar o subir referencias privadas.
7. **Alcance y fidelidad:** INFORME.md cubre seis roles distribuidos en tandas y evita simular simultaneidad; distingue observación visual, documentación y propuesta. Las capturas oficiales prueban apariencia visible, pero no revelan topología, shaders ni rig. El rango 8–16k triángulos, 1024² y 24–40 huesos es una **hipótesis de producción**, no especificación de Football Strike. Los 30–60 h del primer delantero y 46–90 h totales combinan trabajo artístico e integración con experiencia básica; no son compromiso de calendario ni incluyen aprendizaje de principiante. Para el pedido actual, el criterio decisivo debe ser comparación visual de una primera silueta/pose desde la cámara real antes de ampliar la plantilla.
8. **Shaders de terceros:** los ejemplos [eldskald MIT](https://github.com/eldskald/godot4-cel-shader/blob/main/LICENSE) y [EMBYRDEV MIT](https://github.com/EMBYRDEV/godot-toon-outline/blob/main/LICENSE) satisfacen la petición investigativa de ejemplos libres. No están integrados ni probados en Godot 4.7.1 Compatibility, y el efecto de contorno/toon no corresponde a la dirección final indicada por el usuario.

**Estado:** no encontré una contradicción que invalide la recomendación de ensayar una base CC0 muy adaptada en Blender. La decisión de continuar con ella requiere primero verificar el contenido real de Standard y aprobar visualmente un futbolista original desde el partido; si su cara/anatomía sigue pareciendo demasiado cartoon, pasar a modelado propio, sin invertir antes en variantes o paquetes pagos.

**Correcciones aplicadas tras auditoría:** 03 cita ahora `SkeletonProfileHumanoid` de Godot 4.7 para los 56 huesos de referencia; INFORME aclara que las cuatro influencias por vértice son una elección de exportación y que el muestreo inicial sigue a Blender. También distingue uniformes por parámetro de instancia o por material separado, según las regiones del modelo.
