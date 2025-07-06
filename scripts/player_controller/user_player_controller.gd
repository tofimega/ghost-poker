class_name UserPlayerController
extends PlayerController



func _init(player: Player) -> void:
	super(player)
	FrontendManager.add_user_player_interface(player.id).user_bet.connect(_send_bet)
	
	
	
func _send_bet(bet: PlayerController.Bet) -> PlayerController.Bet:
	
	FrontendManager.interfaces[player.id].enabled=false
	# send bet
	PokerEngine.player_bet.emit(player.id, bet)
	return bet
	
func my_turn() -> void:
	FrontendManager.interfaces[player.id].enabled=true
