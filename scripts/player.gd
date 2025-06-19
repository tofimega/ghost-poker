class_name Player
extends Object


var hand: Array[Card] = []

var chips: int = 0

var id: int =-1:
	get:
		return PokerEngine.players.find_key(self)

var in_game: bool=true

var controller: PlayerController = PlayerController.new(self)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			controller.free()
			hand.map(func (c: Card): c.free())


@warning_ignore("shadowed_variable")
func bet(bet: int)-> int:
	bet=min(bet, chips)
	chips-=bet
	PokerEngine.pool+=bet
	return bet

func fold()-> void:
	in_game=false
	PokerEngine.player_out.emit(self)
	
