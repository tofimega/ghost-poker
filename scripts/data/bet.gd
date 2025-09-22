class_name Bet
extends RefCounted

enum Type {
	FOLD,
	CALL,
	RAISE,
	ALL_IN
}

var amount: int
var type: Type

func _init(amount: int, type: Type) -> void:
	self.amount=amount
	self.type=type

func _to_string() -> String:
	return Type.find_key(type)+" "+str(amount)
