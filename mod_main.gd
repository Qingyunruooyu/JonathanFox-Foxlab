extends Node

# MOD配置
const MOD_NAME:="JonathanFox-FoxLab"
const MOD_PATH:="res://mods-unpacked/" + MOD_NAME + "/"
const FOXLAB_TIMESTAMP_FILE: = MOD_PATH + "timestamp.txt"
const FOXLAB_REMOVE_LIST_FILE: = MOD_PATH + "remove_list.txt"
const FOXLAB_RESOURCES_DIR: = MOD_PATH + "resources/"
const FOXLAB_EXTENSION_DIR: = MOD_PATH + "extensions/"
const FOXLAB_TRANSLATION_DIR: = MOD_PATH + "translations/"
const FOXLAB_CONTENTS_DIR: = MOD_PATH + "contents/"
var BROLAB_TARGET_DIR: String = ""
var mod_timestamp: int = 0

const EFFECTS_SCRIPTS: = [
	"get_random_weapon_effect.gd",
	"get_random_character_effect.gd",
	"swap_stat_effect.gd",
	"alternative_append_effect.gd",
	"take_away_effect.gd",
	"convert_remainder_to_stat_effect.gd"
]

const EXTENSION_SCRIPTS: =[
	"utils.gd",
	"item_service.gd",
	"run_data.gd",
	"player.gd",
	"player_run_data.gd",
	"base_shop.gd",
	"item_description.gd",
	"shop_item.gd",
	"floating_text_manager.gd",
]

func _init():
	ModLoaderLog.info("Init", MOD_NAME)
	for script in EXTENSION_SCRIPTS:
		ModLoaderMod.install_script_extension(FOXLAB_EXTENSION_DIR + script)
	if "1.1.13" in CrashReporter.VERSION:
		ModLoaderMod.install_script_extension(FOXLAB_EXTENSION_DIR + "main_latest.gd")
		ModLoaderMod.install_script_extension(FOXLAB_EXTENSION_DIR + "character_panel_ui.gd")

	else:
		ModLoaderMod.install_script_extension(FOXLAB_EXTENSION_DIR + "main_legacy.gd")

	ModLoaderMod.add_translation(FOXLAB_TRANSLATION_DIR + "foxlab_translation.en.translation")
	ModLoaderMod.add_translation(FOXLAB_TRANSLATION_DIR + "foxlab_translation.zh_Hans_CN.translation")

	# 如果没开brolab特殊机制，在这里开启
	var BROLAB_MOD_NAME: String = "QianMo-BroLab"
	var BROLAB_CONFIG_NAME: = "brolab_config"
	var configs: Dictionary = ModLoaderConfig.get_configs(BROLAB_MOD_NAME)
	if configs.has(BROLAB_CONFIG_NAME):
		var config = ModLoaderConfig.get_config(BROLAB_MOD_NAME, BROLAB_CONFIG_NAME)
		var data = config.data
		if not(data and not data.empty() and data.get("BROLAB_ENABLE_SPECIAL_MECHANISMS", false)):
			ModLoaderMod.install_script_extension("res://mods-unpacked/%s/extensions/main.gd" % [BROLAB_MOD_NAME])

func _ready():
	call_deferred("initialize_mod")

func initialize_mod():
	ProgressData.init_save_paths()    
	var save_path: String = ProgressData.SAVE_PATH    
	var last_splitter: = save_path.find_last("/")
	var base_save_path: = save_path.left(last_splitter).get_base_dir()    
	BROLAB_TARGET_DIR = base_save_path.plus_file("brolab")

	if not load_mod_timestamp():
		DebugService.log_data("Failed to load MOD timestamp")
		return

	copy_mod_resources()
	DebugService.log_data("拷贝完成: " + BROLAB_TARGET_DIR)
	delete_files_from_txt(FOXLAB_REMOVE_LIST_FILE)
	for s in EFFECTS_SCRIPTS:
		ItemService.effects.append(load(FOXLAB_CONTENTS_DIR + "/effects/" + s))

func load_mod_timestamp() -> bool:
	var file: = File.new()
	var error := file.open(FOXLAB_TIMESTAMP_FILE, File.READ)
	if error == OK:
		#读取当前OS的时间戳精度，MOD里面给的是秒级别的，安卓上可能会返回毫秒级别
		var timestamp_file = BROLAB_TARGET_DIR.plus_file("timestamp.txt")
		copy_single_file(FOXLAB_TIMESTAMP_FILE, timestamp_file)
		var file_modified_time:String = str(file.get_modified_time(timestamp_file))
		var dir = Directory.new()
		dir.remove(timestamp_file)
		DebugService.log_data("硬盘上文件的时间戳: " + file_modified_time)

		var timestamp_str:String = file.get_as_text().strip_edges()
		while timestamp_str.length() < file_modified_time.length():
			timestamp_str += '0'
		mod_timestamp = timestamp_str.to_int()
		DebugService.log_data("MOD内的时间戳文字（补齐后）：" + timestamp_str)
		file.close()
		return true
	return false

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
		line = BROLAB_TARGET_DIR.plus_file(line)
		# 检查文件是否存在
		if dir.file_exists(line):
			# 删除文件
			if dir.remove(line) != OK:
				DebugService.log_data("删除文件失败: " + line)
			else:
				DebugService.log_data("成功删除文件: " + line)

	file.close()

func copy_mod_resources():
	ensure_directory_exists(BROLAB_TARGET_DIR)

	var mod_files := get_files_in_directory(FOXLAB_RESOURCES_DIR)

	for file_path in mod_files:
		copy_file_if_needed(file_path)

func copy_file_if_needed(mod_file_path: String):
	# 获取相对路径（去掉MOD目录前缀）
	var relative_path := mod_file_path.replace(FOXLAB_RESOURCES_DIR, "")
	var target_file_path := BROLAB_TARGET_DIR.plus_file(relative_path)

	# 检查目标文件是否存在及其时间戳
	if should_copy_file(mod_file_path, target_file_path):
		copy_single_file(mod_file_path, target_file_path)
		DebugService.log_data("Copied: " + relative_path)
	else:
		pass
		#DebugService.log_data("Skipped (up to date): " + relative_path)

func should_copy_file(mod_file_path: String, target_file_path: String) -> bool:
	# 如果目标文件不存在，需要拷贝
	if not File.new().file_exists(target_file_path):
		return true

	# 获取目标文件的修改时间
	var file := File.new()
	if file.open(target_file_path, File.READ) == OK:
		var file_timestamp := file.get_modified_time(target_file_path)
		file.close()

		# 如果目标文件时间早于MOD时间戳，需要更新
		return file_timestamp < mod_timestamp

	return true

func copy_single_file(source_path: String, target_path: String) -> bool:
	# 确保目标目录存在
	var target_path_str := target_path.get_base_dir()
	ensure_directory_exists(target_path_str)

	# 拷贝文件
	var source_file := File.new()
	if source_file.open(source_path, File.READ) != OK:
		push_error("Failed to open source file: " + source_path)
		return false

	var target_file := File.new()
	if target_file.open(target_path, File.WRITE) != OK:
		push_error("Failed to open target file: " + target_path)
		source_file.close()
		return false

	var content := source_file.get_buffer(source_file.get_len())
	target_file.store_buffer(content)

	source_file.close()
	target_file.close()

	# 设置文件修改时间为MOD时间戳
	var file := File.new()
	file.open(target_path, File.READ_WRITE)
	file.close()
	# 注意：Godot 3 没有直接的set_modified_time函数，需要其他方式处理时间戳

	return true

func ensure_directory_exists(dir_path: String):
	var dir := Directory.new()
	if not dir.dir_exists(dir_path):
		dir.make_dir_recursive(dir_path)

func get_files_in_directory(path: String) -> Array:
	var files := []
	var dir := Directory.new()

	if dir.open(path) == OK:
		dir.list_dir_begin(true, true)
		var file_name := dir.get_next()

		while file_name != "":
			var full_path := path.plus_file(file_name)
			if dir.current_is_dir():
				# 递归处理子目录
				files.append_array(get_files_in_directory(full_path))
			elif not full_path.ends_with(".import"):
				files.append(full_path)
			file_name = dir.get_next()
		dir.list_dir_end()

	return files

# 提供给其他脚本使用的接口
func get_mod_resource_path(relative_path: String) -> String:
	var target_path := BROLAB_TARGET_DIR.plus_file(relative_path)

	# 如果user://目录下有文件，优先使用，否则使用MOD内置资源
	if File.new().file_exists(target_path):
		return target_path
	else:
		return FOXLAB_RESOURCES_DIR.plus_file(relative_path)
