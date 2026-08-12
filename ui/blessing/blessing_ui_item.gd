class_name BlessingUIItem
extends TextureRect

func setup(blessing_data: BlessingData) -> void:
	texture = blessing_data.icon
	tooltip_text = blessing_data.name + "\n" + blessing_data.description
