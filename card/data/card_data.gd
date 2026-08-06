class_name CardData
extends Resource

enum CardType { ATK, BUFF, DEBUFF, TRIGGER }
enum Rarity { COMMON, UNCOMMON, RARE }
enum EffectCoat { NONE, CLONE, UNSTABLE, INSULATED, CRYSTALIZED, PURIFY, CATALYST }
enum TargetType { SINGLE_ENEMY, ALL_ENEMIES, SELF }

@export_group("Basic Info")
@export var id: String = "base_card"
@export var card_name: String = "Nama Kartu"
@export var card_texture: Texture2D
@export var card_type: CardType = CardType.ATK
@export var rarity: Rarity = Rarity.COMMON
@export var target_type: TargetType = TargetType.SINGLE_ENEMY
@export var modulate: Color = Color.WHITE

@export_group("Cost Tokens")
@export_range(0, 7) var cost_carbon: int = 0
@export_range(0, 7) var cost_hydrogen: int = 0
@export_range(0, 7) var cost_oxygen: int = 0
@export_range(0, 7) var cost_nitrogen: int = 0

@export_group("Coat & Effects")
@export var effect_coat: EffectCoat = EffectCoat.NONE
@export var base_damage: int = 0
@export var shield_amount: int = 0

@export_group("Buff Token Gains")
@export var gain_carbon: int = 0
@export var gain_hydrogen: int = 0
@export var gain_oxygen: int = 0
@export var gain_nitrogen: int = 0

@export_group("Status & Tags")
@export var inflict_oxidize: bool = false
@export var inflict_ignite: bool = false
@export var add_toxic_stacks: int = 0
@export var inflict_corrosion: bool = false
@export var inflict_volatile: bool = false
@export var reduce_enemy_damage: int = 0
