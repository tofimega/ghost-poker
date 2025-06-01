class_name PlayerController
extends RefCounted

var player: Player



@warning_ignore("shadowed_variable")
func _init(player: Player)->void:
	self.player=player

func find_odds()->float:
	var hand_size: int = player.hand.size()
	var hand_rank: Ranking = PokerEngine.rank_hand(player.hand)
	
	var rt: float=1
	
	# lower ranking -> smaller num
	rt+=float(hand_rank.hand_rank)/(hand_rank.HandRank.size()-1)*5
	rt+=float(hand_rank.cards_rank[0])/Card.Rank.size()-1
	rt=ease(rt/6,-2)
	
	# smaller hand  -> bigger num
	rt*=1/float(hand_size)*PokerEngine.STARING_HAND_SIZE+0.2

	# more players  -> smaller num
	rt*=float(PokerEngine.players.values().reduce(func(acc: int,p: Player):
		if p.in_game: acc+=1
		return acc , 0))/(float(PokerEngine.PLAYER_COUNT)*0.8)
	
	# some randomness
	#rt*=randf_range(0.9, 1.1)

	return rt

func my_turn() -> void:
	print(player.id, ":",find_odds())
