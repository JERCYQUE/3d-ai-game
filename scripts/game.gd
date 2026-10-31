extends Node3D
## Level state: coin counter, HUD text and the win banner.

@onready var _score_label: Label = $UI/Hud/ScoreLabel
@onready var _victory_label: Label = $UI/Hud/VictoryLabel
@onready var _coin_sound: AudioStreamPlayer = $CoinSound

var coins_collected: int = 0
var victory: bool = false
## How many times the pickup sound was triggered (handy for tests).
var sfx_count: int = 0


func _ready() -> void:
	_victory_label.visible = false
	_update_hud()
	for coin in get_tree().get_nodes_in_group("coin"):
		coin.collected.connect(_on_coin_collected)


func _on_coin_collected() -> void:
	coins_collected += 1
	_coin_sound.play()
	sfx_count += 1
	_update_hud()
	if not victory:
		victory = true
		_victory_label.visible = true


func _update_hud() -> void:
	_score_label.text = "Монеты: %d" % coins_collected
