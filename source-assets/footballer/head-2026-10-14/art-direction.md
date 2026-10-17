# Cabeza reconstruida — 14 de octubre de 2026

Objetivo autorizado: reemplazar la anatomía facial irregular, construir ojos
separados y asignar una textura facial dedicada. Dirección: atleta masculino
adulto, anatomía natural y detalle legible en el editor y durante el partido.

Godot 4.7.1 Compatibility, metros, Blender Z arriba / -Y frente. Se conservan
el rig de 53 huesos y los ocho clips. Cuerpo, uniforme y controles permanecen
en sus fuentes actuales. La cabeza se adapta desde `footballer_v4.blend`, cuya
anatomía y UV proceden de MPFB/MakeHuman CC0; no se usan modelos de Football Strike.

Atlas facial dedicado 2048² como objetivo, mipmaps y muestreo anisotrópico.
Mayor densidad frontal, menor en cuero cabelludo posterior. Albedo sin luz
direccional; variación de roughness y microrelieve discretos. Párpados y labios
en geometría; esclera/iris/córnea separados del pigmento de piel. Tintes de piel,
pelo y barba opcional deben seguir funcionando para delantero y arquero.

La textura generada se valida en la malla, con comparaciones de frente, perfil,
piel clara/oscura y barba. La imagen UV por sí sola no prueba el resultado.
