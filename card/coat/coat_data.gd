class_name CoatData
extends Resource

enum EffectCoatType { 
	NONE, 
	CLONE, 
	UNSTABLE, 
	INSULATED, 
	CRYSTALIZED, 
	PURIFY, 
	CATALYST 
}

enum Rarity { COMMON, UNCOMMON, RARE }

@export_group("Coat Identity")
@export var coat_type: EffectCoatType = EffectCoatType.NONE
@export var coat_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var texture_overlay: Texture2D
@export var buy_price: int = 0

@export_group("Coat Stats & Parameters")
@export var damage_multiplier: float = 1.0
@export var self_damage_ratio: float = 0.0
@export var is_retained: bool = false
@export var retain_shield_bonus: int = 0
@export var is_insulated: bool = false
@export var cost_reduction_amount: int = 0
@export var rarity: Rarity = Rarity.COMMON


func apply_damage_modifier(base_damage: int) -> int:
	return int(base_damage * damage_multiplier)


func calculate_self_damage(calculated_damage: int) -> int:
	return int(calculated_damage * self_damage_ratio)
