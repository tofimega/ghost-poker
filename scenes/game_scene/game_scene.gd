class_name GameScene
extends Node2D

@onready var hud: HUD = $HUD
@onready var ghost: GhostSprite = $Objects/Ghost
@onready var ghost_2: GhostSprite = $Objects/Ghost2
@onready var ghost_3: GhostSprite = $Objects/Ghost3
@onready var card_back: Sprite2D = $CardBack
@onready var markers: Array[Marker2D] =[$P0, $P1, $P2, $P3]

@onready var target_selector: TargetSelector = $TargetSelector

var card_back_pos: Vector2


func _ready() -> void:
	hud.toggle_hud(false)
	card_back.visible=false
	card_back_pos=card_back.global_position
	await PokerEngine.new_game()
	hud.update()
	target_selector.toggle_selection.connect(_highlight_all)
	target_selector.target_hovered.connect(_toggle_highlight.bind(true))
	target_selector.target_out.connect(_toggle_highlight.bind(false))
	PokerEngine.game_over.connect(func(a,v): 
		await get_tree().create_timer(3).timeout
		get_tree().change_scene_to_file("res://scenes/title_menu/hud/title_menu_hud.tscn"))


func _highlight_all(on: bool)->void:
	_toggle_highlight(1, !on)
	_toggle_highlight(2, !on)
	_toggle_highlight(3, !on)


func _toggle_highlight(target: int,on: bool)->void:
	var target_sprite: GhostSprite
	match target:
		1: target_sprite=ghost
		2: target_sprite=ghost_2
		3: target_sprite=ghost_3
		
	var mod_color: Color = Color.DIM_GRAY if (!on) and target_selector.selection_on else Color.WHITE
	target_sprite.modulate=mod_color


func anim_deal_card(player: int)->void:
	card_back.global_position=card_back_pos
	var move_tween: Tween = create_tween()
	const transition_type := Tween.TRANS_LINEAR
	const ease_type := Tween.EASE_OUT
	const duration :float = 0.3
	
	card_back.visible=true
	move_tween.tween_property(card_back, "global_position", markers[player].global_position, duration)\
	.set_ease(ease_type).set_trans(transition_type)
	
	await move_tween.finished
	hud.update()
	card_back.visible=false
