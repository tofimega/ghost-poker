class_name GameScene
extends Node2D

@onready var hud: HUD = $HUD

func _ready() -> void:
		PokerEngine.new_game()
		hud._update()
