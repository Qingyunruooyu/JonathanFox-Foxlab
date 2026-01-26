extends Node

# MOD配置
const MOD_NAME:="JonathanFox-FoxLab"
const MOD_PATH:="res://mods-unpacked/" + MOD_NAME + "/"
const FOXLAB_EXTENSION_DIR: = MOD_PATH + "extensions/"
const FOXLAB_TRANSLATION_DIR: = MOD_PATH + "translations/"
var IS_ANDROID:bool = false

const EXTENSION_SCRIPTS: =[
	"utils.gd",
	"item_service.gd",
	"run_data.gd",
	"player.gd",
	"player_run_data.gd",
	"main.gd",
	"base_shop.gd",
	"item_panel_ui.gd",
	"upgrades_ui_player_container.gd",
	"shop_item.gd",
	"floating_text_manager.gd",
	"entity_spawner.gd",
	"entity_service.gd",
	"linked_stats.gd",
	"upgrades_ui.gd",
	"weapon_service.gd",
	"character_panel_ui.gd",
	"memu_confirm.gd",
]


var ModsConfigInterface = null
const DEFAULT_SETTINGS: = {
	"FOXLAB_TRANSFORM_VANILLA_ONLY": false,
	"FOXLAB_DISABLE_CHARACTERS": false,
	"FOXLAB_DISABLE_ITEMS": false
}
var foxlab_config = null
var foxlab_current_settings: Dictionary = DEFAULT_SETTINGS.duplicate()

func _init():
	ModLoaderLog.info("Init", MOD_NAME)
	IS_ANDROID = OS.get_user_data_dir().begins_with("/data")
	for script in EXTENSION_SCRIPTS:
		ModLoaderMod.install_script_extension(FOXLAB_EXTENSION_DIR + script)

	if not IS_ANDROID:
		ModLoaderMod.install_script_extension(FOXLAB_EXTENSION_DIR + "progress_data.gd")
		ModLoaderMod.install_script_extension(FOXLAB_EXTENSION_DIR + "evil_mob.gd")

	if "1.1.14" in CrashReporter.VERSION:
		ModLoaderMod.install_script_extension(FOXLAB_EXTENSION_DIR + "sort_inventory_button_14.gd")
	else:
		ModLoaderMod.install_script_extension(FOXLAB_EXTENSION_DIR + "sort_inventory_button.gd")

	ModLoaderMod.add_translation(FOXLAB_TRANSLATION_DIR + "foxlab_translation.en.translation")
	ModLoaderMod.add_translation(FOXLAB_TRANSLATION_DIR + "foxlab_translation.zh_Hans_CN.translation")

func _ready():
	call_deferred("_foxlab_init_configs")
	if IS_ANDROID:
		call_deferred("initialize_mod")

func initialize_mod():
	var mod_data = load("res://mods-unpacked/%s/content_data/content_data.tres" % [MOD_NAME])
	mod_data.add_resources(foxlab_current_settings)
	ItemService.init_unlocked_pool()
	RunData.reset()
	ProgressData.load_game_file()
	ProgressData.add_unlocked_by_default()
	ProgressData.set_max_selectable_difficulty()

func is_transform_vanilla_only():
	return foxlab_current_settings["FOXLAB_TRANSFORM_VANILLA_ONLY"]

func _foxlab_init_configs():
	ModsConfigInterface = get_node_or_null("/root/ModLoader/dami-ModOptions/ModsConfigInterface")
	var CONFIG_NAME = "foxlab_config"
	var configs = ModLoaderConfig.get_configs(MOD_NAME)
	if configs.has(CONFIG_NAME):
		foxlab_config = ModLoaderConfig.get_config(MOD_NAME, CONFIG_NAME)
	else:
		foxlab_config = ModLoaderConfig.create_config(MOD_NAME, CONFIG_NAME, DEFAULT_SETTINGS)

	if foxlab_config:
		var _error_config = ModLoaderConfig.update_config(foxlab_config)
		var data:Dictionary = foxlab_config.data
		if data.keys() != foxlab_current_settings.keys():
			var key_to_remove = []
			for key in data.keys():
				if not key in foxlab_current_settings:
					key_to_remove.append(key)
			for key in key_to_remove:
				data.erase(key)
			data.merge(foxlab_current_settings)

		for key in foxlab_current_settings.keys():
			foxlab_current_settings[key] = data[key]

	if ModsConfigInterface:
		ModsConfigInterface.connect("setting_changed", self, "_on_setting_changed")
		call_deferred("_foxlab_init_settings")

func _foxlab_init_settings() -> void:
	for key in foxlab_current_settings.keys():
		ModsConfigInterface.on_setting_changed(key, foxlab_current_settings[key], MOD_NAME)

func _on_setting_changed(setting_name, value, mod_name)->void :
	if mod_name == MOD_NAME:
		foxlab_current_settings[setting_name] = value
		if foxlab_config:
			foxlab_config.data[setting_name] = value
			var _error_config = ModLoaderConfig.update_config(foxlab_config)
