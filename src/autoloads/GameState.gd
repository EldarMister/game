extends Node

signal coins_changed(coins: int)

const SAVE_PATH := "user://game_state.cfg"
const DEFAULT_COINS := 50

var _coins: int = DEFAULT_COINS

func _ready() -> void:
	load_state()

func load_state() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		_coins = DEFAULT_COINS
		save_state()
		coins_changed.emit(_coins)
		return
	_coins = int(cfg.get_value("player", "coins", DEFAULT_COINS))
	coins_changed.emit(_coins)

func save_state() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "coins", _coins)
	cfg.save(SAVE_PATH)

func get_coins() -> int:
	return _coins

func set_coins(value: int) -> void:
	_coins = max(0, value)
	save_state()
	coins_changed.emit(_coins)

func add_coins(delta: int) -> void:
	_coins = max(0, _coins + delta)
	save_state()
	coins_changed.emit(_coins)

func can_spend(amount: int) -> bool:
	return _coins >= amount

func spend(amount: int) -> bool:
	if amount <= 0:
		return true
	if not can_spend(amount):
		return false
	_coins -= amount
	save_state()
	coins_changed.emit(_coins)
	return true
