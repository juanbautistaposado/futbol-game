import Phaser from "phaser";
import { getPlayerAppearance, savePlayerAppearance } from "../storage";
import type { PlayerAppearance, PlayerHairColor } from "../types";

export class SettingsScene extends Phaser.Scene {
  private playerAppearance!: PlayerAppearance;
  private isEditingName = false;
  private nameDraft = "";
  private nameValueText!: Phaser.GameObjects.Text;
  private nameHintText!: Phaser.GameObjects.Text;
  private nameField!: Phaser.GameObjects.Rectangle;

  constructor() {
    super("SettingsScene");
  }

  create(): void {
    this.playerAppearance = getPlayerAppearance();
    this.nameDraft = this.playerAppearance.name;
    this.drawBackdrop();

    this.add
      .text(512, 92, "CONFIGURACION", {
        fontFamily: "Inter, Arial",
        fontSize: "54px",
        color: "#f8fafc",
        fontStyle: "800"
      })
      .setOrigin(0.5);

    this.add
      .text(512, 148, "Aspecto del jugador", {
        fontFamily: "Inter, Arial",
        fontSize: "24px",
        color: "#d7f7ff",
        fontStyle: "700"
      })
      .setOrigin(0.5);

    this.add
      .rectangle(512, 354, 560, 252, 0x0e2230, 0.9)
      .setStrokeStyle(2, 0x8ecae6, 0.6);

    this.add
      .text(330, 256, "Numero", {
        fontFamily: "Inter, Arial",
        fontSize: "21px",
        color: "#d7f7ff",
        fontStyle: "700"
      })
      .setOrigin(0, 0.5);

    this.createStepperButton(454, 256, "-", () => this.updatePlayerNumber(-1));
    this.add
      .text(512, 256, String(this.playerAppearance.jerseyNumber), {
        fontFamily: "Inter, Arial",
        fontSize: "30px",
        color: "#f8fafc",
        fontStyle: "900"
      })
      .setOrigin(0.5);
    this.createStepperButton(570, 256, "+", () => this.updatePlayerNumber(1));

    this.add
      .text(330, 328, "Cabello", {
        fontFamily: "Inter, Arial",
        fontSize: "21px",
        color: "#d7f7ff",
        fontStyle: "700"
      })
      .setOrigin(0, 0.5);

    const hairOptions: Array<{ value: PlayerHairColor; label: string; x: number; width: number }> = [
      { value: "rubio", label: "RUBIO", x: 458, width: 90 },
      { value: "morocho", label: "MOROCHO", x: 560, width: 108 },
      { value: "negro", label: "NEGRO", x: 670, width: 90 }
    ];

    hairOptions.forEach(({ value, label, x, width }) => {
      const isSelected = this.playerAppearance.hairColor === value;
      const option = this.add
        .rectangle(x, 328, width, 40, isSelected ? 0xfacc15 : 0x163142)
        .setStrokeStyle(2, isSelected ? 0xfffbeb : 0x8ecae6)
        .setInteractive({ useHandCursor: true });

      const optionLabel = this.add
        .text(x, 328, label, {
          fontFamily: "Inter, Arial",
          fontSize: "15px",
          color: isSelected ? "#111827" : "#d7f7ff",
          fontStyle: "900"
        })
        .setOrigin(0.5);

      const selectHair = () => {
        savePlayerAppearance({ ...this.playerAppearance, hairColor: value });
        this.scene.restart();
      };

      option.on("pointerover", () => {
        if (this.playerAppearance.hairColor !== value) {
          option.setFillStyle(0x1f4f68);
        }
      });
      option.on("pointerout", () => {
        if (this.playerAppearance.hairColor !== value) {
          option.setFillStyle(0x163142);
        }
      });
      option.on("pointerdown", selectHair);
      optionLabel.setInteractive({ useHandCursor: true }).on("pointerdown", selectHair);
    });

    this.add
      .text(330, 400, "Nombre", {
        fontFamily: "Inter, Arial",
        fontSize: "21px",
        color: "#d7f7ff",
        fontStyle: "700"
      })
      .setOrigin(0, 0.5);

    this.nameField = this.add
      .rectangle(570, 400, 230, 44, 0x163142)
      .setStrokeStyle(2, 0x8ecae6)
      .setInteractive({ useHandCursor: true });

    this.nameValueText = this.add
      .text(570, 394, this.playerAppearance.name.toUpperCase(), {
        fontFamily: "Inter, Arial",
        fontSize: "18px",
        color: "#f8fafc",
        fontStyle: "700"
      })
      .setOrigin(0.5);

    this.nameHintText = this.add
      .text(570, 415, "Click para editar", {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#b7d4df"
      })
      .setOrigin(0.5);

    const startEditingName = () => {
      this.isEditingName = true;
      this.nameDraft = this.playerAppearance.name;
      this.refreshNameField();
    };

    this.nameField.on("pointerover", () => {
      if (!this.isEditingName) {
        this.nameField.setFillStyle(0x1f4f68);
      }
    });
    this.nameField.on("pointerout", () => {
      if (!this.isEditingName) {
        this.nameField.setFillStyle(0x163142);
      }
    });
    this.nameField.on("pointerdown", startEditingName);
    this.nameValueText.setInteractive({ useHandCursor: true }).on("pointerdown", startEditingName);
    this.nameHintText.setInteractive({ useHandCursor: true }).on("pointerdown", startEditingName);

    this.input.keyboard?.on("keydown", this.handleNameInput, this);
    this.events.once("shutdown", () => {
      this.input.keyboard?.off("keydown", this.handleNameInput, this);
      this.input.keyboard?.off("keydown-ESC", this.handleEscapeBack, this);
    });
    this.input.keyboard?.on("keydown-ESC", this.handleEscapeBack, this);
    this.refreshNameField();

    const backButton = this.add
      .rectangle(512, 538, 260, 60, 0xf97316)
      .setStrokeStyle(3, 0xffedd5)
      .setInteractive({ useHandCursor: true });

    const backLabel = this.add
      .text(512, 538, "VOLVER", {
        fontFamily: "Inter, Arial",
        fontSize: "28px",
        color: "#111827",
        fontStyle: "900"
      })
      .setOrigin(0.5);

    backButton.on("pointerover", () => backButton.setFillStyle(0xfb923c));
    backButton.on("pointerout", () => backButton.setFillStyle(0xf97316));
    backButton.on("pointerdown", () => this.scene.start("MenuScene"));
    backLabel.setInteractive({ useHandCursor: true }).on("pointerdown", () => {
      this.scene.start("MenuScene");
    });
  }

  private updatePlayerNumber(delta: number): void {
    savePlayerAppearance({
      ...this.playerAppearance,
      jerseyNumber: Phaser.Math.Wrap(this.playerAppearance.jerseyNumber - 1 + delta, 0, 99) + 1
    });
    this.scene.restart();
  }

  private createStepperButton(x: number, y: number, label: string, onPress: () => void): void {
    const button = this.add
      .rectangle(x, y, 40, 36, 0x163142)
      .setStrokeStyle(2, 0x8ecae6)
      .setInteractive({ useHandCursor: true });

    const text = this.add
      .text(x, y, label, {
        fontFamily: "Inter, Arial",
        fontSize: "24px",
        color: "#f8fafc",
        fontStyle: "900"
      })
      .setOrigin(0.5);

    button.on("pointerover", () => button.setFillStyle(0x1f4f68));
    button.on("pointerout", () => button.setFillStyle(0x163142));
    button.on("pointerdown", onPress);
    text.setInteractive({ useHandCursor: true }).on("pointerdown", onPress);
  }

  private handleNameInput(event: KeyboardEvent): void {
    if (!this.isEditingName) {
      return;
    }

    if (event.key === "Enter") {
      savePlayerAppearance({ ...this.playerAppearance, name: this.nameDraft });
      this.scene.restart();
      return;
    }

    if (event.key === "Escape") {
      this.isEditingName = false;
      this.nameDraft = this.playerAppearance.name;
      this.refreshNameField();
      return;
    }

    if (event.key === "Backspace") {
      this.nameDraft = this.nameDraft.slice(0, -1);
      this.refreshNameField();
      return;
    }

    if (event.key === " ") {
      if (this.nameDraft.length < 16 && this.nameDraft.length > 0 && !this.nameDraft.endsWith(" ")) {
        this.nameDraft += " ";
        this.refreshNameField();
      }
      return;
    }

    if (/^[a-zA-Z0-9]$/.test(event.key) && this.nameDraft.length < 16) {
      this.nameDraft += event.key;
      this.refreshNameField();
    }
  }

  private handleEscapeBack(): void {
    if (!this.isEditingName) {
      this.scene.start("MenuScene");
    }
  }

  private refreshNameField(): void {
    const shownName = (this.isEditingName ? this.nameDraft : this.playerAppearance.name).trim() || "JUGADOR";

    this.nameValueText.setText(this.isEditingName ? `${shownName.toUpperCase()}_` : shownName.toUpperCase());
    this.nameHintText.setText(this.isEditingName ? "Enter para guardar  Esc para cancelar" : "Click para editar");
    this.nameField.setFillStyle(this.isEditingName ? 0x23485d : 0x163142);
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
