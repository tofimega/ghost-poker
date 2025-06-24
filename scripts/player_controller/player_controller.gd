class_name PlayerController
extends Object

var player: Player



@warning_ignore("shadowed_variable")
func _init(player: Player)->void:
	self.player=player



const POWER_ADD_HRANK: float= 5
const POWER_ADD_CRANK: float= 1.2
const POWER_ADD_TIME: float=1.5
const POWER_MULT_HSIZE: float=1
const POWER_MULT_PLAYERS:float=1
const TIME_OFFSET: float=0.5

const MIN_VAR: float=0.9
const MAX_VAR: float=1.1

func find_odds()->float:
	#var hand_size: int = player.hand.size()
	var hand_rank: Ranking = PokerEngine.rank_hand(player.hand)
	
	var rt: float=1
	
	# lower ranking -> smaller num
	
	var add_rank: float=float(hand_rank.hand_rank)/(hand_rank.HandRank.size()-1)*POWER_ADD_HRANK
	rt+=add_rank
	var add_card: float=float(hand_rank.cards_rank[0])/(Card.Rank.size()-1)*POWER_ADD_CRANK
	rt+=add_card
	#rt*=ease(rt/(POWER_ADD_HRANK+POWER_ADD_CRANK),-2)
	#var add_time: float=(1.0/(PokerEngine.current_turn+TIME_OFFSET)+1)*POWER_ADD_TIME
	
	#rt+=add_time
	
	# smaller hand  -> bigger num
	#var mult_hsize: float=(1/float(hand_size)*PokerEngine.STARING_HAND_SIZE+0.2)*POWER_MULT_HSIZE
	#rt*=mult_hsize

	# more players  -> smaller num
	var mult_players: float=(float(PokerEngine.players.values().reduce(func(acc: int,p: Player):
		if p.in_game: acc+=1
		return acc , 0))/(float(PokerEngine.PLAYER_COUNT)))*POWER_MULT_PLAYERS
	
	rt*=mult_players
	# some randomness
	rt*=randf_range(MIN_VAR, MAX_VAR)
	rt/=(POWER_ADD_CRANK+POWER_ADD_HRANK)*mult_players*MAX_VAR
	#TODO: this isnt quite right, write a custom function that modifies rt based on time
	rt=ease(rt, -((PokerEngine.current_turn+TIME_OFFSET)*POWER_ADD_TIME))
	
	#rt=clamp(rt,0,1)
	
	return rt

const CONF_THRESHOLD: float = 0.1
var conf_last_turn: float = -1325
func my_turn() -> void:
	
	# if odds<~0.1 -> fold
	var confidence: float = find_odds()
	conf_last_turn = confidence
	if confidence<CONF_THRESHOLD:
		player.fold()
		return
	var bet_amount: int = player.chips*min(confidence, 1)
	if bet_amount == 0:
		player.fold()
		return
	
	# else bet odds% of chips
	player.bet(bet_amount)
	
	print(player.id, ":",find_odds())
