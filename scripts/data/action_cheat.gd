class_name CheatAction
extends Action

var target: int


func do_action()->void:
	PokerEngine.get_player(0).cheat.
