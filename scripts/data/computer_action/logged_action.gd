@abstract
class_name LoggedAction
extends RefCounted

enum Type {
	Bet,
	Cheat,
	Deal,
	Round
}

var player: int
@abstract func type()->Type
