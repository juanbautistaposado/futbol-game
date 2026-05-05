import Phaser from "phaser";

export class BootScene extends Phaser.Scene {
  constructor() {
    super("BootScene");
  }

  create(): void {
    this.createBallTexture();
    this.createKeeperTexture();
    this.scene.start("MenuScene");
  }

  private createBallTexture(): void {
    const graphics = this.add.graphics();
    graphics.fillStyle(0xf8fafc, 1);
    graphics.fillCircle(32, 32, 30);
    graphics.lineStyle(3, 0x1f2937, 1);
    graphics.strokeCircle(32, 32, 30);
    graphics.fillStyle(0x111827, 1);
    graphics.fillTriangle(32, 12, 42, 28, 22, 28);
    graphics.fillTriangle(16, 38, 31, 31, 27, 50);
    graphics.fillTriangle(48, 38, 37, 31, 37, 50);
    graphics.generateTexture("ball", 64, 64);
    graphics.destroy();
  }

  private createKeeperTexture(): void {
    const graphics = this.add.graphics();

    graphics.fillStyle(0xffd38a, 1);
    graphics.fillCircle(40, 14, 11);
    graphics.fillStyle(0x2563eb, 1);
    graphics.fillRoundedRect(25, 26, 30, 48, 8);
    graphics.lineStyle(10, 0xffd38a, 1);
    graphics.lineBetween(28, 34, 8, 56);
    graphics.lineBetween(52, 34, 72, 56);
    graphics.lineStyle(10, 0x111827, 1);
    graphics.lineBetween(31, 72, 21, 104);
    graphics.lineBetween(49, 72, 59, 104);
    graphics.fillStyle(0xf8fafc, 1);
    graphics.fillCircle(8, 56, 7);
    graphics.fillCircle(72, 56, 7);
    graphics.generateTexture("keeper", 80, 112);

    graphics.clear();
    graphics.fillStyle(0xffd38a, 1);
    graphics.fillCircle(48, 28, 11);
    graphics.fillStyle(0x2563eb, 1);
    graphics.fillRoundedRect(33, 42, 30, 50, 8);
    graphics.lineStyle(10, 0xffd38a, 1);
    graphics.lineBetween(36, 50, 14, 14);
    graphics.lineBetween(60, 50, 82, 14);
    graphics.lineStyle(10, 0x111827, 1);
    graphics.lineBetween(39, 88, 25, 122);
    graphics.lineBetween(57, 88, 71, 122);
    graphics.fillStyle(0xf8fafc, 1);
    graphics.fillCircle(12, 12, 8);
    graphics.fillCircle(84, 12, 8);
    graphics.generateTexture("keeper-stretch", 96, 132);

    graphics.destroy();
  }
}
