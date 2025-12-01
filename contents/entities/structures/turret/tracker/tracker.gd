class_name FoxLabTracker
extends Turret

var distance = rand_range(90, 100)
var rotation_speed = rand_range(2, 2.5)

var _current_tracking_enemy: Enemy = null
var _position: Vector2 = ZoneService.get_map_center()
var _angle = rand_range(0, 2 * PI)

export (Resource) var slow_sound

static func get_max_range_melee_weapon_range(stats: Resource, player_index:int) -> int:
	var player_weapons = RunData.get_player_weapons(player_index)
	var max_range = 0
	var has_melee_weapon = false
	for weapon in player_weapons:
		if weapon.type == WeaponType.RANGED:
			continue
		has_melee_weapon = true
		max_range = max(max_range, weapon.stats.max_range)
	return max_range + Utils.get_stat("stat_range", player_index) / 2 if has_melee_weapon else stats.max_range

func set_data(data: Resource) -> void :
	var updated_data = data.duplicate()
	var player_weapons = RunData.get_player_weapons(player_index)
	var max_range = get_max_range_melee_weapon_range(data.stats, player_index)
	updated_data.stats.max_range = max_range
	.set_data(updated_data)
	reload_data()

func on_tracking_enemy_died(target: Node, _args: Entity.DieArgs) -> void :
	target.disconnect("died", self, "on_tracking_enemy_died")
	assert (target == _current_tracking_enemy)
	_current_tracking_enemy = null

func _physics_process(delta: float) -> void :
	if not is_instance_valid(_current_tracking_enemy) or _current_tracking_enemy.dead:
		# 依次选择攻击范围内的血量最低的头目、选择辅助怪、选择血量最高的小怪
		var min_hp_boss: Enemy = null
		var min_boss_health = Utils.LARGE_NUMBER
		var max_health = -Utils.LARGE_NUMBER
		for enemy in _targets_in_range:
			if not enemy is Enemy:
				continue
			var distance = global_position.distance_to(enemy.global_position)
			if distance > stats.max_range:
				continue
			if enemy is Boss:
				if min_hp_boss == null or enemy.current_stats.health < min_boss_health:
					min_hp_boss = enemy
					_current_tracking_enemy = enemy
					min_boss_health = enemy.current_stats.health
			if min_hp_boss:
				continue
			if not enemy.can_be_boosted:
				_current_tracking_enemy = enemy
				break
			if enemy.current_stats.health > max_health:
				max_health = enemy.current_stats.health
				_current_tracking_enemy = enemy
		if _current_tracking_enemy:
			var _error = _current_tracking_enemy.connect("died", self, "on_tracking_enemy_died")

	if is_instance_valid(_current_tracking_enemy) and not _current_tracking_enemy.dead:
		_position =  _current_tracking_enemy.global_position

	_angle += delta * rotation_speed
	global_position = Vector2(_position.x + cos(_angle) * distance, _position.y + sin(_angle) * distance)


func _on_SlowHitbox_hit_something(thing_hit: Node, _damage_dealt: int) -> void :
	SoundManager2D.play(slow_sound, thing_hit.global_position, - 5, 0.2)
	thing_hit.add_decaying_speed( - 50)
