extends Control
## Instructions screen shown after NEW GAME, before the overworld map.

const SECTIONS: Array[Array] = [
	["THE MISSION", "The Sea Lord kidnapped Princess Penny to power his corporate espresso machine. Fight through 4 realms (Earth, Air, Fire, Water) and break her out of his underwater boardroom."],
	["THE MAP", "Click a glowing node to travel there. You can only move along the dotted paths.\nFIGHT - a tactical battle.   HAZARD - a risky event (lose HP, find loot, or find a shortcut).\nCACHE - free weapon or Energy Drink.   BOSS - beat it to clear the realm."],
	["BATTLES", "You get 4 AP (action points) every turn.\nClick a cyan tile to move (1 AP per tile). Click an enemy to attack (2 AP; the Nailgun only 1).\nQ = DASH: 1 AP, move 2 tiles, next attack on you -25% (once a turn).   F = SHOVE: 2 AP, push a monster onto spikes or out of cover.\nH = Energy Drink (+35 HP, 2 AP).   E = end turn.   Right-click cancels.   Esc pauses."],
	["WEAPONS & COVER", "Press 1-4 to switch weapons for free. Swords and mallets hit the tile next to you. Nailguns and Soakers shoot anything in the pink range. Hover an enemy for its HIT badge: 85% in the open, 60% behind a crate (half cover), 35% behind a vending machine (full cover). Enemies use cover too. Watch the badge over each monster: red ! = it will hit you where you stand, yellow CHARGING = a boss big hit next turn."],
	["TRAPS & TIPS", "Fog hides monsters. SPIKES -8 HP. LIVE WIRES spark every other turn (-12 HP, check the hover text). RED TAPE sticks you in place for the turn. OVERHEATED ESPRESSO MACHINES explode when hit or when you shove a monster into them (-25 to everyone next to it) - but monsters can shoot them too! Traps hurt monsters as well. You heal a little after every win and fully each realm. F11 = fullscreen."],
]


func _ready() -> void:
	theme = UiKit.theme()
	UiKit.fit_design(self)
	var bg := ColorRect.new()
	bg.color = UiKit.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := UiKit.label("HOW TO PLAY", 40, UiKit.PINK)
	title.position = Vector2(40, 16)
	add_child(title)
	var sub := UiKit.label("Difficulty: %s  -  %s" % [GameState.DIFFICULTY_NAMES[GameState.difficulty], GameState.save_rule_text()], 16, UiKit.TEAL)
	sub.position = Vector2(44, 72)
	add_child(sub)

	var carol := UiKit.texture_rect(UiKit.sprite("carol_portrait"), Vector2(170, 170))
	carol.position = Vector2(1080, 40)
	add_child(carol)
	var penny := UiKit.texture_rect(UiKit.sprite("penny_portrait"), Vector2(150, 150))
	penny.position = Vector2(1100, 260)
	add_child(penny)
	var save_her := UiKit.label("SAVE PENNY!", 20, UiKit.YELLOW)
	save_her.position = Vector2(1110, 412)
	add_child(save_her)

	var box := VBoxContainer.new()
	box.name = "Sections"
	box.position = Vector2(40, 108)
	box.custom_minimum_size = Vector2(1020, 0)
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	for s in SECTIONS:
		var panel := PanelContainer.new()
		box.add_child(panel)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		panel.add_child(v)
		v.add_child(UiKit.label(s[0], 18, UiKit.YELLOW))
		var body := UiKit.label(s[1], 15)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size = Vector2(990, 0)
		v.add_child(body)

	var go := UiKit.button("LET'S ROCK!", 240)
	go.name = "ContinueButton"
	go.position = Vector2(1000, 662)
	go.custom_minimum_size = Vector2(240, 46)
	go.pressed.connect(continue_to_map)
	add_child(go)
	go.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		continue_to_map()


func continue_to_map() -> void:
	get_tree().change_scene_to_file("res://scenes/overworld/NodeMap.tscn")
