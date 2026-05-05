export type ShotResult = "goal" | "saved" | "missed" | "post-goal" | "post-out";

export type ShotPhase = "ready" | "aiming" | "flying" | "resolved";

export interface ShotInput {
  start: Phaser.Math.Vector2;
  end: Phaser.Math.Vector2;
  direction: Phaser.Math.Vector2;
  power: number;
}

export interface RoundState {
  shotsUsed: number;
  goals: number;
  bestScore: number;
  phase: ShotPhase;
  lastResult?: ShotResult;
}

export type KeeperLane = "left" | "center" | "right";

export interface KeeperState {
  lane: KeeperLane;
  action: "idle" | "diving" | "recovering";
  reactionMs: number;
}

export interface RoundResultData {
  goals: number;
  shots: number;
  bestScore: number;
  isNewBest: boolean;
}
