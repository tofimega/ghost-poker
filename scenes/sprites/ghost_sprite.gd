class_name GhostSprite
extends Sprite2D

@onready var animation_tree: AnimationTree = $AnimationTree

@export var id: int=-1
@onready var label: Label = $Label




func _ready()->void:
	PokerEngine.player_bet.connect(play)
	PokerEngine.player_cheat.connect(cheat)
	PokerEngine.start_flinch.connect(flinch)
	animation_tree.animation_finished.connect(func(name: String): if name=="bet" or name=="fold": label.visible=false)
	label.visible=false
	label.position+=global_position
	


func flinch(t: int)->void:
	if t !=id: return
	animation_tree["parameters/playback"].travel("flinch")
	

func play(p: int, bet: Bet)->void:
	if p != id: return
	label.text=str(bet)
	label.visible=true
	if bet.type ==bet.Type.FOLD: animation_tree["parameters/playback"].travel("fold")
	else: animation_tree["parameters/playback"].travel("bet")


func cheat(p: int, t: int, n: String) ->void:
	if p!=id: return
	label.text=n
	label.visible=true
	await get_tree().create_timer(.7).timeout
	label.visible=false
	PokerEngine.start_flinch.emit(t)
	

func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name=="fold" or anim_name=="bet":
		PokerEngine.cont.emit()
	elif anim_name=="flinch": 
		PokerEngine.cont_cheat.emit()
