extends CanvasLayer
## Esc pause menu on the map and in battle: resume, music / SFX volume, screen shake,
## fullscreen, quit to title. Shows the game's version number.

const PAUSABLE_SCENES := ["NodeMap", "TacticalBattlefield"]

var _root: Control
var _music: HSlider
var _sfx: HSlider
var _shake: CheckBox


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_open() -> bool:
	return _root != null and _root.visible


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		return
	if is_open():
		close()
		get_viewport().set_input_as_handled()
		return
	var scene := get_tree().current_scene
	if scene and PAUSABLE_SCENES.has(String(scene.name)):
		open()
		get_viewport().set_input_as_handled()


func open() -> void:
	# Built on first use so nothing is allocated for headless runs that never pause.
	if _root == null:
		_build()
	_music.set_value_no_signal(AudioManager.music_volume)
	_sfx.set_value_no_signal(AudioManager.sfx_volume)
	_shake.set_pressed_no_signal(AudioManager.screen_shake)
	_root.visible = true
	get_tree().paused = true
	AudioManager.play_sfx("ui_click")


func close() -> void:
	_root.visible = false
	get_tree().paused = false
	AudioManager.save_settings()


func _build() -> void:
	_root = Control.new()
	_root.theme = UiKit.theme()
	UiKit.fit_design(_root)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var panel := PanelContainer.new()
	panel.name = "PausePanel"
	panel.position = Vector2(440, 150)
	panel.custom_minimum_size = Vector2(400, 0)
	_root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := UiKit.label("PAUSED", 34, UiKit.PINK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_music = _slider(box, "Music volume")
	_music.value_changed.connect(AudioManager.set_music_volume)
	_sfx = _slider(box, "Sound effects volume")
	_sfx.value_changed.connect(func(v: float):
		AudioManager.set_sfx_volume(v)
		AudioManager.play_sfx("ui_click"))
	_shake = CheckBox.new()
	_shake.text = "Screen shake"
	_shake.toggled.connect(func(on: bool): AudioManager.screen_shake = on)
	box.add_child(_shake)
	var full := UiKit.button("TOGGLE FULLSCREEN [F11]", 0)
	full.pressed.connect(GameState.toggle_fullscreen)
	box.add_child(full)
	var resume := UiKit.button("RESUME [Esc]", 0)
	resume.name = "ResumeButton"
	resume.pressed.connect(close)
	box.add_child(resume)
	var quit := UiKit.button("QUIT TO TITLE", 0)
	quit.pressed.connect(_quit_to_title)
	box.add_child(quit)
	var ver := UiKit.label("Dungeon Crawler Carol %s" % GameState.version_label(), 13, Color("#bfaee6"))
	ver.name = "VersionLabel"
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(ver)


func _slider(box: VBoxContainer, text: String) -> HSlider:
	box.add_child(UiKit.label(text, 15, UiKit.TEAL))
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.custom_minimum_size = Vector2(360, 24)
	box.add_child(s)
	return s


func _quit_to_title() -> void:
	close()
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
