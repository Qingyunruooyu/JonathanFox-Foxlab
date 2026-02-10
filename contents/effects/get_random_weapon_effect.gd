class_name FoxLabGetRandWeaponEffect
extends "res://items/global/effect.gd"

const CHANCE_EQUIPPED_WEAPON: float = 0.10
const CHANCE_LEGENDARY_ITEM: float = 0.05
const CHANCE_BOOST_MELEE: float = 0.20
const CHANCE_CONST_WEAPON: float = 0.01
const MAX_BONUS_CHANCE: float = 0.25
const VALUE_BASE: int = 1
# item_axolotl, item_goldfish, item_mirror, item_anvil， weapon_captains_sword_3, weapon_stick_1
# item_foxlab_buddhas_hand, item_foxlab_mask, "item_hourglass"
var debug_item_name: Array = []

static func get_id() -> String:
	return "foxlab_effect_get_rand_weapon"

func try_generate(player_index: int):
	var is_cursed:int = value != VALUE_BASE
	var meta = RunData.get_foxlab_buddhas_hand_meta(player_index)[is_cursed]
	if meta.weapon_id.empty():
		RunData.get_foxlab_buddhas_hand_weapon(player_index)[is_cursed] = _get_rand_weapon(player_index)

func apply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	# [佛手堆栈数，正在佛手否]
	var stack_effect:Array = effects[Utils.foxlab_buddhas_hand_stack_hash]
	if stack_effect[1]:
		stack_effect[0] += 1
		return
	stack_effect[1] = true

	try_generate(player_index)
	var is_cursed:int = value != VALUE_BASE
	var meta = RunData.get_foxlab_buddhas_hand_meta(player_index)[is_cursed]
	RunData.add_weapon(RunData.get_foxlab_buddhas_hand_weapon(player_index)[is_cursed], player_index)
	if meta.is_const_weapon:
		RunData.add_tracked_value(player_index, Utils.item_foxlab_buddhas_hand_hash, 1)
	var item_to_get:Array = RunData.get_foxlab_buddhas_hand_item(player_index)
	if  item_to_get[is_cursed]!= null:
		RunData.add_item(item_to_get[is_cursed], player_index)
		item_to_get[is_cursed] = null
	meta.weapon_id = ""

	_after_buddhas_hand(player_index, stack_effect)

func _after_buddhas_hand(player_index: int, stack_effect: Array) -> void:
	stack_effect[1] = false
	if stack_effect[0] > 0:
		stack_effect[0] -= 1
		apply(player_index)

func unapply(_player_index: int) -> void:
	pass


func get_args(player_index: int) -> Array:
	if RunData.get_player_character(player_index) == null:
		return [tr("FOXLAB_RANDOM"), tr("FOXLAB_RANDOM"), tr("EFFECT_FOXLAB_BUDDHAS_HAND_HINT")]
	try_generate(player_index)
	var is_cursed:int = value != VALUE_BASE
	var meta = RunData.get_foxlab_buddhas_hand_meta(player_index)[is_cursed]
	return [
			meta.weapon_id, meta.extra_item_id,\
			tr("EFFECT_FOXLAB_BUDDHAS_HAND_CONST") if meta.is_const_weapon else tr("EFFECT_FOXLAB_BUDDHAS_HAND_BRICK")
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

	var is_cursed:int = value != VALUE_BASE
	var meta = RunData.get_foxlab_buddhas_hand_meta(player_index)[is_cursed]
	var item_to_get:Array = RunData.get_foxlab_buddhas_hand_item(player_index)

	if not item_for_effect.get_category() == Category.WEAPON:
		if item_for_effect.replaced_by:
			item_to_get[is_cursed] = item_for_effect
		else:
			for effect in item_for_effect.effects:
				if effect.key_hash != item_for_effect.my_id_hash:
					continue
				if effect.custom_key_hash == Keys.duplicate_item_hash or effect.custom_key_hash == Keys.increase_tier_on_reroll_hash or effect.key_hash == Keys.item_hourglass_hash:
					item_to_get[is_cursed] = item_for_effect
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
		elif effect is SwapMaxMinStatEffect: # axolotl
			effect.stats_swapped = effect._find_min_max_stat_keys(player_index)
		elif effect is PercentDamageEffect: # lute, icecube, etc
			effect.source_id = weapon.weapon_id
			effect.source_id_hash = weapon.weapon_id_hash
		elif effect.custom_key == "yztato_destory_weapons":
			effect.key = weapon.weapon_id
			effect.key_hash = weapon.weapon_id_hash
		elif effect.get_id() == get_id():
			effect.debug_item_name = []

	item_for_effect.effects = new_effects

	if item_to_get[is_cursed] == null:
		weapon.effects.append_array(item_for_effect.effects)

	meta.weapon_id = "%s %s" % [tr(weapon.name), ItemService.get_tier_number(weapon.tier)]
	if weapon.is_cursed:
		meta.weapon_id += "([color=#%s]%s[/color])" % [Utils.CURSE_COLOR.to_html(), tr("FOXLAB_CURSED_TEXT")]

	if item_for_effect is WeaponData:
		meta.extra_item_id = "%s %s" % [tr(item_for_effect.name), ItemService.get_tier_number(item_for_effect.tier)]
	else:
		meta.extra_item_id = tr(item_for_effect.name)

	if item_for_effect.is_cursed:
		meta.extra_item_id += "([color=#%s]%s[/color])" % [Utils.CURSE_COLOR.to_html(), tr("FOXLAB_CURSED_TEXT")]

	meta.is_const_weapon = 1
	if !_get_chance_success(CHANCE_CONST_WEAPON, luck_chance):
		var level_suffix := "" if weapon.tier == 0 else ("_%d" % [weapon.tier + 1])
		var break_effect := load("res://dlcs/dlc_1/weapons/melee/brick/%d/brick%s_effect_0.tres" % [weapon.tier + 1, level_suffix])
		weapon.effects.append(break_effect)
		meta.extra_item_id += "([color=#%s]+%s[/color])" % [ ProgressData.settings.color_negative, tr("WEAPON_BRICK")]
		meta.is_const_weapon = 0
	elif item_to_get[is_cursed] == null:
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


