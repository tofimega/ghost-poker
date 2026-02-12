class_name LNewRoundAction
extends LoggedAction


func type()->Type: return Type.Round

func _init(round: int)->void:
	player=round

func _to_string() -> String:
	return "round begin action: round " + str(player)
