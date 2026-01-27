class_name Player
extends Object



var blinded: int = 0:
	set(b):
		if blinded!=0 and b>blinded: return
		blinded=clamp(b,0,Stink.length)

var hand: Array[Card] = []

var frozen: bool = false

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
			GlobalLogger.log_text("Player "+str(id)+": controller deleted.")
			hand.map(func (c: Card): c.free())
			GlobalLogger.log_text("Player "+str(id)+": cards in hand deleted.")
			cheat.free()
			GlobalLogger.log_text("Player "+str(id)+": cheat deleted.")


@warning_ignore("shadowed_variable")
func bet()-> void:
	if !in_game: return
	blinded-=1
	controller.my_turn()


func fold()->void:
	in_game=false
	PokerEngine.player_out.emit(id)
