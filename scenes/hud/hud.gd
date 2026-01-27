class_name HUD
extends Control

@onready var pool: Label = $Info/PanelContainer3/Pot
@onready var highest_bet: Label = $Info/PanelContainer2/Bet

@onready var round: Label = $Info/PanelContainer/Round
@onready var user_input: UserInput = $UserInput
@onready var hand: Control = $Hand
@onready var target_hand: HandCont = $TargetHand

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var pow: CheatProgress = $CheatProgress
@onready var bet_label: Label = $Bet
@onready var deck: Label = $Info/PanelContainer4/Deck
@onready var showdown_label: Label = $Showdown
@onready var ph_cheat_name: Label = $PH_CheatName

const CARD_HUD: PackedScene = preload("res://scenes/hud/card_hud/card_hud.tscn")


func _ready() -> void:
	animation_player.play("RESET")
	toggle_hud(false)
	target_hand.visible=false
	bet_label.visible=false
	showdown_label.visible=false
	PokerEngine.next_player.connect(func(a): update())
	PokerEngine.round_over.connect(update)
	PokerEngine.game_over.connect(_display_winner)
	PokerEngine.deck_empty.connect(update)
	PokerEngine.player_bet.connect(_show_bet)
	PokerEngine.s_showdown.connect(_show_down)
	PokerEngine.start_flinch.connect(flinch)
	user_input.enabled=true

func flinch(t: int)->void:
	if t!=0: return
	await display_info("ow")
	PokerEngine.cont_cheat.emit()

func show_other_hand(target: int)->void:
	_show_hand(target_hand, target)
	target_hand.visible=true
	await get_tree().create_timer(1.5).timeout
	target_hand.visible=false


func _display_winner(result: PokerEngine.GameState, winner)-> void:
	update()
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


func display_info(message: String, time: float = 1)->void:
	bet_label.text=message
	bet_label.visible=true
	await get_tree().create_timer(time).timeout
	bet_label.visible=false
	


func _show_bet(p: int, bet: Bet)->void:
	if p != 0: return
	await display_info(str(bet))
	PokerEngine.cont.emit()



func update()-> void:
	pool.text="Pot: "+str(PokerEngine.pool)
	deck.text="Deck: "+str(PokerEngine.deck.size())
	highest_bet.text="Highest Bet: "+str(PokerEngine.highest_bet)
	round.text="Round "+str(PokerEngine.current_turn)
	pow.modulate_progress(PokerEngine.get_player(0).cheat.charge)
	ph_cheat_name.text=PokerEngine.get_player(0).cheat._name
	_show_hand(hand, 0)


func _show_hand(hand: HandCont, player: int)->void:
	for c in hand.get_children():
		c.queue_free()
	if PokerEngine.get_player(0).blinded:
		for i in PokerEngine.get_player(0).hand.size():
			hand.add_child(CARD_HUD.instantiate())
		return
	for c in PokerEngine.get_player(player).hand:
		var ch: CardHUD = CARD_HUD.instantiate()
		ch.card=c
		hand.add_child(ch)


const PLAYER_HAND_ON_POSITION: Vector2 = Vector2(120, 171)
const INPUT_PANEL_ON_POSITION: Vector2 = Vector2(2, 125)

var _hud_enabled: bool =true

func toggle_hud(enabled: bool) -> void:
	user_input.enabled=enabled
	if enabled and !_hud_enabled: animation_player.play_backwards("HUD-out")
	elif !enabled:  animation_player.play("HUD-out")
	pow.enabled=enabled
	pow.button.disabled=!enabled
	_hud_enabled=enabled
