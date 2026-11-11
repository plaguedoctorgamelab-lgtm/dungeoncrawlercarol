extends Control
## Overworld node map for the current realm.

const NODE_BUTTON := preload("res://scenes/overworld/NodeButton.tscn")
const SAVE_MENU := preload("res://scenes/ui/SaveMenu.tscn")
const MAP_RECT := Rect2(80, 150, 1120, 400)

const HAZARDS: Array[Array] = [
	["HOA Lawn Inspection", "A clipboard-wielding inspector measures your grass with a micrometer."],
	["Crypto Rug Pull", "The floor was an NFT. Someone sold it out from under you."],
	["Mandatory Fun Team-Building", "A trust fall with a VC imp. He does not catch you."],
	["Riptide of Red Tape", "A current of unfiled paperwork tries to drag you under."],
]

var _buttons: Dictionary = {}
var _hp_bar: ProgressBar
var _stats: Label
var _message: Label
var _popup: PanelContainer
var _save_btn: Button


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if GameState.map_data.is_empty():
		GameState.new_run(GameState.difficulty)
	_build_ui()
	refresh()
	if GameState.overworld_banner != "":
		show_message(GameState.overworld_banner)
		GameState.overworld_banner = ""


func _build_ui() -> void:
	var realm := GameState.realm
	var header := VBoxContainer.new()
	header.position = Vector2(24, 12)
	add_child(header)
	header.add_child(UiKit.label("LEVEL %d: %s" % [realm + 1, Roster.REALM_NAMES[realm].to_upper()], 30, Roster.REALM_ACCENTS[realm]))
	header.add_child(UiKit.label(Roster.REALM_SUBTITLES[realm], 17, Color("#d8c8ff")))

	var portrait := UiKit.texture_rect(UiKit.sprite("carol_portrait"), Vector2(84, 84))
	portrait.position = Vector2(1180, 8)
	add_child(portrait)
	var stat_box := VBoxContainer.new()
	stat_box.position = Vector2(860, 12)
	stat_box.custom_minimum_size = Vector2(310, 0)
	add_child(stat_box)
	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(310, 26)
	_hp_bar.max_value = GameState.CAROL_MAX_HP
	_hp_bar.show_percentage = false
	stat_box.add_child(_hp_bar)
	_stats = UiKit.label("", 15)
	stat_box.add_child(_stats)

	var footer := HBoxContainer.new()
	footer.position = Vector2(24, 650)
	footer.add_theme_constant_override("separation", 12)
	add_child(footer)
	_save_btn = UiKit.button("SAVE / LOAD", 170)
	_save_btn.pressed.connect(_open_save_menu)
	footer.add_child(_save_btn)
	var title_btn := UiKit.button("TITLE SCREEN", 170)
	title_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn"))
	footer.add_child(title_btn)
	_message = UiKit.label("", 18, UiKit.YELLOW)
	_message.custom_minimum_size = Vector2(820, 40)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(_message)

	var legend := UiKit.label("Pick a glowing node. FIGHT = tactical battle, HAZARD = risky event, CACHE = guaranteed loot, BOSS = clears the realm.", 14, Color("#bfaee6"))
	legend.position = Vector2(24, 612)
	add_child(legend)


func _draw() -> void:
	var realm := GameState.realm
	draw_rect(Rect2(Vector2.ZERO, size), Roster.REALM_COLORS[realm])
	# Scanline-ish stripes for the 16-bit vibe.
	for y in range(0, int(size.y), 6):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0, 0, 0, 0.12), 2.0)
	if GameState.map_data.is_empty():
		return
	var avail := GameState.available_nodes()
	for n in GameState.map_data["nodes"]:
		var a := node_center(int(n["id"]))
		for e in n["edges"]:
			var b := node_center(int(e))
			var col := Color(1, 1, 1, 0.22)
			if int(n["id"]) == GameState.current_node and avail.has(int(e)):
				col = UiKit.YELLOW
			elif GameState.visited.has(int(n["id"])) and GameState.visited.has(int(e)):
				col = Color(UiKit.TEAL, 0.8)
			_dashed(a, b, col)


func _dashed(a: Vector2, b: Vector2, col: Color) -> void:
	var length := a.distance_to(b)
	var dir := (b - a) / maxf(length, 1.0)
	var t := 0.0
	while t < length:
		draw_line(a + dir * t, a + dir * minf(t + 10.0, length), Color.BLACK, 6.0)
		draw_line(a + dir * t, a + dir * minf(t + 10.0, length), col, 3.0)
		t += 16.0


func node_center(id: int) -> Vector2:
	var n: Dictionary = GameState.map_data["nodes"][id]
	var layers := maxi(2, int(GameState.map_data["layer_count"]))
	var x := MAP_RECT.position.x + float(n["layer"]) / (layers - 1) * MAP_RECT.size.x
	var y := MAP_RECT.position.y + float(n["lane"]) * MAP_RECT.size.y
	return Vector2(x, y)


func refresh() -> void:
	for b in _buttons.values():
		b.queue_free()
	_buttons.clear()
	var avail := GameState.available_nodes()
	for n in GameState.map_data["nodes"]:
		var id := int(n["id"])
		var state := "locked"
		if id == GameState.current_node:
			state = "current"
		elif avail.has(id):
			state = "available"
		elif GameState.visited.has(id):
			state = "visited"
		var btn: Button = NODE_BUTTON.instantiate()
		add_child(btn)
		btn.setup(n, GameState.realm, state)
		btn.position = node_center(id) - btn.size / 2.0
		btn.chosen.connect(choose_node)
		_buttons[id] = btn
	_hp_bar.value = GameState.carol_hp
	UiKit.set_bar_color(_hp_bar, UiKit.GREEN if GameState.carol_hp > 40 else UiKit.RED)
	var weapon_names: Array[String] = []
	for w in GameState.weapons:
		weapon_names.append(Roster.weapon_name(w))
	_stats.text = "Carol HP %d/%d   Energy Drinks: %d\nWeapons: %s\nDifficulty: %s   Node %d/%d" % [
		int(GameState.carol_hp), int(GameState.CAROL_MAX_HP), GameState.energy_drinks,
		", ".join(weapon_names), GameState.DIFFICULTY_NAMES[GameState.difficulty],
		GameState.visited.size(), GameState.map_data["nodes"].size()]
	_save_btn.text = "SAVE / LOAD" if GameState.can_save_now() else "LOAD"
	queue_redraw()


func show_message(text: String) -> void:
	_message.text = text


## Entry point for both clicks and tests.
func choose_node(id: int) -> void:
	if _popup != null or not GameState.available_nodes().has(id):
		return
	match GameState.node_type(id):
		"combat", "boss":
			GameState.pending_node = id
			get_tree().change_scene_to_file("res://scenes/tactical/TacticalBattle.tscn")
		"hazard":
			_resolve_hazard(id)
		"supply":
			_resolve_supply(id)


func _resolve_hazard(id: int) -> void:
	var rng := GameState.rng
	var h: Array = HAZARDS[GameState.realm % HAZARDS.size()]
	var roll := rng.randf()
	var outcome := ""
	GameState.complete_node(id)
	if roll < 0.4:
		var dmg := float(rng.randi_range(8, 18)) * GameState.enemy_dmg_scale()
		GameState.carol_hp = maxf(1.0, GameState.carol_hp - dmg)
		outcome = "Ouch! Carol loses %d HP." % int(dmg)
	elif roll < 0.75:
		GameState.energy_drinks += 1
		outcome = "Carol finds a RADICAL Energy Drink in the chaos! (+1 drink)"
	else:
		var added := _add_shortcut(id)
		outcome = "SHORTCUT! Carol spots a secret path %s." % ("further ahead" if added > 0 else "...that loops back. Bummer")
	refresh()
	_show_popup(h[0], "%s\n\n%s" % [h[1], outcome], UiKit.sprite("hazard_spikes"))


## Links the node to every node two layers further on.
func _add_shortcut(id: int) -> int:
	var nodes: Array = GameState.map_data["nodes"]
	var layer := int(nodes[id]["layer"])
	var added := 0
	if id == int(GameState.map_data["boss_id"]):
		return 0
	for n in nodes:
		if int(n["layer"]) == layer + 2 and not (nodes[id]["edges"] as Array).has(int(n["id"])):
			nodes[id]["edges"].append(int(n["id"]))
			added += 1
	return added


func _resolve_supply(id: int) -> void:
	GameState.complete_node(id)
	var missing: Array[String] = []
	for w in Roster.DROP_WEAPONS:
		if not GameState.weapons.has(w):
			missing.append(w)
	var text := ""
	var icon: Texture2D
	if not missing.is_empty() and GameState.rng.randf() < 0.6:
		var w: String = missing[GameState.rng.randi_range(0, missing.size() - 1)]
		GameState.give_weapon(w)
		var data := GameState.weapon_data(w)
		text = "New weapon: %s!\n%s\n(Switch weapons in battle with keys 1-%d.)" % [data.display_name, data.description, GameState.weapons.size()]
		icon = data.icon
	else:
		GameState.energy_drinks += 1
		text = "A RADICAL Energy Drink! Heals %d HP for 1 AP." % int(GameState.DRINK_HEAL)
		icon = UiKit.sprite("item_energy_drink")
	refresh()
	_show_popup("SUPPLY CACHE", text, icon)


func _show_popup(title: String, body: String, icon: Texture2D) -> void:
	_popup = PanelContainer.new()
	_popup.name = "EventPopup"
	_popup.custom_minimum_size = Vector2(560, 0)
	_popup.position = Vector2(360, 220)
	add_child(_popup)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_popup.add_child(box)
	var t := UiKit.label(title, 26, UiKit.PINK)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	if icon:
		box.add_child(UiKit.texture_rect(icon, Vector2(64, 64)))
	var b := UiKit.label(body, 17)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(520, 0)
	box.add_child(b)
	var ok := UiKit.button("RAD", 140)
	ok.name = "OkButton"
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(close_popup)
	box.add_child(ok)
	ok.grab_focus()


func close_popup() -> void:
	if _popup:
		_popup.queue_free()
		_popup = null


func _open_save_menu() -> void:
	var menu := SAVE_MENU.instantiate()
	menu.allow_save = true
	add_child(menu)
	menu.closed.connect(refresh)
