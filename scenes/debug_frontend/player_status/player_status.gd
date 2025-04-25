class_name PlayerStatus
extends PanelContainer

@onready var player_id_label: Label = $VBoxContainer/PlayerID
@onready var chips: Label = $VBoxContainer/Chips
@onready var cards: VBoxContainer = $VBoxContainer/ScrollContainer/Cards


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
		card_label.text="suit: "+str(c.suit)+", "+"rank: "+str(c.rank)
		cards.add_child(card_label)
