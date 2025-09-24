class_name Clairvoyance
extends Cheat



func _computer(target: int)->float:
	Logger.log_text("\tCLAIRVOYANCE")
	var p: Player = PokerEngine.get_player(player)
	if p.blinded: 
		Logger.log_text("\tPlayer using cheat is blinded")
		return 1
	Logger.log_text("\tPlayer "+str(player) +" checking Player "+str(target)+"'s hand...")
	return remap(PokerEngine.compare_hands(p.hand, PokerEngine.get_player(target).hand), -1, 1, 0.9, 1.2)
