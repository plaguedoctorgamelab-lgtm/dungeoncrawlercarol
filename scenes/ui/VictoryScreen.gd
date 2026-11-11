extends Control
## Ending: Carol and Princess Penny high-five over artisan espresso.


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var art := TextureRect.new()
	art.texture = UiKit.sprite("screen_victory")
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(art)
	art.modulate.a = 0.0
	create_tween().tween_property(art, "modulate:a", 1.0, 1.2)

	var panel := PanelContainer.new()
	panel.position = Vector2(340, 560)
	panel.custom_minimum_size = Vector2(600, 0)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var line := UiKit.label("Princess Penny is free and artisan espresso is saved!", 20, UiKit.YELLOW)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(line)
	var stats := UiKit.label("Difficulty: %s   Battles won: %d   Monsters downsized: %d" % [
		GameState.DIFFICULTY_NAMES[GameState.difficulty], GameState.battles_won, GameState.enemies_defeated], 15)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(stats)
	var btn := UiKit.button("BACK TO TITLE", 220)
	btn.name = "TitleButton"
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn"))
	box.add_child(btn)
	btn.grab_focus()
