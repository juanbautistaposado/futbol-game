# Paso 2: transición hombro-manga

Se ajustó únicamente la transición lateral de la camiseta del jugador. La camiseta ya era una superficie conectada: no se agregó una pieza, no se soldaron vértices y no se modificó la topología.

Se aplicaron ocho pares de suavizado y expansión (Taubin), con influencia gradual siguiendo el eje del brazo. Esto reduce las irregularidades locales sin encoger bruscamente el volumen del hombro. El efecto se desvanece hacia el extremo de la manga y hacia el centro del torso. El desplazamiento máximo final es de 8,86 mm. Donde el suavizado perdería la separación respecto de la piel de la clavícula, se conserva la posición original.

La auditoría verifica que las posiciones ajenas a la región del ajuste, la topología, los pesos, los huesos, las curvas de animación, la paleta y todas las UV permanecen idénticos. El short de la pasada anterior, la cara, el pelo, los botines y el centro del pecho están protegidos. Se conservan 53 huesos y ocho clips. Ver `auditoria.json`.

Fuente: `source-assets/footballer/footballer_v3.blend`. Exportación: `apps/free-kick-3d/assets/footballer/footballer_v3.glb`. Ajuste reproducible: `apps/free-kick-3d/tools/tailor_footballer_sleeves.py`, integrado al final del generador, después del short. Rechaza aplicaciones acumulativas. Copia anterior de la sesión: `/tmp/footballer-before-sleeve-pass.blend`.

Revisión visual en Godot: `antes.png`, `despues.png`, `perfil.png`, `celebracion.png` y `patada.png`. No se observa piel atravesando la zona ajustada en estas capturas. Esta comprobación no equivale a una simulación de tela para cualquier pose posible.

La importación de Godot, `athlete_v3_test.gd` y `kick_contact_and_dive_test.gd` pasaron. Sintaxis Python y `git diff --check` correctos. Pendiente de confirmación visual del usuario antes del paso 3 (pecho). Esta pasada no se publicó.
