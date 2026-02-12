class_name LCheatAction
extends LoggedAction

var target: int
var name: Cheat.Type

func type()->Type: return Type.Cheat

func _init(player: int, target: int, name: Cheat.Type)->void:
	self.player=player
	self.target=target
	self.name=name

func _to_string() -> String:
	return "cheat action: (" + Cheat.Type.find_key(name) + ") from player " + str(player) + ", target: " + str(target)
