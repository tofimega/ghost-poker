class_name Clairvoyance
extends Cheat


func _init()->void:
	_name= "Clairvoyance"

func _computer(target: int)->float:
	GlobalLogger.log_text("\tCLAIRVOYANCE")
	var p: Player = PokerEngine.get_player(player)
	if p.blinded: 
		GlobalLogger.log_text("\tPlayer using cheat is blinded")
		return 1
	GlobalLogger.log_text("\tPlayer "+str(player) +" checking Player "+str(target)+"'s hand...")
	return remap(PokerEngine.compare_hands(p.hand, PokerEngine.get_player(target).hand), -1, 1, 0.9, 1.2)


func _user(target: int)->void:
	FrontendManager.get_hud().show_other_hand(target)
