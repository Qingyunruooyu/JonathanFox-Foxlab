extends "res://ui/menus/shop/item_popup.gd"

signal foxlab_item_pin_button_pressed(item_data)
var foxlab_pin_button: Control
var foxlab_shop_ref

func foxlab_add_pin_button():
	var button_container = _combine_button.get_parent()
	foxlab_pin_button = MyMenuButton.new()
	foxlab_pin_button.text = "MENU_CHOOSE"
	foxlab_pin_button.theme = _combine_button.theme
	foxlab_pin_button.add_font_override("font", _combine_button.get_font("font"))
	foxlab_pin_button.connect("pressed", self, "_on_foxlab_pin_button_pressed")
	button_container.add_child_below_node(_combine_button, foxlab_pin_button)
	foxlab_pin_button.focus_neighbour_left = "."
	foxlab_pin_button.focus_neighbour_right = "."
	foxlab_rebuild_focus_chain()
	for connection in get_signal_connection_list("foxlab_item_pin_button_pressed"):
		foxlab_shop_ref = connection.target

func foxlab_rebuild_focus_chain():
	var button_container = _combine_button.get_parent()
	var buttons = []
	for child in button_container.get_children():
		if child is Button and child.visible:
			buttons.append(child)

	for i in buttons.size():
		var b = buttons[i]
		b.focus_neighbour_top = b.get_path_to(buttons[i - 1]) if i > 0 else NodePath(".")
		b.focus_neighbour_bottom = b.get_path_to(buttons[i + 1]) if i < buttons.size() - 1 else NodePath(".")

func foxlab_has_const_extra_effect_upgrade(item_data: WeaponData) -> bool:
	var nb_duplicate = 0
	var has_extra_effect = false
	for weapon in RunData.get_player_weapons_ref(player_index):
		if weapon.my_id_hash == item_data.my_id_hash:
			nb_duplicate += 1
			if not has_extra_effect:
				for effect in weapon.effects:
					if effect.text_key == ("EFFECT_FOXLAB_WEAPON_TEXT_CURSED" if weapon.is_cursed else "EFFECT_FOXLAB_WEAPON_TEXT"):
						has_extra_effect = true
						break
	if RunData.get_free_weapon_slots(player_index) <= 0:
		for item in foxlab_shop_ref.get_player_shop_items(player_index):
			if item[0].my_id_hash == item_data.my_id_hash:
				nb_duplicate += 1
	return has_extra_effect and nb_duplicate > 2

func _on_foxlab_pin_button_pressed() -> void :
	emit_signal("foxlab_item_pin_button_pressed", _item_data)
	_focused = false

### 扩展 ####
func _ready():
	if buttons_enabled:
		call_deferred("foxlab_add_pin_button")

func _update_button_visibilities():
	._update_button_visibilities()
	if foxlab_pin_button != null:
		var visible = _combine_button.visible and foxlab_has_const_extra_effect_upgrade(_item_data)
		foxlab_pin_button.visible = visible
		foxlab_pin_button.focus_mode = FOCUS_ALL if visible && _focused else FOCUS_NONE
		call_deferred("foxlab_rebuild_focus_chain")
