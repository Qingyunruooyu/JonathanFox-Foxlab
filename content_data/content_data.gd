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
	for tag in extra_banned_item.keys():
		for character in ItemService.characters:
			if tag in character.wanted_tags:
				ProgressData._append_without_duplicates(character.banned_items, extra_banned_item[tag])

func add_stats():
	for stat in stats:
		stat.generate_hashes()
		if "foxlab" in stat.stat_name or not ItemService.get_stat(stat.stat_hash):
			ItemService.stats.append(stat)

func add_resources(settings: Dictionary):
	if not settings["FOXLAB_DISABLE_CHARACTERS"]:
		ProgressData._append_without_duplicates(ItemService.characters, characters)
	else:
		var faceless_hash = Keys.generate_hash("character_foxlab_faceless")
		for character in characters:
			if character.my_id_hash == faceless_hash:
				ProgressData._append_without_duplicates(ItemService.characters, [character])
				break

	if settings["FOXLAB_DISABLE_ITEMS"]:
		for item in items:
			item.can_be_looted = false

	ProgressData._append_without_duplicates(ItemService.items, items)
	ProgressData._append_without_duplicates(ItemService.effects, effects)
	ProgressData._append_without_duplicates(RunData.effect_keys_with_weapon_stats, Utils.convert_to_hash_array(effect_keys_with_weapon_stats))
	ProgressData._append_without_duplicates(RunData.effect_keys_full_serialization, Utils.convert_to_hash_array(effect_keys_full_serialization))

	RunData.init_tracked_items.merge(Utils.convert_dictionary_to_hash(tracked_items))

	Text.keys_needing_operator.merge(translation_keys_needing_operator)
	Text.keys_needing_percent.merge(translation_keys_needing_percent)

	call_deferred("modify_characters")
	call_deferred("add_stats")
