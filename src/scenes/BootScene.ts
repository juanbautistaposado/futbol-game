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
    if (this.textures.exists("ball")) {
      this.textures.remove("ball");
    }

    const texture = this.textures.createCanvas("ball", 64, 64);
    const ctx = texture.context;
    const centerX = 32;
    const centerY = 32;
    const radius = 28;

    ctx.clearRect(0, 0, 64, 64);

    const ballPath = new Path2D();
    ballPath.arc(centerX, centerY, radius, 0, Math.PI * 2);

    ctx.save();
    ctx.clip(ballPath);

    const baseGradient = ctx.createRadialGradient(22, 18, 4, 32, 32, 34);
    baseGradient.addColorStop(0, "#ffffff");
    baseGradient.addColorStop(0.48, "#f3f6fb");
    baseGradient.addColorStop(0.78, "#d7dee8");
    baseGradient.addColorStop(1, "#9aa6b2");
    ctx.fillStyle = baseGradient;
    ctx.fillRect(0, 0, 64, 64);

    const shadowGradient = ctx.createRadialGradient(46, 46, 5, 48, 48, 28);
    shadowGradient.addColorStop(0, "rgba(15, 23, 42, 0.42)");
    shadowGradient.addColorStop(1, "rgba(15, 23, 42, 0)");
    ctx.fillStyle = shadowGradient;
    ctx.fillRect(0, 0, 64, 64);

    const highlightGradient = ctx.createRadialGradient(20, 18, 0, 20, 18, 17);
    highlightGradient.addColorStop(0, "rgba(255, 255, 255, 0.95)");
    highlightGradient.addColorStop(0.45, "rgba(255, 255, 255, 0.38)");
    highlightGradient.addColorStop(1, "rgba(255, 255, 255, 0)");
    ctx.fillStyle = highlightGradient;
    ctx.beginPath();
    ctx.arc(20, 18, 17, 0, Math.PI * 2);
    ctx.fill();

    const surfaceGradient = ctx.createLinearGradient(12, 12, 48, 52);
    surfaceGradient.addColorStop(0, "rgba(255, 255, 255, 0.18)");
    surfaceGradient.addColorStop(0.5, "rgba(255, 255, 255, 0)");
    surfaceGradient.addColorStop(1, "rgba(15, 23, 42, 0.14)");
    ctx.fillStyle = surfaceGradient;
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
    ctx.fill();

    ctx.strokeStyle = "rgba(148, 163, 184, 0.22)";
    ctx.lineWidth = 1.1;
    ctx.beginPath();
    ctx.ellipse(29, 31, 17, 24, Math.PI * 0.18, Math.PI * 0.28, Math.PI * 1.72);
    ctx.stroke();

    ctx.beginPath();
    ctx.ellipse(36, 30, 14, 22, -Math.PI * 0.12, Math.PI * 1.22, Math.PI * 0.22, true);
    ctx.stroke();

    ctx.restore();

    ctx.strokeStyle = "rgba(15, 23, 42, 0.88)";
    ctx.lineWidth = 2.2;
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
    ctx.stroke();

    texture.refresh();
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
