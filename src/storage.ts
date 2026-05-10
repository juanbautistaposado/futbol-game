import type { KeeperDifficulty } from "./types";

const BEST_SCORE_KEY = "free-kick-mvp-best-score";
const KEEPER_DIFFICULTY_KEY = "free-kick-mvp-keeper-difficulty";

export function getBestScore(): number {
  const value = window.localStorage.getItem(BEST_SCORE_KEY);
  const score = value === null ? 0 : Number.parseInt(value, 10);

  return Number.isFinite(score) ? Phaser.Math.Clamp(score, 0, 7) : 0;
}

export function saveBestScore(score: number): number {
  const bestScore = Math.max(getBestScore(), Phaser.Math.Clamp(score, 0, 7));
  window.localStorage.setItem(BEST_SCORE_KEY, String(bestScore));

  return bestScore;
}

export function getKeeperDifficulty(): KeeperDifficulty {
  const value = window.localStorage.getItem(KEEPER_DIFFICULTY_KEY);

  return value === "facil" || value === "medio" || value === "dificil" ? value : "medio";
}

export function saveKeeperDifficulty(difficulty: KeeperDifficulty): KeeperDifficulty {
  window.localStorage.setItem(KEEPER_DIFFICULTY_KEY, difficulty);

  return difficulty;
}
