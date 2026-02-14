@abstract
class_name LoggedAction
extends RefCounted

enum Type {
	Bet,
	Cheat,
	Deal,
	Round,
	GameOver,
	Showdown
}

var player: int
@abstract func type()->Type
