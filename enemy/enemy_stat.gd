class_name EnemyStat
extends Resource

enum EnemyTag { SMALL, BIG, BOSS}

@export var enemy_name: String = "Musuh Dasar"
@export var max_hp: int = 30
@export var texture: Texture2D
@export_multiline var description: String = "Deskripsi musuh."
@export var moveset: Array[EnemyAction] = []
@export var tag: EnemyTag = EnemyTag.SMALL

@export var custom_enemy_scene: PackedScene = null
