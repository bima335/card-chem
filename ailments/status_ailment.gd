class_name StatusAilment
extends Resource

enum ailment_type {Corrotion,
Ignite,
Oxidation,
Toxification,
Volatile,
None,
Burnt,
}

@export var ailment: ailment_type = ailment_type.Ignite
@export var duration: int = 2
@export var status_icon: Texture2D
