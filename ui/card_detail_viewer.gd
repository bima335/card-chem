extends Control

@export var title_label: Label
@export var subtitle_label: Label
@export var cost_label: Label
@export var description_label: Label
@export var extra_info_label: Label
@export var card_texture: TextureRect
@export var close_button: TextureButton

func _ready() -> void:
	close_button.pressed.connect(_close_viewer)
	
	# Klik di area kosong (background) juga bisa menutup viewer
	gui_input.connect(_on_background_click)

func setup(data: Resource) -> void:
	# Reset tampilan
	title_label.text = ""
	subtitle_label.text = ""
	cost_label.text = ""
	description_label.text = ""
	extra_info_label.text = ""
	card_texture.texture = null
	
	if data is CardData:
		_setup_from_card(data)
	elif data is AuraCardData:
		_setup_from_aura(data)
	elif data is BlessingData:
		_setup_from_blessing(data)
	elif data is CoatData:
		_setup_from_coat(data)

func _setup_from_card(card_data: CardData) -> void:
	title_label.text = card_data.card_name
	subtitle_label.text = "Kartu " + CardData.CardType.keys()[card_data.card_type]
	description_label.text = card_data.description
	
	# Tampilkan biaya token
	var cost_str = ""
	if card_data.cost_carbon > 0: cost_str += "C:%d " % card_data.cost_carbon
	if card_data.cost_hydrogen > 0: cost_str += "H:%d " % card_data.cost_hydrogen
	if card_data.cost_oxygen > 0: cost_str += "O:%d " % card_data.cost_oxygen
	if card_data.cost_nitrogen > 0: cost_str += "N:%d " % card_data.cost_nitrogen
	if cost_str.is_empty(): cost_str = "Gratis"
	cost_label.text = "Biaya: " + cost_str

	# Texture
	if card_data.card_texture:
		card_texture.texture = card_data.card_texture
	
	# Jika ada Coat, tambahkan info tambahan
	if card_data.coat_data:
		extra_info_label.text = "⭐ COAT: %s\n%s" % [card_data.coat_data.coat_name, card_data.coat_data.description]

func _setup_from_aura(aura_data: AuraCardData) -> void:
	title_label.text = aura_data.name
	subtitle_label.text = "Aura Card"
	description_label.text = aura_data.description
	if aura_data.icon: card_texture.texture = aura_data.icon

func _setup_from_blessing(blessing_data: BlessingData) -> void:
	title_label.text = blessing_data.name
	subtitle_label.text = "Blessing (" + BlessingData.Rarity.keys()[blessing_data.rarity] + ")"
	description_label.text = blessing_data.description
	if blessing_data.icon: card_texture.texture = blessing_data.icon

func _setup_from_coat(coat_data: CoatData) -> void:
	title_label.text = coat_data.coat_name
	subtitle_label.text = "Efek Coat (" + CoatData.Rarity.keys()[coat_data.rarity] + ")"
	description_label.text = coat_data.description
	if coat_data.icon: card_texture.texture = coat_data.icon

func _on_background_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_close_viewer()

func _close_viewer() -> void:
	SoundManager.play_sfx("ui_click") # Opsional
	queue_free()
