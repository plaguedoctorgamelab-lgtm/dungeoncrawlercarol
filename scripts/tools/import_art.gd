extends SceneTree
## Imports a delivery of generated art (see docs/art_brief.md) into res://assets/sprites/.
##   - keys out the #00FF00 background (soft edges + green despill)
##   - crops props / traps to their visible pixels and stores them at 2x game size
##   - aligns every Carol frame on a common foot point and canvas so animations don't jitter
##   - does the same for monster frame sets in enemies/<id>/ (pack 2+), writing frames.json
## Any file that isn't in the delivery is simply skipped, so partial packs are fine.
## Usage: godot --headless --path . --script res://scripts/tools/import_art.gd -- <art folder>

const OUT := "res://assets/sprites/"
const CAROL_OUT := "res://assets/sprites/carol/"
## Carol frame canvas (game pixels x2): feet land on FOOT.
const FRAME := Vector2i(440, 320)
const FOOT := Vector2i(220, 300)
## Carol's idle body height on that canvas (must match CarolUnit.FRAME_BODY).
const CAROL_BODY := 260
const ENEMY_OUT := "res://assets/sprites/enemies/"
## Monster frame canvases (2x game size). The idle pose fits a 256 box (bosses 512).
const ENEMY_FRAME := Vector2i(560, 420)
const ENEMY_FOOT := Vector2i(280, 400)
const BOSS_FRAME := Vector2i(1200, 1100)
const BOSS_FOOT := Vector2i(600, 1070)

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
	for id in ["cover_wooden_crate", "cover_vending_machine", "trap_espresso_machine", "cover_trash_can", "cover_privacy_fence", "cover_mining_rig", "cover_server_rack"]:
		_prop(id, id, 256)
	# Floor traps: the diamond itself, 256 px wide.
	_prop("trap_spikes", "hazard_spikes_iso", 256)
	for id in ["trap_live_wire_on", "trap_live_wire_off", "trap_red_tape"]:
		_prop(id, id, 256)
	_carol_frames()
	_enemy_frames()
	print("import_art: done")
	quit(0)


func _load(path: String) -> Image:
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		push_warning("import_art: missing " + path)
		return null
	img.convert(Image.FORMAT_RGBA8)
	return img


## Background removal that's safe for green (or magenta) subjects.
## 1. The key colour is read from the four corners (#00FF00 green or #FF00FF magenta).
## 2. Background = pixels close to that colour that are connected to the image border
##    (flood fill), plus any near-exact key-colour pixels in enclosed gaps.
## 3. Subject pixels touching the background get a soft edge and lose colour spill.
## A green slime survives because its greens are far from pure #00FF00.
static func key_green(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var key := Color(0, 0, 0)
	for c in [Vector2i(0, 0), Vector2i(w - 1, 0), Vector2i(0, h - 1), Vector2i(w - 1, h - 1)]:
		var px := img.get_pixel(c.x, c.y)
		key += Color(px.r, px.g, px.b) * 0.25
	var near := 0.42 # flood-fill tolerance (colour distance to the key)
	var exact := 0.16 # enclosed gaps must be this close to count as background
	var bg := PackedByteArray()
	bg.resize(w * h)
	var stack: PackedInt32Array = []
	for x in w:
		stack.append(x)
		stack.append((h - 1) * w + x)
	for y in h:
		stack.append(y * w)
		stack.append(y * w + w - 1)
	while not stack.is_empty():
		var idx := stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		if bg[idx] != 0:
			continue
		var x := idx % w
		var y := idx / w
		var c := img.get_pixel(x, y)
		if _dist(c, key) > near:
			continue
		bg[idx] = 1
		if x > 0: stack.append(idx - 1)
		if x < w - 1: stack.append(idx + 1)
		if y > 0: stack.append(idx - w)
		if y < h - 1: stack.append(idx + w)
	for y in h:
		for x in w:
			var idx := y * w + x
			var c := img.get_pixel(x, y)
			if bg[idx] != 0 or _dist(c, key) < exact:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				bg[idx] = 1
	# Soft edges + despill on subject pixels that touch the background.
	var green_key := key.g > key.r and key.g > key.b
	for y in h:
		for x in w:
			var idx := y * w + x
			if bg[idx] != 0:
				continue
			var touches := (x > 0 and bg[idx - 1] != 0) or (x < w - 1 and bg[idx + 1] != 0) or (y > 0 and bg[idx - w] != 0) or (y < h - 1 and bg[idx + w] != 0)
			if not touches:
				continue
			var c := img.get_pixel(x, y)
			var d := _dist(c, key)
			if d < near + 0.18:
				c.a = clampf((d - near * 0.6) / 0.35, 0.25, 1.0)
			if green_key:
				c.g = minf(c.g, maxf(c.r, c.b) + 0.08)
			else:
				var m := minf(c.r, c.b)
				c.r = minf(c.r, c.g + 0.08) if m > c.g else c.r
				c.b = minf(c.b, c.g + 0.08) if m > c.g else c.b
			img.set_pixel(x, y, c)


static func _dist(a: Color, b: Color) -> float:
	return sqrt((a.r - b.r) * (a.r - b.r) + (a.g - b.g) * (a.g - b.g) + (a.b - b.b) * (a.b - b.b))


static func shrink_to_width(img: Image, w: int) -> void:
	if img.get_width() <= w:
		return
	var h := maxi(1, int(round(img.get_height() * float(w) / img.get_width())))
	while img.get_width() > w * 2:
		img.resize(img.get_width() / 2, maxi(1, img.get_height() / 2), Image.INTERPOLATE_BILINEAR)
	img.resize(w, h, Image.INTERPOLATE_LANCZOS)


func _prop(file_id: String, out_id: String, width: int) -> void:
	if not FileAccess.file_exists(src.path_join(file_id + ".png")):
		return
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
	if names.is_empty():
		return
	# One scale for every frame, from a standing pose (idle_01, or the first frame of a
	# partial delivery), so Carol never changes size.
	# Prefer an upright, full-height pose as the size reference (crouches like dash would
	# make her too big).
	var ref_name: String = names[0]
	for cand in ["carol_idle_01", "carol_drink_01", "carol_shove_01", "carol_victory_01", "carol_walk_01"]:
		if names.has(cand):
			ref_name = cand
			break
	var ref := _load(dir.path_join(ref_name + ".png"))
	if ref == null:
		return
	key_green(ref)
	var ref_h := ref.get_used_rect().size.y
	var scale := float(CAROL_BODY) / ref_h
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


## Monster frame sets: enemies/<id>/<id>_<anim>_NN.png. All frames of one monster share a
## scale (its idle_01 fits a 256 px box, 512 for bosses) and a canvas with the feet on a
## fixed point. Writes enemies/<id>/frames.json with the canvas, foot and idle size.
func _enemy_frames() -> void:
	var root := src.path_join("enemies")
	if not DirAccess.dir_exists_absolute(root):
		return
	for id in DirAccess.get_directories_at(root):
		var dir := root.path_join(id)
		var names: Array[String] = []
		for f in DirAccess.get_files_at(dir):
			if f.begins_with(id + "_") and f.ends_with(".png"):
				names.append(f.get_basename())
		if names.is_empty():
			continue
		names.sort()
		var boss := names.has(id + "_charge_01") or id in ["bureaucrat_golem", "vape_cloud_elemental", "burnout_ceo_boss", "sea_lord_boss"]
		var box := 512.0 if boss else 256.0
		var canvas_size := BOSS_FRAME if boss else ENEMY_FRAME
		var foot_at := BOSS_FOOT if boss else ENEMY_FOOT
		var ref_name: String = (id + "_idle_01") if names.has(id + "_idle_01") else names[0]
		var ref := _load(dir.path_join(ref_name + ".png"))
		key_green(ref)
		var rr := ref.get_used_rect()
		var scale := minf(box / rr.size.x, box / rr.size.y)
		var out_dir := ENEMY_OUT + id + "/"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
		for nm in names:
			var img := _load(dir.path_join(nm + ".png"))
			if img == null:
				continue
			key_green(img)
			img.resize(int(round(img.get_width() * scale)), int(round(img.get_height() * scale)), Image.INTERPOLATE_LANCZOS)
			var foot := foot_point(img)
			if nm.contains("_defeated") or nm.contains("_down"):
				var ur := img.get_used_rect()
				foot = Vector2i(ur.get_center().x, ur.end.y - 1)
			var canvas := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
			canvas.fill(Color(0, 0, 0, 0))
			canvas.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), foot_at - foot)
			canvas.save_png(ProjectSettings.globalize_path(out_dir + nm + ".png"))
		var meta := {
			"canvas": [canvas_size.x, canvas_size.y],
			"foot": [foot_at.x, foot_at.y],
			"idle_size": [int(rr.size.x * scale), int(rr.size.y * scale)],
			"boss": boss,
		}
		var f := FileAccess.open(ProjectSettings.globalize_path(out_dir + "frames.json"), FileAccess.WRITE)
		f.store_string(JSON.stringify(meta, "\t"))
		f.close()
		print("  enemy ", id, ": ", names.size(), " frames")
