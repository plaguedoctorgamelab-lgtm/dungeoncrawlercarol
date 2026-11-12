# Dungeon Crawler Carol: Art Brief (v0.4)

This is what to ask an image generator for so the new art fits the game's grid exactly.

It covers:
- **Part A:** obstacles (cover props)
- **Part B:** trap floor tiles (new in v0.4)
- **Part C:** Carol's frame-by-frame animation

Each request uses one of the fit-guide images in `docs/art_guides/`. They're attached to the email.

---

## Why the current props don't line up

The game's floor tile is a **2:1 diamond, 128×64 pixels**. Every diagonal edge goes **2 pixels across for 1 pixel down**, an angle of about 26.6°. Pixel-art games call this "2:1 isometric".

The old art prompt asked for a "30-degree isometric angle", and the current crate and vending machine are drawn as front-facing 3/4 pictures. Neither matches the grid's diamond, so props float or overhang their tile.

The fix is to tell the generator:
- the exact angle
- the exact footprint
- the height
- where the object sits on the canvas

Everything below is drawn at **4× game size** (one tile = 512×256), so it scales down to a perfect fit.

## The fit guides

| File | Use it for | Canvas |
|---|---|---|
| `guide_half_cover_512x512.png` | Crates, trash cans, other short cover | 512×512 |
| `guide_full_cover_512x768.png` | Vending machines, walls, other tall cover | 512×768 |
| `guide_floor_trap_512x256.png` | Flat trap and floor decals | 512×256 |
| `guide_character_512x640.png` | Every Carol animation frame | 512×640 |

Upload the matching guide with every prompt and add:

> "Draw the object exactly inside the magenta guide lines in the attached image, then remove the guide lines. Keep the green background."

---

## The rules block (paste at the end of every prop and trap prompt)

```
2:1 pixel-art isometric projection (dimetric, 26.57 degree lines: every diagonal edge goes exactly 2 pixels across for 1 pixel down), orthographic, NO perspective, NO vanishing points. The object stands on a single diamond floor tile whose footprint is exactly 512 px wide and 256 px tall, with the diamond's bottom point touching the bottom-center of the canvas. Canvas 512 px wide. Show only the TOP face and the two FRONT faces (front-left and front-right); vertical edges perfectly vertical. Light from the upper-left: top face brightest, left face medium, right face darkest. Thick black outline, vibrant 90s neon cartoon palette, 16-bit Sega Genesis style. Solid flat #00FF00 green background, no floor tile, no ground, no drop shadow, no green tint on the edges, nothing touching the canvas edges except the base.
```

---

## Part A: Obstacles

**A1. Wooden crate (half cover).** Use `guide_half_cover_512x512.png`.
```
A single sturdy wooden shipping crate stamped "PROFIT" in red stencil on the front-left face, metal corner brackets, slightly beat-up. A cube that fills the whole 512x256 diamond footprint; its vertical edges are 256 px tall, so the full image is 512 px wide x 512 px tall. [rules block]
```

**A2. Vending machine (full cover).** Use `guide_full_cover_512x768.png`.
```
A single retro 90s soda vending machine, hot pink and teal with yellow trim, glowing drink rows and a coin slot. Its FRONT (the glass and buttons) faces the front-left; its right side is a plain darker panel. Base fills the whole 512x256 diamond footprint; its vertical edges are 512 px tall, so the full image is 512 px wide x 768 px tall. [rules block]
```

**A3. Optional variety, one pair per realm.** Same rules, swapping the subject:

| Realm | Half cover (512×512) | Full cover (512×768) |
|---|---|---|
| Earth (suburbs/HOA) | Overflowing trash can | Wooden privacy-fence section |
| Air (crypto/vape) | Stack of crypto-mining rig boxes | Glowing server rack |
| Fire (VC mansions) | Smoldering stack of pitch decks | Marble column with a gold dollar sign |
| Water (boardroom) | Barnacled filing cabinet | Office cubicle wall covered in coral |

**A4. Overheated Espresso Machine (exploding barrel, new in v0.4).** Use `guide_half_cover_512x512.png`.
```
A single chrome-and-red commercial espresso machine that is dangerously overheating: steam jets, glowing red pressure gauge, yellow-and-black hazard stripes around the base, a "DANGER: HOT" sticker. Fills the 512x256 diamond footprint; vertical edges 256 px tall, full image 512 x 512. [rules block]
```

Prop file names: `cover_wooden_crate.png`, `cover_vending_machine.png`, `cover_trash_can.png`, `cover_<realm>_<name>.png` and `trap_espresso_machine.png`.

---

## Part B: Trap floor tiles (new in v0.4)

These are flat. They lie *on* the floor diamond and shouldn't stick up more than a few pixels. Use `guide_floor_trap_512x256.png` and this rules block instead:

```
Flat floor decal in 2:1 pixel-art isometric projection (26.57 degree diamond), viewed from above at the same angle as an isometric floor tile. Fills the 512x256 diamond exactly and nothing outside it; may rise at most 40 px above the diamond. Light from the upper-left, thick black outline, vibrant 90s neon cartoon palette, 16-bit Sega Genesis style. Solid flat #00FF00 green background, no drop shadow.
```

| File | Trap | Prompt subject |
|---|---|---|
| `trap_spikes.png` | Spike trap (8 dmg to Carol, 15 to monsters) | "A square steel floor plate with six sharp metal spikes poking up" |
| `trap_live_wire_on.png` | Live wire, **active** (12 dmg) | "Sparking downed power cables crackling with bright cyan-yellow electricity across a metal floor grate" |
| `trap_live_wire_off.png` | Live wire, **inactive** | "The same downed power cables on a metal floor grate, dark and not sparking" |
| `trap_red_tape.png` | Red Tape (stops movement, drains AP) | "A tangled sticky mess of red bureaucratic tape and 'APPROVAL PENDING' forms glued to the floor" |

---

## Part C: Carol frame-by-frame animation

Carol is currently one picture, so the game can only move and tilt it. Real frames make her legs walk and her sword swing.

### The frame list (about 18 images)

| Animation | Frames | File names | What each frame shows |
|---|---|---|---|
| Idle | 3 | `carol_idle_01..03` | Breathing: neutral → chest up, shoulders raised → neutral with sword dipped |
| Walk | 6 | `carol_walk_01..06` | One full stride: contact, down, pass, up, contact (other leg), pass |
| Sword attack | 4 | `carol_attack_01..04` | Wind-up (sword back over the shoulder), mid-swing, impact (sword fully forward, motion lines), recover |
| Shoot | 2 | `carol_shoot_01..02` | Aiming the blaster forward → recoil (arm kicked up, muzzle flash) |
| Hit | 2 | `carol_hit_01..02` | Flinch backward, wincing → stagger |
| Knocked out | 2 | `carol_down_01..02` | Falling backward → lying flat on the tile |
| Victory | 1 | `carol_victory_01` | Sword raised high, fist pump, big grin |

**Facing:** draw everything facing **down-right** (toward the front-right of the screen). The game mirrors it for the other direction.

### Prompt template (one image per frame)

Upload `guide_character_512x640.png` **and** your current Carol image as references for every frame, and keep the prompt identical except the pose line:

```
Carol, the exact same character as the attached reference image: punk heroine, red bandana, long black hair, sleeveless denim vest, white tank top, denim shorts, fingerless gloves, red high-top sneakers, magic glowing pink star-sword. Same outfit, same proportions, same colors, same sword, same outline weight as the reference.
POSE: [pose line from the table above, e.g. "walk cycle frame 3 of 6: passing position, left leg lifted and passing the right leg, arms swinging"]
Facing down-right in 2:1 pixel-art isometric view (camera above, 26.57 degree angle), full body, orthographic.
Her feet stand exactly on the black cross at the center of the magenta diamond in the guide image; the top of her head (and sword tip) must stay below the yellow line. Same size and scale in every frame: she is about 400 px tall from feet to top of head.
Thick black outline, vibrant 90s neon cartoon palette, 16-bit Sega Genesis style. Solid flat #00FF00 green background, no ground, no drop shadow, no guide lines in the final image.
```

### Consistency tips (this is where AI generators struggle)
1. **Do frame 1 first, then make it the reference for the rest.** Attach your best frame 1 and say "same character, same scale, only change the pose."
2. **Keep the camera and lighting words identical.** Don't rephrase between frames.
3. **Check the feet.** They should land on the cross in every frame. If they drift, I can re-align small differences automatically, but large jumps in size or angle can't be fixed.
4. **Reject frames where the outfit changes,** for example the sword turning a different color, the vest vanishing, or the hair flipping sides.
5. **The walk cycle matters most.** If you only get time for one set, do the 6 walk frames and the 4 attack frames.

---

## Delivering the images

Put everything in one folder (a zip is fine) using the file names above, keeping the green backgrounds. Then tell me where it is. I'll:
1. Remove the green, auto-align feet and bases to the grid, and normalize the scale.
2. Swap the new props and traps in, keeping the old art as a fallback if anything's missing.
3. Build Carol's frame animations in Godot, so walk, attack, hit and the rest play real frames, and keep the current procedural motion layered on top.
4. Render before-and-after screenshots and email them to you.
