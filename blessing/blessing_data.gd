# BlessingData.gd
class_name BlessingData
extends Resource

enum BlessingID {
	RESONANCE,
	A_HELPING_HAND,
	PROTECTORS_WILL,
	TOXIC_CHEMIST,
	COVER_BEHIND_SMOKE,
	OVER_ACCIDIC,
	RECYCLE,
	STAND_PROUD
}
enum Rarity { COMMON, UNCOMMON, RARE }

@export var id: BlessingID
@export var name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var buy_price: int = 0
@export var sell_price: int = 0
@export var rarity: Rarity = Rarity.COMMON
