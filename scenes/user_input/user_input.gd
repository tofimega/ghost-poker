class_name UserInput
extends Control

signal user_bet(bet: Bet)

# show-only
@onready var current_chips: Label = $VBoxContainer/HBoxContainer/ChipCount/CurrentChips
@onready var remaining_chips: Label = $VBoxContainer/HBoxContainer/ChipCount/RemainingChips
@onready var bet_type: Label = $VBoxContainer/HBoxContainer/VBoxContainer/BetType

# interactive
@onready var fold: Button = $VBoxContainer/HBoxContainer/VBoxContainer/Fold
@onready var bet_amount: SpinBox = $VBoxContainer/HBoxContainer2/BetAmount
@onready var bet: Button = $VBoxContainer/HBoxContainer2/Bet

var player_id: int = 0:
	set(id):
		player_id=id
		_update_text(true)

signal input_enabled(e: bool)

var enabled: bool = false:
	set(e):
		if PokerEngine.game_state!=PokerEngine.GameState.RUNNING: e=false
		enabled=e 
		fold.disabled=!e
		bet_amount.editable=e
		bet.disabled=!e
		_update_text(true)
		input_enabled.emit(e)

func _ready()->void:
	_update_text(true)


func _on_fold_pressed() -> void:
	user_bet.emit(Bet.new(0,Bet.Type.FOLD))


func _on_bet_pressed() -> void:
	#TODO: show confirmation or error popups as needed
	_update_text(false)
	var bet: int = bet_amount.value
	if bet > PokerEngine.players[player_id].chips: return
	if bet < PokerEngine.highest_bet and bet <PokerEngine.players[player_id].chips: return
	
	var rt: Bet
	if bet==PokerEngine.players[player_id].chips: rt = Bet.new(bet, Bet.Type.ALL_IN)
	elif bet > PokerEngine.highest_bet: rt = Bet.new(bet, Bet.Type.RAISE)
	else: rt = Bet.new(bet, Bet.Type.CALL)
	user_bet.emit(rt)


func _on_bet_amount_value_changed(value: float) -> void:
	var bet: int = clamp(value, PokerEngine.highest_bet, PokerEngine.players[player_id].chips)
	bet_amount.set_value_no_signal(bet)
	_update_text(false)


func _update_text(update_bet: bool)->void:
	if PokerEngine.game_state!=PokerEngine.GameState.RUNNING: return
	var chip_count: int =PokerEngine.players[player_id].chips
	if update_bet: bet_amount.set_value_no_signal(min(PokerEngine.highest_bet, chip_count))
	var bet: int = bet_amount.value
	current_chips.text=str(chip_count)+" chips"
	remaining_chips.text=str(chip_count-bet)+" chips"
	
	if bet>=chip_count: bet_type.text="ALL IN"
	elif bet>PokerEngine.highest_bet: bet_type.text="RAISE"
	else: bet_type.text="CALL"
