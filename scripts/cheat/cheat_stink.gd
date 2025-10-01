class_name Stink
extends Cheat

const length: int = 3

func _computer(target: int)->float:
	Logger.log_text("\tSTINK")
	Logger.log_text("\tPLAYER "+str(target)+"can't see hands for"+str(length)+" turns")
	_user(target)
	return 1.06


func _user(target: int)->void:
	PokerEngine.get_player(target).blinded=length
