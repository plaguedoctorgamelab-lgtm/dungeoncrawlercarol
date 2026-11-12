# 04: Commercial Readiness

Labels:
- **[Web]**: checked through web search on 2026-11-12, with the source linked.
- **[General]**: general industry knowledge, not verified for this report.
- **[Inferred]**: my reasoning.

## 1. Where it would sit

- **Genre on Steam:** single-hero, turn-based tactics roguelite with a branching map. The tags would be *Tactical RPG, Roguelite, Turn-Based Tactics, Isometric, Comedy, Pixel Graphics, LGBTQ+* (the hero is rescuing her girlfriend).
- **Comparable games** [General unless marked]:

| Game | What it shares | What it does better (the bar you'll be compared to) |
|---|---|---|
| *Into the Breach* (2018) | Small-grid tactics with short runs | Telegraphed enemy intent makes every turn a puzzle; pushing enemies around |
| *XCOM 2* (2016) | Cover percentages, AP-style turns | Flanking, overwatch, enemies that use cover, squad builds |
| *Slay the Spire* (2019) | Branching map, roguelite run | Every node is a build decision (cards, relics); meta-unlocks |
| *Tactical Breach Wizards* (2024) | Comedy-forward turn-based tactics | Every action is a joke *and* a tactical tool; strong writing |
| *Mario + Rabbids Kingdom Battle* (2017) | Cartoon humour + cover tactics | Dash and team-jump movement makes positioning the fun |
| *Rogue Tactics* (Aug 2025, $4.99), *Valiant Tactics* (Aug 2025) | Turn-based tactical roguelites released recently | Shows the niche is crowded at the low price end. [Web: [DekuDeals](https://www.dekudeals.com/items/rogue-tactics), [Game Developer](https://www.gamedeveloper.com/press-release/liberation-starts-as-valiant-tactics-launches-on-steam-today-)] |

- **Market conditions:**
  - Steam got roughly **19,000-21,500 new games in 2025**, and about half of them had fewer than 10 reviews [Web: [GamingOnLinux](https://www.gamingonlinux.com/2025/12/over-19000-games-have-released-on-steam-in-2025-with-nearly-half-seeing-fewer-than-10-reviews), [howtomarketagame.com](https://howtomarketagame.com/2026/01/08/how-many-games-were-released-in-2025/)].
  - Roguelites keep producing solo-dev hits; *Slots & Daggers* sold 100k in 10 days [Web: [GamesRadar](https://www.gamesradar.com/games/roguelike/another-roguelike-success-story-has-hit-steam-d-and-d-flavored-slot-machine-slots-and-daggers-sells-100-000-copies-in-10-days-a-surreal-number-for-a-solo-dev-like-me)].
  - But those hits had a mechanical hook you could describe in one line.
- **What could set it apart** [Inferred]:
  1. **The tone.** 90s corporate-satire cartoon monsters (the HOA Golem, the Crypto Bro Bat, the Layoff Executioner) are funny, current and very screenshot-friendly. This is the strongest asset in the project.
  2. **The heroines.** A punk heroine rescuing her tattooed barista girlfriend is a warm, uncommon premise with an audience that actively looks for it.
  3. **Missing: a mechanical hook.** Today the systems are "XCOM cover + Slay the Spire map", which is a well-trodden combination. To make it on Steam, the one-line pitch needs a verb nobody else has. The corporate theme hints at some, for example "monsters you can *fire*, *audit* or *unionize* instead of kill".

## 2. Legal, IP and policy risks

| Risk | Evidence | Severity |
|---|---|---|
| **The title is close to a live franchise.** "Dungeon Crawler Carl" is ™ Veriluxx LLC and © Matt Dinniman. It has a Peacock live-action series in production, and licensed pinball, tabletop RPG and deckbuilder releases in 2026. "Dungeon Crawler Carol" differs by one letter and is in the same "dungeon crawler" category. | [Web: [Multimorphic/Arcade Heroes press release](https://arcadeheroes.com/news/press-releases/multimorphic-inc-launches-dungeon-crawler-carl-for-the-p³-pinball-platform/), [Renegade Game Studios](https://renegadegamestudios.com/blog/renegade-game-studios-announces-two-upcoming-dungeon-crawler-carl-tabletop-games/), [ComicBookMovie](https://comicbookmovie.com/sci_fi/dungeon-crawler-carl-games-arrive-next-month-while-peacocks-live-action-series-gears-up-to-shoot-a230569?rc=fm)] | **Critical.** Expect at best confusion and buried search results, and at worst a takedown after you've built wishlists. This is not legal advice; ask an IP lawyer if you want to keep it. Renaming is the cheap path. |
| **Style references in the prompts.** The art manifest's style anchor names *Zombies Ate My Neighbors* (`docs/master_graphics_asset_manifest.md`, section 1). Style isn't protected, but don't use that name in store copy. | [Verified] | Low |
| **AI-generated content disclosure.** Steam needs a disclosure for AI content that players see. The January 2026 rewrite narrowed it to player-facing content. Every sprite and screen in this build is AI-generated, so you'd disclose them. Part of the itch.io and Steam audience reacts badly to AI art. | [Web: [Notebookcheck](https://www.notebookcheck.net/Steam-updates-AI-disclosure-form-requiring-developers-to-report-visible-and-in-game-AI-but-not-background-tools.1206103.0.html), [GIGAZINE](https://gigazine.net/gsc_news/en/20260120-steam-updates-ai-disclosure-guidelines)] | Medium. Allowed, but it affects reception, and AI art is hard to animate consistently (03-V4). |
| **No credits or license file.** The game uses Godot (MIT, which needs its notice in the credits) and its fonts. There's no credits screen. | [Verified] no credits scene; `git ls-files` shows no LICENSE | Low; 1 h fix |

## 3. Biggest scope risks for a solo developer [Inferred]

1. **Animation × roster size.** 24 monsters + Carol + Penny is about 26 characters. Even 4 animations each (idle, move, attack, hit/die) is more than 100 animation sets. This is the single largest cost to ship, and it's why the art-source decision (03-V4) matters now. **Cut the roster to 8-10 well-animated enemies.** Re-skins can cover the rest.
2. **Balancing a roguelite.** Four realms × four difficulties × a random map is a big test matrix. Keep the auto-play sim (in the appendix) as a regression tool, and cut it to two difficulties until the game is fun.
3. **Depth before breadth.** The build already has more content than its core mechanics can support (02, section 2). Adding realms or monsters before the turn is interesting is the classic solo trap.
4. **UI rebuild.** Moving 7 code-built screens into editor scenes (01-A2) gets more expensive with every screen you add.

## 4. From here to store page, demo and launch

| Milestone | What's missing | Rough effort |
|---|---|---|
| **Store page ("Coming Soon")** | A new name and logo · 5+ screenshots that show *decisions*, not just layout · a capsule (main 462×174, plus the large sizes) · a trailer of at least 30 s with motion and sound · a short description with a one-line hook · an AI disclosure | 25-40 h, *after* the rename and a juice pass |
| **Playable demo (Steam Next Fest)** | Realm 1 polished · audio · basic animation · a settings menu · a pause menu · controller or at least Steam Deck "Playable" · a tutorial fight · a crash-free save · an atomic save · a Linux build · a feedback link | 120-200 h |
| **Launch** | The above for all realms · balance across difficulties · meta-progression or replay hooks · achievements (optional) · localization (optional) · credits · press kit | 400-800 h for one person [Inferred; a wide range because animation dominates] |

**Pricing guess** [Inferred]: $9.99-14.99 at launch, in line with small tactics roguelites. A lower price doesn't fix low visibility, though; wishlists do.
