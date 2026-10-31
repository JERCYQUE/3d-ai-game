extends Node3D
## Level state: coins, countdown timer, HUD, best time and restart.

const BEST_TIME_PATH := "user://best_time.cfg"
const RECORD_SECTION := "record"
const RECORD_KEY := "best_time"

@export var level_time: float = 30.0

@onready var _score_label: Label = $UI/Hud/ScoreLabel
@onready var _timer_label: Label = $UI/Hud/TimerLabel
@onready var _best_label: Label = $UI/Hud/BestLabel
@onready var _victory_label: Label = $UI/Hud/VictoryLabel
@onready var _lose_label: Label = $UI/Hud/LoseLabel
@onready var _coin_sound: AudioStreamPlayer = $CoinSound
@onready var _player: CharacterBody3D = $Player

var coins_collected: int = 0
var total_coins: int = 0
var time_left: float = 0.0
var best_time: float = 0.0
var finished: bool = false
## How many times the pickup sound was triggered (handy for tests).
var sfx_count: int = 0


func _ready() -> void:
	_victory_label.visible = false
	_lose_label.visible = false
	time_left = level_time
	best_time = _load_best_time()
	var coins: Array[Node] = get_tree().get_nodes_in_group("coin")
	total_coins = coins.size()
	for coin in coins:
		coin.collected.connect(_on_coin_collected)
	_update_score()
	_update_timer()
	_update_best()


func _process(delta: float) -> void:
	if finished:
		return
	time_left = maxf(time_left - delta, 0.0)
	_update_timer()
	if time_left <= 0.0:
		_lose()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func _on_coin_collected() -> void:
	coins_collected += 1
	_coin_sound.play()
	sfx_count += 1
	_update_score()
	if coins_collected >= total_coins:
		_win()


func _win() -> void:
	if finished:
		return
	finished = true
	var elapsed: float = level_time - time_left
	_victory_label.visible = true
	if best_time <= 0.0 or elapsed < best_time:
		best_time = elapsed
		_save_best_time(best_time)
	_update_best()
	_player.set_physics_process(false)


func _lose() -> void:
	if finished:
		return
	finished = true
	_lose_label.visible = true
	_player.set_physics_process(false)


func _update_score() -> void:
	_score_label.text = "Монеты: %d/%d" % [coins_collected, total_coins]


func _update_timer() -> void:
	_timer_label.text = "Время: %.1f" % time_left


func _update_best() -> void:
	if best_time <= 0.0:
		_best_label.text = "Лучшее время: —"
	else:
		_best_label.text = "Лучшее время: %.1f сек" % best_time


func _load_best_time() -> float:
	var config := ConfigFile.new()
	if config.load(BEST_TIME_PATH) != OK:
		return 0.0
	return float(config.get_value(RECORD_SECTION, RECORD_KEY, 0.0))


func _save_best_time(value: float) -> void:
	var config := ConfigFile.new()
	config.load(BEST_TIME_PATH)
	config.set_value(RECORD_SECTION, RECORD_KEY, value)
	config.save(BEST_TIME_PATH)
