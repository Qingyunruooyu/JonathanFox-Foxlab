extends "res://singletons/progress_data.gd"

var foxlab_data
var foxlab_extension_loaded:=false
const FOXLAB_MOD_NAME:="JonathanFox-FoxLab"
const FOXLAB_MOD_PATH:="res://mods-unpacked/" + FOXLAB_MOD_NAME + "/"
const FOXLAB_EXTENSION_DIR: = FOXLAB_MOD_PATH + "extensions/"

# =========================== Extension =========================== #
func _ready() -> void:
	_foxlab_ready()

func load_dlc_pcks()->void :
	.load_dlc_pcks()
	if not foxlab_extension_loaded:
		foxlab_install_extensions()
		foxlab_extension_loaded = true

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
	ItemService.init_unlocked_pool()
	RunData.reset()
	load_game_file()
	add_unlocked_by_default()
	set_max_selectable_difficulty()

func foxlab_install_extensions() -> void:
	var extensions: Array = [
		"charm_enemy_effect_behavior.gd",
	]
	for path in extensions:
		ModLoaderMod.install_script_extension(FOXLAB_EXTENSION_DIR + path)
