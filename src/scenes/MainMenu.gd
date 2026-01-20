extends Control

const REWARDED_AD_UNIT_ID := "ca-app-pub-1150942230390878/8701627186"
const INTERSTITIAL_AD_UNIT_ID := "ca-app-pub-1150942230390878/5403727614"
const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "settings"
const KEY_LANGUAGE := "language"
const KEY_LANGUAGE_SET := "language_set"

@onready var coins_label: Label = $CoinsPanel/CoinsLabelMargin/CoinsLabel
@onready var play_button: TextureButton = $PlayButton
@onready var ads_button: TextureButton = $AdsButtonEng

var admob: Object
var rewarded_unit_id: String = REWARDED_AD_UNIT_ID
var interstitial_unit_id: String = INTERSTITIAL_AD_UNIT_ID

func _ready() -> void:
	if _needs_language_selection():
		get_tree().change_scene_to_file("res://scenes/LanguageMenu.tscn")
		return
	GameState.coins_changed.connect(_on_coins_changed)
	_update_coins_label()
	_update_texts()
	LanguageManager.language_changed.connect(_on_language_changed)
	_setup_admob()

func _setup_admob() -> void:
	if not Engine.has_singleton("DroidAdMob"):
		return
	admob = Engine.get_singleton("DroidAdMob")
	admob.connect("rewarded", Callable(self, "_on_rewarded"))
	admob.connect("rewarded_ad_loaded", Callable(self, "_on_rewarded_loaded"))
	admob.connect("rewarded_ad_failed_to_load", Callable(self, "_on_rewarded_failed"))
	var test_mode := OS.is_debug_build()
	admob.initialize(test_mode)
	rewarded_unit_id = admob.getTestRewardedAdUnit() if test_mode else REWARDED_AD_UNIT_ID
	interstitial_unit_id = admob.getTestInterstitialAdUnit() if test_mode else INTERSTITIAL_AD_UNIT_ID
	admob.loadRewarded(rewarded_unit_id)
	admob.loadInterstitial(interstitial_unit_id)

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_watch_ad_button_pressed() -> void:
	if admob and admob.isRewardedLoaded():
		admob.showRewarded()
		return
	if admob:
		admob.loadRewarded(rewarded_unit_id)
		return
	GameState.add_coins(50)

func _on_btn_kg_pressed() -> void:
	LanguageManager.set_language("kg")

func _on_btn_ru_pressed() -> void:
	LanguageManager.set_language("ru")

func _on_btn_en_pressed() -> void:
	LanguageManager.set_language("en")

func _on_btn_instagram_pressed() -> void:
	OS.shell_open("https://www.instagram.com/one_shotgame?igsh=aDlxdXphZnowcXdx")

func _on_btn_telegram_pressed() -> void:
	OS.shell_open("https://t.me/one_shotgame")

func _update_coins_label() -> void:
	if coins_label:
		coins_label.text = str(GameState.get_coins())

func _on_language_changed(_code: String) -> void:
	_update_texts()

func _update_texts() -> void:
	pass

func _needs_language_selection() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		var lang_value := str(cfg.get_value(SETTINGS_SECTION, KEY_LANGUAGE, ""))
		var lang_set := bool(cfg.get_value(SETTINGS_SECTION, KEY_LANGUAGE_SET, false))
		if lang_set or not lang_value.is_empty():
			return false
		return true
	if FileAccess.file_exists(LanguageManager.SAVE_PATH):
		var lang_file := FileAccess.open(LanguageManager.SAVE_PATH, FileAccess.READ)
		if lang_file:
			var lang := lang_file.get_line()
			lang_file.close()
			if not lang.is_empty():
				cfg.set_value(SETTINGS_SECTION, KEY_LANGUAGE, lang)
				cfg.set_value(SETTINGS_SECTION, KEY_LANGUAGE_SET, true)
				cfg.save(SETTINGS_PATH)
				return false
	return true

func _on_rewarded(_reward_type: String, reward_amount: int) -> void:
	var amount := reward_amount if reward_amount > 0 else 50
	GameState.add_coins(amount)

func _on_rewarded_loaded() -> void:
	pass

func _on_rewarded_failed(_error: String) -> void:
	pass

func _on_coins_changed(_coins: int) -> void:
	_update_coins_label()
