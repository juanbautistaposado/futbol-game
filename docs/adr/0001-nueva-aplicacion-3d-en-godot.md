# Nueva aplicación 3D en Godot dentro del repositorio

La evolución será una nueva aplicación 3D hecha con Godot y GDScript, ubicada junto al MVP Phaser existente. Elegimos esta separación porque el juego actual acopla reglas, coordenadas y presentación 2D, mientras que el nuevo núcleo necesita simulación espacial, cámara, animaciones y colisiones; conservar el MVP evita perder una referencia jugable. Godot, bajo licencia MIT, permite producir builds web, Windows y macOS sin costo de motor.

## Considered Options

- Convertir incrementalmente el juego Phaser actual a 3D.
- Construir el 3D con Three.js y TypeScript.
- Crear un repositorio independiente para el 3D.

## Consequences

La lógica de tiro podrá reinterpretarse, pero no se portará el `GameScene` ni la UI 2D. El MVP actual queda sin cambios y el 3D tendrá sus propios assets, escenas y builds.
