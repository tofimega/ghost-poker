extends AnimationPlayer
class_name GhostAnim

@onready var label: Label = %Label
@onready var timer: Timer = %Timer

var id: int = -1
var target: int = -1

enum AnimationState {
	IDLE_STATIC,
	IDLE_DEFAULT,
	IDLE_CHEAT,
	BET,
	FOLD,
	CHEAT,
	FLINCH
}

var current_state: AnimationState = AnimationState.IDLE_STATIC

func _reinit_nodes()->void:
	timer.stop()
	#label.visible=false
	stop()
	play("RESET")


var _no_interrupts_please: bool = false
func switch_to(state: AnimationState)->void:
	if _no_interrupts_please: return #prevent interrupting states with signals
		
	current_state = state
	_reinit_nodes()

	match current_state:
		AnimationState.IDLE_STATIC: timer.start(randf_range(1.5, 6))
		AnimationState.IDLE_DEFAULT: play("idle_default")
		AnimationState.IDLE_CHEAT: play("idle_"+PokerEngine.get_player(id).cheat._name.to_lower())
		AnimationState.BET:
			_no_interrupts_please=true
			play("bet")
		AnimationState.FOLD:
			_no_interrupts_please=true
			play("fold")
		AnimationState.CHEAT:
			_no_interrupts_please=true
			play("bet") #play("cheat")
		AnimationState.FLINCH:
			_no_interrupts_please=true
			play("flinch")


func _on_timer_timeout() -> void:
	match current_state:
		AnimationState.IDLE_STATIC:
			if randi()%2: switch_to(AnimationState.IDLE_DEFAULT)
			else: switch_to(AnimationState.IDLE_CHEAT)
		AnimationState.IDLE_DEFAULT: pass
		AnimationState.IDLE_CHEAT: pass
		AnimationState.BET: pass
		AnimationState.FOLD: pass
		AnimationState.CHEAT: pass #CONSIDER: maybe send start_flinch from timer
		AnimationState.FLINCH: pass


func _on_animation_finished(anim_name: StringName) -> void:
	match current_state:
		AnimationState.IDLE_STATIC: pass
		AnimationState.IDLE_DEFAULT: switch_to(AnimationState.IDLE_STATIC)
		AnimationState.IDLE_CHEAT: switch_to(AnimationState.IDLE_STATIC)
		AnimationState.BET:
			_no_interrupts_please=false
			switch_to(AnimationState.IDLE_STATIC)
			PokerEngine.cont.emit()
		AnimationState.FOLD:
			PokerEngine.cont.emit()
		AnimationState.CHEAT:
			_no_interrupts_please=false
			PokerEngine.start_flinch.emit(target)
			switch_to(AnimationState.IDLE_STATIC)
		AnimationState.FLINCH:
			_no_interrupts_please=false
			PokerEngine.cont_cheat.emit()
			switch_to(AnimationState.IDLE_STATIC)


func do_bet(i: int, bet: Bet)->void:
	if i!=id: return
	if bet.type==Bet.Type.FOLD: switch_to(AnimationState.FOLD)
	else: switch_to(AnimationState.BET)


func do_cheat(i: int, t: int, _n)->void:
	if i != id: return
	target = t
	switch_to(AnimationState.CHEAT)


func do_flinch(t: int)->void:
	if t != id: return
	switch_to(AnimationState.FLINCH)


func _ready()->void:
	PokerEngine.start_flinch.connect(do_flinch)
	PokerEngine.player_bet.connect(do_bet)
	PokerEngine.player_cheat.connect(do_cheat)
	switch_to(AnimationState.IDLE_STATIC)

func _process(delta: float)->void:
	pass
