class_name GameResult
extends RefCounted

enum ResultType {
	CONCLUSIVE,
	TIE
}

var result_type: ResultType
var winners: Array[Player]

func _init(result_type: ResultType, winners: Array[Player])->void:
	self.result_type=result_type
	self.winners=winners
