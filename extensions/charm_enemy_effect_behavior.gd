extends "res://dlcs/dlc_1/effect_behaviors/enemy/charm_enemy_effect_behavior.gd"

var _foxlab_original_additional_material: ShaderMaterial
var foxlab_child_charmed = false

###新功能####
func charm_proj(proj: EnemyProjectile):
	_foxlab_original_additional_material = proj._sprite.material
	proj.set_collision_layer(Utils.PET_PROJECTILES_BIT)
	var new_shader: = projectile_shader.duplicate()
	new_shader.set_shader_param("hue", Utils.CHARM_COLOR.h)
	proj.set_sprite_material(new_shader)

func uncharm_proj(proj: EnemyProjectile):
	proj.set_collision_layer(proj._original_collision_layer)
	proj.set_sprite_material(_foxlab_original_additional_material)

###扩展####
func charm(from_player_index: int) -> void :
	.charm(from_player_index)
	if foxlab_child_charmed:
		return

	foxlab_child_charmed = true
	for additional_proj in _parent._all_additional_projectiles:
		charm_proj(additional_proj)
	if _parent.enemy_id == "":
		var proj:EnemyProjectile = _parent.get_node("Pivot/EnemyProjectile")
		if proj:
			charm_proj(proj)

	if _parent is Boss:
		_charm_timer.start(max(_parent._entity_spawner_ref._wave_timer.time_left - 5, Utils.CHARM_DURATION))

func uncharm() -> void :
	.uncharm()
	if not foxlab_child_charmed:
		return
	foxlab_child_charmed = false
	for additional_proj in _parent._all_additional_projectiles:
		uncharm_proj(additional_proj)
	if _parent.enemy_id == "":
		var proj:EnemyProjectile = _parent.get_node("Pivot/EnemyProjectile")
		if proj:
			uncharm_proj(proj)
