# Dungeon Crawler Carol: Art Pack 3 (Air Realm Monsters & Animation)

Pack 2 brought the Earth realm to life. Pack 3 does the same for the **Air realm** (realm 2, "Cloud-High Vaping Towers & Crypto Mines"), in exactly the same format.

**30 images**, the same size as pack 2:

| Group | What | Images |
|---|---|---|
| A | Air monsters: 5 types × 4 frames | 20 |
| B | Smug Vape Cloud (realm 2 boss) | 6 |
| C | Carol's last two missing poses (dash, shove) | 2 |
| D | Air realm props (mining-rig boxes, server rack) | 2 |

When it comes back, the Air realm gets the same treatment the Earth realm got in v0.6.0: animated monsters, a boss wind-up pose on its CHARGING turn, and its own cover.

---

## What changed since pack 2 (please read)

1. **Background color rule (new).** In pack 2 the Landlord Slime is green, so removing the green background also erased the slime.
   - Default: keep the **#00FF00 green** background.
   - **But if the subject has any green in it, use solid #FF00FF magenta instead.** The importer now detects the background color automatically.
   - Most of pack 3 has no green, but check the drink in the Gargoyle's hand and the ghost's glow.
2. Everything else is the same as pack 2:
   - Attach the **fit guide + reference image** to every prompt.
   - Make **one image per frame at full canvas** (512×640, boss 1024×1280).
   - Keep the **feet on the black cross** and the **same scale in every frame**.
   - Do **frame 1 first, then use it as the reference** for that monster's other frames.

Attachments: `guide_character_512x640.png`, `guide_boss_1024x1280.png`, `guide_half_cover_512x512.png`, `guide_full_cover_512x768.png`, the `ref_<monster>.png` images and `ref_carol_idle_01.png`. The monster prompt template and the props rules block are the same as pack 2 and pack 1 (`art_brief_pack2.md`, `art_brief.md`), and both are attached.

---

## Group A: Air monsters (4 frames each, `guide_character_512x640.png`, facing DOWN-LEFT)

Every monster gets four frames:

| Frame | File | What it shows |
|---|---|---|
| 1 | `<id>_idle_01` | Neutral stance |
| 2 | `<id>_idle_02` | Mid-breath or bob, with a small secondary motion |
| 3 | `<id>_attack_01` | Mid-attack, the most dramatic pose |
| 4 | `<id>_hurt_01` | Recoiling from a hit, eyes squeezed shut |

The flying monsters (the bat, the drone and the ghost) should hover a little above the cross, with a small soft shadow drawn under them on the cross.

| ID (file prefix) | Monster | Idle motion (frame 2) | Attack pose (frame 3) |
|---|---|---|---|
| `crypto_bat` | Crypto Bro Bat: purple bat, sunglasses, gold chain, gold coin | Wings flapped down, body lower, coin glinting | Diving forward and flinging the gold crypto coin, wings swept back |
| `nft_monkey` | Bored JPEG Ape: party hat, pixel sunglasses, gold chain, arms crossed | Smug head-tilt, chain bouncing | Arms unfolded, mid-punch, fist forward, hat flying off |
| `drone_drop_shipper` | Drop-Shipper Drone: blue quadcopter carrying an OVERPRICED GADGET box | Bobbing up, propellers blurred, box swaying | Tilting forward and dropping the box, the package mid-fall |
| `hustle_grindset_gargoyle` | 5 AM Grindset Gargoyle: stone gargoyle sipping an iced coffee | Sipping through the straw, wings twitching | Lunging forward, wings spread, slamming the coffee cup like a weapon |
| `algorithm_ghost` | Ad-Tech Ghost: translucent cyan ghost surrounded by BUY NOW pop-ups | Floating higher, pop-ups rearranged around it | Arms thrust forward, launching a swarm of BUY NOW pop-ups |

## Group B: Smug Vape Cloud, realm 2 boss (6 frames, `guide_boss_1024x1280.png`, 2×2 tiles)

A purple-grey cloud wearing a backwards red cap, holding a glowing vape pen. It should fill the large diamond in the guide and be clearly bigger than the regular monsters.

| File | What it shows |
|---|---|
| `vape_cloud_elemental_idle_01` | Floating smugly, vape in hand, swirling vapor |
| `vape_cloud_elemental_idle_02` | Puffing up bigger, exhaling a small vapor ring |
| `vape_cloud_elemental_charge_01` | **Winding up**: inhaling hard, cheeks puffed, the vape glowing bright neon, swelling to its biggest. This shows on its CHARGING turn. |
| `vape_cloud_elemental_attack_01` | Blasting a huge blue-raspberry vapor ring forward |
| `vape_cloud_elemental_hurt_01` | Wispy and torn apart, cap knocked sideways |
| `vape_cloud_elemental_defeated_01` | Shrunk to a sad little puff on the ground, the vape pen dropped and fizzling |

---

## Group C: Carol's last two missing poses (`guide_character_512x640.png`, facing DOWN-RIGHT)

Use the Carol prompt from `art_brief.md` (part C) and attach `ref_carol_idle_01.png`:

| File | Pose |
|---|---|
| `carol_dash_01` | Low, fast forward sprint: leaning hard forward, one leg stretched back, hair and bandana streaming, motion lines behind her |
| `carol_shove_01` | Two-handed shove: both palms thrust forward at chest height, weight on the front foot, gritted teeth |

After these, every action Carol has will play a real frame.

---

## Group D: Air realm props

Use the **pack 1 rules block** (in `art_brief.md`) with the matching guide:

| File | Guide | Prompt subject |
|---|---|---|
| `cover_mining_rig.png` (half cover) | `guide_half_cover_512x512.png` | "A waist-high stack of humming crypto-mining rig boxes with blinking green and pink LEDs, tangled cables, and a sticky note reading 'TO THE MOON'. Base fills the 512x256 diamond footprint; full image 512 x 512." |
| `cover_server_rack.png` (full cover) | `guide_full_cover_512x768.png` | "A tall black server rack with rows of glowing neon blinking lights, a front glass door facing front-left, and a small vapor cloud drifting off the top. Base fills the 512x256 diamond footprint; full image 512 x 768." |

The mining rig LEDs are green, so this one needs the **magenta background**.

---

## Delivery

One zip laid out like pack 2:

```
pack3/
  enemies/crypto_bat/crypto_bat_idle_01.png ... (4 per monster)
  enemies/nft_monkey/...
  enemies/drone_drop_shipper/...
  enemies/hustle_grindset_gargoyle/...
  enemies/algorithm_ghost/...
  enemies/vape_cloud_elemental/vape_cloud_elemental_idle_01.png ... (6)
  carol_frames/carol_dash_01.png, carol_shove_01.png
  cover_mining_rig.png
  cover_server_rack.png
```

**Next after this:** pack 4 is the Fire realm and pack 5 is the Water realm (including the Sea Lord and Princess Penny).
