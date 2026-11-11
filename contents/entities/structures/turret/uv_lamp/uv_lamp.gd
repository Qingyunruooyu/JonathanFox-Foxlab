extends "res://entities/structures/turret/turret.gd"

export (Color) var color_entity_modulation = Color(0.8, 0.5, 1.4)
export (AudioStreamSample) var sound_enter_zone = null
export (AudioStreamSample) var sound_exit_zone = null

var _instance_counted: bool = false
var _exposed_enemies: Dictionary = {}
# player -> 进照射区时 apply 的那组 effects 数组引用；退出时按同一引用 unapply，
# 避免照射期间背包角色变动、缓存重建导致 apply/unapply 数组错配
var _players_in_zone: Dictionary = {}
var _expose_range_ratio: float = 2.0
var _aura_base_radius: float = 0.0
onready var _expose_shape = $ExposeRange / CollisionShape2D
onready var _aura = $ExposeRange / aura

func set_data(data: Resource) -> void :
	.set_data(data)
	_expose_range_ratio = data.expose_range_ratio
	if not _instance_counted:
		_instance_counted = true
		RunData.get_player_effects(player_index)[Utils.foxlab_uv_lamp_instance_hash] += 1


func set_current_stats(new_stats) -> void :
	.set_current_stats(new_stats)
	_sync_expose_range()


func reload_data() -> void :
	.reload_data()
	_sync_expose_range()


func _sync_expose_range() -> void :
	var radius: float = min(stats.max_range, base_stats.max_range * _expose_range_ratio)
	if _expose_shape:
		_expose_shape.shape.radius = radius
	if _aura:
		if _aura_base_radius <= 0.0:
			_aura_base_radius = _aura.texture.get_size().x / 2.0
		_aura.scale = Vector2(radius / _aura_base_radius, radius / _aura_base_radius)


func _physics_process(_delta: float) -> void :
	if _aura and not dead:
		_aura.rotation_degrees += 90.0 * _delta


func _on_ExposeRange_body_entered(body: Node) -> void :
	if body is Player:
		if not dead:
			_foxlab_player_entered(body)
		return
	if not dead and body is Enemy:
		_exposed_enemies[body] = true
		_foxlab_expose(body)
		var _error = body.connect("died", self, "_on_exposed_enemy_died")
		var _error_charm = body.connect("charmed", self, "_on_exposed_enemy_charmed")


func _on_ExposeRange_body_exited(body: Node) -> void :
	if body is Player:
		_foxlab_player_left(body)
		return
	if not body is Enemy or not is_instance_valid(body):
		return
	if not dead and not body.dead:
		_foxlab_unexpose(body)
	_exposed_enemies.erase(body)
	body.disconnect("died", self, "_on_exposed_enemy_died")
	body.disconnect("charmed", self, "_on_exposed_enemy_charmed")


func _on_exposed_enemy_died(target, _args) -> void :
	if not dead:
		_foxlab_unexpose(target)
	_exposed_enemies.erase(target)


func _on_exposed_enemy_charmed(target) -> void :
	if not dead:
		_foxlab_set_exposed_hurtbox(target)


func _on_player_in_zone_died(player, _args) -> void :
	if _players_in_zone.has(player):
		_foxlab_cleanup_player(player, _players_in_zone[player], false)
		_players_in_zone.erase(player)


func _foxlab_player_entered(player) -> void :
	var player_index: int = player.player_index
	var char_effects: Array = RunData.get_foxlab_backpack_char_effects(player_index)
	RunData.foxlab_apply_effects_array(char_effects, player_index)
	player._set_color_modulation(color_entity_modulation)
	if sound_enter_zone:
		SoundService.play_sound2d_with_limit("foxlab_uv_lamp", sound_enter_zone, 2, global_position, 0, 0.1)
	_players_in_zone[player] = char_effects
	var _error = player.connect("died", self, "_on_player_in_zone_died")


func _foxlab_player_left(player) -> void :
	if not _players_in_zone.has(player):
		return
	_foxlab_cleanup_player(player, _players_in_zone[player], true)
	_players_in_zone.erase(player)


func _foxlab_cleanup_player(player, char_effects: Array, play_sound: bool) -> void :
	if not is_instance_valid(player):
		return
	var player_index: int = player.player_index
	player.disconnect("died", self, "_on_player_in_zone_died")
	RunData.foxlab_unapply_effects_array(char_effects, player_index)
	player.remove_color_modulation(color_entity_modulation)
	if play_sound and sound_exit_zone:
		SoundService.play_sound2d_with_limit("foxlab_uv_lamp", sound_exit_zone, 2, global_position, 0, 0.1)


func die(args= Utils.default_die_args) -> void :
	if _instance_counted:
		_instance_counted = false
		RunData.get_player_effects(player_index)[Utils.foxlab_uv_lamp_instance_hash] -= 1
	for body in _exposed_enemies.keys():
		_foxlab_unexpose(body)
	_exposed_enemies.clear()
	for player in _players_in_zone.keys():
		_foxlab_cleanup_player(player, _players_in_zone[player], false)
	_players_in_zone.clear()
	.die(args)

func _foxlab_expose(enemy) -> void :
	enemy._foxlab_uv_lamps.push_back(self)
	enemy.foxlab_try_apply_puddle_colors()
	if enemy._foxlab_uv_lamps.size() == 1:
		if enemy._foxlab_uv_hurtbox_mask == -1:
			enemy._foxlab_uv_hurtbox_mask = enemy._hurtbox.collision_mask
		_foxlab_set_exposed_hurtbox(enemy)
		enemy._set_color_modulation(color_entity_modulation)
		RunData.foxlab_exposed_enemies[enemy.enemy_id_hash] = RunData.foxlab_exposed_enemies.get(enemy.enemy_id_hash, 0) + 1


func _foxlab_set_exposed_hurtbox(enemy) -> void :
	if enemy.get_charmed_by_player_index() != - 1:
		# 魅惑禁用了 hurtbox：打开但只允许敌方来源，玩家方弹幕不打自己的魅惑盟友
		enemy._hurtbox.set_deferred("collision_mask", Utils.ENEMY_PROJECTILES_BIT | Utils.ENEMIES_BIT)
		enemy._hurtbox.enable()
	else:
		enemy._hurtbox.set_deferred("collision_mask", enemy._hurtbox.collision_mask | Utils.ENEMY_PROJECTILES_BIT | Utils.ENEMIES_BIT)

func _foxlab_unexpose(body) -> void :
	if not is_instance_valid(body):
		return
	body._foxlab_uv_lamps.erase(self)
	if not body._foxlab_uv_lamps.empty():
		return
	body.remove_color_modulation(color_entity_modulation)
	if body._foxlab_uv_hurtbox_mask != -1:
		body._hurtbox.set_deferred("collision_mask", body._foxlab_uv_hurtbox_mask)
		body._foxlab_uv_hurtbox_mask = -1
	if body.get_charmed_by_player_index() != - 1:
		body._hurtbox.disable()
	var id_count: int = RunData.foxlab_exposed_enemies.get(body.enemy_id_hash, 0) - 1
	if id_count > 0:
		RunData.foxlab_exposed_enemies[body.enemy_id_hash] = id_count
	else:
		RunData.foxlab_exposed_enemies.erase(body.enemy_id_hash)
