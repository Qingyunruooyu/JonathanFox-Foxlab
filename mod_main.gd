extends Node

# MOD配置
const MOD_NAME = "JonathanFox-FoxLab"
const MOD_PATH = "res://mods-unpacked/" + MOD_NAME + "/"
const FOXLAB_EXTENSION_DIR = MOD_PATH + "extensions/"

const FOXLAB_BASE_SHOP_SNAPSHOT_VERSION = "1.2.0.1"
#脚本作用域持有覆盖脚本的引用，防止被回收导致覆盖失效
var foxlab_base_shop_overwrite = null

const EXTENSION_SCRIPTS = [
	"utils.gd",
	"item_service.gd",
	"progress_data.gd",
	"run_data.gd",
	"player.gd",
	"player_run_data.gd",
	"main.gd",
	"wave_manager.gd",
	"base_shop.gd",
	"shop_item.gd",
	"floating_text_manager.gd",
	"entity_spawner.gd",
	"entity_service.gd",
	"linked_stats.gd",
	"upgrades_ui.gd",
	"weapon_service.gd",
	"character_panel_ui.gd",
	"menu_confirm.gd",
	"sort_inventory_button.gd",
	"item_description.gd",
	"weapon_selection.gd",
	"effects/projectile_effect.gd",
	"tag_panel.gd",
	"tags_container.gd",
	"scapegoat.gd",
	"consumable.gd",
	"catling_gun.gd",
	"dino_egg.gd",
	"upgrades_ui_player_container.gd",
	"upgrade_ui.gd",
	"coop_item_popup.gd",
	"item_popup.gd",
	"killed_by_container.gd",
	"acid_puddle.gd",
	"petrol_puddle.gd",
	"dlc_1_data.gd",
	"dlc_2_data.gd",
	"effects/burning_effect.gd",
	"evil_mob.gd",
	"weapon.gd",
	"enemy.gd",
	"railgun.gd",
	# "builder_turret.gd",# 兼容性差
]


var ModsConfigInterface = null
const DEFAULT_SETTINGS = {
	"FOXLAB_TRANSFORM_VANILLA_ONLY": false,
	"FOXLAB_DISABLE_CHARACTERS": false,
	"FOXLAB_DISABLE_ITEMS": false,
	"FOXLAB_PIN_CHARACTERS": false
}
var foxlab_config = null
var foxlab_current_settings: Dictionary

func _init():
	ModLoaderLog.info("Init", MOD_NAME)
	foxlab_current_settings = DEFAULT_SETTINGS.duplicate()
	_foxlab_overwrite_base_shop()
	for script in EXTENSION_SCRIPTS:
		ModLoaderMod.install_script_extension(FOXLAB_EXTENSION_DIR + script)

#1.2.0.1的base_shop.gd用":= RunData.get_next_wave()"做类型推导，装扩展阶段RunData等autoload尚未实例化，
#解析器无法得知返回类型，基类解析失败会导致extensions/base_shop.gd装不上。vanilla自身能解析时不介入
func _foxlab_overwrite_base_shop():
	if CrashReporter.VERSION != FOXLAB_BASE_SHOP_SNAPSHOT_VERSION:
		return
	var vanilla_shop = load("res://ui/menus/shop/base_shop.gd")
	if vanilla_shop != null and vanilla_shop.can_instance():
		return
	foxlab_base_shop_overwrite = load(MOD_PATH + "overwrites/ui/menus/shop/base_shop.gd")
	foxlab_base_shop_overwrite.take_over_path("res://ui/menus/shop/base_shop.gd")

func _ready():
	call_deferred("_foxlab_init_configs")

func is_transform_vanilla_only():
	return foxlab_current_settings["FOXLAB_TRANSFORM_VANILLA_ONLY"]

func is_pin_characters_enabled():
	return foxlab_current_settings["FOXLAB_PIN_CHARACTERS"]

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
