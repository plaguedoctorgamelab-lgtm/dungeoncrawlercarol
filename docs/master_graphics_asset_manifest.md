# Dungeon Crawler Carol: Lair of The Sea Lord - Master Graphics Asset Manifest

This document is a complete, consolidated catalog of all visual assets required to build *Dungeon Crawler Carol: Lair of The Sea Lord*. It includes sprite IDs, technical descriptions, asset categories, and exact AI image generation prompts for every character, enemy, weapon, projectile effect, terrain tile, cover object, and UI element.

## 0. V2 HD Asset Specs (1920x1080 Fullscreen)

V2 replaces the 16x16 / 32x32 pixel sprites with high-resolution transparent PNGs:

* **Source art:** `512x512` (or larger) AI generations on `#00FF00`, with the green background removed.
* **Pipeline:** `scripts/tools/build_assets.gd` crops each master to its visible pixels, removes leftover green spill, and stores it at about 2x its on-screen footprint (units 256px, bosses 512px, vending machines 256x384, projectiles/items 128px). Floor tiles are cut to exact `128x64` diamonds; title and victory art is resized to `1920x1080`.
* **Runtime scaling:** `scripts/util/SpriteScaler.gd` reads each texture's size and scales the `Sprite2D` uniformly to its footprint, bottom-center anchored on the isometric tile center.
* **Filtering:** Linear.
* **Missing art:** `SpriteScaler.texture()` returns a procedural placeholder for any PNG that isn't in `res://assets/sprites/` yet.

| Asset family | Battlefield footprint | Stored size |
| :--- | :--- | :--- |
| Isometric floor tiles (`tile_*_floor_iso`) | `128 x 64` diamond | `128 x 64` |
| Carol, Princess Penny, regular enemies (1x1 tile) | `128 x 128` | max `256 x 256` |
| Level bosses (2x2 tiles) | `256 x 256` | max `512 x 512` |
| Half cover (`cover_wooden_crate`) | `128 x 128` | max `256 x 256` |
| Full cover (`cover_vending_machine`) | `128 x 192` | max `256 x 384` |
| Projectiles (`proj_*`) and pickups | `56 x 56` | max `128 x 128` |
| Spike hazard decal (`hazard_spikes_iso`) | `112 x 84` | max `128 x 96` |
| Portraits (`carol_portrait`, `penny_portrait`) | UI | `256 x 256` |
| Screens (`screen_title`, `screen_victory`) | full screen | `1920 x 1080` |

## 1. Master Style Guide & AI Prompt Anchor

When generating imagery with AI tools (Midjourney, DALL-E 3, Stable Diffusion), **always append the Master Style Anchor Block** to the end of every prompt to maintain visual consistency across all sprites.

### Master Style Anchor Block:

> `16-bit pixel art, 1990s Sega Genesis video game sprite, isolated 2.5D isometric perspective, vibrant neon color palette, sharp black outlines, arcade cartoon style like Zombies Ate My Neighbors, 30-degree isometric angle projection, isolated on solid green background #00FF00, no drop shadow.`

## 2. Protagonist & Key Characters

| Sprite ID | Asset Name | Description | Full AI Generation Prompt | 
| ----- | ----- | ----- | ----- | 
| `carol_iso` | **Carol (Heroine)** | 90s badass heroine with a red bandana, denim vest, cargo pants, swinging a glowing neon-pink magic star-sword. | *16-bit pixel art, isometric 2.5D view of Carol, 90s badass heroine in a red bandana and denim vest, swinging an oversized glowing neon-pink magic sword, Zombies Ate My Neighbors retro arcade style, vibrant neon colors, isolated on solid green background #00FF00, no drop shadow.* | 
| `princess_barista_iso` | **Princess Penny (The Rescue Target)** | Kick-ass barista princess with neon-pink hair, rad sleeve tattoos, denim barista apron, high-top sneakers, trapped in a neon cage. | *16-bit pixel art, isometric 2.5D view of Princess Penny, a kick-ass barista princess with bright neon-pink hair, sleeve tattoos, denim coffee apron over combat boots, high-fiving posture, 90s Sega Genesis retro arcade style, vibrant neon colors, isolated on solid green background #00FF00, no drop shadow.* | 
| `sea_lord_boss` | **The Sea Lord (Final Boss)** | Bloated grotesque underwater warlord in a cheap pinstripe business suit, golden crown, holding a CEO golden trident. | *16-bit pixel art, isometric 2.5D view of the Sea Lord, a bloated grotesque underwater warlord in a cheap pinstripe business suit wearing a golden crown and holding a CEO golden trident, smarmy expression, 90s Sega Genesis style, isolated on solid green background #00FF00.* | 

## 3. Level 1: Earth Realm (Suburbs & HOA Dungeons)

| Sprite ID | Enemy Name | Role / Behavior | Full AI Generation Prompt | 
| ----- | ----- | ----- | ----- | 
| `earth_slime_suit` | **Landlord Slime** | Melee Swarm | *Isometric 2.5D pixel art of a slimy green blob wearing a tiny crooked tie and holding a "Rent Due" eviction notice, 90s Genesis cartoon style, isolated on solid green background #00FF00.* | 
| `lawn_mower_drone` | **Karen's Turbo Mower** | Fast Charger | *Isometric 2.5D pixel art of a motorized yellow riding lawnmower with an angry face painted on the hood and razor blades spinning, 90s arcade style, isolated on solid green background #00FF00.* | 
| `clipboard_intern` | **Unpaid Intern Zombie** | Swarm Melee | *Isometric 2.5D pixel art of a tired zombie wearing a crumpled office shirt holding a spilling mug of cold coffee and a clipboard, 90s Genesis style, isolated on solid green background #00FF00.* | 
| `gated_community_guard` | **Mall Cop Mercenary** | Ranged Shooter | *Isometric 2.5D pixel art of a smarmy mall security guard riding a motorized Segway holding a megaphone and a flashlight, isolated on solid green background #00FF00.* | 
| `tax_auditor_mole` | **Tax Auditor Mole** | Ground Disruptor | *Isometric 2.5D pixel art of a chubby mole wearing tiny round glasses and an accounting visor, chewing on long paper receipts, isolated on solid green background #00FF00.* | 
| `bureaucrat_golem` | **HOA President Golem** | **LEVEL 1 BOSS** | *Isometric 2.5D pixel art of a bulky stone golem wearing clipboard armor and a yellow hardhat, holding a giant gavel, 90s arcade style, isolated on solid green background #00FF00.* | 

## 4. Level 2: Air Realm (Crypto Towers & Vape Clouds)

| Sprite ID | Enemy Name | Role / Behavior | Full AI Generation Prompt | 
| ----- | ----- | ----- | ----- | 
| `crypto_bat` | **Crypto Bro Bat** | Fast Flier | *Isometric 2.5D pixel art of a smarmy flying bat wearing sunglasses and holding a glowing golden crypto coin, 90s Genesis style, isolated on solid green background #00FF00.* | 
| `nft_monkey` | **Bored JPEG Ape** | Melee Brawler | *Isometric 2.5D pixel art of a smug cartoon ape wearing a party hat, thick golden chain, and pixelated sunglasses, isolated on solid green background #00FF00.* | 
| `drone_drop_shipper` | **Drop-Shipper Drone** | Ranged Aerial | *Isometric 2.5D pixel art of a buzzing quadcopter drone carrying a cardboard box labeled "OVERPRICED GADGET", isolated on solid green background #00FF00.* | 
| `hustle_grindset_gargoyle` | **5 AM Grindset Gargoyle** | Heavy Tank | *Isometric 2.5D pixel art of a stone gargoyle demon drinking a giant iced latte while doing one-handed pushups, 90s arcade style, isolated on solid green background #00FF00.* | 
| `algorithm_ghost` | **Ad-Tech Ghost** | Debuffer / Ghost | *Isometric 2.5D pixel art of a translucent blue ghost covered in pop-up advertisement banners reading "BUY NOW", isolated on solid green background #00FF00.* | 
| `vape_cloud_elemental` | **Smug Vape Cloud** | **LEVEL 2 BOSS** | *Isometric 2.5D pixel art of an angry sentient cloud monster wearing a backwards baseball cap and holding a glowing electronic vape pen, isolated on solid green background #00FF00.* | 

## 5. Level 3: Fire Realm (VC Lava Mansions)

| Sprite ID | Enemy Name | Role / Behavior | Full AI Generation Prompt | 
| ----- | ----- | ----- | ----- | 
| `venture_capitalist_flame` | **VC Flame Imp** | Fast Melee | *Isometric 2.5D pixel art of a fiery elemental imp wearing a tailored red suit and holding a briefcase leaking dollars, 90s arcade style, isolated on solid green background #00FF00.* | 
| `crunch_time_imp` | **Crunch Time Imp** | Ranged Caster | *Isometric 2.5D pixel art of a frantic red devil with glowing eyes typing rapidly on a laptop while throwing flaming bug reports, isolated on solid green background #00FF00.* | 
| `pitch_deck_dragon` | **Slide-Deck Mini-Dragon** | Area Fire Shooter | *Isometric 2.5D pixel art of a small green lizard breathing fire while holding a presentation pointer and a pie chart, isolated on solid green background #00FF00.* | 
| `downsize_executioner` | **Layoff Executioner** | Heavy Melee | *Isometric 2.5D pixel art of a fiery executioner wearing a black hood, holding a glowing pink-slip battle axe, isolated on solid green background #00FF00.* | 
| `monopoly_fire_car` | **Corporate Top-Hat Bug** | Fast Disruptor | *Isometric 2.5D pixel art of a burning top hat wearing a monocle crawling around on beetle legs, 90s Genesis style, isolated on solid green background #00FF00.* | 
| `burnout_ceo_boss` | **Burnout CEO Fire Demon** | **LEVEL 3 BOSS** | *Isometric 2.5D pixel art of a massive flaming demon wearing an unbuttoned power-suit and a gold watch, throwing burning pink slips, isolated on solid green background #00FF00.* | 

## 6. Level 4: Water Realm (Lair of The Sea Lord)

| Sprite ID | Enemy Name | Role / Behavior | Full AI Generation Prompt | 
| ----- | ----- | ----- | ----- | 
| `sea_men_grunt` | **Sea Men Grunt** | Swarm Melee | *Isometric 2.5D pixel art of a goofy, smarmy fish-man in a sailor hat and Hawaiian shirt holding a plastic squirt gun, irreverent 90s cartoon style, isolated on solid green background #00FF00.* | 
| `corporate_shark` | **Corporate Loan Shark** | Heavy Melee | *Isometric 2.5D pixel art of a literal shark walking on two legs wearing a grey suit with a calculator briefcase, isolated on solid green background #00FF00.* | 
| `oil_spill_blob` | **Deregulation Tar Blob** | Hazard Tank | *Isometric 2.5D pixel art of a slick black sludge monster wearing a gold oil company pin and an evil grin, isolated on solid green background #00FF00.* | 
| `tax_haven_crab` | **Offshore Shell Crab** | Armored Tank | *Isometric 2.5D pixel art of a giant hermit crab using a heavy steel Swiss bank vault as its shell, isolated on solid green background #00FF00.* | 
| `deep_sea_lobbyist` | **Anglerfish Lobbyist** | Ranged / Lure | *Isometric 2.5D pixel art of a creepy deep-sea anglerfish wearing a lobbyist badge, dangling a glowing golden dollar bill on its head lure, isolated on solid green background #00FF00.* | 
| `sea_lord_boss` | **The Sea Lord** | **FINAL BOSS** | *Isometric 2.5D pixel art of the Sea Lord, a bloated grotesque underwater warlord in a cheap pinstripe business suit wearing a golden crown and holding a CEO golden trident, smarmy expression, isolated on solid green background #00FF00.* | 

## 7. Weapons, Equipment & Items

| Sprite ID | Item Name | Category | Full AI Generation Prompt | 
| ----- | ----- | ----- | ----- | 
| `weapon_neon_sword` | **Neon Star-Sword** | Starting Weapon | *Isometric 16-bit pixel art of a glowing 90s magic broadsword with a neon-pink blade and star-shaped golden hilt, arcade toy style, isolated on green background #00FF00.* | 
| `weapon_water_pistol` | **Super Soaker 9000** | Ranged Weapon | *Isometric 16-bit pixel art of an oversized neon green and translucent orange plastic water blaster, 90s toy style, isolated on green background #00FF00.* | 
| `weapon_squeak_hammer` | **Squeaky Mallet** | Heavy Melee Drop | *Isometric 16-bit pixel art of a gigantic squeaking yellow foam hammer with cartoon stars around it, isolated on green background #00FF00.* | 
| `weapon_nailgun` | **Contractor Nailgun** | Fast Ranged Drop | *Isometric 16-bit pixel art of a heavy yellow industrial nailgun, 90s Sega Genesis style, isolated on green background #00FF00.* | 
| `item_energy_drink` | **RADICAL Energy Drink** | Consumable Heal | *16-bit pixel art soda can labeled "RADICAL ENERGY" with lightning bolts, vibrant 90s neon colors, isolated on green background #00FF00.* | 

## 8. Projectiles & Visual Attack Effects

| Sprite ID | Owner | Attack Effect | Full AI Generation Prompt | 
| ----- | ----- | ----- | ----- | 
| `proj_water_stream` | Carol (Super Soaker) | Water Blaster Jet | *Isometric 16-bit pixel art of a flying stream of bright neon-blue water droplets with cartoon splash effects, 90s Genesis arcade style, isolated on green background #00FF00.* | 
| `proj_steel_nail` | Carol (Nailgun) | Flying Metal Nail | *Isometric 16-bit pixel art of a sharp yellow-gold industrial nail flying with speed-motion lines, isolated on green background #00FF00.* | 
| `proj_star_slash` | Carol (Star-Sword) | Magic Wave Slash | *Isometric 16-bit pixel art of a crescent-shaped glowing neon-pink energy wave with tiny yellow sparkles, arcade visual effect, isolated on green background #00FF00.* | 
| `proj_tax_receipt` | Tax Auditor Mole | Flying Receipt Paper | *Isometric 16-bit pixel art of a long unspooling paper tax receipt flying through the air, cartoon 90s style, isolated on green background #00FF00.* | 
| `proj_megaphone_wave` | Mall Cop Mercenary | Soundwave Ring | *Isometric 16-bit pixel art of yellow concentric soundwave rings pulsing forward, 90s Genesis style, isolated on green background #00FF00.* | 
| `proj_crypto_coin` | Crypto Bro Bat | Spinning Gold Coin | *Isometric 16-bit pixel art of a spinning glowing golden crypto coin with laser sparkles, isolated on green background #00FF00.* | 
| `proj_amazon_box` | Drop-Shipper Drone | Falling Shipping Box | *Isometric 16-bit pixel art of a falling brown cardboard box with red question marks around it, isolated on green background #00FF00.* | 
| `proj_ad_popup` | Ad-Tech Ghost | Flying "BUY NOW" Banner | *Isometric 16-bit pixel art of a glitchy bright red pop-up advertisement box reading "BUY NOW!", isolated on green background #00FF00.* | 
| `proj_vape_ring` | Smug Vape Cloud (Boss) | Smoke Ring | *Isometric 16-bit pixel art of a thick purple-pink cloud of smoke forming a spinning doughnut ring, isolated on green background #00FF00.* | 
| `proj_bug_report` | Crunch Time Imp | Flaming Bug Document | *Isometric 16-bit pixel art of a burning sheet of red paper with a black beetle icon on fire, isolated on green background #00FF00.* | 
| `proj_pie_chart` | Slide-Deck Mini-Dragon | Spinning 3D Pie Chart | *Isometric 16-bit pixel art of a spinning 3D pie chart with glowing green and orange slices, isolated on green background #00FF00.* | 
| `proj_pink_slip` | Layoff Executioner / CEO | Burning Pink Slip | *Isometric 16-bit pixel art of a burning pink termination slip paper enveloped in cartoon flames, isolated on green background #00FF00.* | 
| `proj_water_squirt` | Sea Men Grunt | Toy Water Squirt | *Isometric 16-bit pixel art of three small cartoon water drops squirting forward, isolated on green background #00FF00.* | 
| `proj_dollar_lure` | Anglerfish Lobbyist | Bribe Dollar Bill | *Isometric 16-bit pixel art of a floating green dollar bill attached to a glowing fishing hook, isolated on green background #00FF00.* | 
| `proj_trident_beam` | The Sea Lord (Boss) | CEO Trident Beam | *Isometric 16-bit pixel art of a thick glowing golden energy beam shot from a trident, 90s arcade boss effect, isolated on green background #00FF00.* | 

## 9. Isometric Tilesets, Cover Objects & Hazards

| Sprite ID | Category | Description | Full AI Generation Prompt | 
| ----- | ----- | ----- | ----- | 
| `tile_earth_floor` | Floor Tile | Level 1 Floor Tile | *16-bit pixel art isometric floor tile, muddy dirt texture, 2.5D angle, seamless tileable, Sega Genesis style.* | 
| `tile_air_floor` | Floor Tile | Level 2 Floor Tile | *16-bit pixel art isometric floor tile, polished cloud platform grid, 2.5D angle, seamless tileable, Sega Genesis style.* | 
| `tile_fire_floor` | Floor Tile | Level 3 Floor Tile | *16-bit pixel art isometric floor tile, charred dark marble with red glowing lava seams, 2.5D angle, seamless tileable, Sega Genesis style.* | 
| `tile_water_floor` | Floor Tile | Level 4 Floor Tile | *16-bit pixel art isometric floor tile, wet metal grate over deep blue water, 2.5D angle, seamless tileable, Sega Genesis style.* | 
| `cover_wooden_crate` | Terrain Cover | Half Cover (Obstacle) | *16-bit pixel art isometric wooden shipping crate labeled "PROFIT", 2.5D angle, 90s cartoon style, isolated on green background #00FF00.* | 
| `cover_vending_machine` | Terrain Cover | Full Cover (Obstacle) | *16-bit pixel art isometric bright neon soda vending machine, cover terrain object, 2.5D angle, isolated on green background #00FF00.* | 
| `hazard_spikes` | Trap Hazard | Floor Hazard Tile | *16-bit pixel art isometric floor trap with cartoon steel spikes sticking up, 2.5D angle, isolated on green background #00FF00.* | 

## 10. User Interface (UI) & Screen Art

| Sprite ID | Component | Description | Full AI Generation Prompt | 
| ----- | ----- | ----- | ----- | 
| `screen_title` | Title Screen Banner | Sega Genesis style logo | *16-bit Sega Genesis splash screen title art, bold 90s radical font reading "Dungeon Crawler Carol: Lair of The Sea Lord", bright neon pink and teal, slime drips, cartoon explosions, Zombies Ate My Neighbors vibe.* | 
| `screen_victory` | Ending Victory Screen | Carol & Princess Penny | *16-bit Sega Genesis victory screen art, Carol and her pink-haired tattooed barista girlfriend Princess Penny high-fiving over a steaming cup of artisan espresso in front of a defeated Sea Lord, bold 90s radical font reading "RESCUE COMPLETE!", vibrant neon colors.* | 
| `ui_hit_chance_badge` | Tactical HUD | Hit percentage badge | *16-bit pixel art percentage indicator badge, glowing neon yellow text reading "85% HIT", Sega Genesis UI style.* | 
