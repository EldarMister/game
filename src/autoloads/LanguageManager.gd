extends Node

signal language_changed(code: String)

const SAVE_PATH := "user://language.save"

var current_language: String = "en"

func _ready() -> void:
    load_language()
    _apply_language()

func set_language(code: String) -> void:
    if code.is_empty():
        return
    current_language = code
    save_language()
    _apply_language()
    language_changed.emit(current_language)

func save_language() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_line(current_language)
        file.close()

func load_language() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file:
        current_language = file.get_line()
        file.close()

func _apply_language() -> void:
    TranslationServer.set_locale(current_language)
