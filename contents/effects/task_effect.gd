extends "res://items/global/effect.gd"

export(Array, Resource) var sub_effects
#当满足 get_player_effect(key_hash) >= value时 (comparison >= 0，comparison < 0时，条件为 < value)，apply一次所有的sub_effects
# 最多执行max_execs次（<0 时执行无数次）
export(int) var max_execs = 1
export(int) var comparison = 0
export(bool) var default_text_mode = true

static func get_id() -> String:
	return "foxlab_task"

func apply(player_index: int) -> void:
	RunData.get_player_effect(Utils.foxlab_tasks_hash, player_index).append(self)

func unapply(player_index: int) -> void:
	RunData.get_player_effect(Utils.foxlab_tasks_hash, player_index).erase(self)

func get_args(player_index: int) -> Array:
	var args = .get_args(player_index)

	for sub_effect in sub_effects:
		args.append_array(sub_effect.get_args(player_index))

	return args

func serialize() -> Dictionary:
	var serialized = .serialize()
	var serialized_sub_effects := []
	for sub_effect in sub_effects:
		serialized_sub_effects.append(sub_effect.serialize())
	serialized.sub_effects = serialized_sub_effects

	serialized.max_execs = str(max_execs)
	serialized.comparison = str(comparison)
	serialized.default_text_mode = default_text_mode

	return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	max_execs = serialized.max_execs as int
	comparison = serialized.comparison as int
	default_text_mode = serialized.default_text_mode

	for serialized_sub_effect in serialized.sub_effects:
		var sub_effect = null
		if serialized_sub_effect.effect_id == Effect.get_id():
			sub_effect = Effect.new()
		else:
			for effect in ItemService.effects:
				if effect.get_id() == serialized_sub_effect.effect_id:
					sub_effect = effect.new()
					break
		if sub_effect:
			sub_effect.deserialize_and_merge(serialized_sub_effect)
			sub_effects.append(sub_effect)

func get_text(player_index: int, _colored: bool = true) -> String:
	if default_text_mode:
		return .get_text(player_index, _colored)
	var texts = []
	var primary_text = .get_text(player_index, _colored)
	if primary_text != "":
		texts.append(primary_text)
	for effect in sub_effects:
		var sub_text = effect.get_text(player_index, _colored)
		if sub_text != "":
			texts.append(sub_text)
	return "\n".join(texts)
