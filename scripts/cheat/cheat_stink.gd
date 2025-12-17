class_name Stink
extends Cheat

const length: int = 3


func _init()->void:
	_name= "Stink"


func _computer(target: int)->float:
	GlobalLogger.log_text("\tSTINK")
	GlobalLogger.log_text("\tPLAYER "+str(target)+"can't see hands for"+str(length)+" turns")
	_user(target)
	return 1.06


func _user(target: int)->void:
	PokerEngine.get_player(target).blinded=length
