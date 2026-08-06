class_name EnemyBase
extends Node2D

@export var stats: EnemyStat 
@export var max_display_size: Vector2 = Vector2(150.0, 150.0)

var current_hp: int
var current_shield: int = 0
var base_attack_power_modifier: int = 0

# Status & Tag System
var has_oxidize: bool = false
var has_corrosion: bool = false
var has_volatile: bool = false
var toxic_stacks: int = 0
var burn_stacks: int = 0

var destabilize_duration: int = 0
var is_destabilized: bool = false
var is_volatile_destabilize: bool = false

var stun_duration: int = 0

@onready var sprite: Sprite2D = $Sprite2D
@onready var selection_aura: Sprite2D = $SelectionAura
@onready var click_area: Area2D = $ClickArea
@onready var collision_shape: CollisionShape2D = $ClickArea/CollisionShape2D
@onready var hp_bar: ProgressBar = $HPBar
@onready var hp_label: Label = $HPBar/Label

var is_selected: bool = false

func _ready() -> void:
	if stats:
		current_hp = stats.max_hp
		if hp_bar:
			hp_bar.max_value = stats.max_hp
			hp_bar.value = current_hp
		_update_hp_text()
		if sprite and stats.texture:
			sprite.texture = stats.texture
			_adjust_sprite_scale()
			selection_aura.texture = stats.texture
			selection_aura.scale = sprite.scale * 1.15

	EventBus.enemy_selected.connect(_on_any_enemy_selected)

func process_turn_start() -> bool:
	# 1. Olah Efek Burn
	if burn_stacks > 0:
		var burn_damage = burn_stacks * 5
		take_damage(burn_damage)
		burn_stacks -= 1
		print(stats.enemy_name, " terkena Burn Damage: ", burn_damage, " | Sisa Burn Stack: ", burn_stacks)
	
	# 2. Cek Efek Stun (Mabuk akibat Poison)
	if stun_duration > 0:
		print(stats.enemy_name, " ter-STUN dan tidak bisa bergerak turn ini!")
		return false # Return false menandakan musuh tidak boleh mengeksekusi aksi
		
	return true # Boleh bertindak

func process_turn_end() -> void:
	# Kelola durasi Destabilize
	if destabilize_duration > 0:
		destabilize_duration -= 1
		if destabilize_duration == 0:
			is_destabilized = false
			is_volatile_destabilize = false
			print("Efek Destabilize pada ", stats.enemy_name, " telah berakhir.")
			
	# Kelola durasi Stun
	if stun_duration > 0:
		stun_duration -= 1

func add_toxic_stacks(amount: int, stage_manager: Node) -> void:
	toxic_stacks += amount
	print(stats.enemy_name, " mendapat ", amount, " Toxic Stack. Total: ", toxic_stacks)
	
	if toxic_stacks >= 5:
		_trigger_poison_explosion(stage_manager)

func _trigger_poison_explosion(stage_manager: Node) -> void:
	toxic_stacks -= 5
	var explosion_damage = 10
	take_damage(explosion_damage)
	stun_duration = 1 # Stun 1 round setelah ledakan
	print("POISON MELEDAK pada ", stats.enemy_name, "! Stun diaplikasikan untuk 1 turn.")
	
	# Unique: Poison + Volatile -> Menyebarkan 2 toxic stack ke semua musuh lain
	if has_volatile and stage_manager:
		has_volatile = false
		for child in stage_manager.get_children():
			if child is EnemyBase and child != self and not child.is_queued_for_deletion():
				child.add_toxic_stacks(2, stage_manager)

func apply_burn_stacks(stacks: int = 3) -> void:
	burn_stacks += stacks
	print(stats.enemy_name, " terkena Burn sebanyak ", stacks, " stack! Total: ", burn_stacks)

func trigger_ignite(stage_manager: Node) -> void:
	if has_oxidize:
		has_oxidize = false
		if has_volatile and stage_manager:
			# Reaksi Burn + Volatile: Konsumsi semua burn, damage AoE menyebar
			has_volatile = false
			var total_burn_damage = 5
			burn_stacks = 0
			
			for child in stage_manager.get_children():
				if child is EnemyBase and not child.is_queued_for_deletion():
					child.take_damage(total_burn_damage)
		else:
			apply_burn_stacks(3)

func trigger_destabilize(is_volatile: bool) -> void:
	if has_corrosion and has_oxidize:
		has_corrosion = false
		has_oxidize = false
		is_destabilized = true
		is_volatile_destabilize = is_volatile
		destabilize_duration = 2
		print("DESTABILIZE AKTIF pada ", stats.enemy_name, " selama 2 round!")

func calculate_incoming_damage(base_dmg: int) -> int:
	var final_dmg: float = float(base_dmg)
	
	if is_destabilized:
		if is_volatile_destabilize:
			final_dmg *= 2.0 # 200% Damage
		else:
			final_dmg *= 1.5 # 150% Damage
			
	return int(final_dmg)

func take_damage(amount: int) -> void:
	var calculated_dmg = calculate_incoming_damage(amount)
	
	current_hp = clampi(current_hp - calculated_dmg, 0, stats.max_hp)
	
	if hp_bar:
		var tween = create_tween()
		tween.tween_property(hp_bar, "value", current_hp, 0.2).set_trans(Tween.TRANS_SINE)
	_update_hp_text()
	
	if sprite:
		var flash_tween = create_tween()
		flash_tween.tween_property(sprite, "modulate", Color.RED, 0.1)
		flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if current_hp <= 0:
		EventBus.enemy_died.emit(self)
		queue_free()

func _update_hp_text() -> void:
	if hp_label and stats:
		hp_label.text = str(current_hp) + " / " + str(stats.max_hp)

func _adjust_sprite_scale() -> void:
	if sprite == null or sprite.texture == null: return
	var original_size: Vector2 = sprite.texture.get_size()
	var scale_factor: float = min(max_display_size.x / original_size.x, max_display_size.y / original_size.y)
	sprite.scale = Vector2(scale_factor, scale_factor)
	if collision_shape:
		var shape = RectangleShape2D.new()
		shape.size = original_size * scale_factor
		collision_shape.shape = shape

func _on_any_enemy_selected(selected_enemy: EnemyBase) -> void:
	if selected_enemy == self:
		is_selected = true
		if selection_aura: selection_aura.show()
	else:
		is_selected = false
		if selection_aura: selection_aura.hide()
