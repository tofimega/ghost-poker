class_name  DebugFrontend
extends Control

@onready var players: HBoxContainer = $Players
@onready var pool: Label = $HBoxContainer/Pool
@onready var deck: Label = $HBoxContainer/Deck



const PLAYER_STATUS = preload("res://scenes/debug_frontend/player_status/player_status.tscn")

func _ready():
	for i in PokerEngine.PLAYER_COUNT:
		var player_status: PlayerStatus= PLAYER_STATUS.instantiate()
		player_status.player_id=i
		players.add_child(player_status)
	pool.text="Pool: "+str(PokerEngine.pool)
	deck.text="Cards in deck: "+str(PokerEngine.deck.size())
	PokerEngine.next_round.connect(func(): 	
		pool.text="Pool: "+str(PokerEngine.pool)
		deck.text="Cards in deck: "+str(PokerEngine.deck.size()))
	


func _on_button_pressed() -> void:
	PokerEngine.start_next_round()
