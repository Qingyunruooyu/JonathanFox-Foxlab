extends "res://singletons/progress_data.gd"

var foxlab_data
const FOXLAB_MOD_NAME:="JonathanFox-FoxLab"
const FOXLAB_MOD_PATH:="res://mods-unpacked/" + FOXLAB_MOD_NAME + "/"

# =========================== Extension =========================== #
func _ready() -> void:
	_foxlab_ready()

# =========================== Custom =========================== #
func _foxlab_ready() -> void:
	foxlab_data = load("%s/content_data/content_data.tres" % [FOXLAB_MOD_PATH])
	var CONFIG_NAME = "foxlab_config"
	var config_settings: Dictionary
	var configs = ModLoaderConfig.get_configs(FOXLAB_MOD_NAME)
	if configs.has(CONFIG_NAME):
		config_settings = ModLoaderConfig.get_config(FOXLAB_MOD_NAME, CONFIG_NAME).data
	var mod_settings:Dictionary = get_node_or_null("/root/ModLoader/" + FOXLAB_MOD_NAME).foxlab_current_settings
	config_settings.merge(mod_settings)
	foxlab_data.add_resources(config_settings)
	Utils.reset_stat_keys()
	ItemService.init_unlocked_pool()
	RunData.reset()
	load_game_file()
	add_unlocked_by_default()
	set_max_selectable_difficulty()
