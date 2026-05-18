extends "res://entities/units/pet/jellyshield/jellyshield.gd"

func _on_Hurtbox_area_entered(hitbox: Area2D) -> void :
	var parent = hitbox.get_parent()
	# 是玩家投射物但是却是敌人投射物的掩码，会攻击玩家，但又不是治疗
	if parent is PlayerProjectile and (hitbox.collision_layer & Utils.ENEMY_PROJECTILES_BIT) and not parent._weapon_stats.is_healing:
		RunData.add_tracked_value(player_index, Keys.item_jellyshield_hash, 1)
		# 为什么不用hitbox.hit_something(self, 0)？
		# 因为JellyFish是Entity，不是Unit，玩家投射物会对thing_hit做add_deacying_speed（鱼叉枪等）、._entity_spawner_ref（反弹）等操作，Entity不支持
		parent.stop()
		_animation_player.play("hit")
		yield(_animation_player, "animation_finished")
		_animation_player.play("idle")
	else:
		._on_Hurtbox_area_entered(hitbox)
