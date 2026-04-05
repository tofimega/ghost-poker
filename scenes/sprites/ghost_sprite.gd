class_name GhostSprite
extends Sprite2D


@onready var animation_player: GhostAnim = %AnimationPlayer

@export var id: int=-1
@onready var label: Label = %Label
@onready var label_anim: AnimationPlayer = %LabelAnim


func _ready()->void:
	animation_player.id=id
	label.visible = true
	label_anim.play("RESET")
	label.position+=global_position

func _process(delta: float) -> void:
	label.position.x = -18 if scale == abs(scale) else 18

func display_info(text:String, color: Color = Color.WHITE, time: float=0.7)->void:
	label.visible = true
	label.text=text
	label.label_settings.font_color = color
	label_anim.play("show")
	await get_tree().create_timer(time).timeout
	label_anim.play("RESET")
