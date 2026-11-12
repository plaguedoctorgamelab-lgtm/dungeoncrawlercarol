extends RefCounted
## Enemy turn logic, split out of TacticalBattlefield.
##
## - Ranged enemies pick the firing spot that gives THEM the most cover from Carol and
##   leaves HER the least cover against them (flanking), then shoot.
## - Melee enemies take the shortest route to a tile next to Carol and swing.
## - Bosses telegraph: they spend a turn CHARGING (shown above their head) and strike on
##   the next turn, so the player always gets one turn to dodge or hide.
## - Enemies only notice Carol when she's within their sight AND in line of sight (or very
##   close), and a monster that shoots from the fog stays revealed through Carol's next turn.

## Score weights for choosing a firing position.
const W_MY_COVER := 10.0
const W_FLANK := 6.0
const W_STEP := 0.6
const W_SPIKES := 8.0
## Enemies hear Carol this close even without line of sight.
const HEARING := 2.0

var battle: Node2D
var grid: IsometricGrid


func _init(b: Node2D) -> void:
	battle = b
	grid = b.grid


# ------------------------------------------------------------------ queries

func occupied_for(e) -> Array[Vector2i]:
	return battle.occupied_cells(e)


## Can `e` attack `target` from tile `from` (range and line of sight)?
func can_attack_from(e, from: Vector2i, target: Vector2i) -> bool:
	if not e.data.is_ranged:
		return CombatMath.manhattan(from, target) == 1
	return CombatMath.distance(from, target) <= e.data.attack_range_tiles + 0.01 and grid.has_los(from, target)


## Tiles `e` can move to this turn while keeping `reserve_ap` for an attack -> plan_moves().
func move_plan(e, reserve_ap: int) -> Dictionary:
	var budget := maxi(0, e.max_ap - reserve_ap) * maxi(1, e.data.tiles_per_ap)
	return grid.plan_moves(e.cell, budget, occupied_for(e))


## True if `e` could attack someone standing on `target` next turn (used for the threat
## preview and the intent icons). Bosses use their 2x2 footprint.
func threatens(e, target: Vector2i) -> bool:
	if e.size_cells > 1:
		var reach: int = (e.max_ap - 2) + (e.data.attack_range_tiles if e.data.is_ranged else 1)
		return CombatMath.manhattan(e.nearest_cell(target), target) <= reach
	var plan := move_plan(e, 2)
	for c in plan["steps"]:
		if can_attack_from(e, c, target):
			return true
	return false


func notices_carol(e) -> bool:
	var from: Vector2i = e.nearest_cell(battle.carol.cell)
	var d := CombatMath.distance(from, battle.carol.cell)
	if d <= HEARING:
		return true
	return d <= e.data.sight_radius_tiles and grid.has_los(from, battle.carol.cell)


# ------------------------------------------------------------------ turn

func act(e) -> void:
	e.ap = e.max_ap
	if not e.alerted:
		if notices_carol(e):
			e.alerted = true
			if e.visible:
				SignalBus.say("%s spotted Carol!" % e.display_name, UiKit.PINK)
		else:
			return
	if e.size_cells > 1:
		await _boss_turn(e)
	elif e.data.is_ranged:
		await _ranged_turn(e)
	else:
		await _melee_turn(e)


func _ranged_turn(e) -> void:
	var carol_cell: Vector2i = battle.carol.cell
	var plan := move_plan(e, 2)
	var best := Vector2i(-1, -1)
	var best_score := -INF
	for c in plan["steps"]:
		if not can_attack_from(e, c, carol_cell):
			continue
		var score := W_MY_COVER * grid.cover_between(carol_cell, c)
		score += W_FLANK * (2 - grid.cover_between(c, carol_cell))
		score -= W_STEP * plan["steps"][c]
		if grid.hazards.has(c) and c != e.cell:
			score -= W_SPIKES
		if score > best_score:
			best_score = score
			best = c
	if best.x >= 0:
		await _walk(e, grid.path_from_plan(plan, e.cell, best))
		if battle.carol.is_dead() or battle.is_ended():
			return
		await battle.enemy_attack(e)
		return
	# No shot this turn: advance toward Carol, preferring a covered tile to end on.
	await _advance(e, true)


func _melee_turn(e) -> void:
	var carol_cell: Vector2i = battle.carol.cell
	if can_attack_from(e, e.cell, carol_cell):
		await battle.enemy_attack(e)
		return
	var plan := move_plan(e, 2)
	var best := Vector2i(-1, -1)
	var best_steps := 999
	for c in plan["steps"]:
		if CombatMath.manhattan(c, carol_cell) == 1 and plan["steps"][c] < best_steps:
			best_steps = plan["steps"][c]
			best = c
	if best.x >= 0:
		await _walk(e, grid.path_from_plan(plan, e.cell, best))
		if not battle.carol.is_dead() and not battle.is_ended():
			await battle.enemy_attack(e)
		return
	await _advance(e, false)


## Moves as far toward Carol as the full AP budget allows. Ranged units prefer to end the
## move on a tile where they have cover from Carol.
func _advance(e, prefer_cover: bool) -> void:
	var carol_cell: Vector2i = battle.carol.cell
	var plan := move_plan(e, 0)
	var best: Vector2i = e.cell
	var best_score := -INF
	for c in plan["steps"]:
		var score := -float(CombatMath.manhattan(c, carol_cell)) * 3.0
		if prefer_cover:
			score += 4.0 * grid.cover_between(carol_cell, c)
		if grid.hazards.has(c) and c != e.cell:
			score -= W_SPIKES
		if score > best_score:
			best_score = score
			best = c
	if best != e.cell:
		await _walk(e, grid.path_from_plan(plan, e.cell, best))


func _walk(e, path: Array[Vector2i]) -> void:
	for i in range(1, path.size()):
		if battle.is_ended():
			return
		var next: Vector2i = path[i]
		var seen: bool = grid.is_cell_visible(e.cell) or grid.is_cell_visible(next)
		e.visible = seen
		await e.step_to(next, grid.cell_to_world(next), seen)
		e.visible = battle.is_enemy_targetable(e)
		await battle.enemy_stepped(e)
		if e.is_dead():
			return


# ------------------------------------------------------------------ bosses

func _boss_turn(e) -> void:
	var carol_cell: Vector2i = battle.carol.cell
	if e.charged:
		# The strike lands on the locked danger zone. If Carol left it, it whiffs.
		var zone: Array[Vector2i] = e.strike_zone()
		if not e.data.is_ranged and not can_attack_from(e, e.nearest_cell(carol_cell), carol_cell):
			await _boss_move(e, e.max_ap - 2)
		var in_zone: bool = zone.has(carol_cell)
		var reachable_now: bool = e.data.is_ranged or can_attack_from(e, e.nearest_cell(carol_cell), carol_cell)
		e.charged = false
		e.strike_cell = Vector2i(-1, -1)
		if in_zone and reachable_now:
			await battle.enemy_attack(e)
		else:
			AudioManager.play_sfx("slam")
			SignalBus.say("%s's big attack smashes an empty spot - Carol dodged it!" % e.display_name, UiKit.TEAL)
		e.queue_redraw()
		return
	# Not charged: close in, then wind up if Carol will be in reach next turn.
	if not can_attack_from(e, e.nearest_cell(carol_cell), carol_cell):
		await _boss_move(e, e.max_ap)
	if threatens(e, carol_cell):
		e.charged = true
		e.strike_cell = carol_cell
		e.queue_redraw()
		SignalBus.say("%s is CHARGING UP at Carol's spot! Get out of the red zone!" % e.display_name, UiKit.YELLOW)
		AudioManager.play_sfx("boss_charge")


func _anchor_free(e, anchor: Vector2i, others: Array[Vector2i]) -> bool:
	for dy in e.size_cells:
		for dx in e.size_cells:
			var c: Vector2i = anchor + Vector2i(dx, dy)
			if not grid.is_walkable(c) or others.has(c):
				return false
	return true


func _anchor_score(e, anchor: Vector2i, carol_cell: Vector2i) -> int:
	var near := Vector2i(clampi(carol_cell.x, anchor.x, anchor.x + e.size_cells - 1), clampi(carol_cell.y, anchor.y, anchor.y + e.size_cells - 1))
	if e.data.is_ranged and CombatMath.distance(near, carol_cell) <= e.data.attack_range_tiles + 0.01 and grid.has_los(near, carol_cell):
		return 0
	return CombatMath.manhattan(near, carol_cell)


## 2x2 bosses path as a whole block: breadth-first search over every anchor position whose
## four tiles are free, toward the spot closest to (or in range of) Carol, then walk up to
## `budget` steps of that route. Returns true if the boss moved.
func _boss_move(e, budget: int) -> bool:
	var others := occupied_for(e)
	var carol_cell: Vector2i = battle.carol.cell
	var start: Vector2i = e.cell
	var parent := {start: start}
	var queue: Array[Vector2i] = [start]
	var best := start
	var best_score := _anchor_score(e, start, carol_cell)
	while not queue.is_empty():
		var a: Vector2i = queue.pop_front()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = a + d
			if parent.has(n) or not _anchor_free(e, n, others):
				continue
			parent[n] = a
			queue.append(n)
			var sc := _anchor_score(e, n, carol_cell)
			if sc < best_score:
				best_score = sc
				best = n
	if best == start:
		return false
	var path: Array[Vector2i] = [best]
	while path[0] != start:
		path.push_front(parent[path[0]])
	var moved := false
	for i in range(1, mini(path.size(), budget + 1)):
		await e.step_to(path[i], battle.unit_world(e, path[i]), e.visible)
		e.visible = battle.is_enemy_targetable(e)
		moved = true
		if can_attack_from(e, e.nearest_cell(carol_cell), carol_cell):
			break
	return moved
