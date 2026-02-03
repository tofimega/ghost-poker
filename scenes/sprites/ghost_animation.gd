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
	match action:
		_:pass


func _on_animation_finished(anim_name: StringName) -> void:
	if current_state==AnimationState.ACTION:
		current_state=AnimationState.IDLE
		action_finished.emit()

	if idle_mode == IdleMode.FOLD: return
	if anim_name == "idle_all_in_start": return
	timer.start(randf_range(1.5, 6))


func _on_timer_timeout() -> void:
	if current_state != AnimationState.IDLE: return

	match idle_mode:
		IdleMode.DEFAULT:
			play("idle_default") if randi_range(0,1) else play("idle_"+PokerEngine.get_player(id).cheat.name().to_lower())
		IdleMode.ALL_IN: play("idle_all_in_start")

func _ready() -> void:
	timer.start(randf_range(1.5, 6))
