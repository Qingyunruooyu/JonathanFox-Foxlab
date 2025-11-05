class_name GetRandWeaponEffect
extends Effect

export(int) var value_base = 1 # set to == value by default to indicate this effect is not cursed

const CHANCE_EQUIPPED_WEAPON: float = 0.10
const CHANCE_LEGENDARY_ITEM: float = 0.05
const CHANCE_BOOST_MELEE: float = 0.20
const CHANCE_CONST_WEAPON: float = 0.01
# item_axolotl, item_goldfish, item_mirror, item_anvil， weapon_captains_sword_3, weapon_stick_1
# item_brolab_佛手_422, item_brolab_面具_422, "item_hourglass"
var debug_item_name: Array = []

var weapon_to_get: Array = [null, null, null, null]
var item_to_get: Array = [null, null, null, null] # for special item effect (duplicate_item, increase_tier_on_reroll, item_hourglass)

var weapon_id: Array = ["","","",""]
var extra_item_id: Array = ["","","",""]

static func get_id() -> String:
	return "get_rand_weapon"


func apply(player_index: int) -> void:
	if weapon_id[player_index].empty():
		weapon_to_get[player_index] = _get_rand_weapon(player_index)
	RunData.add_weapon(weapon_to_get[player_index], player_index)
	if item_to_get[player_index] != null:
		RunData.add_item(item_to_get[player_index], player_index)
		item_to_get[player_index] = null
	if value_base == value: # not cursed
		weapon_id[player_index] = ""


func unapply(_player_index: int) -> void:
	pass


func get_args(player_index: int) -> Array:
	if RunData.get_player_character(player_index) == null:
		return [tr("FOXLAB_RANDOM"), tr("FOXLAB_RANDOM")]
	if weapon_id[player_index].empty():
		weapon_to_get[player_index] = _get_rand_weapon(player_index)
	
	return [weapon_id[player_index], extra_item_id[player_index]]

func _get_chance_success(base_chance: float, luck_chance: float)->bool:
	return Utils.get_chance_success(base_chance * luck_chance)

func _get_rand_weapon(player_index: int) -> WeaponData:
	var luck = Utils.get_stat("stat_luck", player_index) / 100.0
	var luck_chance:float = 1.0
	if luck >= 0:
		luck_chance = luck_chance * (1 + luck)
	else:
		luck_chance = luck_chance / (1 + abs(luck))
	if RunData.current_wave > RunData.nb_of_waves:
		luck_chance /= (1.0 + RunData.get_endless_factor())
	var args := ItemService.GetRandItemForWaveArgs.new()
	args.increase_tier = value - 1
	args.owned_and_shop_items = []
	var weapon :WeaponData = null
	# chance to get the same weapon equiped
	if _get_chance_success(CHANCE_EQUIPPED_WEAPON, luck_chance) and RunData.players_data[player_index].weapons.size() > 0:
		var ref_weapon :WeaponData= Utils.get_rand_element(RunData.players_data[player_index].weapons)
		weapon = ItemService.get_element(ItemService.weapons, ref_weapon.my_id).duplicate() as WeaponData
	else:
		weapon = ItemService._get_rand_item_for_wave(RunData.current_wave, player_index, ItemService.TierData.WEAPONS, args).duplicate() as WeaponData
	if weapon.type ==  WeaponData.Type.MELEE and _get_chance_success(CHANCE_BOOST_MELEE, luck_chance):
		var melee_stats:MeleeWeaponStats  = weapon.stats as MeleeWeaponStats
		melee_stats.deal_dmg_on_return = true	
	
	var item_for_effect :ItemParentData = null

	if !debug_item_name.empty():
		var debug_item:String = debug_item_name.front()
		if debug_item.begins_with("weapon_"):
			item_for_effect = ItemService.get_element(ItemService.weapons, debug_item)
			debug_item_name.pop_front()
		else:
			item_for_effect = ItemService.get_element(ItemService.items, debug_item)
			debug_item_name.pop_front()
	if item_for_effect == null:
		item_for_effect = Utils.get_rand_element(ItemService.weapons)	
	if item_for_effect.effects.empty():
		if _get_chance_success(CHANCE_LEGENDARY_ITEM, luck_chance):
			args.increase_tier = 3
			# items can be get even if it may exceed the limited number
		item_for_effect = ItemService._get_rand_item_for_wave(RunData.current_wave, player_index, ItemService.TierData.ITEMS, args)
	for effect in item_for_effect.effects:
		if effect.custom_key == "duplicate_item" or effect.custom_key == "increase_tier_on_reroll":
			item_to_get[player_index] = item_for_effect
			break
		elif effect.key == "item_hourglass" and RunData.get_nb_item("item_hourglass", player_index) == 0:
			item_to_get[player_index] = item_for_effect
			break

	item_for_effect = item_for_effect.duplicate()
	var new_effects := []
	for effect in item_for_effect.effects:
		effect = effect.duplicate()
		new_effects.append(effect)
		if effect is WeaponStackEffect: # stick
			effect.weapon_stacked_name = weapon.name
			effect.weapon_stacked_id = weapon.weapon_id
		elif effect is WeaponGainStatForEveryStatEffect: # captain's sword
			if effect.stat_scaled == "free_weapon_slots":
				effect.stat_scaled = "legendary_item"
				effect.text_key = "EFFECT_GAIN_STAT_FOR_EVERY_DIFFERENT_STAT"
		elif effect is SwapMaxMinStatEffect: # axolotl
			effect.stats_swapped = effect._find_min_max_stat_keys(player_index)
		elif effect is PercentDamageEffect: # lute, icecube, etc
			effect.source_id = weapon.weapon_id
		elif effect.custom_key == "yztato_destory_weapons":
			effect.key = weapon.weapon_id
			effect.text_key = "每波结束时，只保留%s" % [tr(weapon.name)]
		elif effect.get_id() == get_id():
			effect.weapon_id = ["","","",""]
			effect.debug_item_name = []


	item_for_effect.effects = new_effects
	
	if item_to_get[player_index] == null:
		weapon.effects.append_array(item_for_effect.effects)
		
	weapon_id[player_index] = "%s %s" % [tr(weapon.name), ItemService.get_tier_number(weapon.tier)]
	if weapon.is_cursed:
		weapon_id[player_index] += "([color=#%s]%s[/color])" % [Utils.CURSE_COLOR.to_html(), tr("FOXLAB_CURSED_TEXT")]
	
	if item_for_effect is WeaponData:
		extra_item_id[player_index] = "%s %s" % [tr(item_for_effect.name), ItemService.get_tier_number(item_for_effect.tier)]
	else:
		extra_item_id[player_index] = tr(item_for_effect.name)

	if item_for_effect.is_cursed:
		extra_item_id[player_index] += "([color=#%s]%s[/color])" % [Utils.CURSE_COLOR.to_html(), tr("FOXLAB_CURSED_TEXT")]
		
	if !_get_chance_success(CHANCE_CONST_WEAPON, luck_chance):
		var level_suffix := "" if weapon.tier == 0 else ("_%d" % [weapon.tier + 1])
		var break_effect := load("res://dlcs/dlc_1/weapons/melee/brick/%d/brick%s_effect_0.tres" % [weapon.tier + 1, level_suffix])
		weapon.effects.append(break_effect)
		var neg_color = ("#" + ProgressData.settings.color_negative) if ProgressData.settings.has("color_negative") else Utils.NEG_COLOR_STR
		extra_item_id[player_index] += "([color=%s]+%s[/color])" % [neg_color, tr("WEAPON_BRICK")]
	elif item_to_get[player_index] == null:
		var current = weapon
		var upgrade_into = current.upgrades_into
		while upgrade_into != null:
			upgrade_into = upgrade_into.duplicate()
			upgrade_into.effects.append_array(item_for_effect.effects)
			current.upgrades_into = upgrade_into
			current = upgrade_into
			upgrade_into = current.upgrades_into

	return weapon
	
func serialize() -> Dictionary:
	var serialized =.serialize()

	serialized.weapon_id = weapon_id
	serialized.extra_item_id = extra_item_id
	serialized.value_base = value_base

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	weapon_id = serialized.weapon_id if "weapon_id" in serialized else ""
	extra_item_id = serialized.extra_item_id if "extra_item_id" in serialized else ""
	value_base = serialized.value_base if "value_base" in serialized else 1
