class_name BattleUIManager
extends Node

@export var card_ui_scene: PackedScene

# --- REFERENSI UI ---
@export_group("UI Elements")
@export var hand_container: HBoxContainer
@export var end_turn_button: Button
@export var deck_visual: TextureButton
@export var discard_visual: TextureButton
@export var close_deck_button: Button
@export var blessing_container: VBoxContainer
@export var blessing_item_scene: PackedScene

# --- REFERENSI AURA NEW ---
@export_group("Aura UI")
@export var aura_container: Control
@export var aura_ui_scene: PackedScene

@export_group("Player HUD")
@export var player_hp_bar: ProgressBar
@export var player_hp_label: Label
@export var player_shield_bar: ProgressBar
@export var player_shield_label: Label
@export var token_container: Control
@export var c_label: Label
@export var h_label: Label
@export var o_label: Label
@export var n_label: Label

@export_group("Deck Viewer Panel")
@export var deck_backdrop: ColorRect
@export var deck_view_panel: PanelContainer
@export var panel_title_label: Label
@export var card_grid: GridContainer

signal card_clicked_in_viewer(card_data: CardData)


func _ready() -> void:
	close_deck_button.pressed.connect(hide_deck_viewer)
	
	if EventBus.has_signal("blessing_list_changed"):
		EventBus.blessing_list_changed.connect(update_blessings_display)
		
	_connect_aura_signals()
	update_blessings_display()
	update_aura_display(AuraManager.active_aura)


func _connect_aura_signals() -> void:
	if AuraManager.has_signal("aura_equipped"):
		AuraManager.aura_equipped.connect(_on_aura_changed)
	if AuraManager.has_signal("aura_unequipped"):
		AuraManager.aura_unequipped.connect(func(): _on_aura_changed(null))


func _on_aura_changed(aura_data: AuraCardData) -> void:
	update_aura_display(aura_data)


func update_aura_display(aura_data: AuraCardData) -> void:
	if not aura_container:
		return

	for child in aura_container.get_children():
		child.queue_free()

	if aura_data != null and aura_ui_scene != null:
		var aura_ui = aura_ui_scene.instantiate() as AuraCardUI
		aura_container.add_child(aura_ui)
		aura_ui.setup(aura_data)
		aura_ui.custom_minimum_size = Vector2(136, 200)
	else:
		_show_aura_placeholder()


func _show_aura_placeholder() -> void:
	var placeholder_label = Label.new()
	placeholder_label.text = "EMPTY AURA"
	placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	placeholder_label.modulate = Color(1, 1, 1, 0.4)
	aura_container.add_child(placeholder_label)


func update_tokens(o: int, h: int, c: int, n: int) -> void:
	c_label.text = "Carbon: " + str(c)
	h_label.text = "Hydrogen: " + str(h)
	o_label.text = "Oxygen: " + str(o)
	n_label.text = "Nitrogen: " + str(n)
	
	var tween = create_tween()
	tween.tween_property(token_container, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(token_container, "scale", Vector2.ONE, 0.1)


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


func animate_draw_card(new_card_data: CardData, on_land_callback: Callable) -> void:
	var real_card: CardUI = card_ui_scene.instantiate() as CardUI
	hand_container.add_child(real_card)
	real_card.setup(new_card_data)
	real_card.modulate = Color(1, 1, 1, 0)
	
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

	for child in blessing_container.get_children():
		child.queue_free()

	var active_blessings = BlessingManager.active_blessings
	var count = mini(active_blessings.size(), BlessingManager.MAX_SLOTS)

	for i in range(count):
		var blessing_data = active_blessings[i]
		var blessing_ui = blessing_item_scene.instantiate() as BlessingUIItem
		blessing_container.add_child(blessing_ui)
		blessing_ui.setup(blessing_data)
