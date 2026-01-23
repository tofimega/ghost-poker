class_name CardHUD
extends Control


@onready var texture_rect: TextureRect = $TextureRect



var card: Card


const base_path: StringName = "res://assets/images/card_face"

const suits: Dictionary[Card.Suit, StringName] = {
	Card.Suit.HEART   : "hearts",
	Card.Suit.SPADE   : "spades",
	Card.Suit.CLUB    : "clubs",
	Card.Suit.DIAMOND : "diamonds"
}

const ranks: Dictionary[Card.Rank, StringName] = {
	Card.Rank.TWO   : "2",
	Card.Rank.THREE : "3",
	Card.Rank.FOUR  : "4",
	Card.Rank.FIVE  : "5",
	Card.Rank.SIX   : "6",
	Card.Rank.SEVEN : "7",
	Card.Rank.EIGHT : "8",
	Card.Rank.NINE  : "9",
	Card.Rank.TEN   : "10",
	Card.Rank.JACK  : "jack",
	Card.Rank.QUEEN : "queen",
	Card.Rank.KING  : "king",
	Card.Rank.ACE   : "ace"
}

static var _textures: Dictionary[String, CompressedTexture2D] = {}

static func get_texture(suit: Card.Suit, rank: Card.Rank)->CompressedTexture2D:
	var path: String = base_path+"/"+suits[suit]+"/"+ranks[rank]+".png"
	if _textures.has(path): return _textures[path]
	var tex: CompressedTexture2D = load(path)
	_textures[path] = tex
	return tex

static func unload_textures()->void:
	_textures.clear()


func _ready()->void:
	if card:
		texture_rect.texture=get_texture(card.suit, card.rank)
