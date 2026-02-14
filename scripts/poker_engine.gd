extends Node

enum GameState{
	CLOSED,
	RUNNING,
	FINISHED

}

signal player_cheat(player: int, target: int, cheat_name: String)

signal player_bet(p: int, bet: Bet)

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

var _turn_queue: Array[Player] = []
var empty_deck_flag: bool=false

var player_bets: Dictionary[int, Bet]
var player_bets_noclear: Dictionary[int, Bet]
var highest_bet: int = 0

var cheats: Array[Cheat] = []

var action_log: Array[LoggedAction] = []


enum NextStep {
	NEW_ROUND,
	SHOWDOWN,
	ONE_LEFT
}


func _next_step()->NextStep:
	var p: Array[Player] = players.values().filter(func (f: Player)->bool: return f.in_game)
	if p.size()<=1: return NextStep.ONE_LEFT
	if p.filter(_can_player_move).is_empty(): return NextStep.SHOWDOWN
	return NextStep.NEW_ROUND


func _can_player_move(p: Player)->bool:
	return p.in_game and !p.all_in and !p.chips<=0


func get_player(id: int)->Player:
	return players[id]


func _end_game_eliminated()->GameResult:
	var winner: Array[Player] = players.values().filter(func (p: Player)->bool:return p.in_game)
	assert(winner.size()==1)
	var result: GameResult = GameResult.new(GameResult.ResultType.CONCLUSIVE, winner)
	_push_action(LOverAction.new(result))
	return result


func _end_game_showdown()->GameResult:
	GlobalLogger.log_text("Showdown!")
	_push_action(LShowdownAction.new())
	deal_cards(deck.size(), false)
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

	var result: GameResult
	if winners.size()==1:
		game_state=GameState.FINISHED
		result = GameResult.new(GameResult.ResultType.CONCLUSIVE, winners)
		GlobalLogger.log_text("WINNER: "+str(winners[0].id))
	else:
		game_state=GameState.FINISHED
		GlobalLogger.log_text("TIE! "+str(winners.map(func(p: Player): return p.id)))
		result = GameResult.new(GameResult.ResultType.TIE, winners)
	_push_action(LOverAction.new(result))
	return result


func refill_deck()->void:
	for i in Card.Suit.size():
		for j in Card.Rank.size():
			deck.append(Card.new(i,j))


func deal_cards(count: int, refill: bool=true)->void:
	var p: Array[Player] = players.values().filter(func (f: Player)->bool: return f.in_game)
	var c: int = 0
	for i in count:
		for player: Player in p:
			if deck.is_empty():
				if refill: refill_deck()
				else: break
			c+=1
			player.hand.append(deck.pop_back())
	_push_action(LDealCardAction.new(c/p.size()))


func current_player_count()->int:
	return players.values().reduce(func(acc, player):
		if player.in_game: return acc+1
		return acc
		,0)


var pc_at_start_of_round: int = 0
func start_next_round()->void:
	if game_state!=GameState.RUNNING: return
	player_bets.clear()
	pc_at_start_of_round = current_player_count()
	_turn_queue = [players[0], players[1], players[2], players[3]]
	_turn_queue = _turn_queue.filter(_can_player_move)
	GlobalLogger.log_text("TURN QUEUE INITIALIZED: "+str(_turn_queue))
	highest_bet = MINIMUM_BET
	current_turn+=1
	
	GlobalLogger.log_text("CURRENT TURN: " + str(current_turn))
	GlobalLogger.log_text("CARDS IN DECK: "+ str(deck.size()))
	GlobalLogger.log_text("CHIPS IN POOL: "+ str(pool))

	deal_cards(CARDS_PER_ROUND)
	_push_action(LNewRoundAction.new(current_turn))
	for p: Player in players.values():
		if !p.in_game or p.controller.is_human(): continue
		p.controller.use_early_cheat()
	

	FrontendManager.front_end_updated.connect(_process_round, CONNECT_ONE_SHOT)
	FrontendManager.get_game_scene().update_scene_state(action_log, false)


func _process_round()->void:

	if _process_queue(): 
		FrontendManager.front_end_updated.connect(_process_round, CONNECT_ONE_SHOT)
		FrontendManager.get_game_scene().update_scene_state(action_log)
	else:
		_final_bet()
		var next_step: NextStep = _next_step()
		match next_step:
			NextStep.NEW_ROUND:
				FrontendManager.front_end_updated.connect(start_next_round, CONNECT_ONE_SHOT)
				FrontendManager.get_game_scene().update_scene_state(action_log, false)
			NextStep.SHOWDOWN:
				_end_game_showdown()
				FrontendManager.get_game_scene().update_scene_state(action_log, false)
			NextStep.ONE_LEFT:
				_end_game_eliminated()
				FrontendManager.get_game_scene().update_scene_state(action_log, false)
		return
	


func handle_user_input(user_bet: Bet)->void:
	var player: Player = get_player(0)
	player.last_bet=user_bet
	_handle_player_bet(player)


func _push_action(a: LoggedAction)->void:
	action_log.push_back(a)
	GlobalLogger.log_text("New action: "+ str(a))


func _process_queue()->bool:
	while !_turn_queue.is_empty():
		var player: Player = _turn_queue.pop_front()
		assert(_can_player_move(player))
		if player.controller.is_human(): return true #func outside handles front-end stuff, front-end plays animations of computer moves (sent via queue), takes user input, handles bet, signals back, back-end calls function again
		_handle_player_bet(player)
	return false


func _final_bet()->void:
	assert(_turn_queue.is_empty())
	GlobalLogger.log_text("final bet: "+str(highest_bet))
	GlobalLogger.log_text(" ")
	for id: int in players:
		var p: Player = players[id]
		if !p.in_game: continue
		if p.chips==0: continue
		if !player_bets.has(id): continue
		var bet: int = mini(player_bets[id].amount, p.chips)
		p.chips-=bet
		pool+=bet
		
	GlobalLogger.log_text("CARDS IN DECK: "+ str(deck.size()))
	GlobalLogger.log_text("CHIPS IN POOL: "+ str(pool))


func _handle_player_bet(p: Player)->void:
	var bet: Bet = p.my_turn()
	var id: int = p.id
	
	if bet.type == bet.Type.FOLD:
		p.fold()
		bet.amount=-1
		player_bets[id] = bet
		player_bets_noclear[id] = bet
		_push_action(LBetAction.new(id, bet, p.frozen))
		return
	
	if bet.type==bet.Type.ALL_IN: p.all_in=true

	player_bets[id] = bet
	player_bets_noclear[id] = bet
	var prev_highest: int = highest_bet
	if !p.frozen: highest_bet=maxi(bet.amount, highest_bet)
	else: p.frozen=false
	
	if highest_bet>prev_highest: _expand_turn_queue(p)
	_push_action(LBetAction.new(id, bet, p.frozen))
	player_bet.emit(p.id, bet)


func _expand_turn_queue(exclude: Player)->void: 
	var more_players: Array[Player] = [players[0], players[1], players[2], players[3]]
	more_players.erase(exclude)
	more_players = more_players.filter(_can_player_move)
	more_players = more_players.filter(func (f: Player): return f not in _turn_queue)
	# edge case: player n raises, but player w/ id n+1 is not in the queue (because they raised earlier)
	# if such a player exists, they need to be added to the beginning instead of the end
	var priority_players: Array[Player] = more_players.filter(func(f: Player): return f.id > exclude.id)
	for r: Player in priority_players: more_players.erase(r)
	while !priority_players.is_empty(): _turn_queue.push_front(priority_players.pop_back())
	_turn_queue.append_array(more_players)


func _clear_game_state()->void:
	GlobalLogger.log_text("Clearing game state...")
	
	players.values().map(func(p:Player):
		p.free()
		return null)
	players.clear()
	_turn_queue.clear()
	GlobalLogger.log_text("Players deleted.")
	player_bets.clear()
	GlobalLogger.log_text("Bets deleted.")
	deck.map(func(p:Card):
		p.free()
		return null)
	deck.clear()
	cheats.clear()
	GlobalLogger.log_text("Cards in deck deleted.")
	pool=0
	current_turn=-1
	game_state=GameState.CLOSED
	GlobalLogger.log_text("Game state reset.")


func _init_game_state()->void:
	GlobalLogger.log_text("Initializing game state...")
	current_turn=0
	GlobalLogger.log_text("Turn count initialized")
	refill_deck()
	empty_deck_flag=false
	action_log.clear()
	GlobalLogger.log_text("Deck created")
	deck.shuffle()
	GlobalLogger.log_text("Deck shuffled")
	cheats=[Clairvoyance.new(), WildCard.new(), Freeze.new(), Stink.new()]
	cheats.shuffle()
	for i in PLAYER_COUNT:
		players[i]=Player.new()
		players[i].id=i
	GlobalLogger.log_text("Players created")
	pool=0
	GlobalLogger.log_text("Pool initialized")
	player_bets.clear()
	for i in PLAYER_COUNT:
		players[i].controller = PlayerController.new(players[i]) if i !=0 else UserPlayerController.new(players[i])
		players[i].cheat = cheats[i]
		cheats[i].player=i
	FrontendManager.new_info.emit()
	deal_cards(STARING_HAND_SIZE)
	for p: Player in players.values():
		
		p.chips=STARING_CHIP_COUNT
		p.chips-=STARTING_ANTE
		pool+=STARTING_ANTE
	GlobalLogger.log_text("Cards, chips dealt")
	
	game_state=GameState.RUNNING
	GlobalLogger.log_text("Game Opened")



func new_game()->void:
	GlobalLogger.log_text(" ")
	GlobalLogger.log_text("Beginning new game...")
	_clear_game_state()
	_init_game_state()
	start_next_round()


func rank_hand(hand: Array[Card]) -> Ranking:
	GlobalLogger.log_text("Ranking hand: "+str(hand.map(func(c: Card): return [Card.Suit.find_key(c.suit), Card.Rank.find_key(c.rank)])))
	assert(hand.size()>=5)
	var rankings: Array[Ranking] = []

	if hand.size()<5: return Ranking.new(0,[0,0,0,0,0])
	GlobalLogger.log_text("Hand size valid")
	var suits: Array=[]
	GlobalLogger.log_text("Checking suits for flush...")

	for s in Card.Suit:
		var suit_hand: Array[Card] = hand.filter(func (c: Card)-> bool: return c.suit==Card.Suit[s])
		suits.append(suit_hand)
		GlobalLogger.log_text("\t Cards with suit "+str(s)+": "+str(suit_hand.size()))

	for suit in suits:
		if suit.size()<5: continue
		rankings.append(_rank_hand_with_flush(suit))

	var ranks: Array[int]
	ranks.resize(Card.Rank.size())

	for r in Card.Rank:
		var rank: int = hand.reduce(func (count,c: Card)-> int: return (count+1 if c.rank==Card.Rank[r] else count), 0)
		ranks[Card.Rank[r]]=rank
	
	ranks.reverse()
	GlobalLogger.log_text("Card ranks sorted, checking non-flush Rankings...")

	var fkind_4: int=ranks.find(4)
	var fkind_1: int=ranks.find(1)
	if fkind_1>=0 and fkind_4>=0:
		@warning_ignore_start("confusable_local_declaration")
		GlobalLogger.log_text("\t FOURKIND!")
		var card_ranks: Array[Card.Rank]
		card_ranks.resize(5)
		for i in 4: card_ranks[i]=(ranks.size()-fkind_4)-1
		card_ranks[4]=(ranks.size()-fkind_1)-1
		rankings.append(Ranking.new(Ranking.HandRank.FourKind, card_ranks))

	var fhouse_3: int=ranks.find(3)
	var fhouse_2: int=ranks.find(2)
	if fhouse_3>=0 and fhouse_2>=0:
		GlobalLogger.log_text("\t FULLHOUSE!")
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
				
			GlobalLogger.log_text("\t STRAIGHT!")
			var card_ranks: Array[Card.Rank] = [(ranks.size()-i)-1,
				(ranks.size()-(i+1))-1,
				(ranks.size()-(i+2))-1,
				(ranks.size()-(i+3))-1,
				(ranks.size()-(i+4))-1]
			
			rankings.append(Ranking.new(Ranking.HandRank.Straight, card_ranks))

	var tkind_1=ranks.find(1, fkind_1+1)
	if tkind_1>=0 and fkind_1>=0 and fhouse_3>=0:
		GlobalLogger.log_text("\t THREEKIND!")
		var card_ranks: Array[Card.Rank]
		card_ranks.resize(5)
		for i in 3: card_ranks[i]=(ranks.size()-fhouse_3)-1
		for i in range(3,4): card_ranks[i]=(ranks.size()-fkind_1)-1
		card_ranks[4]=(ranks.size()-tkind_1)-1
		rankings.append(Ranking.new(Ranking.HandRank.ThreeKind, card_ranks))

	var tpair_2: int=ranks.find(2,fhouse_2+1)
	if tpair_2>=0 and fkind_1>=0 and fhouse_2>=0:
		GlobalLogger.log_text("\t TWOPAIR!")
		var card_ranks: Array[Card.Rank]
		card_ranks.resize(5)
		for i in 2: card_ranks[i]=(ranks.size()-fhouse_2)-1
		for i in range(2,4): card_ranks[i]=(ranks.size()-tpair_2)-1
		card_ranks[4]=(ranks.size()-fkind_1)-1
		rankings.append(Ranking.new(Ranking.HandRank.TwoPair, card_ranks))

	var pair_1: int=ranks.find(1, tkind_1+1)
	if pair_1>=0 and fkind_1>=0 and tkind_1>=0 and fhouse_2>=0:
		GlobalLogger.log_text("\t PAIR!")
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
	GlobalLogger.log_text("Final Ranking: "+ str(Ranking.HandRank.find_key(rankings[0].hand_rank))+ " "+ str(rankings[0].cards_rank))
	GlobalLogger.log_text(" ")
	return rankings[0]


func _rank_hand_with_flush(hand: Array[Card]) -> Ranking:
	GlobalLogger.log_text("\t Ranking suit hand: "+str(hand.map(func(c: Card): return [Card.Suit.find_key(c.suit), Card.Rank.find_key(c.rank)])))
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
				GlobalLogger.log_text("\t STRAIGHT FLUSH!")
				return Ranking.new(Ranking.HandRank.StraightFlush, [card_rank[i],
					card_rank[i+1],
					card_rank[i+2],
					card_rank[i+3],
					card_rank[i+4]])
	var a=card_rank.duplicate()
	a.resize(5)
	GlobalLogger.log_text("\t FLUSH!")
	return Ranking.new(Ranking.HandRank.Flush,a)


func compare_hands(left: Array[Card], right: Array[Card]) -> int:
	var left_rank:  Ranking = rank_hand(left)
	var right_rank: Ranking = rank_hand(right)
	return compare_rankings(left_rank, right_rank)


func compare_rankings(left_rank: Ranking, right_rank: Ranking) -> int:
	if left_rank.hand_rank>right_rank.hand_rank: return 1
	if right_rank.hand_rank>left_rank.hand_rank: return -1

	if left_rank.cards_rank>right_rank.cards_rank: return 1
	if right_rank.cards_rank>left_rank.cards_rank: return -1

	return 0
