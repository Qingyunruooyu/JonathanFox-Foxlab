class_name ColoredPercentDamageEffect
extends PercentDamageEffect

export(String) var outline_color_str: = "ebffbfff"

func apply(player_index: int) -> void:
	outline_color = Color(outline_color_str)
	.apply(player_index)

func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	outline_color_str = outline_color.to_html()
