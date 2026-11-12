extends SceneTree
## V2 HD asset pipeline. Turns the full-size transparent master PNGs (green screen already
## removed) into game-ready HD sprites in res://assets/sprites/.
## Usage: godot --headless --script res://scripts/tools/build_assets.gd -- <masters_dir>
##
## Sprites are stored at about 2x their on-screen footprint so linear filtering stays sharp;
## SpriteScaler scales them to the exact footprint at runtime.

const OUT := "res://assets/sprites/"

const BOSSES := ["bureaucrat_golem", "vape_cloud_elemental", "burnout_ceo_boss", "sea_lord_boss"]
const FLOORS := ["tile_earth_floor", "tile_air_floor", "tile_fire_floor", "tile_water_floor"]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Pass the folder with the full-size master PNGs after --")
		quit(1)
		return
	var src: String = args[0]
	var count := 0
	for f in DirAccess.get_files_at(src):
		if not f.ends_with(".png") or f.contains("_v2"):
			continue
		var id := f.get_basename()
		var box := _box_for(id)
		if box == Vector2i.ZERO:
			continue
		_fit(src, id, id, box)
		count += 1
	# Isometric 128x64 floor diamonds and the 128x96 spike decal.
	for id in FLOORS:
		_exact_tile(src, id, id + "_iso", Vector2i(128, 64))
	_fit(src, "hazard_spikes", "hazard_spikes_iso", Vector2i(128, 96))
	# Menu / HUD art.
	_fit(src, "carol_iso", "carol_portrait", Vector2i(256, 256))
	_fit(src, "princess_barista_iso", "penny_portrait", Vector2i(256, 256))
	_fit(src, "ui_hit_chance_badge", "ui_hit_chance_badge", Vector2i(450, 150))
	_resize_full(src, "screen_title", Vector2i(1920, 1080))
	_resize_full(src, "screen_victory", Vector2i(1920, 1080))
	print("build_assets: %d sprites + tiles/portraits/screens" % count)
	quit(0)


## Max stored size per asset family (about 2x the battlefield footprint).
func _box_for(id: String) -> Vector2i:
	if id.begins_with("screen_") or id == "ui_hit_chance_badge":
		return Vector2i.ZERO
	if BOSSES.has(id):
		return Vector2i(512, 512)
	if id == "cover_vending_machine":
		return Vector2i(256, 384)
	if id.begins_with("proj_") or id.begins_with("weapon_") or id.begins_with("item_"):
		return Vector2i(128, 128)
	if id.begins_with("tile_") or id.begins_with("hazard_"):
		return Vector2i(128, 128)
	return Vector2i(256, 256)


func _load(src: String, id: String) -> Image:
	var img := Image.load_from_file(src.path_join(id + ".png"))
	if img == null or img.is_empty():
		push_error("missing master " + id)
		return null
	img.convert(Image.FORMAT_RGBA8)
	return img


static func shrink(img: Image, w: int, h: int) -> void:
	while img.get_width() > w * 2 and img.get_height() > h * 2:
		img.resize(img.get_width() / 2, img.get_height() / 2, Image.INTERPOLATE_BILINEAR)
	img.resize(w, h, Image.INTERPOLATE_LANCZOS)


## Removes leftover #00FF00 spill on semi-transparent edge pixels.
static func despill(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a <= 0.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var cap := maxf(c.r, c.b)
			if c.g > cap and (c.a < 0.98 or c.g > cap + 0.35):
				c.g = lerpf(c.g, cap, 0.85 if c.a < 0.98 else 0.5)
				img.set_pixel(x, y, c)


## Crops to visible pixels and shrinks to fit inside `box`, keeping the aspect ratio.
func _fit(src: String, id: String, out_name: String, box: Vector2i) -> void:
	var img := _load(src, id)
	if img == null:
		return
	img = img.get_region(img.get_used_rect())
	var s := minf(float(box.x) / img.get_width(), float(box.y) / img.get_height())
	s = minf(s, 1.0)
	shrink(img, maxi(1, int(round(img.get_width() * s))), maxi(1, int(round(img.get_height() * s))))
	despill(img)
	img.save_png(ProjectSettings.globalize_path(OUT + out_name + ".png"))
	print("  wrote ", out_name, " ", img.get_size())


## Floor tiles are stretched to an exact diamond with hard alpha so neighbours tile without seams.
func _exact_tile(src: String, id: String, out_name: String, size: Vector2i) -> void:
	var img := _load(src, id)
	if img == null:
		return
	img = img.get_region(img.get_used_rect())
	shrink(img, size.x, size.y)
	for y in size.y:
		for x in size.x:
			var c := img.get_pixel(x, y)
			var d := absf(x + 0.5 - size.x / 2.0) / (size.x / 2.0) + absf(y + 0.5 - size.y / 2.0) / (size.y / 2.0)
			c.a = 1.0 if (c.a >= 0.5 or d <= 0.96) and d <= 1.02 else 0.0
			img.set_pixel(x, y, c)
	img.save_png(ProjectSettings.globalize_path(OUT + out_name + ".png"))
	print("  wrote ", out_name, " ", size)


func _resize_full(src: String, id: String, size: Vector2i) -> void:
	var img := _load(src, id)
	if img == null:
		return
	img.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path(OUT + id + ".png"))
	print("  wrote ", id, " ", size)
