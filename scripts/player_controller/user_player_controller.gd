class_name UserPlayerController
extends PlayerController

func _init(player: Player) -> void:
	super(player)
	FrontendManager.add_user_player_interface(player.id).user_bet.connect(_send_bet)


func _send_bet(bet: Bet) -> Bet:
	FrontendManager.interfaces[player.id].enabled=false
	# send bet
	Logger.log_text("Player "+str(player.id)+" made bet: "+bet.Type.find_key(bet.type)+" "+str(bet.amount))
	PokerEngine.player_bet.emit(player.id, bet)
	return bet


func my_turn() -> void:
	Logger.log_text("Player "+str(player.id)+": waiting for user input...")
	FrontendManager.interfaces[player.id].enabled=true


func is_human()->bool:
	return true
