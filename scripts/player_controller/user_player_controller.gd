class_name UserPlayerController
extends PlayerController


func _init(player: Player) -> void:
	super(player)
	#FrontendManager.add_user_player_interface(player.id).user_bet.connect(_send_bet)
	#FrontendManager.get_hud().pow.button.pressed.connect(_select_target_for_cheat)


func use_early_cheat()->bool:
	return false # User can't do this


func bet() -> Bet:
	return player.last_bet

func is_human()->bool:
	return true
