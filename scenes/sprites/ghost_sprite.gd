class_name GhostSprite
extends Sprite2D

@onready var animation_tree: AnimationTree = $AnimationTree

@export var id: int=-1


func _ready()->void:
	PokerEngine.player_bet.connect(play)
	
func play(p: int, bet: Bet)->void:
	if p != id: return
	if bet.type ==bet.Type.FOLD: animation_tree["parameters/playback"].travel("fold")
	else: animation_tree["parameters/playback"].travel("bet")
	
	
