class_name GhostSprite
extends Sprite2D


@onready var animation_player: GhostAnim = %AnimationPlayer

@export var id: int=-1
@onready var label: Label = %Label


func _ready()->void:
	animation_player.id=id
	label.visible=false
	label.position+=global_position


func display_info(text:String, color: Color = Color.WHITE, time: float=0.7)->void:
	label.text=text
	label.label_settings.font_color = color
	label.visible=true
	await get_tree().create_timer(time).timeout
	label.visible=false
