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
const POWER_MULT_AVGBET: float = 0.6
const TIME_OFFSET: float=0.1

const MIN_VAR: float=0.9
const MAX_VAR: float=1.1

const BLUFF_THRESH: float = 0.3
const BLUFF_MULT: float = 1.1
const BLUFF_COUNT: int = 3

const FOLD_MULT: float = 1.3
const CALL_MULT: float = 1.1
const RAISE_MULT: float = 0.99
const ALL_IN_MULT: float = 0.7


func _select_target()->int:
	var others: Array[int] = PokerEngine.players.keys()
	others.erase(player.id)
	others = others.filter(func (id: int): return PokerEngine._can_player_move(PokerEngine.players[id]))
	if others.is_empty(): return -1
	others.shuffle()
	return others[0]


var early_result: float=0
func use_early_cheat()->bool:
	if !PokerEngine._can_player_move(player): return false
	if randi_range(0,1): return false
	if player.cheat.charge<1:  return false
	var target: int = _select_target()
	if target <0: return false
	early_result = cheat(target)
	return true


func find_odds()->float:
	var hand_rank: Ranking
	if player.blinded: hand_rank=Ranking.new(4, [0,0,0,0,0])
	else: hand_rank=PokerEngine.rank_hand(player.hand)
	
	var rt: float=1
	
	# lower ranking -> smaller num
	var add_rank: float=float(hand_rank.hand_rank)/(hand_rank.HandRank.size()-1)*POWER_ADD_HRANK
	rt+=add_rank
	GlobalLogger.log_text("Player " +str(player.id)+"'s hand is ranked: " + str(Ranking.HandRank.find_key(hand_rank.hand_rank))+ " ("+str(hand_rank.hand_rank)+"), confidence gained: "+str(add_rank)+", confidence total: "+str(rt))
	var add_card: float=float(hand_rank.cards_rank[0])/(Card.Rank.size()-1)*POWER_ADD_CRANK
	rt+=add_card
	GlobalLogger.log_text("Player " +str(player.id)+"'s hand: Best card in ranking is ranked: " +str(Card.Rank.find_key(hand_rank.cards_rank[0])) + " ("+str(hand_rank.cards_rank[0])+"), confidence gained: "+str(add_card)+", confidence total: "+str(rt))
	# some randomness
	rt*=randf_range(MIN_VAR, MAX_VAR)
	GlobalLogger.log_text("Player "+str(player.id)+"'s confidence randomized: "+str(rt))
	
	var avg_bet: float=0
	var other_bets: Dictionary[int, Bet] = PokerEngine.player_bets_noclear.duplicate()
	other_bets.erase(player.id)
	GlobalLogger.log_text("Player "+str(player.id)+" is considering other players' bets: "+str(other_bets))
	
	for id: int in other_bets:
		match other_bets[id].type:
			Bet.Type.CALL: avg_bet+=CALL_MULT
			Bet.Type.RAISE: avg_bet+=RAISE_MULT
			Bet.Type.FOLD: avg_bet+=FOLD_MULT
			Bet.Type.ALL_IN: avg_bet+=ALL_IN_MULT
	
	if (other_bets.size()>0):
		avg_bet/=other_bets.size()
		rt*=((avg_bet-1)*POWER_MULT_AVGBET)+1
		rt/=RAISE_MULT
		GlobalLogger.log_text("\t Player "+str(player.id)+"'s confidence adjusted according to others' bets: "+str(rt))
	else: GlobalLogger.log_text("\t But there were no bets to consider...")
	
	rt/=(POWER_ADD_CRANK+POWER_ADD_HRANK)*MAX_VAR
	GlobalLogger.log_text("Player "+str(player.id)+"'s confidence normalized: "+str(rt))
	rt=ease(rt, -((PokerEngine.current_turn+TIME_OFFSET)*POWER_ADD_TIME))
	GlobalLogger.log_text("Player "+str(player.id)+"'s confidence adjusted according to time passed: "+str(rt))
	
	if early_result!=0:
		GlobalLogger.log_text("Cheat already used")
		rt*=early_result
		early_result=0
	else:
		GlobalLogger.log_text("Using cheat power...")
		var target: int = _select_target()
		if target <0: GlobalLogger.log_text("No available targets...")
		else: rt*= cheat(target)
	GlobalLogger.log_text("Confidence after cheat: "+str(rt))

	rt=clamp(rt,0,1)
	
	# bluff
	if rt>=BLUFF_THRESH: return rt
	GlobalLogger.log_text("Player "+str(player.id)+"'s confidence too low, trying to bluff...")
	for i in randi()%BLUFF_COUNT:
		rt*=BLUFF_MULT
		GlobalLogger.log_text("\t Bluff "+str(i+1)+": "+str(rt))
	
	GlobalLogger.log_text("Player "+str(player.id)+"'s confidence after bluff: "+str(rt))

	rt=clamp(rt,0,1)
	GlobalLogger.log_text("Player "+str(player.id)+"'s confidence clamped: "+str(rt))
	return rt


const CALL_THRESHOLD: float = 0.08/MAX_VAR
const RAISE_THRESHOLD: float = 0.7/MAX_VAR
const FORCED_ALL_IN_MULT: float = 1.3
const ALL_IN_THRESHOLD: float = 0.9/MAX_VAR
var conf_last_turn: float = -1325

var forced_all_in: bool = false

func cheat(target: int)->float:
	#if player.cheat.charge < 1: return 1 #NOTE: removed for TEST ing only
	PokerEngine.action_log.push_back(LCheatAction.new(player.id, target, player.cheat.name()))
	return player.cheat.execute(target)


func bet() -> Bet:
	if player == null or !player.in_game: return
	forced_all_in=false
	cheat(0 if player.id==1 else 1) #TEST
	return Bet.new(PokerEngine.highest_bet+1, Bet.Type.RAISE) #TEST
	GlobalLogger.log_text("PLAYER "+str(player.id)+"'S TURN!" + " (chips: "+str(player.chips)+")")
	GlobalLogger.log_text(" ")
	
	var confidence: float =  find_odds()
	
	GlobalLogger.log_text("player "+str(player.id)+"'s confidence: "+ str(confidence))
	conf_last_turn = confidence
	
	GlobalLogger.log_text("player "+str(player.id)+" considers going ALL IN... "+" (threshold: " + str(ALL_IN_THRESHOLD) + ")")
	if confidence >= ALL_IN_THRESHOLD:
		GlobalLogger.log_text("player "+str(player.id)+" goes ALL IN!")
		return Bet.new(player.chips, Bet.Type.ALL_IN)
	
	if player.chips <= PokerEngine.highest_bet or player.chips==0:
		GlobalLogger.log_text("player "+str(player.id)+" has insufficient chips, considering going ALL IN... "+ "(threshold: " + str(CALL_THRESHOLD*FORCED_ALL_IN_MULT) + ")")
		if confidence >= CALL_THRESHOLD*FORCED_ALL_IN_MULT:
			GlobalLogger.log_text("player "+str(player.id)+" goes ALL IN!")
			forced_all_in=true
			return Bet.new(player.chips, Bet.Type.ALL_IN)

		GlobalLogger.log_text("player "+str(player.id)+" FOLDS!")
		return Bet.new(0, Bet.Type.FOLD)

	GlobalLogger.log_text("player "+str(player.id)+" considers RAISING... "+" (threshold: " + str(RAISE_THRESHOLD) + ")")
	if confidence >= RAISE_THRESHOLD:
		var amount: int = min(PokerEngine.highest_bet + max(player.chips*(confidence-RAISE_THRESHOLD+0.01)/10, 1), player.chips)
		GlobalLogger.log_text("player "+str(player.id)+" tries RAISING bet to: "+ str(amount))
		if amount == player.chips:
			GlobalLogger.log_text("player "+str(player.id)+"'s RAISE is more than all their chips, considering going ALL IN... "+ "(threshold: " + str(RAISE_THRESHOLD*FORCED_ALL_IN_MULT) + ")")
			
			if confidence >= RAISE_THRESHOLD*FORCED_ALL_IN_MULT: 
				GlobalLogger.log_text("player "+str(player.id)+" goes ALL IN!")
				return Bet.new(amount, Bet.Type.ALL_IN)
				
			GlobalLogger.log_text("player "+str(player.id)+" CALLS instead!")
			return Bet.new(PokerEngine.highest_bet, Bet.Type.CALL)
		
		GlobalLogger.log_text("player "+str(player.id)+" RAISES!")
		return Bet.new(amount, Bet.Type.RAISE)
	
	GlobalLogger.log_text("player "+str(player.id)+" considers CALLING... "+" (threshold: " + str(CALL_THRESHOLD) + ")")
	if confidence >= CALL_THRESHOLD:
		GlobalLogger.log_text("player "+str(player.id)+" CALLS!")
		return Bet.new(PokerEngine.highest_bet, Bet.Type.CALL)
		
	GlobalLogger.log_text("player "+str(player.id)+" FOLDS!")
	return Bet.new(0, Bet.Type.FOLD)

func is_human()->bool:
	return false
