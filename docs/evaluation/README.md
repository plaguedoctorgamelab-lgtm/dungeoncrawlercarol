# Dungeon Crawler Carol: Lair of The Sea Lord: External Evaluation

**Build evaluated:** commit `78e1a73` on `main` ("V2 HD tactical overhaul"), Godot 4.7.2.
**Date:** 2026-11-12
**Engagement type:** evaluation only. No game code, scenes or assets were changed.

## Report index

| File | What it covers |
|---|---|
| [00-executive-summary.md](00-executive-summary.md) | Verdict, scorecard, top findings and top recommendations, in 1-2 pages |
| [01-technical-audit.md](01-technical-audit.md) | Build and project health, architecture, code quality, performance |
| [02-gameplay-and-design.md](02-gameplay-and-design.md) | Core loop, mechanics, balance, pacing, onboarding, content |
| [03-visual-audio-ux.md](03-visual-audio-ux.md) | Art direction, readability, animation, UI/HUD, audio, accessibility, input |
| [04-commercial-readiness.md](04-commercial-readiness.md) | Market position, comparable games, scope risk, IP/legal, road to a store page |
| [05-magazine-review.md](05-magazine-review.md) | A player-facing review written in a critic's voice |
| [06-recommendations.md](06-recommendations.md) | What to do, in three horizons, with effort, impact and an order of work |
| [appendix-data.md](appendix-data.md) | Raw metrics, command output, and how to reproduce every number |

## Plan I followed

1. **Survey.** I listed every tracked file (`git ls-files`: 261 files) and read the git history and every config file (`project.godot`, `export_presets.cfg`, `.gitignore`, `.gitattributes`).
2. **Read everything.** I read all 31 tracked `.gd` scripts, all 13 `.tscn` scenes, and the data behind the 43 `.tres` resources (`scripts/data/Roster.gd` generates them). I also read both design docs in `docs/`.
3. **Run it.** I ran headless import, a headless boot, the existing test suite, and a Windows export smoke test. I also ran three measurement scripts (described below).
4. **Look at it.** I opened the actual PNG assets and full-resolution screenshots rendered from the game at 1920x1080.
5. **Market check.** I ran web searches on comparable games, Steam release volume, AI disclosure rules, and the name/IP question.
6. **Write, then verify.** I wrote the report, then re-checked every path, line number and number against the repository.

## Methodology: what was verified and what was inferred

Every finding is tagged with one of these labels:

- **[Verified]**: observed directly. That means a command was run, a file was read at the cited line, or an image or screenshot was looked at.
- **[Measured]**: a number produced by a script or command. [appendix-data.md](appendix-data.md) says how to re-run it.
- **[Inferred]**: a conclusion about feel, pacing, fun or player perception, reasoned from the code, data and measurements, without a human playing. These are the claims a playtest should confirm or overturn.

**What I could do:**
- Godot 4.7.2 is on this machine, and `project.godot` targets `4.7` (`config/features`).
- I ran import, boot, the 152-check test suite and a Windows export.
- I ran three measurement scripts. One is `scripts/tools/audit_probe.gd`, which was already in the working tree, untracked, from an earlier session. The other two (`perf_probe.gd` and `autoplay_sim.gd`) were run from outside the repo, so nothing in the project changed. Together they measured:
  - frame timing and draw calls
  - scene load times
  - memory and VRAM
  - pathfinding consistency
  - how often cover is in play
  - fog vs line of sight
  - balance, across 400 automated battles played through the game's own API by a simple bot

**What I could not do:**
- **No hands-on play.** I can't play the game the way a person does with eyes, ears and a mouse. The auto-play bot is deliberately simple: it never seeks cover and never plans ahead. Its win rates are a *floor*, not a prediction of human results.
- **No Linux export.** The project has no Linux preset (`export_presets.cfg` has only `preset.0`, "Windows Desktop"), and only Windows export templates are installed. Linux export is unverified.
- **No editor warnings.** GDScript static-analysis warnings, such as unused variables, appear in the editor rather than headless runs. The headless runs produced 0 warnings and 0 errors, but that is not the same as an editor warning count.
- **No low-end or Steam Deck hardware.** Frame timing comes from one desktop machine with v-sync on. Low-end and Steam Deck performance is inferred from settings and measurements.
- **No sales data.** Market figures come from public web sources cited in [04-commercial-readiness.md](04-commercial-readiness.md). I don't have SteamDB or VG Insights sales data for comparable games, so those comparisons are directional.

**A note on history:** the game was built in one AI-assisted session over about 16 hours (4 commits, `9a94a0f` → `78e1a73`), by the same assistant writing this evaluation. I have tried to judge the build on its merits, but you should know that the evaluator and the builder are the same model. Where this report criticizes the code, it is criticizing my own earlier work.
