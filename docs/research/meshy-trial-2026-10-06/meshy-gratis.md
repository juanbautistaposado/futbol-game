# Prueba gratuita de Meshy para el futbolista

Consulta: **6 de octubre de 2026**. Investigación documental realizada únicamente sobre fuentes oficiales de Meshy. El agente investigador no accedió a cuentas, subió archivos ni consumió créditos; se incorpora aparte la observación de interfaz comunicada por el agente coordinador. Las páginas contienen contradicciones que obligan a contrastar documentación y cuenta real.

## Decisión

Hacer **una generación Image to 3D con Meshy 6 Lite**, usando una imagen propia preparada fuera de Meshy: un solo futbolista completo, vista frontal en pose A, brazos y piernas separados, fondo simple, camiseta suelta, short hasta medio muslo y musculatura moderada. Primero evaluar la malla blanca; agregar textura únicamente si la silueta mejora claramente. Descargar GLB y comparar en una escena aislada antes de pensar en reemplazar partes del personaje actual.

La captura de Football Strike sirve para analizar proporciones y ropa, pero **no es una buena entrada directa**: presenta dos personajes, brazos cruzados, oclusiones y elementos de interfaz. Mi inferencia es que generaría ambigüedad o geometría fusionada. La guía oficial recomienda un único sujeto claro y explica que la geometría oculta debe inferirse. [Image to 3D](https://help.meshy.ai/en/articles/9996860-how-to-use-meshy-image-to-3d).

## Lo gratuito que sí podemos planificar

| Elemento | Evidencia actual | Consecuencia para la prueba |
| --- | --- | --- |
| Créditos | 100 mensuales; reinicio el día 1 a las 00:00 UTC, sin acumulación | Una prueba pequeña entra holgadamente si quedan créditos |
| Descargas | 10 mensuales para modelos **Meshy 6 Lite** | Seleccionar Lite explícitamente |
| Meshy 6 / 7 | Sus modelos no se descargan en Free | No gastar la prueba en versiones que exigen pago para exportar |
| API | No incluida en Free | Usar la aplicación web |
| Licencia | CC BY 4.0, uso comercial con atribución a Meshy | Guardar licencia y procedencia si incorporamos el resultado |

Fuente para esta tabla: [What Is Included on the Free Plan](https://help.meshy.ai/en/articles/15696428-what-is-included-on-the-free-plan). Esta página específica debe prevalecer sobre resúmenes generales, pero las cuotas disponibles aún deben comprobarse en la cuenta.

La tabla de costes de la aplicación web indica **10 créditos para la geometría Lite** y **10 adicionales para textura 2K/4K**. Propongo presupuesto inicial de **20 créditos**, una generación y una textura condicional, sin gastar el resto de los 100. La propia página aclara que la cifra vigente es la mostrada en la interfaz antes de generar. No usar costes de API como referencia para esta prueba. [Costes de tareas web](https://help.meshy.ai/en/articles/10000507-how-many-credits-does-each-generation-task-cost).

**No crear la imagen de referencia dentro de Meshy Free:** la guía específica Text to Image afirma que el botón requiere un plan superior. Prepararla mediante un render propio, dibujo o generador externo al que ya tengamos acceso. [Text to Image, requisitos de plan](https://help.meshy.ai/en/articles/13696156-how-to-use-the-text-to-image-feature).

## La limitación que cambia el flujo

La comparación oficial atribuye a Lite generación desde texto e imagen y animación, pero **no Pose Control, Multi-view, Split ni Image Enhancement**. Por eso no podemos dar por hecho que un botón transforme los brazos cruzados de la captura en pose A. La pose limpia debe existir en la imagen de entrada. Tampoco planificar tres imágenes como entrada Lite ni separación automática de cuerpo y ropa. [Comparación de versiones](https://help.meshy.ai/en/articles/15697060-meshy-7-vs-meshy-6-vs-meshy-6-lite-which-ai-model-should-you-use).

La guía general de personajes aconseja Pose Control y advierte que escribir «T-pose» en un prompt no garantiza la postura; esos consejos dependen de una versión que admita el control. Para Lite, **Image to 3D con referencia ya posada es la decisión de investigación**, no una capacidad garantizada de corrección de pose. Se deben inspeccionar manos, axilas y separación de piernas antes de texturizar. [Problemas de pose, cara y manos](https://help.meshy.ai/en/articles/16102152-fix-character-pose-face-and-hand-issues-in-meshy).

### Contraste con la cuenta real

El coordinador informó durante esta investigación que hay una sesión existente abierta en Chrome, en `/es/workspace`: **Meshy 6 Lite seleccionado**, Generar muestra **10 créditos**, saldo **120 créditos** y **CC BY 4.0** preseleccionado. También aparece un interruptor Pose con coste 0 aun con Lite, contradiciendo la tabla de versiones. No se activó ni se comprobó su funcionamiento; la prueba seguirá usando referencia ya en pose A. Hay otro indicador con valor **17** cuyo significado no fue identificado: **no equivale a una cuota verificada de descargas**. Estas son observaciones transmitidas del estado de UI, no conclusiones de las páginas públicas.

## Pasos de una prueba concreta

1. Preparar una referencia original del futbolista en pose A. Mantener la paleta del proyecto y describir/representar torso contenido, piernas firmes y uniforme de fútbol; evitar números, escudos y textos en esta etapa.
2. Abrir la cuenta existente en la aplicación web. Verificar plan Free, saldo y descargas restantes; escoger **Model → Image to 3D → Meshy 6 Lite**. No cambiar a versiones de pago ni activar compras.
3. Cargar un PNG/JPG/WEBP con un solo sujeto. Meshy acepta esos formatos de imagen hasta 20 MB. Revisar versión y coste mostrado antes de ejecutar. [Carga y generación de imagen](https://help.meshy.ai/en/articles/9996860-how-to-use-meshy-image-to-3d).
4. Generar únicamente la malla. Examinar frente, lados y espalda: pecho, cuello, hombro/manga, entrepierna, caída del short y rodillas. Si el cuerpo no mejora, detener la prueba sin añadir textura.
5. Si la geometría convence, ejecutar una textura sencilla de la misma paleta. El dorsal y PLAYER conviene añadirlos después mediante UV/textura controlada; es una decisión de implementación para conservar letras legibles y colores configurables.
6. Descargar **GLB estático** y conservar un original sin modificaciones. La lista oficial admite GLB y BLEND entre las salidas. [Formatos soportados](https://help.meshy.ai/en/articles/9991884-what-3d-file-formats-does-meshy-support-full-export-list).
7. Normalizar tamaño/orientación y probar en Blender/Godot por separado. Un resultado visual mejor todavía requiere revisión de topología, UV y materiales. Adoptarlo sólo si mejora a distancia de cámara de juego y se puede adaptar al esqueleto existente.

Si el botón de descarga exige suscripción aun siendo Lite y quedando cuota, no pagar ni seguir generando: registrar la discrepancia de interfaz. No hay una segunda ruta gratuita garantizada en las fuentes consultadas.

## Rig, animaciones y fidelidad

Meshy Auto Rigging construye un nuevo esqueleto y pesos con nombres tipo Mixamo, y puede exportar GLB para Blender/Godot. **Eso no constituye evidencia de que preserve nuestro rig o nuestros clips.** Es preferible que esta primera prueba visual sea estática; integrar el candidato exigiría conservar el esqueleto existente y adaptar/revisar el skinning, con validación de patada y atajadas. [Auto Rigging](https://help.meshy.ai/en/articles/16231707-how-to-create-3d-animation-with-auto-rigging).

La plataforma no garantiza identidad exacta entre generaciones ni una reproducción perfecta de la referencia. Así que esta prueba evalúa si obtenemos una mejor base de silueta y ropa; no promete un personaje idéntico al de Football Strike. No regenerar cada jugador por separado: si una base resulta buena, reutilizarla mediante las variantes de materiales existentes. [Consistencia de personajes](https://help.meshy.ai/en/articles/16102614-how-to-keep-characters-consistent-in-meshy).

Para uso en tiempo real, la documentación de Meshy pide revisar topología que deforme bien, UV y presupuesto de triángulos, y recomienda medir en el motor. Sus cifras genéricas no prueban qué presupuesto tendrá nuestro juego; no adoptar automáticamente la etiqueta «game-ready». [Preparación para juegos](https://help.meshy.ai/en/articles/15723950-how-to-make-meshy-models-game-ready).

## Licencia, referencias y visibilidad

Los **términos actualizados el 19 de septiembre de 2026** establecen CC BY 4.0 para las salidas Free (§3.2); Meshy conserva su propiedad. El usuario debe tener permiso para el material que sube (§2.2). Por eso la entrada aconsejada es una referencia original, en lugar de subir la captura completa del juego. Los términos permiten usar inputs/outputs de usuarios no Enterprise para entrenamiento (§2.9). Publicar voluntariamente en Community tiene condiciones distintas: modelos bajo CC0 e imágenes bajo CC BY-NC (§3.3). **No publicar la prueba en Community.** [Términos de Meshy](https://www.meshy.ai/terms-of-use).

No encontré evidencia suficiente para afirmar que toda generación Free se vuelve visible automáticamente en la comunidad. La documentación distingue licencia/propiedad privada y el acto de publicar en Community; tampoco es correcto prometer privacidad exclusiva del resultado Free. La FAQ dice que las cargas permanecen confidenciales, con posibilidad de entrenamiento futuro para no Enterprise. [Datos y privacidad](https://help.meshy.ai/en/articles/15724182-is-meshy-safe-and-private-data-and-training-faq).

Si se usa el asset, guardar procedencia, versión, fecha y licencia; dar crédito visible a Meshy y conservar registro de modificaciones. La guía de propiedad proporciona una fórmula de atribución a Meshy. [Propiedad de modelos](https://help.meshy.ai/en/articles/10137554-what-is-the-ownership-of-the-generated-models).

## Contradicciones oficiales verificadas

| Tema | Discrepancia | Decisión |
| --- | --- | --- |
| Descargas Free | El comparador de planes dice que no hay descargas; la guía específica Free permite 10 Lite | Guiarse por la excepción Lite y comprobar UI |
| Uso comercial Free | Una guía de marketplaces lo restringe; términos §3.2 y página Free especifican CC BY 4.0 | Priorizar términos y licencia específica |
| Pose | Guías generales muestran A/Tpose; tabla por versión marca Lite sin Pose | Preparar pose antes de subir |
| Creación de imagen | Guías generales describen generadores; requisitos específicos excluyen Free | Referencia fuera de Meshy |
| Entrenamiento | Pricing dice no entrenamiento sin consentimiento; términos nuevos permiten datos no Enterprise | No prometer exclusión de entrenamiento |

Páginas que contradicen las específicas: [Comparador de planes](https://help.meshy.ai/en/articles/12062933-which-meshy-plan-is-right-for-you-free-vs-pro-vs-premium-vs-ultra), [guía de marketplaces](https://help.meshy.ai/en/articles/16102951-can-you-publish-or-sell-meshy-models-on-marketplaces), [pricing](https://www.meshy.ai/pricing). Las contradicciones impiden garantizar cuotas o botones desde documentación sola; se resuelven para la prueba observando la cuenta antes de gastar créditos.
