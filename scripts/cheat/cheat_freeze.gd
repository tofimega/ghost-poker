class_name Freeze
extends Cheat


func _computer(target: int)->float:
	Logger.log_text("\tFREEZE")
	Logger.log_text("\tPLAYER "+str(target)+"'s bet won't increase highest")
	_user(target)
	return 1.06


func _user(target: int)->void:
	PokerEngine.freeze_highest_bet=target
