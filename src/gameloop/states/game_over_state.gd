class_name GameOverState
extends StateAsync

@export var session: GameSession

@export var player_hud: PlayerHUD

@export var selfshot_audio: AudioStreamPlayer
@export var main_theme_audio: AudioStreamPlayer

const INTERSTITIAL_AD_UNIT_ID := "ca-app-pub-1150942230390878/5403727614"
const INTERSTITIAL_LOAD_WAIT := 1.5
const INTERSTITIAL_CLOSE_TIMEOUT := 8.0

func enter_async() -> void:
	session.stop()
	session.current_bet = 0
	player_hud.statistic_panel.update(session)
	selfshot_audio.play()
	main_theme_audio.stop()
	player_hud.show_curtain(0.05)
	await pause(0.3)
	await _show_interstitial_if_available()
	player_hud.show_statistic(2.0)
	player_hud.statistic_panel.retry_pressed.connect(_on_reload)
	player_hud.statistic_panel.home_pressed.connect(_on_home)

func _on_reload() -> void:
	state_machine.switch_to(GameReloadState)

func _on_home() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _show_interstitial_if_available() -> void:
	if not Engine.has_singleton("DroidAdMob"):
		return
	var admob: Object = Engine.get_singleton("DroidAdMob")
	if not admob:
		return
	var test_mode := OS.is_debug_build()
	var unit_id: String = admob.getTestInterstitialAdUnit() if test_mode else INTERSTITIAL_AD_UNIT_ID
	if not admob.isInterstitialLoaded():
		admob.loadInterstitial(unit_id)
		await pause(INTERSTITIAL_LOAD_WAIT)
	if admob.isInterstitialLoaded():
		var closed := false
		admob.connect("ad_closed", func() -> void: closed = true, Object.CONNECT_ONE_SHOT)
		admob.showInterstitial()
		var elapsed := 0.0
		while not closed and elapsed < INTERSTITIAL_CLOSE_TIMEOUT:
			await pause(0.1)
			elapsed += 0.1
		admob.loadInterstitial(unit_id)
