import Phaser from "phaser";
import { getBestScore } from "../storage";

export class MenuScene extends Phaser.Scene {
  constructor() {
    super("MenuScene");
  }

  create(): void {
    this.drawBackdrop();

    this.add
      .text(512, 124, "TIROS LIBRES", {
        fontFamily: "Inter, Arial",
        fontSize: "64px",
        color: "#f8fafc",
        fontStyle: "800"
      })
      .setOrigin(0.5);

    this.add
      .text(512, 192, "7 tiros. Arrastra desde la pelota, apunta y suelta.", {
        fontFamily: "Inter, Arial",
        fontSize: "24px",
        color: "#d7f7ff"
      })
      .setOrigin(0.5);

    this.add
      .text(512, 260, `Mejor marca: ${getBestScore()}/7`, {
        fontFamily: "Inter, Arial",
        fontSize: "28px",
        color: "#ffe08a",
        fontStyle: "700"
      })
      .setOrigin(0.5);

    const button = this.add
      .rectangle(512, 370, 280, 70, 0xf97316)
      .setStrokeStyle(3, 0xffedd5)
      .setInteractive({ useHandCursor: true });

    const label = this.add
      .text(512, 370, "JUGAR", {
        fontFamily: "Inter, Arial",
        fontSize: "30px",
        color: "#111827",
        fontStyle: "900"
      })
      .setOrigin(0.5);

    button.on("pointerover", () => button.setFillStyle(0xfb923c));
    button.on("pointerout", () => button.setFillStyle(0xf97316));
    button.on("pointerdown", () => this.scene.start("GameScene"));
    label.setInteractive({ useHandCursor: true }).on("pointerdown", () => {
      this.scene.start("GameScene");
    });

    this.add
      .text(512, 522, "Tip: los tiros muy centrados son mas faciles de atajar.", {
        fontFamily: "Inter, Arial",
        fontSize: "20px",
        color: "#b7d4df"
      })
      .setOrigin(0.5);
  }

  private drawBackdrop(): void {
    const graphics = this.add.graphics();
    graphics.fillGradientStyle(0x0a1720, 0x0a1720, 0x123827, 0x123827, 1);
    graphics.fillRect(0, 0, 1024, 640);
    graphics.fillStyle(0x1f7a3a, 1);
    graphics.fillRect(0, 460, 1024, 180);
    graphics.lineStyle(3, 0xe5f7df, 0.35);
    graphics.strokeEllipse(512, 640, 620, 210);
    graphics.lineBetween(252, 640, 382, 460);
    graphics.lineBetween(772, 640, 642, 460);
  }
}
