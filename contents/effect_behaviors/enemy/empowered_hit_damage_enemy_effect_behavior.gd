extends "res://effect_behaviors/enemy_effect_behavior.gd"

var _curse_behavior_script = load("res://effect_behaviors/enemies/curse_enemy_effect_behavior.gd")
var _empowered_checked: bool = false
var _empowered: bool = false

func should_add_on_spawn() -> bool:
	for player_index in RunData.get_player_count():
		if not RunData.get_player_effect(Utils.foxlab_hit_damage_against_empowered_enemies_hash, player_index).empty():
			return true
	return false

func get_bonus_damage(hitbox, from_player_index: int) -> int:
	if hitbox == null or from_player_index < 0:
		return 0
	if not _empowered_checked:
		_empowered_checked = true
		_empowered = _parent._is_meca or _parent._is_mutant or _foxlab_has_curse_behavior()
	if not _empowered:
		return 0
	var effects = RunData.get_player_effect(Utils.foxlab_hit_damage_against_empowered_enemies_hash, from_player_index)
	if effects.empty():
		return 0
	var bonus_damage: int = 0
	for effect in effects:
		for scaling_stat in hitbox.scaling_stats:
			if scaling_stat[0] == effect[0]:
				bonus_damage += effect[1]
				break
	if bonus_damage <= 0 and _parent is Boss:
		return 0
	return bonus_damage

func _foxlab_has_curse_behavior() -> bool:
	for behavior in _parent.effect_behaviors.get_children():
		if _curse_behavior_script.instance_has(behavior):
			return true
	return false
