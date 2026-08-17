class_name ShopItemSlot
extends Control

signal buy_requested(item_data: Resource, price: int, slot: ShopItemSlot)

const COLOR_NORMAL: Color = Color.WHITE
const COLOR_DISABLED: Color = Color(0.25, 0.25, 0.25, 1.0)

@export_group("Dimensions")
@export var slot_size: Vector2 = Vector2(170, 260):
	set(value):
		slot_size = value
		_update_slot_dimensions()

@export var icon_size: Vector2 = Vector2(150, 150):
	set(value):
		icon_size = value
		_update_icon_dimensions()

@export_group("Node References")
@export var icon_rect: TextureRect
@export var buy_button: Button
@export var price_label: Label

var item_data: Resource
var price: int = 0


func _ready() -> void:
	_update_slot_dimensions()
	_update_icon_dimensions()
	if buy_button:
		buy_button.pressed.connect(_on_buy_button_pressed)


func setup(data: Resource, item_price: int, item_icon: Texture2D, tooltip_str: String) -> void:
	item_data = data
	price = item_price
	tooltip_text = tooltip_str
	
	if icon_rect:
		icon_rect.texture = item_icon
	
	if price_label:
		price_label.text = "%d G" % price
		
	if buy_button:
		buy_button.disabled = false
		buy_button.modulate = COLOR_NORMAL


func mark_as_bought() -> void:
	if buy_button:
		buy_button.disabled = true
		buy_button.modulate = COLOR_DISABLED
		if price_label:
			price_label.text = "DIBELI"


func show_feedback(text: String, duration: float = 1.0) -> void:
	if not price_label:
		return
	var original_text: String = price_label.text
	price_label.text = text
	var tween: Tween = create_tween()
	tween.tween_interval(duration)
	tween.tween_callback(func():
		if is_instance_valid(price_label) and is_instance_valid(buy_button) and not buy_button.disabled:
			price_label.text = original_text
	)


func set_dimensions(new_slot_size: Vector2, new_icon_size: Vector2) -> void:
	if new_slot_size != Vector2.ZERO:
		slot_size = new_slot_size
	if new_icon_size != Vector2.ZERO:
		icon_size = new_icon_size


func _update_slot_dimensions() -> void:
	custom_minimum_size = slot_size


func _update_icon_dimensions() -> void:
	if is_instance_valid(icon_rect):
		icon_rect.custom_minimum_size = icon_size


func _on_buy_button_pressed() -> void:
	buy_requested.emit(item_data, price, self)
