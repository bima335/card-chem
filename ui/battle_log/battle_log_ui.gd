class_name BattleLogUI
extends NinePatchRect

@onready var log_label: RichTextLabel = $MarginContainer/ScrollContainer/LogLabel
@onready var scroll_container: ScrollContainer = $MarginContainer/ScrollContainer


func _ready() -> void:
	_connect_log_manager()


func _connect_log_manager() -> void:
	var log_manager = get_tree().get_first_node_in_group("log_manager")
	if log_manager and log_manager.has_signal("log_updated"):
		log_manager.log_updated.connect(_on_log_updated)
		log_manager.log_cleared.connect(_on_log_cleared)


func _on_log_updated(full_log_text: String) -> void:
	log_label.text = full_log_text
	_scroll_to_bottom()


func _on_log_cleared() -> void:
	log_label.clear()


func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)
