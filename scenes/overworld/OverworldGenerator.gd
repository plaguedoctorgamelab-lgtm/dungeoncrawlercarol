class_name OverworldGenerator
extends RefCounted
## Procedural Slay-the-Spire-style branching node tree (GDD 3.3).
## - 15-20 nodes laid out in layers of 2-3 (the last layer may be smaller)
## - Boss spawns randomly in the final 25% of nodes (by node number)
## - Every path eventually reaches the boss

const MIN_NODES := 15
const MAX_NODES := 20


static func generate(seed_value: int, realm: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var total := rng.randi_range(MIN_NODES, MAX_NODES)

	# 1) Split nodes into layers.
	var layer_sizes: Array[int] = []
	var remaining := total
	while remaining > 0:
		var s := mini(rng.randi_range(2, 3), remaining)
		layer_sizes.append(s)
		remaining -= s

	# 2) Create nodes, numbered in layer order.
	var nodes: Array = []
	var layers: Array = []
	var id := 0
	for li in layer_sizes.size():
		var ids: Array[int] = []
		for j in layer_sizes[li]:
			var lane := (j + 0.5) / layer_sizes[li] + rng.randf_range(-0.06, 0.06)
			nodes.append({"id": id, "layer": li, "lane": lane, "type": "combat", "edges": []})
			ids.append(id)
			id += 1
		layers.append(ids)

	# 3) Connect each layer to the next: nearest lane plus an occasional branch.
	for li in layers.size() - 1:
		var cur: Array = layers[li]
		var nxt: Array = layers[li + 1]
		for a in cur:
			var nearest := _nearest(nodes, nxt, nodes[a]["lane"])
			_link(nodes, a, nearest)
			if rng.randf() < 0.45:
				var other: int = nxt[rng.randi_range(0, nxt.size() - 1)]
				if absf(nodes[other]["lane"] - nodes[a]["lane"]) < 0.6:
					_link(nodes, a, other)
		for b in nxt:
			if not _has_incoming(nodes, b):
				_link(nodes, _nearest(nodes, cur, nodes[b]["lane"]), b)

	# 4) Boss placement: random node within the final 25% of node numbers.
	var first_boss_candidate := int(ceil(total * 0.75))
	var boss_id := rng.randi_range(first_boss_candidate, total - 1)
	nodes[boss_id]["type"] = "boss"
	nodes[boss_id]["edges"] = []
	# Any dead end that isn't the boss gets a path to the boss.
	for n in nodes:
		if n["id"] != boss_id and (n["edges"] as Array).is_empty():
			_link(nodes, n["id"], boss_id)

	# 5) Node types for everything else.
	var has_cache := false
	for n in nodes:
		if n["id"] == boss_id or n["layer"] == 0:
			continue
		var roll := rng.randf()
		if roll < 0.55:
			n["type"] = "combat"
		elif roll < 0.77:
			n["type"] = "hazard"
		else:
			n["type"] = "supply"
			has_cache = true
	if not has_cache:
		for n in nodes:
			if n["layer"] == 1 and n["id"] != boss_id:
				n["type"] = "supply"
				break

	return {"nodes": nodes, "boss_id": boss_id, "layer_count": layers.size(), "realm": realm}


static func _nearest(nodes: Array, candidates: Array, lane: float) -> int:
	var best: int = candidates[0]
	var best_d := INF
	for c in candidates:
		var d := absf(float(nodes[c]["lane"]) - lane)
		if d < best_d:
			best_d = d
			best = c
	return best


static func _link(nodes: Array, a: int, b: int) -> void:
	if not (nodes[a]["edges"] as Array).has(b):
		nodes[a]["edges"].append(b)


static func _has_incoming(nodes: Array, b: int) -> bool:
	for n in nodes:
		if (n["edges"] as Array).has(b):
			return true
	return false


## Node ids reachable from the realm start (any layer-0 node). Used by tests.
static func reachable_from_start(map: Dictionary) -> Array[int]:
	var seen: Array[int] = []
	var stack: Array[int] = []
	for n in map["nodes"]:
		if int(n["layer"]) == 0:
			stack.append(int(n["id"]))
	while not stack.is_empty():
		var cur: int = stack.pop_back()
		if seen.has(cur):
			continue
		seen.append(cur)
		for e in map["nodes"][cur]["edges"]:
			stack.append(int(e))
	return seen


## True when every node reachable from the start can still reach the boss.
static func boss_always_reachable(map: Dictionary) -> bool:
	var boss := int(map["boss_id"])
	for start in reachable_from_start(map):
		var seen := {}
		var stack: Array[int] = [start]
		var found := false
		while not stack.is_empty():
			var cur: int = stack.pop_back()
			if cur == boss:
				found = true
				break
			if seen.has(cur):
				continue
			seen[cur] = true
			for e in map["nodes"][cur]["edges"]:
				stack.append(int(e))
		if not found:
			return false
	return true
