class_name  DebugFrontend
extends Control

@onready var players: HBoxContainer = $Players
const PLAYER_STATUS = preload("res://scenes/debug_frontend/player_status/player_status.tscn")

func _ready():
	for i in PokerEngine.PLAYER_COUNT:
		var player_status: PlayerStatus= PLAYER_STATUS.instantiate()
		player_status.player_id=i
		players.add_child(player_status)
