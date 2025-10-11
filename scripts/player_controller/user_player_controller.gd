class_name UserPlayerController
extends PlayerController

func _init(player: Player) -> void:
	super(player)
	FrontendManager.add_user_player_interface(player.id).user_bet.connect(_send_bet)
	FrontendManager.get_hud().pow.button.pressed.connect(_select_target_for_cheat)


func _select_target_for_cheat()->void:
	var selector: TargetSelector = FrontendManager.get_selector()
	selector._toggle_selection(true)
	await selector.target_selected
	var target: int = selector.current_target
	selector._toggle_selection(false)
	_use_cheat(target)

func _use_cheat(target: int)->void:
	player.cheat.user(target) 

func _send_bet(bet: Bet) -> Bet:
	FrontendManager.interfaces[player.id].enabled=false
	# send bet
	GlobalLogger.log_text("Player "+str(player.id)+" made bet: "+bet.Type.find_key(bet.type)+" "+str(bet.amount))
	PokerEngine.player_bet.emit(player.id, bet)
	return bet


func my_turn() -> void:
	GlobalLogger.log_text("Player "+str(player.id)+": waiting for user input...")
	FrontendManager.interfaces[player.id].enabled=true


func is_human()->bool:
	return true
