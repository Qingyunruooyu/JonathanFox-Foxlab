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

# ChallengeService
export (Array, Resource) var challenges = []

# RunData
export (Dictionary) var tracked_items = {}
export (Array, String) var effect_keys_with_weapon_stats = []
export (Array, String) var effect_keys_full_serialization = []

# Text
export (Dictionary) var translation_keys_needing_operator = {}
export (Dictionary) var translation_keys_needing_percent = {}

func add_resources(settings: Dictionary):
	if settings["FOXLAB_ENABLE_CHARACTERS"]:
		ProgressData._append_without_duplicates(ItemService.characters, characters)
	else:
		for character in characters:
			if character.my_id == "character_foxlab_faceless":
				ProgressData._append_without_duplicates(ItemService.characters, [character])
				break

	if not settings["FOXLAB_ENABLE_ITEMS"]:
		for item in items:
			item.can_be_looted = false

	ProgressData._append_without_duplicates(ItemService.items, items)
	ProgressData._append_without_duplicates(ItemService.effects, effects)

	if not tracked_items.empty():
		RunData.init_tracked_items.merge(tracked_items)
	ProgressData._append_without_duplicates(RunData.effect_keys_with_weapon_stats, effect_keys_with_weapon_stats)
	ProgressData._append_without_duplicates(RunData.effect_keys_full_serialization, effect_keys_full_serialization)

	if not translation_keys_needing_operator.empty():
		Text.keys_needing_operator.merge(translation_keys_needing_operator)

	if not translation_keys_needing_percent.empty():
		Text.keys_needing_percent.merge(translation_keys_needing_percent)
