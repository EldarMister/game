class_name GameplayState
extends State

const LIVE_BULLET_SCENE := preload("res://revolver/bullets/bullet.tscn")
const BLANK_BULLET_SCENE := preload("res://revolver/bullets/dummy_bullet.tscn")

const TAKE_DURATION: float = 0.6
const RETURN_DURATION: float = 0.6
const DEALER_HOLD_MIN: float = 1.0
const DEALER_HOLD_MAX: float = 2.0

enum Turn {
	PLAYER = 0,
	DEALER = 1
}

enum RevolverState {
	ON_TABLE = 0,
	IN_HAND_PLAYER = 1,
	IN_HAND_DEALER = 2,
	BUSY_RELOAD = 3,
	BUSY_SHOOT = 4
}

@export var choices: ChoiceLabels

@export var dealer: Dealer
@export var player: Player

@export var monitor_controller: MonitorController
@export var session: GameSession

@export var cash_audio_player: AudioStreamPlayer
@export var player_hud: PlayerHUD
@export var bet_dialog: BetDialog
@export var revolver_table_mockup: Node3D
@export var dealer_revolver_pose: Node3D
@export var dealer_head: Node3D

var is_first_dealer_apperence: bool = true
var current_turn: Turn = Turn.PLAYER
var revolver_state: RevolverState = RevolverState.ON_TABLE
var revolver_hand_transform: Transform3D
var revolver_hand_local: Transform3D
var revolver_table_transform: Transform3D
var has_revolver_hand: bool = false
var has_revolver_table: bool = false
var _dealer_rng := RandomNumberGenerator.new()

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("back") and player.is_aiming() and revolver_state == RevolverState.IN_HAND_PLAYER:
		return_to_select_target()

func process(_delta: float) -> void:
	process_choices_on_table()

func process_choices_on_table() -> void:
	var can_choose := current_turn == Turn.PLAYER \
		and not _is_revolver_busy() \
		and player.can_shoot() \
		and (revolver_state == RevolverState.ON_TABLE or revolver_state == RevolverState.IN_HAND_PLAYER)
	if choices.is_shown and not can_choose:
		choices.hide_labels()
	elif not choices.is_shown and can_choose:
		choices.show_labels()
		
		if is_first_dealer_apperence:
			entry_dealer()

func entry_dealer() -> void:
	dealer.entry()
	monitor_controller.show_target_reach()
	is_first_dealer_apperence = false

func enter() -> void:
	choices.dealer_label.clicked.connect(_on_dealer_clicked)
	choices.you_label.clicked.connect(_on_self_clicked)
	player.shooted.connect(_on_player_shooted)
	player.chamber_updated.connect(_on_chamber_updated)
	player.block_reloading()
	current_turn = Turn.PLAYER
	revolver_state = RevolverState.ON_TABLE
	if player_hud:
		player_hud.set_lives(session.player_lives, session.dealer_lives)
	if not has_revolver_hand:
		revolver_hand_transform = player.revolver.global_transform
		revolver_hand_local = player.revolver.transform
		has_revolver_hand = true
	if revolver_table_mockup and not has_revolver_table:
		revolver_table_transform = revolver_table_mockup.global_transform
		has_revolver_table = true
	_set_revolver_on_table()
	_dealer_rng.randomize()
	call_deferred("_start_round_if_needed")

func exit() -> void:
	choices.dealer_label.clicked.disconnect(_on_dealer_clicked)
	choices.you_label.clicked.disconnect(_on_self_clicked)
	player.shooted.disconnect(_on_player_shooted)
	player.chamber_updated.disconnect(_on_chamber_updated)

func _start_round_if_needed() -> void:
	if revolver_state == RevolverState.BUSY_RELOAD:
		return
	if player.revolver.has_bullets():
		return
	await _start_round()

func _start_round() -> void:
	revolver_state = RevolverState.BUSY_RELOAD
	if session.current_bet <= 0:
		var bet := await _request_bet()
		if bet <= 0:
			revolver_state = RevolverState.ON_TABLE
			return
		session.current_bet = bet
	player.revolver.drop_bullets()
	var count := session.get_weighted_shell_count()
	var shells := session.generate_round_shells(count)
	shells = session.shuffle_shells(shells)
	var blank_count := 0
	var live_count := 0
	for shell in shells:
		if shell == GameSession.ShellType.BLANK:
			blank_count += 1
		else:
			live_count += 1
	if player_hud:
		player_hud.set_round_text("В раунде: %s холостых и %s боевых" % [blank_count, live_count])
	_set_revolver_for_dealer()
	dealer_load_shells(shells)
	current_turn = Turn.PLAYER
	revolver_state = RevolverState.ON_TABLE
	_set_revolver_on_table()

func dealer_load_shells(shells: Array) -> void:
	var revolver := player.revolver
	var chamber_node := revolver.chamber.chamber
	for shell in shells:
		var bullet_scene := LIVE_BULLET_SCENE if shell == GameSession.ShellType.LIVE else BLANK_BULLET_SCENE
		var bullet := bullet_scene.instantiate() as Bullet
		chamber_node.add_child(bullet)
		var chamber_point := revolver.get_current_chamber_position()
		bullet.global_transform = chamber_point.global_transform
		revolver.load_bullet(bullet)
		revolver.chamber.spin_up()
	revolver.chamber.spin_random()

func _set_revolver_on_table() -> void:
	if not has_revolver_table:
		return
	player.revolver.show()
	player.revolver.set_as_top_level(true)
	player.revolver.global_transform = revolver_table_transform

func _set_revolver_in_hand() -> void:
	if not has_revolver_hand:
		return
	player.revolver.show()
	player.revolver.set_as_top_level(false)
	player.revolver.transform = revolver_hand_local

func _set_revolver_for_dealer() -> void:
	if dealer_revolver_pose:
		player.revolver.show()
		player.revolver.set_as_top_level(true)
		player.revolver.global_transform = dealer_revolver_pose.global_transform
	else:
		_set_revolver_on_table()

func _on_chamber_updated(revolver: Revolver) -> void:
	session.update_chamber(revolver.chamber)

func _on_dealer_clicked() -> void:
	if not _can_player_take_revolver():
		return
	if revolver_state == RevolverState.ON_TABLE:
		revolver_state = RevolverState.BUSY_SHOOT
		await _tween_revolver_to(revolver_hand_transform, TAKE_DURATION, true)
		revolver_state = RevolverState.IN_HAND_PLAYER
	choices.hide_labels()
	dealer.change_face(Dealer.DealerFace.HAPPY)
	monitor_controller.show_sad()
	await player.to_target_aiming()

func _on_self_clicked() -> void:
	if not _can_player_take_revolver():
		return
	if revolver_state == RevolverState.ON_TABLE:
		revolver_state = RevolverState.BUSY_SHOOT
		await _tween_revolver_to(revolver_hand_transform, TAKE_DURATION, true)
		revolver_state = RevolverState.IN_HAND_PLAYER
	choices.hide_labels()
	dealer.change_face(Dealer.DealerFace.HYPED)
	monitor_controller.show_good_luck()
	await player.to_self_aiming()

func return_to_select_target() -> void:
	monitor_controller.show_target_reach()
	choices.show_labels()
	dealer.change_face(Dealer.DealerFace.SAD)
	await player.to_idle()

func _on_player_shooted(bullet: Bullet, to_dealer: bool) -> void:
	if current_turn != Turn.PLAYER or revolver_state != RevolverState.IN_HAND_PLAYER:
		return
	revolver_state = RevolverState.BUSY_SHOOT
	var profit := session.make_shot(bullet, player, to_dealer)
	monitor_controller.show_current_score(session.get_score_line())
	monitor_controller.show_profit(profit)
	cash_audio_player.play()
	
	if to_dealer:
		await process_dealer_shooting(bullet)
	else:
		await process_self_shooting(bullet)

func process_self_shooting(bullet: Bullet) -> void:
	if _is_live_bullet(bullet):
		session.player_lives -= 1
		if player_hud:
			player_hud.set_lives(session.player_lives, session.dealer_lives)
		if session.player_lives <= 0:
			session.game_end_reason = GameSession.Reason.SELFSHOT
			_consume_bullet(bullet)
			revolver_state = RevolverState.ON_TABLE
			await state_machine.switch_to(GameOverState)
			player.block()
			return
	
	await pause_async(0.15)
	dealer.change_face(Dealer.DealerFace.SAD)
	await _finish_shot_return()
	_consume_bullet(bullet)
	await end_player_turn(0.5)

func process_dealer_shooting(bullet: Bullet) -> void:
	await pause_async(0.15)
	if _is_live_bullet(bullet):
		session.dealer_lives -= 1
		dealer.take_damage()
		if player_hud:
			player_hud.set_lives(session.player_lives, session.dealer_lives)
	else:
		dealer.change_face(Dealer.DealerFace.NEUTRAL)
	
	await _finish_shot_return()
	_consume_bullet(bullet)
	await end_player_turn(0.0)

func end_player_turn(pause: float) -> void:
	await player.to_idle()
	await pause_async(pause)
	
	if session.dealer_lives <= 0:
		await state_machine.switch_to(WiningState)
		return
	
	if not player.revolver.has_bullets():
		await _start_round()
		return
	
	current_turn = Turn.DEALER
	await _dealer_turn()

func _dealer_turn() -> void:
	if current_turn != Turn.DEALER or revolver_state != RevolverState.ON_TABLE:
		return
	choices.hide_labels()
	revolver_state = RevolverState.BUSY_SHOOT
	dealer.play_take_revolver()
	await _tween_revolver_to(_get_dealer_target_transform(), TAKE_DURATION, false)
	revolver_state = RevolverState.IN_HAND_DEALER
	await pause_async(_dealer_rng.randf_range(DEALER_HOLD_MIN, DEALER_HOLD_MAX))
	var dealer_shoots_self := _dealer_choose_self()
	if dealer_shoots_self:
		dealer.change_face(Dealer.DealerFace.SAD)
		dealer.play_shoot_self()
		revolver_state = RevolverState.BUSY_SHOOT
		await _tween_revolver_to(_get_dealer_self_shot_transform(), 0.35, false)
	revolver_state = RevolverState.BUSY_SHOOT
	player.revolver.show()
	player.revolver.set_as_top_level(true)
	dealer.fire()
	player.revolver.fire()
	var bullet := player.revolver.get_current_bullet()
	if _is_live_bullet(bullet):
		if dealer_shoots_self:
			session.dealer_lives -= 1
		else:
			session.player_lives -= 1
	if dealer_shoots_self:
		dealer.take_damage()
	if _is_live_bullet(bullet) and player_hud:
		player_hud.set_lives(session.player_lives, session.dealer_lives)
	if session.player_lives <= 0:
		_consume_bullet(bullet)
		revolver_state = RevolverState.ON_TABLE
		await state_machine.switch_to(DealerForceOverState)
		return
	
	player.revolver.show()
	await _finish_shot_return()
	_consume_bullet(bullet)
	await pause_async(0.15)
	
	if session.dealer_lives <= 0:
		await state_machine.switch_to(WiningState)
		return
	
	if session.player_lives <= 0:
		await state_machine.switch_to(DealerForceOverState)
		return
	
	if not player.revolver.has_bullets():
		await _start_round()
		return
	
	current_turn = Turn.PLAYER

func _dealer_choose_self() -> bool:
	return _dealer_rng.randi_range(0, 1) == 0

func _is_live_bullet(bullet: Bullet) -> bool:
	return bullet != null and not bullet.effect.is_dummy

func _consume_bullet(bullet: Bullet) -> void:
	if bullet == null:
		return
	player.revolver.unload_bullet(bullet)
	bullet.queue_free()

func _finish_shot_return() -> void:
	await _await_revolver_shot()
	await _tween_revolver_to(revolver_table_transform, RETURN_DURATION, false)
	revolver_state = RevolverState.ON_TABLE

func _await_revolver_shot() -> void:
	if player.revolver.animation_player.is_playing():
		await player.revolver.animation_player.animation_finished

func _is_revolver_busy() -> bool:
	return revolver_state == RevolverState.BUSY_RELOAD or revolver_state == RevolverState.BUSY_SHOOT

func _can_player_take_revolver() -> bool:
	if current_turn != Turn.PLAYER:
		return false
	if _is_revolver_busy():
		return false
	if revolver_state != RevolverState.ON_TABLE and revolver_state != RevolverState.IN_HAND_PLAYER:
		return false
	return player.can_shoot()

func _tween_revolver_to(target: Transform3D, duration: float, attach_to_hand: bool) -> void:
	player.revolver.show()
	player.revolver.set_as_top_level(true)
	var tween := create_tween()
	tween.tween_property(player.revolver, "global_position", target.origin, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(player.revolver, "global_rotation", target.basis.get_euler(), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	player.revolver.global_transform = target
	if attach_to_hand and has_revolver_hand:
		player.revolver.set_as_top_level(false)
		player.revolver.transform = revolver_hand_local

func _get_dealer_target_transform() -> Transform3D:
	if dealer_revolver_pose:
		return dealer_revolver_pose.global_transform
	return revolver_table_transform

func _get_dealer_self_shot_transform() -> Transform3D:
	if dealer_head:
		var head_transform := dealer_head.global_transform
		var offset := Vector3(0, -0.12, 0.18)
		var forward := -head_transform.basis.z
		var up := head_transform.basis.y
		var right := forward.cross(up).normalized()
		var basis := Basis(right, up, forward)
		var target := Transform3D(basis, head_transform.origin + offset)
		target = target.looking_at(head_transform.origin, up)
		return target
	return _get_dealer_target_transform()

func pause_async(duration: float) -> void:
	await get_tree().create_timer(duration).timeout

func _request_bet() -> int:
	if bet_dialog == null:
		var fallback: int = int(min(10, GameState.get_coins()))
		if fallback < 10:
			return 0
		return fallback if GameState.spend(fallback) else 0
	bet_dialog.open(GameState.get_coins())
	var bet: int = int(await bet_dialog.bet_confirmed)
	if not GameState.spend(bet):
		return 0
	return bet
