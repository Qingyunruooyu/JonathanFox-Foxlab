extends "res://zones/wave_manager.gd"

func init_elite_group(elites_to_spawn: Array = [], add_endless_elites: bool = true):
	var local_elite_group = .init_elite_group(elites_to_spawn, add_endless_elites)
	var current_zone_elites = ZoneService.get_elites_from_zone(current_zone_data.my_id)
	# 基类已把endless精英追加进elites_to_spawn并生成过单位，这里只处理当前区域没有的
	var all_elites = null
	for elite_to_spawn in elites_to_spawn:
		assert (elite_to_spawn is int)
		var found = false
		for elite in current_zone_elites:
			if elite_to_spawn == elite.my_id_hash:
				found = true
				break
		if found:
			continue
		if all_elites == null:
			all_elites = Utils.foxlab_get_available_zone_units(false)
		for elite in all_elites:
			if elite_to_spawn == elite.my_id_hash:
				var unit = WaveUnitData.new()
				unit.type = EntityType.BOSS
				unit.unit_scene = elite.scene
				local_elite_group.wave_units_data.push_back(unit)
				break
	return local_elite_group
