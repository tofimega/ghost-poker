class_name CheatProgress
extends PanelContainer


@onready var texture_progress_bar: TextureProgressBar = $TextureProgressBar
@onready var button: Button = $Button

var enabled: bool = true

func _process(delta: float) -> void:
	if texture_progress_bar.value == texture_progress_bar.max_value and get_tree().get_frame()%2==0 and enabled:
		if texture_progress_bar.tint_progress==Color.GREEN: texture_progress_bar.tint_progress=Color.LIGHT_GREEN
		else: texture_progress_bar.tint_progress=Color.GREEN

var origin_mod: Color
func modulate_progress(progress: float)->void:
	#texture_progress_bar.value=progress
	var prog_tween: Tween =create_tween()
	prog_tween.tween_property(texture_progress_bar, "value", progress, 0.2).set_trans(Tween.TRANS_CIRC)
