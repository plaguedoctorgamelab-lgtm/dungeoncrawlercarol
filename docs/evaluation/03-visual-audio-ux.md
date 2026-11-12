# 03: Visual, Audio and UX

Labels: [Verified] = I looked at the actual PNG or the rendered screen · [Measured] · [Inferred].
Assets examined: `screen_title.png`, `screen_victory.png`, `carol_iso.png`, `vape_cloud_elemental.png`, `gated_community_guard.png`, `proj_pink_slip.png` and `tile_earth_floor` (master), plus six 1920×1080 renders in `docs/screenshots/`.

## 1. Art direction

**Direction: strong and coherent. Execution: placeholder-grade in the ways that count for a tactics game.**

What's good [Verified]:
- **A clear identity.** Every asset shares one look:
  - neon magenta, cyan and yellow
  - thick black outlines
  - exaggerated 90s Saturday-morning cartoon faces
  - corporate-satire jokes built into the designs (a Segway mall cop with a megaphone, a vape cloud in a backwards cap, a flaming pink slip)
- The title and victory art (`screen_title.png`, `screen_victory.png`, 1920×1080) are genuinely striking, and they'd make a usable store capsule after a re-crop.
- **The characters read at gameplay size.** At 128 px on the grid, Carol, the bosses and most enemies are recognizable in `docs/screenshots/03_battle_realm*.png`.
- **The UI matches the art.** `UiKit.theme()` (`scripts/ui/UiKit.gd`) uses pink, teal and yellow neon borders on deep purple, which suits the art.

Problems:

| # | Finding | Evidence | Placeholder or direction? |
|---|---|---|---|
| V1 | **Sprites face the camera, not the isometric angle.** The units are front-facing cartoon portraits standing on an isometric floor, so the 2.5D illusion is weak. There's no facing direction and no flip toward the target. | [Verified] `carol_iso.png`, `gated_community_guard.png`; battle screenshots | **Direction:** decide now whether units are iso-angled or flat billboards, because it changes every future asset |
| V2 | **No animation at all.** There's one frame per unit and movement is a position tween (`BattleUnit.step_to`). There are no idle, walk, attack, hit or death frames. | [Verified] `assets/sprites/` has one PNG per unit; there's no `AnimatedSprite2D` or `SpriteFrames` anywhere | Placeholder, but the *pipeline* question matters now (see V4) |
| V3 | **Fake pixel art filtered smoothly.** The masters are AI-generated "pixel style" images with inconsistent pixel sizes: chunky on the title screen, fine on the sprites. V2 switched to linear filtering (`project.godot:42`) and downscales by 2×, so the "pixels" render soft and at mixed densities. | [Verified] by comparing `screen_title.png` with the battle sprites | **Direction:** pick either true low-res pixel art at integer scale, or clean HD cartoon. Mixing them looks cheap at store-page size [Inferred]. |
| V4 | **The art is AI-generated.** The masters came from AI generation on green screen (`docs/master_graphics_asset_manifest.md`, section 1, "AI Prompt Anchor"). That's fine for a prototype. But AI art is hard to *animate consistently*, and it needs a Steam content disclosure (see 04). | [Verified] in the manifest | **Direction:** decide the final art source before you produce 24+ animated units |
| V5 | **The map is busy.** 12-17 props per room (`TacticalBattlefield.gd:165`) are tall vending machines (128×192), and they hide units and tiles behind them. Nothing makes props transparent when a unit is behind them. | [Verified] `03_battle_realm4.png` (the boss is partly hidden behind machines) | Placeholder, but fix before a demo |
| V6 | **The palette and floors differ by realm, but the props don't.** Every realm uses the same crate and vending machine. | [Verified] `_place_terrain` loads only `cover_wooden_crate` and `cover_vending_machine` | Placeholder |

## 2. Audio

**There is none [Verified].**
- 0 `.ogg`, `.wav` or `.mp3` files.
- 0 `AudioStreamPlayer` nodes.
- 0 references to `AudioServer` (`git grep`; see the appendix).

For a game whose pitch is 90s arcade energy, audio is roughly half of the feel. It's what makes hits, misses, turn changes and boss reveals register [Inferred].

- It's normal for a prototype to have *placeholder* audio.
- It's not normal to have *none* when you're trying to judge whether it's fun. A silent build will playtest worse than it really is.
- Fix: about 8-12 h with free SFX packs and one music loop per realm.

## 3. UI and HUD

What's good [Verified]:
- **The hit badge.** A neon "85% HIT" label with the cover name and target HP shows on hover (`TacticalHUD.gd:113-155`). There's an open/half/full key next to it.
- **Range highlighting.** Cyan for movement, pink for weapon range, and an outline on the target (`scenes/tactical/GridOverlay.gd`).
- **A combat log** of the last 6 lines (`TacticalHUD.gd:249`), plus AP pips and an HP bar.
- **How to Play** comes before the map, and the map has a node legend.

Problems:

| # | Finding | Evidence |
|---|---|---|
| U1 | **No settings menu.** There's no volume control (no audio exists anyway), no resolution or window mode setting (it always boots fullscreen, `project.godot:24`), no keybinds and no text size option. Steam reviewers expect at least window mode and volume. | [Verified] no `ConfigFile` use anywhere |
| U2 | **No pause or in-battle menu.** Esc does nothing in battle. The only way out is to finish the fight or close the game. | [Verified] `TacticalBattlefield._unhandled_input` (`:334-349`) handles no Esc |
| U3 | **Small text.** The design sizes go down to 11 px (`TacticalHUD.gd` help text; the hit-badge key), which is 16.5 px at 1080p and about 11 px effective on a 7" Steam Deck [Inferred]. Body text is 13-15 px design size, so 19-22 px at 1080p. | [Verified] font sizes in `TacticalHUD.gd`, `HowToPlay.gd` |
| U4 | **Hover-only information.** Enemy role, HP and flavour text appear only on mouse hover. There's no way to inspect a unit with a controller or keyboard. | [Verified] `_update_hover` (`TacticalBattlefield.gd:352`) |
| U5 | **Hit-chance art duplication.** `ui_hit_chance_badge.png` has "85%" baked in, so it's no longer used, and the HUD draws its own badge. It's dead weight in the build. | [Verified] README "Notes" section |

## 4. Accessibility and input

| Area | State | Evidence |
|---|---|---|
| Controller / Steam Input | **None.** Mouse is required to move and target. | [Verified] 0 `JOY_*` or `is_action` uses |
| Key rebinding | None; keys are hard-coded | `TacticalBattlefield.gd:344-348` |
| Colour-blind safety | Cyan (move) vs pink (range) is distinguishable for most people. But red/green is used for HP (`UiKit.GREEN`/`RED` in `TacticalHUD.update_all`), and enemy HP bars are pink vs Carol's cyan | [Verified]; [Inferred] risk for protanopia |
| Text scaling | None | U3 |
| Screen shake / flash toggles | No shake exists. The white hit flash (`BattleUnit.take_damage`, modulate ×4) has no toggle | [Verified] |
| Game speed | No animation-speed option. The enemy phase is already fast (250 ms for 3 enemies) [Measured] | |

**Placeholder vs direction:**
- *Placeholder* (fine for now): no animation, no SFX, rough props.
- *Direction* (decide now):
  - billboard vs isometric-angled units (V1)
  - true pixel art vs HD cartoon (V3)
  - where the final art comes from (V4)
  - whether you'll support controllers. That decides whether hover-only UI (U4) must go.
