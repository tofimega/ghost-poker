class_name Stink
extends Cheat

const length: int = 3


func name()->Type: return Type.STINK


func _execute(target: int)->float:
	GlobalLogger.log_text("\tSTINK")
	GlobalLogger.log_text("\tPLAYER "+str(target)+"can't see hands for"+str(length)+" turns")
	PokerEngine.get_player(target).blinded=length
	return 1.06
