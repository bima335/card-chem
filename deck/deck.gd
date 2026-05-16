class_name Deck
extends Node

@export var  max_capacity: int = 30

var cards: Array[CardData] = []

#Define signal
signal deck_updated(current_size: int, max_size:int)
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
		deck_empty.emit()
		return null
	
	var drawn_card: CardData = cards.pop_back()
	deck_updated.emit(cards.size(), max_capacity)
	card_drawn.emit(drawn_card)
	return drawn_card

func set_maz_capacity(new_capacity: int):
	max_capacity = new_capacity
	deck_updated.emit(cards.size(), max_capacity)
