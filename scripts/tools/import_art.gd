extends SceneTree
## Imports a delivery of generated art (see docs/art_brief.md) into res://assets/sprites/.
##   - keys out the #00FF00 background (soft edges + green despill)
##   - crops props / traps to their visible pixels and stores them at 2x game size
##   - aligns every Carol frame on a common foot point and canvas so animations don't jitter
## Usage: godot --headless --path . --script res://scripts/tools/import_art.gd -- <art folder>

const OUT := "res://assets/sprites/"
const CAROL_OUT := "res://assets/sprites/carol/"
## Carol frame canvas (game pixels x2): feet land on FOOT.
const FRAME := Vector2i(440, 320)
const FOOT := Vector2i(220, 300)

var src: String


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Pass the art folder after --")
		quit(1)
		return
	src = args[0]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAROL_OUT))
	# Props: stored 256 px wide (2x the 128 px tile) so their base diamond spans the tile.
	for id in ["cover_wooden_crate", "cover_vending_machine", "trap_espresso_machine"]:
		_prop(id, id, 256)
	# Floor traps: the diamond itself, 256 px wide.
	_prop("trap_spikes", "hazard_spikes_iso", 256)
	for id in ["trap_live_wire_on", "trap_live_wire_off", "trap_red_tape"]:
		_prop(id, id, 256)
	_carol_frames()
	print("import_art: done")
	quit(0)


func _load(path: String) -> Image:
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		push_warning("import_art: missing " + path)
		return null
	img.convert(Image.FORMAT_RGBA8)
	return img


## Soft chroma key for a #00FF00 background with green despill on the edges.
static func key_green(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			var other := maxf(c.r, c.b)
			var g := c.g - other
			if g > 0.38 and c.g > 0.5:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			elif g > 0.12:
				var a := clampf(1.0 - (g - 0.12) / 0.26, 0.0, 1.0)
				img.set_pixel(x, y, Color(c.r, other, c.b, a * c.a))
			elif c.g > other:
				c.g = lerpf(c.g, other, 0.5)
				img.set_pixel(x, y, c)


static func shrink_to_width(img: Image, w: int) -> void:
	if img.get_width() <= w:
		return
	var h := maxi(1, int(round(img.get_height() * float(w) / img.get_width())))
	while img.get_width() > w * 2:
		img.resize(img.get_width() / 2, maxi(1, img.get_height() / 2), Image.INTERPOLATE_BILINEAR)
	img.resize(w, h, Image.INTERPOLATE_LANCZOS)


func _prop(file_id: String, out_id: String, width: int) -> void:
	var img := _load(src.path_join(file_id + ".png"))
	if img == null:
		return
	key_green(img)
	img = img.get_region(img.get_used_rect())
	shrink_to_width(img, width)
	img.save_png(ProjectSettings.globalize_path(OUT + out_id + ".png"))
	print("  prop ", out_id, " ", img.get_size())


## Finds where the feet are: bottom of the opaque area, centred on the opaque columns of
## its lowest 12% (so an outstretched sword or gun doesn't shift the anchor sideways).
static func foot_point(img: Image) -> Vector2i:
	var r := img.get_used_rect()
	var band := maxi(4, int(r.size.y * 0.12))
	var xs := 0.0
	var n := 0
	for y in range(r.end.y - band, r.end.y):
		for x in range(r.position.x, r.end.x):
			if img.get_pixel(x, y).a > 0.5:
				xs += x
				n += 1
	var fx := int(xs / n) if n > 0 else r.get_center().x
	return Vector2i(fx, r.end.y - 1)


func _carol_frames() -> void:
	var dir := src.path_join("carol_frames")
	var names: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if f.begins_with("carol_") and f.ends_with(".png"):
			names.append(f.get_basename())
	names.sort()
	# One scale for every frame, from the idle pose, so Carol never changes size.
	var ref := _load(dir.path_join("carol_idle_01.png"))
	if ref == null:
		return
	key_green(ref)
	var ref_h := ref.get_used_rect().size.y
	var scale := float(FOOT.y - 40) / ref_h
	for nm in names:
		var img := _load(dir.path_join(nm + ".png"))
		if img == null:
			continue
		key_green(img)
		if not is_equal_approx(scale, 1.0):
			img.resize(int(round(img.get_width() * scale)), int(round(img.get_height() * scale)), Image.INTERPOLATE_LANCZOS)
		var foot := foot_point(img)
		if nm.begins_with("carol_down"):
			# Lying down: centre the body on the tile instead of the feet.
			var ur := img.get_used_rect()
			foot = Vector2i(ur.get_center().x, ur.end.y - 1)
		var canvas := Image.create(FRAME.x, FRAME.y, false, Image.FORMAT_RGBA8)
		canvas.fill(Color(0, 0, 0, 0))
		canvas.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), FOOT - foot)
		canvas.save_png(ProjectSettings.globalize_path(CAROL_OUT + nm + ".png"))
		print("  frame ", nm)
		if nm == "carol_idle_01":
			# The idle pose also becomes Carol's single sprite and her HUD portrait.
			var cut := canvas.get_region(canvas.get_used_rect())
			cut.save_png(ProjectSettings.globalize_path(OUT + "carol_iso.png"))
			var por := cut.duplicate()
			var s := 256.0 / maxf(por.get_width(), por.get_height())
			if s < 1.0:
				por.resize(int(por.get_width() * s), int(por.get_height() * s), Image.INTERPOLATE_LANCZOS)
			por.save_png(ProjectSettings.globalize_path(OUT + "carol_portrait.png"))
