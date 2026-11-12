class_name CombatMath
extends RefCounted
## V2 XCOM-style hit chances, set by the target's cover:
##   open ground 85%, half cover 60% (-25%), full cover 35% (-50%), no line of sight 0%.
## Melee attacks hit an adjacent tile, so cover does not apply to them.

const OPEN_CHANCE := 0.85
const HALF_COVER_PENALTY := 0.25
const FULL_COVER_PENALTY := 0.50

const COVER_NONE := 0
const COVER_HALF := 1
const COVER_FULL := 2
const COVER_NAMES: Array[String] = ["NO COVER", "HALF COVER", "FULL COVER"]


static func hit_chance(cover: int, has_los: bool = true) -> float:
	if not has_los:
		return 0.0
	match cover:
		COVER_HALF:
			return OPEN_CHANCE - HALF_COVER_PENALTY
		COVER_FULL:
			return OPEN_CHANCE - FULL_COVER_PENALTY
		_:
			return OPEN_CHANCE


## Badge text shown when hovering an enemy, e.g. "85% HIT".
static func badge_text(chance: float) -> String:
	return "%d%% HIT" % int(round(chance * 100.0))


static func manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


static func distance(a: Vector2i, b: Vector2i) -> float:
	return Vector2(a).distance_to(Vector2(b))
