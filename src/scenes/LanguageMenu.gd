extends Control

const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "settings"
const KEY_LANGUAGE := "language"
const KEY_LANGUAGE_SET := "language_set"

@onready var btn_kg: TextureButton = $LanguagePanel/BtnKG
@onready var btn_ru: TextureButton = $LanguagePanel/BtnRU
@onready var btn_en: TextureButton = $LanguagePanel/BtnEN

func _ready() -> void:
	btn_kg.pressed.connect(_on_language_pressed.bind("kg"))
	btn_ru.pressed.connect(_on_language_pressed.bind("ru"))
	btn_en.pressed.connect(_on_language_pressed.bind("en"))

func _on_language_pressed(code: String) -> void:
	_save_language(code)
	LanguageManager.set_language(code)
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _save_language(code: String) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value(SETTINGS_SECTION, KEY_LANGUAGE, code)
	cfg.set_value(SETTINGS_SECTION, KEY_LANGUAGE_SET, true)
	cfg.save(SETTINGS_PATH)
