class_name EnemyBase
extends Node2D

signal health_updated(current: int, max_val: int)
@export var stats: EnemyStat 
@export var exposed_resource_data: StatusAilment 

var active_statuses: Dictionary = {}
var current_hp: int
var current_shield: int = 0
var is_stunned: bool = false
var is_targetable: bool = true

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var selection_aura: Sprite2D = $SelectionAura
@onready var click_area: Area2D = $ClickArea
@onready var collision_shape: CollisionShape2D = $ClickArea/CollisionShape2D
@onready var hp_bar: TextureProgressBar = $HPBar
@onready var hp_label: Label = $HPBar/Label
@onready var status_container: HBoxContainer = $StatusContainer

var is_selected: bool = false
var float_tween: Tween
var base_sprite_y: float
var _sprite_material: ShaderMaterial


func _ready() -> void:
	_init_material()
	_init_stats()
	_init_animations()
	
	click_area.input_event.connect(_on_click_area_input_event)
	click_area.mouse_entered.connect(_on_mouse_entered)
	click_area.mouse_exited.connect(_on_mouse_exited)
	
	base_sprite_y = animated_sprite.position.y if animated_sprite.visible else sprite.position.y
	EventBus.enemy_selected.connect(_on_any_enemy_selected)
	
	_setup_enemy()
	play_anim(&"idle")


func _init_stats() -> void:
	if stats == null:
		return
		
	current_hp = stats.max_hp
	hp_bar.max_value = stats.max_hp
	hp_bar.value = current_hp
	_update_hp_text()
	
	if stats.tag == EnemyStat.EnemyTag.BOSS:
		hp_bar.hide()
		if status_container:
			var top_edge_y: float = stats.click_area_offset.y - (stats.click_area_size.y * 0.5)
			status_container.position.x = -(status_container.size.x * 0.5)
			status_container.position.y = top_edge_y - stats.ui_vertical_offset - status_container.size.y
	
	if stats.texture:
		if sprite:
			sprite.texture = stats.texture
		if selection_aura:
			selection_aura.texture = stats.texture

	_apply_manual_sizing()
	health_updated.emit(current_hp, stats.max_hp)


func _apply_manual_sizing() -> void:
	if stats == null:
		return

	if animated_sprite:
		animated_sprite.scale = stats.sprite_scale
	if sprite:
		sprite.scale = stats.sprite_scale
	if selection_aura:
		selection_aura.scale = stats.sprite_scale * 1.15

	var custom_rect := RectangleShape2D.new()
	custom_rect.size = stats.click_area_size
	collision_shape.shape = custom_rect
	collision_shape.position = stats.click_area_offset

	_reposition_ui_elements(stats.click_area_size, stats.click_area_offset, stats.ui_vertical_offset)


func _reposition_ui_elements(box_size: Vector2, box_offset: Vector2, gap_offset: float) -> void:
	var top_edge_y: float = box_offset.y - (box_size.y * 0.5)

	if hp_bar:
		hp_bar.position.x = -(hp_bar.size.x * 0.5)
		hp_bar.position.y = top_edge_y - gap_offset - hp_bar.size.y

		if status_container:
			status_container.position.x = -(status_container.size.x * 0.5)
			status_container.position.y = hp_bar.position.y - status_container.size.y - 6.0


func _init_material() -> void:
	if animated_sprite.material is ShaderMaterial:
		_sprite_material = animated_sprite.material.duplicate() as ShaderMaterial
		animated_sprite.material = _sprite_material
		_set_shader_selected(false)


func _set_shader_selected(selected: bool) -> void:
	if _sprite_material:
		_sprite_material.set_shader_parameter("is_selected", selected)


func _init_animations() -> void:
	if anim_player == null or stats == null or stats.animation_library == null:
		return
		
	if anim_player.has_animation_library(&""):
		anim_player.remove_animation_library(&"")
		
	anim_player.add_animation_library(&"", stats.animation_library)


func play_anim(anim_name: StringName, custom_blend: float = -1.0, custom_speed: float = 1.0, from_end: bool = false) -> bool:
	if anim_player and anim_player.has_animation(anim_name):
		anim_player.play(anim_name, custom_blend, custom_speed, from_end)
		return true
	return false


func play_anim_and_wait(anim_name: StringName) -> void:
	if play_anim(anim_name):
		await anim_player.animation_finished


func _setup_enemy() -> void:
	pass


func _update_hp_text() -> void:
	if hp_label:
		hp_label.text = str(current_hp) + " / " + str(stats.max_hp)


func determine_next_move() -> EnemyAction:
	if stats == null or stats.moveset.is_empty():
		push_error("EnemyBase: " + (stats.enemy_name if stats else name) + " tidak memiliki moveset!")
		return null
		
	return stats.moveset.pick_random()


func start_turn_process() -> void:
	_on_turn_started()

	if has_status(StatusAilment.AilmentType.BURN):
		var burn_damage = 5
		take_damage(burn_damage, false)
		EventBus.burn_damage_dealt.emit(burn_damage)


func execute_move(action: EnemyAction) -> void:
	if is_stunned:
		end_turn_process()
		return
		
	if action != null:
		match action.type:
			EnemyAction.ActionType.ATTACK:
				await play_anim_and_wait(&"attack")
				var toxic_stacks = get_status_stacks(StatusAilment.AilmentType.TOXIC)
				var final_atk = max(0, action.amount - toxic_stacks)
				EventBus.player_damage_requested.emit(final_atk, self)
				
			EnemyAction.ActionType.SHIELD:
				await play_anim_and_wait(&"skill")
				current_shield += 10
				
			EnemyAction.ActionType.HEAL:
				await play_anim_and_wait(&"skill")
				current_hp = clampi(current_hp + 15, 0, stats.max_hp)
				
			EnemyAction.ActionType.SKILL:
				await play_anim_and_wait(&"skill")
				_execute_custom_skill(action)

	play_anim(&"idle")
	end_turn_process()

func _execute_custom_skill(_action: EnemyAction) -> void:
	pass

func end_turn_process() -> void:
	decrease_status_durations()


func _on_turn_started() -> void:
	pass


func set_targetable(enable: bool) -> void:
	if is_targetable == enable:
		return
		
	is_targetable = enable
	
	click_area.monitoring = is_targetable
	click_area.monitorable = is_targetable
	collision_shape.set_deferred("disabled", not is_targetable)
	
	if not is_targetable and is_selected:
		EventBus.enemy_selected.emit(null)
		
	var target_alpha: float = 1.0 if is_targetable else 0.4
	var active_visual = animated_sprite if animated_sprite.visible else sprite
	create_tween().tween_property(active_visual, "modulate:a", target_alpha, 0.2)


func toggle_targetable(enable: Variant = null) -> void:
	if enable == null:
		set_targetable(not is_targetable)
	else:
		set_targetable(bool(enable))


func take_damage(amount: int, is_direct_attack: bool = false) -> void:
	if not is_targetable:
		return
		
	var damage_multiplier: float = 1.0
	var flat_bonus_damage: int = 0
	
	var has_disintegrate: bool = has_status(StatusAilment.AilmentType.DISINTEGRATE)
	var has_destabilize: bool = has_status(StatusAilment.AilmentType.DESTABILIZE)
	
	if has_disintegrate:
		damage_multiplier = 2.0
	elif has_destabilize:
		if has_status(StatusAilment.AilmentType.VOLATILE):
			damage_multiplier = 2.0
		else:
			damage_multiplier = 1.5
			
		if is_direct_attack and BlessingManager.has_blessing(BlessingData.BlessingID.OVER_ACCIDIC):
			flat_bonus_damage = 3
			
	if has_status(StatusAilment.AilmentType.BURN):
		if has_status(StatusAilment.AilmentType.VOLATILE):
			remove_status(StatusAilment.AilmentType.BURN)
			remove_status(StatusAilment.AilmentType.VOLATILE)
	
	var exposed_stacks = get_status_stacks(StatusAilment.AilmentType.EXPOSED)
	if exposed_stacks > 0:
		damage_multiplier += (exposed_stacks * 0.15)
	
	var base_calculated_damage = int(amount * damage_multiplier) + flat_bonus_damage
	var reduction_pct = _calculate_custom_damage_reduction()
	var final_damage = max(0, int(base_calculated_damage * (1.0 - reduction_pct)))

	current_hp = clampi(current_hp - final_damage, 0, stats.max_hp)
	
	if is_direct_attack:
		consume_hit_based_statuses()
	
	var tween = create_tween()
	tween.tween_property(hp_bar, "value", current_hp, 0.2).set_trans(Tween.TRANS_SINE)
	_update_hp_text()
	
	var active_visual = animated_sprite if animated_sprite.visible else sprite
	var flash_tween = create_tween()
	flash_tween.tween_property(active_visual, "modulate", Color.RED, 0.1)
	flash_tween.tween_property(active_visual, "modulate", Color.WHITE, 0.1)
	health_updated.emit(current_hp, stats.max_hp)
	_on_health_changed(current_hp)

	if is_direct_attack:
		AuraManager.process_neon_illuminate_post_damage(self)

	if current_hp <= 0:
		set_targetable(false)
		die()


func consume_hit_based_statuses() -> void:
	if has_status(StatusAilment.AilmentType.DISINTEGRATE):
		_decrement_status_duration(StatusAilment.AilmentType.DISINTEGRATE)
	elif has_status(StatusAilment.AilmentType.DESTABILIZE):
		_decrement_status_duration(StatusAilment.AilmentType.DESTABILIZE)


func _decrement_status_duration(ailment_type: StatusAilment.AilmentType) -> void:
	if not active_statuses.has(ailment_type):
		return
		
	active_statuses[ailment_type]["duration"] -= 1
	if active_statuses[ailment_type]["duration"] <= 0:
		remove_status(ailment_type)
	else:
		_update_status_ui()


func _calculate_custom_damage_reduction() -> float:
	return 0.0


func _on_health_changed(_new_hp: int) -> void:
	pass


func apply_status(status_data: StatusAilment, duration: int = 1, initial_stacks: int = 1) -> void:
	if not is_targetable or status_data == null: 
		return
		
	var ailment_id = status_data.ailment
	
	if ailment_id == StatusAilment.AilmentType.STUN:
		is_stunned = true

	if active_statuses.has(ailment_id):
		active_statuses[ailment_id]["duration"] += duration
		active_statuses[ailment_id]["stacks"] += initial_stacks
	else:
		active_statuses[ailment_id] = {
			"duration": duration,
			"stacks": initial_stacks,
			"resource": status_data
		}
		
	_update_status_ui()
	EventBus.enemy_status_applied.emit(self, ailment_id)


func add_status_stacks(ailment_type: StatusAilment.AilmentType, amount: int, default_res: StatusAilment = null) -> void:
	if not active_statuses.has(ailment_type):
		if default_res != null:
			apply_status(default_res, default_res.default_duration, amount)
		return
		
	active_statuses[ailment_type]["stacks"] += amount
	if active_statuses[ailment_type]["stacks"] <= 0:
		remove_status(ailment_type)
	else:
		_update_status_ui()


func get_status_stacks(ailment_type: StatusAilment.AilmentType) -> int:
	if active_statuses.has(ailment_type):
		return active_statuses[ailment_type].get("stacks", 0)
	return 0


func get_status_duration(ailment_type: StatusAilment.AilmentType) -> int:
	if active_statuses.has(ailment_type):
		return active_statuses[ailment_type].get("duration", 0)
	return 0


func has_status(ailment_type: StatusAilment.AilmentType) -> bool:
	return active_statuses.has(ailment_type)


func remove_status(ailment_type: StatusAilment.AilmentType) -> void:
	if ailment_type == StatusAilment.AilmentType.STUN:
		is_stunned = false

	if active_statuses.has(ailment_type):
		active_statuses.erase(ailment_type)
		_update_status_ui()


func decrease_status_durations() -> void:
	var keys_to_remove = []
	for ailment_id in active_statuses.keys():
		var status_info = active_statuses[ailment_id]
		var res: StatusAilment = status_info.get("resource")
		
		if res != null and not res.decrease_on_turn_end:
			continue
			
		if res != null and res.use_stacks_for_display:
			status_info["stacks"] -= 1
			if status_info["stacks"] <= 0:
				keys_to_remove.append(ailment_id)
		else:
			status_info["duration"] -= 1
			if status_info["duration"] <= 0:
				keys_to_remove.append(ailment_id)
			
	for ailment_id in keys_to_remove:
		remove_status(ailment_id)
		
	_update_status_ui()


func _update_status_ui() -> void:
	for child in status_container.get_children():
		child.queue_free()
		
	for ailment_id in active_statuses.keys():
		var status_info = active_statuses[ailment_id]
		var resource_data: StatusAilment = status_info["resource"]
		var current_duration: int = status_info["duration"]
		var current_stacks: int = status_info["stacks"]
		
		var icon_rect = TextureRect.new()
		if resource_data:
			icon_rect.texture = resource_data.status_icon
			icon_rect.modulate = resource_data.modulate
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.custom_minimum_size = Vector2(30, 30)
		
		var label = Label.new()
		
		if resource_data and resource_data.use_stacks_for_display:
			label.text = str(current_stacks)
		else:
			label.text = str(current_duration)

		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 6)
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		
		icon_rect.add_child(label)
		status_container.add_child(icon_rect)


func add_exposed_stack(amount: int = 1) -> void:
	if not has_status(StatusAilment.AilmentType.EXPOSED):
		apply_status(exposed_resource_data, 999, amount)
	else:
		add_status_stacks(StatusAilment.AilmentType.EXPOSED, amount)


func add_toxic_stack(amount: int, poison_resource: StatusAilment = null, stun_resource: StatusAilment = null, toxic_resource: StatusAilment = null) -> void:
	if not has_status(StatusAilment.AilmentType.TOXIC):
		apply_status(toxic_resource, 999, amount)
	else:
		add_status_stacks(StatusAilment.AilmentType.TOXIC, amount)
	
	if get_status_stacks(StatusAilment.AilmentType.TOXIC) >= 5:
		trigger_poison_explosion(poison_resource, stun_resource)


func trigger_poison_explosion(poison_resource: StatusAilment = null, stun_resource: StatusAilment = null) -> void:
	remove_status(StatusAilment.AilmentType.TOXIC)
	EventBus.poison_explosion_triggered.emit(self)
	
	var poison_dur = poison_resource.default_duration if poison_resource else 1
	apply_status(poison_resource, poison_dur)

	var stun_dur = stun_resource.default_duration if stun_resource else 1
	apply_status(stun_resource, stun_dur)


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
	if is_selected: 
		return
	is_selected = true
	_set_shader_selected(true)
	
	create_tween().tween_property(self, "scale", Vector2(1.15, 1.15), 0.3).set_trans(Tween.TRANS_BACK)
	
	var target_visual = animated_sprite if animated_sprite.visible else sprite
	if float_tween and float_tween.is_valid(): 
		float_tween.kill()
	float_tween = create_tween().set_loops()
	float_tween.tween_property(target_visual, "position:y", base_sprite_y - 15.0, 1.0).set_trans(Tween.TRANS_SINE)
	float_tween.tween_property(target_visual, "position:y", base_sprite_y, 1.0).set_trans(Tween.TRANS_SINE)


func _become_deselected() -> void:
	if not is_selected: 
		return
	is_selected = false
	_set_shader_selected(false)
	
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.2)
	var target_visual = animated_sprite if animated_sprite.visible else sprite
	if float_tween and float_tween.is_valid(): 
		float_tween.kill()
	create_tween().tween_property(target_visual, "position:y", base_sprite_y, 0.2)


func die() -> void:
	var is_boss: bool = false
	if stats and stats.tag == EnemyStat.EnemyTag.BOSS:
		is_boss = true

	EventBus.enemy_killed.emit(self, is_boss)
	
	await play_anim_and_wait(&"death")
	
	EventBus.enemy_died.emit(self)
	queue_free()
