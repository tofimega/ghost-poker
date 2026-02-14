class_name BetAction
extends Action

var _bet: Bet

func _init(bet: Bet)->void:
	_bet=bet

func do_action()->void:
	var p :Player = PokerEngine.get_player(0)
	p.last_bet= _bet
	PokerEngine._handle_player_bet(p)
