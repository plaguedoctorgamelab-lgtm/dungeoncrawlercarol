class_name Roster
extends RefCounted
## Single source of truth for the GDD 4.5 roster and the weapon list.
## scripts/tools/generate_resources.gd turns these tables into .tres files.

const ENEMIES: Array[Dictionary] = [
	# ---- Level 1: Earth ----
	{"id": "earth_slime_suit", "name": "Landlord Slime", "role": "Melee Swarm", "realm": 0, "hp": 35.0, "dmg": 10.0, "sight": 6, "proj": "", "range": 1, "speed": 1, "armor": 0.0, "boss": false, "flavor": "Your rent is due. Also, it went up."},
	{"id": "lawn_mower_drone", "name": "Karen's Turbo Mower", "role": "Fast Charger", "realm": 0, "hp": 45.0, "dmg": 14.0, "sight": 7, "proj": "", "range": 1, "speed": 2, "armor": 0.0, "boss": false, "flavor": "Would like to speak to your manager at 40 mph."},
	{"id": "clipboard_intern", "name": "Unpaid Intern Zombie", "role": "Swarm Melee", "realm": 0, "hp": 25.0, "dmg": 8.0, "sight": 5, "proj": "", "range": 1, "speed": 1, "armor": 0.0, "boss": false, "flavor": "Working for exposure. And brains."},
	{"id": "gated_community_guard", "name": "Mall Cop Mercenary", "role": "Ranged Shooter", "realm": 0, "hp": 40.0, "dmg": 12.0, "sight": 8, "proj": "proj_megaphone_wave", "range": 5, "speed": 1, "armor": 0.0, "boss": false, "flavor": "Ma'am. MA'AM. This is a private sidewalk."},
	{"id": "tax_auditor_mole", "name": "Tax Auditor Mole", "role": "Ground Disruptor", "realm": 0, "hp": 30.0, "dmg": 9.0, "sight": 6, "proj": "proj_tax_receipt", "range": 4, "speed": 1, "armor": 0.0, "boss": false, "flavor": "Itemizes your pain. Deducts your joy."},
	{"id": "bureaucrat_golem", "name": "HOA President Golem", "role": "LEVEL 1 BOSS", "realm": 0, "hp": 160.0, "dmg": 24.0, "sight": 8, "proj": "", "range": 1, "speed": 1, "armor": 0.0, "boss": true, "flavor": "Your mailbox is two inches too tall. FINED."},
	# ---- Level 2: Air ----
	{"id": "crypto_bat", "name": "Crypto Bro Bat", "role": "Fast Flier", "realm": 1, "hp": 30.0, "dmg": 11.0, "sight": 7, "proj": "proj_crypto_coin", "range": 4, "speed": 2, "armor": 0.0, "boss": false, "flavor": "Have you heard about my coin? It's going to the moon."},
	{"id": "nft_monkey", "name": "Bored JPEG Ape", "role": "Melee Brawler", "realm": 1, "hp": 50.0, "dmg": 15.0, "sight": 6, "proj": "", "range": 1, "speed": 1, "armor": 0.0, "boss": false, "flavor": "Right-click this, nerd."},
	{"id": "drone_drop_shipper", "name": "Drop-Shipper Drone", "role": "Ranged Aerial", "realm": 1, "hp": 35.0, "dmg": 13.0, "sight": 8, "proj": "proj_amazon_box", "range": 5, "speed": 1, "armor": 0.0, "boss": false, "flavor": "Your package has arrived. On your head."},
	{"id": "hustle_grindset_gargoyle", "name": "5 AM Grindset Gargoyle", "role": "Heavy Tank", "realm": 1, "hp": 60.0, "dmg": 18.0, "sight": 5, "proj": "", "range": 1, "speed": 1, "armor": 0.15, "boss": false, "flavor": "Sleep is for people without a podcast."},
	{"id": "algorithm_ghost", "name": "Ad-Tech Ghost", "role": "Debuffer / Ghost", "realm": 1, "hp": 40.0, "dmg": 10.0, "sight": 7, "proj": "proj_ad_popup", "range": 5, "speed": 1, "armor": 0.0, "boss": false, "flavor": "We value your privacy. (We do not.)"},
	{"id": "vape_cloud_elemental", "name": "Smug Vape Cloud", "role": "LEVEL 2 BOSS", "realm": 1, "hp": 180.0, "dmg": 26.0, "sight": 9, "proj": "proj_vape_ring", "range": 6, "speed": 1, "armor": 0.0, "boss": true, "flavor": "*exhales a blue-raspberry cloud the size of a bus*"},
	# ---- Level 3: Fire ----
	{"id": "venture_capitalist_flame", "name": "VC Flame Imp", "role": "Fast Melee", "realm": 2, "hp": 40.0, "dmg": 14.0, "sight": 7, "proj": "", "range": 1, "speed": 2, "armor": 0.0, "boss": false, "flavor": "Wants forty percent equity in your face."},
	{"id": "crunch_time_imp", "name": "Crunch Time Imp", "role": "Ranged Caster", "realm": 2, "hp": 45.0, "dmg": 16.0, "sight": 8, "proj": "proj_bug_report", "range": 5, "speed": 1, "armor": 0.0, "boss": false, "flavor": "Ship it Friday. Fix it never."},
	{"id": "pitch_deck_dragon", "name": "Slide-Deck Mini-Dragon", "role": "Area Fire Shooter", "realm": 2, "hp": 55.0, "dmg": 18.0, "sight": 6, "proj": "proj_pie_chart", "range": 5, "speed": 1, "armor": 0.0, "boss": false, "flavor": "Next slide. NEXT SLIDE."},
	{"id": "downsize_executioner", "name": "Layoff Executioner", "role": "Heavy Melee", "realm": 2, "hp": 75.0, "dmg": 22.0, "sight": 5, "proj": "", "range": 1, "speed": 1, "armor": 0.1, "boss": false, "flavor": "We're a family. Anyway, you're fired."},
	{"id": "monopoly_fire_car", "name": "Corporate Top-Hat Bug", "role": "Fast Disruptor", "realm": 2, "hp": 50.0, "dmg": 15.0, "sight": 7, "proj": "", "range": 1, "speed": 2, "armor": 0.0, "boss": false, "flavor": "Do not pass GO. Do not collect anything."},
	{"id": "burnout_ceo_boss", "name": "Burnout CEO Fire Demon", "role": "LEVEL 3 BOSS", "realm": 2, "hp": 220.0, "dmg": 32.0, "sight": 9, "proj": "proj_pink_slip", "range": 6, "speed": 1, "armor": 0.0, "boss": true, "flavor": "Record quarter! Everybody's fired!"},
	# ---- Level 4: Water ----
	{"id": "sea_men_grunt", "name": "Sea Men Grunt", "role": "Swarm Melee", "realm": 3, "hp": 50.0, "dmg": 16.0, "sight": 7, "proj": "proj_water_squirt", "range": 2, "speed": 1, "armor": 0.0, "boss": false, "flavor": "Aye aye, middle management!"},
	{"id": "corporate_shark", "name": "Corporate Loan Shark", "role": "Heavy Melee", "realm": 3, "hp": 80.0, "dmg": 24.0, "sight": 6, "proj": "", "range": 1, "speed": 1, "armor": 0.1, "boss": false, "flavor": "Low, low APR of 400 percent."},
	{"id": "oil_spill_blob", "name": "Deregulation Tar Blob", "role": "Hazard Tank", "realm": 3, "hp": 90.0, "dmg": 20.0, "sight": 5, "proj": "", "range": 1, "speed": 1, "armor": 0.2, "boss": false, "flavor": "Rules are just suggestions with lawyers."},
	{"id": "tax_haven_crab", "name": "Offshore Shell Crab", "role": "Armored Tank", "realm": 3, "hp": 70.0, "dmg": 18.0, "sight": 6, "proj": "", "range": 1, "speed": 1, "armor": 0.3, "boss": false, "flavor": "My assets are in my shell. Literally."},
	{"id": "deep_sea_lobbyist", "name": "Anglerfish Lobbyist", "role": "Ranged / Lure", "realm": 3, "hp": 60.0, "dmg": 22.0, "sight": 8, "proj": "proj_dollar_lure", "range": 5, "speed": 1, "armor": 0.0, "boss": false, "flavor": "Just a little campaign contribution..."},
	{"id": "sea_lord_boss", "name": "The Sea Lord", "role": "FINAL BOSS", "realm": 3, "hp": 300.0, "dmg": 40.0, "sight": 10, "proj": "proj_trident_beam", "range": 6, "speed": 1, "armor": 0.0, "boss": true, "flavor": "Artisan espresso is a threat to shareholder value!"},
]

const WEAPONS: Array[Dictionary] = [
	{"id": "neon_sword", "file": "NeonSword", "name": "Neon Star-Sword", "dmg": 25.0, "ap": 2, "ranged": false, "range": 1, "proj": "proj_star_slash", "icon": "weapon_neon_sword", "tint": Color(1, 1, 1), "desc": "Starting weapon. A magic star-blade that hums at a radical frequency."},
	{"id": "super_soaker", "file": "SuperSoaker", "name": "Super Soaker 9000", "dmg": 26.0, "ap": 3, "ranged": true, "range": 5, "proj": "proj_water_stream", "icon": "weapon_water_pistol", "tint": Color(1, 1, 1), "desc": "Pressurized neon water. Ruins suits, ruins days."},
	{"id": "squeak_hammer", "file": "SqueakHammer", "name": "Squeaky Mallet", "dmg": 36.0, "ap": 2, "ranged": false, "range": 1, "proj": "proj_star_slash", "icon": "weapon_squeak_hammer", "tint": Color(1, 0.95, 0.3), "desc": "Gigantic foam mallet. SQUEAK. Heavy melee drop."},
	{"id": "nailgun", "file": "Nailgun", "name": "Contractor Nailgun", "dmg": 15.0, "ap": 2, "ranged": true, "range": 7, "proj": "proj_steel_nail", "icon": "weapon_nailgun", "tint": Color(1, 1, 1), "desc": "Fast, long-range, union-certified."},
]

const STARTING_WEAPONS: Array[String] = ["neon_sword", "super_soaker"]
const DROP_WEAPONS: Array[String] = ["squeak_hammer", "nailgun"]

## Realm layout helpers.
const REALM_NAMES: Array[String] = ["Earth Realm", "Air Realm", "Fire Realm", "Water Realm"]
const REALM_SUBTITLES: Array[String] = [
	"Corporate Suburbs & HOA Dungeons",
	"Cloud-High Vaping Towers & Crypto Mines",
	"Venture Capitalist Lava Mansions",
	"Lair of The Sea Lord: Submerged Underwater Boardroom",
]
const REALM_FLOORS: Array[String] = ["tile_earth_floor", "tile_air_floor", "tile_fire_floor", "tile_water_floor"]
const REALM_COLORS: Array[Color] = [Color("#2a1a10"), Color("#16203d"), Color("#2e0b0b"), Color("#04182c")]
const REALM_ACCENTS: Array[Color] = [Color("#9cff57"), Color("#7fe7ff"), Color("#ff7a1a"), Color("#00f0ff")]


static func enemies_for_realm(realm: int, bosses: bool) -> Array[String]:
	var out: Array[String] = []
	for e in ENEMIES:
		if int(e["realm"]) == realm and bool(e["boss"]) == bosses:
			out.append(String(e["id"]))
	return out


static func boss_for_realm(realm: int) -> String:
	return enemies_for_realm(realm, true)[0]


static func weapon_file(weapon_id: String) -> String:
	for w in WEAPONS:
		if w["id"] == weapon_id:
			return "res://resources/weapons/%s.tres" % w["file"]
	return ""


static func enemy_file(enemy_id: String) -> String:
	return "res://resources/enemies/%s.tres" % enemy_id


static func weapon_name(weapon_id: String) -> String:
	for w in WEAPONS:
		if w["id"] == weapon_id:
			return String(w["name"])
	return weapon_id
