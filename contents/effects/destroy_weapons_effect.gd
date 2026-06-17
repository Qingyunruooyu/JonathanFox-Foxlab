extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "foxlab_destroy_weapons"

func apply(player_index: int) -> void:
	var weapons_ref = RunData.get_player_weapons_ref(player_index)
	if weapons_ref.empty():
		return

	var remained_weapon: WeaponData = Utils.get_rand_element(weapons_ref)
	var new_cursed_weapon_min_factor = 0.0
	var effects = []
	var curse_new_weapon = false
	var useless_weapon_num = 0
	for weapon in weapons_ref:
		if weapon.is_cursed:
			curse_new_weapon = true
			for effect in weapon.effects:
				new_cursed_weapon_min_factor = max(new_cursed_weapon_min_factor, effect.curse_factor)
		if weapon != remained_weapon:
			var is_useless = true
			for effect in weapon.effects:
				# 只是显示作用
				if effect is SlowInZoneEffect or effect is PlayerNoHitEffect or\
					((effect.key_hash == Keys.bounce_on_crit_hash or effect.key_hash == Keys.pierce_on_crit_hash)\
					and remained_weapon.type == WeaponData.Type.MELEE):
					continue
				is_useless = false
				effects.append(effect)
			if is_useless:
				useless_weapon_num += 1
	RunData.remove_all_weapons(player_index)
	if useless_weapon_num > 0:
		RunData.add_stat(Keys.trees_hash, useless_weapon_num, player_index)

	# 升满
	while remained_weapon.upgrades_into != null:
		remained_weapon = remained_weapon.upgrades_into
	# 村好剑等特殊升级武器，直接检索
	if remained_weapon.tier < Tier.LEGENDARY:
		for weapon in ItemService.weapons:
			if weapon.weapon_id_hash == remained_weapon.weapon_id_hash and weapon.tier == Tier.LEGENDARY:
				remained_weapon = weapon
				break

	# 选中的武器是诅咒版，需要在下面重新诅咒
	if remained_weapon.is_cursed and remained_weapon.tier == Tier.LEGENDARY:
		remained_weapon = ItemService.get_element(ItemService.weapons, remained_weapon.my_id_hash)

	remained_weapon = remained_weapon.duplicate()
	var adjusted_effects = remained_weapon.effects.duplicate()
	for effect in effects:
		adjusted_effects.append(effect.duplicate())
		RunData.foxlab_adjust_weapon_effect(adjusted_effects.back(), remained_weapon)

	remained_weapon.effects = adjusted_effects
	if curse_new_weapon:
		for dlc_id in RunData.enabled_dlcs:
			var dlc_data = ProgressData.get_dlc_data(dlc_id)
			if dlc_data and dlc_data.has_method("curse_item"):
				remained_weapon = dlc_data.curse_item(remained_weapon, player_index, false, new_cursed_weapon_min_factor)
	RunData.add_weapon(remained_weapon, player_index)
	RunData.emit_signal("foxlab_item_added", remained_weapon, 1, player_index)
	SoundManager.play(preload("res://resources/sounds/metal_small_movement_03.wav"))

func unapply(_player_index: int) -> void:
	pass
