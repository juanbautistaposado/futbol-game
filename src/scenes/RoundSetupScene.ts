import Phaser from "phaser";
import { getBestScore, getSelectedShotCount, saveSelectedShotCount } from "../storage";

export class RoundSetupScene extends Phaser.Scene {
  private shotCount = 7;
  private shotCountText!: Phaser.GameObjects.Text;
  private bestScoreText!: Phaser.GameObjects.Text;

  constructor() {
    super("RoundSetupScene");
  }

  create(): void {
    this.shotCount = getSelectedShotCount();
    this.drawBackdrop();

    this.add
      .text(512, 116, "ELEGIR TIROS", {
        fontFamily: "Inter, Arial",
        fontSize: "54px",
        color: "#f8fafc",
        fontStyle: "900"
      })
      .setOrigin(0.5);

    this.add
      .text(512, 184, "Antes de jugar, elige cuantas chances quieres en la ronda.", {
        fontFamily: "Inter, Arial",
        fontSize: "22px",
        color: "#d7f7ff"
      })
      .setOrigin(0.5);

    this.add
      .rectangle(512, 324, 420, 160, 0x0e2230, 0.9)
      .setStrokeStyle(2, 0x8ecae6, 0.6);

    this.add
      .text(512, 270, "Cantidad de tiros", {
        fontFamily: "Inter, Arial",
        fontSize: "26px",
        color: "#f8fafc",
        fontStyle: "800"
      })
      .setOrigin(0.5);

    this.createStepperButton(390, 324, "-", () => this.changeShotCount(-1));
    this.shotCountText = this.add
      .text(512, 316, String(this.shotCount), {
        fontFamily: "Inter, Arial",
        fontSize: "60px",
        color: "#fde68a",
        fontStyle: "900"
      })
      .setOrigin(0.5);
    this.createStepperButton(634, 324, "+", () => this.changeShotCount(1));

    this.bestScoreText = this.add
      .text(512, 372, "", {
        fontFamily: "Inter, Arial",
        fontSize: "20px",
        color: "#d7f7ff",
        fontStyle: "700"
      })
      .setOrigin(0.5);

    const playButton = this.add
      .rectangle(512, 478, 280, 66, 0xf97316)
      .setStrokeStyle(3, 0xffedd5)
      .setInteractive({ useHandCursor: true });

    const playLabel = this.add
      .text(512, 478, "EMPEZAR", {
        fontFamily: "Inter, Arial",
        fontSize: "30px",
        color: "#111827",
        fontStyle: "900"
      })
      .setOrigin(0.5);

    const startRound = () => {
      saveSelectedShotCount(this.shotCount);
      this.scene.start("GameScene", { shotLimit: this.shotCount });
    };

    playButton.on("pointerover", () => playButton.setFillStyle(0xfb923c));
    playButton.on("pointerout", () => playButton.setFillStyle(0xf97316));
    playButton.on("pointerdown", startRound);
    playLabel.setInteractive({ useHandCursor: true }).on("pointerdown", startRound);

    const backButton = this.add
      .rectangle(512, 554, 220, 54, 0x163142)
      .setStrokeStyle(2, 0x8ecae6)
      .setInteractive({ useHandCursor: true });

    const backLabel = this.add
      .text(512, 554, "VOLVER", {
        fontFamily: "Inter, Arial",
        fontSize: "24px",
        color: "#d7f7ff",
        fontStyle: "800"
      })
      .setOrigin(0.5);

    backButton.on("pointerover", () => backButton.setFillStyle(0x1f4f68));
    backButton.on("pointerout", () => backButton.setFillStyle(0x163142));
    backButton.on("pointerdown", () => this.scene.start("MenuScene"));
    backLabel.setInteractive({ useHandCursor: true }).on("pointerdown", () => {
      this.scene.start("MenuScene");
    });

    this.input.keyboard?.once("keydown-ESC", () => this.scene.start("MenuScene"));
    this.refreshShotCount();
  }

  private changeShotCount(delta: number): void {
    this.shotCount = Phaser.Math.Clamp(this.shotCount + delta, 5, 15);
    this.refreshShotCount();
  }

  private refreshShotCount(): void {
    this.shotCountText.setText(String(this.shotCount));
    this.bestScoreText.setText(`Mejor marca para ${this.shotCount} tiros: ${getBestScore(this.shotCount)}/${this.shotCount}`);
  }

  private createStepperButton(x: number, y: number, label: string, onPress: () => void): void {
    const button = this.add
      .rectangle(x, y, 54, 54, 0x163142)
      .setStrokeStyle(2, 0x8ecae6)
      .setInteractive({ useHandCursor: true });

    const text = this.add
      .text(x, y, label, {
        fontFamily: "Inter, Arial",
        fontSize: "30px",
        color: "#f8fafc",
        fontStyle: "900"
      })
      .setOrigin(0.5);

    button.on("pointerover", () => button.setFillStyle(0x1f4f68));
    button.on("pointerout", () => button.setFillStyle(0x163142));
    button.on("pointerdown", onPress);
    text.setInteractive({ useHandCursor: true }).on("pointerdown", onPress);
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
