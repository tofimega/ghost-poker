class_name GhostSprite
extends Sprite2D

@onready var animation_tree: AnimationTree = $AnimationTree

@export var id: int=-1
@onready var label: Label = $Label


func _ready()->void:
	PokerEngine.player_bet.connect(play)
	animation_tree.animation_finished.connect(func(name: String): if name=="bet" or name=="fold": label.visible=false)
	label.visible=false
	label.position+=global_position
	
func play(p: int, bet: Bet)->void:
	if p != id: return
	label.text=str(bet)
	label.visible=true
	if bet.type ==bet.Type.FOLD: animation_tree["parameters/playback"].travel("fold")
	else: animation_tree["parameters/playback"].travel("bet")
	
	
