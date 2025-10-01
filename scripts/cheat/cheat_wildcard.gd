class_name WildCard
extends Cheat


func _computer(target: int)->float:
	Logger.log_text("\tWILDCARD")
	var p: Player = PokerEngine.get_player(player)
	p.hand.append(Card.new(randi()%Card.Suit.size(), randi()%Card.Rank.size()))
	return remap(PokerEngine.compare_hands(p.hand, PokerEngine.get_player(target).hand), -1, 1, 0.9, 1.2)


func _user(target: int)->void:
	PokerEngine.get_player(player).hand.append(Card.new(randi()%Card.Suit.size(), randi()%Card.Rank.size()))
