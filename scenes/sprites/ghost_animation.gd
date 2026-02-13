extends AnimationPlayer
class_name GhostAnim

@onready var label: Label = %Label
@onready var timer: Timer = %Timer

var id: int = -1
var target: int = -1

enum AnimationState {
	IDLE,
	ACTION
}

enum IdleMode {
	DEFAULT,
	ALL_IN,
	FOLD
}

enum ActionMode {
	BET_DEFAULT,
	BET_ALL_IN,
	BET_FOLD,
	BET_FROZEN,
	CHEAT,
	HURT
}

var idle_mode: IdleMode = IdleMode.DEFAULT
var current_state: AnimationState = AnimationState.IDLE

signal action_finished


func do_action(action: ActionMode)->void:
	current_state = AnimationState.ACTION
	_play("RESET")
	match action:
		ActionMode.BET_DEFAULT: _play("bet")
		ActionMode.BET_ALL_IN: _play("all_in")
		ActionMode.BET_FOLD: _play("fold")
		ActionMode.CHEAT: _play("bet")
		ActionMode.HURT: _play("flinch")
		_: action_finished.emit()


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "RESET": return
	if current_state==AnimationState.ACTION:
		current_state=AnimationState.IDLE
		action_finished.emit()

	if idle_mode == IdleMode.FOLD: return
	if anim_name == "idle_all_in_start": return
	
	_back_to_idle()



func _play(anim_name: StringName)->void:
	play(anim_name)
	advance(0)


func _back_to_idle()->void:
	_play("RESET")
	match idle_mode:
		IdleMode.DEFAULT: timer.start(randf_range(1.5, 6))
		IdleMode.ALL_IN: _play("idle_all_in_start")
		IdleMode.FOLD: return


func _on_timer_timeout() -> void:
	if current_state != AnimationState.IDLE: return

	match idle_mode:
		IdleMode.DEFAULT:
			if randi_range(0,1): play("idle_default")
			else: _play("idle_"+Cheat.Type.find_key(PokerEngine.get_player(id).cheat.name()).to_lower())


func _ready() -> void:
	timer.start(randf_range(1.5, 6))
