extends "res://singletons/run_data.gd"

func on_wave_start(timer: WaveTimer) -> void :
	.on_wave_start(timer)
	RunData.get_player_effects(0)["foxlab_shop_effects_checked"] = 0

func get_next_level_xp_needed(player_index) -> float:
	var xp_needed = .get_next_level_xp_needed(player_index)
	if xp_needed > 0:
		return xp_needed
	# 防止需要的经验不是正数，导致无限升级爆栈
	var xp_needed_effect = max(get_player_effect("next_level_xp_needed", player_index), -99)
	return get_xp_needed(get_player_level(player_index) + 1) * (1.0 + xp_needed_effect / 100.0)

func add_starting_items_and_weapons() -> void :
	var effects = get_player_effects(0)
	.add_starting_items_and_weapons()
	effects["fox_wave_started"] = 1

func is_wave_started() -> bool:
	return get_player_effect_bool("fox_wave_started", 0)

const FOXLAB_ELITE_CHARS = ["character_foxlab_war_master", "character_foxlab_survivor", "character_foxlab_kidnapper", "character_foxlab_wormhole_traveler", "character_foxlab_venom", "character_foxlab_bounty_hunter"]
const FOXLAB_HORDE_CHARS = ["character_foxlab_pufferfish"]

func init_elites_spawn(base_wave: int = 10, horde_chance: float = 0.4) -> void :
	for player_index in get_player_count():
		var current_character = get_player_character(player_index)
		if current_character != null:
			if current_character.my_id in FOXLAB_ELITE_CHARS:
				horde_chance = 0.0
			elif get_player_count() == 1 and current_character.my_id in FOXLAB_HORDE_CHARS:
				horde_chance = 1.0
	.init_elites_spawn(base_wave, horde_chance)
