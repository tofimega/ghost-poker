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
		
var _name: String= ""

func _boost_charge(p: int, bet: Bet)->void:
	if p!=player: return
	if bet.type==Bet.Type.FOLD: return
	charge+=.4
	

func play_anim(target: int=-1)->void:
	PokerEngine.player_cheat.emit(player, target, _name)
	await PokerEngine.cheat_anim_finished
	if target <0 or target >PokerEngine.players.size(): PokerEngine.cont_cheat.emit()
	else: await PokerEngine.cont_cheat

func computer(target: int)->float:
	if charge <1 : return 1
	await play_anim(target)
	GlobalLogger.log_text("\tSufficient charge")
	charge=0
	return _computer(target)


func user(target: int)->void:
	if charge <1: return
	await play_anim(target)
	GlobalLogger.log_text("\tSufficient charge")
	charge=0
	_user(target)


func _computer(target: int)-> float:
	GlobalLogger.log_text("\tCheat not implemented, default: 1")
	return 1


func _user(target: int) -> void:
	GlobalLogger.log_text("\tCheat not implemented")
	pass
