class_name LCheatAction
extends LoggedAction

var target: int
var name: String

func type()->Type: return Type.Cheat

func _init(player: int, target: int, name: String)->void:
	self.player=player
	self.target=target
	self.name=name
