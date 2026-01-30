@abstract
class_name LoggedAction
extends RefCounted

enum Type {
	Bet,
	Cheat
}

var player: int
@abstract func type()->Type
