extends CanvasLayer
## Battle HUD: HP/AP, phase banner, combat log, weapons, Dash / Shove abilities, energy
## drinks, hit-chance badge, results.

var battle: TacticalBattlefield
var root: Control
var _hp_bar: ProgressBar
var _ap_label: Label
var _phase_label: Label
var _enemy_label: Label
var _log: VBoxContainer
var _weapon_row: HBoxContainer
var _drink_btn: Button
var _dash_btn: Button
var _shove_btn: Button
var _end_btn: Button
var _hit_panel: PanelContainer
var _hit_label: Label
var _hit_target: Label
var _info_label: Label
var _result: PanelContainer


func _ready() -> void:
	root = Control.new()
	root.theme = UiKit.theme()
	UiKit.fit_design(root)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_top()
	_build_bottom()
	_build_hit_panel()
	SignalBus.log_message.connect(add_log)
	SignalBus.phase_changed.connect(_on_phase)
	SignalBus.hp_changed.connect(func(_c, _m): update_all())
	SignalBus.ap_changed.connect(func(_c, _m): update_all())
	SignalBus.inventory_changed.connect(update_all)
	SignalBus.hit_preview.connect(_on_hit_preview)


func bind(b: TacticalBattlefield) -> void:
	battle = b
	_rebuild_weapons()
	update_all()


func _bar_panel(rect: Rect2) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(p)
	return p


func _build_top() -> void:
	_bar_panel(Rect2(0, 0, 1280, 64))
	var portrait := UiKit.texture_rect(UiKit.sprite("carol_portrait"), Vector2(56, 56))
	portrait.position = Vector2(8, 4)
	root.add_child(portrait)
	var name_l := UiKit.label("CAROL", 16, UiKit.TEAL)
	name_l.position = Vector2(72, 2)
	root.add_child(name_l)
	_hp_bar = ProgressBar.new()
	_hp_bar.position = Vector2(72, 26)
	_hp_bar.size = Vector2(240, 24)
	_hp_bar.max_value = GameState.carol_max_hp()
	_hp_bar.show_percentage = false
	root.add_child(_hp_bar)
	_ap_label = UiKit.label("", 22, UiKit.YELLOW)
	_ap_label.position = Vector2(326, 18)
	root.add_child(_ap_label)
	_phase_label = UiKit.label("", 24, UiKit.PINK)
	_phase_label.position = Vector2(480, 14)
	_phase_label.size = Vector2(420, 36)
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_phase_label)
	_enemy_label = UiKit.label("", 16)
	_enemy_label.position = Vector2(930, 8)
	_enemy_label.size = Vector2(340, 50)
	_enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(_enemy_label)
	_log = VBoxContainer.new()
	_log.position = Vector2(10, 70)
	_log.add_theme_constant_override("separation", 0)
	_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_log)


func _build_bottom() -> void:
	_bar_panel(Rect2(0, 628, 1280, 92))
	_weapon_row = HBoxContainer.new()
	_weapon_row.position = Vector2(10, 638)
	_weapon_row.add_theme_constant_override("separation", 6)
	root.add_child(_weapon_row)
	_dash_btn = _ability_button("DashButton", "DASH [Q]\n1 AP  move 2", Vector2(632, 638), func(): _on_mode("dash"))
	_shove_btn = _ability_button("ShoveButton", "SHOVE [F]\n2 AP  push", Vector2(746, 638), func(): _on_mode("shove"))
	_drink_btn = Button.new()
	_drink_btn.name = "DrinkButton"
	_drink_btn.position = Vector2(860, 638)
	_drink_btn.custom_minimum_size = Vector2(136, 52)
	_drink_btn.icon = UiKit.sprite("item_energy_drink")
	_drink_btn.expand_icon = true
	_drink_btn.add_theme_constant_override("icon_max_width", 26)
	_drink_btn.add_theme_font_size_override("font_size", 14)
	_drink_btn.pressed.connect(_on_drink)
	root.add_child(_drink_btn)
	_end_btn = UiKit.button("END TURN\n[E]", 0)
	_end_btn.name = "EndTurnButton"
	_end_btn.position = Vector2(1002, 638)
	_end_btn.custom_minimum_size = Vector2(118, 52)
	_end_btn.add_theme_font_size_override("font_size", 15)
	_end_btn.pressed.connect(_on_end_turn)
	root.add_child(_end_btn)
	var help := UiKit.label("Tile: move 1 AP\nEnemy: attack\nRight-click: cancel\nEsc: pause", 12, Color("#bfaee6"))
	help.position = Vector2(1130, 632)
	root.add_child(help)


func _ability_button(node_name: String, text: String, pos: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.name = node_name
	b.text = text
	b.toggle_mode = true
	b.position = pos
	b.custom_minimum_size = Vector2(108, 52)
	b.add_theme_font_size_override("font_size", 14)
	b.pressed.connect(cb)
	root.add_child(b)
	return b


func _on_mode(m: String) -> void:
	if battle:
		battle.set_mode("" if battle.mode == m else m)
		update_all()


func _build_hit_panel() -> void:
	_hit_panel = PanelContainer.new()
	_hit_panel.position = Vector2(900, 470)
	_hit_panel.custom_minimum_size = Vector2(370, 0)
	_hit_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_hit_panel)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hit_panel.add_child(box)
	var row := HBoxContainer.new()
	box.add_child(row)
	# Floating neon badge ("85% HIT"). Drawn as a styled panel because the
	# ui_hit_chance_badge art has a fixed number baked into it.
	var badge := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0b0418")
	style.border_color = UiKit.PINK
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(1.0, 0.17, 0.84, 0.45)
	style.shadow_size = 8
	style.set_content_margin_all(4)
	style.content_margin_left = 14
	style.content_margin_right = 14
	badge.add_theme_stylebox_override("panel", style)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(badge)
	_hit_label = UiKit.label("", 26, UiKit.YELLOW)
	_hit_label.add_theme_constant_override("outline_size", 8)
	_hit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_child(_hit_label)
	var tip := UiKit.label("open 85%\nhalf cover 60%\nfull cover 35%", 11, Color("#bfaee6"))
	tip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(tip)
	_hit_target = UiKit.label("", 14)
	box.add_child(_hit_target)
	_info_label = UiKit.label("", 13, Color("#d8c8ff"))
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_label.custom_minimum_size = Vector2(350, 0)
	box.add_child(_info_label)
	_hit_panel.visible = false


func _rebuild_weapons() -> void:
	for c in _weapon_row.get_children():
		c.queue_free()
	for i in GameState.weapons.size():
		var w := GameState.weapon_data(GameState.weapons[i])
		var b := Button.new()
		b.name = "Weapon%d" % (i + 1)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(150, 52)
		b.icon = w.icon
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 26)
		b.add_theme_font_size_override("font_size", 12)
		b.text = "%d %s\n%d dmg %d AP rng %d" % [i + 1, w.display_name.replace("Contractor ", "").replace("Squeaky Foam ", "Foam "), int(w.damage * GameState.carol_damage_mult()), w.ap_cost, w.max_range_tiles]
		b.tooltip_text = "%s - %s" % [w.display_name, w.description]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_on_weapon.bind(i))
		_weapon_row.add_child(b)


func _on_drink() -> void:
	if battle:
		battle.use_drink()


func _on_end_turn() -> void:
	if battle:
		battle.end_player_turn()


func _on_weapon(i: int) -> void:
	if battle:
		battle.equip_index(i)


func update_all() -> void:
	if battle == null or battle.carol == null:
		return
	var c: BattleUnit = battle.carol
	_hp_bar.max_value = c.max_hp
	_hp_bar.value = c.hp
	UiKit.set_bar_color(_hp_bar, UiKit.GREEN if c.hp > 40 else UiKit.RED)
	_hp_bar.tooltip_text = "%d / %d HP" % [int(c.hp), int(c.max_hp)]
	var pips := ""
	for i in c.max_ap:
		pips += "■" if i < c.ap else "□"
	_ap_label.text = "AP %s  HP %d" % [pips, int(c.hp)]
	var alive := 0
	var boss := ""
	for e in battle.enemies:
		if not e.is_dead():
			alive += 1
			if e.data.is_boss:
				boss = "\nBOSS %s: %d/%d" % [e.display_name, int(e.hp), int(e.max_hp)]
	_enemy_label.text = "%s | Enemies left: %d%s" % [Roster.REALM_NAMES[GameState.realm], alive, boss]
	if GameState.weapons.size() != _weapon_row.get_child_count():
		_rebuild_weapons()
	for i in _weapon_row.get_child_count():
		var b: Button = _weapon_row.get_child(i)
		b.set_pressed_no_signal(GameState.weapons[i] == GameState.equipped_weapon)
	var player_turn: bool = battle.is_player_phase()
	_drink_btn.text = "Drink x%d\n+%d HP, %d AP" % [GameState.energy_drinks, int(GameState.DRINK_HEAL), GameState.DRINK_AP]
	_drink_btn.disabled = not player_turn or GameState.energy_drinks <= 0
	_end_btn.disabled = not player_turn
	_dash_btn.disabled = not player_turn or battle.dash_used or c.ap < GameState.DASH_AP
	_shove_btn.disabled = not player_turn or c.ap < GameState.SHOVE_AP
	_dash_btn.set_pressed_no_signal(battle.mode == "dash")
	_shove_btn.set_pressed_no_signal(battle.mode == "shove")


func _on_phase(text: String) -> void:
	_phase_label.text = text
	_phase_label.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(_phase_label, "modulate:a", 1.0, 0.25)
	update_all()


func _on_hit_preview(chance: float, target: String) -> void:
	if chance < 0.0:
		_hit_label.text = ""
		_hit_target.text = ""
		_hit_panel.visible = _info_label.text != ""
		return
	_hit_panel.visible = true
	_hit_label.text = CombatMath.badge_text(chance)
	_hit_label.add_theme_color_override("font_color", UiKit.YELLOW if chance > 0 else UiKit.RED)
	_hit_target.text = target


func set_hover_info(text: String) -> void:
	_info_label.text = text
	_hit_panel.visible = text != "" or _hit_label.text != ""


func add_log(text: String, color: Color = Color.WHITE) -> void:
	var l := UiKit.label(text, 14, color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log.add_child(l)
	while _log.get_child_count() > 6:
		var old := _log.get_child(0)
		_log.remove_child(old)
		old.queue_free()


func popup_text(screen_pos: Vector2, text: String, color: Color) -> void:
	# Convert from viewport pixels into the HUD's 1280x720 design grid.
	screen_pos = screen_pos / root.scale
	var l := UiKit.label(text, 26, color)
	l.position = screen_pos - Vector2(30, 0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(l)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", screen_pos.y - 50, 0.8)
	tw.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tw.chain().tween_callback(l.queue_free)


## buttons: Array of [label: String, action: Callable]
func show_result(title: String, body: String, buttons: Array) -> void:
	if _result:
		_result.queue_free()
	_hit_panel.visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	_result = PanelContainer.new()
	_result.name = "ResultPanel"
	_result.custom_minimum_size = Vector2(600, 0)
	_result.position = Vector2(340, 220)
	root.add_child(_result)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	_result.add_child(box)
	var t := UiKit.label(title, 36, UiKit.PINK)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var b := UiKit.label(body, 18)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(560, 0)
	box.add_child(b)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	for entry in buttons:
		var btn := UiKit.button(entry[0], 200)
		btn.pressed.connect(entry[1])
		row.add_child(btn)
	if row.get_child_count() > 0:
		(row.get_child(0) as Button).grab_focus()


func result_buttons() -> Array[Button]:
	var out: Array[Button] = []
	if _result:
		for n in _result.find_children("*", "Button", true, false):
			out.append(n)
	return out
