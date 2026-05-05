import Phaser from "phaser";
import "./style.css";
import { BootScene } from "./scenes/BootScene";
import { GameScene } from "./scenes/GameScene";
import { MenuScene } from "./scenes/MenuScene";
import { ResultScene } from "./scenes/ResultScene";

const config: Phaser.Types.Core.GameConfig = {
  type: Phaser.AUTO,
  parent: "game",
  width: 1024,
  height: 640,
  backgroundColor: "#0b1f2a",
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH
  },
  scene: [BootScene, MenuScene, GameScene, ResultScene]
};

const game = new Phaser.Game(config);

declare global {
  interface Window {
    __FREE_KICK_GAME__?: Phaser.Game;
  }
}

if (import.meta.env.DEV) {
  window.__FREE_KICK_GAME__ = game;
}
