extends Node2D
## Loot dropped on the battlefield. Carol picks it up by stepping on the tile.

var cell: Vector2i
var item_id: String = "energy_drink"

@onready var sprite: Sprite2D = $Sprite2D


func setup(c: Vector2i, world: Vector2, id: String = "energy_drink") -> void:
	cell = c
	position = world
	item_id = id
	if id != "energy_drink":
		var w := GameState.weapon_data(id)
		if w:
			sprite.texture = w.icon
	SpriteScaler.fit(sprite, SpriteScaler.DROP, 8.0)


## Applies the item to the run state. Returns a log line.
func collect() -> String:
	var text := ""
	if item_id == "energy_drink":
		GameState.energy_drinks += 1
		text = "Picked up a RADICAL Energy Drink!"
	else:
		if GameState.give_weapon(item_id):
			text = "Picked up the %s!" % Roster.weapon_name(item_id)
		else:
			GameState.energy_drinks += 1
			text = "Duplicate weapon traded for an Energy Drink."
	queue_free()
	return text
