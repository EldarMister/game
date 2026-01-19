extends Node

const SAVE_PATH := "user://coins.save"

var coins: int = 500

func _ready() -> void:
	load_coins()

func add_coins(amount: int) -> void:
	coins = max(0, coins + amount)

func save_coins() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_32(coins)
		file.close()

func load_coins() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		coins = file.get_32()
		file.close()
