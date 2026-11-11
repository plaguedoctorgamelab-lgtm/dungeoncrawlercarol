class_name WeaponData
extends Resource
## Weapon definition (GDD 5.1). Extra fields below the GDD block are presentation helpers.

@export var weapon_id: String = ""
@export var display_name: String = ""
@export var damage: float = 20.0
@export var ap_cost: int = 2
@export var is_ranged: bool = false
@export var max_range_tiles: int = 1
@export var projectile_texture: Texture2D
@export var icon: Texture2D

@export_group("Extras")
@export_multiline var description: String = ""
@export var projectile_tint: Color = Color.WHITE
