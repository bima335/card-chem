class_name EnemyStat
extends Resource

enum EnemyTag { SMALL, BIG, BOSS, MINION }

@export var enemy_name: String = "Musuh Dasar"
@export var max_hp: int = 30
@export var texture: Texture2D
@export_multiline var description: String = "Deskripsi musuh."
@export var moveset: Array[EnemyAction] = []
@export var tag: EnemyTag = EnemyTag.SMALL
@export var gold_out: int = 0
@export var custom_enemy_scene: PackedScene = null
@export var animation_library: AnimationLibrary = null

@export_group("Manual Sizing & Hitbox")
@export var sprite_scale: Vector2 = Vector2.ONE
@export var click_area_size: Vector2 = Vector2(150.0, 150.0)
@export var click_area_offset: Vector2 = Vector2.ZERO
@export var ui_vertical_offset: float = 16.0
