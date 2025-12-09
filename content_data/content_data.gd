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

# Text
export (Dictionary) var translation_keys_needing_operator = {}
export (Dictionary) var translation_keys_needing_percent = {}

func add_resources():
	if "1.1.13" in CrashReporter.VERSION:
		for i in items:
			if  not ProgressData.items_unlocked.has(i.my_id):
				ProgressData.items_unlocked.append(i.my_id)

	ProgressData._append_without_duplicates(ItemService.characters, characters)
	ProgressData._append_without_duplicates(ItemService.items, items)
	ProgressData._append_without_duplicates(ItemService.effects, effects)

	if not tracked_items.empty():
		RunData.init_tracked_items.merge(tracked_items)

	if not translation_keys_needing_operator.empty():
		Text.keys_needing_operator.merge(translation_keys_needing_operator)

	if  not translation_keys_needing_percent.empty():
		Text.keys_needing_percent.merge(translation_keys_needing_percent)
