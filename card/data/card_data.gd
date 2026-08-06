class_name CardData
extends Resource

enum CardType { ATK, BUFF, DEBUFF, TRIGGER }
enum EffectCoat { NONE, CLONE, UNSTABLE, INSULATED, CRYSTALIZED, PURIFY, CATALYST }
enum TargetType { SINGLE, ALL_ENEMIES, SELF }
enum Rarity { COMMON, UNCOMMON, RARE }

@export_group("Basic Info")
@export var id: String = "base_card"
@export var card_name: String = "Nama Kartu"
@export var card_texture: Texture2D
@export var modulate: Color = Color.WHITE
@export var rarity: Rarity = Rarity.COMMON
@export var card_type: CardType = CardType.ATK
@export var target_type: TargetType = TargetType.SINGLE
@export var can_be_reward: bool = true

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
@export var coat: EffectCoat = EffectCoat.NONE
@export var trigger_element: StatusAilment.AilmentType = StatusAilment.AilmentType.NONE
@export var statuses_to_apply: Array[StatusAilment] = []
