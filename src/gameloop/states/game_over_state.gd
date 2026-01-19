class_name GameOverState
extends StateAsync

@export var session: GameSession

@export var player_hud: PlayerHUD

@export var selfshot_audio: AudioStreamPlayer
@export var main_theme_audio: AudioStreamPlayer

func enter_async() -> void:
	session.stop()
	session.current_bet = 0
	player_hud.statistic_panel.update(session)
	selfshot_audio.play()
	main_theme_audio.stop()
	player_hud.show_curtain(0.05)
	await pause(0.3)
	player_hud.show_statistic(2.0)
	player_hud.statistic_panel.retry_pressed.connect(_on_reload)
	player_hud.statistic_panel.home_pressed.connect(_on_home)

func _on_reload() -> void:
	state_machine.switch_to(GameReloadState)

func _on_home() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
