class_name PlayerHUD
extends CanvasLayer

const MOBILE_EXTRA_UI := preload("res://player/hud/mobile/mobile_device_ui.tscn")

@export var player: Player

@onready var curtain: ColorRect = %Curtain
@onready var statistic_panel: StatisticPanel = %"Statistic Panel"
@onready var global_tooltip_container: PanelContainer = $"Global Tooltip Container"
@onready var round_label: Label = %"Round Label"
@onready var player_label: Label = %"Player Label"
@onready var player_lives_value: Label = %"Player Lives Value"
@onready var dealer_label: Label = %"Dealer Label"
@onready var dealer_lives_value: Label = %"Dealer Lives Value"

var mobile_device_ui: MobileDeviceUI
var _round_hide_token: int = 0
var _round_blank_count: int = -1
var _round_live_count: int = -1

func _ready() -> void:
	await get_tree().physics_frame
	_update_lives_labels()
	LanguageManager.language_changed.connect(_on_language_changed)
	
	if is_mobile():
		mobile_device_ui = MOBILE_EXTRA_UI.instantiate()
		add_child(mobile_device_ui)
		mobile_device_ui.initialize(player)

func is_mobile() -> bool:
	return OS.has_feature("web_android") or OS.has_feature("web_ios")

func show_curtain(duration: float = 1.0) -> void:
	curtain.modulate.a = 0
	curtain.show()
	_tween_alpha(curtain, 1.0, duration)

func hide_curtain(duration: float = 1.0) -> void:
	_tween_alpha(curtain, 0, duration).tween_callback(curtain.hide)

func show_statistic(duration: float = 1.0) -> void:
	statistic_panel.modulate.a = 0
	statistic_panel.show()
	_tween_alpha(statistic_panel, 1.0, duration)

func hide_statistic(duration: float = 1.0) -> void:
	_tween_alpha(statistic_panel, 0, duration).tween_callback(statistic_panel.hide)

func show_shop_tooltip() -> void:
	if is_mobile():
		mobile_device_ui.show_skip_shop_button()
		return
	
	global_tooltip_container.modulate.a = 0
	global_tooltip_container.show()
	_tween_alpha(global_tooltip_container, 0.8, 0.25)

func hide_shop_tooltip() -> void:
	if is_mobile():
		mobile_device_ui.hide_skip_shop_button()
		return
	
	_tween_alpha(global_tooltip_container, 0, 0.25).tween_callback(global_tooltip_container.hide)

func show_round_info(blank_count: int, live_count: int) -> void:
	_round_blank_count = blank_count
	_round_live_count = live_count
	_round_hide_token += 1
	var token := _round_hide_token
	round_label.text = tr("[ROUND_INFO]") % [blank_count, live_count]
	round_label.show()
	await get_tree().create_timer(3.0).timeout
	if token == _round_hide_token:
		round_label.hide()

func set_lives(player_lives: int, dealer_lives: int) -> void:
	if player_lives_value:
		player_lives_value.text = str(player_lives)
	if dealer_lives_value:
		dealer_lives_value.text = str(dealer_lives)

func _on_language_changed(_code: String) -> void:
	_update_lives_labels()
	if round_label.visible and _round_blank_count >= 0 and _round_live_count >= 0:
		round_label.text = tr("[ROUND_INFO]") % [_round_blank_count, _round_live_count]

func _update_lives_labels() -> void:
	var code := LanguageManager.current_language
	if player_label:
		player_label.text = "Игрок" if code == "ru" else ("Оюнчу" if code == "kg" else "Player")
	if dealer_label:
		dealer_label.text = "Дилер" if code == "ru" else ("Дилер" if code == "kg" else "Dealer")

func _tween_alpha(target: Object, target_value: float, duration: float) -> Tween:
	var tween := create_tween()
	tween.tween_property(target, "modulate:a", target_value, duration)
	return tween
