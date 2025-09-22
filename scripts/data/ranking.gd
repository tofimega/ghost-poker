class_name Ranking
extends RefCounted

var hand_rank: HandRank
var cards_rank: Array[Card.Rank]

enum HandRank{
	HighCard,
	Pair,
	TwoPair,
	ThreeKind,
	Straight,
	Flush,
	FullHouse,
	FourKind,
	StraightFlush
}

func _init(hand: HandRank, cards: Array[Card.Rank]):
	assert(cards.size()==5)
	hand_rank=hand
	cards_rank=cards

func _to_string() -> String:
	return HandRank.find_key(hand_rank)+"\n"+str(cards_rank)
