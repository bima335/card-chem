class_name CardData
extends Resource

enum CardType { ATK, BUFF, DEBUFF, TRIGGER }
enum TargetType { SINGLE, ALL_ENEMIES, SELF }
enum Rarity { COMMON, UNCOMMON, RARE }
enum CostType { NONE, CARBON, HYDROGEN, OXYGEN, NITROGEN }

@export_group("Basic Info")
@export var id: String = "base_card"
@export var card_name: String = "Nama Kartu"
@export var card_texture: Texture2D
@export var modulate: Color = Color.WHITE
@export var rarity: Rarity = Rarity.COMMON
@export var card_type: CardType = CardType.ATK
@export var target_type: TargetType = TargetType.SINGLE
@export var can_be_reward: bool = true

@export_group("Coat Mechanics")
@export var coat_data: CoatData:
	set(value):
		coat_data = value
		if coat_data:
			_check_and_apply_coat_effects()

@export var catalyst_reduced_type: CostType = CostType.NONE

@export_group("Token Costs")
@export var cost_oxygen: int = 0
@export var cost_hydrogen: int = 0
@export var cost_carbon: int = 0
@export var cost_nitrogen: int = 0

@export_group("Buff & Primary Effects")
@export var damage_amount: int = 0
@export var shield_amount: int = 0
@export var gain_oxygen: int = 0
@export var gain_hydrogen: int = 0
@export var gain_carbon: int = 0
@export var gain_nitrogen: int = 0

@export_group("Ekonomi")
@export var buy_value: int = 0
@export var sell_value: int = 0

@export_group("Status & Combo Mechanics")
@export var trigger_element: StatusAilment.AilmentType = StatusAilment.AilmentType.NONE
@export var statuses_to_apply: Array[StatusAilment] = []
@export var toxic_stacks_to_apply: int = 1


func apply_coat(new_coat: CoatData) -> void:
	coat_data = new_coat


func _check_and_apply_coat_effects() -> void:
	if not coat_data:
		return
		
	if coat_data.coat_type == CoatData.EffectCoatType.CATALYST:
		_apply_catalyst_effect()


func _apply_catalyst_effect() -> void:
	if catalyst_reduced_type != CostType.NONE:
		return
		
	var valid_costs: Array[CostType] = []
	
	if cost_carbon > 0: valid_costs.append(CostType.CARBON)
	if cost_hydrogen > 0: valid_costs.append(CostType.HYDROGEN)
	if cost_oxygen > 0: valid_costs.append(CostType.OXYGEN)
	if cost_nitrogen > 0: valid_costs.append(CostType.NITROGEN)
	
	if not valid_costs.is_empty():
		catalyst_reduced_type = valid_costs.pick_random()


func get_effective_cost(cost_type: CostType) -> int:
	var base_val: int = 0
	match cost_type:
		CostType.CARBON: base_val = cost_carbon
		CostType.HYDROGEN: base_val = cost_hydrogen
		CostType.OXYGEN: base_val = cost_oxygen
		CostType.NITROGEN: base_val = cost_nitrogen
		
	if catalyst_reduced_type == cost_type:
		return max(0, base_val - 1)
		
	return base_val
