class_name CardUI
extends TextureButton

var data: CardData

@export var hover_scale: Vector2 = Vector2(1.2, 1.2)
@export var hover_rotation_degrees: float = 3.0
@export var animation_duration: float = 0.25

@onready var name_label: Label = $TooltipPanel/VBoxContainer/Name
@onready var cost_label: Label = $TooltipPanel/VBoxContainer/Cost
@onready var tooltip_panel: Control = $TooltipPanel

var hover_tween: Tween

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(card_data: CardData) -> void:
	data = card_data
	texture_normal = data.card_texture
	if texture_normal:
		pivot_offset = custom_minimum_size / 2.0
	_setup_tooltip_text()

func _setup_tooltip_text() -> void:
	if not data: return
	name_label.text = data.card_name
	
	var cost_string: String = ""
	if data.cost_carbon > 0: cost_string += "[C: " + str(data.cost_carbon) + "] "
	if data.cost_hydrogen > 0: cost_string += "[H: " + str(data.cost_hydrogen) + "] "
	if data.cost_oxygen > 0: cost_string += "[O: " + str(data.cost_oxygen) + "] "
	if data.cost_nitrogen > 0: cost_string += "[N: " + str(data.cost_nitrogen) + "] "
	
	if cost_string == "": cost_string = "Gratis!"
	cost_label.text = cost_string.strip_edges()

func _on_mouse_entered() -> void:
	SoundManager.play_sfx("card_hover")
	z_index = 10 
	
	var random_dir: float = 1.0 if randf() > 0.5 else -1.0
	var target_rot: float = deg_to_rad(hover_rotation_degrees) * random_dir
	_animate_hover(hover_scale, target_rot)

	if tooltip_panel:
		tooltip_panel.show()
		tooltip_panel.reset_size()
		
		var target_x: float = global_position.x + (size.x / 2.0) - (tooltip_panel.size.x / 2.0)
		var target_y: float = global_position.y - tooltip_panel.size.y - 15.0
		tooltip_panel.global_position = Vector2(target_x, target_y)

func _on_mouse_exited() -> void:
	z_index = 0
	_animate_hover(Vector2.ONE, 0.0) 
	if tooltip_panel:
		tooltip_panel.hide()

func _animate_hover(target_scale: Vector2, target_rotation: float) -> void:
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		
	hover_tween = create_tween()
	hover_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	hover_tween.set_parallel(true)
	hover_tween.tween_property(self, "scale", target_scale, animation_duration)
	hover_tween.tween_property(self, "rotation", target_rotation, animation_duration)
