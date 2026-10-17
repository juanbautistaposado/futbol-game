# Iluminación de estadio — 13 de octubre de 2026

## Diagnóstico local

El proyecto usa `gl_compatibility` también en móvil/web. `pitch_lighting.gd` comparte la iluminación del partido y del estadio del menú: ambiente de color uniforme a 0,62, sol a 0,88 y alcance de sombras de 145 m. Los dos clientes crean un cielo degradado sin nubes. El relleno uniforme hace que los materiales cambien poco entre zonas orientadas al cielo y hacia el suelo.

## Investigación primaria

- El cielo interviene tanto en el fondo como en iluminación y reflejos. Combinar ambiente del cielo con una contribución de color permite conservar legibilidad en sombras. Fuente: [Godot: Environment and post-processing](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html).
- Compatibility permite niebla de profundidad, tonemapping, ajustes e iluminación basada en el cielo. La tabla oficial excluye volumétricas, SSR, SDFGI y PCSS direccional en este renderer. Por eso esos efectos no forman parte de esta mejora. Fuente: [Godot: Overview of renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html).
- Un shader de cielo puede calcular nubes en la radiancia una vez y reutilizarla al dibujar el fondo. Referenciar `TIME` o `POSITION` provoca actualizaciones frecuentes; se evita en este cielo estático. Fuente: [Godot: Sky shaders](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/sky_shader.html).
- El modo Quality está pensado para cielos estáticos; 256 píxeles por cara ofrece un presupuesto moderado. Tamaños de 512 o mayores pueden causar dificultades en hardware limitado. Fuente: [Godot: Sky](https://docs.godotengine.org/en/stable/classes/class_sky.html).
- Reducir distancia máxima de sombras aumenta la resolución útil cerca de cámara. Las cascadas concentran detalle; mezclarlas tiene costo, por lo que se mantiene el modo de cuatro cascadas ya predeterminado. Fuente: [Godot: DirectionalLight3D](https://docs.godotengine.org/en/stable/classes/class_directionallight3d.html).

## Dirección elegida

Estadio diurno de transmisión deportiva: luz principal ligeramente cálida, relleno del cielo más frío, blancos de camiseta con detalle, nubes estratificadas y una separación atmosférica tenue para las tribunas lejanas. El objetivo es materialidad y profundidad, conservando visibilidad de la pelota y de las líneas. No se añaden luces dinámicas extra ni un cambio de renderer.

## Implementación y validación

Implementado y capturado por el coordinador. Ownership: `pitch_lighting.gd` y un shader de cielo nuevo. Las animaciones, la cámara y la lógica del partido están fuera del alcance de este agente.
