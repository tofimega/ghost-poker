extends Node

signal user_player_added(id: int)

signal front_end_updated

signal new_info

var interfaces: Dictionary[int, UserInput]={} # player id, UI instance

const UI_PACKED: PackedScene = preload("res://scenes/user_input/user_input.tscn") 

func add_user_player_interface(id: int) -> UserInput: 
	var player_input: UserInput = get_hud().user_input
	player_input.player_id=id
	interfaces[id] = player_input
	return player_input


func get_selector()-> TargetSelector:
	return get_tree().get_first_node_in_group("Selector")

func get_hud() -> HUD:
	return get_tree().get_first_node_in_group("HUD")

func get_game_scene() -> GameScene:
	return get_tree().get_first_node_in_group("GameScene")
