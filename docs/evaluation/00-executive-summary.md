# Executive Summary

## Verdict

**The engine work is sound, but the game hasn't proven it's fun, and the name is a commercial liability.**

*Dungeon Crawler Carol* is a complete, stable, end-to-end prototype:
- title screen with 4 difficulties
- a 4-realm branching map
- turn-based isometric battles
- 24 monsters and 4 two-by-two-tile bosses
- a rescue ending
- saves

It boots in under a second, runs at a locked 60 fps with at most 325 draw calls, and passes 152 of 152 automated checks. That's unusually complete for a prototype, and it's worth protecting.

What it doesn't have yet is a *reason to play it* rather than a better-known tactics roguelite:
- Battles give the player very few interesting decisions. Each turn there are only 3-4 AP choices and no abilities.
- Enemies walk straight at Carol and ignore cover.
- The difficulty curve is flat and easy, then falls off a cliff at the final boss.
- There is no audio at all, no animation, and no controller support.

Separately from the game itself, the title is one letter away from *Dungeon Crawler Carl*, an active book, TV and games franchise with a registered trademark holder. That's the single most expensive problem to fix late, and the cheapest to fix today.

## Scorecard (calibrated to a prototype, out of 10)

| Area | Score | One-line rationale |
|---|---|---|
| Build and project health | **6** | Builds and tests cleanly. But there's no Linux preset, no `.exe` icon, ~88 MB of release zips committed to git (`.git` is 193 MB), and no CI. |
| Programming and architecture | **6** | Typed, data-driven, decoupled through `SignalBus`. But there's one 728-line scene script, all UI is built in code, and saves are non-atomic. |
| Performance and technical visuals | **8** | Locked 60 fps, ≤ 325 draw calls, 25-34 MB VRAM, sub-millisecond turn refresh. |
| Gameplay: core loop | **4** | It runs end to end, but turns are shallow, cover rarely comes into play, and balance spikes at the final boss. Fun is unproven, and the evidence leans "not yet". |
| Visual direction | **6** | A strong, consistent 90s-cartoon look. But sprites are static, front-facing, AI-generated, and have no animation. |
| Audio | **0** | Not a single sound file or audio node in the project. |
| UX and accessibility | **4** | The How to Play screen and hit badge are good. But input is mouse/keyboard only with hard-coded keys, there's no settings menu, and the smallest text renders at 16-17 px at 1080p. |
| Commercial readiness | **2** | The trademark-adjacent name, a generic hook, and no audio or animation pipeline. The store page has nothing to sell yet. |

## The five most important findings

1. **Trademark exposure on the title [Verified via web].** "Dungeon Crawler Carl" is ™ Veriluxx LLC and © Matt Dinniman ([Multimorphic press release, Jul 2026](https://arcadeheroes.com/news/press-releases/multimorphic-inc-launches-dungeon-crawler-carl-for-the-p³-pinball-platform/)). It has a Peacock TV series in production, and licensed tabletop and pinball games are shipping in 2026. A Steam page titled "Dungeon Crawler Carol" invites a takedown or confusion claim. Renaming now costs about an hour. Renaming after a store page, wishlists and a trailer costs far more.
2. **The battle loop doesn't yet create hard decisions [Measured + Inferred].**
   - A bot that never uses cover and plays greedily won **100%** of Medium realm-1 fights (40/40), averaging **4.3 turns** and losing 18 HP.
   - The same bot wins **20%** of Medium Sea Lord fights, **5%** on Hard, and **0%** on EXTREME.
   - So regular fights are trivial and the last boss is a wall, with nothing teaching the player in between.
3. **Cover, the headline mechanic, is rarely in play [Measured].**
   - Across 40 generated rooms, **73.5%** of possible ranged shots were in the open, and only **3.8%** were against full cover.
   - Enemy AI never seeks cover. `_enemy_step` (`scenes/tactical/TacticalBattlefield.gd:540`) paths straight at Carol.
4. **Rules bugs a player will notice [Measured].**
   - **1.6%** of highlighted move tiles silently refuse the click. The BFS range in `IsometricGrid.gd:218` ignores the spike weight set at `:175`, and the AP check at `TacticalBattlefield.gd:406` then rejects the weighted path.
   - **~10%** of "visible" tiles are behind solid cover, because fog is radius-only (`IsometricGrid.gd:276`).
   - Battle layouts aren't seeded from the run seed (`TacticalBattlefield.gd:48` calls `rng.randomize()`), so runs can't be reproduced.
5. **Zero audio, zero animation, no controller [Verified].** For a game selling "1990s arcade energy", sound and motion carry most of the feel. Today they're absent: 0 audio files, single-frame sprites, and mouse-only targeting.

## Top recommendations (details in [06-recommendations.md](06-recommendations.md))

1. **Rename the game now** (1-3 h). Keep Carol as the character. Lose the "Dungeon Crawler ___" construction.
2. **Spend the next two weeks proving the battle is fun, not adding content.** Specifically:
   - make enemies use cover and telegraph their attacks
   - give Carol one or two abilities that create real choices
   - fix the four rules bugs
   - then playtest with 3-5 people and watch them (about 25-35 h total)
3. **Add a minimal juice pass**: hit sounds, a music loop, and screen shake or squash on hits (8-12 h). This gives the fun question a fair test.
4. **Flatten the difficulty curve.** Tune realm-1 fights up and the realm-4 boss down, then re-run the auto-play sim from the appendix to verify (4-6 h).
5. **Clean up the repo foundations** (3-4 h):
   - stop committing release zips (use GitHub Releases or itch's butler)
   - add a Linux preset and an `.exe` icon
   - make saves atomic
