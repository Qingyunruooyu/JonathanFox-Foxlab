extends Resource

# ItemService
export (Array, Resource) var characters = []
export (Array, Resource) var items = []
export (Array, Resource) var weapons = []
export (Array, Resource) var sets = []
export (Array, Resource) var upgrades = []
export (Array, Resource) var consumables = []
export (Array, Resource) var elites = []
export (Array, Resource) var difficulties = []
export (Array, Resource) var effects = []
export (Array, Resource) var stats = []
export (Dictionary) var extra_starting_item = {} #版本兼容相关，添加旧版没有的道具
export (Dictionary) var extra_banned_item = {} #给原版和其他MOD角色按tag添加物品禁用

# ChallengeService
export (Array, Resource) var challenges = []

# RunData
export (Dictionary) var tracked_items = {}
export (Array, String) var effect_keys_with_weapon_stats = []
export (Array, String) var effect_keys_full_serialization = []

# Text
export (Dictionary) var translation_keys_needing_operator = {}
export (Dictionary) var translation_keys_needing_percent = {}

func modify_characters():
	var item_cache = {}
	for character in characters:
		if character.my_id in extra_starting_item and "starting_items" in character:
			for item_name in extra_starting_item[character.my_id]:
				if not item_name in item_cache:
					item_cache[item_name] = ItemService.get_element(ItemService.items, item_name)
				var item = item_cache[item_name]
				if item and not item in character.starting_items:
					character.starting_items.append(item)

	for character in ItemService.characters:
		for tag in extra_banned_item.keys():
			if tag in character.wanted_tags:
				ProgressData._append_without_duplicates(character.banned_items, extra_banned_item[tag])

func add_resources(settings: Dictionary):
	if not settings["FOXLAB_DISABLE_CHARACTERS"]:
		ProgressData._append_without_duplicates(ItemService.characters, characters)
	else:
		for character in characters:
			if character.my_id == "character_foxlab_faceless":
				ProgressData._append_without_duplicates(ItemService.characters, [character])
				break

	if settings["FOXLAB_DISABLE_ITEMS"]:
		for item in items:
			item.can_be_looted = false

	ProgressData._append_without_duplicates(ItemService.items, items)
	ProgressData._append_without_duplicates(ItemService.effects, effects)

	if not tracked_items.empty():
		RunData.init_tracked_items.merge(tracked_items)
	ProgressData._append_without_duplicates(RunData.effect_keys_with_weapon_stats, effect_keys_with_weapon_stats)
	ProgressData._append_without_duplicates(RunData.effect_keys_full_serialization, effect_keys_full_serialization)

	for stat in stats:
		if stat.stat_name.begins_with("foxlab") or not ItemService.get_stat(stat.stat_name):
			ItemService.stats.append(stat)

	if not translation_keys_needing_operator.empty():
		Text.keys_needing_operator.merge(translation_keys_needing_operator)

	if not translation_keys_needing_percent.empty():
		Text.keys_needing_percent.merge(translation_keys_needing_percent)

	call_deferred("modify_characters")
