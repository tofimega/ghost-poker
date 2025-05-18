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
	assert(hand.size()>=5)
	var rankings: Array[Ranking] = []
	@warning_ignore_start("int_as_enum_without_cast")
	if hand.size()<5: return Ranking.new(0,[0,0,0,0,0])
	
	var suits=[]
	for s in Card.Suit:
		var suit_hand: Array[Card] = hand.filter(func (c: Card)-> bool: return c.suit==Card.Suit[s])
		suits.append(suit_hand)
	for suit in suits:
		if suit.size()<5: continue
		rankings.append(_rank_hand_with_flush(suit))
	
	
	var ranks: Array[int]
	ranks.resize(Card.Rank.size())
	
	for r in Card.Rank:
		var rank: int = hand.reduce(func (count,c: Card)-> int: return (count+1 if c.rank==Card.Rank[r] else count), 0)
		ranks[Card.Rank[r]]=rank
	ranks.reverse()
	
	
	var fkind_4: int=ranks.find(4)
	var fkind_1: int=ranks.find(1)
	if fkind_1>=0 and fkind_4>=0: 
		@warning_ignore_start("confusable_local_declaration")
		var card_ranks: Array[Card.Rank]
		card_ranks.resize(5)
		for i in 4: card_ranks[i]=(ranks.size()-fkind_4)+1
		card_ranks[4]=(ranks.size()-fkind_1)+1
		rankings.append(Ranking.new(Ranking.HandRank.FourKind, card_ranks))
	
	var fhouse_3: int=ranks.find(3)
	var fhouse_2: int=ranks.find(2)
	if fhouse_3>=0 and fhouse_2>=0: 
		var card_ranks: Array[Card.Rank]
		card_ranks.resize(5)
		for i in 3: card_ranks[i]=(ranks.size()-fhouse_3)+1
		for i in range(3,5): card_ranks[i]=(ranks.size()-fhouse_2)+1
		rankings.append(Ranking.new(Ranking.HandRank.FullHouse, card_ranks))
		
	for i in ranks.size()-4:
		if (ranks[i]>0 and
			ranks[i+1]>0 and
			ranks[i+2]>0 and
			ranks[i+3]>0 and
			ranks[i+4]>0):
			
			var card_ranks: Array[Card.Rank] = [(ranks.size()-i)+1,
												(ranks.size()-(i+1))+1,
												(ranks.size()-(i+2))+1,
												(ranks.size()-(i+3))+1,
												(ranks.size()-(i+4))+1]
			
			rankings.append(Ranking.new(Ranking.HandRank.Straight, card_ranks))
	
	var tkind_1=ranks.find(1, fkind_1+1)
	if tkind_1>=0 and fkind_1>=0 and fhouse_3>=0:
		var card_ranks: Array[Card.Rank]
		card_ranks.resize(5)
		for i in 3: card_ranks[i]=(ranks.size()-fhouse_3)+1
		for i in range(3,4): card_ranks[i]=(ranks.size()-fkind_1)+1
		card_ranks[4]=(ranks.size()-tkind_1)+1
		rankings.append(Ranking.new(Ranking.HandRank.ThreeKind, card_ranks))
		
	var tpair_2: int=ranks.find(2,fhouse_2+1)
	if tpair_2>=0 and fkind_1>=0 and fhouse_2>=0:
		var card_ranks: Array[Card.Rank]
		card_ranks.resize(5)
		for i in 2: card_ranks[i]=(ranks.size()-fhouse_2)+1
		for i in range(2,4): card_ranks[i]=(ranks.size()-tpair_2)+1
		card_ranks[4]=(ranks.size()-fkind_1)+1
		rankings.append(Ranking.new(Ranking.HandRank.TwoPair, card_ranks))
	
	var pair_1: int=ranks.find(1, tkind_1+1)
	if pair_1>=0 and fkind_1>=0 and tkind_1>=0 and fhouse_2>=0:
		var card_ranks: Array[Card.Rank]
		card_ranks.resize(5)
		for i in 2: card_ranks[i]=(ranks.size()-fhouse_2)+1
		card_ranks[2]=(ranks.size()-fkind_1)+1
		card_ranks[3]=(ranks.size()-tkind_1)+1
		card_ranks[4]=(ranks.size()-pair_1)+1
		rankings.append(Ranking.new(Ranking.HandRank.Pair, card_ranks))
	
	var card_ranks: Array[Card.Rank]
	for i in ranks.size():
		for j in ranks[i]:
			if card_ranks.size()>=5: break
			card_ranks.append((ranks.size()-i)+1)

	rankings.append(Ranking.new(Ranking.HandRank.HighCard, card_ranks))
	
	rankings.sort_custom(func (left: Ranking, right: Ranking): return left.hand_rank>right.hand_rank || (left.hand_rank==right.hand_rank && left.cards_rank>right.cards_rank))
	return rankings[0]


func _rank_hand_with_flush(hand: Array[Card]) -> Ranking:
	hand.sort_custom(func (left: Card, right: Card)->bool: return left.rank-right.rank>0)
	var card_rank: Array[Card.Rank] = hand.map(func (c: Card):  return c.rank)
	
	if card_rank.size()<5: return Ranking.new(Ranking.HandRank.HighCard,card_rank)
	
	for i in card_rank.size()-4 :
		if (card_rank[i+1]==card_rank[i]-1 and
			card_rank[i+2]==card_rank[i]-2 and
			card_rank[i+3]==card_rank[i]-3 and
			card_rank[i+4]==card_rank[i]-4):
				return Ranking.new(Ranking.HandRank.StraightFlush, [card_rank[i],
																	card_rank[i+1],
																	card_rank[i+2],
																	card_rank[i+3],
																	card_rank[i+4]])
	card_rank.duplicate().resize(5)
	return Ranking.new(Ranking.HandRank.Flush,card_rank)


func compare_hands(left: Array[Card], right: Array[Card]) -> int:
	var left_rank:  Ranking = rank_hand(left)
	var right_rank: Ranking = rank_hand(right)
	
	if left_rank.hand_rank>right_rank.hand_rank: return 1
	if right_rank.hand_rank>left_rank.hand_rank: return -1
	
	for i in 5:
		if left_rank.cards_rank>right_rank.cards_rank: return 1
		if right_rank.cards_rank>left_rank.cards_rank: return -1

	return 0
