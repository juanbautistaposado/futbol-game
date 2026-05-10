import type { KeeperDifficulty, PlayerAppearance, PlayerHairColor } from "./types";

const BEST_SCORE_KEY = "free-kick-mvp-best-score";
const KEEPER_DIFFICULTY_KEY = "free-kick-mvp-keeper-difficulty";
const PLAYER_NAME_KEY = "free-kick-mvp-player-name";
const PLAYER_NUMBER_KEY = "free-kick-mvp-player-number";
const PLAYER_HAIR_COLOR_KEY = "free-kick-mvp-player-hair-color";
const SHOT_COUNT_KEY = "free-kick-mvp-shot-count";

export function getBestScore(shotCount: number = getSelectedShotCount()): number {
  const bestScores = getBestScoreMap();
  const key = String(normalizeShotCount(shotCount));
  const score = bestScores[key] ?? 0;

  return Number.isFinite(score) ? Phaser.Math.Clamp(score, 0, normalizeShotCount(shotCount)) : 0;
}

export function saveBestScore(score: number, shotCount: number = getSelectedShotCount()): number {
  const normalizedShotCount = normalizeShotCount(shotCount);
  const bestScores = getBestScoreMap();
  const key = String(normalizedShotCount);
  const nextScore = Phaser.Math.Clamp(score, 0, normalizedShotCount);
  const bestScore = Math.max(bestScores[key] ?? 0, nextScore);

  bestScores[key] = bestScore;
  window.localStorage.setItem(BEST_SCORE_KEY, JSON.stringify(bestScores));

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

export function getPlayerAppearance(): PlayerAppearance {
  const rawName = window.localStorage.getItem(PLAYER_NAME_KEY) ?? "Jugador";
  const rawNumber = window.localStorage.getItem(PLAYER_NUMBER_KEY);
  const rawHairColor = window.localStorage.getItem(PLAYER_HAIR_COLOR_KEY);
  const jerseyNumber = rawNumber === null ? 9 : Number.parseInt(rawNumber, 10);

  return {
    name: sanitizePlayerName(rawName),
    jerseyNumber: Number.isFinite(jerseyNumber) ? Phaser.Math.Clamp(jerseyNumber, 1, 99) : 9,
    hairColor: isPlayerHairColor(rawHairColor) ? rawHairColor : "negro"
  };
}

export function savePlayerAppearance(appearance: PlayerAppearance): PlayerAppearance {
  const nextAppearance = {
    name: sanitizePlayerName(appearance.name),
    jerseyNumber: Phaser.Math.Clamp(appearance.jerseyNumber, 1, 99),
    hairColor: isPlayerHairColor(appearance.hairColor) ? appearance.hairColor : "negro"
  };

  window.localStorage.setItem(PLAYER_NAME_KEY, nextAppearance.name);
  window.localStorage.setItem(PLAYER_NUMBER_KEY, String(nextAppearance.jerseyNumber));
  window.localStorage.setItem(PLAYER_HAIR_COLOR_KEY, nextAppearance.hairColor);

  return nextAppearance;
}

export function getSelectedShotCount(): number {
  const value = window.localStorage.getItem(SHOT_COUNT_KEY);
  const shotCount = value === null ? 7 : Number.parseInt(value, 10);

  return normalizeShotCount(shotCount);
}

export function saveSelectedShotCount(shotCount: number): number {
  const normalized = normalizeShotCount(shotCount);
  window.localStorage.setItem(SHOT_COUNT_KEY, String(normalized));

  return normalized;
}

function sanitizePlayerName(name: string): string {
  const cleaned = name.trim().replace(/\s+/g, " ");

  return cleaned.length > 0 ? cleaned.slice(0, 16) : "Jugador";
}

function isPlayerHairColor(value: string | null): value is PlayerHairColor {
  return value === "rubio" || value === "morocho" || value === "negro";
}

function getBestScoreMap(): Record<string, number> {
  const raw = window.localStorage.getItem(BEST_SCORE_KEY);

  if (!raw) {
    return {};
  }

  try {
    const parsed = JSON.parse(raw) as Record<string, unknown>;
    const normalized: Record<string, number> = {};

    Object.entries(parsed).forEach(([key, value]) => {
      const shotCount = normalizeShotCount(Number.parseInt(key, 10));
      const score = typeof value === "number" ? value : Number.parseInt(String(value), 10);
      normalized[String(shotCount)] = Number.isFinite(score) ? Phaser.Math.Clamp(score, 0, shotCount) : 0;
    });

    return normalized;
  } catch {
    const legacyScore = Number.parseInt(raw, 10);

    return Number.isFinite(legacyScore) ? { "7": Phaser.Math.Clamp(legacyScore, 0, 7) } : {};
  }
}

function normalizeShotCount(shotCount: number): number {
  return Phaser.Math.Clamp(Number.isFinite(shotCount) ? shotCount : 7, 5, 15);
}
