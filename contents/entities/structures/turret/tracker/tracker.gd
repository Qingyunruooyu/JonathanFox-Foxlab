class_name FoxLabTracker
extends Turret

var move_speed = rand_range(1000, 1500)
var _orbit_radius = rand_range(90, 100)
var _orbit_speed = rand_range(2, 2.5)
var _orbit_angle: float = 0.0
var _current_orbit_center: Vector2 = ZoneService.get_rand_pos_in_area(ZoneService.get_map_center(), 200)

var _current_tracking_enemy: Enemy = null
var _player_tracked: = false
var _in_assembling: = false

var _angle = rand_range(0, 2 * PI)
var _players: = []
const _PLAYER_TRACKING_DISTANCE = 100.0

func init(zone_min_pos: Vector2, zone_max_pos: Vector2, players_ref: Array = [], _entity_spawner_ref = null) -> void :
	.init(zone_min_pos, zone_max_pos, players_ref, _entity_spawner_ref)
	_players = players_ref
	if Utils.get_chance_success(0.5):
		_orbit_speed = -_orbit_speed
	if RunData.get_player_effect_bool("foxlab_assemble_tracker_on_hurt", player_index):
		var player:Player = players_ref[player_index]
		if ItemService.FOXLAB_IS_NEW_DAWN:
			player.connect("took_damage", self, "_on_player_took_damage")
		else:
			player.connect("took_damage", self, "_on_player_took_damage_legacy")

static func get_max_range_melee_weapon_range(stats: Resource, player_index:int) -> int:
	var player_weapons = RunData.get_player_weapons(player_index)
	var max_range = 0
	var best_weapon:WeaponData = null
	for weapon in player_weapons:
		if weapon.type == WeaponType.RANGED:
			continue
		if weapon.stats.max_range > max_range:
			best_weapon = weapon
			max_range = weapon.stats.max_range
	if best_weapon:
		var args := WeaponServiceInitStatsArgs.new()
		args.sets = best_weapon.sets
		args.effects = best_weapon.effects
		var current_stats = WeaponService.init_melee_stats(best_weapon.stats, player_index, args)
		max_range = current_stats.max_range

	return max_range if best_weapon else stats.max_range as int

func set_data(data: Resource) -> void :
	var updated_data = data.duplicate()
	var player_weapons = RunData.get_player_weapons(player_index)
	var max_range = get_max_range_melee_weapon_range(data.stats, player_index)
	if max_range != updated_data.stats.max_range:
		var stats = updated_data.stats.duplicate()
		stats.max_range = max_range
		updated_data.stats = stats
	.set_data(updated_data)
	reload_data()

func _on_tracking_enemy_died(target: Node, _args: Entity.DieArgs) -> void :
	target.disconnect("died", self, "_on_tracking_enemy_died")
	assert (target == _current_tracking_enemy)
	_current_tracking_enemy = null

func _on_player_took_damage(enemy: Enemy, _value: int, _knockback_direction: Vector2, _is_crit: bool, _is_dodge: bool, _is_protected: bool, _armor_did_something: bool, args: TakeDamageArgs, _hit_type: int, _is_one_shot: bool) -> void :
	_assemble_if_idle()

func _on_player_took_damage_legacy(enemy: Enemy, _value: int, _knockback_direction: Vector2, _is_crit: bool, _is_dodge: bool, _is_protected: bool, _armor_did_something: bool, args: TakeDamageArgs, _hit_type: int) -> void :
	_assemble_if_idle()

func _is_idle() -> bool:
	return not is_instance_valid(_current_tracking_enemy) or _current_tracking_enemy.dead

# 召回前不会锁定敌人
func _assemble_if_idle():
	if _is_idle() :
		_in_assembling = true

func _physics_process(delta: float) -> void :
	if not _in_assembling and _is_idle():
		# 依次选择攻击范围内的血量最低的头目、选择辅助怪、选择血量最高的小怪
		var min_hp_boss: Enemy = null
		var min_boss_health = Utils.LARGE_NUMBER
		var max_health = -Utils.LARGE_NUMBER
		for enemy in _targets_in_range:
			if not enemy is Enemy:
				continue
			if global_position.distance_to(enemy.global_position) > stats.max_range:
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
			var _error = _current_tracking_enemy.connect("died", self, "_on_tracking_enemy_died")

	var new_center = _current_orbit_center
	if not _is_idle():
		new_center =  _current_tracking_enemy.global_position
		_player_tracked = false
	elif _in_assembling or _player_tracked or global_position.distance_to(_players[player_index].global_position) <= _PLAYER_TRACKING_DISTANCE:
		_player_tracked = true
		if _in_assembling and global_position.distance_to(_players[player_index].global_position) <= _PLAYER_TRACKING_DISTANCE:
			_in_assembling = false
		new_center = _players[player_index].global_position

	# 如果旋转中心改变了，重新计算当前角度
	if _current_orbit_center != new_center:
		# 计算当前相对于旧中心的向量和角度
		var current_offset = global_position - _current_orbit_center
		_orbit_angle = current_offset.angle()

	# 更新旋转中心（无论是移动还是旋转都需要更新）
	_current_orbit_center = new_center

	# 无论旋转中心是否移动，都要增加轨道角度
	_orbit_angle += _orbit_speed * delta

	# 计算新的位置
	var new_offset = Vector2.RIGHT.rotated(_orbit_angle) * _orbit_radius
	var desired_position = _current_orbit_center + new_offset

	# 平滑移动到新位置
	global_position = global_position.move_toward(desired_position, move_speed * delta)

