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
