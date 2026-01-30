class_name WildCard
extends Cheat



func name()->String: return "WildCard"
func offense()->bool: return false


func _execute(target: int)->float:
	GlobalLogger.log_text("\tWILDCARD")
	var p: Player = PokerEngine.get_player(player)
	p.hand.append(Card.new(randi()%Card.Suit.size(), randi()%Card.Rank.size()))
	return remap(PokerEngine.compare_hands(p.hand, PokerEngine.get_player(target).hand), -1, 1, 0.9, 1.2)
