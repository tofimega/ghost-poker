class_name LBetAction
extends LoggedAction

var bet: Bet
var frozen: bool = false

func type()->Type: return Type.Bet

func _init(player: int, bet: Bet, frozen: bool) -> void:
	self.player=player
	self.bet=bet
	self.frozen=frozen
