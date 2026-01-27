class_name UserPlayerController
extends PlayerController

func _init(player: Player) -> void:
	super(player)
	FrontendManager.add_user_player_interface(player.id).user_bet.connect(_send_bet)
	FrontendManager.get_hud().pow.button.pressed.connect(_select_target_for_cheat)


func use_early_cheat()->void:
	return # User can't do this


func _select_target_for_cheat()->void:
	if player.cheat.charge<1: return
	var target: int = -1
	if player.cheat.offense:
		var selector: TargetSelector = FrontendManager.get_selector()
		selector._toggle_selection(true)
		await selector.target_selected
		target = selector.current_target
		selector._toggle_selection(false)

	_use_cheat(target)
	PokerEngine.start_flinch.emit(target)
	FrontendManager.get_hud().update()
	

func _use_cheat(target: int)->void:
	await player.cheat.user(target) 
	

func _send_bet(bet: Bet) -> Bet:
	FrontendManager.get_hud().toggle_hud(false)
	# send bet
	GlobalLogger.log_text("Player "+str(player.id)+" made bet: "+bet.Type.find_key(bet.type)+" "+str(bet.amount))
	PokerEngine.player_bet.emit(player.id, bet)
	FrontendManager.get_hud().update()
	return bet


func my_turn() -> void:
	GlobalLogger.log_text("Player "+str(player.id)+": waiting for user input...")
	FrontendManager.get_hud().toggle_hud(true)


func is_human()->bool:
	return true
