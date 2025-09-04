class_name GhostSprite
extends Sprite2D

@onready var animation_tree: AnimationTree = $AnimationTree

@export var id: int=-1
@onready var label: Label = $Label


func _ready()->void:
	PokerEngine.player_bet.connect(play)
	animation_tree.animation_finished.connect(func(name: String): if name=="bet": label.visible=false)
	label.visible=false
	
func play(p: int, bet: Bet)->void:
	if p != id: return
	label.text=bet.Type.find_key(bet.type)+" "+str(bet.amount)
	label.visible=true
	if bet.type ==bet.Type.FOLD: animation_tree["parameters/playback"].travel("fold")
	else: animation_tree["parameters/playback"].travel("bet")
	
	
