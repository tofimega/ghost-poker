class_name HUD
extends Control

@onready var pool: Label = $Info/PanelContainer3/Pot #$GameStatus/Pool
@onready var highest_bet: Label = $Info/PanelContainer2/Bet #$GameStatus/HighestBet
#@onready var deck: Label = $GameStatus/Deck
#@onready var game_status: HBoxContainer = $GameStatus
#@onready var players: HBoxContainer = $Players
@onready var round: Label = $Info/PanelContainer/Round #$GameStatus/Round
@onready var user_input: UserInput = $UserInput
@onready var hand: Control = $Hand
@onready var pow: Control = $Pow_PH2


const CARD_HUD = preload("res://scenes/hud/card_hud/card_hud.tscn")

func _ready() -> void:
	PokerEngine.next_player.connect(func(a): _update())
	PokerEngine.round_over.connect(_update)
	PokerEngine.game_over.connect(func(a,b): _update())
	PokerEngine.deck_empty.connect(_update)
	user_input.input_enabled.connect(_toggle_hud)
	user_input.enabled=true
	
	
	

	#_update()

func _update()-> void:
	pool.text="Pool: "+str(PokerEngine.pool)
	#deck.text="Cards in deck: "+str(PokerEngine.deck.size())
	highest_bet.text="Highest Bet: "+str(PokerEngine.highest_bet)
	round.text="Round "+str(PokerEngine.current_turn)
	for c in hand.get_children():
		c.queue_free()
	for c in PokerEngine.get_player(0).hand:
		var ch: CardHUD = CARD_HUD.instantiate()
		ch.card=c
		hand.add_child(ch)


func _toggle_hud(enabled: bool) -> void:
	user_input.visible=enabled
	hand.visible=enabled
	pow.visible=enabled
