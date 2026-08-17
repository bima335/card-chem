class_name ShopCardSlot
extends Control

signal action_requested(card_data: CardData, price: int, slot: ShopCardSlot)

enum SlotMode { BUY, SELL }

const COLOR_NORMAL: Color = Color.WHITE
const COLOR_DISABLED: Color = Color(0.25, 0.25, 0.25, 1.0)

@export_group("Dimensions")
@export var slot_size: Vector2 = Vector2(370, 600):
	set(value):
		slot_size = value
		_update_slot_dimensions()

@export var card_display_size: Vector2 = Vector2(300, 530):
	set(value):
		card_display_size = value
		_update_card_dimensions()

@export_group("Slot Textures")
@export var buy_background_texture: Texture2D
@export var sell_background_texture: Texture2D

@export_group("Node References")
@export var background_rect: TextureRect
@export var card_container: CenterContainer
@export var action_button: Button
@export var price_label: Label

var current_mode: SlotMode = SlotMode.BUY
var card_data: CardData
var price: int = 0
var card_ui_instance: CardUI


func _ready() -> void:
	_update_slot_dimensions()
	if action_button:
		action_button.pressed.connect(_on_action_button_pressed)


func setup(data: CardData, item_price: int, card_ui_scene: PackedScene, tooltip_str: String, mode: SlotMode = SlotMode.BUY) -> void:
	card_data = data
	price = item_price
	current_mode = mode
	
	_apply_visual_mode()

	if card_container and card_ui_scene:
		for child in card_container.get_children():
			child.queue_free()

		card_ui_instance = card_ui_scene.instantiate() as CardUI
		card_container.add_child(card_ui_instance)
		card_ui_instance.setup(card_data)
		card_ui_instance.is_preview = true
		card_ui_instance.tooltip_text = tooltip_str
		_update_card_dimensions()

	if price_label:
		price_label.text = "%d G" % price

	if action_button:
		action_button.disabled = false
		action_button.modulate = COLOR_NORMAL


func mark_as_bought() -> void:
	if action_button:
		action_button.disabled = true
		action_button.modulate = COLOR_DISABLED
		if price_label:
			price_label.text = "TERJUAL" if current_mode == SlotMode.SELL else "DIBELI"


func set_dimensions(new_slot_size: Vector2, new_card_size: Vector2) -> void:
	slot_size = new_slot_size
	card_display_size = new_card_size


func _apply_visual_mode() -> void:
	if background_rect:
		match current_mode:
			SlotMode.BUY:
				if buy_background_texture:
					background_rect.texture = buy_background_texture
			SlotMode.SELL:
				if sell_background_texture:
					background_rect.texture = sell_background_texture
				elif buy_background_texture:
					background_rect.texture = buy_background_texture


func _update_slot_dimensions() -> void:
	custom_minimum_size = slot_size


func _update_card_dimensions() -> void:
	if is_instance_valid(card_ui_instance):
		card_ui_instance.custom_minimum_size = card_display_size


func _on_action_button_pressed() -> void:
	action_requested.emit(card_data, price, self)
