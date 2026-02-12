extends Node

var log_file: FileAccess


func _init()->void:
	log_file = FileAccess.open("log.txt", FileAccess.WRITE)


func log_text(s: String)->void:
	log_file.store_line(s)
	log_file.flush()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_CRASH, NOTIFICATION_PREDELETE, NOTIFICATION_WM_CLOSE_REQUEST:
			log_file.close()
