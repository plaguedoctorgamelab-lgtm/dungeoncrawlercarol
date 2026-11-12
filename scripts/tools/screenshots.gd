extends SceneTree
## Renders the main screens to PNGs (needs a real window, not --headless).
## godot --path . --script res://scripts/tools/screenshots.gd -- <out_dir>

var out_dir: String


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if not args.is_empty() else ProjectSettings.globalize_path("res://docs/screenshots")
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()


func _snap(file: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out_dir.path_join(file))
	print("saved ", file)


func _wait(n: int) -> void:
	for i in n:
		await process_frame


func _run() -> void:
	var gs := root.get_node("GameState")
	# Never touch the player's real save slots.
	root.get_node("SaveManager").base_dir = "user://screenshot_saves"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://screenshot_saves"))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	root.size = Vector2i(1920, 1080)
	change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
	await _wait(10)
	await _snap("01_title.png")
	gs.new_run(1, 777)
	change_scene_to_file("res://scenes/ui/HowToPlay.tscn")
	await _wait(10)
	await _snap("01b_how_to_play.png")
	gs.complete_node(gs.available_nodes()[0])
	gs.overworld_banner = "Earth Realm - Corporate Suburbs & HOA Dungeons"
	change_scene_to_file("res://scenes/overworld/NodeMap.tscn")
	await _wait(10)
	await _snap("02_overworld.png")
	for realm in [0, 3]:
		gs.start_realm(realm)
		gs.pending_node = gs.map_data["boss_id"] if realm == 3 else gs.available_nodes()[0]
		change_scene_to_file("res://scenes/tactical/TacticalBattlefield.tscn")
		await _wait(10)
		var battle := current_scene
		while not battle.ready_done:
			await process_frame
		# Reveal the whole map for the screenshot.
		for c in battle.grid.all_cells():
			battle.grid.explored[c] = true
		battle.grid.update_fog(battle.carol.cell, 30)
		battle._refresh_player_view()
		for e in battle.enemies:
			e.visible = true
		# Realm 1 keeps the NEW THREAT card up; the boss shot shows the board and hover card.
		if realm == 3:
			while battle.hud.is_intro_showing():
				battle.hud.dismiss_intro()
		var e0 = battle.enemies[0]
		battle.hovered_cell = e0.cell
		battle._update_hover()
		await _wait(5)
		if realm == 3:
			while battle.hud.is_intro_showing():
				battle.hud.dismiss_intro()
			await _wait(12)
		await _snap("03_battle_realm%d.png" % (realm + 1))
	change_scene_to_file("res://scenes/ui/VictoryScreen.tscn")
	await _wait(90)
	await _snap("04_victory.png")
	quit(0)
