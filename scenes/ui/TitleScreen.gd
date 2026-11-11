extends Control
## Title screen: 4 difficulty selectors, New Game, Load (slot menu), Quit.

const SAVE_MENU := preload("res://scenes/ui/SaveMenu.tscn")

var selected_difficulty: int = GameState.Difficulty.MEDIUM
var _diff_buttons: Array[Button] = []
var _blurb: Label
var _panel_box: VBoxContainer
var _load_btn: Button


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = UiKit.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var art := TextureRect.new()
	art.texture = UiKit.sprite("screen_title")
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(art)

	var panel := PanelContainer.new()
	panel.position = Vector2(1280 / 2.0 - 330, 720 - 158)
	panel.custom_minimum_size = Vector2(660, 0)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var group := ButtonGroup.new()
	for i in GameState.DIFFICULTY_NAMES.size():
		var b := UiKit.button(GameState.DIFFICULTY_NAMES[i], 150)
		b.toggle_mode = true
		b.button_group = group
		b.name = "Difficulty%d" % i
		b.pressed.connect(_on_difficulty.bind(i))
		row.add_child(b)
		_diff_buttons.append(b)
	_blurb = UiKit.label("", 15, UiKit.TEAL)
	_blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_blurb.custom_minimum_size = Vector2(620, 0)
	box.add_child(_blurb)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	box.add_child(actions)
	var new_btn := UiKit.button("NEW GAME", 180)
	new_btn.name = "NewGame"
	new_btn.pressed.connect(start_new_game)
	actions.add_child(new_btn)
	_load_btn = UiKit.button("LOAD GAME", 180)
	_load_btn.name = "LoadGame"
	_load_btn.pressed.connect(_open_load_menu)
	_load_btn.disabled = not SaveSystem.has_any_save()
	actions.add_child(_load_btn)
	var quit_btn := UiKit.button("QUIT", 120)
	quit_btn.pressed.connect(func(): get_tree().quit())
	actions.add_child(quit_btn)

	_on_difficulty(selected_difficulty)
	_diff_buttons[selected_difficulty].button_pressed = true
	new_btn.grab_focus()


func _on_difficulty(i: int) -> void:
	selected_difficulty = i
	_blurb.text = GameState.DIFFICULTY_BLURBS[i]


func start_new_game() -> void:
	GameState.new_run(selected_difficulty)
	GameState.active_slot = 1
	GameState.overworld_banner = "%s - %s" % [Roster.REALM_NAMES[0], Roster.REALM_SUBTITLES[0]]
	get_tree().change_scene_to_file("res://scenes/ui/HowToPlay.tscn")


func _open_load_menu() -> void:
	var menu := SAVE_MENU.instantiate()
	menu.allow_save = false
	add_child(menu)
	menu.closed.connect(func(): _load_btn.disabled = not SaveSystem.has_any_save())
