class_name Freeze
extends Cheat




func name()->Type: return Type.FREEZE


func _execute(target: int)->float:
	GlobalLogger.log_text("\tFREEZE")
	GlobalLogger.log_text("\tPLAYER "+str(target)+"'s bet won't increase highest")
	PokerEngine.players[target].frozen=true
	return 1.06
