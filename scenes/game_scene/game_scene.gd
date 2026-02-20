class_name GameScene
extends Node2D


signal _next_action

var player: Player
@onready var hud: HUD = $HUD
@onready var ghost: GhostSprite = $Objects/Ghost
@onready var ghost_2: GhostSprite = $Objects/Ghost2
@onready var ghost_3: GhostSprite = $Objects/Ghost3
@onready var card_back: Sprite2D = $CardBack
@onready var markers: Array[Marker2D] =[$P0, $P3, $P2, $P1]

@onready var target_selector: TargetSelector = $TargetSelector

var card_back_pos: Vector2


func _ready() -> void:
	for s: int in Card.Suit.values():
		for r: int in Card.Rank.values():
			CardHUD.get_texture(s,r)
	hud.toggle_hud(false)
	card_back.visible=false
	card_back_pos=card_back.global_position
	target_selector.toggle_selection.connect(_highlight_all)
	target_selector.target_hovered.connect(_toggle_highlight.bind(true))
	target_selector.target_out.connect(_toggle_highlight.bind(false))
	hud.user_input.bet.pressed.connect(_end_user_turn)
	hud.user_input.fold.pressed.connect(_game_over)
	hud.pow.button.pressed.connect(_select_target_for_cheat)
	PokerEngine.new_game()
	player=PokerEngine.get_player(0)


func _end_user_turn()->void:
	var bet: int = hud.user_input.bet_amount.value
	hud.toggle_hud(false)
	if bet > player.chips: return
	if bet < PokerEngine.highest_bet and bet < player.chips: return
	
	var rt: Bet
	if bet==player.chips: rt = Bet.new(bet, Bet.Type.ALL_IN)
	elif bet > PokerEngine.highest_bet: rt = Bet.new(bet, Bet.Type.RAISE)
	else: rt = Bet.new(bet, Bet.Type.CALL)

	PokerEngine.handle_user_input(rt)
	FrontendManager.new_info.emit()
	FrontendManager.front_end_updated.emit()

func _game_over()->void:
	PokerEngine._clear_game_state()
	get_tree().change_scene_to_file("res://scenes/title_menu/hud/title_menu_hud.tscn")

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
var _get_input: bool =false
func update_scene_state(changes: Array[LoggedAction], get_input: bool =true)->void:
	assert(_changes.is_empty())
	_get_input=get_input
	GlobalLogger.log_text("Received actions: " + str(changes))
	GlobalLogger.log_text("get_input is " + str(get_input))
	GlobalLogger.log_text("Beginning action playback...")
	_changes = changes.duplicate()
	_changes.reverse()
	changes.clear()
	_next_action.connect(_update_scene_state)
	_update_scene_state()


func _update_scene_state()->void:
	if _changes.is_empty():
		GlobalLogger.log_text("All actions finished playing")
		_next_action.disconnect(_update_scene_state)
		FrontendManager.new_info.emit()
		if _get_input: hud.toggle_hud(true)
		else: FrontendManager.front_end_updated.emit()
		return 

	var change: LoggedAction = _changes.pop_back()
	_playback_action(change)


func _playback_action(action: LoggedAction)->void:
	GlobalLogger.log_text("Playing action: " + str(action))
	match action.type():
		LoggedAction.Type.Bet: _playback_bet(action as LBetAction)
		LoggedAction.Type.Cheat: _playback_cheat(action as LCheatAction)
		LoggedAction.Type.Deal: _playback_deal(action as LDealCardAction)
		LoggedAction.Type.Round: _playback_round(action as LNewRoundAction)
		LoggedAction.Type.GameOver: _playback_over(action as LOverAction)
		LoggedAction.Type.Showdown: _playback_showdown(action as LShowdownAction)
		_:
			push_warning("UNKNOWN ACTION TYPE \""+LoggedAction.Type.find_key(action.type())+"\", IGNORING")
			_next_action.emit()


func _playback_showdown(action: LShowdownAction)->void:
	hud.display_finished.connect(_next_action.emit, CONNECT_ONE_SHOT)
	hud.display_info("Showdown!", DISPLAY_TIME)


func _playback_over(action: LOverAction)->void:
	hud.display_finished.connect(_game_over, CONNECT_ONE_SHOT)
	hud.display_info(str(action._result), DISPLAY_TIME)


func _playback_round(action: LNewRoundAction)->void:
	hud.display_finished.connect(_next_action.emit, CONNECT_ONE_SHOT)
	hud.display_info("Round "+str(action.player), DISPLAY_TIME)


func _playback_deal(action: LDealCardAction) ->void:
	var players: Array[int] = PokerEngine.players.keys().filter(func (i: int)->bool: return PokerEngine.get_player(i).in_game)
	if players.has(1) and !players.has(3):
		players[players.find(1)]=3 #ANIMAION FIX: make sure the card goes to the right marker
		players.insert(1,players.pop_at(players.find(1))) #fix order of markers
	elif players.has(3) and !players.has(1): 
		players[players.find(3)]=1
		players.insert(1,players.pop_at(players.find(1)))
	var count = action.player *players.size()
	_playback_next_deal(count, players)


func _playback_next_deal(count: int, players: Array[int])->void:
	GlobalLogger.log_text("Next card goes to: "+str(players[count%players.size()]))
	card_back.visible=false
	if count <= 1: anim_deal_card(players[count%players.size()])\
					.finished.connect(func ()->void:
									card_back.visible=false
									_next_action.emit(), CONNECT_ONE_SHOT)
	else: anim_deal_card(players[count%players.size()]).finished.connect(_playback_next_deal.bind(count-1, players), CONNECT_ONE_SHOT)


func _playback_bet(action: LBetAction)->void:
	if action.player==0:
		hud.display_finished.connect(_next_action.emit, CONNECT_ONE_SHOT)
		hud.display_info(str(action.bet), DISPLAY_TIME)
		return	

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
	sprite.animation_player.action_finished.connect(_next_action.emit, CONNECT_ONE_SHOT)
	sprite.animation_player.do_action(GhostAnim.ActionMode.BET_FROZEN if action.frozen else bet_mode)


func _playback_cheat(action: LCheatAction)->void:
	var sprite: GhostSprite = get_sprite(action.player)
	sprite.display_info(Cheat.Type.find_key(action.name))
	if action.name == Cheat.Type.CLAIRVOYANCE or action.name ==Cheat.Type.STINK: sprite.animation_player.action_finished.connect(func (): _playback_hurt(action), CONNECT_ONE_SHOT)
	else: sprite.animation_player.action_finished.connect(_next_action.emit, CONNECT_ONE_SHOT)
	sprite.animation_player.do_action(GhostAnim.ActionMode.CHEAT)


const DISPLAY_TIME: float = 0.7
func _playback_hurt(action: LCheatAction)->void:
	match action.name:
		Cheat.Type.CLAIRVOYANCE, Cheat.Type.STINK:
			if action.target == 0:
				hud.display_finished.connect(_next_action.emit, CONNECT_ONE_SHOT)
				hud.display_info("ow", DISPLAY_TIME)
			else:
				var sprite: GhostSprite = get_sprite(action.target)
				sprite.animation_player.action_finished.connect(_next_action.emit, CONNECT_ONE_SHOT)
				sprite.animation_player.do_action(GhostAnim.ActionMode.HURT)
		_: pass


func get_sprite(player: int)->GhostSprite:
	match player:
		1: return ghost
		2: return ghost_2
		3: return ghost_3
		_: return null


func anim_deal_card(player: int)->Tween:
	card_back.global_position=card_back_pos
	var move_tween: Tween = create_tween()
	const transition_type := Tween.TRANS_LINEAR
	const ease_type := Tween.EASE_OUT
	const duration :float = 0.3
	
	card_back.visible=true
	hud.deck_size-=1
	hud.set_deck()
	move_tween.tween_property(card_back, "global_position", markers[player].global_position, duration)\
	.set_ease(ease_type).set_trans(transition_type)
	
	return move_tween
	


func _select_target_for_cheat()->void:
	if player.cheat.charge<1: return
	if player.cheat.offense():
		target_selector._toggle_selection(true)
		target_selector.target_selected.connect(target_selected, CONNECT_ONE_SHOT)
	else:
		player.cheat.execute(-1)
		FrontendManager.new_info.emit()


func target_selected(target: int)->void:
	target_selector._toggle_selection(false)
	player.cheat.execute(target)
	if player.cheat.name() == Cheat.Type.CLAIRVOYANCE: hud.show_other_hand(target)
	FrontendManager.new_info.emit()
	hud.toggle_hud(true)
	if player.cheat.name() == Cheat.Type.FREEZE: return
	get_sprite(target).animation_player.do_action(GhostAnim.ActionMode.HURT)
