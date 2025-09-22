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
@onready var bet_label: Label = $Bet
@onready var deck: Label = $Info/PanelContainer4/Deck
@onready var showdown_label: Label = $Showdown

const CARD_HUD = preload("res://scenes/hud/card_hud/card_hud.tscn")

func _ready() -> void:
	bet_label.visible=false
	showdown_label.visible=false
	PokerEngine.next_player.connect(func(a): _update())
	PokerEngine.round_over.connect(_update)
	PokerEngine.game_over.connect(_display_winner)
	PokerEngine.deck_empty.connect(_update)
	PokerEngine.player_bet.connect(_show_bet)
	PokerEngine.s_showdown.connect(_show_down)
	user_input.input_enabled.connect(_toggle_hud)
	user_input.enabled=true

func _display_winner(result: PokerEngine.GameState, winner)-> void:
	if result == PokerEngine.GameState.TIE:
		bet_label.text="DRAW!\n"
		for w in winner:
			bet_label.text+="Player "+str(w.id)+" "+str(PokerEngine.rank_hand(w.hand))
	elif result == PokerEngine.GameState.CONCLUSIVE:
		bet_label.text="GAME OVER!\n"+"Winner: Player "+str(winner.id)+"\n"+str(PokerEngine.rank_hand(winner.hand))
	bet_label.visible=true
	
func _show_down(cause: bool)->void:
	showdown_label.text="SHOWDOWN!\n"
	if cause: showdown_label.text+="Deck empty"
	else: showdown_label.text+="Nobody can bet"
	showdown_label.visible=true

func _show_bet(p: int, bet: Bet)->void:
	if p != 0: return
	bet_label.text=str(bet)
	bet_label.visible=true
	await get_tree().create_timer(1).timeout
	bet_label.visible=false

func _update()-> void:
	pool.text="Pot: "+str(PokerEngine.pool)
	deck.text="Deck: "+str(PokerEngine.deck.size())
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
