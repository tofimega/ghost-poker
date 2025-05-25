class_name Player
extends RefCounted


var hand: Array[Card] = []

var chips: int = 0

var id: int =-1

@warning_ignore("shadowed_variable")
func bet(bet: int)-> int:
	bet=min(bet, chips)
	chips-=bet
	PokerEngine.pool+=bet
	return bet
