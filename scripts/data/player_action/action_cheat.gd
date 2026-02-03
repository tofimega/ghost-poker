class_name CheatAction
extends Action

var _target: int

func _init(target: int) -> void:
	_target=target

func do_action()->void:
	PokerEngine.get_player(0).cheat.execute(_target)
