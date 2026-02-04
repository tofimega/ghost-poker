@abstract
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
		
func offense()->bool: return true

@abstract func name() -> String

func _boost_charge(p: int, bet: Bet)->void:
	if p!=player: return
	if bet.type==Bet.Type.FOLD: return
	charge+=1.1


func execute(target: int)->float:
	if charge <1 : return 1
	charge=0
	GlobalLogger.log_text("\tSufficient charge")
	return _execute(target)
	
@abstract func _execute(target: int)
