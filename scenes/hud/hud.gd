class_name HUD
extends VBoxContainer

@onready var pool: Label = $GameStatus/Pool
@onready var highest_bet: Label = $GameStatus/HighestBet
@onready var deck: Label = $GameStatus/Deck
@onready var game_status: HBoxContainer = $GameStatus
@onready var players: HBoxContainer = $Players
@onready var round: Label = $GameStatus/Round

const PLAYER_STATUS = preload("res://scenes/debug_frontend/player_status/player_status.tscn")

func _ready() -> void:
	PokerEngine.next_player.connect(func(a): _update())
	
	for i in PokerEngine.PLAYER_COUNT:
		var player_status: PlayerStatus= PLAYER_STATUS.instantiate()
		player_status.player_id=i
		players.add_child(player_status)
	
	PokerEngine.start_next_round()
	_update()

func _update()-> void:
	pool.text="Pool: "+str(PokerEngine.pool)
	deck.text="Cards in deck: "+str(PokerEngine.deck.size())
	highest_bet.text="Highest Bet: "+str(PokerEngine.highest_bet)
	round.text="Round "+str(PokerEngine.current_turn)
