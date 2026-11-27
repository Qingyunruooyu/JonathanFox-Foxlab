extends "res://entities/units/enemies/enemy.gd"

var _foxlab_uv_lamps: Array = []
var _foxlab_uv_hurtbox_mask: int = -1

# 酸液DoT，状态机与玩家侧apply_acid_dot/notify_acid_exit同构：
var _foxlab_acid_damage_per_tick: int = 0
var _foxlab_acid_tick_interval: float = 1.0
var _foxlab_acid_puddle_count: int = 0
var _foxlab_acid_in_puddle: bool = false
var _foxlab_acid_remaining_time: float = 0.0
var _foxlab_acid_timer: Timer = null
var _foxlab_acid_damage_args = TakeDamageArgs.new(-1)
var _foxlab_acid_color_applied: bool = false

const FOXLAB_COLOR_ACID: Color = Color(1.2, 1.5, 0.2, 1)
const FOXLAB_COLOR_PETROL: Color = Color(0.537255, 0.607843, 0.768627, 1)

# 原版燃烧速度最多生效80%，超出的部分线性折算成额外的dot伤害：每10%燃烧速度增加10%每一跳的燃烧伤害
const FOXLAB_BURN_SURPLUS_START: float = 0.8
var _foxlab_burn_surplus: float = 0.0

# 汽油减速（petrol_puddle 调用），与玩家侧apply_petrol_effect/notify_petrol_exit同构；
var _foxlab_petrol_puddle_count: int = 0
var _foxlab_petrol_in_puddle: bool = false
var _foxlab_petrol_color_applied: bool = false

func foxlab_try_apply_puddle_colors() -> void:
	if _foxlab_uv_lamps.empty():
		return
	if _foxlab_acid_timer != null and not _foxlab_acid_timer.is_stopped() and not _foxlab_acid_color_applied:
		_foxlab_acid_color_applied = true
		_set_color_modulation(FOXLAB_COLOR_ACID)
	if _foxlab_petrol_in_puddle and not _foxlab_petrol_color_applied:
		_foxlab_petrol_color_applied = true
		_set_color_modulation(FOXLAB_COLOR_PETROL)

func foxlab_apply_acid_dot(damage: int, interval: float, duration_after_exit: float, in_puddle: bool) -> void :
	_foxlab_acid_damage_per_tick = damage
	_foxlab_acid_tick_interval = interval
	if in_puddle:
		_foxlab_acid_puddle_count += 1
		_foxlab_acid_in_puddle = true
		_foxlab_acid_remaining_time = duration_after_exit
	if _foxlab_acid_timer.is_stopped():
		_foxlab_acid_timer.wait_time = _foxlab_acid_tick_interval
		_foxlab_acid_timer.start()
	foxlab_try_apply_puddle_colors()

func foxlab_notify_acid_exit(duration_after_exit: float) -> void :
	_foxlab_acid_puddle_count -= 1
	if _foxlab_acid_puddle_count <= 0:
		_foxlab_acid_puddle_count = 0
		_foxlab_acid_in_puddle = false
		_foxlab_acid_remaining_time = duration_after_exit

func foxlab_apply_petrol_effect() -> void :
	_foxlab_petrol_puddle_count += 1
	_foxlab_petrol_in_puddle = true
	foxlab_try_apply_puddle_colors()

func foxlab_notify_petrol_exit() -> void :
	_foxlab_petrol_puddle_count -= 1
	if _foxlab_petrol_puddle_count <= 0:
		_foxlab_petrol_puddle_count = 0
		_foxlab_petrol_in_puddle = false
		if _foxlab_petrol_color_applied:
			_foxlab_petrol_color_applied = false
			remove_color_modulation(FOXLAB_COLOR_PETROL)

func foxlab_get_uv_lamp_owner() -> int:
	if _foxlab_uv_lamps.empty():
		return -1
	return _foxlab_uv_lamps.back().player_index

func _on_foxlab_acid_timer_timeout() -> void :
	if not _foxlab_acid_in_puddle:
		_foxlab_acid_remaining_time -= _foxlab_acid_tick_interval
		if _foxlab_acid_remaining_time <= 0:
			_foxlab_acid_timer.stop()
			_foxlab_acid_color_applied = false
			remove_color_modulation(FOXLAB_COLOR_ACID)
			return
	if dead or _foxlab_uv_lamps.empty() or _is_charmed:
		return
	var dmg_taken: Array = take_damage(_foxlab_acid_damage_per_tick, _foxlab_acid_damage_args)
	if dmg_taken[1] > 0:
		var lamp_owner: int = foxlab_get_uv_lamp_owner()
		if lamp_owner >= 0:
			RunData.add_tracked_value(lamp_owner, Utils.item_foxlab_uv_lamp_hash, dmg_taken[1], 1)

# 腕龙的脚的魅惑外观：可见图形是根级Sprite（$Sprite2下落的脚/$Sprite3落地环），基础sprite只是地面标记，
# 原版魅惑描边只装饰基础sprite（entity.gd _set_outlines），魅惑时需给根级Sprite补描边并记录原值供复原
var _foxlab_charmed_outline_sprites: Array = []

func _foxlab_convert_charmed_attack_behavior(p_attack_behavior: AttackBehavior, charm_material) -> void:
	if p_attack_behavior.custom_collision_layer == Utils.PET_PROJECTILES_BIT:
		return
	for effect_behavior in effect_behaviors.get_children():
		if "charmed" in effect_behavior and effect_behavior.charmed:
			var shooting_states = effect_behavior.get("_original_shooting_states") # TODO(jona): remove when compatible
			if shooting_states != null:
				shooting_states.push_back([p_attack_behavior, p_attack_behavior.custom_collision_layer, p_attack_behavior.custom_sprite_material])
	p_attack_behavior.custom_collision_layer = Utils.PET_PROJECTILES_BIT
	if charm_material != null:
		p_attack_behavior.custom_sprite_material = charm_material

func _foxlab_apply_charm_outline_to_root_sprites() -> void:
	if outline_material == null:
		return
	for node in get_children():
		if not (node is Sprite) or node.texture == null:
			continue
		_foxlab_charmed_outline_sprites.push_back([node, node.material])
		var outline_mat = ShaderMaterial.new()
		outline_mat.shader = outline_material.shader
		outline_mat.set_shader_param("texture_size", node.texture.get_size())
		outline_mat.set_shader_param("alpha", 0.4)
		outline_mat.set_shader_param("desaturation", 0.75)
		outline_mat.set_shader_param("outline_color_0", Utils.CHARM_COLOR)
		node.material = outline_mat

func _foxlab_restore_charm_outline_sprites() -> void:
	for sprite_entry in _foxlab_charmed_outline_sprites:
		if is_instance_valid(sprite_entry[0]):
			sprite_entry[0].material = sprite_entry[1]
	_foxlab_charmed_outline_sprites.clear()

func _foxlab_get_charm_material() -> ShaderMaterial:
	for effect_behavior in effect_behaviors.get_children():
		if "charmed" in effect_behavior and effect_behavior.charmed:
			var new_shader = effect_behavior.projectile_shader.duplicate()
			new_shader.set_shader_param("hue", Utils.CHARM_COLOR.h)
			return new_shader
	return null

func foxlab_on_charmed(_enemy) -> void:
	var charm_material = _foxlab_get_charm_material()
	for proj in _all_additional_projectiles:
		if is_instance_valid(proj):
			proj.set_collision_layer(Utils.PET_PROJECTILES_BIT)
			if charm_material != null:
				proj.set_sprite_material(charm_material)

	if "is_elite" in self:
		for effect_behavior in effect_behaviors.get_children():
			if "charmed" in effect_behavior and effect_behavior.charmed:
				effect_behavior._charm_timer.start(max(_entity_spawner_ref._wave_timer.time_left - 5, Utils.CHARM_DURATION))

	# 腕龙的脚的攻击不注册，补充一下，不然踩到玩家可能有伤害
	for node in get_children():
		if node is ShootingAttackBehavior and not _all_attack_behaviors.has(node):
			_foxlab_convert_charmed_attack_behavior(node, charm_material)

	_foxlab_apply_charm_outline_to_root_sprites()

func foxlab_on_died(_entity, _die_args) -> void:
	for proj in _all_additional_projectiles:
		if is_instance_valid(proj) and proj._has_custom_material:
			proj.set_collision_layer(proj._original_collision_layer)
			proj._has_custom_material = false
			proj._sprite.material = Utils.projectile_outline_petrol_shadermat if proj.evolution_puddle_type == proj.EVOLUTION_PUDDLE_PETROL else Utils.projectile_outline_shadermat
	_foxlab_restore_charm_outline_sprites()

######## 扩展 ######

func _ready():
	_foxlab_acid_timer = Timer.new()
	var _err = _foxlab_acid_timer.connect("timeout", self, "_on_foxlab_acid_timer_timeout")
	add_child(_foxlab_acid_timer)
	_foxlab_acid_damage_args.dodgeable = false
	_foxlab_acid_damage_args.armor_applied = false
	var _e_charmed = connect("charmed", self, "foxlab_on_charmed")
	var _e_died = connect("died", self, "foxlab_on_died")

func init(zone_min_pos: Vector2, zone_max_pos: Vector2, p_players_ref: Array = [], entity_spawner_ref = null) -> void:
	.init(zone_min_pos, zone_max_pos, p_players_ref, entity_spawner_ref)
	_foxlab_burn_surplus = max(0.0, (RunData.sum_all_player_effects(Keys.burning_cooldown_reduction_hash)\
		- RunData.sum_all_player_effects(Keys.burning_cooldown_increase_hash)) / 100.0 - FOXLAB_BURN_SURPLUS_START)

func respawn() -> void :
	.respawn()
	_foxlab_uv_lamps.clear()
	_foxlab_uv_hurtbox_mask = -1
	_foxlab_acid_puddle_count = 0
	_foxlab_acid_in_puddle = false
	_foxlab_acid_color_applied = false
	_foxlab_petrol_puddle_count = 0
	_foxlab_petrol_in_puddle = false
	_foxlab_petrol_color_applied = false
	remove_color_modulation(FOXLAB_COLOR_ACID)
	remove_color_modulation(FOXLAB_COLOR_PETROL)
	_foxlab_restore_charm_outline_sprites()
	# 腕龙的脚踩完即死入池而魅惑计时未到点，且uncharm不复位charmed标记：
	# 复用后set_charmed会因charm()早退而空转（脚被标记已魅惑但层是敌方的），残留计时还会中途杀死复用实例
	for effect_behavior in effect_behaviors.get_children():
		if "charmed" in effect_behavior and effect_behavior.charmed:
			effect_behavior.charmed = false
			effect_behavior._charm_timer.stop()
	if _foxlab_acid_timer != null:
		_foxlab_acid_timer.stop()

func register_attack_behavior(p_attack_behavior: AttackBehavior) -> void:
	.register_attack_behavior(p_attack_behavior)
	if not _is_charmed or not (p_attack_behavior is ShootingAttackBehavior):
		return
	_foxlab_convert_charmed_attack_behavior(p_attack_behavior, _foxlab_get_charm_material())

func register_additional_projectile(p_additional_projectile: EnemyProjectile) -> void:
	.register_additional_projectile(p_additional_projectile)
	if not _is_charmed or p_additional_projectile == null or not is_instance_valid(p_additional_projectile):
		return
	if p_additional_projectile._hitbox.collision_layer == Utils.PET_PROJECTILES_BIT:
		return
	p_additional_projectile.set_collision_layer(Utils.PET_PROJECTILES_BIT)
	var charm_material = _foxlab_get_charm_material()
	if charm_material != null:
		p_additional_projectile.set_sprite_material(charm_material)

func take_damage(value: int, args: TakeDamageArgs) -> Array:
	var dmg_taken: Array = .take_damage(value, args)
	if not _foxlab_uv_lamps.empty() and args.hitbox != null and dmg_taken[1] > 0:
		var layer: int = args.hitbox.collision_layer
		if (layer & (Utils.ENEMY_PROJECTILES_BIT | Utils.ENEMIES_BIT)) != 0 and (layer & (Utils.PLAYER_PROJECTILES_BIT | Utils.PET_PROJECTILES_BIT)) == 0:
			var lamp_owner: int = foxlab_get_uv_lamp_owner()
			if lamp_owner >= 0:
				RunData.add_tracked_value(lamp_owner, Utils.item_foxlab_uv_lamp_hash, dmg_taken[1], 1)
	return dmg_taken

func get_move_speed() -> float:
	var speed: float = .get_move_speed()
	if _foxlab_petrol_in_puddle and not _foxlab_uv_lamps.empty() and not _is_charmed:
		speed = speed / 2.0
	return speed

func _on_BurningTimer_timeout() -> void :
	if _burning == null:
		._on_BurningTimer_timeout()
		return
	var saved_burning = _burning
	var saved_damage: int = _burning.damage
	var bumped_damage: int = saved_damage
	if _foxlab_burn_surplus > 0.0:
		bumped_damage = (saved_damage * (1.0 + _foxlab_burn_surplus)) as int
		_burning.damage = bumped_damage
	if RunData.get_nb_item(Utils.character_foxlab_nyuba_hash, _burning_player_index) > 0:
		var nb_nyuba = RunData.get_nb_item(Utils.character_foxlab_nyuba_hash, _burning_player_index)
		if not _burning.is_global_burn:
			._on_BurningTimer_timeout()
			RunData.add_tracked_value(_burning_player_index, Utils.character_foxlab_nyuba_hash, nb_nyuba)
		else:
			var nb_sausage = RunData.get_nb_item(Keys.item_scared_sausage_hash, _burning_player_index)
			var tracked_effects = RunData.tracked_item_effects[_burning_player_index]
			var before_sausage = tracked_effects[Keys.item_scared_sausage_hash]
			._on_BurningTimer_timeout()
			var after_sausage = tracked_effects[Keys.item_scared_sausage_hash]
			var diff = after_sausage - before_sausage
			var nyuba_value = diff * nb_nyuba / (nb_nyuba + nb_sausage)
			var sausage_value = diff - nyuba_value
			RunData.add_tracked_value(_burning_player_index, Utils.character_foxlab_nyuba_hash, nyuba_value)
			RunData.set_tracked_value(_burning_player_index, Keys.item_scared_sausage_hash, before_sausage + sausage_value)
	else:
		._on_BurningTimer_timeout()
	if _burning == saved_burning and _burning.damage == bumped_damage:
		_burning.damage = saved_damage
