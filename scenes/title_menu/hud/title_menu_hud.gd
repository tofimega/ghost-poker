class_name TitleMenuHUD
extends Control


@onready var button: Button = $Button

const GAME_SCENE: PackedScene = preload("res://scenes/game_scene/game_scene.tscn")

func _on_button_pressed() -> void:
	get_tree().change_scene_to_packed(GAME_SCENE)
