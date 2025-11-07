extends Node

# MOD配置
const MOD_NAME:="JonathanFox-FoxLab"
const MOD_PATH:="res://mods-unpacked/" + MOD_NAME + "/"
const FOXLAB_REMOVE_LIST_FILE: = MOD_PATH + "remove_list.txt"
const FOXLAB_EXTENSION_DIR: = MOD_PATH + "extensions/"
const FOXLAB_TRANSLATION_DIR: = MOD_PATH + "translations/"
var LEGACY_DIR: String = ""
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
]

func _init():
	ModLoaderLog.info("Init", MOD_NAME)
	IS_NEW_DAWN = "1.1.13" in CrashReporter.VERSION
	for script in EXTENSION_SCRIPTS:
		ModLoaderMod.install_script_extension(FOXLAB_EXTENSION_DIR + script)
	if IS_NEW_DAWN:
		ModLoaderMod.install_script_extension(FOXLAB_EXTENSION_DIR + "main_latest.gd")
		ModLoaderMod.install_script_extension(FOXLAB_EXTENSION_DIR + "character_panel_ui.gd")
	else:
		ModLoaderMod.install_script_extension(FOXLAB_EXTENSION_DIR + "main_legacy.gd")

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

	var translation: Translation = Translation.new()
	for c in mod_data.characters:
		translation.add_message(c.my_id.to_upper(), tr(c.name))
	for i in mod_data.items:
		translation.add_message(i.my_id.to_upper(), tr(i.name))
	TranslationServer.add_translation(translation)

	# remove legacy files
	ProgressData.init_save_paths()    
	var save_path: String = ProgressData.SAVE_PATH    
	var last_splitter: = save_path.find_last("/")
	var base_save_path: = save_path.left(last_splitter).get_base_dir()    
	LEGACY_DIR = base_save_path.plus_file("brolab")
	delete_files_from_txt(FOXLAB_REMOVE_LIST_FILE)

func delete_files_from_txt(file_path: String) -> void:
	var file = File.new()

	# 读取 txt 文件
	if file.open(file_path, File.READ) != OK:
		DebugService.log_data("无法打开文件: " + file_path)
		return

	# 逐行处理
	while not file.eof_reached():
		var line = file.get_line().strip_edges()

		if line.empty():
			continue

		# 创建 Directory 对象
		var dir = Directory.new()
		line = LEGACY_DIR.plus_file(line)
		# 检查文件是否存在
		if dir.file_exists(line):
			# 删除文件
			if dir.remove(line) != OK:
				DebugService.log_data("删除文件失败: " + line)
			else:
				DebugService.log_data("成功删除文件: " + line)

	file.close()
