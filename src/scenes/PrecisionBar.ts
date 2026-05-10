import Phaser from "phaser";

export interface PrecisionBarConfig {
  x: number;
  y: number;
  width: number;
  height: number;
  scene: Phaser.Scene;
}

export class PrecisionBar {
  private scene: Phaser.Scene;
  private container!: Phaser.GameObjects.Container;
  private barGraphics!: Phaser.GameObjects.Graphics;
  private indicatorGraphics!: Phaser.GameObjects.Graphics;
  private x: number;
  private y: number;
  private width: number;
  private height: number;
  
  // Estado del indicador
  private indicatorPosition = 0.5; // 0 a 1, donde 0.5 es el centro
  private indicatorDirection = 1; // 1 o -1
  private indicatorSpeed = 2.5; // píxeles por frame
  private isActive = false;

  constructor(config: PrecisionBarConfig) {
    this.scene = config.scene;
    this.x = config.x;
    this.y = config.y;
    this.width = config.width;
    this.height = config.height;
    this.createBar();
  }

  private createBar(): void {
    this.barGraphics = this.scene.add.graphics().setDepth(15);
    this.indicatorGraphics = this.scene.add.graphics().setDepth(16);
    this.container = this.scene.add.container(this.x, this.y, [this.barGraphics, this.indicatorGraphics]).setDepth(15);
    this.draw();
  }

  private draw(): void {
    // Limpiar gráficos
    this.barGraphics.clear();
    this.indicatorGraphics.clear();

    // Dibujar barra con gradiente rojo → amarillo → verde → amarillo → rojo
    const barX = -this.width / 2;
    const barY = -this.height / 2;

    // Dividir la barra en 5 segmentos para simular el gradiente
    const segmentWidth = this.width / 5;
    const colors = [
      0xff4444, // Rojo
      0xffaa44, // Amarillo
      0x44dd44, // Verde
      0xffaa44, // Amarillo
      0xff4444  // Rojo
    ];

    for (let i = 0; i < 5; i++) {
      const x = barX + i * segmentWidth;
      this.barGraphics.fillStyle(colors[i], 1);
      this.barGraphics.fillRect(x, barY, segmentWidth, this.height);
    }

    // Borde de la barra
    this.barGraphics.lineStyle(2, 0xffffff, 0.8);
    this.barGraphics.strokeRect(barX, barY, this.width, this.height);

    // Línea del centro (referencia visual)
    const centerX = 0;
    this.barGraphics.lineStyle(2, 0xffffff, 0.4);
    this.barGraphics.lineBetween(centerX, barY - 4, centerX, barY + this.height + 4);

    // Dibujar indicador (bloque que se mueve)
    const indicatorX = barX + this.indicatorPosition * this.width;
    const indicatorWidth = this.width * 0.08; // 8% del ancho
    const indicatorY = barY - 6;

    this.indicatorGraphics.fillStyle(0xffffff, 1);
    this.indicatorGraphics.fillRect(indicatorX - indicatorWidth / 2, indicatorY, indicatorWidth, this.height + 12);
    this.indicatorGraphics.lineStyle(2, 0x000000, 1);
    this.indicatorGraphics.strokeRect(indicatorX - indicatorWidth / 2, indicatorY, indicatorWidth, this.height + 12);
  }

  show(): void {
    this.isActive = true;
    this.indicatorPosition = 0.5;
    this.indicatorDirection = 1;
    this.container.setVisible(true);
  }

  hide(): void {
    this.isActive = false;
    this.container.setVisible(false);
  }

  update(): void {
    if (!this.isActive) {
      return;
    }

    // Mover indicador
    this.indicatorPosition += (this.indicatorDirection * this.indicatorSpeed) / this.width;

    // Rebotar en los extremos
    if (this.indicatorPosition <= 0) {
      this.indicatorPosition = 0;
      this.indicatorDirection = 1;
    } else if (this.indicatorPosition >= 1) {
      this.indicatorPosition = 1;
      this.indicatorDirection = -1;
    }

    this.draw();
  }

  /**
   * Obtiene la presión actual (0 a 1)
   * 0.5 = precisión máxima (verde, centro)
   * > 0.5 o < 0.5 = desviación (amarillo/rojo, extremos)
   */
  getPrecision(): number {
    return this.indicatorPosition;
  }

  /**
   * Calcula la desviación horizontal basada en la posición del indicador
   * Retorna un valor que modifica la dirección X del tiro
   * 0 = sin desviación (verde, centro)
   * -1 a 1 = desviación máxima (rojo, extremos)
   */
  getDirectionDeviation(): number {
    // Mapear 0-1 a -1 a 1, con 0.5 siendo 0 (sin desviación)
    return (this.indicatorPosition - 0.5) * 2;
  }

  /**
   * Calcula el multiplicador de precisión
   * 1.0 = máxima precisión (verde)
   * 0.5 = precisión media (amarillo)
   * 0.0 = sin precisión (rojo, extremos)
   */
  getPrecisionMultiplier(): number {
    const distanceFromCenter = Math.abs(this.indicatorPosition - 0.5);
    // distanceFromCenter: 0 (centro) a 0.5 (extremos)
    // Mapear a multiplicador: 1.0 (centro) a 0.0 (extremos)
    return Math.max(0, 1 - distanceFromCenter * 2);
  }

  destroy(): void {
    this.barGraphics.destroy();
    this.indicatorGraphics.destroy();
    this.container.destroy();
  }
}
