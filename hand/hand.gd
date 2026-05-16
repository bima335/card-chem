class_name Hand
extends Node

@export var max_hand_size: int = 5
var cards_in_hand: Array[CardData] = []

#Define signal
signal hand_updated(current_size: int, max_size: int)
signal card_added_to_hand(card: CardData)
signal card_removed_from_hand(card: CardData)
signal hand_full_warning

func add_card(new_card: CardData) -> bool:
	if cards_in_hand.size() >= max_hand_size:
		hand_full_warning.emit()
		return false
	
	cards_in_hand.append(new_card)
	card_added_to_hand.emit(new_card)
	hand_updated.emit(cards_in_hand.size(), max_hand_size)
	return true

func remove_card(card_to_remove: CardData):
	if card_to_remove in cards_in_hand:
		cards_in_hand.erase((card_to_remove))
		card_removed_from_hand.emit(card_to_remove)
		hand_updated.emit(cards_in_hand.size(), max_hand_size)

func set_max_hand_size(new_size:int):
	max_hand_size = new_size
	hand_updated.emit(cards_in_hand.size(), max_hand_size)
