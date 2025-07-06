class_name Player
extends Object


var hand: Array[Card] = []

var chips: int = 0:
	set(c):
		
		chips=max(c, 0)

var id: int =-1:
	get:
		return PokerEngine.players.find_key(self)

var in_game: bool=true

var controller: PlayerController = PlayerController.new(self)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			controller.free()
			Logger.log_text("Player "+str(id)+": controller deleted.")
			hand.map(func (c: Card): c.free())
			Logger.log_text("Player "+str(id)+": cards in hand deleted.")


@warning_ignore("shadowed_variable")
func bet()-> void:
	if !in_game: pass
	controller.my_turn()
	

func fold()->void:
	in_game=false
	PokerEngine.player_out.emit(id)
