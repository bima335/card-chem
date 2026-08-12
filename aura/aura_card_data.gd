class_name AuraCardData
extends Resource

enum AuraID {
	NONE,
	IRON_RAGE,
	CORRODED_LIMITS,
	RUSTED_RESILIENCE
}

@export var aura_id: AuraID = AuraID.NONE
@export var name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
