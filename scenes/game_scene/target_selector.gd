class_name TargetSelector
extends Node


signal toggle_selection(on: bool)
signal target_hovered(id: int)
signal target_out(id: int)
signal target_selected(id: int)

@onready var button: Button = $"../Objects/Ghost/Button"
@onready var button2: Button = $"../Objects/Ghost2/Button"
@onready var button3: Button = $"../Objects/Ghost3/Button"

var selection_on: bool = false

var current_target: int=-1

func _ready()->void:
	button.mouse_entered.connect(func()->void:
		current_target=1
		target_hovered.emit(1))
	button2.mouse_entered.connect(func()->void:
		current_target=2
		target_hovered.emit(2))
	button3.mouse_entered.connect(func()->void:
		current_target=3
		target_hovered.emit(3))
	
	button.mouse_exited.connect(func()->void:
		current_target=-1
		target_out.emit(1))
	button2.mouse_exited.connect(func()->void:
		current_target=-1
		target_out.emit(2))
	button3.mouse_exited.connect(func()->void:
		current_target=-1
		target_out.emit(3))

	button.pressed.connect(func()->void:target_selected.emit(1))
	button2.pressed.connect(func()->void:target_selected.emit(2))
	button3.pressed.connect(func()->void:target_selected.emit(3))
	
	#FrontendManager.get_hud().pow.button.pressed.connect(_toggle_selection.bind(true))
	
	
	
func _toggle_selection(on: bool)->void:
	selection_on=on
	button.disabled=!on
	button2.disabled=!on
	button3.disabled=!on
	
	FrontendManager.get_hud().toggle_hud(!on)
	
	
	toggle_selection.emit(selection_on)
