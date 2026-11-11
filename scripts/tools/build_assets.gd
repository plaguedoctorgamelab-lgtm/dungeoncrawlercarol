extends SceneTree
## Asset pipeline: builds 32x16 isometric floor tiles and resized screen art from the
## full-size sprite masters.
## Usage: godot --headless --script res://scripts/tools/build_assets.gd -- <masters_dir>

const OUT := "res://assets/sprites/"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Pass the folder with the full-size master PNGs after --")
		quit(1)
		return
	var src: String = args[0]
	for id in ["tile_earth_floor", "tile_air_floor", "tile_fire_floor", "tile_water_floor", "hazard_spikes"]:
		_make_sprite(src, id, id + "_iso", Vector2i(32, 16) if id.begins_with("tile") else Vector2i(32, 24), id.begins_with("tile"))
	# Bigger art for menus / HUD.
	_make_sprite(src, "carol_iso", "carol_portrait", Vector2i(96, 96), false, false)
	_make_sprite(src, "princess_barista_iso", "penny_portrait", Vector2i(96, 96), false, false)
	_make_sprite(src, "ui_hit_chance_badge", "ui_hit_chance_badge", Vector2i(150, 50), false, false)
	_resize_full(src, "screen_title", Vector2i(1280, 720))
	_resize_full(src, "screen_victory", Vector2i(1280, 720))
	print("build_assets: done")
	quit(0)


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
	img.resize(w, h, Image.INTERPOLATE_BILINEAR)


## Crops to visible pixels, shrinks to `size` (stretch when `exact`, else keep aspect, bottom-centered),
## then hardens alpha for crisp pixel edges.
func _make_sprite(src: String, id: String, out_name: String, size: Vector2i, exact: bool, hard_alpha: bool = true) -> void:
	var img := _load(src, id)
	if img == null:
		return
	var used := img.get_used_rect()
	img = img.get_region(used)
	var canvas := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	if exact:
		shrink(img, size.x, size.y)
		canvas.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i.ZERO)
	else:
		var s := minf(float(size.x) / img.get_width(), float(size.y) / img.get_height())
		var w := maxi(1, int(img.get_width() * s))
		var h := maxi(1, int(img.get_height() * s))
		shrink(img, w, h)
		canvas.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i((size.x - w) / 2, size.y - h))
	if hard_alpha:
		for y in canvas.get_height():
			for x in canvas.get_width():
				var c := canvas.get_pixel(x, y)
				c.a = 1.0 if c.a >= 0.5 else 0.0
				canvas.set_pixel(x, y, c)
	canvas.save_png(ProjectSettings.globalize_path(OUT + out_name + ".png"))
	print("  wrote ", out_name, " ", size, " from ", used.size)


func _resize_full(src: String, id: String, size: Vector2i) -> void:
	var img := _load(src, id)
	if img == null:
		return
	shrink(img, size.x, size.y)
	img.save_png(ProjectSettings.globalize_path(OUT + id + ".png"))
	print("  wrote ", id, " ", size)
