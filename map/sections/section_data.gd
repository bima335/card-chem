class_name SectionData
extends Resource

@export var section_name: String = "Section Baru"
@export var section_wallpaper: Texture2D

@export_group("Exclusive Enemies")
@export var exclusive_common: Array[EnemyStat] = []
@export var exclusive_elite: Array[EnemyStat] = []
@export var exclusive_boss: Array[EnemyStat] = []
