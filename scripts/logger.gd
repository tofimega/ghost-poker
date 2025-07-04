extends Node

var log_file: FileAccess

var mute: bool = false:
	set(m):
		if m: log_text("[LOGGER MUTED]")
		mute=m
		if !m: log_text("[LOGGER UNMUTED]")

func _init():
	log_file = FileAccess.open("log.txt", FileAccess.WRITE)


func log_text(s: String):
	if mute: return
	log_file.store_line(s)
	log_file.flush()
	
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_CRASH, NOTIFICATION_PREDELETE, NOTIFICATION_WM_CLOSE_REQUEST:
			log_file.close()
