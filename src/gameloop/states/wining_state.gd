class_name WiningState
extends StateAsync

@export var dealer: Dealer
@export var player: Player

@export var monitor: QueuedMonitor3D
@export var player_hud: PlayerHUD
@export var game_session: GameSession

@export var main_theme: AudioStreamPlayer
@export var switch_audio_player: AudioStreamPlayer

@export var winning_audio_player: SmoothAudioStreamPlayer

const INTERSTITIAL_AD_UNIT_ID := "ca-app-pub-1150942230390878/5403727614"
const INTERSTITIAL_LOAD_WAIT := 1.5
const INTERSTITIAL_CLOSE_TIMEOUT := 8.0

func enter_async() -> void:
	game_session.game_end_reason = GameSession.Reason.WINNER
	game_session.stop()
	if game_session.current_bet > 0:
		GameState.add_coins(game_session.current_bet * GameSession.BET_WIN_MULTIPLIER)
		game_session.current_bet = 0
	player_hud.statistic_panel.update(game_session)
	
	player.block()
	await pause(0.1)
	monitor.push("[GAMEPLAY_CONGRATS]")
	dealer.change_face(Dealer.DealerFace.HAPPY)
	await pause(0.6)
	switch_audio_player.play()
	await pause(0.05)
	
	winning_audio_player.smooth_duration = 4.0
	winning_audio_player.smooth_play()
	await pause(2.0)
	dealer.quit();
	await pause(0.8)
	switch_audio_player.play()
	main_theme.stop()
	await pause(0.05)
	winning_audio_player.stop()
	
	await pause(0.05)
	player_hud.show_curtain(0.05)
	await pause(0.3)
	await _show_interstitial_if_available()
	player_hud.show_statistic(3.0)
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
