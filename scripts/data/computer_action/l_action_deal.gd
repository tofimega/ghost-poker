class_name LDealCardAction
extends LoggedAction


func _init(amount: int) -> void:
	player=amount


func type() -> Type:
	return Type.Deal

func _to_string() -> String:
	return "deal action: " + str(player) + " cards to all active players"
