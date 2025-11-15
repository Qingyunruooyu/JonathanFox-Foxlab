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
