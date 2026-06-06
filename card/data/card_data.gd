class_name CardData
extends Resource
enum tipe_kartu {ATTACK, SHIELD}
enum effect_kartu {UNSTABLE, VOLATILE, NONE}

@export var id:String = "base_card"
@export var card_name:String = "nama basic"
@export var card_texture: Texture2D

@export var modulate: Color

@export var cost_oxygen: int = 0
@export var cost_hydrogen: int = 0
@export var cost_carbon: int = 0
@export var cost_nitrogen: int = 0
@export var effect_amount: int = 0
@export var effect: effect_kartu = effect_kartu.NONE
@export var tipe: tipe_kartu
@export var can_be_reward: bool= false
@export var is_multi_target: bool = false
@export var attack_ailment: StatusAilment.ailment_type = StatusAilment.ailment_type.None
@export var status_to_apply: StatusAilment
