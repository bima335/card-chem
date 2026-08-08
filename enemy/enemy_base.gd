class_name EnemyBase
extends Node2D

@export var stats: EnemyStat 
@export var max_display_size: Vector2 = Vector2(150.0, 150.0)

var active_statuses: Dictionary = {}

var current_hp: int
var current_shield: int = 0
var toxic_stacks: int = 0
var burn_stacks: int = 0
var is_stunned: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var selection_aura: Sprite2D = $SelectionAura
@onready var click_area: Area2D = $ClickArea
@onready var collision_shape: CollisionShape2D = $ClickArea/CollisionShape2D
@onready var hp_bar: ProgressBar = $HPBar
@onready var hp_label: Label = $HPBar/Label
@onready var status_container: HBoxContainer = $StatusContainer

var is_selected: bool = false
var float_tween: Tween
var base_sprite_y: float

func _ready() -> void:
	if stats:
		current_hp = stats.max_hp
		hp_bar.max_value = stats.max_hp
		hp_bar.value = current_hp
		_update_hp_text()
		
		if sprite and stats.texture:
			sprite.texture = stats.texture
			_adjust_sprite_scale()
			selection_aura.texture = stats.texture
			selection_aura.scale = sprite.scale * 1.15
			
	click_area.input_event.connect(_on_click_area_input_event)
	click_area.mouse_entered.connect(_on_mouse_entered)
	click_area.mouse_exited.connect(_on_mouse_exited)
	
	base_sprite_y = sprite.position.y
	EventBus.enemy_selected.connect(_on_any_enemy_selected)
	
	_setup_enemy()

# Hook virtual untuk inisialisasi kelas turunan
func _setup_enemy() -> void:
	pass

func _update_hp_text() -> void:
	if hp_label:
		hp_label.text = str(current_hp) + " / " + str(stats.max_hp)

func _adjust_sprite_scale() -> void:
	if sprite.texture == null: return
	var original_size: Vector2 = sprite.texture.get_size()
	var scale_factor: float = min(max_display_size.x / original_size.x, max_display_size.y / original_size.y)
	sprite.scale = Vector2(scale_factor, scale_factor)
	var shape = RectangleShape2D.new()
	shape.size = original_size * scale_factor
	collision_shape.shape = shape

func determine_next_move() -> EnemyAction:
	if stats == null or stats.moveset.is_empty():
		push_error("EnemyBase: " + (stats.enemy_name if stats else name) + " tidak memiliki moveset!")
		return null
		
	return stats.moveset.pick_random()

func start_turn_process() -> void:
	_on_turn_started()

	if is_stunned:
		is_stunned = false
		remove_status(StatusAilment.AilmentType.STUN)
		return

	if burn_stacks > 0:
		var burn_damage = 5
		take_damage(burn_damage)
		burn_stacks = max(0, burn_stacks - 1)
		if burn_stacks == 0:
			remove_status(StatusAilment.AilmentType.BURN)

	decrease_status_durations()

# Hook virtual untuk logika diawal turn
func _on_turn_started() -> void:
	pass

func execute_move(action: EnemyAction) -> void:
	if is_stunned or action == null:
		return
		
	match action.type:
		EnemyAction.ActionType.ATTACK:
			var final_atk = max(0, action.amount - toxic_stacks)
			EventBus.player_took_damage.emit(final_atk)
		EnemyAction.ActionType.SHIELD:
			current_shield += 10
		EnemyAction.ActionType.HEAL:
			current_hp = clampi(current_hp + 15, 0, stats.max_hp)

func take_damage(amount: int) -> void:
	var damage_multiplier = 1.0
	
	if has_status(StatusAilment.AilmentType.DESTABILIZE):
		if has_status(StatusAilment.AilmentType.VOLATILE):
			damage_multiplier = 2.0
		else:
			damage_multiplier = 1.5
			
	if has_status(StatusAilment.AilmentType.BURN):
		if has_status(StatusAilment.AilmentType.VOLATILE):
			remove_status(StatusAilment.AilmentType.BURN)
			remove_status(StatusAilment.AilmentType.VOLATILE)
	
	var base_calculated_damage = int(amount * damage_multiplier)
	
	var reduction_pct = _calculate_custom_damage_reduction()
	var final_damage = int(base_calculated_damage * (1.0 - reduction_pct))
	final_damage = max(0, final_damage)

	current_hp = clampi(current_hp - final_damage, 0, stats.max_hp)
	
	var tween = create_tween()
	tween.tween_property(hp_bar, "value", current_hp, 0.2).set_trans(Tween.TRANS_SINE)
	_update_hp_text()
	
	var flash_tween = create_tween()
	flash_tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	_on_health_changed(current_hp)

	if current_hp <= 0:
		EventBus.enemy_died.emit(self)
		die()

func _calculate_custom_damage_reduction() -> float:
	return 0.0

func _on_health_changed(_new_hp: int) -> void:
	pass

func add_toxic_stack(amount: int) -> void:
	toxic_stacks += amount
	if toxic_stacks >= 5:
		trigger_poison_explosion()

func trigger_poison_explosion() -> void:
	toxic_stacks = max(0, toxic_stacks - 5)
	take_damage(15)
	is_stunned = true
	var stun_resource = StatusAilment.new()
	stun_resource.ailment = StatusAilment.AilmentType.STUN
	apply_status(stun_resource, 1)

func apply_status(status_data: StatusAilment, duration: int) -> void:
	if status_data == null: return
	var ailment_id = status_data.ailment
	
	if ailment_id == StatusAilment.AilmentType.BURN:
		burn_stacks = 3
		
	active_statuses[ailment_id] = {
		"duration": duration,
		"resource": status_data
	}
	_update_status_ui()

func has_status(ailment_type: StatusAilment.AilmentType) -> bool:
	return active_statuses.has(ailment_type)

func remove_status(ailment_type: StatusAilment.AilmentType) -> void:
	if active_statuses.has(ailment_type):
		active_statuses.erase(ailment_type)
		_update_status_ui()

func decrease_status_durations() -> void:
	var keys_to_remove = []
	for ailment_id in active_statuses.keys():
		active_statuses[ailment_id]["duration"] -= 1
		if active_statuses[ailment_id]["duration"] <= 0:
			keys_to_remove.append(ailment_id)
			
	for ailment_id in keys_to_remove:
		active_statuses.erase(ailment_id)
		
	_update_status_ui()

func _update_status_ui() -> void:
	for child in status_container.get_children():
		child.queue_free()
		
	for ailment_id in active_statuses.keys():
		var status_info = active_statuses[ailment_id]
		var resource_data: StatusAilment = status_info["resource"]
		var current_duration: int = status_info["duration"]
		
		var icon_rect = TextureRect.new()
		icon_rect.texture = resource_data.status_icon
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.custom_minimum_size = Vector2(30, 30)
		icon_rect.modulate = resource_data.modulate
		
		var duration_label = Label.new()
		duration_label.text = str(current_duration)
		duration_label.add_theme_color_override("font_outline_color", Color.BLACK)
		duration_label.add_theme_constant_override("outline_size", 6)
		
		duration_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		duration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		duration_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		
		icon_rect.add_child(duration_label)
		status_container.add_child(icon_rect)

func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		SoundManager.play_sfx("enemy_select")
		if is_selected:
			EventBus.enemy_selected.emit(null)
		else:
			EventBus.enemy_selected.emit(self)

func _on_mouse_entered() -> void:
	if is_selected: return
	create_tween().tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)

func _on_mouse_exited() -> void:
	if is_selected: return
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.1)

func _on_any_enemy_selected(selected_enemy: EnemyBase) -> void:
	if selected_enemy == self:
		_become_selected()
	else:
		_become_deselected()

func _become_selected() -> void:
	if is_selected: return
	is_selected = true
	selection_aura.show()
	create_tween().tween_property(self, "scale", Vector2(1.15, 1.15), 0.3).set_trans(Tween.TRANS_BACK)
	
	if float_tween and float_tween.is_valid(): float_tween.kill()
	float_tween = create_tween().set_loops()
	float_tween.tween_property(sprite, "position:y", base_sprite_y - 15.0, 1.0).set_trans(Tween.TRANS_SINE)
	float_tween.tween_property(sprite, "position:y", base_sprite_y, 1.0).set_trans(Tween.TRANS_SINE)

func _become_deselected() -> void:
	if not is_selected: return
	is_selected = false
	selection_aura.hide()
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.2)
	if float_tween and float_tween.is_valid(): float_tween.kill()
	create_tween().tween_property(sprite, "position:y", base_sprite_y, 0.2)

func die() -> void:
	queue_free()
