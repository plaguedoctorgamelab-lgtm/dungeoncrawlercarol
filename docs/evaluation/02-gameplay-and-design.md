# 02: Gameplay and Design

Labels: [Verified] · [Measured] · [Inferred]. Feel and fun claims are [Inferred] unless they're backed by a measurement.

## 1. The core loop, as the build presents it

You didn't describe the game, so this is inferred from the repository.

> **Carol, a punk 90s heroine, crosses four elemental "realms" of corporate-satire monsters to rescue her girlfriend Princess Penny from the Sea Lord.**
>
> - **Map layer:** each realm is a Slay-the-Spire-style branching map. You pick a path, and each node is a fight, a hazard (a random HP loss, a drink, or a shortcut), or a supply cache (a weapon or a drink).
> - **Battle layer:** a fight is a one-hero, XCOM-flavoured turn-based skirmish on a small isometric grid. Carol has 4 AP per turn: move 1 AP per tile, attack 2 AP, drink 2 AP. Ranged hit chances are 85% in the open, 60% behind half cover and 35% behind full cover.
> - **Carry-over:** HP, drinks and weapons carry between fights. Each realm ends with a 2×2-tile boss, and the last boss frees Penny.

Supporting evidence [Verified]:
- `OverworldGenerator.gd:12-82`
- `NodeMap.gd:158-188`
- `TacticalBattlefield.gd`
- `CombatMath.gd`
- `GameState.gd:21-26`
- The How to Play text (`scenes/ui/HowToPlay.gd:4-10`)

**Does the build communicate this? Mostly yes.** The How to Play screen states the loop clearly, and the HUD shows AP, HP, weapons, the hit badge and range highlights. What the build does *not* communicate is a reason to make one choice over another, which is the real issue (see section 3).

## 2. How much content exists [Verified / Measured]

| Content | Amount | Notes |
|---|---|---|
| Realms | 4 | Each has its own floor tile, colours and enemy pool (`Roster.gd:71-80`) |
| Regular enemies | 20 (5 per realm) | Stat variety: HP 25-90, damage 8-24, range 1-5, 9 ranged |
| Bosses | 4, each 2×2 | Same AI as regular enemies, with a different footprint |
| Weapons | 4 | All cost 2 AP (`Roster.gd:38-43`) |
| Abilities / skills | **0** | The only non-attack action is the Energy Drink |
| Node types | combat, hazard, supply, boss | Hazards have 3 outcomes (`NodeMap.gd:177-186`) |
| Map size | 17.5 nodes on average, 7.3 layers; a path visits 6.7-8.2 nodes | [Measured] 200 maps |
| Fights per run | ≈ 4-5 per realm + boss ≈ **20-24 battles** | [Inferred] from 57% combat nodes on the path |
| Run length | ≈ 24 battles × ~5 turns ≈ 120 player turns | [Inferred] from the sim's average turns |
| Meta-progression / unlocks | **none** | Nothing carries over between runs |

For a prototype that's a *lot* of content breadth, and very little systemic depth. That's backwards from what a prototype should prove (see section 6).

## 3. Mechanics and balance

### 3.1 Decisions per turn are thin [Inferred, backed by data]
- With 4 AP, a move costing 1 and every attack costing 2, a turn is one of: *attack twice*, *move 1-2 and attack*, or *move 3-4*.
- Weapons differ only in damage and range. There are no secondary effects such as knockback, pierce or area of effect.
- There are no abilities, no overwatch, and no telegraphed enemy intent.

Expected damage per AP, from the probe [Measured]:

| Weapon | Open | Half cover | Full cover |
|---|---|---|---|
| Squeaky Foam Mallet (melee) | **15.3** | 15.3 | 15.3 |
| Super Soaker 9000 | 14.5 | 10.2 | 6.0 |
| Neon Star-Sword (melee) | 10.6 | 10.6 | 10.6 |
| Contractor Nailgun | 6.8 | 4.8 | 2.8 |

- Melee ignores cover (`TacticalBattlefield.attack_cover`), so the Mallet is strictly the best weapon whenever you're adjacent to a target.
- The Nailgun is a trap pick. Its only advantage is range, and range doesn't matter because hit chance doesn't fall off with distance (`CombatMath.hit_chance`, `CombatMath.gd:17-27`).
- The "right" play is almost always obvious [Inferred].

### 3.2 Cover is the headline mechanic, and it's rarely in play [Measured]
- 40 rooms, 5,222 possible ranged shots within 7 tiles:
  - **73.5% open**
  - 14.6% against half cover
  - **3.8% against full cover**
  - 8.1% with no line of sight
- An earlier run of 40 rooms found 81.3% open. Battle layouts aren't seeded (see 01-A9), so these numbers vary from run to run.
- Why cover rarely matters:
  - The 12-17 props are scattered at random (`_place_terrain`, `TacticalBattlefield.gd:161-188`).
  - Enemy AI never chooses tiles for cover. `_enemy_step` (`:540`) A*-paths straight at Carol.
- Cover therefore doesn't slow the game or cause frustrating misses. It mostly doesn't happen.
- **This is the biggest design gap: the game's identity mechanic is incidental.**

### 3.3 Win rates show a flat curve, then a cliff [Measured]
The auto-play bot plays greedily and never seeks cover. Each row is 40 battles, played through the real battle API.

| Difficulty | Fight | Win rate | Avg turns | Avg HP lost | Carol's hit rate |
|---|---|---|---|---|---|
| Medium | Realm 1 regular | **100%** | 4.3 | 18 | 83% |
| Medium | Realm 1 boss (Golem) | 88% | **13.6** | 32 | 67% |
| Medium | Realm 3 regular | 95% | 4.6 | 20 | 78% |
| Medium | Realm 4 boss (Sea Lord) | **20%** | 5.7 | 92 | 83% |
| Easy | Realm 4 boss | 48% | 9.3 | 72 | 73% |
| Hard | Realm 4 boss | **5%** | 5.7 | 92 | 86% |
| EXTREME | Realm 1 regular | 70% | 8.6 | 58 | 76% |
| EXTREME | Realm 1 boss | 35% | 14.1 | 71 | 62% |
| EXTREME | Realm 4 regular | 60% | 5.5 | 67 | 89% |
| EXTREME | Realm 4 boss | **0%** | 2.6 | 100 | 87% |

How to read this [Inferred]:
- **Regular fights are trivially easy on Medium.** A bot with no tactics wins every realm-1 fight in about 4 turns, losing 18 of 100 HP, and Carol heals 15 after each win (`GameState.gd:26`). There's no attrition pressure, so the map's "risk vs reward" choices barely matter.
- **The first boss is a slog.** 13.6 turns against the Golem: at that point Carol only has the 16-damage Nailgun and the Sword, and the Golem has 160 HP.
- **The final boss is a wall.** The Sea Lord hits for 40 (×1.6 = 64 on EXTREME, so Carol dies in 2 hits). He attacks every turn, and Carol's maximum HP never grows. Nothing between realm 1 and realm 4 teaches the player the cover play that this fight requires.
- **What this means:** a human who uses cover will do much better than the bot. But the game never forces cover use earlier, so the skill gets demanded without ever being taught.

### 3.4 Difficulty tiers [Verified + Measured]
- The tiers are 0.8× / 1.0× / 1.3× / 1.6× enemy HP and damage, and sight of 8 / 6 / 5 / 3 tiles (`GameState.gd:8-13`).
- On EXTREME, sight 3 is below every ranged enemy's attack range of 4-6. The probe found that 2 of 2, 3 of 3, 2 of 2 and 1 of 2 ranged enemies per realm can shoot from tiles Carol can't see. That's punishment the player can't play around [Inferred].
- Permadeath can be dodged (see 01-A5).

### 3.5 Controls and input [Verified]
- Click a tile to move, click an enemy to attack, `1-4` switch weapons, `H` drinks, and `E` / Space / Enter end the turn (`TacticalBattlefield.gd:334-349`).
- **There's no undo, no move confirmation and no right-click cancel.** One misclick spends AP permanently [Inferred: a frequent frustration in tactics games].
- 1.6% of highlighted move tiles silently refuse the click (01-C1).

### 3.6 Feel and feedback [Verified code, Inferred feel]
What's there:
- step tweens (0.14 s per tile, `BattleUnit.gd:8`)
- a lunge on melee
- a white flash on hit
- floating damage numbers
- 15 tweened projectile styles with trails (`Roster.gd:52-68`)
- an animated cage break

What's missing:
- **sound**
- hit-stop
- screen shake
- death animations (enemies only fade out over 0.3 s, `TacticalBattlefield.gd:634-650`)
- sprite animation or facing
- a turn-transition beat beyond the phase label fade

Turn tempo is quick: an enemy phase with 3 enemies took 250 ms at 1× speed [Measured]. That fits the "arcade" goal, but it also means enemy actions may be hard to follow [Inferred].

### 3.7 Progression and pacing [Measured / Inferred]
- Within a run, the progression is:
  - weapons (Mallet from caches; the Super Soaker guaranteed at the Fire realm, `GameState.gd:97-101`)
  - +20% damage per realm (`GameState.carol_damage_mult`)
  - drinks
- There are no build choices, no levelling and no relics or modifiers. So runs will feel the same after the first one or two [Inferred].
- In 111 of 200 maps (55%), the boss is not in the last layer, and later nodes link *back* to it (`OverworldGenerator.gd:53-61`). The map reads as if it loops.
- Hazard outcomes are pure luck, with no choice offered (`NodeMap.gd:171-188`).

### 3.8 Onboarding [Verified]
- Strong for a prototype:
  - a How to Play screen with 5 sections, shown after NEW GAME
  - a legend on the map
  - a hit-badge cover key
  - inline "need 2 AP" and "OUT OF RANGE" feedback in hover text
- There's no tutorial battle, though, and no in-game prompt teaches cover before the bosses demand it.

## 4. Is the prototype answering "is this fun?"

**Not yet, and the evidence leans towards "not in its current form" [Inferred from Measured data].**

A prototype should prove that the core 30 seconds, one turn, is interesting. What the build shows:
- **Turns rarely contain a real dilemma.** The best action is usually computable at a glance (section 3.1).
- **Cover rarely affects outcomes** (section 3.2).
- **Regular fights end in about 4 turns with almost no risk**, and the final boss is decided by burst damage rather than by decisions (section 3.3).
- The project spent its effort on breadth (24 monsters, 15 projectiles, 4 realms, 3 save slots) before depth.

What would show it *is* fun: playtesters voluntarily replaying, talking out loud about trade-offs ("if I step here I lose cover but…"), and failing fights for reasons they can name.

## 5. Playtest checklist (for you, with a human)

Run each of these with 3-5 people who haven't seen the game. Watch them silently, and note the time and what they say.

1. **First 5 minutes:** do they read How to Play? Can they say what AP and cover mean without help?
2. **First battle:** count the moments they pause to think. Fewer than 2 per turn means the decisions are too thin.
3. **Cover:** do they ever move *because of* cover? Do they notice enemies ignoring it?
4. **Misclicks:** count AP lost to misclicks, and whether they ask for undo.
5. **Highlighted tiles that don't respond (01-C1):** does anyone click a cyan tile next to spikes and get nothing?
6. **Golem fight:** does it feel long? Time it. The bot averaged 13.6 turns.
7. **Sea Lord fight:** do they understand *why* they lost?
8. **After the run:** "Would you start another run right now?" That yes/no is your fun metric.
9. **Readability:** can they tell the 24 monsters apart, and tell which are ranged, without hovering?
10. **Silence:** ask what the game *sounds* like in their head. If nobody can answer, the audio gap is costing feel.
