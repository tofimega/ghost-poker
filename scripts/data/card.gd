class_name Card
extends Object

var suit: Suit
var rank: Rank

enum Suit{
	HEART,
	SPADE,
	CLUB,
	DIAMOND
}

enum Rank{
	TWO,
	THREE,
	FOUR,
	FIVE,
	SIX,
	SEVEN,
	EIGHT,
	NINE,
	TEN,
	JACK,
	QUEEN,
	KING,
	ACE
}

@warning_ignore("shadowed_variable")
func _init(suit: Suit, rank: Rank ):
	self.suit=suit
	self.rank=rank


func _to_string() -> String:
	return Suit.find_key(suit)+" "+Rank.find_key(rank)
