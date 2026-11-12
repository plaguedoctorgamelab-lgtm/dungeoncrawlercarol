extends Node
## JSON save system. Slot 1 is user://savegame.json (GDD); slots 2-3 add a suffix.
## Writes are atomic: the new save goes to <slot>.tmp, the old one is kept as <slot>.bak
## until the swap succeeds, and reads fall back to the .bak if the main file is damaged.

const SLOT_COUNT := 3

## Tests point this at a throwaway folder.
var base_dir: String = "user://"
## Set when a load found an EXTREME run that was quit mid-battle (it gets wiped instead).
var last_load_was_flee: bool = false


func slot_path(slot: int) -> String:
	if slot <= 1:
		return base_dir.path_join("savegame.json")
	return base_dir.path_join("savegame_%d.json" % slot)


func _abs(path: String) -> String:
	return ProjectSettings.globalize_path(path)


func has_save(slot: int) -> bool:
	var p := slot_path(slot)
	return FileAccess.file_exists(p) or FileAccess.file_exists(p + ".bak")


func has_any_save() -> bool:
	for i in range(1, SLOT_COUNT + 1):
		if has_save(i):
			return true
	return false


func save_game(slot: int) -> bool:
	var path := slot_path(slot)
	var tmp := path + ".tmp"
	var bak := path + ".bak"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: cannot write %s (%s)" % [tmp, error_string(FileAccess.get_open_error())])
		return false
	f.store_string(JSON.stringify(GameState.to_dict(), "\t"))
	f.close()
	if FileAccess.file_exists(bak):
		DirAccess.remove_absolute(_abs(bak))
	if FileAccess.file_exists(path):
		DirAccess.rename_absolute(_abs(path), _abs(bak))
	var err := DirAccess.rename_absolute(_abs(tmp), _abs(path))
	if err != OK:
		push_error("SaveManager: could not finalize %s (%s)" % [path, error_string(err)])
		return false
	if FileAccess.file_exists(bak):
		DirAccess.remove_absolute(_abs(bak))
	GameState.active_slot = slot
	return true


func _parse(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY or not (parsed as Dictionary).has("map_data"):
		return {}
	return parsed


func read_slot(slot: int) -> Dictionary:
	var path := slot_path(slot)
	var d := _parse(path)
	if d.is_empty() and FileAccess.file_exists(path + ".bak"):
		push_warning("SaveManager: slot %d main file damaged, using backup" % slot)
		d = _parse(path + ".bak")
	elif d.is_empty() and FileAccess.file_exists(path):
		push_warning("SaveManager: slot %d is corrupt" % slot)
	return d


## Loads a slot. An EXTREME save that was left mid-battle counts as fleeing: every slot of
## that run is wiped and a fresh run starts (last_load_was_flee tells the caller).
func load_game(slot: int) -> bool:
	last_load_was_flee = false
	var d := read_slot(slot)
	if d.is_empty():
		return false
	GameState.from_dict(d)
	GameState.active_slot = slot
	if GameState.is_permadeath() and GameState.battle_in_progress >= 0:
		last_load_was_flee = true
		wipe_run(GameState.run_seed)
		GameState.new_run(GameState.difficulty)
		GameState.overworld_banner = "You quit in the middle of an EXTREME fight. That counts as a PERMADEATH - back to Level 1!"
	return true


## Deletes one slot (main file, backup and any half-written temp file).
func wipe_save(slot: int) -> void:
	var path := slot_path(slot)
	for p in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(_abs(p))


## EXTREME permadeath: deletes every slot that holds the given run (copies included).
func wipe_run(seed_value: int) -> int:
	var wiped := 0
	for i in range(1, SLOT_COUNT + 1):
		var d := read_slot(i)
		if not d.is_empty() and int(d.get("run_seed", -1)) == seed_value:
			wipe_save(i)
			wiped += 1
	return wiped


func slot_summary(slot: int) -> String:
	var d := read_slot(slot)
	if d.is_empty():
		return "Slot %d - empty" % slot
	var r := int(d.get("realm", 0))
	var diff_i := int(d.get("difficulty", 1))
	return "Slot %d - %s | %s | HP %d | %s" % [
		slot, Roster.REALM_NAMES[clampi(r, 0, 3)], GameState.DIFFICULTY_NAMES[clampi(diff_i, 0, 3)],
		int(float(d.get("carol_hp", 0))), String(d.get("saved_at", "")),
	]
