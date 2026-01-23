class_name GhostSprite
extends Sprite2D


@onready var animation_player: GhostAnim = %AnimationPlayer

@export var id: int=-1
@onready var label: Label = %Label

var unique_anim_flag: bool = false

func _ready()->void:
	PokerEngine.player_bet.connect(play)
	PokerEngine.player_cheat.connect(cheat)
	animation_player.id=id
	label.visible=false
	label.position+=global_position


func play(p: int, bet: Bet)->void:
	if p != id: return
	display_info(str(bet), Color.CADET_BLUE if PokerEngine.freeze_highest_bet==id else Color.WHITE)
	

func cheat(p: int, t: int, n: String) ->void:
	if p!=id: return
	display_info(n)
	animation_player.switch_to(GhostAnim.AnimationState.CHEAT)


func display_info(text:String, color: Color = Color.WHITE, time: float=0.7)->void:
	label.text=text
	label.label_settings.font_color = color
	label.visible=true
	await get_tree().create_timer(time).timeout
	label.visible=false
