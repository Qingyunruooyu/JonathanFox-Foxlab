extends Node

class FoxlabTurretEntry:
	extends Reference
	var orig = null
	var installed = null
	var last_stats = null
	var x_list: Array = []
	var combos: Dictionary = {}
	var mode: int = 0
	var combined_bits: int = -1

var _entries: Dictionary = {}

func foxlab_register(turret) -> void:
	if not _entries.has(turret):
		var entry = FoxlabTurretEntry.new()
		_entries[turret] = entry
		var animation_player = turret._animation_player
		if not animation_player.is_connected("animation_started", self, "_foxlab_on_shoot_anim_started"):
			var _error = animation_player.connect("animation_started", self, "_foxlab_on_shoot_anim_started", [turret])
		_foxlab_update(turret, entry)
	else:
		_foxlab_update(turret, _entries[turret])

func _foxlab_on_shoot_anim_started(anim_name: String, turret) -> void:
	if anim_name == "shoot":
		_foxlab_update(turret, _entries[turret])

func _foxlab_update(turret, entry) -> void:
	if turret.stats != entry.last_stats or turret._stats_every_x_shots != entry.installed:
		_foxlab_changed(turret, entry)
	_foxlab_maintain(turret, entry)

func _foxlab_changed(turret, entry) -> void:
	entry.combos = {}
	entry.combined_bits = -1
	if turret._stats_every_x_shots != entry.installed:
		entry.orig = turret._stats_every_x_shots
		entry.installed = turret._stats_every_x_shots
		entry.mode = 1
		_foxlab_scan_keys(entry)
	turret.projectiles_on_hit = WeaponService.foxlab_merge_projectiles_on_hit(turret.effects, turret.player_index, true)
	entry.last_stats = turret.stats

func _foxlab_scan_keys(entry) -> void:
	var keys = entry.orig.keys()
	keys.sort()
	if keys.size() <= 1 or keys.size() > 62:
		entry.x_list = []
		return
	for x in keys:
		if not (x is int) or x < 1:
			entry.x_list = []
			return
	entry.x_list = keys

func _foxlab_maintain(turret, entry) -> void:
	var x_list = entry.x_list
	if x_list.empty():
		return
	var nb = turret._nb_shots_taken
	var bits = 0
	var count = 0
	var lowest = 0
	for i in range(x_list.size()):
		if nb % x_list[i] == 0:
			bits |= 1 << i
			if count == 0:
				lowest = x_list[i]
			count += 1
	if count <= 1:
		if entry.mode != 1:
			turret._stats_every_x_shots = entry.orig
			entry.installed = entry.orig
			entry.mode = 1
			entry.combined_bits = -1
		return
	if entry.mode == 2 and entry.combined_bits == bits:
		return
	var matched = []
	for i in range(x_list.size()):
		if bits & (1 << i):
			matched.append(x_list[i])
	var combined = entry.combos.get(bits)
	if combined == null:
		var args = turret._init_stats_args_build
		args.effects = turret.effects
		combined = WeaponService.foxlab_build_combined_every_x_turret_stats(turret, matched)
		entry.combos[bits] = combined
	var desired = {lowest: combined}
	turret._stats_every_x_shots = desired
	entry.installed = desired
	entry.mode = 2
	entry.combined_bits = bits
