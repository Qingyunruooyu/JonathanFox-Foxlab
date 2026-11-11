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

# 汽油减速（petrol_puddle 调用），与玩家侧apply_petrol_effect/notify_petrol_exit同构；
var _foxlab_petrol_puddle_count: int = 0
var _foxlab_petrol_in_puddle: bool = false
var _foxlab_petrol_color_applied: bool = false

func _ready():
	_foxlab_acid_timer = Timer.new()
	var _err = _foxlab_acid_timer.connect("timeout", self, "_on_foxlab_acid_timer_timeout")
	add_child(_foxlab_acid_timer)
	_foxlab_acid_damage_args.dodgeable = false
	_foxlab_acid_damage_args.armor_applied = false

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
	if _foxlab_acid_timer != null:
		_foxlab_acid_timer.stop()

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
	if _foxlab_petrol_in_puddle and not _foxlab_uv_lamps.empty() and get_charmed_by_player_index() == -1:
		speed = speed / 2.0
	return speed

func _on_foxlab_acid_timer_timeout() -> void :
	if not _foxlab_acid_in_puddle:
		_foxlab_acid_remaining_time -= _foxlab_acid_tick_interval
		if _foxlab_acid_remaining_time <= 0:
			_foxlab_acid_timer.stop()
			_foxlab_acid_color_applied = false
			remove_color_modulation(FOXLAB_COLOR_ACID)
			return
	if dead or _foxlab_uv_lamps.empty() or get_charmed_by_player_index() != -1:
		return
	var dmg_taken: Array = take_damage(_foxlab_acid_damage_per_tick, _foxlab_acid_damage_args)
	if dmg_taken[1] > 0:
		var lamp_owner: int = foxlab_get_uv_lamp_owner()
		if lamp_owner >= 0:
			RunData.add_tracked_value(lamp_owner, Utils.item_foxlab_uv_lamp_hash, dmg_taken[1], 1)

func _on_BurningTimer_timeout() -> void :
	if _burning != null and RunData.get_nb_item(Utils.character_foxlab_nyuba_hash, _burning_player_index) > 0:
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
