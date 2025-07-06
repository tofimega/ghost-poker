class_name UserInput
extends Control

signal user_bet(bet: PlayerController.Bet)


var player_id: int

var enabled: bool:
	set(e):
		enabled=e #TODO: enable/disable all ui elements 

#TODO: select bet type, amount via interface
#TODO: bet and fold buttons
