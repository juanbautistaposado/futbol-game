import Phaser from "phaser";
import { getBestScore, getKeeperDifficulty, getPlayerAppearance, getSelectedPlayerCount, getSelectedShotCount, saveBestScore } from "../storage";
import type { KeeperDifficulty, KeeperLane, KeeperState, PlayerAppearance, PlayerHairColor, RoundResultPlayer, RoundSetupData, RoundState, ShotInput, ShotResult } from "../types";

const GOAL = new Phaser.Geom.Rectangle(314, 108, 396, 178);
const GOAL_CENTER = new Phaser.Math.Vector2(512, 198);
const MAX_DRAG = 250;
const POST_MARGIN = 20;
const BALL_SCALE = 0.8;
const BALL_FLIGHT_END_SCALE = 0.336;
const BALL_POST_GOAL_SCALE = 0.288;
const BALL_POST_OUT_SCALE = 0.384;
const PLAYER_HAIR_COLORS: Record<PlayerHairColor, number> = {
  rubio: 0xfacc15,
  morocho: 0x5b3a29,
  negro: 0x111827
};

interface FreeKickSetup {
  ball: Phaser.Math.Vector2;
  striker: Phaser.Math.Vector2;
}

interface Competitor {
  name: string;
  goals: number;
  shotsTaken: number;
  jerseyNumber: number;
}

const FREE_KICK_SETUPS: FreeKickSetup[] = [
  {
    ball: new Phaser.Math.Vector2(512, 552),
    striker: new Phaser.Math.Vector2(448, 486)
  },
  {
    ball: new Phaser.Math.Vector2(446, 536),
    striker: new Phaser.Math.Vector2(378, 472)
  },
  {
    ball: new Phaser.Math.Vector2(584, 536),
    striker: new Phaser.Math.Vector2(520, 472)
  },
  {
    ball: new Phaser.Math.Vector2(404, 574),
    striker: new Phaser.Math.Vector2(338, 510)
  },
  {
    ball: new Phaser.Math.Vector2(620, 578),
    striker: new Phaser.Math.Vector2(556, 514)
  }
];

interface PostImpact {
  point: Phaser.Math.Vector2;
  rebound: Phaser.Math.Vector2;
  goesIn: boolean;
}

interface ShotResolution {
  result: ShotResult;
  postImpact?: PostImpact;
}

interface KeeperDifficultyConfig {
  reactionMs: number;
  guessCorrectChance: number;
  centralSaveChance: number;
  sideSaveChance: number;
  highCentralSaveChance: number;
  highSideSaveChance: number;
  highCornerSaveChance: number;
}

const KEEPER_DIFFICULTY_CONFIG: Record<KeeperDifficulty, KeeperDifficultyConfig> = {
  facil: {
    reactionMs: 220,
    guessCorrectChance: 0.42,
    centralSaveChance: 0.58,
    sideSaveChance: 0.36,
    highCentralSaveChance: 0.28,
    highSideSaveChance: 0.2,
    highCornerSaveChance: 0.12
  },
  medio: {
    reactionMs: 130,
    guessCorrectChance: 0.66,
    centralSaveChance: 0.8,
    sideSaveChance: 0.6,
    highCentralSaveChance: 0.48,
    highSideSaveChance: 0.38,
    highCornerSaveChance: 0.3
  },
  dificil: {
    reactionMs: 70,
    guessCorrectChance: 0.82,
    centralSaveChance: 0.92,
    sideSaveChance: 0.72,
    highCentralSaveChance: 0.62,
    highSideSaveChance: 0.5,
    highCornerSaveChance: 0.4
  }
};

export class GameScene extends Phaser.Scene {
  private ball!: Phaser.GameObjects.Image;
  private keeper!: Phaser.GameObjects.Image;
  private striker!: Phaser.GameObjects.Container;
  private strikerTorso!: Phaser.GameObjects.Rectangle;
  private strikerKickLeg!: Phaser.GameObjects.Rectangle;
  private strikerKickFoot!: Phaser.GameObjects.Ellipse;
  private strikerNameText!: Phaser.GameObjects.Text;
  private strikerNumberText!: Phaser.GameObjects.Text;
  private fieldGraphics!: Phaser.GameObjects.Graphics;
  private aimGraphics!: Phaser.GameObjects.Graphics;
  private goalFlash!: Phaser.GameObjects.Graphics;
  private hudText!: Phaser.GameObjects.Text;
  private bestText!: Phaser.GameObjects.Text;
  private feedbackText!: Phaser.GameObjects.Text;
  private instructionText!: Phaser.GameObjects.Text;
  private round!: RoundState;
  private keeperState!: KeeperState;
  private keeperIdleTween?: Phaser.Tweens.Tween;
  private dragStart = new Phaser.Math.Vector2();
  private dragEnd = new Phaser.Math.Vector2();
  private keeperDifficulty: KeeperDifficulty = "medio";
  private playerAppearance!: PlayerAppearance;
  private shotLimit = 7;
  private playerCount = 1;
  private competitors: Competitor[] = [];
  private currentFreeKickIndex = 0;
  private ballStartPosition = FREE_KICK_SETUPS[0].ball.clone();
  private strikerBasePosition = FREE_KICK_SETUPS[0].striker.clone();

  constructor() {
    super("GameScene");
  }

  create(): void {
    this.keeperDifficulty = getKeeperDifficulty();
    this.playerAppearance = getPlayerAppearance();
    const sceneData = this.scene.settings.data as Partial<RoundSetupData> | undefined;
    this.shotLimit = Phaser.Math.Clamp(sceneData?.shotLimit ?? getSelectedShotCount(), 5, 15);
    this.playerCount = Phaser.Math.Clamp(sceneData?.playerCount ?? getSelectedPlayerCount(), 1, 4);
    this.competitors = this.buildCompetitors();
    const keeperConfig = KEEPER_DIFFICULTY_CONFIG[this.keeperDifficulty];

    this.round = {
      shotsUsed: 0,
      goals: 0,
      bestScore: getBestScore(this.shotLimit),
      phase: "ready"
    };

    this.keeperState = {
      lane: "center",
      action: "idle",
      reactionMs: keeperConfig.reactionMs
    };

    this.fieldGraphics = this.add.graphics();
    this.aimGraphics = this.add.graphics();
    this.drawField();
    this.goalFlash = this.add.graphics().setDepth(12);
    this.createActors();
    this.createHud();
    this.registerInput();
    this.resetShot();
  }

  update(): void {
    if (this.round.phase === "aiming") {
      this.drawAim();
    }
  }

  private createActors(): void {
    this.keeper = this.add.image(GOAL_CENTER.x, 240, "keeper").setDepth(6).setScale(0.92);
    this.createStriker();
    this.ball = this.add.image(this.ballStartPosition.x, this.ballStartPosition.y, "ball").setDepth(10).setScale(BALL_SCALE);
    this.ball.setInteractive({ useHandCursor: true });
  }

  private createStriker(): void {
    const shadow = this.add.ellipse(0, 70, 90, 18, 0x06131a, 0.28);
    const head = this.add.circle(0, -72, 13, PLAYER_HAIR_COLORS[this.playerAppearance.hairColor], 1);
    const neck = this.add.rectangle(0, -55, 12, 12, 0xffd38a, 1);
    this.strikerTorso = this.add
      .rectangle(0, -30, 42, 54, 0xdc2626, 1)
      .setStrokeStyle(3, 0xfee2e2, 1);

    const namePlate = this.add.rectangle(0, -43, 34, 10, 0xb91c1c, 0.95);
    this.strikerNameText = this.add
      .text(0, -43, this.playerAppearance.name.toUpperCase().slice(0, 10), {
        fontFamily: "Inter, Arial",
        fontSize: "10px",
        color: "#f8fafc",
        fontStyle: "900"
      })
      .setOrigin(0.5);

    this.strikerNumberText = this.add
      .text(0, -29, String(this.playerAppearance.jerseyNumber), {
        fontFamily: "Inter, Arial",
        fontSize: "26px",
        color: "#ffffff",
        fontStyle: "900"
      })
      .setOrigin(0.5);

    const leftArm = this.add.rectangle(-28, -35, 10, 44, 0xffd38a, 1).setAngle(30);
    const rightArm = this.add.rectangle(30, -35, 10, 46, 0xffd38a, 1).setAngle(-40);
    const shorts = this.add.rectangle(0, 4, 44, 18, 0x111827, 1);
    const plantLeg = this.add.rectangle(-13, 12, 13, 58, 0x111827, 1).setOrigin(0.5, 0).setAngle(10);
    this.strikerKickLeg = this.add.rectangle(14, 10, 13, 62, 0x111827, 1).setOrigin(0.5, 0).setAngle(-36);
    const plantFoot = this.add.ellipse(-8, 63, 26, 11, 0x111827, 1).setAngle(-18);
    this.strikerKickFoot = this.add.ellipse(39, 54, 26, 11, 0x111827, 1).setAngle(-18);

    this.striker = this.add.container(448, 486, [
      shadow,
      leftArm,
      rightArm,
      neck,
      head,
      this.strikerTorso,
      namePlate,
      this.strikerNameText,
      this.strikerNumberText,
      shorts,
      plantLeg,
      this.strikerKickLeg,
      plantFoot,
      this.strikerKickFoot
    ]);
    this.striker.setDepth(9);
  }

  private createHud(): void {
    this.hudText = this.add
      .text(34, 28, "", {
        fontFamily: "Inter, Arial",
        fontSize: "28px",
        color: "#f8fafc",
        fontStyle: "800"
      })
      .setDepth(20);

    this.bestText = this.add
      .text(990, 30, "", {
        fontFamily: "Inter, Arial",
        fontSize: "23px",
        color: "#fde68a",
        fontStyle: "700"
      })
      .setOrigin(1, 0)
      .setDepth(20);

    this.feedbackText = this.add
      .text(512, 336, "", {
        fontFamily: "Inter, Arial",
        fontSize: "54px",
        color: "#ffffff",
        fontStyle: "900",
        stroke: "#0f172a",
        strokeThickness: 7
      })
      .setOrigin(0.5)
      .setDepth(22)
      .setVisible(false);

    this.instructionText = this.add
      .text(512, 608, "Arrastra desde la pelota hacia el arco y suelta para patear", {
        fontFamily: "Inter, Arial",
        fontSize: "19px",
        color: "#d7f7ff"
      })
      .setOrigin(0.5)
      .setDepth(20);

    this.updateHud();
  }

  private buildCompetitors(): Competitor[] {
    return Array.from({ length: this.playerCount }, (_, index) => ({
      name: index === 0 ? this.playerAppearance.name : `Jugador ${index + 1}`,
      goals: 0,
      shotsTaken: 0,
      jerseyNumber: this.getJerseyNumberForPlayer(index)
    }));
  }

  private getJerseyNumberForPlayer(index: number): number {
    const jerseyNumber = this.playerAppearance.jerseyNumber + index;
    return jerseyNumber <= 99 ? jerseyNumber : ((jerseyNumber - 1) % 99) + 1;
  }

  private getCurrentPlayer(): Competitor {
    return this.competitors[this.round.shotsUsed % this.playerCount] ?? this.competitors[0];
  }

  private getCurrentRoundNumber(): number {
    return Math.floor(this.round.shotsUsed / this.playerCount) + 1;
  }

  private getTotalShots(): number {
    return this.shotLimit * this.playerCount;
  }

  private applyCurrentPlayerIdentity(): void {
    const currentPlayer = this.getCurrentPlayer();
    this.strikerNameText.setText(currentPlayer.name.toUpperCase().slice(0, 10));
    this.strikerNumberText.setText(String(currentPlayer.jerseyNumber));
  }

  private registerInput(): void {
    this.ball.on("pointerdown", (pointer: Phaser.Input.Pointer) => {
      if (this.round.phase !== "ready") {
        return;
      }

      this.round.phase = "aiming";
      this.dragStart.set(this.ballStartPosition.x, this.ballStartPosition.y);
      this.dragEnd.set(pointer.x, pointer.y);
      this.feedbackText.setVisible(false);
    });

    this.input.on("pointermove", (pointer: Phaser.Input.Pointer) => {
      if (this.round.phase !== "aiming") {
        return;
      }

      this.dragEnd.set(pointer.x, pointer.y);
    });

    this.input.on("pointerup", (pointer: Phaser.Input.Pointer) => {
      if (this.round.phase !== "aiming") {
        return;
      }

      this.dragEnd.set(pointer.x, pointer.y);
      const shotInput = this.createShotInput();

      if (shotInput.power < 0.12 || shotInput.direction.y > -0.12) {
        this.round.phase = "ready";
        this.aimGraphics.clear();
        this.showTemporaryFeedback("MAS FUERTE", "#fef3c7", 420);
        return;
      }

      this.takeShot(shotInput);
    });

    this.input.keyboard?.on("keydown-ESC", () => this.scene.start("MenuScene"));
  }

  private createShotInput(): ShotInput {
    const raw = this.dragEnd.clone().subtract(this.dragStart);
    raw.y = Math.min(raw.y, -16);
    raw.x = Phaser.Math.Clamp(raw.x, -MAX_DRAG, MAX_DRAG);
    raw.y = Phaser.Math.Clamp(raw.y, -MAX_DRAG, -16);

    const distance = Phaser.Math.Clamp(raw.length(), 0, MAX_DRAG);
    const power = Phaser.Math.Clamp(distance / MAX_DRAG, 0, 1);
    const direction = raw.clone().normalize();
    const end = this.dragStart.clone().add(direction.clone().scale(distance));

    return {
      start: this.dragStart.clone(),
      end,
      direction,
      power
    };
  }

  private takeShot(shotInput: ShotInput): void {
    this.round.phase = "flying";
    this.aimGraphics.clear();
    this.instructionText.setText("");

    const target = this.calculateTarget(shotInput);
    const resolution = this.resolveShot(target);
    const duration = Phaser.Math.Linear(980, 660, shotInput.power);
    const control = new Phaser.Math.Vector2(
      (this.ballStartPosition.x + target.x) / 2 + shotInput.direction.x * 96,
      (this.ballStartPosition.y + target.y) / 2 - 92 * shotInput.power
    );

    this.playStrikerKick();
    this.sendKeeper(target, resolution.result, duration);
    this.animateBall(target, control, duration, resolution);
  }

  private playStrikerKick(): void {
    this.tweens.killTweensOf([this.striker, this.strikerTorso, this.strikerKickLeg, this.strikerKickFoot]);

    this.tweens.add({
      targets: this.striker,
      x: this.strikerBasePosition.x + 14,
      y: this.strikerBasePosition.y - 4,
      angle: 4,
      duration: 120,
      ease: "Sine.easeOut",
      yoyo: true
    });

    this.tweens.add({
      targets: this.strikerTorso,
      angle: 8,
      duration: 120,
      ease: "Sine.easeOut",
      yoyo: true
    });

    this.tweens.add({
      targets: this.strikerKickLeg,
      angle: -62,
      duration: 130,
      ease: "Back.easeOut",
      yoyo: true
    });

    this.tweens.add({
      targets: this.strikerKickFoot,
      x: 60,
      y: 45,
      angle: -34,
      duration: 130,
      ease: "Back.easeOut",
      yoyo: true
    });
  }

  private calculateTarget(shotInput: ShotInput): Phaser.Math.Vector2 {
    const x = GOAL_CENTER.x + shotInput.direction.x * Phaser.Math.Linear(180, 330, shotInput.power);
    const y = Phaser.Math.Linear(318, 122, shotInput.power) + shotInput.direction.y * 46;

    return new Phaser.Math.Vector2(
      Phaser.Math.Clamp(x, 180, 844),
      Phaser.Math.Clamp(y, 74, 360)
    );
  }

  private resolveShot(target: Phaser.Math.Vector2): ShotResolution {
    const keeperConfig = KEEPER_DIFFICULTY_CONFIG[this.keeperDifficulty];
    const postImpact = this.getPostImpact(target);

    if (postImpact) {
      this.keeperState.lane = this.pickKeeperLane(this.getLaneForX(postImpact.point.x));

      return {
        result: postImpact.goesIn ? "post-goal" : "post-out",
        postImpact
      };
    }

    if (!Phaser.Geom.Rectangle.Contains(GOAL, target.x, target.y)) {
      return { result: "missed" };
    }

    const lane = this.getLaneForX(target.x);
    const keeperGuess = this.pickKeeperLane(lane);
    this.keeperState.lane = keeperGuess;

    const laneMatches = keeperGuess === lane;
    if (!laneMatches) {
      return { result: "goal" };
    }

    const targetIsCentral = Math.abs(target.x - GOAL_CENTER.x) < 56;
    const targetIsCorner = target.x < GOAL.x + 92 || target.x > GOAL.right - 92;
    const targetIsHigh = target.y <= 150;
    const saveChance = targetIsHigh
      ? targetIsCentral
        ? keeperConfig.highCentralSaveChance
        : targetIsCorner
          ? keeperConfig.highCornerSaveChance
          : keeperConfig.highSideSaveChance
      : targetIsCentral
        ? keeperConfig.centralSaveChance
        : keeperConfig.sideSaveChance;

    if (Math.random() < saveChance) {
      return { result: "saved" };
    }

    return { result: "goal" };
  }

  private getPostImpact(target: Phaser.Math.Vector2): PostImpact | undefined {
    const nearLeftPost = Math.abs(target.x - GOAL.x) <= POST_MARGIN && target.y >= GOAL.y - 14 && target.y <= GOAL.bottom + 18;
    const nearRightPost =
      Math.abs(target.x - GOAL.right) <= POST_MARGIN && target.y >= GOAL.y - 14 && target.y <= GOAL.bottom + 18;
    const nearCrossbar =
      Math.abs(target.y - GOAL.y) <= POST_MARGIN && target.x >= GOAL.x - 18 && target.x <= GOAL.right + 18;

    if (!nearLeftPost && !nearRightPost && !nearCrossbar) {
      return undefined;
    }

    const goesIn = Math.random() < 0.45;
    const hitX = nearLeftPost ? GOAL.x : nearRightPost ? GOAL.right : Phaser.Math.Clamp(target.x, GOAL.x, GOAL.right);
    const hitY = nearCrossbar ? GOAL.y : Phaser.Math.Clamp(target.y, GOAL.y, GOAL.bottom);
    const point = new Phaser.Math.Vector2(hitX, hitY);

    if (nearCrossbar && !nearLeftPost && !nearRightPost) {
      return {
        point,
        rebound: goesIn
          ? new Phaser.Math.Vector2(Phaser.Math.Clamp(point.x + Phaser.Math.Between(-36, 36), GOAL.x + 70, GOAL.right - 70), GOAL.y + 94)
          : new Phaser.Math.Vector2(Phaser.Math.Clamp(point.x + Phaser.Math.Between(-100, 100), GOAL.x - 70, GOAL.right + 70), GOAL.y - 44),
        goesIn
      };
    }

    const hitLeft = nearLeftPost;
    return {
      point,
      rebound: goesIn
        ? new Phaser.Math.Vector2(hitLeft ? GOAL.x + 116 : GOAL.right - 116, Phaser.Math.Clamp(point.y + 62, GOAL.y + 52, GOAL.bottom - 14))
        : new Phaser.Math.Vector2(hitLeft ? GOAL.x - 118 : GOAL.right + 118, Phaser.Math.Clamp(point.y + 78, GOAL.y + 50, GOAL.bottom + 92)),
      goesIn
    };
  }

  private pickKeeperLane(actualLane: KeeperLane): KeeperLane {
    if (Math.random() < KEEPER_DIFFICULTY_CONFIG[this.keeperDifficulty].guessCorrectChance) {
      return actualLane;
    }

    if (actualLane === "left") {
      return Phaser.Math.Between(0, 1) === 0 ? "center" : "right";
    }

    if (actualLane === "right") {
      return Phaser.Math.Between(0, 1) === 0 ? "center" : "left";
    }

    return Phaser.Math.Between(0, 1) === 0 ? "left" : "right";
  }

  private getLaneForX(x: number): KeeperLane {
    if (x < GOAL_CENTER.x - 76) {
      return "left";
    }

    if (x > GOAL_CENTER.x + 76) {
      return "right";
    }

    return "center";
  }

  private sendKeeper(target: Phaser.Math.Vector2, result: ShotResult, duration: number): void {
    this.stopKeeperIdle();
    this.tweens.killTweensOf(this.keeper);

    const laneX = {
      left: GOAL.x + 78,
      center: GOAL_CENTER.x,
      right: GOAL.right - 78
    };

    const targetLaneX = result === "saved" ? target.x : laneX[this.keeperState.lane];
    const isHighDive = target.y <= 150 && (result === "saved" || this.getLaneForX(target.x) === this.keeperState.lane);
    const diveY =
      result === "saved"
        ? Phaser.Math.Clamp(target.y + (isHighDive ? 58 : 32), isHighDive ? 142 : 168, 252)
        : isHighDive
          ? 196
          : 232;
    const angle = this.keeperState.lane === "left" ? -32 : this.keeperState.lane === "right" ? 32 : 0;

    this.keeperState.action = "diving";
    this.tweens.add({
      targets: this.keeper,
      y: 248,
      scaleX: 1.02,
      scaleY: 0.84,
      duration: 90,
      ease: "Sine.easeOut"
    });

    this.time.delayedCall(this.keeperState.reactionMs, () => {
      this.keeper.setTexture(isHighDive ? "keeper-stretch" : "keeper");
      this.tweens.add({
        targets: this.keeper,
        x: targetLaneX,
        y: diveY,
        angle,
        scaleX: isHighDive ? 1.05 : 1.03,
        scaleY: isHighDive ? 0.96 : 0.88,
        duration: duration * 0.42,
        ease: "Cubic.easeOut"
      });
    });
  }

  private animateBall(
    target: Phaser.Math.Vector2,
    control: Phaser.Math.Vector2,
    duration: number,
    resolution: ShotResolution
  ): void {
    if (resolution.postImpact) {
      this.animatePostShot(target, control, duration, resolution);
      return;
    }

    const flight = { t: 0 };

    this.tweens.add({
      targets: flight,
      t: 1,
      duration,
      ease: "Cubic.easeOut",
      onUpdate: () => {
        const t = flight.t;
        const inverse = 1 - t;
        const x = inverse * inverse * this.ballStartPosition.x + 2 * inverse * t * control.x + t * t * target.x;
        const y = inverse * inverse * this.ballStartPosition.y + 2 * inverse * t * control.y + t * t * target.y;
        this.ball.setPosition(x, y);
        this.ball.setScale(Phaser.Math.Linear(BALL_SCALE, BALL_FLIGHT_END_SCALE, t));
        this.ball.setAngle(t * 720);
      },
      onComplete: () => this.finishShot(resolution.result)
    });
  }

  private animatePostShot(
    target: Phaser.Math.Vector2,
    control: Phaser.Math.Vector2,
    duration: number,
    resolution: ShotResolution
  ): void {
    const postImpact = resolution.postImpact;

    if (!postImpact) {
      this.animateBall(target, control, duration, resolution);
      return;
    }

    const flight = { t: 0 };
    this.tweens.add({
      targets: flight,
      t: 1,
      duration: duration * 0.82,
      ease: "Cubic.easeOut",
      onUpdate: () => {
        const t = flight.t;
        const inverse = 1 - t;
        const x = inverse * inverse * this.ballStartPosition.x + 2 * inverse * t * control.x + t * t * postImpact.point.x;
        const y = inverse * inverse * this.ballStartPosition.y + 2 * inverse * t * control.y + t * t * postImpact.point.y;
        this.ball.setPosition(x, y);
        this.ball.setScale(Phaser.Math.Linear(BALL_SCALE, BALL_FLIGHT_END_SCALE, t));
        this.ball.setAngle(t * 760);
      },
      onComplete: () => {
        this.playPostHitEffect(postImpact.point);
        this.animatePostRebound(postImpact, resolution.result);
      }
    });
  }

  private animatePostRebound(postImpact: PostImpact, result: ShotResult): void {
    this.tweens.add({
      targets: this.ball,
      x: postImpact.rebound.x,
      y: postImpact.rebound.y,
      scale: postImpact.goesIn ? BALL_POST_GOAL_SCALE : BALL_POST_OUT_SCALE,
      angle: this.ball.angle + (postImpact.goesIn ? 260 : -340),
      duration: 440,
      ease: postImpact.goesIn ? "Sine.easeOut" : "Quad.easeOut",
      onComplete: () => this.finishShot(result)
    });
  }

  private playPostHitEffect(point: Phaser.Math.Vector2): void {
    this.cameras.main.shake(120, 0.004);

    this.goalFlash.clear();
    this.goalFlash.lineStyle(9, 0xfacc15, 1);
    this.goalFlash.strokeRect(GOAL.x, GOAL.y, GOAL.width, GOAL.height);
    this.goalFlash.fillStyle(0xfacc15, 1);
    this.goalFlash.fillCircle(point.x, point.y, 13);

    this.tweens.add({
      targets: this.goalFlash,
      alpha: 0,
      duration: 260,
      ease: "Sine.easeOut",
      onComplete: () => {
        this.goalFlash.clear();
        this.goalFlash.setAlpha(1);
      }
    });
  }

  private finishShot(result: ShotResult): void {
    const currentPlayer = this.getCurrentPlayer();
    this.round.shotsUsed += 1;
    this.round.lastResult = result;
    this.keeperState.action = "recovering";
    currentPlayer.shotsTaken += 1;

    if (result === "goal" || result === "post-goal") {
      this.round.goals += 1;
      currentPlayer.goals += 1;
    }

    this.updateHud();
    this.showResultFeedback(result);

    this.time.delayedCall(1080, () => {
      if (this.round.shotsUsed >= this.getTotalShots()) {
        if (this.playerCount > 1) {
          const players = this.competitors.map<RoundResultPlayer>((player) => ({
            name: player.name,
            goals: player.goals,
            shots: player.shotsTaken
          }));
          const winningGoals = Math.max(...players.map((player) => player.goals), 0);

          this.scene.start("ResultScene", {
            goals: winningGoals,
            shots: this.shotLimit,
            bestScore: winningGoals,
            isNewBest: false,
            players
          });
          return;
        }

        const previousBest = this.round.bestScore;
        const bestScore = saveBestScore(this.round.goals, this.shotLimit);

        this.scene.start("ResultScene", {
          goals: this.round.goals,
          shots: this.shotLimit,
          bestScore,
          isNewBest: this.round.goals > previousBest
        });
        return;
      }

      this.resetShot();
    });
  }

  private resetShot(): void {
    this.round.phase = "ready";
    this.keeperState.action = "idle";
    this.keeperState.lane = "center";
    this.pickNextFreeKickSetup();
    this.stopKeeperIdle();
    this.tweens.killTweensOf(this.keeper);
    this.drawField();
    this.ball
      .setPosition(this.ballStartPosition.x, this.ballStartPosition.y)
      .setScale(BALL_SCALE)
      .setAngle(0)
      .setVisible(true);
    this.applyCurrentPlayerIdentity();
    this.resetStrikerPose();
    this.keeper.setTexture("keeper").setPosition(GOAL_CENTER.x, 240).setAngle(0).setScale(0.92);
    this.startKeeperIdle();
    this.instructionText.setText(this.getInstructionText());
    this.aimGraphics.clear();
    this.updateHud();
  }

  private resetStrikerPose(): void {
    this.tweens.killTweensOf([this.striker, this.strikerTorso, this.strikerKickLeg, this.strikerKickFoot]);
    this.striker.setPosition(this.strikerBasePosition.x, this.strikerBasePosition.y).setAngle(0).setScale(1);
    this.strikerTorso.setAngle(0);
    this.strikerKickLeg.setAngle(-36);
    this.strikerKickFoot.setPosition(39, 54).setAngle(-18);
  }

  private pickNextFreeKickSetup(): void {
    if (FREE_KICK_SETUPS.length === 1) {
      this.currentFreeKickIndex = 0;
      this.ballStartPosition = FREE_KICK_SETUPS[0].ball.clone();
      this.strikerBasePosition = FREE_KICK_SETUPS[0].striker.clone();
      return;
    }

    let nextIndex = Phaser.Math.Between(0, FREE_KICK_SETUPS.length - 1);

    while (nextIndex === this.currentFreeKickIndex) {
      nextIndex = Phaser.Math.Between(0, FREE_KICK_SETUPS.length - 1);
    }

    this.currentFreeKickIndex = nextIndex;
    this.ballStartPosition = FREE_KICK_SETUPS[nextIndex].ball.clone();
    this.strikerBasePosition = FREE_KICK_SETUPS[nextIndex].striker.clone();
  }

  private startKeeperIdle(): void {
    this.keeperIdleTween = this.tweens.add({
      targets: this.keeper,
      x: GOAL_CENTER.x + 16,
      y: 236,
      angle: 3,
      scaleX: 0.96,
      scaleY: 0.9,
      duration: 760,
      ease: "Sine.easeInOut",
      yoyo: true,
      repeat: -1
    });
  }

  private stopKeeperIdle(): void {
    if (!this.keeperIdleTween) {
      return;
    }

    this.keeperIdleTween.stop();
    this.keeperIdleTween = undefined;
  }

  private showResultFeedback(result: ShotResult): void {
    const text =
      result === "goal"
        ? "GOL"
        : result === "post-goal"
          ? "PALO Y GOL"
          : result === "saved"
            ? "ATAJADA"
            : result === "post-out"
              ? "PALO"
              : "FUERA";
    const color =
      result === "goal" || result === "post-goal"
        ? "#86efac"
        : result === "saved"
          ? "#93c5fd"
          : result === "post-out"
            ? "#fde047"
            : "#fca5a5";
    this.showTemporaryFeedback(text, color, 900);
  }

  private showTemporaryFeedback(text: string, color: string, duration: number): void {
    this.feedbackText
      .setText(text)
      .setColor(color)
      .setAlpha(1)
      .setScale(0.92)
      .setVisible(true);

    this.tweens.add({
      targets: this.feedbackText,
      scale: 1,
      duration: 160,
      ease: "Back.easeOut",
      yoyo: false
    });

    this.time.delayedCall(duration, () => {
      this.tweens.add({
        targets: this.feedbackText,
        alpha: 0,
        duration: 180,
        onComplete: () => this.feedbackText.setVisible(false)
      });
    });
  }

  private updateHud(): void {
    if (this.playerCount === 1) {
      this.hudText.setText(
        `Goles ${this.round.goals}/${this.shotLimit}   Tiro ${Math.min(this.round.shotsUsed + 1, this.shotLimit)}/${this.shotLimit}`
      );
      this.bestText.setText(`Mejor ${this.round.bestScore}/${this.shotLimit}`);
      return;
    }

    const roundIsFinished = this.round.shotsUsed >= this.getTotalShots();
    if (roundIsFinished) {
      this.hudText.setText(`Ronda completa   ${this.shotLimit}/${this.shotLimit}`);
      this.bestText.setText(this.getMultiplayerScoreboardText());
      return;
    }

    const currentPlayer = this.getCurrentPlayer();
    const roundNumber = this.getCurrentRoundNumber();

    this.hudText.setText(`Turno ${currentPlayer.name.toUpperCase().slice(0, 14)}   Ronda ${roundNumber}/${this.shotLimit}`);
    this.bestText.setText(this.getMultiplayerScoreboardText());
  }

  private getInstructionText(): string {
    if (this.playerCount === 1) {
      return "Arrastra desde la pelota hacia el arco y suelta para patear";
    }

    return `Turno de ${this.getCurrentPlayer().name}. Arrastra desde la pelota y patea.`;
  }

  private getMultiplayerScoreboardText(): string {
    return this.competitors
      .map((player, index) => `${index === 0 ? player.name.toUpperCase().slice(0, 6) : `J${index + 1}`} ${player.goals}`)
      .join("   ");
  }

  private drawAim(): void {
    const shotInput = this.createShotInput();
    const target = this.calculateTarget(shotInput);
    const powerColor = Phaser.Display.Color.Interpolate.ColorWithColor(
      new Phaser.Display.Color(134, 239, 172),
      new Phaser.Display.Color(249, 115, 22),
      100,
      shotInput.power * 100
    );
    const color = Phaser.Display.Color.GetColor(powerColor.r, powerColor.g, powerColor.b);

    this.aimGraphics.clear();
    this.aimGraphics.lineStyle(5, color, 0.78);
    this.aimGraphics.lineBetween(this.ballStartPosition.x, this.ballStartPosition.y, target.x, target.y);
    this.aimGraphics.fillStyle(color, 0.95);
    this.aimGraphics.fillCircle(target.x, target.y, 10 + shotInput.power * 8);
    this.aimGraphics.lineStyle(3, 0xffffff, 0.3);
    this.aimGraphics.strokeCircle(this.ballStartPosition.x, this.ballStartPosition.y, MAX_DRAG);
  }

  private drawField(): void {
    const graphics = this.fieldGraphics;
    graphics.clear();
    graphics.fillGradientStyle(0x123827, 0x123827, 0x20904f, 0x20904f, 1);
    graphics.fillRect(0, 0, 1024, 640);

    graphics.fillStyle(0x2eb85c, 0.32);
    for (let i = 0; i < 7; i += 1) {
      graphics.fillRect(i * 150 - 28, 0, 76, 640);
    }

    graphics.fillStyle(0x16713d, 1);
    graphics.beginPath();
    graphics.moveTo(258, 290);
    graphics.lineTo(766, 290);
    graphics.lineTo(1024, 640);
    graphics.lineTo(0, 640);
    graphics.closePath();
    graphics.fillPath();

    graphics.lineStyle(4, 0xf3fff1, 0.74);
    graphics.strokeEllipse(512, 624, 600, 210);
    graphics.lineBetween(258, 290, 0, 640);
    graphics.lineBetween(766, 290, 1024, 640);
    this.drawPenaltyArea(graphics);

    graphics.fillStyle(0x0b1720, 0.55);
    graphics.fillRect(GOAL.x + 12, GOAL.y + 12, GOAL.width - 24, GOAL.height - 10);
    graphics.lineStyle(7, 0xf8fafc, 1);
    graphics.strokeRect(GOAL.x, GOAL.y, GOAL.width, GOAL.height);
    graphics.lineStyle(2, 0xbde7ff, 0.45);

    for (let x = GOAL.x + 36; x < GOAL.right; x += 36) {
      graphics.lineBetween(x, GOAL.y, x, GOAL.bottom);
    }

    for (let y = GOAL.y + 28; y < GOAL.bottom; y += 28) {
      graphics.lineBetween(GOAL.x, y, GOAL.right, y);
    }

    graphics.fillStyle(0xffffff, 0.2);
    graphics.fillEllipse(this.ballStartPosition.x, this.ballStartPosition.y + 24, 61, 14);
  }

  private drawPenaltyArea(graphics: Phaser.GameObjects.Graphics): void {
    graphics.lineStyle(4, 0xf3fff1, 0.76);

    this.strokePerspectiveBox(graphics, {
      topLeft: new Phaser.Math.Vector2(276, 286),
      topRight: new Phaser.Math.Vector2(748, 286),
      bottomLeft: new Phaser.Math.Vector2(214, 458),
      bottomRight: new Phaser.Math.Vector2(810, 458)
    });

    this.strokePerspectiveBox(graphics, {
      topLeft: new Phaser.Math.Vector2(386, 286),
      topRight: new Phaser.Math.Vector2(638, 286),
      bottomLeft: new Phaser.Math.Vector2(354, 356),
      bottomRight: new Phaser.Math.Vector2(670, 356)
    });

    graphics.fillStyle(0xf3fff1, 0.9);
    graphics.fillCircle(512, 404, 5);
  }

  private strokePerspectiveBox(
    graphics: Phaser.GameObjects.Graphics,
    box: {
      topLeft: Phaser.Math.Vector2;
      topRight: Phaser.Math.Vector2;
      bottomLeft: Phaser.Math.Vector2;
      bottomRight: Phaser.Math.Vector2;
    }
  ): void {
    graphics.lineBetween(box.topLeft.x, box.topLeft.y, box.topRight.x, box.topRight.y);
    graphics.lineBetween(box.topLeft.x, box.topLeft.y, box.bottomLeft.x, box.bottomLeft.y);
    graphics.lineBetween(box.topRight.x, box.topRight.y, box.bottomRight.x, box.bottomRight.y);
    graphics.lineBetween(box.bottomLeft.x, box.bottomLeft.y, box.bottomRight.x, box.bottomRight.y);
  }
}
