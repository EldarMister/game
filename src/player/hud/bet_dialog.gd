class_name BetDialog
extends Control

signal bet_confirmed(bet: int)

const MIN_BET := 10
const MAX_BET := 100

@onready var bet_slider: HSlider = %BetSlider
@onready var bet_value_label: Label = %BetValue
@onready var start_button: Button = %StartButton
@onready var home_button: Button = %HomeButton
@onready var hint_label: Label = %HintLabel

func _ready() -> void:
	hide()
	bet_slider.value_changed.connect(_on_slider_changed)
	start_button.pressed.connect(_on_start_pressed)
	home_button.pressed.connect(_on_home_pressed)

func open(current_coins: int) -> void:
	var max_value: int = int(min(MAX_BET, current_coins))
	var can_start: bool = current_coins >= MIN_BET
	bet_slider.min_value = MIN_BET
	bet_slider.max_value = float(max(MIN_BET, max_value))
	bet_slider.step = 1
	bet_slider.value = clamp(bet_slider.value, bet_slider.min_value, bet_slider.max_value)
	start_button.disabled = not can_start
	hint_label.visible = not can_start
	if not can_start:
		hint_label.text = "Need 10 coins"
	_update_value_label()
	show()

func _on_slider_changed(_value: float) -> void:
	_update_value_label()

func _update_value_label() -> void:
	bet_value_label.text = str(int(bet_slider.value))

func _on_start_pressed() -> void:
	var bet := int(bet_slider.value)
	hide()
	bet_confirmed.emit(bet)

func _on_home_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
