class_name GameScene
extends Node2D


signal _next_action


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


var _changes: Array[LoggedAction] = []

func update_scene_state(changes: Array[LoggedAction])->void:
	assert(_changes.is_empty())
	_changes = changes
	_changes.reverse()
	_next_action.connect(_update_scene_state)
	_update_scene_state()


func _update_scene_state()->void:
	if _changes.is_empty():
		_next_action.disconnect(_update_scene_state)
		return #TODO: enable HUD, receive & process player actions, disable HUD, front_end_updated

	var change: LoggedAction = _changes.pop_back()
	_playback_action(change)


func _playback_action(action: LoggedAction)->void:
	match action.type():
		LoggedAction.Type.Bet: _playback_bet(action as LBetAction)
		LoggedAction.Type.Cheat: _playback_cheat(action as LCheatAction)


func _playback_bet(action: LBetAction)->void:
	var sprite: GhostSprite = get_sprite(action.player)
	sprite.display_info(str(action.bet), Color.CADET_BLUE if action.frozen else Color.WHITE)
	var bet_mode: GhostAnim.ActionMode
	match action.bet.type:
		Bet.Type.ALL_IN:
			sprite.animation_player.idle_mode=GhostAnim.IdleMode.ALL_IN
			bet_mode = GhostAnim.ActionMode.BET_ALL_IN
		Bet.Type.FOLD:
			sprite.animation_player.idle_mode=GhostAnim.IdleMode.FOLD
			bet_mode = GhostAnim.ActionMode.BET_FOLD
		_:
			sprite.animation_player.idle_mode=GhostAnim.IdleMode.DEFAULT
			bet_mode = GhostAnim.ActionMode.BET_DEFAULT
	sprite.animation_player.do_action(GhostAnim.ActionMode.BET_FROZEN if action.frozen else bet_mode)
	sprite.animation_player.action_finished.connect(_next_action.emit, CONNECT_ONE_SHOT)


func _playback_cheat(action: LCheatAction)->void:
	var sprite: GhostSprite = get_sprite(action.player)
	sprite.display_info(action.name)
	sprite.animation_player.do_action(GhostAnim.ActionMode.CHEAT)
	sprite.animation_player.action_finished.connect(func (): _playback_hurt(action), CONNECT_ONE_SHOT)


func _playback_hurt(action: LCheatAction)->void:
	match action.name:
		"clairvayance", "stink":
			if action.target == 0:
				await hud.display_info("ow")
				_next_action.emit()
			else:
				var sprite: GhostSprite = get_sprite(action.target)
				sprite.animation_player.do_action(GhostAnim.ActionMode.HURT)
				sprite.animation_player.action_finished.connect(_next_action.emit, CONNECT_ONE_SHOT)
		_: _next_action.emit()

func get_sprite(player: int)->GhostSprite:
	match player:
		1: return ghost
		2: return ghost_2
		3: return ghost_3
		_: return null


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
