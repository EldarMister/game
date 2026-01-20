extends TextureButton

@export var texture_en: Texture2D
@export var texture_ru: Texture2D
@export var texture_kg: Texture2D

const FALLBACK_EN := preload("res://PlayButtonENG.png")
const FALLBACK_RU := preload("res://PlayButtonRU.png")
const FALLBACK_KG := preload("res://PlayButtonKG.png")

func _ready() -> void:
	_apply_language(_get_current_language())
	LanguageManager.language_changed.connect(_on_language_changed)

func set_lang(lang: String) -> void:
	_apply_language(lang)

func _on_language_changed(lang: String) -> void:
	_apply_language(lang)

func _get_current_language() -> String:
	return LanguageManager.current_language if LanguageManager else "en"

func _apply_language(lang: String) -> void:
	var tex := _resolve_texture(lang)
	texture_normal = tex
	texture_pressed = tex
	texture_hover = tex

func _resolve_texture(lang: String) -> Texture2D:
	match lang:
		"ru":
			return texture_ru if texture_ru else FALLBACK_RU
		"kg":
			return texture_kg if texture_kg else FALLBACK_KG
		_:
			return texture_en if texture_en else FALLBACK_EN
