extends "res://singletons/item_service.gd"

######## 全局杀敌 ######
var foxlab_kill_nearby_icon;

######## 武器池 ########
var foxlab_pet_structure_stats_added = false
var foxlab_weapons_spawning_structure = {}
var foxlab_weapon_spawning_pet = [] #原版没有召唤宠物的武器，浅陌造物有

######### 面具相关 ############
var foxlab_transform_characters:Array=[]
var foxlab_vanilla_characters:Array=[]

const FOXLAB_MOD_NAME = "JonathanFox-FoxLab"
var foxlab_is_android = false
var foxlab_mod = null

func _ready() -> void :
	call_deferred("_foxlab_init_resources")
	call_deferred("_foxlab_init_configs")
	call_deferred("_foxlab_init_enemies")


func _foxlab_init_resources():
	foxlab_kill_nearby_icon = get_element(items, Utils.item_foxlab_inner_indomitable_hash).icon

func _foxlab_init_configs():
	var ModsConfigInterface = get_node_or_null("/root/ModLoader/dami-ModOptions/ModsConfigInterface")
	foxlab_mod = get_node_or_null("/root/ModLoader/" + FOXLAB_MOD_NAME)
	foxlab_is_android = foxlab_mod.IS_ANDROID
	DebugService.log_data("run on andriod: " + str(foxlab_is_android))
	if ModsConfigInterface:
		ModsConfigInterface.connect("setting_changed", self, "_on_setting_changed")
		call_deferred("_foxlab_init_transform_characters")

func _on_setting_changed(setting_name, _value, mod_name)->void :
	if mod_name == FOXLAB_MOD_NAME and setting_name == "FOXLAB_TRANSFORM_VANILLA_ONLY":
		_foxlab_init_transform_characters()

func _foxlab_init_transform_characters():
	if not foxlab_mod.is_transform_vanilla_only():
		foxlab_transform_characters = characters
		#DebugService.log_data("item service _foxlab_init_transform_characters done, all")
		return
	if foxlab_vanilla_characters.empty():
		for character in characters:
			if "res://items/" in character.resource_path or "res://dlcs/" in character.resource_path:
				foxlab_vanilla_characters.append(character)
	foxlab_transform_characters = foxlab_vanilla_characters
	#DebugService.log_data("_foxlab_init_transform_characters done, vanilla only")

func get_foxlab_transform_characters() -> Array:
	if foxlab_transform_characters.empty():
		_foxlab_init_transform_characters()
	return foxlab_transform_characters


######## 建造者的炮塔相关 ###############
var foxlab_builder_turret_scatter : Array = [null, null, null, null]

# 玩家第一个建造者的炮塔会居中，其他炮塔除非有group_structure，不然是随机分布的
func foxlab_get_builder_turret_at_level(new_level: int, player_index: int)-> ItemData:
	if RunData.get_nb_item(Keys.item_builder_turret_n_hash[new_level], player_index) == 0:
		return get_element(items, Keys.item_builder_turret_n_hash[new_level]) as ItemData
	if  foxlab_builder_turret_scatter[new_level] == null:
		foxlab_builder_turret_scatter[new_level] = get_element(items, Keys.item_builder_turret_n_hash[new_level]).duplicate()
		for i in range(foxlab_builder_turret_scatter[new_level].effects.size()):
			var effect = foxlab_builder_turret_scatter[new_level].effects[i]
			if effect is BuilderTurretEffect:
				effect = effect.duplicate()
				effect.spawn_in_center = -1
				foxlab_builder_turret_scatter[new_level].effects[i] = effect
				break
	return foxlab_builder_turret_scatter[new_level]


####### 变异相关 ##############
const FOXLAB_BOSS_CHANCE := 0.06
const FOXLAB_CHARM_CHANCE := 0.03
var foxlab_enemies = []
var foxlab_die_args = Entity.DieArgs.new()
const FOXLAB_PLAYER_HP_BOOST = 20
var foxlab_player_boost_args = BoostArgs.new()
var foxlab_enemy_boost_args = BoostArgs.new()
func _foxlab_init_enemies():
	foxlab_die_args.cleaning_up = true
	foxlab_die_args.enemy_killed_by_player = false
	foxlab_die_args.killed_by_player_index = - 1
	foxlab_player_boost_args.speed_boost = 20
	foxlab_player_boost_args.attack_speed_boost = 20
	foxlab_enemy_boost_args.hp_boost = 150
	foxlab_enemy_boost_args.damage_boost = 25
	foxlab_enemy_boost_args.speed_boost = 50

func foxlab_has_node_with_name(packed_scene: PackedScene, node_name: String) -> bool:
	var state = packed_scene.get_state()
	for i in range(state.get_node_count()):
		if state.get_node_name(i) == node_name:
			return true
	return false

func foxlab_get_enemy_from_item(enemy:Resource):
	var enemy_path:String = enemy.resource_path.trim_suffix("_item.tres")
	var scene_path:String = enemy_path + ".tscn"
	var scene:PackedScene = load(scene_path)
	if scene == null:
		#print("%s doesn't exist. enemy item: %s" % [scene_path, enemy.resource_path])
		return
	if not foxlab_has_node_with_name(scene, "Boss"):
		foxlab_enemies.append(scene)
		#print(scene_path)

func foxlab_random_enemies() -> Array:
	if not foxlab_enemies.empty():
		return foxlab_enemies
	for entity in entities:
		if not entity is ItemEnemy or entity.is_elite or entity.is_boss:
			continue
		foxlab_get_enemy_from_item(entity)
	foxlab_enemies.append(load("res://entities/units/enemies/corrupted_tree/corrupted_tree.tscn") as PackedScene)
	return foxlab_enemies

func foxlab_should_spawn_new_boss(boss_spawned_this_wave: int, player_index: int):
	var nb_reactor = max(1, RunData.get_nb_item(Utils.item_foxlab_reactor_hash, player_index))
	var boss_factor = boss_spawned_this_wave / nb_reactor
	return (boss_factor < (1 + max(0, (RunData.current_wave -3 ) / 10)) and Utils.get_chance_success(FOXLAB_BOSS_CHANCE / (1 + boss_factor)))

func foxlab_spawn_random_enemy(enemy: Enemy, boss_spawned_this_wave: int, player_index: int) -> int:
	var new_boss_num = 0
	var charmed_by = player_index if Utils.get_chance_success(FOXLAB_CHARM_CHANCE) else enemy.get_charmed_by_player_index()
	var pos = ZoneService.get_rand_pos_in_area(Vector2(enemy.global_position.x, enemy.global_position.y), 200)
	if enemy is Boss or foxlab_should_spawn_new_boss(boss_spawned_this_wave, player_index):
		# 最终BOSS不能被变异
		if enemy is Boss and not enemy.is_elite:
			return new_boss_num
		var enemy_data = null
		if RunData.current_wave >= 13 and Utils.get_chance_success(FOXLAB_BOSS_CHANCE):
			enemy_data = Utils.get_rand_element(bosses)
		else:
			enemy_data = Utils.get_rand_element(elites)
		var main = Utils.get_scene_node()
		for _player_index in RunData.get_player_count():
			var player =  main._players[_player_index]
			if not player._pending_die and Utils.get_stat(Keys.stat_max_hp_hash, _player_index) > 0:
				if player.is_boosted:
					player._boost_timer.start()
					continue
				var max_hp = player.max_stats.health as float
				# 最少增加20点血量
				if max_hp * (FOXLAB_PLAYER_HP_BOOST / 100.0) < FOXLAB_PLAYER_HP_BOOST:
					foxlab_player_boost_args.hp_boost = ((max_hp + FOXLAB_PLAYER_HP_BOOST) / max_hp - 1) * 100
				else:
					foxlab_player_boost_args.hp_boost = FOXLAB_PLAYER_HP_BOOST
				player.boost(foxlab_player_boost_args)
				player.emit_signal("stats_boosted", player)

		var floating_text_manager = main._floating_text_manager
		if not enemy is Boss:
			var icon = get_element(icons, Keys.icon_elite_hash).icon
			var player_position = floating_text_manager.players[player_index].global_position
			floating_text_manager.display_icon(1, icon, floating_text_manager.stat_pos_sounds, \
				floating_text_manager.stat_neg_sounds, player_position, floating_text_manager.direction, -10.0)
			new_boss_num = 1
			RunData.add_tracked_value(player_index, Utils.item_foxlab_reactor_hash, 1, 1)
		else:
			floating_text_manager.display("FOXLAB_RESURRECT", enemy.global_position)
			RunData.add_tracked_value(player_index, Utils.item_foxlab_reactor_hash, 1, 2)
		enemy.emit_signal("wanted_to_spawn_an_enemy", enemy_data.scene, pos, enemy, charmed_by)
	else:
		enemy.emit_signal("wanted_to_spawn_an_enemy", Utils.get_rand_element(foxlab_random_enemies()), pos, enemy,charmed_by)

	enemy.can_drop_loot = false
	enemy.call_deferred("die", foxlab_die_args)
	return new_boss_num

func foxlab_add_pet_structure_stats():
	if not foxlab_pet_structure_stats_added:
		_foxlab_modify_items_tag()
		_foxlab_record_spawning_weapons()
		foxlab_pet_structure_stats_added = true

func _foxlab_modify_items_tag():
	for item in items:
		if not "structure" in item.tags and item.is_structure_item():
			item.tags.append("structure")
		if not "pet" in item.tags and item.is_pet_item():
			item.tags.append("pet")

func _foxlab_record_spawning_weapons():
	for weapon in weapons:
		if weapon.is_structure_item():
			foxlab_weapons_spawning_structure[weapon.weapon_id_hash] = 1
		if weapon.is_pet_item():
			foxlab_weapon_spawning_pet.push_back([weapon, 0])

####### 扩展 ###########
func get_recycling_value(wave: int, from_value: int, player_index: int, is_weapon: bool = false, affected_by_items_price_stat: bool = true) -> int:
	# 游戏本身bug，回收带有 specific_items_price 的武器时，如果道具价格低于-100%，导致负负得正，原因是没有乘以 specific_items_price/100
	# ui/menus/shop/item_popup.gd ui/menus/shop/base_shop.gd
	return .get_recycling_value(wave, max(1, from_value) as int, player_index, is_weapon, affected_by_items_price_stat)

var foxlab_just_enter_shop = [true, true, true, true]
func get_player_shop_items(wave: int, player_index: int, args: ItemServiceGetShopItemsArgs) -> Array:
	if not foxlab_just_enter_shop[player_index]:
		args.increase_tier += RunData.get_player_effect(Utils.foxlab_increase_tier_on_rerolls_hash, player_index) + \
							min(1, RunData.get_player_effect(Utils.foxlab_buy_item_increase_tier_current_hash, player_index))
	return .get_player_shop_items(wave, player_index, args)

var FOXLAB_BANNED_ITEM_NAMES_EARLIER = [Keys.generate_hash("item_foxlab_slow_and_steady_wins"), Keys.generate_hash("item_foxlab_spacetime_anchor")]
var foxlab_banned_items_earlier = []
func _get_rand_item_for_wave(wave: int, player_index: int, type: int, args: GetRandItemForWaveArgs):
	if wave < 13 and type == TierData.ITEMS:
		if foxlab_banned_items_earlier.empty():
			for item_name in FOXLAB_BANNED_ITEM_NAMES_EARLIER:
				foxlab_banned_items_earlier.push_back([get_item_from_id(item_name), 0])
		args.excluded_items.append_array(foxlab_banned_items_earlier)

	if type == TierData.WEAPONS and RunData.get_player_effect(Keys.remove_shop_items_hash, player_index).has(Keys.pet_hash):
		args.excluded_items.append_array(foxlab_weapon_spawning_pet)

	return ._get_rand_item_for_wave(wave, player_index, type, args)

func get_upgrades(level: int, number: int, old_upgrades: Array, player_index: int) -> Array:
	var upgrades = .get_upgrades(level, number, old_upgrades, player_index)
	if not RunData.get_player_effect_bool(Utils.foxlab_item_upgrade_hash, player_index):
		return upgrades

	var owned_items: Array = RunData.get_player_items(player_index)
	for locked_item in RunData.get_player_locked_shop_items(player_index):
		if locked_item[0] is ItemData:
			owned_items.push_back(locked_item[0])
	var args: = GetRandItemForWaveArgs.new()
	args.owned_and_shop_items = owned_items
	for upgrade in old_upgrades:
		if upgrade.has_meta("foxlab_item"):
			args.excluded_items.push_back([upgrade.get_meta("foxlab_item"), 0])
	var items_ret = []
	var stats_upgrade_map = Utils.foxlab_get_primary_stat_level_up_map()[1]
	for base_upgrade in upgrades:
		if not base_upgrade.upgrade_id_hash in stats_upgrade_map:
			items_ret.append(base_upgrade)
		else:
			args.fixed_tier = base_upgrade.tier
			var item = _get_rand_item_for_wave(level, player_index, TierData.ITEMS, args)
			args.excluded_items.push_back([item, 0])
			var upgrade = UpgradeData.new()
			upgrade.icon = item.icon
			upgrade.deserialize_and_merge(item.serialize())
			upgrade.upgrade_id = item.my_id
			upgrade.upgrade_id_hash = item.my_id_hash
			upgrade.set_meta("foxlab_item", item)
			items_ret.append(upgrade)
	return items_ret
