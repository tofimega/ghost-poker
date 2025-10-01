class_name CardHUD
extends Control

@onready var info_ph: Label = $Info_PH
var card: Card

func _ready()->void:
	if card:
		info_ph.text="r: "+str(card.rank)+"\ns: "+str(card.suit)
