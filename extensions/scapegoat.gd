extends "res://entities/units/pet/scapegoat/scapegoat.gd"

onready var foxlab_healing_zone = $"%HealingTriggeringZone"
onready var foxlab_healing_shape = $"%HealingTriggeringZone/CollisionShape2D"
var _foxlab_movement_behavior = preload("res://entities/units/movement_behaviors/follow_rand_pos_around_player_movement_behavior.gd")
var _foxlab_target_behavior = preload("res://entities/units/target_behavior/closest_player_target_behavior.gd")

var _foxlab_movement_ins = null
var _foxlab_target_ins = null

func _ready():
	call_deferred("_foxlab_ready")

func _foxlab_ready():
	if not RunData.get_player_effect(Utils.foxlab_gain_scapegoat_no_hurt_hash, player_index).empty():
		RunData.foxlab_scapegoat_no_hurt[player_index].append(self)

	if RunData.get_player_effect_bool(Utils.foxlab_scapegoat_no_heal_hash, player_index):
		foxlab_healing_shape.shape.radius = 0
		foxlab_healing_zone.collision_mask = 0

		_foxlab_target_ins = _foxlab_target_behavior.new().init(self)
		_current_target_behavior = _foxlab_target_ins
		_current_target_behavior.update_target()
		add_child(_foxlab_target_ins)
		_foxlab_movement_ins = _foxlab_movement_behavior.new().init(self)
		_current_movement_behavior = _foxlab_movement_ins
		add_child(_foxlab_movement_ins)

func on_health_updated(_unit: Unit, current_val: int, max_val: int) -> void :
	.on_health_updated(_unit, current_val, max_val)
	if not RunData.get_player_effect(Utils.foxlab_gain_scapegoat_no_hurt_hash, player_index).empty() \
		and current_val >= max_val:
		life_bar.hide()

func update_highlight(_value: bool = true):
	.update_highlight(_value)
	if RunData.is_coop_run and \
		not RunData.get_player_effect(Utils.foxlab_gain_scapegoat_no_hurt_hash, player_index).empty():
		call_deferred("_foxlab_update_coop_hightlight")

func _foxlab_update_coop_hightlight():
	var highlight_color: Color = CoopService.get_player_color(player_index)
	highlight_color.a = 0.5
	if not has_outline(highlight_color):
		add_outline(highlight_color)

func take_damage(value: int, args: TakeDamageArgs) -> Array:
	var dmg_taken = .take_damage(value, args)
	if dmg_taken[1] > 0:
		if not RunData.foxlab_scapegoat_no_hurt[player_index].empty() and current_stats.health + dmg_taken[1] >= max_stats.health:
			RunData.foxlab_scapegoat_no_hurt[player_index].erase(self)

		var material = RunData.get_player_effect(Utils.foxlab_materials_on_scapegoat_hit_hash, player_index)
		if material > 0:
			players_ref[player_index].emit_signal("wanted_to_spawn_gold", material, global_position, 100)

		var movement_chance =  RunData.get_player_effect(Utils.foxlab_scapegoat_no_heal_hash, player_index)
		if movement_chance > 0:
			if Utils.get_chance_success(movement_chance / 100.0):
				_alter_movement_behavior()

	return dmg_taken

func _alter_movement_behavior():
	if _current_target_behavior == _foxlab_target_ins:
		_current_movement_behavior = _movement_behavior
		_current_target_behavior = _target_behavior
		_current_target_behavior.update_target()
	else:
		_current_target_behavior = _foxlab_target_ins
		_current_target_behavior.update_target()
		_current_movement_behavior = _foxlab_movement_ins

func die(args: = Entity.DieArgs.new()) -> void :
	.die(args)
	if not args.cleaning_up:
		for stats_on_scapegoat_death in RunData.get_player_effect(Utils.foxlab_stats_on_scapegoat_death_hash, player_index):
			RunData.add_stat(stats_on_scapegoat_death[0], stats_on_scapegoat_death[1], player_index)
