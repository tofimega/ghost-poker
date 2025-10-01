class_name Player
extends Object



var blinded: bool = true

var hand: Array[Card] = []


var cheat: Cheat

var chips: int = 0:
	set(c):
		chips=max(c, 0)

var id: int =-1:
	get:
		return PokerEngine.players.find_key(self)

var in_game: bool=true
var all_in: bool=false
var controller: PlayerController = null

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			controller.free()
			Logger.log_text("Player "+str(id)+": controller deleted.")
			hand.map(func (c: Card): c.free())
			Logger.log_text("Player "+str(id)+": cards in hand deleted.")
			cheat.free()


@warning_ignore("shadowed_variable")
func bet()-> void:
	if !in_game: return
	controller.my_turn()


func fold()->void:
	in_game=false
	PokerEngine.player_out.emit(id)
