class_name FoxLabGetRandWeaponEffect
extends "res://items/global/effect.gd"

const CHANCE_EQUIPPED_WEAPON: float = 0.10
const CHANCE_LEGENDARY_ITEM: float = 0.05
const CHANCE_BOOST_MELEE: float = 0.20
const CHANCE_CONST_WEAPON: float = 0.01
const MAX_BONUS_CHANCE: float = 0.25
# item_axolotl, item_goldfish, item_mirror, item_anvil， weapon_captains_sword_3, weapon_stick_1
# item_foxlab_buddhas_hand, item_foxlab_mask, "item_hourglass"
var debug_item_name: Array = []

var weapon_to_get: Array = [null, null, null, null]
var item_to_get: Array = [null, null, null, null] # for special item effect (duplicate_item, increase_tier_on_reroll, item_hourglass)

var weapon_id: Array = ["","","",""]
var extra_item_id: Array = ["","","",""]
var is_const_weapon: Array = [0, 0, 0, 0]

static func get_id() -> String:
	return "foxlab_effect_get_rand_weapon"

func try_generate(player_index: int):
	var first_generate = RunData.get_player_effect_bool(Utils.foxlab_buddhas_hand_first_generate_hash, player_index)
	if weapon_id[player_index].empty() or first_generate:
		weapon_to_get[player_index] = _get_rand_weapon(player_index)
		if first_generate:
			RunData.get_player_effects(player_index)[Utils.foxlab_buddhas_hand_first_generate_hash] = 0
			DebugService.log_data("first generate buddha's hand")

func apply(player_index: int) -> void:
	try_generate(player_index)
	RunData.add_weapon(weapon_to_get[player_index], player_index)
	if is_const_weapon[player_index]:
		RunData.add_tracked_value(player_index, Utils.item_foxlab_buddhas_hand_hash, 1)
	if item_to_get[player_index] != null:
		RunData.add_item(item_to_get[player_index], player_index)
		item_to_get[player_index] = null
	weapon_id[player_index] = ""

func unapply(_player_index: int) -> void:
	pass


func get_args(player_index: int) -> Array:
	if RunData.get_player_character(player_index) == null:
		return [tr("FOXLAB_RANDOM"), tr("FOXLAB_RANDOM"), ""]
	try_generate(player_index)
	return [
			weapon_id[player_index],\
			extra_item_id[player_index],\
			tr("EFFECT_FOXLAB_BUDDHAS_HAND_CONST") if is_const_weapon[player_index] else tr("EFFECT_FOXLAB_BUDDHAS_HAND_BRICK")
			]

func _get_chance_success(base_chance: float, luck_chance: float)->bool:
	return Utils.get_chance_success(min(MAX_BONUS_CHANCE, base_chance * luck_chance))

func _get_rand_weapon(player_index: int) -> WeaponData:
	var luck = Utils.get_stat(Keys.stat_luck_hash, player_index) / 100.0
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
	if RunData.get_nb_item(Keys.item_hourglass_hash, player_index) > 0:
		args.owned_and_shop_items.push_back(ItemService.get_element(ItemService.items, Keys.item_hourglass_hash))

	var weapon = null
	# chance to get the same weapon equiped
	if _get_chance_success(CHANCE_EQUIPPED_WEAPON, luck_chance) and RunData.get_player_weapons_ref(player_index).size() > 0:
		var ref_weapon = Utils.get_rand_element(RunData.get_player_weapons_ref(player_index))
		weapon = ItemService.get_element(ItemService.weapons, ref_weapon.my_id_hash).duplicate()
	else:
		weapon = ItemService._get_rand_item_for_wave(RunData.current_wave, player_index, ItemService.TierData.WEAPONS, args).duplicate()

	var is_melee_boosted = false
	if weapon.type ==  WeaponData.Type.MELEE and _get_chance_success(CHANCE_BOOST_MELEE, luck_chance):
		var melee_stats = weapon.stats.duplicate()
		melee_stats.deal_dmg_on_return = true
		weapon.stats = melee_stats
		is_melee_boosted = true

	var item_for_effect = null

	if !debug_item_name.empty():
		var debug_item:String = debug_item_name.pop_front()
		var debug_item_hash = Keys.generate_hash(debug_item)
		if debug_item.begins_with("weapon_"):
			item_for_effect = ItemService.get_element(ItemService.weapons, debug_item_hash)
		else:
			item_for_effect = ItemService.get_element(ItemService.items, debug_item_hash)
	if item_for_effect == null:
		item_for_effect = Utils.get_rand_element(ItemService.weapons)
	if item_for_effect.effects.empty():
		if _get_chance_success(CHANCE_LEGENDARY_ITEM, luck_chance):
			args.increase_tier = 3
			# items (except hourglass) can be get even if it may exceed the limited number
		item_for_effect = ItemService._get_rand_item_for_wave(RunData.current_wave, player_index, ItemService.TierData.ITEMS, args)

	if not item_for_effect.get_category() == Category.WEAPON:
		if item_for_effect.replaced_by:
			item_to_get[player_index] = item_for_effect
		else:
			for effect in item_for_effect.effects:
				if effect.key_hash != item_for_effect.my_id_hash:
					continue
				if effect.custom_key_hash == Keys.duplicate_item_hash or effect.custom_key_hash == Keys.increase_tier_on_reroll_hash or effect.key_hash == Keys.item_hourglass_hash:
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
			effect.weapon_stacked_id_hash = weapon.weapon_id_hash
		elif effect is WeaponGainStatForEveryStatEffect: # captain's sword
			if effect.stat_scaled_hash == Keys.free_weapon_slots_hash:
				effect.stat_scaled = "legendary_item"
				effect.stat_scaled_hash = Keys.legendary_item_hash
				effect.text_key = "EFFECT_GAIN_STAT_FOR_EVERY_DIFFERENT_STAT"
		elif effect is SwapMaxMinStatEffect: # axolotl
			effect.stats_swapped = effect._find_min_max_stat_keys(player_index)
		elif effect is PercentDamageEffect: # lute, icecube, etc
			effect.source_id = weapon.weapon_id
			effect.source_id_hash = weapon.weapon_id_hash
		elif effect.custom_key == "yztato_destory_weapons":
			effect.key = weapon.weapon_id
			effect.key_hash = weapon.weapon_id_hash
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

	is_const_weapon[player_index] = 1
	if !_get_chance_success(CHANCE_CONST_WEAPON, luck_chance):
		var level_suffix := "" if weapon.tier == 0 else ("_%d" % [weapon.tier + 1])
		var break_effect := load("res://dlcs/dlc_1/weapons/melee/brick/%d/brick%s_effect_0.tres" % [weapon.tier + 1, level_suffix])
		weapon.effects.append(break_effect)
		extra_item_id[player_index] += "([color=#%s]+%s[/color])" % [ ProgressData.settings.color_negative, tr("WEAPON_BRICK")]
		is_const_weapon[player_index] = 0
	elif item_to_get[player_index] == null:
		var current = weapon
		var upgrade_into = current.upgrades_into
		while upgrade_into != null:
			upgrade_into = upgrade_into.duplicate()
			upgrade_into.effects.append_array(item_for_effect.effects)
			if is_melee_boosted:
				upgrade_into.stats = upgrade_into.stats.duplicate()
				upgrade_into.stats.deal_dmg_on_return = true
			current.upgrades_into = upgrade_into
			current = upgrade_into
			upgrade_into = current.upgrades_into

	return weapon


