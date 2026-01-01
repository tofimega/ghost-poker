class_name Cheat
extends Object

#TODO: allow cheats to be "hidden" so that animation doesn't play

var charge: float = 0:
	set(c):
		charge=clamp(c,0,1.1)
		FrontendManager.get_hud().update()

var player: int = -1:
	set(p):
		assert(p in PokerEngine.players.keys())
		PokerEngine.player_bet.connect(_boost_charge)
		player=p
		
var offense: bool = true

var _name: String= ""

func _boost_charge(p: int, bet: Bet)->void:
	if p!=player: return
	if bet.type==Bet.Type.FOLD: return
	charge+=1.1
	

func play_anim(target: int=-1)->void:
	if !offense: target = -1
	PokerEngine.player_cheat.emit(player, target, _name)
	if !offense:
		await PokerEngine.start_flinch
		PokerEngine.cont_cheat.emit()
	else: await PokerEngine.cont_cheat

func computer(target: int)->float:
	if charge <1 : return 1
	charge=0
	await play_anim(target)
	GlobalLogger.log_text("\tSufficient charge")
	return _computer(target)


func user(target: int)->void:
	if charge <1: return
	charge=0
	await play_anim(target)
	GlobalLogger.log_text("\tSufficient charge")
	_user(target)


func _computer(target: int)-> float:
	GlobalLogger.log_text("\tCheat not implemented, default: 1")
	return 1


func _user(target: int) -> void:
	GlobalLogger.log_text("\tCheat not implemented")
	pass
