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

const BLUFF_THRESH: float = 0.3
const BLUFF_MULT: float = 1.1
const BLUFF_COUNT: int = 3

const FOLD_MULT: float = 1.3
const CALL_MULT: float = 1.1
const RAISE_MULT: float = 0.99
const ALL_IN_MULT: float = 0.7

#TODO: consider previous bets in round
func find_odds()->float:

	var hand_rank: Ranking = PokerEngine.rank_hand(player.hand)
	
	var rt: float=1
	
	# lower ranking -> smaller num
	var add_rank: float=float(hand_rank.hand_rank)/(hand_rank.HandRank.size()-1)*POWER_ADD_HRANK
	rt+=add_rank
	var add_card: float=float(hand_rank.cards_rank[0])/(Card.Rank.size()-1)*POWER_ADD_CRANK
	rt+=add_card
	
	# some randomness
	rt*=randf_range(MIN_VAR, MAX_VAR)
	
	
	var avg_bet: float=0
	for id: int in PokerEngine.player_bets:
		if id == player.id: continue
		
		match PokerEngine.player_bets[id]:
			Bet.Type.CALL: avg_bet+=CALL_MULT
			Bet.Type.RAISE: avg_bet+=RAISE_MULT
			Bet.Type.FOLD: avg_bet+=FOLD_MULT
			Bet.Type.ALL_IN: avg_bet+=ALL_IN_MULT
	
	if PokerEngine.player_bets.size()>0:
		avg_bet/=PokerEngine.player_bets.size()
		rt*=avg_bet
		rt/=RAISE_MULT
	
	rt/=(POWER_ADD_CRANK+POWER_ADD_HRANK)*MAX_VAR
	rt=ease(rt, -((PokerEngine.current_turn+TIME_OFFSET)*POWER_ADD_TIME))
	
	#bluff
	if rt>=BLUFF_THRESH: return rt
	
	for i in randi()%BLUFF_COUNT:
		rt*=BLUFF_MULT
	
	rt=clamp(rt,0,1)
	return rt

class Bet extends RefCounted:
	enum Type {
		FOLD,
		CALL,
		RAISE,
		ALL_IN
	}
	var amount: int
	var type: Type
	
	func _init(amount: int, type: Type) -> void:
		self.amount=amount
		self.type=type


const CALL_THRESHOLD: float = 0.08/MAX_VAR
const RAISE_THRESHOLD: float = 0.7/MAX_VAR
const FORCED_ALL_IN_MULT: float = 1.3
const ALL_IN_THRESHOLD: float = 0.9/MAX_VAR
var conf_last_turn: float = -1325

var forced_all_in: bool = false
func my_turn() -> Bet:
	if player == null or !player.in_game: return null
	forced_all_in=false
	Logger.log_text("PLAYER "+str(player.id)+"'S TURN!" + " (chips: "+str(player.chips)+")")
	Logger.log_text(" ")
	
	
	var confidence: float = find_odds()
	Logger.log_text("player "+str(player.id)+"'s confidence: "+ str(confidence))
	conf_last_turn = confidence
	
	Logger.log_text("player "+str(player.id)+" considers going ALL IN... "+" (threshold: " + str(ALL_IN_THRESHOLD) + ")")
	if confidence >= ALL_IN_THRESHOLD:
		Logger.log_text("player "+str(player.id)+" goes ALL IN!")
		return Bet.new(player.chips, Bet.Type.ALL_IN)
	
	if player.chips <= PokerEngine.highest_bet or player.chips==0:
		Logger.log_text("player "+str(player.id)+" has insufficient chips, considering going ALL IN... "+ "(threshold: " + str(CALL_THRESHOLD*FORCED_ALL_IN_MULT) + ")")
		if confidence >= CALL_THRESHOLD*FORCED_ALL_IN_MULT:
			Logger.log_text("player "+str(player.id)+" goes ALL IN!")
			forced_all_in=true
			return Bet.new(player.chips, Bet.Type.ALL_IN)
		Logger.log_text("player "+str(player.id)+" FOLDS!")
		return Bet.new(0, Bet.Type.FOLD)
		
	
	Logger.log_text("player "+str(player.id)+" considers RAISING... "+" (threshold: " + str(RAISE_THRESHOLD) + ")")
	if confidence >= RAISE_THRESHOLD:
		var amount: int = min(PokerEngine.highest_bet + max(player.chips*(confidence-RAISE_THRESHOLD+0.01)/10, 1), player.chips)
		Logger.log_text("player "+str(player.id)+" tries RAISING bet to: "+ str(amount))
		if amount == player.chips:
			Logger.log_text("player "+str(player.id)+"'s RAISE is more than all their chips, considering going ALL IN... "+ "(threshold: " + str(RAISE_THRESHOLD*FORCED_ALL_IN_MULT) + ")")
			if confidence >= RAISE_THRESHOLD*FORCED_ALL_IN_MULT: 
				Logger.log_text("player "+str(player.id)+" goes ALL IN!")
				return Bet.new(amount, Bet.Type.ALL_IN)
			Logger.log_text("player "+str(player.id)+" CALLS instead!")
			return Bet.new(PokerEngine.highest_bet, Bet.Type.CALL)
		
		Logger.log_text("player "+str(player.id)+" RAISES!")
		return Bet.new(amount, Bet.Type.RAISE)
	
	Logger.log_text("player "+str(player.id)+" considers CALLING... "+" (threshold: " + str(CALL_THRESHOLD) + ")")
	if confidence >= CALL_THRESHOLD:
		Logger.log_text("player "+str(player.id)+" CALLS!")
		return Bet.new(PokerEngine.highest_bet, Bet.Type.CALL)
		
	Logger.log_text("player "+str(player.id)+" FOLDS!")
	return Bet.new(0, Bet.Type.FOLD)
