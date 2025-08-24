class_name HUD
extends Control

@onready var pool: Label = $Info/PanelContainer3/Pot #$GameStatus/Pool
@onready var highest_bet: Label = $Info/PanelContainer2/Bet #$GameStatus/HighestBet
#@onready var deck: Label = $GameStatus/Deck
#@onready var game_status: HBoxContainer = $GameStatus
#@onready var players: HBoxContainer = $Players
@onready var round: Label = $Info/PanelContainer/Round #$GameStatus/Round
@onready var user_input: UserInput = $UserInput

const PLAYER_STATUS = preload("res://scenes/debug_frontend/player_status/player_status.tscn")

func _ready() -> void:
	PokerEngine.next_player.connect(func(a): _update())
	PokerEngine.round_over.connect(_update)
	PokerEngine.game_over.connect(func(a,b): _update())
	PokerEngine.deck_empty.connect(_update)
	user_input.enabled=true
	
	for i in PokerEngine.PLAYER_COUNT:
		var player_status: PlayerStatus= PLAYER_STATUS.instantiate()
		player_status.player_id=i
		#players.add_child(player_status)
	
	PokerEngine.start_next_round()
	_update()

func _update()-> void:
	pool.text="Pool: "+str(PokerEngine.pool)
	#deck.text="Cards in deck: "+str(PokerEngine.deck.size())
	highest_bet.text="Highest Bet: "+str(PokerEngine.highest_bet)
	round.text="Round "+str(PokerEngine.current_turn)
