import Phaser from "phaser";
import { getBestScore, getSelectedPlayerCount, getSelectedShotCount, saveSelectedPlayerCount, saveSelectedShotCount } from "../storage";
import type { RoundSetupData } from "../types";

export class RoundSetupScene extends Phaser.Scene {
  private shotCount = 7;
  private playerCount = 1;
  private shotCountText!: Phaser.GameObjects.Text;
  private playerCountText!: Phaser.GameObjects.Text;
  private summaryText!: Phaser.GameObjects.Text;

  constructor() {
    super("RoundSetupScene");
  }

  create(): void {
    this.shotCount = getSelectedShotCount();
    this.playerCount = getSelectedPlayerCount();
    this.drawBackdrop();

    this.add
      .text(512, 108, "CONFIGURAR RONDA", {
        fontFamily: "Inter, Arial",
        fontSize: "54px",
        color: "#f8fafc",
        fontStyle: "900"
      })
      .setOrigin(0.5);

    this.add
      .text(512, 170, "Elige cuantas chances tendra cada jugador antes de empezar.", {
        fontFamily: "Inter, Arial",
        fontSize: "22px",
        color: "#d7f7ff"
      })
      .setOrigin(0.5);

    this.createSetupCard({
      x: 332,
      y: 314,
      title: "Cantidad de tiros",
      valueColor: "#fde68a",
      helper: "Cada persona pateara esa cantidad de veces.",
      onDecrease: () => this.changeShotCount(-1),
      onIncrease: () => this.changeShotCount(1),
      onValueCreated: (text) => {
        this.shotCountText = text;
      }
    });

    this.createSetupCard({
      x: 692,
      y: 314,
      title: "Cantidad de jugadores",
      valueColor: "#93c5fd",
      helper: "Se van turnando: un tiro cada uno por vuelta.",
      onDecrease: () => this.changePlayerCount(-1),
      onIncrease: () => this.changePlayerCount(1),
      onValueCreated: (text) => {
        this.playerCountText = text;
      }
    });

    this.summaryText = this.add
      .text(512, 428, "", {
        fontFamily: "Inter, Arial",
        fontSize: "20px",
        color: "#d7f7ff",
        fontStyle: "700",
        align: "center"
      })
      .setOrigin(0.5);

    const playButton = this.add
      .rectangle(512, 500, 280, 66, 0xf97316)
      .setStrokeStyle(3, 0xffedd5)
      .setInteractive({ useHandCursor: true });

    const playLabel = this.add
      .text(512, 500, "EMPEZAR", {
        fontFamily: "Inter, Arial",
        fontSize: "30px",
        color: "#111827",
        fontStyle: "900"
      })
      .setOrigin(0.5);

    const startRound = () => {
      const data: RoundSetupData = {
        shotLimit: saveSelectedShotCount(this.shotCount),
        playerCount: saveSelectedPlayerCount(this.playerCount)
      };

      this.scene.start("GameScene", data);
    };

    playButton.on("pointerover", () => playButton.setFillStyle(0xfb923c));
    playButton.on("pointerout", () => playButton.setFillStyle(0xf97316));
    playButton.on("pointerdown", startRound);
    playLabel.setInteractive({ useHandCursor: true }).on("pointerdown", startRound);

    const backButton = this.add
      .rectangle(512, 576, 220, 54, 0x163142)
      .setStrokeStyle(2, 0x8ecae6)
      .setInteractive({ useHandCursor: true });

    const backLabel = this.add
      .text(512, 576, "VOLVER", {
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
    this.refreshSummary();
  }

  private createSetupCard(config: {
    x: number;
    y: number;
    title: string;
    valueColor: string;
    helper: string;
    onDecrease: () => void;
    onIncrease: () => void;
    onValueCreated: (text: Phaser.GameObjects.Text) => void;
  }): void {
    this.add
      .rectangle(config.x, config.y, 320, 164, 0x0e2230, 0.9)
      .setStrokeStyle(2, 0x8ecae6, 0.6);

    this.add
      .text(config.x, config.y - 56, config.title, {
        fontFamily: "Inter, Arial",
        fontSize: "26px",
        color: "#f8fafc",
        fontStyle: "800"
      })
      .setOrigin(0.5);

    this.createStepperButton(config.x - 112, config.y, "-", config.onDecrease);
    const valueText = this.add
      .text(config.x, config.y - 8, "", {
        fontFamily: "Inter, Arial",
        fontSize: "60px",
        color: config.valueColor,
        fontStyle: "900"
      })
      .setOrigin(0.5);
    this.createStepperButton(config.x + 112, config.y, "+", config.onIncrease);
    config.onValueCreated(valueText);

    this.add
      .text(config.x, config.y + 50, config.helper, {
        fontFamily: "Inter, Arial",
        fontSize: "18px",
        color: "#b7d4df"
      })
      .setOrigin(0.5);
  }

  private changeShotCount(delta: number): void {
    this.shotCount = Phaser.Math.Clamp(this.shotCount + delta, 5, 15);
    this.refreshSummary();
  }

  private changePlayerCount(delta: number): void {
    this.playerCount = Phaser.Math.Clamp(this.playerCount + delta, 1, 4);
    this.refreshSummary();
  }

  private refreshSummary(): void {
    this.shotCountText.setText(String(this.shotCount));
    this.playerCountText.setText(String(this.playerCount));

    const bestScore = getBestScore(this.shotCount);
    const totalShots = this.shotCount * this.playerCount;
    const summary =
      this.playerCount === 1
        ? `Mejor marca individual: ${bestScore}/${this.shotCount}\nTotal de remates en la ronda: ${totalShots}`
        : `Cada jugador pateara ${this.shotCount} veces.\nTotal de remates entre todos: ${totalShots}`;

    this.summaryText.setText(summary);
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
