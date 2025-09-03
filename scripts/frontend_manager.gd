extends Node

signal user_player_added(id: int)

var interfaces: Dictionary[int, UserInput]={} # player id, player Interface

const UI_PACKED: PackedScene = preload("res://scenes/user_input/user_input.tscn") 

func add_user_player_interface(id: int) -> UserInput: 
	var player_input: UserInput = get_hud().user_input
	player_input.player_id=id
	interfaces[id] = player_input
	#get_hud().add_child(player_input)
	return player_input


func get_hud() -> HUD:
	return get_tree().get_first_node_in_group("HUD")
