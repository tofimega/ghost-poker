class_name PlayerStatus
extends PanelContainer

@onready var player_id_label: Label = $VBoxContainer/PlayerID
@onready var chips: Label = $VBoxContainer/Chips
@onready var cards: VBoxContainer = $VBoxContainer/ScrollContainer/Cards
@onready var rank: Label = $VBoxContainer/Rank
@onready var conf: Label = $VBoxContainer/Conf


var player: Player

var player_id: int = PokerEngine.PLAYER_COUNT+1

func _ready():
	player=PokerEngine.get_player(player_id)
	PokerEngine.next_round.connect(_fetch_player_data, CONNECT_DEFERRED)
	_fetch_player_data()


func _fetch_player_data():
	
	if player == null:
		queue_free()
		return
	if !player.in_game:
		modulate=Color(0.5,0.5,0.5,1)
		return
	modulate=Color(1,1,1,1)
	player_id_label.text="ID: "+str(player.id)
	chips.text="Chips: "+str(player.chips)
	for c in cards.get_children(): c.queue_free()
	for c in player.hand:
		var card_label: Label = Label.new()
		card_label.text="suit: "+str(Card.Suit.find_key(c.suit))+", "+"rank: "+str(Card.Rank.find_key(c.rank))
		cards.add_child(card_label)
	var a=PokerEngine.rank_hand(player.hand)
	rank.text="Rank: "+Ranking.HandRank.find_key(a.hand_rank)+", "+ str(a.cards_rank) #a.cards_rank.map(func (r: Card.Rank): Card.Rank.find_key(r))
	conf.text="Conf: "+str(player.controller.conf_last_turn)
