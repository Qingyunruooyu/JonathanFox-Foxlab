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
]

func _init():
	ModLoaderLog.info("Init", MOD_NAME)
	IS_NEW_DAWN = "1.1.13" in CrashReporter.VERSION
	for script in EXTENSION_SCRIPTS:
		ModLoaderMod.install_script_extension(FOXLAB_EXTENSION_DIR + script)
	if IS_NEW_DAWN:
		ModLoaderMod.install_script_extension(FOXLAB_EXTENSION_DIR + "character_panel_ui.gd")
		ModLoaderMod.install_script_extension(FOXLAB_EXTENSION_DIR + "sort_inventory_button.gd")

	ModLoaderMod.add_translation(FOXLAB_TRANSLATION_DIR + "foxlab_translation.en.translation")
	ModLoaderMod.add_translation(FOXLAB_TRANSLATION_DIR + "foxlab_translation.zh_Hans_CN.translation")

func _ready():
	call_deferred("initialize_mod")

func initialize_mod():
	var mod_data = load("res://mods-unpacked/%s/content_data/content_data.tres" % [MOD_NAME])

	if IS_NEW_DAWN:
		for i in mod_data.items:
			if  not ProgressData.items_unlocked.has(i.my_id):
				ProgressData.items_unlocked.append(i.my_id)

	ProgressData._append_without_duplicates(ItemService.characters, mod_data.characters)
	ProgressData._append_without_duplicates(ItemService.items, mod_data.items)
	ProgressData._append_without_duplicates(ItemService.effects, mod_data.effects)

	if not mod_data.tracked_items.empty():
		RunData.init_tracked_items.merge(mod_data.tracked_items)

	if not mod_data.translation_keys_needing_operator.empty():
		Text.keys_needing_operator.merge(mod_data.translation_keys_needing_operator)

	if  not mod_data.translation_keys_needing_percent.empty():
		Text.keys_needing_percent.merge(mod_data.translation_keys_needing_percent)

	ItemService.init_unlocked_pool()
	RunData.reset()
	ProgressData.load_game_file()
	ProgressData.add_unlocked_by_default()
	ProgressData.set_max_selectable_difficulty()
