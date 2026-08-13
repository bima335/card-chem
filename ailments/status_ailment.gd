class_name StatusAilment
extends Resource

enum AilmentType {
	NONE,
	OXIDIZE,
	TOXIC,
	CORROSION,
	IGNITE,
	VOLATILE,
	BURN,
	POISON,
	DESTABILIZE,
	STUN,
	DISINTEGRATE,
	EXPOSED
}

@export var ailment: AilmentType = AilmentType.NONE
@export var duration: int = 1
@export var status_icon: Texture2D
@export var modulate: Color = Color.WHITE
