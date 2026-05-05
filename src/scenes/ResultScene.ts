import Phaser from "phaser";
import type { RoundResultData } from "../types";

export class ResultScene extends Phaser.Scene {
  constructor() {
    super("ResultScene");
  }

  create(data: RoundResultData): void {
    const result = data.goals >= 5 ? "GRAN RONDA" : data.goals >= 3 ? "BUENA RONDA" : "A SEGUIR PROBANDO";

    this.drawBackdrop();

    this.add
      .text(512, 120, result, {
        fontFamily: "Inter, Arial",
        fontSize: "58px",
        color: "#f8fafc",
        fontStyle: "900"
      })
      .setOrigin(0.5);

    this.add
      .text(512, 226, `${data.goals}/${data.shots}`, {
        fontFamily: "Inter, Arial",
        fontSize: "112px",
        color: data.isNewBest ? "#fde047" : "#86efac",
        fontStyle: "900"
      })
      .setOrigin(0.5);

    this.add
      .text(512, 324, data.isNewBest ? "Nuevo mejor puntaje" : `Mejor puntaje: ${data.bestScore}/7`, {
        fontFamily: "Inter, Arial",
        fontSize: "28px",
        color: "#d7f7ff",
        fontStyle: "700"
      })
      .setOrigin(0.5);

    const playAgain = this.add
      .rectangle(512, 438, 320, 70, 0xf97316)
      .setStrokeStyle(3, 0xffedd5)
      .setInteractive({ useHandCursor: true });

    const label = this.add
      .text(512, 438, "OTRA RONDA", {
        fontFamily: "Inter, Arial",
        fontSize: "28px",
        color: "#111827",
        fontStyle: "900"
      })
      .setOrigin(0.5);

    playAgain.on("pointerover", () => playAgain.setFillStyle(0xfb923c));
    playAgain.on("pointerout", () => playAgain.setFillStyle(0xf97316));
    playAgain.on("pointerdown", () => this.scene.start("GameScene"));
    label.setInteractive({ useHandCursor: true }).on("pointerdown", () => {
      this.scene.start("GameScene");
    });

    this.add
      .text(512, 530, "Esc para volver al menu", {
        fontFamily: "Inter, Arial",
        fontSize: "19px",
        color: "#b7d4df"
      })
      .setOrigin(0.5);

    this.input.keyboard?.once("keydown-ESC", () => this.scene.start("MenuScene"));
  }

  private drawBackdrop(): void {
    const graphics = this.add.graphics();
    graphics.fillGradientStyle(0x0a1720, 0x0a1720, 0x164e35, 0x164e35, 1);
    graphics.fillRect(0, 0, 1024, 640);
    graphics.lineStyle(4, 0xffffff, 0.1);
    for (let y = 90; y < 640; y += 82) {
      graphics.lineBetween(0, y, 1024, y - 34);
    }
  }
}
