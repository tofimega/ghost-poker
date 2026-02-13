class_name LOverAction
extends LoggedAction


func type()->Type: return Type.GameOver

var _result: GameResult

func _init(result: GameResult) -> void:
	_result = result
	
func _to_string() -> String:
	return "Game Over Action " + str(_result)
