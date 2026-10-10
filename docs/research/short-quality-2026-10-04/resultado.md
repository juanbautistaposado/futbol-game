# Paso 1: short del jugador

Se ajustó únicamente el short de `footballer_v3.blend` y se exportó su GLB para Godot. Pendiente de confirmación visual del usuario antes de continuar con mangas, pecho o textura. No se publicó esta pasada.

- Ruedo: de 0,715 m a 0,695 m en coordenadas del modelo.
- Entrepierna: descenso gradual, hasta 3,8 cm en la zona central, con un descenso adicional de 1,8 cm respecto del ruedo. Se conserva una abertura pequeña y la cintura continua.
- Laterales inferiores: 2 mm de holgura adicional, sin mover la cintura ni cambiar la escala del personaje.
- Se recalculó únicamente la altura UV2 del short respecto del nuevo ruedo para conservar su vivo inferior. Las UV de la camiseta permanecen idénticas.

La auditoría previa al guardado compara posiciones de todas las regiones ajenas al short, topología, pesos, matrices de huesos, curvas y tangentes de animación, paleta, UV0 y UV2 ajenas al short. Todos los controles pasaron; ver `auditoria.json`. Se conservan los 53 huesos y los ocho clips. No se aplicó el modificador Armature ni se agregó o eliminó geometría.

Capturas revisadas en Godot: `short.png`, `perfil.png`, `patada.png` (0,4 s) y `patada-alta.png` (0,6 s). En las poses revisadas no se observa piel atravesando el short ni una ruptura de la entrepierna.

Validación: importación en Godot completada; `athlete_v3_test.gd` y `kick_contact_and_dive_test.gd` pasaron; sintaxis Python y `git diff --check` correctos. La comprobación visual corresponde a estas poses, no a una simulación de tela.

Implementación reproducible: `apps/free-kick-3d/tools/tailor_footballer_shorts.py`, ejecutada por el generador después del ajuste de camiseta. Rechaza la aplicación acumulativa sobre un archivo ya ajustado. Copia previa de esta sesión: `/tmp/footballer-before-short-pass.blend`.
