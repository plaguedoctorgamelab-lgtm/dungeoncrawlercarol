extends Node
## Run state for the current playthrough (difficulty, realm, Carol's stats, overworld map).

enum Difficulty { EASY, MEDIUM, HARD, EXTREME }

const DIFFICULTY_NAMES: Array[String] = ["Easy", "Medium", "Hard", "EXTREME!!!!!!"]
## GDD 4.6 difficulty matrix.
const DIFFICULTY_TABLE: Array[Dictionary] = [
	{"hp": 0.8, "dmg": 0.8, "sight": 8, "save": "node", "permadeath": false},
	{"hp": 1.0, "dmg": 1.0, "sight": 6, "save": "node", "permadeath": false},
	{"hp": 1.25, "dmg": 1.25, "sight": 5, "save": "realm", "permadeath": false},
	{"hp": 1.5, "dmg": 1.5, "sight": 4, "save": "realm", "permadeath": true},
]
const DIFFICULTY_BLURBS: Array[String] = [
	"Enemies x0.8 HP/DMG. Sight 8 tiles. Save at every node.",
	"Enemies x1.0 HP/DMG. Sight 6 tiles. Save at every node.",
	"Enemies x1.25 HP/DMG. Sight 5 tiles. Save only at the start of each realm.",
	"Enemies x1.5 HP/DMG. Sight 4 tiles. FULL PERMADEATH: dying wipes your save and resets to Level 1.",
]

const CAROL_MAX_HP := 100.0
const CAROL_AP := 4
const DRINK_HEAL := 35.0
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

var rng := RandomNumberGenerator.new()

var _weapon_cache: Dictionary = {}
var _enemy_cache: Dictionary = {}


func _ready() -> void:
	rng.randomize()


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


func can_save_now() -> bool:
	if diff()["save"] == "node":
		return true
	return at_realm_start()


func save_rule_text() -> String:
	match String(diff()["save"]):
		"node":
			return "Saving allowed at the start of every node."
		_:
			if is_permadeath():
				return "Saving only at realm start. PERMADEATH is on."
			return "Saving only at the start of each realm."


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
