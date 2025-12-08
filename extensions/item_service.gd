extends "res://singletons/item_service.gd"

######### 面具相关 ############
var foxlab_transform_characters:Array=[]
var foxlab_vanilla_characters:Array=[]

const FOXLAB_MOD_NAME = "JonathanFox-FoxLab"

var ModsConfigInterface = null

# 面具的配置相关
const FOXLAB_DEFAULT_SETTINGS: = {
	"FOXLAB_TRANSFORM_VANILLA_ONLY": false
}

var foxlab_config = null
var foxlab_current_settings: Dictionary = FOXLAB_DEFAULT_SETTINGS.duplicate()

func is_transform_vanilla_only():
	return foxlab_current_settings["FOXLAB_TRANSFORM_VANILLA_ONLY"]

func _ready() -> void :
	call_deferred("_init_configs")
	call_deferred("_init_enemies")

func _init_configs():
	ModsConfigInterface = get_node_or_null("/root/ModLoader/dami-ModOptions/ModsConfigInterface")
	var CONFIG_NAME = "foxlab_config"
	var configs = ModLoaderConfig.get_configs(FOXLAB_MOD_NAME)
	if configs.has(CONFIG_NAME):
		foxlab_config = ModLoaderConfig.get_config(FOXLAB_MOD_NAME, CONFIG_NAME)
	else:
		foxlab_config = ModLoaderConfig.create_config(FOXLAB_MOD_NAME, CONFIG_NAME, FOXLAB_DEFAULT_SETTINGS)

	if foxlab_config:
		var _error_config = ModLoaderConfig.update_config(foxlab_config)
		var data = foxlab_config.data

		for key in foxlab_current_settings.keys():
			foxlab_current_settings[key] = data[key]

	if ModsConfigInterface:
		ModsConfigInterface.connect("setting_changed", self, "_on_setting_changed")
		call_deferred("_init_settings")

func _init_settings() -> void:
	for key in foxlab_current_settings.keys():
		ModsConfigInterface.on_setting_changed(key, foxlab_current_settings[key], FOXLAB_MOD_NAME)
	_init_foxlab_transform_characters()

func _on_setting_changed(setting_name, value, mod_name)->void :
	if mod_name == FOXLAB_MOD_NAME:
		foxlab_current_settings[setting_name] = value

		if foxlab_config:
			foxlab_config.data[setting_name] = value
			var _error_config = ModLoaderConfig.update_config(foxlab_config)
		if setting_name == "FOXLAB_TRANSFORM_VANILLA_ONLY":
			_init_foxlab_transform_characters()

func _init_foxlab_transform_characters():
	if not is_transform_vanilla_only():
		foxlab_transform_characters = characters
		DebugService.log_data("item service _init_foxlab_transform_characters done, all")
		return
	if foxlab_vanilla_characters.empty():
		for character in characters:
			if "res://items/" in character.resource_path or "res://dlcs/" in character.resource_path:
				foxlab_vanilla_characters.append(character)
	foxlab_transform_characters = foxlab_vanilla_characters
	DebugService.log_data("_init_foxlab_transform_characters done, vanilla only")

func get_foxlab_transform_characters() -> Array:
	if foxlab_transform_characters.empty():
		_init_foxlab_transform_characters()
	return foxlab_transform_characters


######## 建造者的炮塔相关 ###############

const foxlab_builder_turret_names : Array = ["item_builder_turret_0", "item_builder_turret_1", "item_builder_turret_2", "item_builder_turret_3"]

var foxlab_builder_turret_scatter : Array = [null, null, null, null]

# 玩家第一个建造者的炮塔会居中，其他炮塔除非有group_structure，不然是随机分布的
func foxlab_get_builder_turret_at_level(new_level: int, player_index: int)-> ItemData:
	if RunData.get_nb_item(foxlab_builder_turret_names[new_level], player_index) == 0:
		return get_element(items, foxlab_builder_turret_names[new_level]) as ItemData
	if  foxlab_builder_turret_scatter[new_level] == null:
		foxlab_builder_turret_scatter[new_level] = get_element(items, foxlab_builder_turret_names[new_level]).duplicate()
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
var FOXLAB_IS_NEW_DAWN = "1.1.13" in CrashReporter.VERSION
var foxlab_enemies = []
var foxlab_die_args = Entity.DieArgs.new()
var foxlab_player_boost_args = BoostArgs.new()
var foxlab_enemy_boost_args = BoostArgs.new()
func _init_enemies():
	foxlab_die_args.cleaning_up = true
	foxlab_die_args.enemy_killed_by_player = false
	foxlab_die_args.killed_by_player_index = - 1
	foxlab_player_boost_args.hp_boost = 20
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

func foxlab_random_enemies() -> Array:
	if not foxlab_enemies.empty():
		return foxlab_enemies

	if FOXLAB_IS_NEW_DAWN:
		for enemy in ItemService.enemies:
			var enemy_path:String = enemy.resource_path.trim_suffix("_item.tres")
			var scene_path:String = enemy_path + ".tscn"
			var scene:PackedScene = load(scene_path)
			if scene == null:
				#DebugService.log_data("%s doesn't exist. enemy item: %s" % [scene_path, enemy.resource_path])
				continue
			if not foxlab_has_node_with_name(scene, "Boss"):
				foxlab_enemies.append(scene)
				#DebugService.log_data(scene_path)
	else:
		for zone_data in ZoneService.zones:
#			DebugService.log_data(zone_data.resource_path)
			var waves_data:Array = zone_data.waves_data
			for wave_data in waves_data:
#				DebugService.log_data(wave_data.resource_path)
				var groups_data:Array = wave_data.groups_data
				for group_data in groups_data:
					if group_data.is_boss or group_data.is_neutral:
						continue
#					DebugService.log_data(group_data.resource_path)
					var wave_units_data:Array = group_data.wave_units_data
					for unit_data in wave_units_data:
#						DebugService.log_data(unit_data.resource_path)
						if not unit_data.unit_scene in foxlab_enemies:
							foxlab_enemies.append(unit_data.unit_scene)
	return foxlab_enemies

func foxlab_spawn_random_enemy(enemy: Enemy, boss_spawned_this_wave: int, player_index: int) -> int:
	var enemy_scene: PackedScene = null
	var new_boss_num = 0
	if enemy is Boss or (boss_spawned_this_wave < (1 + max(0, (RunData.current_wave -3 ) / 10)) and Utils.get_chance_success(FOXLAB_BOSS_CHANCE / (1 + boss_spawned_this_wave))):
		# 最终BOSS不能被变异
		if enemy is Boss and not enemy.is_elite:
			return new_boss_num
		var enemy_data: EnemyData = null
		if RunData.current_wave >= 13 and Utils.get_chance_success(FOXLAB_BOSS_CHANCE):
			enemy_data = Utils.get_rand_element(ItemService.bosses)
		else:
			enemy_data = Utils.get_rand_element(ItemService.elites)
		enemy_scene = enemy_data.scene
		var main:Main = Utils.get_scene_node()
		for player_index in RunData.get_player_count():
			var player: Player =  main._players[player_index]
			if is_instance_valid(player) and not player.dead:
				if player.is_boosted:
					player._boost_timer.start()
					continue
				var boost_args = BoostArgs.new()
				boost_args.speed_boost = foxlab_player_boost_args.speed_boost
				boost_args.attack_speed_boost = foxlab_player_boost_args.attack_speed_boost
				var max_hp = player.max_stats.health as float
				# 最少增加20点血量
				if max_hp > 0 and max_hp * (foxlab_player_boost_args.hp_boost / 100.0) < foxlab_player_boost_args.hp_boost:
					boost_args.hp_boost = ((max_hp + foxlab_player_boost_args.hp_boost) / max_hp - 1) * 100
				else:
					boost_args.hp_boost = foxlab_player_boost_args.hp_boost
				player.boost(boost_args)
				player.emit_signal("stats_boosted", player)
		if main.has_node("FloatingTextManager"):
			var floating_text_manager:FloatingTextManager = main.get_node("FloatingTextManager")
			if not enemy is Boss:
				var icon = ItemService.get_element(ItemService.icons, "icon_elite").icon
				var player_position = floating_text_manager.players[player_index].global_position
				floating_text_manager.display_icon(1, icon, floating_text_manager.stat_pos_sounds, floating_text_manager.stat_neg_sounds, player_position, floating_text_manager.direction, -10.0)
				new_boss_num = 1
			else:
				floating_text_manager.display("FOXLAB_RESURRECT", enemy.global_position)
	else:
		enemy_scene = Utils.get_rand_element(foxlab_random_enemies())

	enemy.emit_signal("wanted_to_spawn_an_enemy", enemy_scene, ZoneService.get_rand_pos_in_area(Vector2(enemy.global_position.x,
	enemy.global_position.y), 200), enemy, player_index if Utils.get_chance_success(FOXLAB_CHARM_CHANCE) else enemy.get_charmed_by_player_index())
	enemy.can_drop_loot = false
	enemy.die(foxlab_die_args)
	return new_boss_num


####### 扩展 ###########
func get_recycling_value(wave: int, from_value: int, player_index: int, is_weapon: bool = false, affected_by_items_price_stat: bool = true) -> int:
	# 游戏本身bug，回收带有 specific_items_price 的武器时，如果道具价格低于-100%，导致负负得正，原因是没有乘以 specific_items_price/100
	# ui/menus/shop/item_popup.gd ui/menus/shop/base_shop.gd
	return .get_recycling_value(wave, max(1, from_value), player_index, is_weapon, affected_by_items_price_stat)

var foxlab_just_enter_shop = [true, true, true, true]
func get_player_shop_items(wave: int, player_index: int, args: ItemServiceGetShopItemsArgs) -> Array:
	if not foxlab_just_enter_shop[player_index]:
		args.increase_tier += RunData.get_player_effect("foxlab_increase_tier_on_rerolls", player_index)
	return .get_player_shop_items(wave, player_index, args)
