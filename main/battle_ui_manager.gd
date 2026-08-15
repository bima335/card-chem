class_name BattleUIManager
extends Node

@export var card_ui_scene: PackedScene

@export_group("UI Elements")
@export var hand_container: Control
@export var end_turn_button: TextureButton
@export var deck_visual: TextureButton
@export var discard_visual: TextureButton
@export var close_deck_button: Button
@export var blessing_container: VBoxContainer
@export var blessing_item_scene: PackedScene

@export_group("Aura UI")
@export var aura_container: Control
@export var aura_ui_scene: PackedScene

@export_group("Player HUD")
@export var player_hp_bar: TextureProgressBar
@export var player_hp_label: Label
@export var player_shield_bar: TextureProgressBar
@export var player_shield_label: Label
@export var token_container: Control

@export_group("Token Visual Containers")
@export var c_token_container: HBoxContainer
@export var h_token_container: HBoxContainer
@export var o_token_container: HBoxContainer
@export var n_token_container: HBoxContainer

@export_group("Token Textures")
@export var token_c_tex: Texture2D
@export var token_h_tex: Texture2D
@export var token_o_tex: Texture2D
@export var token_n_tex: Texture2D

@export_group("Token Layout Settings")
@export var token_spacing: int = 8
@export var token_icon_size: Vector2 = Vector2(32, 32)

@export_group("Deck Viewer Panel")
@export var deck_backdrop: ColorRect
@export var deck_view_panel: PanelContainer
@export var panel_title_label: Label
@export var card_grid: GridContainer

@export_group("Hand Fan Layout")
@export var hand_card_spacing: float = 70.0
@export var hand_max_hand_width: float = 760.0
@export var hand_fan_angle_degrees: float = 8.0
@export var hand_arc_height: float = 30.0
@export var hand_bottom_margin: float = 10.0
@export var hand_layout_duration: float = 0.22


var _end_turn_tween: Tween

@export_category("Gold")
@export var gold_label: Label

signal card_clicked_in_viewer(card_data: CardData)


func _ready() -> void:
	close_deck_button.pressed.connect(hide_deck_viewer)
	
	if EventBus.has_signal("blessing_list_changed"):
		EventBus.blessing_list_changed.connect(update_blessings_display)
	
	_setup_end_turn_button()
	_connect_aura_signals()
	_connect_gold_signals()
	update_gold_display(GameManager.shop_coins)
	update_blessings_display()
	update_aura_display()


func _connect_aura_signals() -> void:
	if AuraManager.has_signal("aura_equipped"):
		AuraManager.aura_equipped.connect(_on_aura_changed)
	if AuraManager.has_signal("aura_unequipped"):
		AuraManager.aura_unequipped.connect(_on_aura_changed_slot)


func _on_aura_changed(_aura_data: AuraCardData, _slot_index: int) -> void:
	update_aura_display()


func _on_aura_changed_slot(_slot_index: int) -> void:
	update_aura_display()

func update_aura_display() -> void:
	if not aura_container:
		return

	var slots = aura_container.get_children()

	for slot_index in range(AuraManager.MAX_AURA_SLOTS):
		if slot_index >= slots.size():
			continue

		var current_slot: Control = slots[slot_index]
		
		# Bersihkan UI kartu lama di dalam slot tanpa menghapus node slot itu sendiri
		for child in current_slot.get_children():
			child.queue_free()

		var aura_data: AuraCardData = AuraManager.equipped_auras[slot_index] if slot_index < AuraManager.equipped_auras.size() else null

		if aura_data != null and aura_ui_scene != null:
			var aura_ui: AuraCardUI = aura_ui_scene.instantiate() as AuraCardUI
			aura_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			aura_ui.offset_left = -6.0 
			aura_ui.offset_right = -8.0
			aura_ui.offset_top = -0
			aura_ui.offset_bottom = -7.0
			aura_ui.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			aura_ui.size_flags_vertical = Control.SIZE_EXPAND_FILL
			current_slot.add_child(aura_ui)
			aura_ui.setup(aura_data)


func _show_aura_placeholder(slot_index: int) -> void:
	var placeholder_panel: PanelContainer = PanelContainer.new()
	placeholder_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placeholder_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var placeholder_label: Label = Label.new()
	placeholder_label.text = "SLOT " + str(slot_index + 1)
	placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	placeholder_label.modulate = Color(1.0, 1.0, 1.0, 0.4)
	
	placeholder_panel.add_child(placeholder_label)
	aura_container.add_child(placeholder_panel)


func update_tokens(o: int, h: int, c: int, n: int) -> void:
	_render_token_icons(c_token_container, token_c_tex, c)
	_render_token_icons(h_token_container, token_h_tex, h)
	_render_token_icons(o_token_container, token_o_tex, o)
	_render_token_icons(n_token_container, token_n_tex, n)

	var tween = create_tween()
	tween.tween_property(token_container, "scale", Vector2(1.05, 1.05), 0.1)
	tween.tween_property(token_container, "scale", Vector2.ONE, 0.1)


func _render_token_icons(container: HBoxContainer, texture: Texture2D, count: int) -> void:
	if not container or not texture:
		return
		
	container.add_theme_constant_override("separation", token_spacing)
		
	for child in container.get_children():
		child.queue_free()
		
	for i in range(count):
		var icon = TextureRect.new()
		icon.texture = texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = token_icon_size
		container.add_child(icon)


func update_player_stats(hp: int, max_hp: int, shield: int, _damage: int) -> void:
	player_hp_bar.max_value = max_hp
	var hp_tween = create_tween()
	hp_tween.tween_property(player_hp_bar, "value", hp, 0.3).set_trans(Tween.TRANS_BOUNCE)
	
	if player_hp_label:
		player_hp_label.text = str(hp) + " / " + str(max_hp)
		
	player_shield_bar.max_value = max_hp 
	var shield_tween = create_tween()
	shield_tween.tween_property(player_shield_bar, "value", shield, 0.3).set_trans(Tween.TRANS_SINE)
	
	if player_shield_label:
		if shield > 0:
			player_shield_label.text = "Shield: " + str(shield)
			player_shield_bar.show()
		else:
			player_shield_label.text = ""
			player_shield_bar.hide()


func show_card_viewer(cards_to_show: Array[CardData], title_text: String, is_selecting_effect: bool) -> void:
	panel_title_label.text = title_text
	
	for child in card_grid.get_children():
		child.queue_free()
		
	for card_data in cards_to_show:
		var card_instance = card_ui_scene.instantiate() as CardUI
		card_grid.add_child(card_instance)
		card_instance.setup(card_data)
		card_instance.is_preview = true 
		
		if is_selecting_effect:
			card_instance.pressed.connect(func(): card_clicked_in_viewer.emit(card_data))
			
	if is_selecting_effect:
		close_deck_button.hide()
	else:
		close_deck_button.show()
		
	deck_backdrop.show()
	deck_view_panel.show()
	
	deck_backdrop.modulate.a = 0.0
	deck_view_panel.modulate.a = 0.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(deck_backdrop, "modulate:a", 1.0, 0.2)
	tween.tween_property(deck_view_panel, "modulate:a", 1.0, 0.2)


func hide_deck_viewer() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(deck_backdrop, "modulate:a", 0.0, 0.15)
	tween.tween_property(deck_view_panel, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(deck_view_panel.hide)
	tween.chain().tween_callback(deck_backdrop.hide)

func arrange_hand() -> void:
	if not hand_container:
		return

	var cards: Array[CardUI] = []
	for child in hand_container.get_children():
		if child is CardUI and is_instance_valid(child) and not child.is_queued_for_deletion():
			cards.append(child)

	var count: int = cards.size()
	if count == 0:
		return

	var spacing: float = hand_card_spacing
	if count > 1:
		var total_span: float = spacing * (count - 1)
		if total_span > hand_max_hand_width:
			spacing = hand_max_hand_width / float(count - 1)

	var container_size: Vector2 = hand_container.size
	var center_x: float = container_size.x / 2.0
	var base_y: float = container_size.y - hand_bottom_margin

	for i in range(count):
		var card: CardUI = cards[i]

		var card_size: Vector2 = card.custom_minimum_size
		if card_size == Vector2.ZERO:
			card_size = card.size

		var offset_index: float = i - float(count - 1) / 2.0
		var normalized: float = 0.0
		if count > 1:
			normalized = offset_index / (float(count - 1) / 2.0)

		var target_x: float = center_x + offset_index * spacing - card_size.x / 2.0
		var target_y: float = base_y - card_size.y - hand_arc_height * (1.0 - normalized * normalized)
		var target_rotation: float = deg_to_rad(normalized * hand_fan_angle_degrees)
		var target_position: Vector2 = Vector2(target_x, target_y)

		card.pivot_offset = card_size / 2.0
		card.hand_position = target_position
		card.hand_rotation = target_rotation
		card.hand_z_index = i

		if card.is_dragging or card.is_returning:
			continue

		card.z_index = i

		if card.modulate.a < 0.99:
			card.position = target_position
			card.rotation = target_rotation
		else:
			var tween: Tween = card.create_tween()
			tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.set_parallel(true)
			tween.tween_property(card, "position", target_position, hand_layout_duration)
			tween.tween_property(card, "rotation", target_rotation, hand_layout_duration)

func animate_draw_card(new_card_data: CardData, on_land_callback: Callable) -> void:
	var real_card: CardUI = card_ui_scene.instantiate() as CardUI
	hand_container.add_child(real_card)
	real_card.setup(new_card_data)
	real_card.modulate = Color(1, 1, 1, 0)
	arrange_hand()
	
	await get_tree().process_frame
	
	var dummy_card: CardUI = card_ui_scene.instantiate() as CardUI
	get_tree().root.add_child(dummy_card)
	dummy_card.setup(new_card_data)
	dummy_card.global_position = deck_visual.global_position
	
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(dummy_card, "global_position", real_card.global_position, 0.4)
	
	tween.finished.connect(func():
		dummy_card.queue_free()
		real_card.modulate = Color.WHITE
		on_land_callback.call(real_card)
	)


func reject_play(card_ui: CardUI) -> void:
	var error_tween = create_tween()
	error_tween.tween_property(card_ui, "modulate", Color.RED, 0.1)
	error_tween.tween_property(card_ui, "modulate", Color.WHITE, 0.1)


func clear_hand_visuals() -> void:
	for child in hand_container.get_children():
		child.queue_free()


func update_blessings_display() -> void:
	if not blessing_container or not blessing_item_scene:
		return

	var slots: Array[Node] = blessing_container.get_children()
	var active_blessings: Array[BlessingData] = BlessingManager.active_blessings

	for i in range(slots.size()):
		var slot_node: Control = slots[i] as Control
		if not slot_node:
			continue
			
		for child in slot_node.get_children():
			child.queue_free()

		if i < active_blessings.size():
			var blessing_data: BlessingData = active_blessings[i]
			var blessing_ui: BlessingUIItem = blessing_item_scene.instantiate() as BlessingUIItem
			
			slot_node.add_child(blessing_ui)
			
			blessing_ui.custom_minimum_size = Vector2(60, 60)
			blessing_ui.set_anchors_preset(Control.PRESET_CENTER)
			blessing_ui.offset_left = -30.0
			blessing_ui.offset_top = -30.0
			blessing_ui.offset_right = 30.0
			blessing_ui.offset_bottom = 30.0
			blessing_ui.grow_horizontal = Control.GROW_DIRECTION_BOTH
			blessing_ui.grow_vertical = Control.GROW_DIRECTION_BOTH
			
			blessing_ui.setup(blessing_data)

func _connect_gold_signals() -> void:
	if EventBus.has_signal("gold_changed"):
		if not EventBus.gold_changed.is_connected(_on_gold_changed):
			EventBus.gold_changed.connect(_on_gold_changed)

func _on_gold_changed(total_gold: int) -> void:
	update_gold_display(total_gold)

func update_gold_display(amount: int) -> void:
	if gold_label:
		gold_label.text = str(amount)

func _setup_end_turn_button() -> void:
	if not end_turn_button:
		return
	
	_generate_click_mask(end_turn_button)
	
	end_turn_button.resized.connect(_update_end_turn_pivot)
	_update_end_turn_pivot()
	
	end_turn_button.mouse_entered.connect(_on_end_turn_button_mouse_entered)
	end_turn_button.mouse_exited.connect(_on_end_turn_button_mouse_exited)

func _generate_click_mask(button: TextureButton) -> void:
	if not button.texture_normal:
		return
	
	var texture_image: Image = button.texture_normal.get_image()
	if not texture_image:
		return
		
	var bitmap: BitMap = BitMap.new()
	bitmap.create_from_image_alpha(texture_image, 0.1)
	button.texture_click_mask = bitmap

func _update_end_turn_pivot() -> void:
	end_turn_button.pivot_offset = end_turn_button.size / 2.0

func _on_end_turn_button_mouse_entered() -> void:
	if _end_turn_tween and _end_turn_tween.is_valid():
		_end_turn_tween.kill()
		
	_end_turn_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_end_turn_tween.tween_property(end_turn_button, "rotation_degrees", end_turn_button.rotation_degrees - 45.0, 0.25)

func set_battle_hud_visible(is_visible: bool) -> void:
	if hand_container:
		hand_container.visible = is_visible
	if end_turn_button:
		end_turn_button.visible = is_visible
	if token_container:
		token_container.visible = is_visible
	if player_hp_bar:
		player_hp_bar.get_parent().visible = is_visible
	if player_shield_bar:
		player_shield_bar.visible = is_visible

func _on_end_turn_button_mouse_exited() -> void:
	if _end_turn_tween and _end_turn_tween.is_valid():
		_end_turn_tween.kill()
		
	_end_turn_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	_end_turn_tween.tween_property(end_turn_button, "rotation_degrees", 0.0, 0.4)
