class_name Cheat
extends Object


var charge: float = 0:
	set(c):
		charge=clamp(c,0,1.1)

var player: int = -1:
	set(p):
		assert(p in PokerEngine.players.keys())
		PokerEngine.player_bet.connect(_boost_charge)
		player=p
		

func _boost_charge(p: int, bet: Bet)->void:
	if p!=player: return
	if bet.type==Bet.Type.FOLD: return
	charge+=.4
	

func computer(target: int)->float:
	if charge <1 : return 1
	GlobalLogger.log_text("\tSufficient charge")
	charge=0
	return _computer(target)


func user(target: int)->void:
	if charge <1: return
	GlobalLogger.log_text("\tSufficient charge")
	charge=0
	_user(target)


func _computer(target: int)-> float:
	GlobalLogger.log_text("\tCheat not implemented, default: 1")
	return 1


func _user(target: int) -> void:
	GlobalLogger.log_text("\tCheat not implemented")
	pass
