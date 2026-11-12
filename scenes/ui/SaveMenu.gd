extends Control
## Modal save/load slot picker. `allow_save` is false on the title screen
## and follows the difficulty save rule on the overworld.

signal closed
signal loaded

var allow_save: bool = true
var _rows: VBoxContainer
var _status: Label


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 0)
	panel.position = Vector2(260, 160)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := UiKit.label("SAVE / LOAD" if allow_save else "LOAD GAME", 26, UiKit.PINK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_status = UiKit.label("", 15, UiKit.TEAL)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_status)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 8)
	box.add_child(_rows)
	var close := UiKit.button("CLOSE", 160)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(_close)
	box.add_child(close)
	if allow_save and not GameState.can_save_now():
		_status.text = "Can't save here. " + GameState.save_rule_text()
	elif allow_save:
		_status.text = GameState.save_rule_text()
	_refresh()


func _refresh() -> void:
	for c in _rows.get_children():
		c.queue_free()
	for slot in range(1, SaveManager.SLOT_COUNT + 1):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var l := UiKit.label(SaveManager.slot_summary(slot), 15)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		if allow_save:
			var s := UiKit.button("SAVE", 90)
			s.disabled = not GameState.can_save_now()
			s.pressed.connect(_save.bind(slot))
			row.add_child(s)
		var ld := UiKit.button("LOAD", 90)
		ld.disabled = not SaveManager.has_save(slot)
		ld.pressed.connect(_load.bind(slot))
		row.add_child(ld)
		_rows.add_child(row)


func _save(slot: int) -> void:
	if SaveManager.save_game(slot):
		_status.text = "Saved to slot %d. Totally tubular." % slot
	else:
		_status.text = "Save failed!"
	_refresh()


func _load(slot: int) -> void:
	if SaveManager.load_game(slot):
		loaded.emit()
		GameState.overworld_banner = "Loaded slot %d - %s" % [slot, Roster.REALM_NAMES[GameState.realm]]
		get_tree().change_scene_to_file("res://scenes/overworld/NodeMap.tscn")
	else:
		_status.text = "That slot is empty or corrupt."


func _close() -> void:
	closed.emit()
	queue_free()
