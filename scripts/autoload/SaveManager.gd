extends Node
## JSON save system. Slot 1 is user://savegame.json (GDD); slots 2-3 add a suffix.

const SLOT_COUNT := 3

## Tests point this at a throwaway folder.
var base_dir: String = "user://"


func slot_path(slot: int) -> String:
	if slot <= 1:
		return base_dir.path_join("savegame.json")
	return base_dir.path_join("savegame_%d.json" % slot)


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func has_any_save() -> bool:
	for i in range(1, SLOT_COUNT + 1):
		if has_save(i):
			return true
	return false


func save_game(slot: int) -> bool:
	var f := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: cannot write %s (%s)" % [slot_path(slot), error_string(FileAccess.get_open_error())])
		return false
	f.store_string(JSON.stringify(GameState.to_dict(), "\t"))
	f.close()
	GameState.active_slot = slot
	return true


func read_slot(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}
	var text := FileAccess.get_file_as_string(slot_path(slot))
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager: slot %d is corrupt" % slot)
		return {}
	return parsed


func load_game(slot: int) -> bool:
	var d := read_slot(slot)
	if d.is_empty():
		return false
	GameState.from_dict(d)
	GameState.active_slot = slot
	return true


## EXTREME permadeath: delete the save file for the slot.
func wipe_save(slot: int) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(slot)))


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
