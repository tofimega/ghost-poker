class_name  DebugFrontend
extends VBoxContainer

@onready var players: HBoxContainer = $Players
@onready var pool: Label = $HBoxContainer/Pool
@onready var deck: Label = $HBoxContainer/Deck
@onready var next_round: Button = $HBoxContainer/NextRound
@onready var h_ighest_bet: Label = $HBoxContainer/HIghestBet




const PLAYER_STATUS = preload("res://scenes/debug_frontend/player_status/player_status.tscn")

func _ready():
	PokerEngine.game_start.connect(func(): get_tree().reload_current_scene())
	PokerEngine.game_over.connect(func(a,b): next_round.disabled=true, CONNECT_DEFERRED)
	PokerEngine.game_over.connect(func(a,b): _update(), CONNECT_DEFERRED)
	PokerEngine.next_round.connect(func(): next_round.disabled=true, CONNECT_DEFERRED)
	PokerEngine.round_over.connect(func(): next_round.disabled=false, CONNECT_DEFERRED)
	PokerEngine.round_over.connect(_update, CONNECT_DEFERRED)
	
	for i in PokerEngine.PLAYER_COUNT:
		var player_status: PlayerStatus= PLAYER_STATUS.instantiate()
		player_status.player_id=i
		players.add_child(player_status)
	
	
	_update()

func _update():
	pool.text="Pool: "+str(PokerEngine.pool)
	deck.text="Cards in deck: "+str(PokerEngine.deck.size())
	h_ighest_bet.text="Highest Bet: "+str(PokerEngine.highest_bet)

func _on_button_pressed() -> void:
	PokerEngine.start_next_round()


func _on_new_game_pressed() -> void:
	PokerEngine.new_game()
