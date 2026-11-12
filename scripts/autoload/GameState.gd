extends Node
## Run state for the current playthrough (difficulty, realm, Carol's stats, overworld map).

enum Difficulty { EASY, MEDIUM, HARD, EXTREME }

const DIFFICULTY_NAMES: Array[String] = ["Easy", "Medium", "Hard", "EXTREME!!!!!!"]
## V2 difficulty matrix. "save" = when the game auto-saves: "room" (start of every room) or "level".
const DIFFICULTY_TABLE: Array[Dictionary] = [
	{"hp": 0.8, "dmg": 0.8, "sight": 8, "save": "room", "permadeath": false},
	{"hp": 1.0, "dmg": 1.0, "sight": 6, "save": "room", "permadeath": false},
	{"hp": 1.3, "dmg": 1.3, "sight": 5, "save": "level", "permadeath": false},
	{"hp": 1.6, "dmg": 1.6, "sight": 3, "save": "level", "permadeath": true},
]
const DIFFICULTY_BLURBS: Array[String] = [
	"Enemies x0.8 HP/DMG. Wide sight (8 tiles). Auto-saves at the start of every room.",
	"Enemies x1.0 HP/DMG. Standard sight (6 tiles). Auto-saves at the start of every room.",
	"Enemies x1.3 HP/DMG. Reduced sight (5 tiles). Auto-saves only at the start of each level.",
	"Enemies x1.6 HP/DMG. Tight fog (3 tiles). FULL PERMADEATH: dying deletes your save and resets to Level 1.",
]

const CAROL_MAX_HP := 100.0
const CAROL_AP := 4
const DRINK_HEAL := 35.0
## Consumables / specials cost 2-3 AP (V2 spec). The Energy Drink costs 2.
const DRINK_AP := 2
const VICTORY_HEAL := 15.0
const REALM_COUNT := 4

var difficulty: int = Difficulty.MEDIUM
var realm: int = 0
var carol_hp: float = CAROL_MAX_HP
var weapons: Array[String] = []
var equipped_weapon: String = "neon_sword"
var energy_drinks: int = 1
## Overworld map for the current realm (see OverworldGenerator).
var map_data: Dictionary = {}
## Last completed node id (-1 = realm start, no node chosen yet).
var current_node: int = -1
## Node ids already played this realm.
var visited: Array[int] = []
## Node being fought in the tactical scene.
var pending_node: int = -1
var active_slot: int = 1
var battles_won: int = 0
var enemies_defeated: int = 0
var run_seed: int = 0
## One-shot banner shown when the overworld opens.
var overworld_banner: String = ""
## Weapon handed out by start_realm (shown in the realm banner).
var realm_gift: String = ""

var rng := RandomNumberGenerator.new()

var _weapon_cache: Dictionary = {}
var _enemy_cache: Dictionary = {}


func _ready() -> void:
	rng.randomize()
	process_mode = Node.PROCESS_MODE_ALWAYS


## F11 toggles fullscreen / windowed from any screen.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		toggle_fullscreen()
		get_viewport().set_input_as_handled()


func toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func new_run(diff: int, seed_value: int = -1) -> void:
	difficulty = clampi(diff, 0, 3)
	realm = 0
	carol_hp = CAROL_MAX_HP
	weapons.assign(Roster.STARTING_WEAPONS)
	equipped_weapon = weapons[0]
	energy_drinks = 1
	battles_won = 0
	enemies_defeated = 0
	run_seed = seed_value if seed_value >= 0 else int(Time.get_unix_time_from_system()) ^ rng.randi()
	rng.seed = run_seed
	start_realm(0)


func start_realm(index: int) -> void:
	realm = index
	carol_hp = CAROL_MAX_HP
	current_node = -1
	pending_node = -1
	visited.clear()
	map_data = OverworldGenerator.generate(run_seed + index * 7919, index)
	# The Super Soaker 9000 is guaranteed before the Fire level starts.
	realm_gift = ""
	if index >= Roster.SOAKER_REALM and give_weapon("super_soaker"):
		realm_gift = "Found the SUPER SOAKER 9000 high-damage water blaster!"


## True when the player is standing at the very start of a realm map.
func at_realm_start() -> bool:
	return current_node == -1 and visited.is_empty()


func diff() -> Dictionary:
	return DIFFICULTY_TABLE[difficulty]


func enemy_hp_scale() -> float:
	return float(diff()["hp"])


func enemy_dmg_scale() -> float:
	return float(diff()["dmg"])


func sight_radius() -> int:
	return int(diff()["sight"])


func is_permadeath() -> bool:
	return bool(diff()["permadeath"])


## Carol gets a little stronger each realm so later fights stay winnable.
func carol_damage_mult() -> float:
	return 1.0 + 0.2 * realm


## Manual saves follow the same rule as auto-saves.
func can_save_now() -> bool:
	if diff()["save"] == "room":
		return true
	return at_realm_start()


func save_rule_text() -> String:
	if diff()["save"] == "room":
		return "Auto-saves at the start of every room."
	if is_permadeath():
		return "Auto-saves only at level start. PERMADEATH is on."
	return "Auto-saves only at the start of each level."


## Called when a room starts and when a level starts. Writes the active slot when the
## difficulty allows it. Returns true if a save was written.
func autosave(at_level_start: bool) -> bool:
	if map_data.is_empty():
		return false
	if diff()["save"] == "level" and not at_level_start:
		return false
	var mgr := get_node_or_null("/root/SaveManager")
	return mgr != null and mgr.save_game(active_slot)


# ---------------------------------------------------------------- data access

func weapon_data(id: String) -> WeaponData:
	if not _weapon_cache.has(id):
		var path := Roster.weapon_file(id)
		_weapon_cache[id] = load(path) if path != "" and ResourceLoader.exists(path) else null
	return _weapon_cache[id]


func enemy_data(id: String) -> EnemyData:
	if not _enemy_cache.has(id):
		var path := Roster.enemy_file(id)
		_enemy_cache[id] = load(path) if ResourceLoader.exists(path) else null
	return _enemy_cache[id]


func current_weapon() -> WeaponData:
	return weapon_data(equipped_weapon)


func heal(amount: float) -> void:
	carol_hp = minf(CAROL_MAX_HP, carol_hp + amount)


func give_weapon(id: String) -> bool:
	if weapons.has(id):
		return false
	weapons.append(id)
	return true


# ---------------------------------------------------------------- overworld progress

func available_nodes() -> Array[int]:
	var out: Array[int] = []
	if map_data.is_empty():
		return out
	if current_node == -1:
		for n in map_data["nodes"]:
			if int(n["layer"]) == 0:
				out.append(int(n["id"]))
	else:
		for e in map_data["nodes"][current_node]["edges"]:
			out.append(int(e))
	return out


func complete_node(id: int) -> void:
	current_node = id
	if not visited.has(id):
		visited.append(id)
	pending_node = -1


func node_type(id: int) -> String:
	return String(map_data["nodes"][id]["type"])


func is_boss_node(id: int) -> bool:
	return id == int(map_data.get("boss_id", -1))


# ---------------------------------------------------------------- save data

func to_dict() -> Dictionary:
	return {
		"version": 2,
		"difficulty": difficulty,
		"realm": realm,
		"carol_hp": carol_hp,
		"weapons": weapons.duplicate(),
		"equipped_weapon": equipped_weapon,
		"energy_drinks": energy_drinks,
		"map_data": map_data,
		"current_node": current_node,
		"visited": visited.duplicate(),
		"battles_won": battles_won,
		"enemies_defeated": enemies_defeated,
		"run_seed": run_seed,
		"saved_at": Time.get_datetime_string_from_system(false, true),
	}


func from_dict(d: Dictionary) -> void:
	difficulty = int(d.get("difficulty", Difficulty.MEDIUM))
	realm = int(d.get("realm", 0))
	carol_hp = float(d.get("carol_hp", CAROL_MAX_HP))
	weapons.clear()
	for w in d.get("weapons", Roster.STARTING_WEAPONS):
		weapons.append(String(w))
	equipped_weapon = String(d.get("equipped_weapon", weapons[0]))
	energy_drinks = int(d.get("energy_drinks", 0))
	map_data = _normalize_map(d.get("map_data", {}))
	current_node = int(d.get("current_node", -1))
	visited.clear()
	for v in d.get("visited", []):
		visited.append(int(v))
	battles_won = int(d.get("battles_won", 0))
	enemies_defeated = int(d.get("enemies_defeated", 0))
	run_seed = int(d.get("run_seed", 0))
	pending_node = -1


## JSON turns every number into a float; convert ids back to ints.
func _normalize_map(m: Dictionary) -> Dictionary:
	if m.is_empty():
		return m
	var out := {"boss_id": int(m["boss_id"]), "layer_count": int(m["layer_count"]), "realm": int(m.get("realm", realm)), "nodes": []}
	for n in m["nodes"]:
		var edges: Array = []
		for e in n["edges"]:
			edges.append(int(e))
		out["nodes"].append({
			"id": int(n["id"]), "layer": int(n["layer"]), "lane": float(n["lane"]),
			"type": String(n["type"]), "edges": edges,
		})
	return out
