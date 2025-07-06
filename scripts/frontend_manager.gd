extends Node




signal user_player_added(id: int)

var interfaces: Dictionary[int, UserInput]={} # player id, player Interface

const UI_PACKED: PackedScene = preload("res://scenes/user_input/user_input.tscn") 

func add_user_player_interface(id: int) -> UserInput: 
	var player_input: UserInput = UI_PACKED.instantiate()
	player_input.player_id=id
#TODO: add it to screen
	interfaces[id] = player_input
	return player_input
