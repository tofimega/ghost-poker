class_name Player
extends RefCounted


var hand: Array[Card] = []

var chips: int = 0

var id: int =-1:
	get:
		return PokerEngine.players.find_key(self)

var in_game: bool=true

var controller: PlayerController = PlayerController.new(self)

@warning_ignore("shadowed_variable")
func bet(bet: int)-> int:
	bet=min(bet, chips)
	chips-=bet
	PokerEngine.pool+=bet
	return bet

func fold()-> void:
	controller.player=null
	controller=null
	in_game=false
	PokerEngine.player_out.emit(self)
	
