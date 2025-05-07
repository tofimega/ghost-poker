extends Node



const PLAYER_COUNT: int = 4
const STARING_HAND_SIZE: int = 5
const STARING_CHIP_COUNT: int = 100

var players: Array[Player] = []

var deck: Array[Card] = []


func _ready(): _init_game_state()


func deal_cards(player: Player, count: int):
	for i in count:
		if deck.is_empty(): return # TODO: signal empty deck
		player.hand.append(deck.pop_back())


func _clear_game_state():
	players.clear()
	deck.clear()


func _init_game_state():
	for i in Card.Suit.size(): 
		for j in Card.Rank.size():
			deck.append(Card.new(i,j))

	deck.shuffle()
	for i in PLAYER_COUNT: players.append(Player.new())
	for p in players:
		deal_cards(p, STARING_HAND_SIZE)
		p.chips=STARING_CHIP_COUNT


func new_game():
	_clear_game_state()
	_init_game_state()


func rank_hand(hand: Array[Card]) -> Ranking:
	var suit_hands=[]
	for s in Card.Suit:
		var suit_hand: Array[Card] = hand.filter(func (c: Card)-> bool: return c.suit==Card.Suit[s])
		if suit_hand.size()>=5:
			suit_hands.append(suit_hand)
	if !suit_hands.is_empty():
		suit_hands.sort_custom(func (left: Array[Card], right: Array[Card]): return left.reduce(func (acc: int,c: Card): return c.rank+acc, 0)>right.reduce(func (acc: int,c: Card): return c.rank+acc, 0))
		return _rank_hand_with_flush(suit_hands[0])
	
	var trunc_hand: Array[Card] = hand.duplicate()
	trunc_hand.sort_custom( func (left: Card, right: Card)->bool: return left.rank-right.rank>0 )
	trunc_hand.resize(5)
	@warning_ignore("int_as_enum_without_cast")
	if trunc_hand.filter(func (c): return c != null).size()<5: return Ranking.new(Ranking.HandRank.HighCard, [0,0,0,0,0])
	var card_rank: Array[Card.Rank] = trunc_hand.map(func (c: Card):  return c.rank)
	
	
	if (card_rank[0]==card_rank[1] and 
		card_rank[0]==card_rank[2] and 
		card_rank[0]==card_rank[3]):
		return Ranking.new(Ranking.HandRank.FourKind, card_rank)
	
	if (card_rank[0]==card_rank[1] and 
		card_rank[0]==card_rank[2]):
		if card_rank[3]==card_rank[4]: return Ranking.new(Ranking.HandRank.FullHouse,card_rank)
		return Ranking.new(Ranking.HandRank.ThreeKind, card_rank)
		
	var straight_flag: bool=true
	for i in range(1,5):
		if abs(card_rank[i-1]-card_rank[i])!=1: 
			straight_flag=false
			break
	if straight_flag:  Ranking.new(Ranking.HandRank.Straight,card_rank)
	
	if (card_rank[0]==card_rank[1] and 
		card_rank[2]==card_rank[3]):
		return Ranking.new(Ranking.HandRank.TwoPair, card_rank)
	if (card_rank[0]==card_rank[1]): return Ranking.new(Ranking.HandRank.Pair, card_rank)
	
	return Ranking.new(Ranking.HandRank.HighCard,card_rank)


func _rank_hand_with_flush(hand: Array[Card]) -> Ranking:
	var trunc_hand: Array[Card]=hand.duplicate() 
	trunc_hand.sort_custom(func (left: Card, right: Card)->bool: return left.rank-right.rank>0)
	trunc_hand.resize(5)
	var card_rank: Array[Card.Rank] = trunc_hand.map(func (c: Card):  return c.rank)
	for i in range(1,5):
		if abs(card_rank[i-1]-card_rank[i])!=1: return Ranking.new(Ranking.HandRank.Flush,card_rank)
	return Ranking.new(Ranking.HandRank.StraightFlush,card_rank)


func compare_hands(left: Array[Card], right: Array[Card]) -> int:
	var left_rank:  Ranking = rank_hand(left)
	var right_rank: Ranking = rank_hand(right)
	
	if left_rank.hand_rank>right_rank.hand_rank: return 1
	if right_rank.hand_rank>left_rank.hand_rank: return -1
	
	for i in 5:
		if left_rank.cards_rank>right_rank.cards_rank: return 1
		if right_rank.cards_rank>left_rank.cards_rank: return -1

	return 0
