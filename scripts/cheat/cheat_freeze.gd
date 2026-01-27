class_name Freeze
extends Cheat



func _init()->void:
	_name= "Freeze"


func _computer(target: int)->float:
	GlobalLogger.log_text("\tFREEZE")
	GlobalLogger.log_text("\tPLAYER "+str(target)+"'s bet won't increase highest")
	_user(target)
	return 1.06


func _user(target: int)->void:
	PokerEngine.players[target].frozen=true
