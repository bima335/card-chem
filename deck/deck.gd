class_name Deck
extends Node

@export var  max_capacity: int = 30

var cards: Array[CardData] = []
var discard_pile: Array[CardData] = []

#Define signal
signal deck_updated(current_size: int, max_size:int)
signal discard_updated(current_size: int)
signal card_drawn(card:CardData)
signal deck_empty

#functoin

func add_card(new_card: CardData) -> bool:
	if cards.size() >= max_capacity:
		push_warning("Deck penuh!")
		return false
	
	cards.append(new_card)
	deck_updated.emit(cards.size(), max_capacity)
	return true

func shuffle_deck():
	cards.shuffle()

func draw_card() -> CardData:
	if cards.is_empty():
		# Pengecekan Discard Pile harus dilakukan DI SINI, sebelum melakukan return null!
		if discard_pile.is_empty():
			deck_empty.emit()
			return null
		else:
			_reshuffle_discard_into_deck()
	
	var drawn_card: CardData = cards.pop_back()
	deck_updated.emit(cards.size(), max_capacity)
	card_drawn.emit(drawn_card)
	return drawn_card

func set_maz_capacity(new_capacity: int):
	max_capacity = new_capacity
	deck_updated.emit(cards.size(), max_capacity)
	
func add_to_discard(card: CardData) -> void:
	discard_pile.append(card)
	discard_updated.emit(discard_pile.size())

func _reshuffle_discard_into_deck() -> void:
	print("Deck habis! Mengocok ulang Discard Pile menjadi Deck baru...")
	# 1. Pindahkan semua kartu buangan kembali ke deck
	cards.append_array(discard_pile)
	
	# 2. Kosongkan tumpukan buangan
	discard_pile.clear()
	
	# 3. Kocok!
	shuffle_deck()
	
	# 4. Beritahu UI
	discard_updated.emit(0)
	deck_updated.emit(cards.size(), max_capacity)
