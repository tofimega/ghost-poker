class_name PlayerStatus
extends PanelContainer

@onready var player_id_label: Label = $VBoxContainer/PlayerID
@onready var chips: Label = $VBoxContainer/Chips
@onready var cards: VBoxContainer = $VBoxContainer/ScrollContainer/Cards
@onready var rank: Label = $VBoxContainer/Rank


var player: WeakRef

var player_id: int = PokerEngine.PLAYER_COUNT+1

func _ready():
	player=weakref(PokerEngine.players[player_id])
	_fetch_player_data()


func _fetch_player_data():
	player_id_label.text+=str(player_id)
	chips.text+=str(player.get_ref().chips)
	for c in player.get_ref().hand:
		var card_label: Label = Label.new()
		card_label.text="suit: "+str(Card.Suit.find_key(c.suit))+", "+"rank: "+str(Card.Rank.find_key(c.rank))
		cards.add_child(card_label)
	var a=PokerEngine.rank_hand(player.get_ref().hand)
	rank.text+=Ranking.HandRank.find_key(a.hand_rank)+", "+ str(a.cards_rank) #a.cards_rank.map(func (r: Card.Rank): Card.Rank.find_key(r))
