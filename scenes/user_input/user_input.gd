class_name UserInput
extends Control

signal user_bet(bet: Bet)

# show-only
@onready var current_chips: Label = $VBoxContainer/HBoxContainer/ChipCount/CurrentChips
@onready var remaining_chips: Label = $VBoxContainer/HBoxContainer/ChipCount/RemainingChips
@onready var bet_type: Label = $VBoxContainer/HBoxContainer/VBoxContainer/BetType

# interaactive
@onready var fold: Button = $VBoxContainer/HBoxContainer/VBoxContainer/Fold
@onready var bet_amount: SpinBox = $VBoxContainer/HBoxContainer2/BetAmount
@onready var bet: Button = $VBoxContainer/HBoxContainer2/Bet



var player_id: int = 0

var enabled: bool = false:
	set(e):
		enabled=e 
		fold.disabled=!e
		bet_amount.editable=e
		bet.disabled=!e

#TODO: select bet type, amount via interface
#TODO: bet and fold buttons


func _ready()->void:
	bet_amount.set_value_no_signal(PokerEngine.MINIMUM_BET)
	_update_text()


func _on_fold_pressed() -> void:
	pass #TODO: show popup, fold


func _on_bet_pressed() -> void:
	#TODO: show confirmation or error popups as needed
	_update_text()
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
	_update_text()
	
	
	
func _update_text()->void:
	var chip_count: int =PokerEngine.players[player_id].chips
	var bet: int = bet_amount.value
	current_chips.text=str(chip_count)+" chips"
	remaining_chips.text=str(chip_count-bet)+" chips"
	
	if bet>=chip_count: bet_type.text="ALL IN"
	elif bet>PokerEngine.highest_bet: bet_type.text="RAISE"
	else: bet_type.text="CALL"
