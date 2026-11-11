extends Button
## One clickable node on the overworld tree.

signal chosen(node_id: int)

const TYPE_LABELS := {"combat": "FIGHT", "hazard": "HAZARD", "supply": "CACHE", "boss": "BOSS"}
const TYPE_COLORS := {"combat": Color("#ff2bd6"), "hazard": Color("#ffb000"), "supply": Color("#7dff4a"), "boss": Color("#ff3b3b")}

var node_id: int = -1
var node_type: String = "combat"
var state: String = "locked" # locked | available | visited | current


func setup(data: Dictionary, realm: int, new_state: String) -> void:
	node_id = int(data["id"])
	node_type = String(data["type"])
	state = new_state
	name = "Node%d" % node_id
	custom_minimum_size = Vector2(64, 64) if node_type == "boss" else Vector2(52, 52)
	size = custom_minimum_size
	expand_icon = true
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon = _icon_for(realm)
	tooltip_text = "Node %d - %s" % [node_id + 1, TYPE_LABELS[node_type]]
	var col: Color = TYPE_COLORS[node_type]
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#1b0c2c")
	sb.border_color = col
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(32)
	sb.set_content_margin_all(6)
	var hov := sb.duplicate() as StyleBoxFlat
	hov.border_color = Color.WHITE
	hov.bg_color = Color("#3a1666")
	add_theme_stylebox_override("normal", sb)
	add_theme_stylebox_override("hover", hov)
	add_theme_stylebox_override("pressed", hov)
	add_theme_stylebox_override("disabled", sb)
	match state:
		"available":
			disabled = false
			modulate = Color.WHITE
			_pulse()
		"current":
			disabled = true
			modulate = Color(1, 1, 0.6)
		"visited":
			disabled = true
			modulate = Color(0.45, 0.45, 0.5)
		_:
			disabled = true
			modulate = Color(0.75, 0.75, 0.8)
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)


func _icon_for(realm: int) -> Texture2D:
	match node_type:
		"boss":
			return UiKit.sprite(Roster.boss_for_realm(realm))
		"hazard":
			return UiKit.sprite("hazard_spikes")
		"supply":
			return UiKit.sprite("item_energy_drink")
		_:
			var pool := Roster.enemies_for_realm(realm, false)
			return UiKit.sprite(pool[node_id % pool.size()])


func _pulse() -> void:
	var tw := create_tween().set_loops()
	tw.tween_property(self, "scale", Vector2(1.12, 1.12), 0.45)
	tw.tween_property(self, "scale", Vector2.ONE, 0.45)
	pivot_offset = custom_minimum_size / 2.0


func _on_pressed() -> void:
	chosen.emit(node_id)
