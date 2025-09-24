class_name Cheat
extends Object


var charge: float = 1.1 #TODO: reset to 0
var player: int = -1

func _init(p: int) -> void:
	player=p #TODO: increase charge on bets, etc. 


func computer(target: int)->float:
	if charge <1 : return 1
	Logger.log_text("\tSufficient charge")
	#charge=0
	return _computer(target)


func user(target: int)->void:
	if charge <1: return
	Logger.log_text("\tSufficient charge")
	#charge=0
	_user(target)


func _computer(target: int)-> float:
	Logger.log_text("\tCheat not implemented, default: 1")
	return 1


func _user(target: int) -> void:
	Logger.log_text("\tCheat not implemented")
	pass
