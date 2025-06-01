extends Node

enum GameState{
	CLOSED,
	RUNNING,
	TIE,
	CONCLUSIVE

}

signal hand_dealt(player: Player)
signal game_start
signal next_round
signal deck_empty
@warning_ignore("unused_signal")
signal player_out(p: Player)
signal game_over(result: GameState, winner)

const PLAYER_COUNT: int = 4
const STARING_HAND_SIZE: int = 5
const CARDS_PER_ROUND: int = 2
const STARING_CHIP_COUNT: int = 100
const STARTING_ANTE: int = 40

var players: Dictionary[int, Player] = {}

var deck: Array[Card] = []

var pool: int=0

var game_state: GameState=GameState.CLOSED
var current_turn: int=-1

func _ready()->void: 
	_init_game_state()
	deck_empty.connect(showdown)
	


func get_player(id: int)->Player:
	return players[id]

@warning_ignore_start("int_as_enum_without_cast")
func showdown()->void:
	print("Showdown!")
	var winning_hand: Ranking = players.values().reduce(func(acc: Ranking, player: Player):
		var rank: Ranking=rank_hand(player.hand)
		
		if rank.hand_rank>acc.hand_rank || (rank.hand_rank==acc.hand_rank && rank.cards_rank>acc.cards_rank):
			return rank
		return acc
		
		, Ranking.new(Ranking.HandRank.HighCard, [0,0,0,0,0]))
	
	var winners: Array[Player]
	
	for p in players.values():
		var ranking: Ranking=rank_hand(p.hand)
		if ranking.hand_rank==winning_hand.hand_rank && ranking.cards_rank==winning_hand.cards_rank:
			winners.append(p)
			
	if winners.size()==1:
		game_state=GameState.CONCLUSIVE
		game_over.emit(GameState.CONCLUSIVE, winners[0])
		print("WINNER: "+str(winners[0].id))
	else:
		game_state=GameState.TIE
		game_over.emit(GameState.TIE, winners)
		print("TIE! "+str(winners.map(func(p: Player): return p.id)))

func deal_cards(player: Player, count: int)->void:
	for i in count:
		if deck.is_empty(): 
			deck_empty.emit()
			return
		player.hand.append(deck.pop_back())
	hand_dealt.emit(player)
	if deck.is_empty(): 
			deck_empty.emit()


func start_next_round()->void:
	for p in players.values():
		if deck.size()==0: break
		deal_cards(p, CARDS_PER_ROUND)
	current_turn+=1
	next_round.emit()


func _clear_game_state()->void:
	players.clear()
	deck.clear()
	pool=0
	current_turn=-1
	game_state=GameState.CLOSED


func _init_game_state()->void:
	current_turn=0
	for i in Card.Suit.size(): 
		for j in Card.Rank.size():
			deck.append(Card.new(i,j))

	deck.shuffle()
	for i in PLAYER_COUNT: 
		players[i]=Player.new()
		
	for p in players.values():
		deal_cards(p, STARING_HAND_SIZE)
		p.chips=STARING_CHIP_COUNT
		p.bet(STARTING_ANTE)
	game_state=GameState.RUNNING


#TODO: is only for debug
#CRITICAL: DON'T FORGET TO RESTORE PHYSICS TICK RATE WHEN REMOVING THIS
func _physics_process(delta: float) -> void:
	for p: Player in players.values():
		p.controller.my_turn()
	print()

func new_game()->void:
	_clear_game_state()
	_init_game_state()
	game_start.emit()


func rank_hand(hand: Array[Card]) -> Ranking:
	assert(hand.size()>=5)
	var rankings: Array[Ranking] = []
	
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
			
			var card_ranks: Array[Card.Rank] = [(ranks.size()-i)-1,
												(ranks.size()-(i+1))-1,
												(ranks.size()-(i+2))-1,
												(ranks.size()-(i+3))-1,
												(ranks.size()-(i+4))-1]
			
			rankings.append(Ranking.new(Ranking.HandRank.Straight, card_ranks))
	
	var tkind_1=ranks.find(1, fkind_1+1)
	if tkind_1>=0 and fkind_1>=0 and fhouse_3>=0:
		var card_ranks: Array[Card.Rank]
		card_ranks.resize(5)
		for i in 3: card_ranks[i]=(ranks.size()-fhouse_3)-1
		for i in range(3,4): card_ranks[i]=(ranks.size()-fkind_1)-1
		card_ranks[4]=(ranks.size()-tkind_1)-1
		rankings.append(Ranking.new(Ranking.HandRank.ThreeKind, card_ranks))
		
	var tpair_2: int=ranks.find(2,fhouse_2+1)
	if tpair_2>=0 and fkind_1>=0 and fhouse_2>=0:
		var card_ranks: Array[Card.Rank]
		card_ranks.resize(5)
		for i in 2: card_ranks[i]=(ranks.size()-fhouse_2)-1
		for i in range(2,4): card_ranks[i]=(ranks.size()-tpair_2)-1
		card_ranks[4]=(ranks.size()-fkind_1)-1
		rankings.append(Ranking.new(Ranking.HandRank.TwoPair, card_ranks))
	
	var pair_1: int=ranks.find(1, tkind_1+1)
	if pair_1>=0 and fkind_1>=0 and tkind_1>=0 and fhouse_2>=0:
		var card_ranks: Array[Card.Rank]
		card_ranks.resize(5)
		for i in 2: card_ranks[i]=(ranks.size()-fhouse_2)-1
		card_ranks[2]=(ranks.size()-fkind_1)-1
		card_ranks[3]=(ranks.size()-tkind_1)-1
		card_ranks[4]=(ranks.size()-pair_1)-1
		rankings.append(Ranking.new(Ranking.HandRank.Pair, card_ranks))
	
	var card_ranks: Array[Card.Rank]
	for i in ranks.size():
		for j in ranks[i]:
			if card_ranks.size()>=5: break
			card_ranks.append((ranks.size()-i)-1)

	rankings.append(Ranking.new(Ranking.HandRank.HighCard, card_ranks))
	
	rankings.sort_custom(func (left: Ranking, right: Ranking): return left.hand_rank>right.hand_rank || (left.hand_rank==right.hand_rank && left.cards_rank>right.cards_rank))
	return rankings[0]


func _rank_hand_with_flush(hand: Array[Card]) -> Ranking:
	hand.sort_custom(func (left: Card, right: Card)->bool: return left.rank-right.rank>0)
	var card_rank: Array[Card.Rank]
	card_rank.resize(hand.size())
	for h in hand.size():
		card_rank[h]=hand[h].rank
	
	if card_rank.size()<5: return Ranking.new(Ranking.HandRank.HighCard,[0,0,0,0,0])
	
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
	var a=card_rank.duplicate()
	a.resize(5)
	return Ranking.new(Ranking.HandRank.Flush,a)


func compare_hands(left: Array[Card], right: Array[Card]) -> int:
	var left_rank:  Ranking = rank_hand(left)
	var right_rank: Ranking = rank_hand(right)
	
	if left_rank.hand_rank>right_rank.hand_rank: return 1
	if right_rank.hand_rank>left_rank.hand_rank: return -1
	
	for i in 5:
		if left_rank.cards_rank>right_rank.cards_rank: return 1
		if right_rank.cards_rank>left_rank.cards_rank: return -1

	return 0
