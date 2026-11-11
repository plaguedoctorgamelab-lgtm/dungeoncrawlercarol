extends SceneTree
## Writes resources/weapons/*.tres and resources/enemies/*.tres from scripts/data/Roster.gd.
## Usage: godot --headless --script res://scripts/tools/generate_resources.gd

const SPRITES := "res://assets/sprites/"


func _initialize() -> void:
	var roster: GDScript = load("res://scripts/data/Roster.gd")
	var weapon_script: GDScript = load("res://scripts/resources/WeaponData.gd")
	var enemy_script: GDScript = load("res://scripts/resources/EnemyData.gd")
	var errors := 0
	for w: Dictionary in roster.WEAPONS:
		var r: Resource = weapon_script.new()
		r.weapon_id = w["id"]
		r.display_name = w["name"]
		r.damage = w["dmg"]
		r.ap_cost = w["ap"]
		r.is_ranged = w["ranged"]
		r.max_range_tiles = w["range"]
		r.projectile_texture = load(SPRITES + w["proj"] + ".png")
		r.icon = load(SPRITES + w["icon"] + ".png")
		r.description = w["desc"]
		r.projectile_tint = w["tint"]
		errors += _save(r, "res://resources/weapons/%s.tres" % w["file"])
	for e: Dictionary in roster.ENEMIES:
		var r: Resource = enemy_script.new()
		r.enemy_id = e["id"]
		r.display_name = e["name"]
		r.max_hp = e["hp"]
		r.ap_pool = 4
		r.base_damage = e["dmg"]
		r.sight_radius_tiles = e["sight"]
		r.is_ranged = e["proj"] != ""
		if e["proj"] != "":
			r.projectile_texture = load(SPRITES + e["proj"] + ".png")
		r.sprite_texture = load(SPRITES + e["id"] + ".png")
		r.role = e["role"]
		r.realm = e["realm"]
		r.is_boss = e["boss"]
		r.attack_range_tiles = e["range"]
		r.tiles_per_ap = e["speed"]
		r.damage_reduction = e["armor"]
		r.flavor_text = e["flavor"]
		if r.sprite_texture == null:
			push_error("missing sprite for " + e["id"])
			errors += 1
		errors += _save(r, "res://resources/enemies/%s.tres" % e["id"])
	print("generate_resources: %d weapons, %d enemies, %d errors" % [roster.WEAPONS.size(), roster.ENEMIES.size(), errors])
	quit(1 if errors > 0 else 0)


func _save(r: Resource, path: String) -> int:
	var err := ResourceSaver.save(r, path)
	if err != OK:
		push_error("could not save %s: %s" % [path, error_string(err)])
		return 1
	return 0
