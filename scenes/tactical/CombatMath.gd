class_name CombatMath
extends RefCounted
## GDD 4.3: HitChance = max(30%, BaseAccuracy - Distance * 5%); 0% without line of sight.

const MELEE_BASE := 0.95
const RANGED_BASE := 0.85
const MIN_CHANCE := 0.30
const FALLOFF_PER_TILE := 0.05


static func hit_chance(is_ranged: bool, distance_tiles: float, has_los: bool) -> float:
	if not has_los:
		return 0.0
	var base := RANGED_BASE if is_ranged else MELEE_BASE
	return maxf(MIN_CHANCE, base - distance_tiles * FALLOFF_PER_TILE)


static func manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


static func distance(a: Vector2i, b: Vector2i) -> float:
	return Vector2(a).distance_to(Vector2(b))
