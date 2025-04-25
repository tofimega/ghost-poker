class_name Card
extends RefCounted

var suit: Suit
var rank: Rank

enum Suit{
	HEART,
	SPADE,
	CLUB,
	DIAMOND,
	SUIT_COUNT
}

enum Rank{
	TWO,
	THREE,
	FOUR,
	FIVE,
	SIC,
	SEVEN,
	EIGHT,
	NINE,
	QUEEN,
	KING,
	ACE,
	RANK_COUNT
}


func _init(suit: Suit, rank: Rank ):
	self.suit=suit
	self.rank=rank
