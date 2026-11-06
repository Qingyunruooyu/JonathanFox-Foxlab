extends "res://entities/units/pet/dino_egg/dino_egg.gd"

func take_damage(value: int, args: TakeDamageArgs) -> Array:
	if args.hitbox and args.hitbox.is_healing:
		return [0, 0]
	return .take_damage(value, args)
