class_name SectionData
extends Resource

@export var section_name: String = "Section Baru"
@export var section_wallpaper: Texture2D

@export_group("Exclusive Enemies")
@export var exclusive_common: Array[EnemyStat] = []
@export var exclusive_elite: Array[EnemyStat] = []
@export var exclusive_boss: Array[EnemyStat] = []

@export_group("Boss Rewards")
@export var boss_aura_rewards: Array[AuraCardData] = []

@export_group("Shop Odds - Cards (%)")
@export_range(0.0, 100.0) var cards_common_chance: float = 70.0
@export_range(0.0, 100.0) var cards_uncommon_chance: float = 25.0
@export_range(0.0, 100.0) var cards_rare_chance: float = 5.0

@export_group("Shop Odds - Coat (%)")
@export_range(0.0, 100.0) var coat_common_chance: float = 70.0
@export_range(0.0, 100.0) var coat_uncommon_chance: float = 25.0
@export_range(0.0, 100.0) var coat_rare_chance: float = 5.0

@export_group("Shop Odds - Blessing (%)")
@export_range(0.0, 100.0) var blessing_common_chance: float = 60.0
@export_range(0.0, 100.0) var blessing_uncommon_chance: float = 30.0
@export_range(0.0, 100.0) var blessing_rare_chance: float = 10.0
