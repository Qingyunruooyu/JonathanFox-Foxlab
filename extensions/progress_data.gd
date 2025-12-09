extends "res://singletons/progress_data.gd"

var foxlab_data
const MOD_NAME:="JonathanFox-FoxLab"
const MOD_PATH:="res://mods-unpacked/" + MOD_NAME + "/"
const FOXLAB_EXTENSION_DIR: = MOD_PATH + "extensions/"

# =========================== Extention =========================== #
func _ready() -> void:
	DebugService.log_data("_ready")
	if not "1.1.13" in VERSION:
		._ready()
		foxlab_install_extensions()
	_foxlab_ready()

func load_dlc_pcks()->void :
	.load_dlc_pcks()
	foxlab_install_extensions()

# =========================== Custom =========================== #
func _foxlab_ready() -> void:
	DebugService.log_data("%s/content_data/content_data.tres" % [MOD_PATH])
	foxlab_data = load("%s/content_data/content_data.tres" % [MOD_PATH])
	foxlab_data.add_resources()
	DebugService.log_data("add_resources")

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
		DebugService.log_data(path)
		ModLoaderMod.install_script_extension(FOXLAB_EXTENSION_DIR + path)
