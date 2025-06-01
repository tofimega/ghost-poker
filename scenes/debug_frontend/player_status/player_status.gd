class_name PlayerStatus
extends PanelContainer

@onready var player_id_label: Label = $VBoxContainer/PlayerID
@onready var chips: Label = $VBoxContainer/Chips
@onready var cards: VBoxContainer = $VBoxContainer/ScrollContainer/Cards
@onready var rank: Label = $VBoxContainer/Rank


var player: WeakRef

var player_id: int = PokerEngine.PLAYER_COUNT+1

func _ready():
	player=weakref(PokerEngine.get_player(player_id))
	PokerEngine.next_round.connect(_fetch_player_data)
	_fetch_player_data()


func _fetch_player_data():
	var maybe_player: Player = player.get_ref()
	if maybe_player == null:
		queue_free()
		return
	if !maybe_player.in_game:
		modulate=Color(0.5,0.5,0.5,1)
		return
	modulate=Color(1,1,1,1)
	player_id_label.text="ID: "+str(maybe_player.id)
	chips.text="Chips: "+str(maybe_player.chips)
	for c in cards.get_children(): c.queue_free()
	for c in maybe_player.hand:
		var card_label: Label = Label.new()
		card_label.text="suit: "+str(Card.Suit.find_key(c.suit))+", "+"rank: "+str(Card.Rank.find_key(c.rank))
		cards.add_child(card_label)
	var a=PokerEngine.rank_hand(player.get_ref().hand)
	rank.text="Rank: "+Ranking.HandRank.find_key(a.hand_rank)+", "+ str(a.cards_rank) #a.cards_rank.map(func (r: Card.Rank): Card.Rank.find_key(r))
