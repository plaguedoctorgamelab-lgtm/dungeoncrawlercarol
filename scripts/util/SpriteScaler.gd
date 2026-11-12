class_name SpriteScaler
extends RefCounted
## Normalizes high-res textures (e.g. raw 512x512 PNGs) to fixed battlefield footprints,
## and hands out procedural placeholders for any PNG that has not been dropped in yet.

## Visual footprints in screen pixels on the 128x64 isometric grid.
const UNIT := Vector2(128, 128)       ## Carol, Princess Penny, regular enemies (1x1 tile)
const BOSS := Vector2(256, 256)       ## Level bosses (2x2 tiles)
const COVER_HALF := Vector2(128, 128) ## Crates
const COVER_FULL := Vector2(128, 192) ## Vending machines
const PROJECTILE := Vector2(56, 56)   ## Projectiles and pickup drops
const DROP := Vector2(56, 56)

## How far feet sink below the tile center so units stand "in" the diamond.
const FOOT_SINK := 10.0

static var _placeholders: Dictionary = {}


## Scales `sprite` uniformly so its texture fits inside `footprint`, bottom-center anchored
## at the node origin (the isometric tile center). Returns the drawn size in pixels.
static func fit(sprite: Sprite2D, footprint: Vector2, sink: float = FOOT_SINK, bottom_anchor: bool = true) -> Vector2:
	if sprite.texture == null:
		sprite.texture = placeholder("unit")
	var tex_size := Vector2(sprite.texture.get_size())
	var s := scale_for(tex_size, footprint)
	sprite.centered = true
	sprite.scale = Vector2(s, s)
	if bottom_anchor:
		sprite.offset = Vector2(0, -tex_size.y / 2.0 + sink / s)
	else:
		sprite.offset = Vector2.ZERO
	return tex_size * s


## For true 2:1 isometric props (art from docs/art_brief.md): scales the texture so it is
## exactly `width` px wide (the tile is 128) and puts its lowest pixel - the front corner of
## its base - on the tile's bottom corner, `base_y` px below the tile centre.
static func fit_iso(sprite: Sprite2D, width: float = 128.0, base_y: float = 32.0) -> Vector2:
	var tex_size := Vector2(sprite.texture.get_size())
	var s := width / maxf(tex_size.x, 1.0)
	sprite.centered = true
	sprite.scale = Vector2(s, s)
	sprite.offset = Vector2(0, -tex_size.y / 2.0 + base_y / s)
	return tex_size * s


## Flat floor decals (traps): `width` px wide, centred on the tile.
static func fit_decal(sprite: Sprite2D, width: float = 124.0, lift: float = 0.0) -> void:
	var tex_size := Vector2(sprite.texture.get_size())
	var s := width / maxf(tex_size.x, 1.0)
	sprite.centered = true
	sprite.scale = Vector2(s, s)
	sprite.offset = Vector2(0, -lift / s)


## Uniform scale that fits `tex_size` inside `footprint`.
static func scale_for(tex_size: Vector2, footprint: Vector2) -> float:
	if tex_size.x <= 0 or tex_size.y <= 0:
		return 1.0
	return minf(footprint.x / tex_size.x, footprint.y / tex_size.y)


## Loads `res://assets/sprites/<id>.png`, or returns a placeholder so the game never
## boots with a missing-resource error.
static func texture(id: String, kind: String = "") -> Texture2D:
	var path := "res://assets/sprites/%s.png" % id
	if ResourceLoader.exists(path):
		var t: Texture2D = load(path)
		if t != null:
			return t
	return placeholder(kind if kind != "" else _guess_kind(id))


static func _guess_kind(id: String) -> String:
	if id.begins_with("proj_"):
		return "projectile"
	if id.begins_with("tile_"):
		return "tile"
	if id.begins_with("cover_"):
		return "cover"
	if id.begins_with("weapon_") or id.begins_with("item_"):
		return "item"
	return "unit"


## Procedural fallback art: a neon checker silhouette sized for its role.
static func placeholder(kind: String) -> Texture2D:
	if _placeholders.has(kind):
		return _placeholders[kind]
	var img: Image
	match kind:
		"tile":
			img = Image.create(128, 64, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			for y in 64:
				for x in 128:
					var d := absf(x + 0.5 - 64.0) / 64.0 + absf(y + 0.5 - 32.0) / 32.0
					if d <= 1.0:
						var checker := ((x / 16) + (y / 8)) % 2 == 0
						img.set_pixel(x, y, Color("#3a1666") if checker else Color("#22103d"))
		"projectile", "item":
			img = _blob(64, 64, Color("#ffe600"))
		"cover":
			img = _blob(128, 160, Color("#7fe7ff"))
		_:
			img = _blob(128, 128, Color("#ff2bd6"))
	var tex := ImageTexture.create_from_image(img)
	_placeholders[kind] = tex
	return tex


static func _blob(w: int, h: int, col: Color) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(w / 2.0, h / 2.0)
	for y in h:
		for x in w:
			var p := (Vector2(x + 0.5, y + 0.5) - c) / c
			var r := p.length()
			if r <= 1.0:
				var checker := ((x / 8) + (y / 8)) % 2 == 0
				img.set_pixel(x, y, Color.BLACK if r > 0.9 else (col if checker else col.darkened(0.45)))
	return img
