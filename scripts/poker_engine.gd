extends Node



const PLAYER_COUNT: int = 4
const STARING_HAND_SIZE: int = 5
const STARING_CHIP_COUNT: int = 100

var players: Array[Player] = []

var deck: Array[Card] = []


func _ready(): _init_game_state()


func deal_cards(player: Player, count: int):
	for i in count:
		if deck.is_empty(): return # TODO: signal empty deck
		player.hand.append(deck.pop_back())


func _clear_game_state():
	players.clear()
	deck.clear()


func _init_game_state():
	for i in Card.Suit.SUIT_COUNT: 
		for j in Card.Rank.RANK_COUNT:
			deck.append(Card.new(i,j))

	deck.shuffle()
	for i in PLAYER_COUNT: players.append(Player.new())
	for p in players:
		deal_cards(p, STARING_HAND_SIZE)
		p.chips=STARING_CHIP_COUNT


func new_game():
	_clear_game_state()
	_init_game_state()
