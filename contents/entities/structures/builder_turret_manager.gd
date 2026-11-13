extends Node

class FoxlabEntry:
	extends Reference
	var orig = null
	var installed = null
	var gen: int = 0
	var combos: Dictionary = {}
	var last_stats = null

var _entries: Dictionary = {}

func foxlab_register(turret) -> void:
	if not _entries.has(turret):
		_entries[turret] = FoxlabEntry.new()
		var animation_player = turret._animation_player
		if not animation_player.is_connected("animation_started", self, "_foxlab_on_shoot_anim_started"):
			var _error = animation_player.connect("animation_started", self, "_foxlab_on_shoot_anim_started", [turret])
	_foxlab_update(turret)

func _foxlab_on_shoot_anim_started(anim_name: String, turret) -> void:
	if anim_name == "shoot":
		_foxlab_update(turret)

func _foxlab_update(turret) -> void:
	var entry = _entries[turret]
	if turret._stats_every_x_shots != entry.installed:
		_foxlab_capture(turret)
	elif turret.stats != entry.last_stats:
		_foxlab_refresh(turret)
	_foxlab_maintain(turret)

func _foxlab_capture(turret) -> void:
	var entry = _entries[turret]
	entry.orig = turret._stats_every_x_shots
	entry.gen += 1
	entry.combos = {}
	turret.projectiles_on_hit = WeaponService.foxlab_merge_projectiles_on_hit(turret.effects, turret.player_index, true)
	entry.last_stats = turret.stats
	entry.installed = turret._stats_every_x_shots

func _foxlab_refresh(turret) -> void:
	var entry = _entries[turret]
	entry.gen += 1
	entry.combos = {}
	turret.projectiles_on_hit = WeaponService.foxlab_merge_projectiles_on_hit(turret.effects, turret.player_index, true)
	entry.last_stats = turret.stats

func _foxlab_maintain(turret) -> void:
	var entry = _entries[turret]
	var orig = entry.orig
	if orig.size() <= 1 or not _foxlab_keys_valid(orig):
		return
	var nb = turret._nb_shots_taken
	var matched = []
	for x in orig:
		if nb % x == 0:
			matched.append(x)
	if matched.size() <= 1:
		if turret._stats_every_x_shots != orig:
			turret._stats_every_x_shots = orig
			entry.installed = orig
		return
	matched.sort()
	var cache_key = str(matched) + "|" + str(entry.gen)
	var combined = entry.combos.get(cache_key)
	if combined == null:
		var args = turret._init_stats_args_build
		args.effects = turret.effects
		combined = WeaponService.foxlab_build_combined_every_x_turret_stats(turret, matched)
		entry.combos[cache_key] = combined
	var desired = {matched[0]: combined}
	if turret._stats_every_x_shots == desired:
		entry.installed = desired
		return
	turret._stats_every_x_shots = desired
	entry.installed = desired

func _foxlab_keys_valid(every_x: Dictionary) -> bool:
	for x in every_x.keys():
		if not (x is int) or x < 1:
			return false
	return true
