extends Node

# MOD配置
const MOD_NAME:="JonathanFox-FoxLab"
const MOD_PATH:="res://mods-unpacked/" + MOD_NAME + "/"
const FOXLAB_EXTENSION_DIR: = MOD_PATH + "extensions/"
const FOXLAB_TRANSLATION_DIR: = MOD_PATH + "translations/"
var IS_NEW_DAWN:bool = false

const EXTENSION_SCRIPTS: =[
	"utils.gd",
	"item_service.gd",
	"run_data.gd",
	"player.gd",
	"player_run_data.gd",
	"main.gd",
	"base_shop.gd",
	"item_description.gd",
	"shop_item.gd",
	"floating_text_manager.gd",
	"entity_spawner.gd",
	"linked_stats.gd",
	"upgrades_ui.gd",
	"weapon_service.gd",
]

func _init():
	ModLoaderLog.info("Init", MOD_NAME)
	IS_NEW_DAWN = "1.1.13" in CrashReporter.VERSION
	for script in EXTENSION_SCRIPTS:
		ModLoaderMod.install_script_extension(FOXLAB_EXTENSION_DIR + script)
	if IS_NEW_DAWN:
		ModLoaderMod.install_script_extension(FOXLAB_EXTENSION_DIR + "character_panel_ui.gd")
		ModLoaderMod.install_script_extension(FOXLAB_EXTENSION_DIR + "sort_inventory_button.gd")
		ModLoaderMod.install_script_extension(FOXLAB_EXTENSION_DIR + "progress_data.gd")

	ModLoaderMod.add_translation(FOXLAB_TRANSLATION_DIR + "foxlab_translation.en.translation")
	ModLoaderMod.add_translation(FOXLAB_TRANSLATION_DIR + "foxlab_translation.zh_Hans_CN.translation")

func _ready():
	if not IS_NEW_DAWN:
		call_deferred("initialize_mod")

func initialize_mod():
	var mod_data = load("res://mods-unpacked/%s/content_data/content_data.tres" % [MOD_NAME])
	mod_data.add_resources()
	ItemService.init_unlocked_pool()
	RunData.reset()
	ProgressData.load_game_file()
	ProgressData.add_unlocked_by_default()
	ProgressData.set_max_selectable_difficulty()
