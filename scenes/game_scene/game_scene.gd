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
	
	for s: int in Card.Suit.values():
		for r: int in Card.Rank.values():
			CardHUD.get_texture(s,r)
	hud.toggle_hud(false)
	card_back.visible=false
	card_back_pos=card_back.global_position
	PokerEngine.new_game()
	hud.update()
	target_selector.toggle_selection.connect(_highlight_all)
	target_selector.target_hovered.connect(_toggle_highlight.bind(true))
	target_selector.target_out.connect(_toggle_highlight.bind(false))
	PokerEngine.game_over.connect(func(a,v): 
		await get_tree().create_timer(3).timeout
		CardHUD.unload_textures()
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



func update_scene_state(changes: Array[LoggedAction])->void:
	var anim_queue: Array[GhostAnim.ActionMode] =[]
	var string_queue: Array[String] = [] # to be dosplayed in sprite's label
	while !changes.is_empty():
		var change: LoggedAction = changes.pop_back()
		match change.type():
			LoggedAction.Type.Bet:
				change = change as LBetAction
				match change.bet.type: # add bet anim, account for frozen, all_in(_idle), fold_idle
					_:pass
			LoggedAction.Type.Cheat: pass # add cheat anim + target's hit anim
	anim_queue.reverse()
	string_queue.reverse()
	_playback_actions(anim_queue, string_queue)

func _playback_actions(actions: Array[GhostAnim.ActionMode], strings: Array[String])->void:
	#while actions.pop
		#match action
			#bet: do_bet + display strings.pop ...
			#all_in: do_all_in + idle_all_in
			#...
		#await finished
	pass


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
