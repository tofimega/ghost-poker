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
signal round_over
signal deck_empty
signal s_showdown(F_no_p_T_mt_d: bool)
signal no_player_found
@warning_ignore("unused_signal")
signal player_out(p: int)
signal game_over(result: GameState, winner)

signal player_bet(p: int, bet: Bet)
signal next_player(p: int)

const PLAYER_COUNT: int = 4
const CARDS_PER_ROUND: int = 2
const STARING_HAND_SIZE: int = clamp(5-CARDS_PER_ROUND, 0, 5)
const STARING_CHIP_COUNT: int = 100
const STARTING_ANTE: int = 40
const MINIMUM_BET: int = 3


var players: Dictionary[int, Player] = {}

var deck: Array[Card] = []

var pool: int=0

var game_state: GameState=GameState.CLOSED
var current_turn: int=-1

var current_player: int = -1
var empty_deck_flag: bool=false

var player_bets: Dictionary[int, Bet]
var player_bets_noclear: Dictionary[int, Bet]
var highest_bet: int = 0
var freeze_highest_bet: int = -1


var cheats: Array[Cheat] = []

func _ready()->void:
	deck_empty.connect(func(): empty_deck_flag=true)
	player_bet.connect(_incoming_bet,CONNECT_DEFERRED) # defer to prevent stack overflow, just in case)
	round_over.connect(start_next_round)


func _incoming_bet(p: int, bet: Bet):
	if p == current_player and players[p].in_game: _handle_player_bet(p, bet)
	await get_tree().create_timer(1).timeout #TODO: await animation end instead
	_next_step()


func _next_step()->void:
	if empty_deck_flag:
		s_showdown.emit(true)
		showdown()
		return

	var players_available: bool = _find_next_player()
	
	if current_player_count() <= 1:
		game_state=GameState.CONCLUSIVE
		var winning_player: Player = players[current_player]
		Logger.log_text("GAME OVER!")
		Logger.log_text("WINNER: "+str(winning_player.id))
		Logger.log_text("CARDS IN DECK: "+ str(deck.size()))
		Logger.log_text("CHIPS IN POOL: "+ str(pool))
		game_over.emit(GameState.CONCLUSIVE, winning_player)
		return
	
	if !players_available:
			Logger.log_text("No player worth asking found...")
			Logger.log_text("Dealing remaining cards...")
			
			var ps: Array[Player] = players.values()
			var p: int=0
			while !deck.is_empty():
				deal_cards(ps[p%ps.size()], 1)
				p+=1

			for pr in ps: 
				hand_dealt.emit(pr)

			s_showdown.emit(false)
			showdown() 
			return

	if !player_bets.values().all(func(b: Bet): return b.type==Bet.Type.FOLD or b.amount==highest_bet): _ask_next_player()
	else: _final_bet()

func _can_player_move(id: int)->bool:
	return players[id].in_game or players[id].all_in or players[id].chips==0


func _find_next_player() ->bool:
	var id: int = current_player+1
	id%=players.size()
	var counter: int = 0
	while (!_can_player_move(id) or player_bets[id].amount==highest_bet) and counter<players.size():
		counter+=1
		id+=1
		id%=players.size()

	if counter==players.size():
		no_player_found.emit()
		return players.keys().any(_can_player_move)
	current_player=id
	return true


func get_player(id: int)->Player:
	return players[id]


@warning_ignore_start("int_as_enum_without_cast")
func showdown()->void:
	Logger.log_text("Showdown!")
	var winning_hand: Ranking = players.values().reduce(func(acc: Ranking, player: Player):
		if !player.in_game: return acc
		var rank: Ranking=rank_hand(player.hand)

		if compare_rankings(rank, acc)>0:
			return rank
		return acc

		, Ranking.new(Ranking.HandRank.HighCard, [0,0,0,0,0]))

	var winners: Array[Player]

	for p in players.values():
		if !p.in_game: continue
		var ranking: Ranking=rank_hand(p.hand)
		if compare_rankings(ranking, winning_hand)>=0:
			winners.append(p)

	if winners.size()==1:
		game_state=GameState.CONCLUSIVE
		game_over.emit(GameState.CONCLUSIVE, winners[0])
		Logger.log_text("WINNER: "+str(winners[0].id))
	else:
		game_state=GameState.TIE
		game_over.emit(GameState.TIE, winners)
		Logger.log_text("TIE! "+str(winners.map(func(p: Player): return p.id)))


func deal_cards(player: Player, count: int)->void:
	if !player.in_game: return
	for i in count:
		if deck.is_empty():
			deck_empty.emit()
			return
		player.hand.append(deck.pop_back())
	
	if deck.is_empty():
		deck_empty.emit()


func current_player_count()->int:
	return players.values().reduce(func(acc, player):
		if player.in_game: return acc+1
		return acc
		,0)


var pc_at_start_of_round: int = 0
func start_next_round()->void:
	freeze_highest_bet=false
	if game_state!=GameState.RUNNING: return
	player_bets.clear()
	pc_at_start_of_round = current_player_count()
	current_player=-1
	highest_bet = MINIMUM_BET
	calls_this_turn = 0
	current_turn+=1
	Logger.log_text("CURRENT TURN: " + str(current_turn))
	Logger.log_text("CARDS IN DECK: "+ str(deck.size()))
	Logger.log_text("CHIPS IN POOL: "+ str(pool))
	next_round.emit()

	for i in CARDS_PER_ROUND:
		for p in players.values():
			if deck.size()==0: break
			deal_cards(p, 1)
			hand_dealt.emit(p)
	_next_step()



var calls_this_turn: int=0
func _ask_next_player()->void:
	if !players[current_player].in_game: return
	
	var player_bets_text: Dictionary[int, String]
	for i in player_bets.keys(): player_bets_text[i] = Bet.Type.find_key(player_bets[i])
	Logger.log_text(" ")
	Logger.log_text("current highest bet: "+str(highest_bet))
	Logger.log_text("current player bets: "+str(player_bets_text))
	Logger.log_text("players remaining: "+str(current_player_count()))
	Logger.log_text(" ")
	players[current_player].bet()
	next_player.emit(current_player)
	return


func _final_bet()->void:
	Logger.log_text("final bet: "+str(highest_bet))
	Logger.log_text(" ")
	for p: Player in players.values():
		if !p.in_game: continue
		var bet: int = min(highest_bet, p.chips)
		p.chips-=bet
		pool+=bet
		
	Logger.log_text("CARDS IN DECK: "+ str(deck.size()))
	Logger.log_text("CHIPS IN POOL: "+ str(pool))
	round_over.emit()


func _handle_player_bet(id: int, bet: Bet)->void:
	if bet.type == bet.Type.FOLD:
		players[id].fold()
		bet.amount=-1
		player_bets[id] = bet
		player_bets_noclear[id] = bet
		return
	
	if bet.type==bet.Type.ALL_IN: players[id].all_in=true
	
	if bet.amount <= highest_bet: calls_this_turn+=1
	else: calls_this_turn = 0

	player_bets[id] = bet
	player_bets_noclear[id] = bet
	if freeze_highest_bet != id: highest_bet=max(bet.amount, highest_bet)


func _clear_game_state()->void:
	Logger.log_text("Clearing game state...")
	
	players.values().map(func(p:Player):
		p.free()
		return null)
	players.clear()
	Logger.log_text("Players deleted.")
	player_bets.clear()
	Logger.log_text("Bets deleted.")
	deck.map(func(p:Card):
		p.free()
		return null)
	deck.clear()
	cheats.clear()
	Logger.log_text("Cards in deck deleted.")
	pool=0
	current_turn=-1
	game_state=GameState.CLOSED
	Logger.log_text("Game state reset.")


func _init_game_state()->void:
	Logger.log_text("Initializing game state...")
	current_turn=0
	Logger.log_text("Turn count initialized")
	for i in Card.Suit.size():
		for j in Card.Rank.size():
			deck.append(Card.new(i,j))
	empty_deck_flag=false
	Logger.log_text("Deck created")
	deck.shuffle()
	Logger.log_text("Deck shuffled")
	cheats=[Clairvoyance.new(), WildCard.new(), Freeze.new(), Stink.new()]
	cheats.shuffle()
	for i in PLAYER_COUNT:
		players[i]=Player.new()
	current_player = 0
	Logger.log_text("Players created")
	pool=0
	Logger.log_text("Pool initialized")
	player_bets.clear()
	for p: Player in players.values():
		deal_cards(p, STARING_HAND_SIZE)
		hand_dealt.emit(p)
		p.chips=STARING_CHIP_COUNT
		p.chips-=STARTING_ANTE
		pool+=STARTING_ANTE
	Logger.log_text("Cards, chips dealt")
	
	for i in PLAYER_COUNT:
	#	players[i]=Player.new()
		players[i].controller = PlayerController.new(players[i]) if i !=0 else UserPlayerController.new(players[i])
		players[i].cheat = cheats[i]
		cheats[i].player=i
	game_state=GameState.RUNNING
	Logger.log_text("Game Opened")


func new_game()->void:
	Logger.log_text(" ")
	Logger.log_text("Beginning new game...")
	_clear_game_state()
	_init_game_state()
	game_start.emit()
	start_next_round()


func rank_hand(hand: Array[Card]) -> Ranking:
	Logger.log_text("Ranking hand: "+str(hand.map(func(c: Card): return [Card.Suit.find_key(c.suit), Card.Rank.find_key(c.rank)])))
	assert(hand.size()>=5)
	var rankings: Array[Ranking] = []

	if hand.size()<5: return Ranking.new(0,[0,0,0,0,0])
	Logger.log_text("Hand size valid")
	var suits: Array=[]
	Logger.log_text("Checking suits for flush...")

	for s in Card.Suit:
		var suit_hand: Array[Card] = hand.filter(func (c: Card)-> bool: return c.suit==Card.Suit[s])
		suits.append(suit_hand)
		Logger.log_text("\t Cards with suit "+str(s)+": "+str(suit_hand.size()))

	for suit in suits:
		if suit.size()<5: continue
		rankings.append(_rank_hand_with_flush(suit))

	var ranks: Array[int]
	ranks.resize(Card.Rank.size())

	for r in Card.Rank:
		var rank: int = hand.reduce(func (count,c: Card)-> int: return (count+1 if c.rank==Card.Rank[r] else count), 0)
		ranks[Card.Rank[r]]=rank
	
	ranks.reverse()
	Logger.log_text("Card ranks sorted, checking non-flush Rankings...")

	var fkind_4: int=ranks.find(4)
	var fkind_1: int=ranks.find(1)
	if fkind_1>=0 and fkind_4>=0:
		@warning_ignore_start("confusable_local_declaration")
		Logger.log_text("\t FOURKIND!")
		var card_ranks: Array[Card.Rank]
		card_ranks.resize(5)
		for i in 4: card_ranks[i]=(ranks.size()-fkind_4)-1
		card_ranks[4]=(ranks.size()-fkind_1)-1
		rankings.append(Ranking.new(Ranking.HandRank.FourKind, card_ranks))

	var fhouse_3: int=ranks.find(3)
	var fhouse_2: int=ranks.find(2)
	if fhouse_3>=0 and fhouse_2>=0:
		Logger.log_text("\t FULLHOUSE!")
		var card_ranks: Array[Card.Rank]
		card_ranks.resize(5)
		for i in 3: card_ranks[i]=(ranks.size()-fhouse_3)-1
		for i in range(3,5): card_ranks[i]=(ranks.size()-fhouse_2)-1
		rankings.append(Ranking.new(Ranking.HandRank.FullHouse, card_ranks))

	for i in ranks.size()-4:
		if (ranks[i]>0 and
			ranks[i+1]>0 and
			ranks[i+2]>0 and
			ranks[i+3]>0 and
			ranks[i+4]>0):
				
			Logger.log_text("\t STRAIGHT!")
			var card_ranks: Array[Card.Rank] = [(ranks.size()-i)-1,
				(ranks.size()-(i+1))-1,
				(ranks.size()-(i+2))-1,
				(ranks.size()-(i+3))-1,
				(ranks.size()-(i+4))-1]
			
			rankings.append(Ranking.new(Ranking.HandRank.Straight, card_ranks))

	var tkind_1=ranks.find(1, fkind_1+1)
	if tkind_1>=0 and fkind_1>=0 and fhouse_3>=0:
		Logger.log_text("\t THREEKIND!")
		var card_ranks: Array[Card.Rank]
		card_ranks.resize(5)
		for i in 3: card_ranks[i]=(ranks.size()-fhouse_3)-1
		for i in range(3,4): card_ranks[i]=(ranks.size()-fkind_1)-1
		card_ranks[4]=(ranks.size()-tkind_1)-1
		rankings.append(Ranking.new(Ranking.HandRank.ThreeKind, card_ranks))

	var tpair_2: int=ranks.find(2,fhouse_2+1)
	if tpair_2>=0 and fkind_1>=0 and fhouse_2>=0:
		Logger.log_text("\t TWOPAIR!")
		var card_ranks: Array[Card.Rank]
		card_ranks.resize(5)
		for i in 2: card_ranks[i]=(ranks.size()-fhouse_2)-1
		for i in range(2,4): card_ranks[i]=(ranks.size()-tpair_2)-1
		card_ranks[4]=(ranks.size()-fkind_1)-1
		rankings.append(Ranking.new(Ranking.HandRank.TwoPair, card_ranks))

	var pair_1: int=ranks.find(1, tkind_1+1)
	if pair_1>=0 and fkind_1>=0 and tkind_1>=0 and fhouse_2>=0:
		Logger.log_text("\t PAIR!")
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

	rankings.sort_custom(func (left: Ranking, right: Ranking): return compare_rankings(left, right)>0)
	Logger.log_text("Final Ranking: "+ str(Ranking.HandRank.find_key(rankings[0].hand_rank))+ " "+ str(rankings[0].cards_rank))
	Logger.log_text(" ")
	return rankings[0]


func _rank_hand_with_flush(hand: Array[Card]) -> Ranking:
	Logger.log_text("\t Ranking suit hand: "+str(hand.map(func(c: Card): return [Card.Suit.find_key(c.suit), Card.Rank.find_key(c.rank)])))
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
				Logger.log_text("\t STRAIGHT FLUSH!")
				return Ranking.new(Ranking.HandRank.StraightFlush, [card_rank[i],
					card_rank[i+1],
					card_rank[i+2],
					card_rank[i+3],
					card_rank[i+4]])
	var a=card_rank.duplicate()
	a.resize(5)
	Logger.log_text("\t FLUSH!")
	return Ranking.new(Ranking.HandRank.Flush,a)


func compare_hands(left: Array[Card], right: Array[Card]) -> int:
	var left_rank:  Ranking = rank_hand(left)
	var right_rank: Ranking = rank_hand(right)
	return compare_rankings(left_rank, right_rank)
	

func compare_rankings(left_rank: Ranking, right_rank: Ranking) -> int:
	if left_rank.hand_rank>right_rank.hand_rank: return 1
	if right_rank.hand_rank>left_rank.hand_rank: return -1

	for i in 5:
		if left_rank.cards_rank>right_rank.cards_rank: return 1
		if right_rank.cards_rank>left_rank.cards_rank: return -1

	return 0
