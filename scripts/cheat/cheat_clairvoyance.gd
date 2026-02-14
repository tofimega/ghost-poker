class_name Clairvoyance
extends Cheat


func name() -> Type: return Type.CLAIRVOYANCE

func _execute(target: int)->float:
	GlobalLogger.log_text("\tCLAIRVOYANCE")
	var p: Player = PokerEngine.get_player(player)
	if p.blinded: 
		GlobalLogger.log_text("\tPlayer using cheat is blinded")
		return 1
	GlobalLogger.log_text("\tPlayer "+str(player) +" checking Player "+str(target)+"'s hand...")
	return remap(PokerEngine.compare_hands(p.hand, PokerEngine.get_player(target).hand), -1, 1, 0.9, 1.2)
