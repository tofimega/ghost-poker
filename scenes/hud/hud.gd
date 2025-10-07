class_name HUD
extends Control

@onready var pool: Label = $Info/PanelContainer3/Pot
@onready var highest_bet: Label = $Info/PanelContainer2/Bet

@onready var round: Label = $Info/PanelContainer/Round
@onready var user_input: UserInput = $UserInput
@onready var hand: Control = $Hand
@onready var target_hand: HandCont = $TargetHand


@onready var pow: CheatProgress = $CheatProgress
@onready var bet_label: Label = $Bet
@onready var deck: Label = $Info/PanelContainer4/Deck
@onready var showdown_label: Label = $Showdown

const CARD_HUD: PackedScene = preload("res://scenes/hud/card_hud/card_hud.tscn")


func _ready() -> void:
	target_hand.visible=false
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


func show_other_hand(target: int)->void:
	_show_hand(target_hand, target)
	target_hand.visible=true
	await get_tree().create_timer(1.5).timeout
	target_hand.visible=false


func _display_winner(result: PokerEngine.GameState, winner)-> void:
	_update()
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
	pow.texture_progress_bar.value=PokerEngine.get_player(0).cheat.charge
	_show_hand(hand, 0)


func _show_hand(hand: HandCont, player: int)->void:
	for c in hand.get_children():
		c.queue_free()
	if PokerEngine.get_player(0).blinded:
		hand.add_child(CARD_HUD.instantiate())
		return
	for c in PokerEngine.get_player(player).hand:
		var ch: CardHUD = CARD_HUD.instantiate()
		ch.card=c
		hand.add_child(ch)


func _toggle_hud(enabled: bool) -> void:
	#user_input.enabled=enabled
	user_input.visible=enabled
	hand.visible=enabled
	pow.visible=enabled
	pow.button.disabled=!enabled
