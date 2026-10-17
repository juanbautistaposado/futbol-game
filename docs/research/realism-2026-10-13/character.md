# Materiales del jugador — 13 de octubre de 2026

La prueba de material blanco con/sin luces eliminó las líneas oscuras; reaparecieron
usando sólo el albedo. Desactivar normales no las quitó. Diagnóstico: detalle del
atlas o contaminación de islas UV, no huecos en la geometría. La revisión comprime
el contraste del color original sólo en regiones semánticas de tela; conserva
piel, pelo, número/nombre y personalización. El tejido usa detalle filtrado por
derivadas, rugosidad variable y respuesta de fibras iluminada por las luces.
Piel y guantes conservan sus pigmentos, con reflejos más amplios y controlados.

Fuentes: [Godot, materiales PBR](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html)
y [Godot, shaders espaciales](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html).
La separación entre albedo, normales, rugosidad y respuesta especular evita
confundir una sombra horneada en la textura con el sombreado de la escena.

Ver `after-shirt.png`. Prueba nativa del editor aprobada. Auditoría GLB:
esqueleto, ocho clips y geometría/UV/pesos de cabeza y botines preservados.
No se reexportaron GLB ni se editaron controladores de animación en esta tarea.
