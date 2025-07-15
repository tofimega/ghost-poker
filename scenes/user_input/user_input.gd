class_name UserInput
extends Control

signal user_bet(bet: PlayerController.Bet)

# show-only
@onready var current_chips: Label = $VBoxContainer/HBoxContainer/ChipCount/CurrentChips
@onready var remaining_chips: Label = $VBoxContainer/HBoxContainer/ChipCount/RemainingChips
@onready var bet_type: Label = $VBoxContainer/HBoxContainer/VBoxContainer/BetType

# interaactive
@onready var fold: Button = $VBoxContainer/HBoxContainer/VBoxContainer/Fold
@onready var bet_amount: SpinBox = $VBoxContainer/HBoxContainer2/BetAmount
@onready var bet: Button = $VBoxContainer/HBoxContainer2/Bet



var player_id: int

var enabled: bool:
	set(e):
		enabled=e #TODO: enable/disable all ui elements 

#TODO: select bet type, amount via interface
#TODO: bet and fold buttons


func _ready()->void:
	pass #TODO: initialize text


func _on_fold_pressed() -> void:
	pass #TODO: show popup, fold


func _on_bet_pressed() -> void:
	pass #TODO: show popup, validate amount, bet


func _on_bet_amount_value_changed(value: float) -> void:
	pass #TODO: validate, clamp, store amount, update remaining chip count text
