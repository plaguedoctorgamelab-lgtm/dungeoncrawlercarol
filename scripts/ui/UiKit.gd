class_name UiKit
extends RefCounted
## Shared neon 90s UI theme and small widget helpers.

const PINK := Color("#ff2bd6")
const TEAL := Color("#00f0ff")
const YELLOW := Color("#ffe600")
const GREEN := Color("#7dff4a")
const RED := Color("#ff3b3b")
const BG := Color("#140726")
const PANEL := Color("#22103d")
## Menus and HUDs are laid out on a 1280x720 design grid and scaled up to the 1920x1080
## viewport (x1.5). Fonts use MSDF (project setting) so scaled text stays sharp.
const DESIGN := Vector2(1280, 720)

static var _theme: Theme


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font_size = 18
	var normal := _box(PANEL, PINK, 3)
	var hover := _box(Color("#3a1666"), TEAL, 3)
	var pressed := _box(Color("#4c0f5c"), YELLOW, 3)
	var disabled := _box(Color("#1a1326"), Color("#4a3a5a"), 3)
	for cls in ["Button", "OptionButton"]:
		t.set_stylebox("normal", cls, normal)
		t.set_stylebox("hover", cls, hover)
		t.set_stylebox("pressed", cls, pressed)
		t.set_stylebox("disabled", cls, disabled)
		t.set_stylebox("focus", cls, _box(Color(0, 0, 0, 0), YELLOW, 2))
		t.set_color("font_color", cls, Color.WHITE)
		t.set_color("font_hover_color", cls, TEAL)
		t.set_color("font_pressed_color", cls, YELLOW)
		t.set_color("font_disabled_color", cls, Color("#6b5a7d"))
		t.set_constant("outline_size", cls, 4)
		t.set_color("font_outline_color", cls, Color.BLACK)
	t.set_stylebox("panel", "PanelContainer", _box(Color(BG, 0.92), TEAL, 3))
	t.set_stylebox("panel", "Panel", _box(Color(BG, 0.92), TEAL, 3))
	t.set_constant("outline_size", "Label", 5)
	t.set_color("font_outline_color", "Label", Color.BLACK)
	t.set_constant("outline_size", "RichTextLabel", 4)
	t.set_color("font_outline_color", "RichTextLabel", Color.BLACK)
	var bar_bg := _box(Color("#1b0c2c"), Color.BLACK, 2)
	var bar_fill := _box(GREEN, Color(0, 0, 0, 0), 0)
	t.set_stylebox("background", "ProgressBar", bar_bg)
	t.set_stylebox("fill", "ProgressBar", bar_fill)
	t.set_color("font_color", "ProgressBar", Color.WHITE)
	t.set_constant("outline_size", "ProgressBar", 4)
	t.set_color("font_outline_color", "ProgressBar", Color.BLACK)
	_theme = t
	return t


static func _box(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_content_margin_all(8)
	s.shadow_color = Color(0, 0, 0, 0.6)
	s.shadow_size = 0
	s.shadow_offset = Vector2(3, 3)
	return s


## Lays `c` out on the 1280x720 design grid and scales it to fill the 1920x1080 viewport.
static func fit_design(c: Control) -> void:
	c.set_anchors_preset(Control.PRESET_TOP_LEFT)
	c.position = Vector2.ZERO
	c.size = DESIGN
	var view := Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920)),
		float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080)))
	var s := minf(view.x / DESIGN.x, view.y / DESIGN.y)
	c.scale = Vector2(s, s)


## Design-grid scale factor (1.5 at 1920x1080).
static func design_scale() -> float:
	return float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920)) / DESIGN.x


static func label(text: String, size: int = 18, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func button(text: String, min_w: int = 0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, 40)
	return b


static func texture_rect(tex: Texture2D, size: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.custom_minimum_size = size
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return r


## Loads a sprite, falling back to a procedural placeholder when the PNG is missing.
static func sprite(id: String) -> Texture2D:
	return SpriteScaler.texture(id)


static func set_bar_color(bar: ProgressBar, color: Color) -> void:
	var fill := _box(color, Color(0, 0, 0, 0), 0)
	bar.add_theme_stylebox_override("fill", fill)
