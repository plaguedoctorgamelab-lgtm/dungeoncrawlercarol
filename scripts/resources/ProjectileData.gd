class_name ProjectileData
extends Resource
## A tweened ranged projectile / attack effect (V2: 15 of them, see Roster.PROJECTILES).

@export var projectile_id: String = ""
@export var display_name: String = ""
@export var texture: Texture2D
## Screen-space speed in px/s on the 128x64 grid.
@export var speed: float = 1100.0
## "straight", "arc" (lobbed), "spin", "wobble" (flutter / pulse) or "beam" (fast streak).
@export_enum("straight", "arc", "spin", "wobble", "beam") var motion: String = "straight"
## Peak height of the lob for "arc" motion, in px.
@export var arc_height: float = 0.0
## Turns per second for spinning projectiles.
@export var spin_turns: float = 0.0
@export var tint: Color = Color.WHITE
## Afterimage trail colour (alpha 0 = no trail).
@export var trail_color: Color = Color(1, 1, 1, 0)
## On-screen footprint (SpriteScaler.PROJECTILE by default).
@export var footprint: Vector2 = Vector2(56, 56)
@export_multiline var description: String = ""
