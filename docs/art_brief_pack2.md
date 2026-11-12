# Dungeon Crawler Carol: Art Pack 2 (Earth Realm Monsters & Animation)

Pack 1 gave Carol real animation and made the props and traps sit on the grid. Pack 2 does the same for **everything you meet in the Earth realm** (realm 1). That makes the first realm a fully animated slice of the game.

**30 images in total**, about the same size as pack 1 (27):

| Group | What | Images |
|---|---|---|
| A | Earth monsters: 5 types × 4 frames | 20 |
| B | HOA President Golem (realm 1 boss) | 6 |
| C | Carol's two missing poses (drink, dodge) | 2 |
| D | Earth realm props (trash can, privacy fence) | 2 |

When this comes back, I'll give monsters the same frame system Carol has. They'll play idle, attack and hurt frames, turn to face their target, and the boss will show a real wind-up pose on its CHARGING turn.

---

## Lessons from pack 1 (please read first)

Pack 1 came out well, but the generator didn't get the reference images, and the frames came back small. This time:

1. **Attach the reference image AND the fit guide to every prompt.** Both are included with this email:
   - `ref_<monster>.png`: what each monster looks like now
   - `ref_carol_idle_01.png`: Carol now
   - `guide_character_512x640.png`: for regular monsters and Carol
   - `guide_boss_1024x1280.png`: for the 2×2 boss
   - `guide_half_cover_512x512.png` and `guide_full_cover_512x768.png`: for props
2. **One image per frame, at full canvas size:** 512×640 for regular monsters and Carol, 1024×1280 for the boss. Pack 1's frames arrived at 280 px, which is usable but soft.
3. **Feet on the black cross in every frame, same size in every frame.** I re-align small drift automatically.
4. **Solid #00FF00 green background.** No transparency is needed; I remove the green myself.
5. **Do frame 1 of each monster first, then attach it as the reference** for that monster's other frames.

---

## The monster frame prompt (Groups A and B)

Attach `ref_<monster>.png` plus the guide, and change only the POSE line:

```
[MONSTER NAME], the exact same character as the attached reference image: same design, same colors, same accessories, same proportions, same outline weight. Do not redesign it.
POSE: [pose line from the tables below]
Facing DOWN-LEFT (toward the front-left of the screen) in 2:1 pixel-art isometric view (camera above, 26.57 degree angle), full body, orthographic.
Its feet / base stand exactly on the black cross at the center of the magenta diamond in the attached guide; the top of its head must stay below the yellow line. Same size and scale in every frame: it is about 400 px tall from base to top (boss: about 900 px).
Thick black outline, vibrant 90s neon cartoon palette, 16-bit Sega Genesis style. Solid flat #00FF00 green background, no ground, no drop shadow, no guide lines in the final image.
```

They face **down-left** because they usually face Carol, who starts on the left. The game mirrors them when they turn the other way.

### Group A: Earth monsters (4 frames each, `guide_character_512x640.png`)

Every monster gets the same four frames:

| Frame | File | What it shows |
|---|---|---|
| 1 | `<id>_idle_01` | Neutral stance, relaxed |
| 2 | `<id>_idle_02` | Same stance, mid-breath: body slightly squashed or bobbing, a small secondary motion (see table) |
| 3 | `<id>_attack_01` | Mid-attack, the most dramatic pose (see table) |
| 4 | `<id>_hurt_01` | Recoiling from a hit, eyes squeezed shut, leaning back |

| ID (file prefix) | Monster | Idle motion (frame 2) | Attack pose (frame 3) |
|---|---|---|---|
| `earth_slime_suit` | Landlord Slime | Slime body sags lower, the RENT DUE notice flaps | Lunges forward, stretching tall, slapping the RENT DUE notice toward the viewer |
| `lawn_mower_drone` | Karen's Turbo Mower | Engine shudder: body tilted, small exhaust puff | Rearing up on its back wheels, blades spinning with grass and motion lines flying |
| `clipboard_intern` | Unpaid Intern Zombie | Shoulders slumped further, coffee sloshing | Lurching forward, swinging the clipboard overhead like a club |
| `gated_community_guard` | Mall Cop Mercenary | Segway rocking back, flashlight swaying | Leaning forward, shouting into the megaphone, sound-wave rings blasting out |
| `tax_auditor_mole` | Tax Auditor Mole | Adjusting glasses, nose twitching | Hurling a crumpled tax receipt overhand, paper flying |

### Group B: HOA President Golem, realm 1 boss (6 frames, `guide_boss_1024x1280.png`)

The boss stands on a **2×2-tile footprint**, the big diamond in the guide, so it should fill that space and be clearly bigger than the other monsters.

| File | What it shows |
|---|---|
| `bureaucrat_golem_idle_01` | Looming, arms folded, smug |
| `bureaucrat_golem_idle_02` | Same, chest out, mid-breath, rubble crumbling off |
| `bureaucrat_golem_charge_01` | **Winding up its big hit**: rearing back, a glowing FINED stamp or fist raised high, eyes glowing yellow. This shows during the game's CHARGING turn. |
| `bureaucrat_golem_attack_01` | Slamming the stamp or fist down, a shockwave ring on the ground |
| `bureaucrat_golem_hurt_01` | Chunks of rock cracking off, staggering back |
| `bureaucrat_golem_defeated_01` | Crumbled into a pile of rubble with its tie and papers on top |

---

## Group C: Carol's missing poses (2 frames, `guide_character_512x640.png`)

Use the same Carol prompt as pack 1 (in `art_brief.md`, part C), attach `ref_carol_idle_01.png`, and face **down-right** as before:

| File | Pose |
|---|---|
| `carol_drink_01` | Tilting her head back, chugging a neon RADICAL energy drink can, sword lowered, fizzing bubbles |
| `carol_dodge_01` | Leaning sharply sideways out of the way, one foot lifted, hair swinging, surprised face |

---

## Group D: Earth realm props (2 images)

Use the **pack 1 rules block** (in `art_brief.md`) at the end of each prompt, and the matching guide:

| File | Guide | Prompt subject |
|---|---|---|
| `cover_trash_can.png` (half cover) | `guide_half_cover_512x512.png` | "A dented metal suburban garbage can overflowing with junk mail and HOA violation notices, lid askew, a stray cat tail poking out. Base fills the 512x256 diamond footprint; full image 512 x 512." |
| `cover_privacy_fence.png` (full cover) | `guide_full_cover_512x768.png` | "A tall wooden privacy-fence section with a 'NO TRESPASSING - HOA' sign and a garden gnome peeking over the top. The fence panel runs along the front-left face. Base fills the 512x256 diamond footprint; full image 512 x 768." |

The trash can becomes the realm 1 half cover alongside the crate. The fence becomes the realm 1 full cover alongside the vending machine.

---

## Delivery

One zip, with the file names above, laid out like this:

```
pack2/
  enemies/earth_slime_suit/earth_slime_suit_idle_01.png ... (4 per monster)
  enemies/lawn_mower_drone/...
  enemies/clipboard_intern/...
  enemies/gated_community_guard/...
  enemies/tax_auditor_mole/...
  enemies/bureaucrat_golem/bureaucrat_golem_idle_01.png ... (6)
  carol_frames/carol_drink_01.png, carol_dodge_01.png
  cover_trash_can.png
  cover_privacy_fence.png
```

When it arrives, I'll:
1. Run the importer: remove the green, align feet, normalize the scale.
2. Add monster frame animation, with idle loops, attack, hurt, the boss charge pose, the boss defeat pose, and monsters turning to face Carol.
3. Use the trash can and fence as Earth realm cover.
4. Hook up Carol's drink and dodge poses.

**After that (pack 3 and later):** the Air, Fire and Water monsters and bosses, plus their realm props, in the same format, one realm per pack.
