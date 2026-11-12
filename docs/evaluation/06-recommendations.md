# 06: Recommendations

Effort is in focused solo hours [Inferred estimates]. Priority: **P0** = do before anything else · **P1** = needed for a vertical slice or demo · **P2** = needed for launch.
"Evidence" points to the report section that backs each item.

---

## Horizon 1: Immediate (next ~2 weeks, about 45-60 h)

The goal of these two weeks is to **prove the turn is fun**, and to remove the problems that get more expensive every day.

| # | Recommendation | Problem it solves | Evidence | Expected impact | Effort | Priority |
|---|---|---|---|---|---|---|
| I1 | **Rename the game.** Keep Carol, Penny and the Sea Lord, and drop the "Dungeon Crawler ___" pattern. Rename the project, window title, export product name and repo before any public post. | Trademark confusion with *Dungeon Crawler Carl* (™ Veriluxx LLC) | 04, section 2 | Removes the biggest commercial risk | 1-3 h (+ thinking time) | **P0** |
| I2 | **Fix four rules bugs.** (a) Make `reachable()` cost spikes the same as A*, or stop weighting spikes. (b) Limit the line-of-sight exemption to cover beside the shooter, off the firing line. (c) Add a line-of-sight check to fog and enemy detection. (d) Seed battle RNG from `run_seed + node_id`. Add a test for each. | Highlighted tiles that ignore clicks; seeing and shooting through walls; runs that can't be reproduced | 01-C1, C2, C3, A9; `IsometricGrid.gd:175,218,240-247,276`; `TacticalBattlefield.gd:48,406,507` | Removes "this game is broken" moments and makes bugs reproducible | 4-6 h | **P0** |
| I3 | **Make enemies fight smart.** (a) Ranged enemies pick the reachable tile that has line of sight to Carol *and* the most cover (`cover_between(carol, tile)`). (b) Melee enemies try to flank. (c) Telegraph intent: show the tile or target each enemy will attack next turn, Into-the-Breach style. | Cover rarely matters; turns lack dilemmas | 02-3.2 (73.5% open shots); `_enemy_step` `TacticalBattlefield.gd:540` | **The single biggest lever on fun** | 10-14 h | **P0** |
| I4 | **Give Carol 2 abilities that create choices.** For example, a *Dash* (1 AP, move 2 and ignore the next shot) and a *Shove* (2 AP, push an enemy one tile into spikes or out of cover). Remove the Nailgun or give it a niche (1 AP shots, or 1-tile pierce). | Obvious best play every turn; the Nailgun is a trap | 02-3.1 (damage per AP table) | Turns gain real trade-offs | 6-8 h | **P0** |
| I5 | **Minimal juice and audio pass.** One music loop, about 12 SFX (step, swing, hit, miss, enemy shot, death, drink, turn start, UI click, boss intro, victory, defeat), 80 ms hit-stop, small screen shake, and a squash/scale "bounce" on hit and death. Use free packs such as Kenney (CC0). | A silent, static build playtests worse than it really is | 03, section 2; 02-3.6 | Gives the fun question a fair test | 8-12 h | **P0** |
| I6 | **Re-tune the curve, then re-run the sim.** Raise realm-1 enemy damage or count. Lower the Sea Lord's damage, or give him a telegraphed charge. Add +10 max HP per realm cleared. Use the auto-play sim (appendix, section F) to aim for: bot win rate ~70-85% in regular fights and ~40-60% against bosses on Medium. | Flat curve, then a cliff | 02-3.3 (100% → 20%) | The run gets an actual tension arc | 4-6 h | P0 |
| I7 | **Stop committing build zips.** Remove `releases/` from git, add it to `.gitignore`, and publish builds through GitHub Releases or itch.io `butler`. Optionally rewrite history to drop the ~88 MB of zips (`git filter-repo`). | `.git` is already 193 MB after 4 commits | 01-B1 | A repo that stays fast to clone and back up | 1-2 h | P0 |
| I8 | **Playtest with 3-5 people.** Use the checklist in 02, section 5, and record "would you play another run?" | Fun is unproven | 02, section 4 | The answer the whole prototype exists to give | 4-6 h | **P0** |

**Decision gate at the end of Horizon 1.** If playtesters don't want to start another run after I3-I6, change the battle concept (try a different core verb) *before* investing in art or content. That's the cheapest moment to pivot.

---

## Horizon 2: Near term (before a vertical slice or demo, about 120-200 h)

| # | Recommendation | Problem it solves | Evidence | Impact | Effort | Priority |
|---|---|---|---|---|---|---|
| N1 | **Decide the art direction.** Choose (a) iso-angled or flat billboard units, (b) true pixel art at integer scale or clean HD cartoon, and (c) where the final art comes from: AI-assisted with consistent animation, commissioned, or your own. Make one fully animated unit as a test before committing. | Static, front-facing, mixed pixel density; AI art is hard to animate | 03-V1, V3, V4 | Sets the cost of all remaining art | 6-10 h (decision + test unit) | P1 |
| N2 | **Cut the roster for the slice.** Realm 1 only, with 5 enemies + the Golem fully animated (idle, move, attack, hit, death) and real audio. | 26 characters × animations is the biggest solo cost | 04, section 3 | Scope you can actually finish | 40-80 h (art-dependent) | P1 |
| N3 | **Split `TacticalBattlefield.gd`** into `RoomGenerator`, `EnemyAI` and a battle controller. Add `class_name TacticalBattlefield` and type the HUD's reference to it. | A 728-line god script; untyped HUD coupling | 01-A1, A7 | Abilities, statuses and AI get easier to add | 4-6 h | P1 |
| N4 | **Move the UI into editor-built scenes** with Containers, anchors and a shared Theme resource, replacing the `UiKit.fit_design` ×1.5 scaling. Start with the HUD and the title screen. | Code-only UI; letterboxing at 16:10; slow iteration | 01-A2, A3; 03-U3 | Faster UI work; Steam Deck layout | 10-16 h | P1 |
| N5 | **Add input actions and controller support.** Move every `KEY_*` into the InputMap. Add a grid cursor for gamepad, plus key and pad navigation for unit inspection. | Mouse-only; no rebinding; hover-only info | 01-B4; 03-U4, accessibility section | Steam Deck "Playable" and better accessibility | 10-14 h | P1 |
| N6 | **Add settings and pause menus.** Window mode, volume buses, text scale, screen-shake toggle and game speed, saved through `ConfigFile`. Esc opens pause, with Resume, Settings and Quit to Title. | None exist | 03-U1, U2 | Baseline Steam expectations | 6-8 h | P1 |
| N7 | **Harden saves.** Write to a temp file, then rename. Validate weapon IDs against `Roster`. Bump the save version to 3, with migration. Auto-save after every node on EXTREME, and wipe every slot that shares a `run_seed`. | Truncated saves; crash on stale IDs; permadeath loopholes | 01-A4, A5 | No lost or corrupt runs once players have saves | 3-4 h | P1 |
| N8 | **Add a Linux preset, the export templates, an `.ico`, and a smoke-test script** that exports both platforms and runs the tests. Optionally add a GitHub Actions workflow. | No Linux build; default icon; no CI | 01-B2, B3, B5 | Steam/Deck/itch-ready builds | 3-5 h | P1 |
| N9 | **Improve the map's readability and choices.** Always place the boss in the final layer, and give hazards a choice (for example, "risk 15 HP for a weapon"). | The boss appears mid-map in 55% of maps; hazards are pure luck | 02-3.7; `OverworldGenerator.gd:53-61` | Map decisions start to matter | 3-4 h | P1 |
| N10 | **Add a tutorial fight** that teaches cover and abilities with a scripted layout. | Bosses demand skills that the game never teaches | 02-3.8 | Better onboarding and fewer bounced players | 4-6 h | P1 |

---

## Horizon 3: Future (road to commercial release)

| # | Recommendation | Why | Effort | Priority |
|---|---|---|---|---|
| F1 | **A store page as soon as the slice is fun**, under the new name: capsules, 5 screenshots that show decisions, and a trailer. Then build wishlists through social posts, festivals and Next Fest. | ~19-21k Steam releases a year; visibility comes from wishlists (04, section 1) | 25-40 h | P2 |
| F2 | **A replay hook.** Unlockable starting weapons or modifiers, relic-style perks from caches, and seeded daily runs (this needs I2-d). | There's no meta-progression; runs feel the same after one or two | 30-60 h | P2 |
| F3 | **Expand to realms 2-4 at the new art standard**, re-using rigs and re-skins to reach 8-12 enemy types plus 4 bosses. | Content breadth, but at a quality you can maintain | 150-300 h | P2 |
| F4 | **Balance pass across difficulties** using the sim as a regression gate in CI. Consider shipping 3 difficulties instead of 4. | A 4×4 balance matrix is a big solo burden | 20-40 h | P2 |
| F5 | **Compliance and polish:** an AI content disclosure (if AI art remains), a credits screen with the Godot MIT notice and font licenses, a privacy-safe crash log, achievements (optional), and `tr()` strings for localization (optional). | Store requirements and reception | 10-20 h | P2 |
| F6 | **A custom export template** (no 3D, fewer modules) to cut the ~118 MB `.exe`. | 109 MB of the `.exe` is the stock template | 3-6 h | P2 |

---

## Suggested order of work

1. **I1 Rename** (day 1, before anything public).
2. **I7 Repo hygiene** (same day; it only gets bigger).
3. **I2 Rules bugs + seeding** (gives you reproducible battles to test against).
4. **I3 Enemy AI with cover and telegraphs → I4 Carol's abilities** (the fun core).
5. **I5 Juice + audio** (so the playtest is fair).
6. **I6 Re-tune with the sim.**
7. **I8 Playtest → decision gate.** Pivot the battle concept here if it isn't landing.
8. **N1 Art direction test unit → N3 Split the battle script → N7 Saves → N9 Map → N10 Tutorial.**
9. **N4 UI scenes → N5 Input/controller → N6 Settings and pause → N8 Linux/CI.**
10. **N2 Realm-1 vertical slice → F1 Store page + Next Fest demo.**
11. **F2-F6** toward launch.

Rule of thumb for every week: **depth before breadth.** Don't add a monster, realm or projectile until the last playtest says the turn itself is fun.
