class_name BossHPBar
extends MarginContainer

@export_group("Layout Customization")
@export var bar_width: float = 600.0
@export var bar_height: float = 32.0
@export var top_margin: float = 24.0
@export var side_margin: float = 0.0

@export_group("Animation Settings")
@export var tween_duration: float = 0.25
@export var tween_transition: Tween.TransitionType = Tween.TRANS_SINE
@export var tween_ease: Tween.EaseType = Tween.EASE_OUT

@onready var boss_name_label: Label = %BossNameLabel
@onready var hp_value_label: Label = %HPValueLabel
@onready var bar: TextureProgressBar = %Bar

var _tracked_boss: EnemyBase = null
var _hp_tween: Tween
var _is_initialized: bool = false


func _ready() -> void:
	_ensure_nodes_initialized()
	_apply_layout_adjustments()
	hide()
	
	if EventBus.has_signal("boss_spawned"):
		EventBus.boss_spawned.connect(setup_boss)


func setup_boss(boss_enemy: EnemyBase) -> void:
	if boss_enemy == null or boss_enemy.stats == null:
		hide()
		return

	_ensure_nodes_initialized()
	_tracked_boss = boss_enemy
	
	if boss_name_label:
		boss_name_label.text = _tracked_boss.stats.enemy_name
		
	if bar:
		bar.max_value = _tracked_boss.stats.max_hp
		bar.value = _tracked_boss.current_hp
		
	_update_label_text(_tracked_boss.current_hp, _tracked_boss.stats.max_hp)
	
	if not _tracked_boss.health_updated.is_connected(_on_boss_health_updated):
		_tracked_boss.health_updated.connect(_on_boss_health_updated)
		
	if not _tracked_boss.tree_exited.is_connected(_on_boss_tree_exited):
		_tracked_boss.tree_exited.connect(_on_boss_tree_exited)

	show()


func _on_boss_health_updated(current: int, max_val: int) -> void:
	if bar == null:
		return
		
	bar.max_value = max_val
	
	if _hp_tween and _hp_tween.is_valid():
		_hp_tween.kill()
		
	_hp_tween = create_tween()
	_hp_tween.set_trans(tween_transition).set_ease(tween_ease)
	_hp_tween.tween_property(bar, "value", float(current), tween_duration)
	
	_update_label_text(current, max_val)


func _update_label_text(current: int, max_val: int) -> void:
	if hp_value_label:
		hp_value_label.text = "%d / %d" % [current, max_val]


func _on_boss_tree_exited() -> void:
	_tracked_boss = null
	hide()


func _ensure_nodes_initialized() -> void:
	if _is_initialized:
		return
		
	if boss_name_label == null:
		boss_name_label = get_node_or_null("%BossNameLabel")
	if hp_value_label == null:
		hp_value_label = get_node_or_null("%HPValueLabel")
	if bar == null:
		bar = get_node_or_null("%Bar")
		
	_is_initialized = true


func _apply_layout_adjustments() -> void:
	add_theme_constant_override("margin_top", int(top_margin))
	add_theme_constant_override("margin_left", int(side_margin))
	add_theme_constant_override("margin_right", int(side_margin))
	
	if bar:
		bar.custom_minimum_size = Vector2(bar_width, bar_height)
