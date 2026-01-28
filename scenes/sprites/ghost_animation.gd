extends AnimationPlayer
class_name GhostAnim

@onready var label: Label = %Label
@onready var timer: Timer = %Timer

var id: int = -1
var target: int = -1

enum AnimationState {
	IDLE_STATIC,
	IDLE_DEFAULT,
	IDLE_ALL_IN,
	IDLE_CHEAT,
	BET,
	ALL_IN,
	FOLD,
	CHEAT,
	FLINCH
}

var states: Array[AnimationState] = []
var current_state: AnimationState = AnimationState.IDLE_STATIC

func _reinit_nodes()->void:
	timer.stop()
	play("RESET")


var _no_interrupts_please: bool = false
func switch_to(state: AnimationState)->void:
	GlobalLogger.log_text("Sprite "+str(id)+": SWITCHING ANIMATION from: "+AnimationState.find_key(current_state) + " TO: "+AnimationState.find_key(state))
	if _no_interrupts_please: # prevent interrupting states with signals
		GlobalLogger.log_text("Sprite "+str(id)+": SWITCH FAILED! ANIMATION CANNOT BE INTERRUPTED. QUEUEING SWITCH FOR LATER")
		states.push_back(state)
		return 
		
	current_state = state
	_reinit_nodes()

	match current_state:
		AnimationState.IDLE_STATIC: timer.start(randf_range(1.5, 6))
		AnimationState.IDLE_DEFAULT: play("idle_default")
		AnimationState.IDLE_CHEAT: play("idle_"+PokerEngine.get_player(id).cheat._name.to_lower())
		AnimationState.IDLE_ALL_IN:
			_no_interrupts_please=true # no more moves after this
			play("idle_all_in_start")
		AnimationState.BET:
			_no_interrupts_please=true # load-bearing animation
			play("bet")
		AnimationState.ALL_IN:
			_no_interrupts_please=true # load-bearing animation
			play("all_in")
		AnimationState.FOLD:
			_no_interrupts_please=true # no more moves after this + load-bearing animation
			play("fold")
		AnimationState.CHEAT:
			_no_interrupts_please=true # load-bearing animation
			play("bet") #play("cheat")
		AnimationState.FLINCH:
			_no_interrupts_please=true # load-bearing animation
			play("flinch")
	GlobalLogger.log_text("Sprite "+str(id)+": SWITCH SUCCESFUL! NEW STATE: "+AnimationState.find_key(current_state)+", NO INTERRUPT: "+str(_no_interrupts_please))

func _on_timer_timeout() -> void:
	GlobalLogger.log_text("Sprite "+str(id)+": TIMER OUT! IN STATE: "+AnimationState.find_key(current_state))
	match current_state:
		AnimationState.IDLE_STATIC:
			if randi()%2: switch_to(AnimationState.IDLE_DEFAULT)
			else: switch_to(AnimationState.IDLE_CHEAT)
		AnimationState.IDLE_DEFAULT: pass
		AnimationState.IDLE_CHEAT: pass
		AnimationState.IDLE_ALL_IN: pass
		AnimationState.BET: pass
		AnimationState.ALL_IN: pass
		AnimationState.FOLD: pass
		AnimationState.CHEAT: pass #CONSIDER: maybe send start_flinch from timer
		AnimationState.FLINCH: pass


var incoming_queue: Array[AnimationState] = []
func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name=="RESET": return
	GlobalLogger.log_text("Sprite "+str(id)+": ANIMATION OVER! IN STATE: "+AnimationState.find_key(current_state))
	if !states.is_empty():
		GlobalLogger.log_text("Sprite "+str(id)+": QUEUED STATES FOUND! CHEWING THROUGH THEM FIRST...")
		incoming_queue.push_back(current_state) # defer processing this transition until all previous ones are processed
		_no_interrupts_please=false # the only case where forcing this variable wouldn't be okay is if _can_player_move return false, but they shouldn't receive animation commands in that state anyway
		switch_to(states.pop_front())
		return

	if !incoming_queue.is_empty():
		var old_state: AnimationState = current_state
		current_state=incoming_queue.pop_back() # pop_back because stack + call stack = queue
		_on_animation_finished("")
		current_state = old_state
		# fall through to process them all (also this is garbage)

	match current_state:
		AnimationState.IDLE_STATIC: pass
		AnimationState.IDLE_DEFAULT: switch_to(AnimationState.IDLE_STATIC)
		AnimationState.IDLE_CHEAT: switch_to(AnimationState.IDLE_STATIC)
		AnimationState.IDLE_ALL_IN: pass
		AnimationState.BET:
			_no_interrupts_please=false
			switch_to(AnimationState.IDLE_STATIC)
			PokerEngine.cont.emit()
		AnimationState.ALL_IN:
			_no_interrupts_please=false
			switch_to(AnimationState.IDLE_ALL_IN)
			PokerEngine.cont.emit()
		AnimationState.FOLD: PokerEngine.cont.emit()
		AnimationState.CHEAT:
			_no_interrupts_please=false
			switch_to(AnimationState.IDLE_STATIC)
			if target >=0: PokerEngine.start_flinch.emit(target)
			else: PokerEngine.cont_cheat.emit()
		AnimationState.FLINCH:
			_no_interrupts_please=false
			switch_to(AnimationState.IDLE_STATIC)
			PokerEngine.cont_cheat.emit()


func do_bet(i: int, bet: Bet)->void:
	if i!=id: return

	match bet.type:
		Bet.Type.FOLD: switch_to(AnimationState.FOLD)
		Bet.Type.ALL_IN: switch_to(AnimationState.ALL_IN)
		_: switch_to(AnimationState.BET)


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
