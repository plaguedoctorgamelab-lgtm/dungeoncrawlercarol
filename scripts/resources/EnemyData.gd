class_name EnemyData
extends Resource
## Enemy definition (GDD 5.2). Extra fields below the GDD block drive AI behaviour.

@export var enemy_id: String = ""
@export var display_name: String = ""
@export var max_hp: float = 40.0
@export var ap_pool: int = 4
@export var base_damage: float = 12.0
@export var sight_radius_tiles: int = 6
@export var is_ranged: bool = false
@export var projectile_texture: Texture2D
@export var sprite_texture: Texture2D

@export_group("Behaviour")
@export var role: String = ""
@export var realm: int = 0
@export var is_boss: bool = false
## Max tiles a ranged attack reaches (melee is always 1).
@export var attack_range_tiles: int = 1
## Fast units (chargers, fliers) move this many tiles per AP.
@export var tiles_per_ap: int = 1
## Fraction of incoming damage ignored (armored tanks).
@export_range(0.0, 0.9) var damage_reduction: float = 0.0
@export_multiline var flavor_text: String = ""
